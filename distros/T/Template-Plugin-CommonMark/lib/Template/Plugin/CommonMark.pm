package Template::Plugin::CommonMark;

use 5.008;
use strict;
use warnings;

our $VERSION = '1.000';
$VERSION = eval $VERSION;

use parent qw( Template::Plugin::Filter );
use CommonMark;

sub init {
    my $self = shift;
    $self->{_DYNAMIC} = 1;

    my $name = $self->{ _ARGS }->[0] || 'cmark';
    $self->install_filter($name);

    return $self;
}

sub filter {
    my ($self, $text, $args, $config) = @_;

    $config = { %{$self->{_CONFIG}}, %{$config || {}} };

    my $opt = CommonMark::OPT_DEFAULT;

    $config->{normalize} and $opt |= CommonMark::OPT_NORMALIZE;
    $config->{validate_utf8} and $opt |= CommonMark::OPT_VALIDATE_UTF8;
    $config->{smart} and $opt |= CommonMark::OPT_SMART;

    CommonMark->markdown_to_html($text, $opt)
}

__PACKAGE__;
__END__
=head1 NAME

Template::Plugin::CommonMark - Template Toolkit plugin to generate HTML from CommonMark

=head1 VERSION

Version 1.000

=head1 SYNOPSIS

    [% FILTER cmark %]
    # Chapter 1

    A long time ago in a village far away, a bullet list was constructed:

    * Foo
    * Bar
    * Baz

    It was *emphasized* that the **bold** were in the forefront. Here is some
    Perl:

    ```perl
    use Path::Tiny;

    my $path = path('/a/dir/file');
    ```
    [% END %]

=head1 DESCRIPTION

C<Template::Plugin::CommonMark> wraps L<CommonMark> into a Template Toolkit plugin, and will filter your markdown text into HTML. The code and tests are shamelessly lifted from L<Template::Plugin::MultiMarkdown>.

=head1 METHODS

This module does not export any subroutines. Two methods are required by the Template Toolkit API:

=head2 init

=head2 filter

=head1 AUTHOR

A. Sinan Unur, C<< <nanis at cpan.org> >>

=head1 BUGS

Please report bugs on L<GitHub|https://github.com/nanis/template-plugin-commonmark/issues>.

=head1 ACKNOWLEDGEMENTS

Almost everything in this module is adapted or copied from L<Template::Plugin::MultiMarkdown|https://metacpan.org/pod/Template::Plugin::MultiMarkdown>. Sincere thanks to Andrew Ford (RIP) and Barbie.

=head1 LICENSE AND COPYRIGHT

Copyright 2016 A. Sinan Unur.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

