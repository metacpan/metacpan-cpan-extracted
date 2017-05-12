use strict;
use warnings;

package Pod::Weaver::Section::WarrantyDisclaimer;
{
  $Pod::Weaver::Section::WarrantyDisclaimer::VERSION = '0.121290';
}

use Moose;
with 'Pod::Weaver::Role::Section';
# ABSTRACT: Add a standard DISCLAIMER OF WARRANTY section (for your Perl module)

use Moose::Autobox;

use Pod::Elemental::Element::Pod5::Ordinary;
use Pod::Elemental::Element::Nested;


sub warranty_section_title {
    return 'DISCLAIMER OF WARRANTY';
}


sub warranty_text {
    return <<'EOF';
BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.
EOF
}


sub weave_section {
    my ($self, $document) = @_;

    my $warranty_para = Pod::Elemental::Element::Nested->new({
        command  => 'head1',
        content  => $self->warranty_section_title(),
        children => [
            Pod::Elemental::Element::Pod5::Ordinary->new({
                content => $self->warranty_text()
            }),
        ],
    });

    $document->children->push($warranty_para);
}

1;



=pod

=head1 NAME

Pod::Weaver::Section::WarrantyDisclaimer - Add a standard DISCLAIMER OF WARRANTY section (for your Perl module)

=head1 VERSION

version 0.121290

=head1 SYNOPSIS

In F<weaver.ini>, probably near the end:

    [WarrantyDisclaimer]

=head1 OVERVIEW

This section plugin will add a standard B<DISCLAIMER OF WARRANTY>
section to your POD. See the bottom of this module's documentation for
the content of this section.

Note that there are several other warranty texts available that
correspond to the text used in various open-source licenses, such as
L<Pod::Weaver::Section::WarrantyDisclaimer::GPL2>. If your code's
license has a specific warranty clause, you should try to use the
corresponding module, so that the warranty text in your modules will
match that of the license. If a warranty disclaimer module is not
provided for your license of choice, you can easily create one by
subclassing this class and overriding the methods
C<warranty_section_title> and C<warranty_text>. Alternatively, you can
simply use C<[WarrantyDisclaimer::Custom]> and then use the C<title>
and C<text> options to specify your custom warranty.

=head1 METHODS

=head2 warranty_section_title

This method provides the text to be used as the title of the warranty
section. It can be overridden by subclasses to provide different
warranties.

=head2 warranty_text

This method provides the text to be used in the warranty section. It
can be overridden by subclasses to provide different warranties.

=for Pod::Coverage weave_section

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AUTHOR

Ryan C. Thompson <rct@thompsonclan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ryan C. Thompson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut


__END__
