package Template::Plugin::GD::Text::Wrap;

use strict;
use warnings;
use base qw( GD::Text::Wrap Template::Plugin );

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

Template::Plugin::GD::Text::Wrap - Break and wrap strings in GD images

=head1 SYNOPSIS

    [% USE align = GD.Text.Wrap(gd_image); %]

=head1 EXAMPLES

    [% FILTER null;
        USE gd  = GD.Image(200,400);
        USE gdc = GD.Constants;
        black = gd.colorAllocate(0,   0, 0);
        green = gd.colorAllocate(0, 255, 0);
        txt = "This is some long text. " | repeat(10);
        USE wrapbox = GD.Text.Wrap(gd,
         line_space  => 4,
         color       => green,
         text        => txt,
        );
        wrapbox.set_font(gdc.gdMediumBoldFont);
        wrapbox.set(align => 'center', width => 160);
        wrapbox.draw(20, 20);
        gd.png | stdout(1);
      END;
    -%]

    [% txt = BLOCK -%]
    Lorem ipsum dolor sit amet, consectetuer adipiscing elit,
    sed diam nonummy nibh euismod tincidunt ut laoreet dolore
    magna aliquam erat volutpat.
    [% END -%]
    [% FILTER null;
        #
        # This example follows the example in GD::Text::Wrap, except
        # we create a second image that is a copy just enough of the
        # first image to hold the final text, plus a border.
        #
        USE gd  = GD.Image(400,400);
        USE gdc = GD.Constants;
        green = gd.colorAllocate(0, 255, 0);
        blue  = gd.colorAllocate(0, 0, 255);
        USE wrapbox = GD.Text.Wrap(gd,
         line_space  => 4,
         color       => green,
         text        => txt,
        );
        wrapbox.set_font(gdc.gdMediumBoldFont);
        wrapbox.set(align => 'center', width => 140);
        rect = wrapbox.get_bounds(5, 5);
        x0 = rect.0;
        y0 = rect.1;
        x1 = rect.2 + 9;
        y1 = rect.3 + 9;
        gd.filledRectangle(0, 0, x1, y1, blue);
        gd.rectangle(0, 0, x1, y1, green);
        wrapbox.draw(x0, y0);
        nx = x1 + 1;
        ny = y1 + 1;
        USE gd2 = GD.Image(nx, ny);
        gd2.copy(gd, 0, 0, 0, 0, x1, y1);
        gd2.png | stdout(1);
       END;
    -%]

=head1 DESCRIPTION

The GD.Text.Wrap plugin provides an interface to the GD::Text::Wrap
module. It allows multiples line of text to be drawn in GD images with
various wrapping and alignment.

See L<GD::Text::Wrap> for more details. See
L<Template::Plugin::GD::Text::Align> for a plugin that allow you to
draw text with various alignment and orientation.

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

L<Template::Plugin::GD>, L<Template::Plugin::GD::Text>, L<GD|GD>

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
