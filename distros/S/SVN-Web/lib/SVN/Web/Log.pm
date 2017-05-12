package SVN::Web::Log;

use strict;
use warnings;

use base 'SVN::Web::action';

use Encode ();
use SVN::Core;
use SVN::Ra;

our $VERSION = 0.62;

=head1 NAME

SVN::Web::Log - SVN::Web action to show log messages for a repository path

=head1 SYNOPSIS

In F<config.yaml>

  actions:
    ...
    log:
      class: SVN::Web::Log
      action_menu:
        show:
          - file
          - directory
        link_text: (view revision log)
    ...

=head1 DESCRIPTION

Shows log messages (in reverse order) for interesting revisions of a given
file or directory in the repository.

=head1 OPTIONS

=over 8

=item limit

The number of log entries to retrieve.  The default is 20.

=item rev

The repository revision to start with.  The default is the repository's
youngest revision.

=back

=head1 TEMPLATE VARIABLES

=over 8

=item context

Either C<directory> or C<file>.

=item at_head

A boolean value, true if the log starts with the most recent revision.

=item at_oldest

A boolean value, true if the list of revisions (C<revs>) includes the oldest
revision for this path.

=item isdir

A boolean value, true if the given path is a directory.

=item rev

The repository revision that the log starts with.

=item revs

A list of hashes.  Each entry corresponds to a particular repository revision,
and has the following keys.

=over 8

=item rev

The repository revision this entry is for.

=item youngest_rev

The repository's youngest revision.

=item author

The author of this change.

=item date

The date of this change, formatted according to
L<SVN::Web/"Time and date formatting">.

=item msg

The log message for this change.

=item paths

A list of hashes containing information about the paths that were
changed with this commit.  Each hash key is the path name that was
modified with this commit.  Each key is a hash ref of extra
information about the change to this path.  These hash refs have the
following keys.

=over 8

=item action

A single letter indicating the action that was carried out on the
path.  A file was either added C<A>, modified C<M>, replaced C<R>,
or deleted C<D>.

=item copyfrom

If the file was copied from another file then this is the path of the
source of the copy.

=item copyfromrev

If the file was copied from another file then this is the revision of
the file that it was copied from.

=back

=back

=item limit

The value of the C<limit> parameter.

=back

=head1 EXCEPTIONS

None.

=cut

sub _log {
    my ( $self, $paths, $rev, $author, $date, $msg, $pool ) = @_;

    return unless $rev > 0;

    my $data = {
        rev    => $rev,
        author => $author,
        date   => $self->format_svn_timestamp($date),
        msg    => Encode::decode('utf8',$msg),
    };

    $data->{paths} = {
        map {
            $_ => {
                action      => $paths->{$_}->action(),
                copyfrom    => $paths->{$_}->copyfrom_path(),
                copyfromrev => $paths->{$_}->copyfrom_rev(),
              }
          } keys %$paths
    };

    push @{ $self->{REVS} }, $data;
}

sub cache_key {
    my $self = shift;
    my $path = $self->{path};

    my ( undef, undef, $act_rev, $head ) = $self->get_revs();

    my $limit = $self->_get_limit();

    return "$act_rev:$limit:$head:$path";
}

# Obtain the correct 'limit' value.  Use the CGI parameter if it's defined,
# supporting the special value 'all' to mean all revisions.  Default to 20
# if it's not defined.
sub _get_limit {
    my $self = shift;

    my $limit = $self->{cgi}->param('limit');
    if ( defined $limit ) {
        return $limit eq '(all)' ? 0 : $limit;
    }

    return 20;
}

sub run {
    my $self  = shift;
    my $ra    = $self->{repos}{ra};
    my $limit = $self->_get_limit();
    my $rev   = $self->{cgi}->param('rev') || $ra->get_latest_revnum();
    my $uri   = $self->{repos}{uri};
    $uri .= '/'.$self->rpath if $self->rpath;

    my ( undef, $yng_rev, undef, $head ) = $self->get_revs();

    # Handle log paging
    my $at_oldest;
    if ($limit) {    # $limit not 'all'
            # Get one more log entry than asked for.  If we get back this
            # many log entries then we know there's at least one more page
            # of results to show.  If we get back $limit or less log
            # entries then we're on the last page.
            #
            # If we're not on the last page then pop off the extra log entry
        $ra->get_log( [ $self->rpath ], $rev, 1, $limit + 1, 1, 1, sub { $self->_log(@_) } );

        $at_oldest = @{ $self->{REVS} } <= $limit;

        pop @{ $self->{REVS} } unless $at_oldest;
    }
    else {

        # We must be displaying to the oldest rev, so no paging required
        $ra->get_log( [ $self->rpath ], $rev, 1, $limit, 1, 1, sub { $self->_log(@_) } );

        $at_oldest = 1;
    }

    #    $self->_resolve_changed_paths();
    my $node_kind = $self->svn_get_node_kind($uri, $rev, $rev);
    my $is_dir = $node_kind == $SVN::Node::dir;

    return {
        template => 'log',
        data     => {
            context => $is_dir ? 'directory' : 'file',
            isdir   => $is_dir,
            revs    => $self->{REVS},
            limit   => $limit,
            rev     => $rev,
            youngest_rev => $yng_rev,
            at_oldest    => $at_oldest,
            at_head      => $head,
        }
    };
}

# Add 'isdir' keys to the paths if appropriate.  Also, add trailing slashes
# if necessary.
#
# This code used to be in get_log() when it used the repos layer.  When
# the code was changed to use the ra layer it had to be moved out, as you
# can't call ra functions from a get_log() callback.
#
# XXX Very similar code in Revision.pm, needs refactoring
sub _resolve_changed_paths {
    my $self = shift;
    my $uri  = $self->{repos}{uri};

    my $subpool = SVN::Pool->new();

    foreach my $data ( @{ $self->{REVS} } ) {
        foreach my $path ( keys %{ $data->{paths} } ) {
            my $node_kind = $self->svn_get_node_kind("$uri$path", $data->{rev}, $data->{rev}, $subpool);

            $data->{paths}{$path}{isdir} = $node_kind == $SVN::Node::dir;

            $subpool->clear();
        }
    }
}

1;

=head1 COPYRIGHT

Copyright 2003-2004 by Chia-liang Kao C<< <clkao@clkao.org> >>.

Copyright 2005-2007 by Nik Clayton C<< <nik@FreeBSD.org> >>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
