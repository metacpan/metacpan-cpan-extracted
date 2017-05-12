package SVN::Web::Revision;

use strict;
use warnings;

use base 'SVN::Web::action';

use Encode ();
use SVN::Core;
use SVN::Ra;
use SVN::Web::X;
use SVN::Web::DiffParser;

our $VERSION = 0.63;

=head1 NAME

SVN::Web::Revision - SVN::Web action to view a repository revision

=head1 SYNOPSIS

In F<config.yaml>

  actions:
    ...
    revision:
      class: SVN::Web::Revision
      opts:
        max_diff_size: 200_000
        show_diff: 1 # or 0
    ...

=head1 DESCRIPTION

Shows information about a specific revision in a Subversion repository.

=head1 CONFIGURATION

The following configuration options may be specified in F<config.yaml>.

=over

=item max_diff_size

If showing the diff (see C<show_diff>), this determines the maximum size
of the diff that will be shown.  If the size of the generated diff (in
bytes) is larger than this figure then it is not shown.

Defaults to 200,000 bytes.

=item show_diff

Boolean indicating whether or not a diff of every file that was changed
in the revision should be shown.

Defaults to 1.

=back

=head1 OPTIONS

=over 8

=item rev

The revision to show.  If not provided then use the repository's
youngest revision.

=back

=head1 TEMPLATE VARIABLES

=over 8

=item context

Always C<revision>.

=item rev

The revision that is being shown.

=item youngest_rev

The repository's youngest revision.  This is useful when constructing
C<next revision> and C<previous revision> links.

=item date

The date on which the revision was committed, formatted according to
L<SVN::Web/"Time and date formatting">.

=item author

The revision's author.

=item msg

The log message associated with this revision.

=item paths

A hash of hash refs.  Each key is a path name.  The value is a further hash ref
with the following keys.

=over 8

=item isdir

A boolean value, true if the given path is a directory.

=item diff

A L<SVN::Web::DiffParser> object representing the diff.  This may be undef,
if the generated diff was larger than C<max_diff_size> or if C<show_diff>
is false.

=item diff_size

The size of the generated diff (before parsing).

=item max_diff_size

The configured maximum diff size.

=item action

A single letter indicating the action that carried out on the path.  A
file was either added C<A>, modified C<M>, replaced C<R>, or deleted
C<D>.

=item copyfrom

If the file was copied from another file then this is the path of the
source of the copy.

=item copyfromrev

If the file was copied from another file then this is the revision of
the file that it was copied form.

=back

=back

=head1 EXCEPTIONS

=over 4

=item (revision %1 does not exist)

The given revision does not exist in the repository.

=back

=cut

my %default_opts = (
    max_diff_size => 200_000,
    show_diff     => 1,
);

sub _log {
    my ( $self, $paths, $rev, $author, $date, $msg, $pool ) = @_;

    my $data = {
        rev    => $rev,
        author => $author,
        date   => $self->format_svn_timestamp($date),
        msg    => Encode::decode('utf8',$msg),
    };

    $data->{paths} = {
        map {
            $self->decode_svn_uri($_) => {
                action      => $paths->{$_}->action(),
                copyfrom    => $paths->{$_}->copyfrom_path(),
                copyfromrev => $paths->{$_}->copyfrom_rev(),
              }
          } keys %$paths
    };

    return $data;
}

sub cache_key {
    my $self = shift;

    return $self->{cgi}->param('rev') if defined $self->{cgi}->param('rev');

    return $self->{repos}{ra}->get_latest_revnum();
}

sub run {
    my $self = shift;

    $self->{opts} = { %default_opts, %{ $self->{opts} } };

    my $ra   = $self->{repos}{ra};
    my $yrev = $ra->get_latest_revnum();

    my $uri  = $self->{repos}{uri};

    my $rev           = $self->{cgi}->param('rev');
    my $max_diff_size = $self->{opts}{max_diff_size};

    $rev = $yrev unless defined $rev;

    SVN::Web::X->throw(
        error => '(revision %1 does not exist)',
        vars  => [$rev]
    ) if $rev > $yrev;

    $ra->get_log( [''], $rev, $rev, 1, 1, 1,
        sub { $self->{REV} = $self->_log(@_) } );

    $self->_resolve_changed_paths();

    my $diff;
    my $diff_size = 0;
    if ( $self->{opts}{show_diff} ) {
        my $out = Encode::decode('utf8', $self->svn_get_diff($uri, $rev - 1, $uri, $rev, 1));
        $diff_size = length($out);
        if ( $diff_size <= $max_diff_size ) {
            $diff = SVN::Web::DiffParser->new($out);
        }
    }

    return {
        template => 'revision',
        data     => {
            context       => 'revision',
            rev           => $rev,
            youngest_rev  => $yrev,
            diff          => $diff,
            diff_size     => $diff_size,
            max_diff_size => $max_diff_size,
            %{ $self->{REV} },
        }
    };
}

# Add 'isdir' keys to the paths if appropriate.
#
# This code used to be in get_log() when it used the repos layer.  When
# the code was changed to use the ra layer it had to be moved out, as you
# can't call ra functions from a get_log() callback.
#
# XXX Very similar code in Log.pm, needs refactoring
sub _resolve_changed_paths {
    my $self    = shift;
    my $uri     = $self->{repos}{uri};
    my $data    = $self->{REV};

    my $subpool = SVN::Pool->new();
    # Set the 'isdir' key
    foreach my $path ( keys %{ $data->{paths} } ) {
        # Ignore deleted nodes
        if ( $data->{paths}{$path}{action} ne 'D' ) {
            my $node_kind = $self->svn_get_node_kind("$uri$path", $data->{rev}, $data->{rev}, $subpool);

            $data->{paths}{$path}{isdir} = $node_kind == $SVN::Node::dir;
        }

        $subpool->clear();
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
