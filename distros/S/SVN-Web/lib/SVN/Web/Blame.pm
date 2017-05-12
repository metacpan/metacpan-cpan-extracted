package SVN::Web::Blame;

use strict;
use warnings;

use base 'SVN::Web::action';

use Encode ();

our $VERSION = 0.62;

=head1 NAME

SVN::Web::Blame - SVN::Web action to show blame/annotation information

=head1 SYNOPSIS

In F<config.yaml>

  actions:
    ...
    blame:
      class: SVN::Web::Blame
      action_menu:
        show:
          - file
        link_text: (view blame)
    ...

=head1 DESCRIPTION

Shows a specific revision of a file in the Subversion repository, with
blame/annotation information.

=head1 OPTIONS

=over 8

=item rev

The revision of the file to show.  Defaults to the repository's
youngest revision.

If this is not an interesting revision for this file, the repository history
is searched to find the youngest interesting revision for this file that is
less than C<rev>.

=back

=head1 TEMPLATE VARIABLES

=over 8

=item at_head

A boolean value, indicating whether the user is currently viewing the
HEAD of the file in the repository.

=item context

Always C<file>.

=item rev

The revision that has been returned.  This is not necessarily the same
as the C<rev> option passed to the action.  If the C<rev> passed to the
action is not interesting (i.e., there were no changes to the file at that
revision) then the file's history is searched backwards to find the next
oldest interesting revision.

=item youngest_rev

The youngest interesting revision of the file.

=item mimetype

The file's MIME type, extracted from the file's C<svn:mime-type>
property.  If this is not set then C<text/plain> is used.

=item blame_details

An array of hashes.  Each entry in the array corresponds to a line from
the file.  Each hash contains the following keys:

=over

=item line_no

The line number (starting with 0) in the file.

=item revision

The revision in which this line was last changed.

=item author

The author of the revision that changed this line

=item date

The date on which the line was changed, formatted according to
L<SVN::Web/"Time and date formatting">.

=item line

The contents of this line.

=back

=back

=head1 EXCEPTIONS

None.

=cut

sub cache_key {
    my $self = shift;
    my $path = $self->{path};

    my ( undef, undef, $act_rev, $head ) = $self->get_revs();

    return "$act_rev:$head:$path";
}

sub run {
    my $self = shift;
    my $uri  = $self->{repos}{uri} . $self->{path};

    my ( $exp_rev, $yng_rev, $act_rev, $head ) = $self->get_revs();

    my $rev = $act_rev;

    my @blame_details;

    $self->ctx_blame(
        $uri,
        1, $rev,
        sub {
            push @blame_details,
              {
                line_no => $_[0],
                rev     => $_[1],
                author  => $_[2],
                date    => $self->format_svn_timestamp( $_[3] ),
                line    => Encode::decode('utf8',$_[4]),
              };
        }
    );

    my $mime_type;
    my $props = $self->ctx_propget( 'svn:mime-type', $uri, $rev, 0 );
    if ( exists $props->{$uri} ) {
        $mime_type = $props->{$uri};
    }
    else {
        $mime_type = 'text/plain';
    }

    return {
        template => 'blame',
        data     => {
            context       => 'file',
            rev           => $act_rev,
            youngest_rev  => $yng_rev,
            at_head       => $head,
            mimetype      => $mime_type,
            blame_details => \@blame_details,
        }
    };
}

1;

=head1 COPYRIGHT

Copyright 2007 by Nik Clayton C<< <nik@FreeBSD.org> >>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
