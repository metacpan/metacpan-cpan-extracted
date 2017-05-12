package Template::Plugin::Color::HSV;

use Template::Colour::Class
    base    => 'Template::Plugin::Colour::HSV',
    throws  => 'Color.HSV';

our $VERSION = 2.10;

1;

__END__

=head1 NAME

Template::Plugin::Color - Template plugin for color manipulation

=head1 SYNOPSIS

    [% USE col = Color.HSV(50, 255, 128) %]

    [% col.hue %]                          # 50
    [% col.sat %] / [% col.saturation %]   # 255
    [% col.val %] / [% col.value %]        # 128

=head1 DESCRIPTION

The C<Template::Plugin::Color::HSV> plugin module creates an object that
represents a color in the HSV (hue, saturation, value) colour space.

It is implemented as a subclass of L<Template::Plugin::Colour::HSV> (note
the spelling difference) and is provided as a convenience for
Americans and other international users who spell 'C<Colour>' as 'C<Color>'.

Please see the documentation for L<Template::Plugin::Colour::HSV> for
further details.  Wherever you see 'C<Colour>', you can safely write it
as 'C<Color>'.

=head1 AUTHOR

Andy Wardley E<lt>abw@cpan.orgE<gt>, L<http://wardley.org>

=head1 COPYRIGHT

Copyright (C) 2006-2012 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin::Colour::HSV>


