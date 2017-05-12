package Template::Plugin::Imager;

use strict;

use Imager;
use Template::Plugin;

use base qw/ Template::Plugin /;

our $VERSION = 0.01;

sub new {
    my $class   = shift;
    my $context = shift;
    return Imager->new( @_ ) or $class->_throw( "Failed to create Imager\n" );
}

1;

__END__

=head1 NAME

Template::Plugin::Imager - Plugin interface to Imager

=head1 SYNOPSIS

    [% 
        FILTER null;
            USE im = Imager();
            im.read( 'file', 't/testimage.jpg' );
            im.convert( 'preset', 'noalpha' );
            thumb_im = im.scale( 'xpixels', 32 );
            thumb_im.write( 'file', 't/scaledimage.jpg' );
            im.read( 'file', 't/scaledimage.jpg' );
        END;
        im.getwidth();
    -%]

=head1 DESCRIPTION

This module provides an interface to the L<Imager> library. See L<Imager> for a complete description of the Imager library. 

Be aware that due to Template::Toolkit merging named parameters into hashrefs while Imager's methods expect hash parameters 
you have to pass parameters in list form! So when you'd normally do this:

    $im->read( file => 'imager.jpg' );

you'll have to call read() like this in your templates:

    imager.read( 'file', 'imager.jpg' );

=head1 AUTHOR

Tobias Kremer, L<tobias@funkreich.de>

=head1 SEE ALSO

L<Imager>, L<Template>

=head1 COPYRIGHT

Copyright (C) 2009 Tobias Kremer.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
