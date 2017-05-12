# -*- Mode: cperl; cperl-indent-level: 4 -*-

package SVN::Web::Diff;

use strict;
use warnings;

use base 'SVN::Web::action';

use Encode ();
use SVN::Core;
use SVN::Ra;
use SVN::Client;
use SVN::Web::DiffParser;
use SVN::Web::X;
use List::Util qw(max min);

our $VERSION = 0.62;

=head1 NAME

SVN::Web::Diff - SVN::Web action to show differences between file revisions

=head1 SYNOPSIS

In F<config.yaml>

  actions:
    ...
    diff:
      class: SVN::Web::Diff
    ...

=head1 DESCRIPTION

Returns the difference between two revisions of the same file.

=head1 CONFIGURATION

The following configuration options may be specified in F<config.yaml>.

=over

=item max_diff_size

If showing the diff (see C<show_diff>), this determines the maximum size
of the diff that will be shown.  If the size of the generated diff (in
bytes) is larger than this figure then it is not shown.

Defaults to 200,000 bytes.

=back

=head1 OPTIONS

=over 8

=item rev1

The first revision of the file to compare.

=item rev2

The second revision of the file to compare.

=item revs

A list of two or more revisions.  If present, the smallest number in
the list is assigned to C<rev1> (overriding any given C<rev1> value) and the
largest number in the list is assigned to C<rev2> (overriding any given
C<rev2> value).

In other words:

    ...?rev1=5;rev2=10

is equal to:

    ...?revs=10;revs=5

This supports the "diff between arbitrary revisions" functionality.

=item mime

The desired output format.  The default is C<html> for a diff marked
up in HTML.  The other allowed value is C<text>, for a plain text
unified diff.

=back

=head1 TEMPLATE VARIABLES

=over 8

=item at_head

Boolean, indicating whether or not we're currently diffing against the
youngest revision of this file.

=item context

Always C<file>.

=item rev1

The first revision of the file to compare.  Corresponds with the C<rev1>
parameter, either set explicitly, or extracted from C<revs>.

=item rev2

The second revision of the file to compare.  Corresponds with the C<rev2>
parameter, either set explicitly, or extracted from C<revs>.

=item diff

An L<SVN::Web::DiffParser> object that contains the text of the diff.
Call the object's methods to format the diff.

=item diff_size

The size of the generated diff (before parsing).

=item max_diff_size

The configured maximum diff size.

=back

=head1 EXCEPTIONS

=over 4

=item (cannot diff nodes of different types: %1 %2 %3)

The given path has different node types at the different revisions.
This probably means a file was added, deleted, and then re-added as a
directory at a later date (or vice-versa).

=item (path %1 is a directory at rev %2)

The user has tried to diff two directories.  This is not currently
supported.

=item (path %1 does not exist in revision %2)

The given path is not present in the repository at the given revision.

=item (two revisions must be provided)

No revisions were given to diff against.

=item (rev1 and rev2 must be different)

Either only one revision number was given, or several were given, but
they're the same number.

=back

=cut

my %default_opts = ( max_diff_size => 200_000, );

sub cache_key {
    my $self = shift;

    my ( $rev1, $rev2 ) = $self->_check_params();
    my $path = $self->{path};
    my $mime = $self->{cgi}->param('mime') || 'text/html';

    return "$rev1:$rev2:$mime:$path";
}

sub run {
    my $self = shift;

    $self->{opts} = { %default_opts, %{ $self->{opts} } };

    my ( $rev1, $rev2 ) = $self->_check_params();

    my $ctx  = $self->{repos}{client};
    my $ra   = $self->{repos}{ra};
    my $uri  = $self->{repos}{uri};
    $uri .= '/'.$self->rpath if $self->rpath;

    my ( undef, undef, undef, $at_head ) = $self->get_revs();

    my $mime = $self->{cgi}->param('mime') || 'text/html';

    my %types = (
        $rev1 => $ra->check_path( $self->rpath, $rev1 ),
        $rev2 => $ra->check_path( $self->rpath, $rev2 )
    );

    SVN::Web::X->throw(
        error => '(cannot diff nodes of different types: %1 %2 %3)',
        vars  => [ $self->rpath, $rev1, $rev2 ]
    ) if $types{$rev1} != $types{$rev2};

    foreach my $rev ( $rev1, $rev2 ) {
        SVN::Web::X->throw(
            error => '(path %1 does not exist in revision %2)',
            vars  => [ $self->rpath, $rev ]
        ) if $types{$rev} == $SVN::Node::none;

        SVN::Web::X->throw(
            error => '(path %1 is a directory at rev %2)',
            vars  => [ $self->rpath, $rev ]
        ) if $types{$rev} == $SVN::Node::dir;
    }

    my $style;
    $mime eq 'text/html'  and $style = 'Text::Diff::HTML';
    $mime eq 'text/plain' and $style = 'Unified';

    if ( $mime eq 'text/html' ) {
        my $out = Encode::decode('utf8',$self->svn_get_diff($uri, $rev1, $uri, $rev2, 0));
        my $diff;
        my $diff_size = length($out);
        my $max_diff_size = $self->{opts}{max_diff_size} || 0;
        if ( $diff_size <= $max_diff_size ) {
            $diff = SVN::Web::DiffParser->new($out);
        }

        return {
            template => 'diff',
            data     => {
                context       => 'file',
                rev1          => $rev1,
                rev2          => $rev2,
                diff          => $diff,
                diff_size     => $diff_size,
                max_diff_size => $max_diff_size,
                at_head       => $at_head,
            }
        };
    }
    else {
        return {
            mimetype => $mime,
            body     => $self->svn_get_diff($uri, $rev1, $uri, $rev2, 0),
        };
    }
}

sub _check_params {
    my $self = shift;

    my $rev1 = $self->{cgi}->param('rev1');
    my $rev2 = $self->{cgi}->param('rev2');
    my @revs = $self->{cgi}->param('revs');

    if (@revs) {
        $rev1 = min(@revs);
        $rev2 = max(@revs);
    }

    SVN::Web::X->throw(
        error => '(two revisions must be provided)',
        vars  => []
      )
      unless defined $rev1
          and defined $rev2;

    SVN::Web::X->throw(
        error => '(rev1 and rev2 must be different)',
        vars  => []
    ) if @revs and @revs < 2;

    SVN::Web::X->throw(
        error => '(rev1 and rev2 must be different)',
        vars  => []
    ) if $rev1 == $rev2;

    return ( $rev1, $rev2 );
}

# Make sure that a path exists in a revision
sub _check_path {
    my $self = shift;
    my $path = shift;
    my $rev  = shift;

    my $ra = $self->{repos}{ra};

    if ( $ra->check_path( $self->rpath($path), $rev ) == $SVN::Node::none ) {
        SVN::Web::X->throw(
            error => '(path %1 does not exist in revision %2)',
            vars  => [ $path, $rev ],
        );
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
