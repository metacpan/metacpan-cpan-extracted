package OpenPlugin::Config::XML;

# $Id: XML.pm,v 1.17 2003/04/03 01:51:24 andreychek Exp $

use strict;
use base            qw( OpenPlugin::Config );
use Log::Log4perl   qw( get_logger );
use OpenThought::XML2Hash();

$OpenPlugin::Config::XML::VERSION = sprintf("%d.%02d", q$Revision: 1.17 $ =~ /(\d+)\.(\d+)/);

my $logger = get_logger();

# Stuff in metadata (_m):
#   sections (\@): all full sections, in the order they were read
#   comments (\%): key is full section name, value is comment scalar
#   filename ($):  file read from


########################################
# PUBLIC INTERFACE
########################################


sub get_config {
    my ( $self, $filename ) = @_;

    return OpenThought::XML2Hash::xml2hash( $filename );

}


sub write {
    my ( $self, $filename ) = @_;
    $logger->warn( "We don't support write yet" );
}


1;

__END__

=pod

=head1 NAME

OpenPlugin::Config::XML - Read XML configuration files

=head1 PARAMETERS

=over 4

=item * src

Path and filename to the config file.  If you don't wish to pass this parameter
into OpenPlugin, you may instead set the package variable:

$OpenPlugin::Config::Src = /path/to/config.xml

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
 my $OP = OpenPlugin->new( config => { src => '/some/file/name.xml' } );

=head1 CONFIG OPTIONS

There is no need to define a driver for a config file.  However, within a
"xml" config file, you'll want to use the following syntax:

 <config>
    <section>
        <one>
            <param name="key" value="value">
            <param name="another" value="value-another">
        </one>
        <two>
            <param name="key" value="value-two">
            <param name="another" value="value-another-two">
        </two>
    </section>
 </config>

=head1 SEE ALSO

L<OpenThought::XML2Hash|OpenThought::XML2Hash>
L<XML::Parser::Expat|XML::Parser::Expat>
L<XML::Parser|XML::Parser>

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut
