package Pushmi::Command::Sync;
use strict;
use warnings;
use base 'Pushmi::Command::Mirror';
use SVK::I18N;

my $memd = Pushmi::Config->memcached;
my $logger = Pushmi::Config->logger('pushmi.sync');

sub options {
    ('nowait' => 'nowait');
}

sub run {
    my ($self, $repospath) = @_;
    $self->canonpath($repospath);
    my $repos = SVN::Repos::open($repospath) or die "Can't open repository: $@";

    my $t = $self->root_svkpath($repos);
    $self->ensure_consistency($t);

    $self->setup_auth;
    my ($mirror) = $t->is_mirrored;

    if ($self->{nowait}) {
	my $token   = join(':', $mirror->repos->path, $mirror->_lock_token);
	if (my $who = $memd->get( $token ) ) {
	    print loc("Mirror on $repospath is locked by %1, skipping.\n", $who);
	    return;
	}
    }

    my ($first, $last);
    eval {
    $mirror->mirror_changesets(undef,
        sub { $first ||= $_[0]; $last = $_[0] });
    };
    $logger->error("[$repospath] sync failed: $@") if $@;
    $logger->info("[$repospath] sync revision $first to $last") if $first;

    return;
}

=head1 NAME

Pushmi::Command::Sync - synchronize pushmi mirrors

=head1 SYNOPSIS

 sync URL

=head1 OPTIONS

 --nowait             : Don't wait on lock.  Bail out immediately.

=cut

1;
