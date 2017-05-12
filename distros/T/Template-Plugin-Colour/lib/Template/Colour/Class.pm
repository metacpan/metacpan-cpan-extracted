package Template::Colour::Class;

use Badger::Class
    debug    => 0,
    uber     => 'Badger::Class',
    constant => {
        CONSTANTS => 'Template::Colour::Constants',
    };

1;

__END__

=head1 NAME

Template::Colour::Class - class metaprogramming module for Template::Colour

=head1 SYNOPSIS

An example showing how L<Template::Colour::RGB> uses
C<Template::Colour::Class>:

    package Template::Colour::RGB;

    use Template::Colour::Class
        version   => 2.09,
        debug     => 0,
        base      => 'Template::Colour',
        constants => 'ARRAY HASH SCHEME :RGB',
        utils     => 'is_object',
        as_text   => 'HTML',
        is_true   => 1,
        throws    => 'Colour.RGB';

=head1 DESCRIPTION

This module is a simple subclass of L<Badger::Class> which other 
L<Template::Colour> modules use to add a bit of class metaprogramming 
magic.

It can be used in exactly the same way as L<Badger::Class> to help with the
definition of various class items. For example, the L<Template::Colour::RGB>
modules uses it like this:

    package Template::Colour::RGB;

    use Template::Colour::Class
        version   => 2.09,
        debug     => 0,
        base      => 'Template::Colour',
        constants => 'ARRAY HASH SCHEME :RGB',
        utils     => 'is_object',
        as_text   => 'HTML',
        is_true   => 1,
        throws    => 'Colour.RGB';

The only difference between C<Template::Colour::Class> and L<Badger::Class>
is that the C<constants> are loaded from L<Template::Colour::Constants>.
This is a subclass of L<Badger::Constants> which adds constant definitions
used by the colour modules.

=head1 AUTHOR

Andy Wardley E<lt>abw@cpan.orgE<gt>, L<http://wardley.org>

=head1 COPYRIGHT

Copyright (C) 2006-2012 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Badger::Class>


