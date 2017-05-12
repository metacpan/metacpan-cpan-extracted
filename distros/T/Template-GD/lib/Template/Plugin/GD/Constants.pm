package Template::Plugin::GD::Constants;

use strict;
use warnings;
use GD qw(/^gd/ /^GD/);
use base 'Template::Plugin';

our $VERSION = sprintf("%d.%02d", q$Revision: 1.56 $ =~ /(\d+)\.(\d+)/);

sub new {
    my $class   = shift;
    my $context = shift;
    my $self    = { };
    bless $self, $class;

    #
    # GD has exported various gd* and GD_* contstants.  Find them.
    #
    foreach my $v ( keys(%Template::Plugin::GD::Constants::) ) {
        $self->{$v} = eval($v) if ( $v =~ /^gd/ || $v =~ /^GD_/ );
    }
    return $self;
}

1;

__END__

=head1 NAME

Template::Plugin::GD::Constants - Interface to GD module constants

=head1 SYNOPSIS

    [% USE gdc = GD.Constants %]

    # --> the constants gdc.gdBrushed, gdc.gdSmallFont, gdc.GD_CMP_IMAGE
    #     are now available

=head1 EXAMPLES

    [% FILTER null;
        USE gdc = GD.Constants;
        USE im  = GD.Image(200,100);
        black = im.colorAllocate(0  ,0,  0);
        red   = im.colorAllocate(255,0,  0);
        r = im.string(gdc.gdLargeFont, 10, 10, "Large Red Text", red);
        im.png | stdout(1);
       END;
    -%]

=head1 DESCRIPTION

The GD.Constants plugin provides access to the various GD module's
constants (such as gdBrushed, gdSmallFont, gdTransparent, GD_CMP_IMAGE
etc).  When GD.pm is used in perl it exports various contstants
into the caller's namespace.  This plugin makes those exported
constants available as template variables.

See L<Template::Plugin::GD::Image> and L<GD> for further examples and
details.

=head1 AUTHOR

Thomas Boutell wrote the GD graphics library.

Lincoln D. Stein wrote the Perl GD modules that interface to it.

Craig Barratt E<lt>craig@arraycomm.comE<gt> wrote the original GD
plugins for the Template Toolkit (2001).

Andy Wardley E<lt>abw@cpan.orgE<gt> extracted them from the TT core
into a separate distribution for TT version 2.15.

=head1 COPYRIGHT

Copyright (C) 2001 Craig Barratt E<lt>craig@arraycomm.comE<gt>, 2006
Andy Wardley E<lt>abw@cpan.orgE<gt>.

The GD.pm interface is copyright 1995-2000, Lincoln D. Stein.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin::GD>, L<Template::Plugin::GD::Image>, L<GD>

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
