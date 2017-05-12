package Template::Plugin::GD::Text::Align;

use strict;
use warnings;
use base qw( GD::Text::Align Template::Plugin );

our $VERSION = sprintf("%d.%02d", q$Revision: 1.56 $ =~ /(\d+)\.(\d+)/);

sub new {
    my $class   = shift;
    my $context = shift;
    my $gd      = shift;
    push(@_, %{pop(@_)}) if ( @_ & 1 && ref($_[@_-1]) eq "HASH" );
    return $class->SUPER::new($gd, @_);
}

sub set {
    my $self = shift;
    push(@_, %{pop(@_)}) if ( @_ & 1 && ref($_[@_-1]) eq "HASH" );
    $self->SUPER::set(@_);
}

1;

__END__

=head1 NAME

Template::Plugin::GD::Text::Align - Draw aligned strings in GD images

=head1 SYNOPSIS

    [% USE align = GD.Text.Align(gd_image); %]

=head1 EXAMPLES

    [% FILTER null;
        USE im  = GD.Image(100,100);
        USE gdc = GD.Constants;
        # allocate some colors
        black = im.colorAllocate(0,   0, 0);
        red   = im.colorAllocate(255,0,  0);
        blue  = im.colorAllocate(0,  0,  255);
        # Draw a blue oval
        im.arc(50,50,95,75,0,360,blue);

        USE a = GD.Text.Align(im);
        a.set_font(gdc.gdLargeFont);
        a.set_text("Hello");
        a.set(colour => red, halign => "center");
        a.draw(50,70,0);

        # Output image in PNG format
        im.png | stdout(1);
       END;
    -%]

=head1 DESCRIPTION

The GD.Text.Align plugin provides an interface to the GD::Text::Align
module. It allows text to be drawn in GD images with various
alignments and orientations.

See L<GD::Text::Align> for more details. See
L<Template::Plugin::GD::Text::Wrap> for a plugin that allow you to
render wrapped text in GD images.

=head1 AUTHOR

Thomas Boutell wrote the GD graphics library.

Lincoln D. Stein wrote the Perl GD modules that interface to it
and Martien Verbruggen wrote the GD::Text module.

Craig Barratt E<lt>craig@arraycomm.comE<gt> wrote the original GD
plugins for the Template Toolkit (2001).

Andy Wardley E<lt>abw@cpan.orgE<gt> extracted them from the TT core
into a separate distribution for TT version 2.15.

These modules are looking for a new maintainer.  Please contact 
Andy Wardley if you are willing to help out.

=head1 COPYRIGHT

Copyright (C) 2001 Craig Barratt E<lt>craig@arraycomm.comE<gt>,
2006 Andy Wardley E<lt>abw@cpan.orgE<gt>.

GD::Text is copyright 1999 Martien Verbruggen.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin::GD>, L<Template::Plugin::GD::Text>, L<Template::Plugin::GD::Text::Wrap>, L<GD|GD>

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
