package Template::Colour::Constants;

use Badger::Class
    debug    => 0,
    base     => 'Badger::Constants',
    constant => {
        RED    => 0,
        GREEN  => 1,
        BLUE   => 2,
        HUE    => 0,
        SAT    => 1,
        VAL    => 2,
        SCHEME => 3,
        BLACK  => '#000000',
        WHITE  => '#FFFFFF',
    },
    exports => {
        any  => 'SCHEME BLACK WHITE',
        tags => {
            RGB => 'RED GREEN BLUE',
            HSV => 'HUE SAT VAL',
        },
    };

1;

__END__

=head1 NAME

Template::Colour::Constants - constants used by L<Template::Colour> modules

=head1 SYNOPSIS

    use Template::Colour::RGB;
    use Template::Colour::Constants ':RGB';

    my $rgb = Template::Colour::RGB->new('#ff7f00');

    # RED, GREEN and BLUE are the slot offsets in RGB colours
    print $rgb->[RED];      # 255
    print $rgb->[GREEN];    # 127
    print $rgb->[BLUE];     #   0

=head1 DESCRIPTION

This module is a simple subclass of L<Badger::Constants> which defines
some additional constants used by the L<Template::Colour> modules.

=head1 CONSTANTS

You can export any of these constants by name.  e.g.

    use Template::Colour::Constants 'RED GREEN BLUE';

=head2 RED 

Slot offset for red component in RGB colours (0).

=head2 GREEN

Slot offset for green component in RGB colours (1).

=head2 BLUE

Slot offset for blue component in RGB colours (2).

=head2 HUE

Slot offset for hue component in HSV colours (0).

=head2 SAT

Slot offset for saturation component in HSV colours (1).

=head2 VAL

Slot offset for value component in HSV colours (2).

=head2 SCHEME

Slot offset for any additional colour scheme defined for a colour (3).

=head2 BLACK

Hex representation of black: C<#000000>.  How much more black could this be?
And the answer is none, none more black.

=head2 WHITE

Hex representation of white: C<#FFFFFF>. 

=head1 CONSTANT SETS

You can export related constants by specify the name of a constant tag set.
e.g.

    use Template::Colour::Constants ':RGB';

=head2 :RGB

RED, GREEN and BLUE.

=head2 :HSV

HUE, SAT and VAL.

=head1 AUTHOR

Andy Wardley E<lt>abw@cpan.orgE<gt>, L<http://wardley.org>

=head1 COPYRIGHT

Copyright (C) 2006-2012 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Colour>, L<Badger::Constants>.
