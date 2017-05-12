package Pushmi::Command::Mirror;
use strict;
use warnings;
use base 'Pushmi::Command';

use Pushmi::Mirror;
use Pushmi::Config;
use Path::Class;
use SVN::Mirror;
use SVK::Config;
use SVK::Mirror;
use SVK::XD;
use SVN::Delta;
use SVK::I18N;
use UNIVERSAL::require;

my $logger = Pushmi::Config->logger('pushmi.svkmirror');
{
no warnings 'redefine';
my $memd = Pushmi::Config->memcached;

*SVK::Mirror::lock = sub {
    my ($self)  = @_;
    my $fs      = $self->repos->fs;
    my $token = join(':', $self->repos->path, $self->_lock_token );
    my $content = $self->_lock_content;
    my $where = join( ' ', ( caller(0) )[ 0 .. 2 ] );

    my $lock_message = $self->_lock_message;
LOCKED:
    {
	my $pool = SVN::Pool->new_default;
	my $trial = 0;
        while (1) {
	    $pool->clear;
	    my $ret;
	    last LOCKED if $ret = $memd->add( $token, $content );
            my $who = $memd->get( $token ) or next;
	    last if $who eq $content;
	    $logger->warn('['.$self->repos->path."] lock held by $who...")
		unless $trial++ % 60;
	    $lock_message->($self, $who);
            sleep 1;
        }
    }
    $logger->debug('['.$self->repos->path."] locked by ".$token);
    $self->_locked(1);
};

*SVK::Mirror::unlock = sub {
    my ( $self, $force ) = @_;
    my $token = join(':', $self->repos->path, $self->_lock_token );
    my $who = $memd->get( $token );
    if ($force || $self->_locked ) {
	my $ret = $memd->delete( $token );
	$logger->debug('['.$self->repos->path."] unlock result: $ret");
	$self->_locked(0);
    }
};


}

sub options { () }

sub run {
    my $self = shift;

    # compat
    for ($self->subcommands) {
	if ($self->{$_}) {
	    my $cmd = 'Pushmi::Command::'.ucfirst($_);
	    $cmd->require or die "can't require $cmd: $@";
	    return (bless $self, $cmd)->run(@_)
	}
    }

    $self->run_init(@_);
}

sub root_svkpath {
    my ($self, $repos) = @_;
    my $depot = SVK::Depot->new( { repos => $repos, repospath => $repos->path, depotname => '' } );
    SVK::Path->real_new(
        {
            depot => $depot,
            path => '/'
        }
    )->refresh_revision;
}

sub setup_auth {
    my $self = shift;
    my $config = Pushmi::Config->config;
    SVK::Config->auth_providers(
    sub {
        [ $config->{use_cached_auth} ? SVN::Client::get_simple_provider() : (),
          SVN::Client::get_username_provider(),
          SVN::Client::get_ssl_server_trust_file_provider(),
          SVN::Client::get_ssl_server_trust_prompt_provider(
                \&SVK::Config::_ssl_server_trust_prompt
          ),
	  SVN::Client::get_simple_prompt_provider( $self->can('pushmi_auth'), 0 ) ]
    });
}

# XXX: we should be using real providers if we can thunk svn::auth providers
sub pushmi_auth {
    my ($cred, $realm, $default_username, $may_save, $pool) = @_;
    my $config = Pushmi::Config->config;
    $logger->logdie("unable to get username from config file.")
	unless defined $config->{username};
    $cred->username($config->{username});
    $cred->password($config->{password});
    $cred->may_save(0);
    return $SVN::_Core::SVN_NO_ERROR;
}

sub canonpath {
    my $self = shift;
    $_[0] = Path::Class::Dir->new($_[0])->absolute->stringify;
}

sub run_init {
    my ($self, $repospath, $url) = @_;
    $self->canonpath($repospath);
    my ($repos, $created);
    die "url required.\n" unless $url;
    if (-e $repospath) {
	$repos = SVN::Repos::open($repospath) or die "Can't open repository: $@";
    }
    else {
	$created = 1;
	$repos = SVN::Repos::create($repospath, undef, undef, undef, undef )
	    or die "Unable to create repository on $repospath";
    }

    my $t = $self->root_svkpath($repos);

    my $mirror = SVK::Mirror->new( { depot => $t->depot, path => '/', url => $url, pool => SVN::Pool->new} );
    require SVK::Mirror::Backend::SVNSync;

    $self->setup_auth;
    my $backend = bless { mirror => $mirror }, 'SVK::Mirror::Backend::SVNSync';
    $mirror->_backend($backend->create( $mirror ));

    Pushmi::Mirror->install_hook($repospath);
    $mirror->depot->repos->fs->set_uuid($mirror->server_uuid);

    print loc("Mirror initialized.\n");

    return;
}

sub ensure_consistency {
    my ($self, $t) = @_;
    my $repos = $t->repos;
    my $revision = $repos->fs->revision_prop(0, 'pushmi:inconsistent')
	or return;

    my $repospath = $repos->path;

    $logger->info("[$repospath] ".ref($self).' blocked by inconsistency');

    my ($mirror) = $t->is_mirrored;
    my $master = $mirror->url;

    die "Pushmi slave in inconsistency.  Please use the master repository at $master\nand contact your administrator.  Sorry for the inconveniences.\n";

}

=head1 NAME

Pushmi::Command::Mirror - initialize pushmi mirrors

=head1 SYNOPSIS

 mirror REPOSPATH URL

=cut

1;
