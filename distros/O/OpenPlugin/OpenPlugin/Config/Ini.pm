package OpenPlugin::Config::Ini;

# $Id: Ini.pm,v 1.14 2003/04/03 01:51:24 andreychek Exp $

use strict;
use base            qw( OpenPlugin::Config );
use Log::Log4perl   qw( get_logger );

$OpenPlugin::Config::Ini::VERSION = sprintf("%d.%02d", q$Revision: 1.14 $ =~ /(\d+)\.(\d+)/);

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

    open( CONF, $filename ) || die "Cannot open ($filename) for reading: $!";

    # Temporary holding for comments

    my @comments = ();
    my ( $section, $sub_section );

    # Cycle through the file: skip blanks; accumulate comments for
    # each section; register section/subsection; add parameter/value

    while ( <CONF> ) {
        chomp;
        next if ( /^\s*$/ );
        s/\s+$//;
        if ( /^\s*\#/ ) {
            push @comments, $_;
            next;
        }
        if ( /^\s*\[\s*(\S|\S.*\S)\s*\]\s*$/) {
            $logger->info( "Found section ($1)" );
            ( $section, $sub_section ) = $self->read_section_head( lc $1, \@comments );
            @comments = ();
            next;
        }
        my ( $param, $value ) = /^\s*([^=]+?)\s*=\s*(.*)\s*$/;
        $logger->debug( "Setting ($param) to ($value) in ($section)($sub_section)" );
        $self->read_item( $section, $sub_section, $param, $value );
    }
    close( CONF );

    return {};
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

    # Copy all data to a hash we can manipulate separately (allows us
    # to add new sections, etc.

    my %data = %{ $self };
    delete $data{_m};

    # Set 'Global' items from the config object root

    foreach my $key ( keys %data ) {
        next if ( ref $key );
        $data{Global}{ $key } = $data{ $key };
        delete $data{ $key };
    }

    $logger->info( "--Writing INI to ($filename) (original: $original_filename)" );
    open( OUT, "> $filename" ) || die "Cannot write configuration to ($filename): $!";
    print OUT "# Written by ", ref $self, " at ", scalar localtime, "\n";
    foreach my $full_section ( @{ $self->{_m}{order} } ) {
        print OUT $self->{_m}{comments}{ $full_section }, "\n",
                  "[$full_section]\n",
                  $self->output_section( \%data, $full_section ),
                  "\n\n";
    }

    # Now, find all the items that are left and output them

    foreach my $section_head ( keys %data ) {

        # First, display any subsections -- the process of outputting
        # deletes it from %data

        foreach my $sub_item ( keys %{ $data{ $section_head } } ) {
            if ( ref $data{ $section_head }->{ $sub_item } eq 'HASH' ) {
                my $full_section_name = "$section_head $sub_item";
                $self->output_section( \%data, $full_section_name );
                push @{ $self->{_m}{order} }, $full_section_name;
            }
        }

        # Now, if there are any items left in $data{ $section_head },
        # output THAT

        if ( keys %{ $data{ $section_head } } ) {
            $self->output_section( \%data, $section_head );
            push @{ $self->{_m}{order} }, $section_head;
        }
    }

    close( OUT );
    if ( $original_filename ) {
        unlink( $original_filename );
        rename( $filename, $original_filename );
    }
    return $filename;
}


########################################
# INTERNAL: INPUT
########################################



sub read_section_head {
    my ( $self, $full_section, $comments ) = @_;
    push @{ $self->{_m}{order} }, $full_section;
    $self->{_m}{comments}{ $full_section } = join "\n", @{ $comments };
    if ( $full_section =~ /^(\w+)\s+(\w+)$/ ) {
        my ( $section, $sub_section ) = ( $1, $2 );
        $self->{ $section }{ $sub_section } ||= {};
        return ( $section, $sub_section );
    }
    $self->{ $full_section } ||= {};
    return ( $full_section, undef );
}


sub read_item {
    my ( $self, $section, $sub_section, $param, $value ) = @_;

    # Special case -- 'Global' stuff goes in the config object root

    if ( $section eq 'Global' ) {
        push @{ $self->{_m}{global} }, $param;
        $self->set_value( $self, $param, $value );
        return;
    }

    return ( $sub_section )
             ? $self->set_value( $self->{ $section }{ $sub_section }, $param, $value )
             : $self->set_value( $self->{ $section }, $param, $value );
}


sub set_value {
    my ( $self, $set_in, $param, $value ) = @_;
    my $existing = $set_in->{ $param };
    if ( $existing and ref $set_in->{ $param } eq 'ARRAY' ) {
        push @{ $set_in->{ $param } }, $value;
    }
    elsif ( $existing ) {
        $set_in->{ $param } = ();
        push @{ $set_in->{ $param } }, $existing, $value
    }
    else {
        $set_in->{ $param } = $value;
    }
}

########################################
# INTERNAL: OUTPUT
########################################

sub output_section {
    my ( $self, $data, $full_section ) = @_;
    my ( $section, $sub_section ) = split /\s+/, $full_section;
    my $show_from = ( $sub_section )
                      ? $data->{ $section }{ $sub_section }
                      : $data->{ $section };
    my @items = ();
    foreach my $key ( keys %{ $show_from } ) {
        if ( ref $show_from->{ $key } eq 'ARRAY ' ) {
            foreach my $value ( @{ $show_from->{ $key } } ) {
                push @items, $self->show_item( $key, $value );
            }
        }
        else {
            push @items, $self->show_item( $key, $show_from->{ $key } );
        }
    }

    # Clear out the data

    if ( $sub_section ) { delete $data->{ $section }{ $sub_section } }
    else                { delete $data->{ $section } }

    return join "\n", @items;
}

sub show_item { return join( ' = ', $_[1], $_[2] ) }

1;

__END__

=pod

=head1 NAME

OpenPlugin::Config::Ini - Read Ini style configuration files

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
 my $OP = OpenPlugin->new( config => { src => '/some/file/name.ini' } );

=head1 CONFIG OPTIONS

There is no need to define a driver for a config file.  However, within a
"ini" config file, you'll want to use the following syntax:

This is a very simple implementation of a configuration file
reader/writer that preserves comments and section order, enables
multivalue fields and one or two-level sections.

Yes, there are other configuration file modules out there to
manipulate INI-style files. But this one takes several features from
them while providing a very simple and uncluttered interface.

=over 4

=item *

From L<Config::IniFiles|Config::IniFiles> we take comment preservation
and the idea that we can have multi-level sections like:

 [Section subsection]

=item *

From L<Config::Ini|Config::Ini> and L<AppConfig|AppConfig> we borrow
the usage of multivalue keys:

 item = first
 item = second

=back

=head2 Example

Given the following configuration in INI-style:

 [datasource main]
 type          = DBI
 db_owner      =
 username      = captain
 password      = whitman
 dsn           = dbname=usa
 db_name       =
 driver_name   = Pg
 sql_install   =
 long_read_len = 65536
 long_trunc_ok = 0

 [datasource other]
 type          = DBI
 db_owner      =
 username      = tyger
 password      = blake
 dsn           = dbname=britain
 db_name       =
 driver_name   = Pg
 sql_install   =
 long_read_len = 65536
 long_trunc_ok = 0

You would get the following Perl data structure:

 $config = {
   datasource => {
      default_connection_db => 'main',
      db                    => [ 'main', 'other' ],
   },
   db_info => {

      main => {
           db_owner      => undef,
           username      => 'captain',
           password      => 'whitman',
           dsn           => 'dbname=usa',
           db_name       => undef,
           driver_name   => 'Pg',
           sql_install   => undef,
           long_read_len => '65536',
           long_trunc_ok => '0',
      },

      other => {
           db_owner      => undef,
           username      => 'tyger',
           password      => 'blake',
           dsn           => 'dbname=britain',
           db_name       => undef,
           driver_name   => 'Pg',
           sql_install   => undef,
           long_read_len => '65536',
           long_trunc_ok => '0',
      },
   },
 };


=head2 'Global' Key

Anything under the 'Global' key in the configuration will be available
under the configuration object root. For instance:

 [Global]
 DEBUG = 1

will be available as:

 $CONFIG->{DEBUG}

=head1 SEE ALSO

L<AppConfig|AppConfig>

L<Config::Ini|Config::Ini>

L<Config::IniFiles|Config::IniFiles>

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

Chris Winters <chris@cwinters.com>

=cut
