package OpenPlugin::Config::Perl;

# $Id: Perl.pm,v 1.14 2003/04/03 01:51:24 andreychek Exp $

use strict;
use base          qw( OpenPlugin::Config );
use Data::Dumper  qw( Dumper );
use Log::Log4perl  qw( get_logger );

$OpenPlugin::Config::Perl::VERSION = sprintf("%d.%02d", q$Revision: 1.14 $ =~ /(\d+)\.(\d+)/);

my $logger = get_logger();

sub get_config {
    my ( $self, $filename ) = @_;

    open( CONF, "$filename" ) || die "Cannot open ($filename) for reading";
    my ( $raw_config );
    {
        local $/ = undef;
        $raw_config = <CONF>;
    }
    close( CONF );

    my ( $data );
    {
        no strict 'vars';
        $data = eval $raw_config;
    }

    die "Cannot read configuration file!: $@" if ( $@ );

    if( $logger->is_debug ) {
        $logger->debug( "Data read in ok:\n", Dumper( $data ) );
    }

    return $data;
}



sub write {
    my ( $self, $filename ) = @_;
    $filename ||= join( '/', $self->{_m}{dir}, $self->{_m}{filename} );
    unless ( $filename ) {
        die "Cannot write configuration without a given filename!\n";
    }
    my ( $original_filename );
    if ( -f $filename ) {
        $original_filename = $filename;
        $filename = "$filename.new";
    }

    $logger->info( "Trying to save configuration to: ($filename)" );

    open( OUT, "> $filename" ) || die "Cannot open configuration file for writing: $!";
    print OUT "# Written by ", ref $self, " at ", scalar localtime, "\n\n";

    my %data = %{ $self };
    delete $data{_m};

    print OUT Data::Dumper->Dump( [ \%data ], [ 'data' ] );
    close( OUT );

    return $self;
}


1;

__END__

=pod

=head1 NAME

OpenPlugin::Config::Perl - Read configuration files written in Perl

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
 my $OP = OpenPlugin->new( config => { src => '/some/file/name.perl' } );

=head1 CONFIG OPTIONS

There is no need to define a driver for a config file.  However, within a
"perl" config file, you'll want to use the following syntax:

 $config = {
    Section => {
        one => {
            key     => 'value',
            another => 'value-another',
        }
        two => {
             key     => 'value-two',
             another => 'value-another-two',
        },
    },
 };

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
