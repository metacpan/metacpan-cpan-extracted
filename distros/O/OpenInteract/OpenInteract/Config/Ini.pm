package OpenInteract::Config::Ini;

# $Id: Ini.pm,v 1.91 2003/01/24 13:03:47 lachoy Exp $

use strict;
use OpenInteract::Config qw( _w DEBUG );

$OpenInteract::Config::Ini::VERSION = sprintf("%d.%02d", q$Revision: 1.91 $ =~ /(\d+)\.(\d+)/);

# Stuff in metadata (_m):
#   sections (\@): all full sections, in the order they were read
#   comments (\%): key is full section name, value is comment scalar
#   filename ($):  file read from

sub new {
    my ( $pkg, $params ) = @_;
    my $class = ref $pkg || $pkg;
    my $self = bless( {}, $class );
    if ( $self->{_m}{filename} = $params->{filename} ) {
        $self->read_file( $self->{_m}{filename} );
    }
    return $self;
}


sub get {
    my ( $self, $section, @p ) = @_;
    my ( $sub_section, $param ) = ( $p[1] ) ? ( $p[0], $p[1] ) : ( undef, $p[0] );
    my $item = ( $sub_section )
                 ? $self->{ $section }{ $sub_section }{ $param }
                 : $self->{ $section }{ $param };
    return $item unless ( ref $item eq 'ARRAY' );
    return wantarray ? @{ $item } : $item->[0];
}


sub set {
    my ( $self, $section, @p ) = @_;
    my ( $sub_section, $param, $value ) = ( $p[2] ) ? ( $p[0], $p[1], $p[2] ) : ( undef, $p[0], $p[1] );
    return $self->{ $section }{ $sub_section }{ $param } = $value  if ( $sub_section );
    return $self->{ $section }{ $param } = $value
}


sub delete {
    my ( $self, $section, @p ) = @_;
    my ( $sub_section, $param ) = ( $p[1] ) ? ( $p[0], $p[1] ) : ( undef, $p[0] );
    delete $self->{ $section }{ $sub_section }{ $param } if ( $sub_section );
    delete $self->{ $section }{ $param };
}


sub sections {
    my ( $self ) = @_;
    return @{ $self->{_m}{order} };
}

########################################
# INPUT
########################################

sub read_file {
    my ( $self, $filename ) = @_;

    DEBUG && _w( 1, "Trying to read INI file ($filename)" );

    open( CONF, $filename ) || die "Cannot open ($filename) for reading: $!";

    # Temporary holding for comments

    my @comments = ();
    my ( $section, $sub_section );

    # Cycle through the file: skip blanks; accumulate comments for
    # each section; register section/subsection; add parameter/value

    while ( <CONF> ) {
        chomp;
        next if ( /^\s*$/ );
        if ( /^# Written by OpenInteract::Config::Ini at/ ) {
            my $dispose = <CONF>; # get rid of next blank line
            next;                 # ... and the current line
        }
        s/\s+$//;
        if ( /^\s*\#/ ) {
            push @comments, $_;
            next;
        }
        if ( /^\s*\[\s*(\S|\S.*\S)\s*\]\s*$/) {
            DEBUG && _w( 2, "Found section ($1)" );
            ( $section, $sub_section ) = $self->read_section_head( $1, \@comments );
            @comments = ();
            next;
        }
        my ( $param, $value ) = /^\s*([^=]+?)\s*=\s*(.*)\s*$/;
        DEBUG && _w( 2, "Setting ($param) to ($value)" );
        $self->read_item( $section, $sub_section, $param, $value );
    }
    close( CONF );
    $self->{_m}{filename} = $filename;
    return $self;
}


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
        $set_in->{ $param } = [ $existing, $value ];
    }
    else {
        $set_in->{ $param } = $value;
    }
}

########################################
# OUTPUT
########################################

sub write_file {
    my ( $self, $filename ) = @_;
    $filename ||= $self->{_m}{filename} || 'config.ini';
    my ( $original_filename );
    if ( -f $filename ) {
        $original_filename = $filename;
        $filename = "$filename.new";
    }

    # Set 'Global' items from the config object root

    foreach my $key ( @{ $self->{_m}{global} } ) {
        $self->{Global}{ $key } = $self->{ $key };
    }

    DEBUG && _w( 1, "--Writing INI to ($filename) (original: $original_filename)" );
    open( OUT, "> $filename" ) || die "Cannot write configuration to ($filename): $!";
    print OUT "# Written by ", ref $self, " at ", scalar localtime, "\n\n";
    foreach my $full_section ( @{ $self->{_m}{order} } ) {
        if ( $self->{_m}{comments}{ $full_section } ) {
            print OUT $self->{_m}{comments}{ $full_section }, "\n";
        }
        print OUT "[$full_section]\n",
                  $self->output_section( $full_section ),
                  "\n\n";
    }
    close( OUT );
    if ( $original_filename ) {
        unlink( $original_filename );
        rename( $filename, $original_filename );
    }
    return $filename;
}


sub output_section {
    my ( $self, $full_section ) = @_;
    my ( $section, $sub_section ) = split /\s+/, $full_section;
    my $show_from = ( $sub_section )
                      ? $self->{ $section }{ $sub_section }
                      : $self->{ $section };
    my @items = ();
    foreach my $key ( keys %{ $show_from } ) {
        if ( ref $show_from->{ $key } eq 'ARRAY' ) {
            foreach my $value ( @{ $show_from->{ $key } } ) {
                push @items, $self->show_item( $key, $value );
            }
        }
        else {
            push @items, $self->show_item( $key, $show_from->{ $key } );
        }
    }
    return join "\n", @items;
}


sub show_item { return join( ' = ', $_[1], $_[2] ) }

1;

__END__

=pod

=head1 NAME

OpenInteract::Config::Ini - Read/write INI-style (++) configuration files

=head1 SYNOPSIS

 my $config = OpenInteract::Config::Ini->new({ filename => 'myconf.ini' });
 print "Main database driver is:", $config->{db_info}{main}{driver}, "\n";
 $config->{db_info}{main}{username} = 'mariolemieux';
 $config->write_file;

=head1 DESCRIPTION

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

 [datasource]
 default_connection_db = main
 db                    = main
 db                    = other

 [db_info main]
 db_owner      =
 username      = captain
 password      = whitman
 dsn           = dbname=usa
 db_name       =
 driver_name   = Pg
 sql_install   =
 long_read_len = 65536
 long_trunc_ok = 0

 [db_info other]
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

Copyright (c) 2001-2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>

=cut
