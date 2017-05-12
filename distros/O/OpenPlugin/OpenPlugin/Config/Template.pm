package OpenPlugin::Config::Template;

# $Id: Template.pm,v 1.12 2003/04/03 01:51:24 andreychek Exp $

# This is a template for a config file driver.  You can use this as a base for
# creating new drivers that read in configuration information.  The only two
# subs you have to create are 'read' and 'write'.  Much of the rest of the
# functionality can be found in OpenPlugin::Config.  However, if the methods
# used in there don't suit your needs, feel free to overload them here.

use strict;
use base          qw( OpenPlugin::Config );
use Data::Dumper  qw( Dumper );

$OpenPlugin::Config::Template::VERSION = sprintf("%d.%02d", q$Revision: 1.12 $ =~ /(\d+)\.(\d+)/);

# This sub is called when OpenPlugin is ready to read in the configuration.
# Once this is called, it's your responsibility to open the configuration data,
# and return it as a hash reference to the calling program
sub get_config {
    my ( $self, $filename ) = @_;

    # Read/Parse Config File ($filename)

    # Return hashref
    return \%data;
}


# This sub is called when OpenPlugin would like to write out the configuration
# data is has to a file.  You are again passed the $self hashref, and possibly
# filename to write too.
sub write {
    my ( $self, $filename ) = @_;

    # If we weren't given a filename, use the same one we read the data from
    $filename ||= join( '/', $self->{_m}{dir}, $self->{_m}{filename} );
    unless ( $filename ) {
        die "Cannot write configuration without a given filename!\n";
    }

    # Save the configuration data found in $self
}


1;

__END__

=pod

=head1 NAME

OpenPlugin::Config::Template - Sample template for creating a OpenPlugin Config
driver

=head1 PARAMETERS

=over 4

=item * src

Path and filename to the config file.  If you don't wish to pass this parameter
into OpenPlugin, you may instead set the package variable:

$OpenPlugin::Config::Src = /path/to/config.conf

=item * config

Config passed in as a hashref

=item * dir

Directory to look for the config file in.  This is usually unnecessary, as most
will choose to make this directory part of the 'src' parameter.

=item * type

Driver to use for the config file.  In most cases, the driver is determined by
the extension of the file.  If that may be unreliable for some reason, you can
use this parameter.

=back

 Example:
 my $OP = OpenPlugin->new( config => { src => '/some/file/name.conf' } );

=head1 CONFIG OPTIONS

There is no need to define a driver for a config file.  However, within a
"<template>" config file, you'll want to use the following syntax:

# List syntax for your config file type

=head1 TO DO

Nothing known.

=head1 BUGS

None known.

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut
