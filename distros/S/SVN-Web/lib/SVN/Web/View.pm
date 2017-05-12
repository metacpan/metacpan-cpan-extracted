package SVN::Web::View;

use strict;
use warnings;

use base 'SVN::Web::action';

use Encode ();

our $VERSION = 0.62;

=head1 NAME

SVN::Web::View - SVN::Web action to view a file in the repository

=head1 SYNOPSIS

In F<config.yaml>

  actions:
    ...
    view:
      class: SVN::Web::View
      action_menu:
        show:
          - file
        link_text: (view file)
    ...

=head1 DESCRIPTION

Shows a specific revision of a file in the Subversion repository.  Includes
the commit information for that file.

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

=item file

The contents of the file.

=item author

The revision's author.

=item date

The date the revision was committed, formatted according to
L<SVN::Web/"Time and date formatting">.

=item msg

The revision's commit message.

=back

=head1 EXCEPTIONS

None.

=cut

sub _log {
    my ( $self, $paths, $rev, $author, $date, $msg, $pool ) = @_;

    return unless $rev > 0;

    return {
        rev    => $rev,
        author => $author,
        date   => $self->format_svn_timestamp($date),
        msg    => Encode::decode('utf8',$msg),
    };
}

sub cache_key {
    my $self = shift;
    my $path = $self->{path};

    my ( undef, undef, $act_rev, $head ) = $self->get_revs();

    return "$act_rev:$head:$path";
}

sub run {
    my $self = shift;
    my $ra   = $self->{repos}{ra};

    my $uri  = $self->{repos}{uri};
    $uri .= '/'.$self->rpath if $self->rpath;

    my ( $exp_rev, $yng_rev, $act_rev, $head ) = $self->get_revs();

    my $rev = $act_rev;

    # Get the log for this revision of the file
    $ra->get_log( [ $self->rpath ], $rev, $rev, 1, 1, 1, sub { $self->{REV} = $self->_log(@_) } );

    # Get the text for this revision of the file
    my ( $fh, $fc ) = ( undef, '' );
    open( $fh, '>', \$fc );
    $self->ctx_cat( $fh, $uri, $rev );
    close($fc);
    $fc = Encode::decode('utf8', $fc);

    my $mime_type;
    my $props = $self->ctx_propget( 'svn:mime-type', $uri, $rev, 0 );
    if ( exists $props->{$uri} ) {
        $mime_type = $props->{$uri};
    }
    else {
        $mime_type = 'text/plain';
    }

    return {
        template => 'view',
        data     => {
            context      => 'file',
            rev          => $act_rev,
            youngest_rev => $yng_rev,
            at_head      => $head,
            mimetype     => $mime_type,
            file         => $fc,
            %{ $self->{REV} },
        }
    };
}

1;

=head1 COPYRIGHT

Copyright 2003-2004 by Chia-liang Kao C<< <clkao@clkao.org> >>.

Copyright 2005-2007 by Nik Clayton C<< <nik@FreeBSD.org> >>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
