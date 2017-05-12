package OpenPlugin::Config::Conf;

# $Id: Conf.pm,v 1.9 2003/04/03 01:51:24 andreychek Exp $

use strict;
use base            qw( OpenPlugin::Config );
use Log::Log4perl   qw( get_logger );
use Config::General();

$OpenPlugin::Config::Conf::VERSION = sprintf("%d.%02d", q$Revision: 1.9 $ =~ /(\d+)\.(\d+)/);

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

    my $data = Config::General->new( -ConfigFile     => $filename,
                                     #-LowerCaseNames => 1,
    );

    my %config = $data->getall;

    return \%config;
}


sub write {
    my ( $self, $filename ) = @_;
    $logger->info( "We don't support write yet" );
}


1;

__END__

=pod

=head1 NAME

OpenPlugin::Config::Conf - Read Config::General configuration files (similar to
Apache configs)

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
"conf" config file, you'll want to use the following syntax:

 <Section>
    <one>
        key     = value
        another = value-another
    </one>
    <two>
        key     = value-two
        another = value-another-two
    </two>
 </Section>

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<Config::General|Config::General>

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut
