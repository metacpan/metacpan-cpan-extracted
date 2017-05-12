# BEGIN BPS TAGGED BLOCK {{{
# COPYRIGHT:
# 
# This software is Copyright (c) 2003-2008 Best Practical Solutions, LLC
#                                          <clkao@bestpractical.com>
# 
# (Except where explicitly superseded by other copyright notices)
# 
# 
# LICENSE:
# 
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of either:
# 
#   a) Version 2 of the GNU General Public License.  You should have
#      received a copy of the GNU General Public License along with this
#      program.  If not, write to the Free Software Foundation, Inc., 51
#      Franklin Street, Fifth Floor, Boston, MA 02110-1301 or visit
#      their web page on the internet at
#      http://www.gnu.org/copyleft/gpl.html.
# 
#   b) Version 1 of Perl's "Artistic License".  You should have received
#      a copy of the Artistic License with this package, in the file
#      named "ARTISTIC".  The license is also available at
#      http://opensource.org/licenses/artistic-license.php.
# 
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# CONTRIBUTION SUBMISSION POLICY:
# 
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of the
# GNU General Public License and is only of importance to you if you
# choose to contribute your changes and enhancements to the community
# by submitting them to Best Practical Solutions, LLC.)
# 
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with SVK,
# to Best Practical Solutions, LLC, you confirm that you are the
# copyright holder for those contributions and you grant Best Practical
# Solutions, LLC a nonexclusive, worldwide, irrevocable, royalty-free,
# perpetual, license to use, copy, create derivative works based on
# those contributions, and sublicense and distribute those contributions
# and any derivatives thereof.
# 
# END BPS TAGGED BLOCK }}}
package SVK::Mirror;
use strict;
use warnings;

use SVN::Core;
use SVK::Logger;

use Sys::Hostname;
use SVK::I18N;
use SVK::Util qw(uri_escape uri_unescape);
use Scalar::Util 'weaken';
use File::Temp qw//;

use base 'Class::Accessor::Fast';
use SVK::Notify;

__PACKAGE__->mk_accessors(qw(depot path server_uuid source_uuid pool url _backend _locked follow_anchor_copy _rev_cache));

*repos = sub { Carp::cluck unless $_[0]->depot; shift->depot->repos };

use SVK::Mirror::Backend::SVNRa;

## class SVK::Mirror;
## has ($.repos, $.path, $.server_uuid, $.url, $.pool);
## has $!backend handles <find_changeset sync_changeset traverse_new_changesets mirror_changesets get_commit_editor>;
## has $!locked

## submethod BUILD($.path, $.repos, :$backend = 'SVNRa', :$.url, :%backend_options) {
##   $!backend = $.load_backend: self;
##   if $.url {
##       $!backend.new: self;
##   }
##   else {
##       $!backend.load: self;
##   }
##   POST {
##     [&&] $.url, $.server_uuid;
##   }
## }

## method load($path, $repos) {
##   $.new(:$path, :$repos);
##}

=head1 NAME

SVK::Mirror - 

=head1 SYNOPSIS

    # setup a new mirror
    my $mirror = SVK::Mirror->create( { backend => 'SVNRa',  url => 'http://server/',
                                        backend_options => {}, repos => $repos, path => '/mirror' } );
    # load existing mirror
    my $existing = SVK::Mirror->load( { path => $path, repos => $repos } );

    $mirror->mirror_changesets();

    $mirror->traverse_changesets( sub { $revs_to_mirror++ } );

=head1 DESCRIPTION

=over

=item create

=cut

sub create {
    my ( $class, $args ) = @_;
    my $self = $class->SUPER::new($args);

    $self->{url} =~ s{/+$}{}g;
    $self->{url} = uri_unescape($self->{url});

    $self->pool( SVN::Pool->new(undef) )
        unless $self->pool;

    if ( $self->path eq '/' ) {
        $self->_backend(
            $self->_create_backend( 'SVNSync',
                $args->{backend_options} )
        );
        weaken( $self->{_backend}{mirror} );
        return $self;
    }

    my $t = $self->get_svkpath('/');

    my ($editor, %opt) = $t->get_dynamic_editor(
        ignore_mirror => 1,
        message       => loc('Mirror initialized for %1', $self->url),
        author        => $ENV{USER},
    );

    $self->_backend(
        $self->_create_backend( $args->{backend}, $args->{backend_options}, $opt{txn}, $editor )
    );

    weaken( $self->{_backend}{mirror} );

    my %mirrors = map { ( $_ => 1 ) } $self->path,
        split( /\n/, $t->root->node_prop( '/', 'svm:mirror' ) || '' );

    $editor->change_dir_prop( $editor->_root_baton, 'svm:mirror',
        join( "\n", ( grep length, sort keys %mirrors ), '' ) );
    $editor->close_edit;

    return $self;
}

sub _create_backend {
    my $self = shift;
    my ($backend) = @_;
    my $class = 'SVK::Mirror::Backend::'.$backend;
    use UNIVERSAL::require;
    $class->require or die $!;

    # actually initialise the mirror on mirror path
    return $class->create( $self, @_ );

}

=item load

=cut

sub load {
    my ( $class, $args ) = @_;
    my $self = $class->SUPER::new($args);

    my $backend = $self->path eq '/' ? 'SVNSync' : 'SVNRa';
    $self->_backend(
        $self->_load_backend( $backend, $args->{backend_options} ) );
    weaken( $self->{_backend}{mirror} );

    return $self;
}

sub _load_backend {
    my $self = shift;
    my ($backend) = @_;
    my $class = 'SVK::Mirror::Backend::'.$backend;
    use UNIVERSAL::require;
    $class->require or die $!;

    # actually initialise the mirror on mirror path
    return $class->load( $self, @_ );
}

=back

=head2 METHODS

=over

=item detach

=cut

sub detach {
    my ($self, $remove_props) = @_;

    my $t = $self->get_svkpath('/');

    my ($editor) = $t->get_dynamic_editor(
        ignore_mirror => 1,
        message       => 'Discard mirror for '.$self->path,
        author        => $ENV{USER},
    );

    my %mirrors = map { ( $_ => 1 ) } $self->path,
        split( /\n/, $t->root->node_prop( '/', 'svm:mirror' ) || '' );

    $editor->change_dir_prop( $editor->_root_baton, 'svm:mirror',
        join( "\n", grep { $_ ne $self->path }( grep length, sort keys %mirrors ), '' ) );

    if (0 && $remove_props) {
	$editor->change_dir_prop( 0, 'svm:uuid', undef);
	$editor->change_dir_prop( 0, 'svm:source', undef);
	$editor->adjust;
    }

    $editor->close_edit;
}

=item bootstrap

=cut

sub bootstrap {
    my ($self, $dumpfile, $file_hint) = @_;
    $file_hint ||= $dumpfile;
    my $fh;
    require SVN::Dump;

    if ($dumpfile eq '-') {
        $fh = \*STDIN;
    } elsif ($dumpfile =~ m{^(file|https?|ftp)://}) {
        $logger->info( loc( "Downloading dump file: %1", $dumpfile ) );

        require LWP::UserAgent;
        my $ua = LWP::UserAgent->new(agent => "SVK-bootstrap/$SVK::VERSION");
        my $response = $ua->head( $dumpfile );
        die $response->status_line unless $response->is_success;

        my $writer;
        pipe( $fh, $writer );
        unless (fork) {
            close $fh;
            $ua->get(
                $dumpfile,
                ':content_cb' => sub {
                    my ( $data, $cb_response, $protocol ) = @_;
                    print { $writer } $data;
                },
                ':read_size_hint' => 16384,
            );
            close $writer;
            exit;
        }
        close $writer;
        binmode($fh, ":raw");
    }
    else {
        open $fh, '<:raw', $dumpfile or die $!;
    }

    # XXX make these fail optionally
    if ($file_hint =~ m/bz2$/i) {
        require PerlIO::via::Bzip2;
        binmode($fh, ':via(Bzip2)');
    }
    elsif ($file_hint =~ m/gz$/i) {
        require PerlIO::gzip;
        binmode($fh, ':gzip(lazy)');
    }

    my $dump = SVN::Dump->new( { fh => $fh } );
    my $prefix = $self->path.'/';

    my $prev = undef;
    my $rev = 0;
    my $buf;
    my $header;
    my $progress = SVK::Notify->new->progress( min => 0, max => $self->_backend->_new_ra->get_latest_revnum );
    if ($self->fromrev) {
        $logger->info(loc("Skipping dumpstream up to revision %1", $self->fromrev));
    }

    my $pool = SVN::Pool->new_default;
    while ( my $record = $dump->next_record() ) {
	if ($record->type eq 'format' or $record->type eq 'uuid') {
	    $header = $header.$record->as_string;
	    next;
	}

	for my $r ($record, $record->get_included_record) {
	    next unless $r;

	    if (my $path = $r->get_header('Node-copyfrom-path')) {
		$path = $prefix.$path;
		$r->set_header('Node-copyfrom-path' => $path );
	    }

	    if ($r->get_header('Revision-number')) {
		printf STDERR "%s rev:%d\r",$progress->report( "%45b",$rev),$rev;
		$rev = $r->get_header('Revision-number');
		$prev = $rev if !$prev;
		$r->set_property('svm:headrev',$self->source_uuid.':'.$rev."\n");
	    }

	    if ( my $path = $r->get_header('Node-path') ) {
		$path = $prefix.$path;
		$r->set_header('Node-path' => $path);
	    }
	}

	if ($rev and $prev != $rev) {
	    $self->_import_repos($header, $buf, $pool) if $prev > $self->fromrev;
	    $pool->clear;
	    $buf = "";
	    $prev = $rev;
	}

	$buf = $buf.$record->as_string;
    }
    # last one
    if ($rev) {
	$self->_import_repos($header, $buf, $pool) if $prev > $self->fromrev;
    }

}

sub _import_repos {
    my $self = shift;
    my ($header, $buf, $pool) = @_;
    $buf = $header.$buf;
    open my $fh, '<', \$buf;
    my $feedback = '';
    open my $fstream, '>', \$feedback;
    my $ret = SVN::Repos::load_fs2( $self->repos, $fh, $fstream, $SVN::Repos::load_uuid_default, undef, 0, 0, undef, undef, $pool );
    # (repos,dumpstream,feedback_stream,uuid_action,parent_dir,use_pre_commit_hook,use_post_commit_hook,cancel_func,cancel_baton,pool);
    # XXX: display $feedback if we are in verbose / debug mode.
    # and provide progress feedback in caller
    return $ret;
}

=item relocate($newurl)

=item with_lock($code)

=cut

sub with_lock {
    my ( $self, $lock, $code ) = @_;

    $self->lock;
    eval { $code->() };
    $self->unlock;
    die $@ if $@;
}

sub _lock_token {
    my $token = $_[0]->path;
    $token =~ s/_/__/g;
    $token =~ s{/}{_}g;
    return "svm:lock:$token";
}

sub _lock_content { hostname . ':' . $$ };

sub lock {
    my ($self)  = @_;
    my $fs      = $self->repos->fs;
    my $token   = $self->_lock_token;
    my $content = $self->_lock_content;
    my $where = join( ' ', ( caller(0) )[ 0 .. 2 ] );

    my $lock_message = $self->_lock_message;
    # This is not good enough but race condition should result in failed sync
    # without corrupting repository.
LOCKED:
    {
	my $pool = SVN::Pool->new_default;
        while (1) {
	    $pool->clear;
            my $who = $fs->revision_prop( 0, $token ) or last LOCKED;
	    last if $who eq $content;
	    $lock_message->($self, $who);
            sleep 1;
        }
    }
    $fs->change_rev_prop( 0, $token, $content );
    $self->_locked(1);
}

sub unlock {
    my ( $self, $force ) = @_;
    my $fs = $self->repos->fs;
    if ($force) {
        for ( keys %{ $fs->revision_proplist(0) } ) {
            next unless m/^svm:lock:/;
            $fs->change_rev_prop( 0, $_, undef );
        }
        return;
    }

    my $token = $self->_lock_token;
    if ( $self->_locked ) {
        $fs->change_rev_prop( 0, $token, undef );
        $self->_locked(0);
    }
}

=item find_changeset($localrev)

Returns an opaque object that C<sync_changeset> understands.

=cut

=item find_rev_from_changeset($remote_identifier)

=item traverse_new_changesets($code)

calls C<$code> with an opaque object and metadata that C<sync_changeset> understands.

=item sync_changeset($changeset, $metadata)

=item mirror_changesets

=item get_commit_editor

=item url

=cut

sub get_svkpath {
    my ($self, $path) = @_;
    return SVK::Path->real_new( { depot => $self->depot, path => $path || $self->path } )
      ->refresh_revision;
}

for my $delegate
    qw( find_rev_from_changeset find_changeset sync_changeset traverse_new_changesets mirror_changesets get_commit_editor refresh change_rev_prop fromrev source_path relocate )
{
    no strict 'refs';
    *{$delegate} = sub {
        my $self   = shift;
	Carp::cluck $delegate unless $self->_backend;
        my $method = $self->_backend->can($delegate);
        unshift @_, $self->_backend;
        goto $method;
    };
}

# compat methods

sub spec {
    my $self = shift;
    return join(':', $self->server_uuid, $self->_backend->source_path);
}

sub find_local_rev {
    my ($self, $changeset, $uuid) = @_;
    $self->_rev_cache({}) unless $self->_rev_cache;
    $self->_rev_cache->{$uuid || ''}{$changeset}
        ||= $self->find_rev_from_changeset($changeset, $uuid);
}

sub find_remote_rev {
    goto \&find_changeset;
}

sub get_merge_back_editor {
    my $self = shift;
    return ($self->_backend->fromrev, $self->get_commit_editor(@_));
}

sub run {
    my ($self, $torev, $fake_last) = @_;
    return $self->run_svnmirror_sync({ torev => $torev }) unless $self->_backend->has_replay;

    $logger->info(loc("Syncing %1", $self->url).($self->_backend->_relayed ? loc(" via %1", $self->server_url) : ""));

    $self->{use_progress} = 1 unless SVK::Test->can('is_output');

    $self->mirror_changesets($torev,
        sub {
            my ( $changeset, $rev ) = @_;
            $logger->info("Committed revision $rev from revision $changeset.")
                unless $self->{use_progress};
        }, $fake_last
    );
    die $@ if $@;
}

sub sync_snapshot {
    my ($self, $snapshot) = @_;
    $logger->warn(loc("
svk is now taking a snapshot of the repository at:
  %1

This is essentially making a checkout of the url, and is bad if the
url contains directories like trunk and branches.  If this isn't what
you mean, please hit ^C.

", $self->url));

    $self->run_svnmirror_sync( { skip_to => $snapshot });
}

sub _lock_message {
    my $self = shift;
    my $target = $self->get_svkpath;
    my $i = 0;
    sub {
	my ($mirror, $who) = @_;
	$logger->warn(loc("Waiting for lock on %1: %2.", $target->depotpath, $who));
	if (++$i % 3 == 0) {
	    $logger->error(loc ("
The mirror is currently locked. This might be because the mirror is
in the middle of a sensitive operation or because a process holding
the lock hung or died.  To check if the mirror lock is stalled,  see
if $who is a running, valid process

If the mirror lock is stalled, please interrupt this process and run:
    svk mirror --unlock %1
", $target->depotpath));
	}
    }
}

sub _copy_notify {
    my ($self, $target, $m, undef, $path, $from_path, $from_rev) = @_;
    # XXX: on anchor, try to get a external copy cache
    return unless $m->path ne $path;
    return $target->depot->find_local_mirror($m->server_uuid, $from_path, $from_rev);
}

sub run_svnmirror_sync {
    my ( $self, $arg ) = @_;

    require SVN::Mirror;
    my $target = $self->get_svkpath;

    my $lock_message = $self->_lock_message;
    my $escaped_url = uri_escape($self->url);
	    
    # XXX if SVN::Mirror do uri_escape in future, then we can remove 'source => $escaped_url' line
    my $svm = SVN::Mirror->new(
        source => $escaped_url,
        target_path    => $self->path,
        repos          => $self->depot->repos,
        config         => SVK::Config->svnconfig,
        revprop        => $self->depot->mirror->revprop,
        cb_copy_notify =>
          sub { $self->_copy_notify( $target, $self, @_ ) },
        lock_message => sub { $lock_message->($_[0], $_[2])},
        get_source   => 1,
        pool         => SVN::Pool->new,
        %$arg
    );
    $svm->init;

    $svm->run( $arg->{torev} );
}

=back

=cut

1;
