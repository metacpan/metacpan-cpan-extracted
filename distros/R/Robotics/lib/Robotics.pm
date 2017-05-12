package Robotics;

use warnings;
use strict;

use Carp;
use Moose;
use MooseX::StrictConstructor;

#use Module::Pluggable::Object;  # maybe in future
use IO::Socket;
use YAML::XS;

our @Devices = (
    "Robotics::Tecan",
    "Robotics::Fialab"
);

has 'alias' => ( is => 'rw' );

has 'device' => ( is => 'rw' );

has 'devices' => ( 
    traits    => ['Hash'],
    is => 'rw', 
    isa       => 'HashRef[Str]',
    default   => sub { {} },
    );  

=head1 NAME

Robotics - Robotics hardware control and abstraction

=head1 VERSION

Version 0.23

=cut

our $VERSION = '0.23';


=head1 SYNOPSIS

Provides local communication to robotics hardware devices, related
peripherals, or network communication to these devices.  Also
provides a high-level, object oriented software interface to
abstract the low level robotics commands or low level robotics
hardware.  Environmental configuration is provided with a
configuration file in YAML format.  Allows other hardware device
drivers to be plugged into this module.

Simple examples are provided in the examples/ directory of the
distribution.



Nominclature note:  The name "Robotics" is used in full, rather than
"Robot", to distinguish mechanical robots from the many
internet-spidering software modules or software user agents commonly
(and erroneously) referred to as "robots".  Robotics has motors;
both the internet & software do not!

=cut

# Application should always perform device probing as first thing,
# so this is done as 'new'
sub BUILD {
    my ($self, $params) = @_;
    
    if ($self->device()) { 
        print STDOUT "Setting up ". $self->device(). "\n";
    }
    else { 
        $self->probe();
    }
}

sub probe { 
    my ($self, $params) = @_;
	print STDOUT "Searching for locally connected robotics devices\n";
	
	# Find Tecan Gemini, EVO, Genesis, ...

    my $this = shift;
    my %device_tree;
    $self->devices( \%device_tree );
    for my $class ( @Robotics::Devices ) {
        warn "Loading $class\n";
        if ( _try_load($class) ) {
            my $result = $class->probe();
            if (defined($result)) { 
                $self->devices->{$class} = $result;
                #$list{$class} = $result;
            }
        }
        else {
            die "should not get here; could not load ".
                "Robotics::Device subclass $class\n\n\n$@";
        }
    }

	# Add other robotics systems here
	
	# TODO Perhaps scan serial ports using Hardware::PortScanner
}

sub printDevices {
    my ($self, $params) = @_;
    my $yamlstring;
    if ($self->devices() ) { 
        $yamlstring = "\n".YAML::XS::Dump( $self->devices() );
    }
    return $yamlstring;   
}

sub findDevice { 
    my ($self, %params) = @_;
    my $root;
    my $want = $params{"product"} || return "";
    $root = $params{root};
    if (!$root) { 
        $root = $self->devices();
    }
    for my $key (keys %{$root}) {
        if ($key =~ /$want/) { 
            return $root->{$key};
        }
        else {
            my $val; 
            eval {
                if (keys %{$root->{$key}}) { 
                    $val = $self->findDevice(
                        root => $root->{$key},
                        %params);
                    if (defined($val)) { 
                        return $val;
                    }
                } 
            };
            if ($val) { 
                return $val;
            }
        }
    }
    return undef;
}

=secret 
# see example from File::ChangeNotify
my $finder =
    Module::Pluggable::Object->new( search_path => 'Robotics::Device' );

=cut

sub _try_load
{
    my $class = shift;

    eval { Class::MOP::load_class($class) };

    my $e = $@;
    die $e if $e && $e !~ /Can\'t locate/;

    return $e ? 0 : 1;
}

sub configure {
    my $self = shift;
    my $infile = shift || croak "cant open configuration file";
	
	open(IN, $infile) || return 1;
	my $s = do { local $/ = <IN> };
    $self->{CONFIG} = YAML::XS::Load($s) || return 2;
    
    warn "Configuring from $infile\n";
    my $root;
    my $model;
    for $root (keys %{$self->{CONFIG}}) {
        if ($root =~ m/tecan/i) { 
            warn "Configuring $root\n";
            for $model (keys %{$self->{CONFIG}->{$root}}) {
                warn "Configuring $model\n";
                if ($model =~ m/genesis/i) {
                    Robotics::Tecan::Genesis::configure(
                            $self, $self->{CONFIG}->{$root}->{$model});                        
                }
            }
        }
        elsif ($root =~ m/objects/i) { 
            die "Configuring $root\n";
            #Robotics::Objects::configure($self, $self->{CONFIG}->{$root});        
        }
    }
    return 0;
}


# Convert well string to well number
# Returns:  
# >0 well number if success
# 0 if error
# 
sub convertWellStringToNumber {
    my $s = $_[0];  # string
    my $size = $_[1] || 96;     # size of plate
    my $orient = $_[2] || "L";  # orientation of plate

    my $row = substr($s, 0, 1);
    my $col = substr($s, 1);
    $row = ord($row) - 64;
    if ($row < 0 || $row > 16) { 
        warn "not a well string, '$s'";
        return $s;
    }
    if ($col > 12 && $size == 96) { 
        warn "bad well string $s";
        return 0;
    }
    if ($col > 24 && $size == 384) { 
        warn "bad well string $s";
        return 0;
    }
    if ($size == 96) { 
        if ($orient eq "L") { 
            return ($col - 1) * 8 + $row;
        }
        elsif ($orient eq "P") { 
            return ($row - 1) * 12 + $col;
        }
        else {
            warn "bad well string $s\n";
            return 0;
        }
    }
    if ($size == 384) { 
        if ($orient eq "L") { 
            return ($col - 1) * 16 + $row;
        }
        elsif ($orient eq "P") { 
            return ($row - 1) * 24 + $col;
        }
        else {
            warn "bad well string $s\n";
            return 0;
        }
    }
}

# Convert well number to well (x,y) number
# Returns:  
# well array (x,y) if success
# 0 if error
# 
sub convertWellNumberToXY {
    return convertWellStringToXY(
            convertWellNumberToString(@_));
            
}

# Convert well string to well (x,y) number
# Returns:  
# well array (x,y) if success
# 0 if error
# 
sub convertWellStringToXY {
    my $s = $_[0];  # string
    my $size = $_[1] || 96;     # size of plate
    my $orient = $_[2] || "L";  # orientation of plate

    my $row = substr($s, 0, 1);
    my $col = substr($s, 1);
    $row = ord($row) - 64;
    if ($row < 0 || $row > 16) { 
        warn "not a well string, '$s'";
        return $s;
    }
    if ($col > 12 && $size == 96) { 
        warn "bad well string $s";
        return 0;
    }
    if ($col > 24 && $size == 384) { 
        warn "bad well string $s";
        return 0;
    }
    if ($size == 96) { 
        if ($orient eq "L") { 
            return ($col, $row);
        }
        elsif ($orient eq "P") { 
            return ($row, $col);
        }
        else {
            warn "bad well string $s\n";
            return 0;
        }
    }
    if ($size == 384) { 
        if ($orient eq "L") { 
            return ($col, $row);
        }
        elsif ($orient eq "P") { 
            return ($row, $col);
        }
        else {
            warn "bad well string $s\n";
            return 0;
        }
    }
}


# Convert well number to well string
# Returns:  
# string if success
# "" if error
# 
sub convertWellNumberToString {
    my $n = $_[0];  # number
    my $size = $_[1] || 96;     # size of plate
    my $orient = $_[2] || "L";  # Landscape or Portrait orientation

    my $col;
    my $row;
    my $s;
    if ($n < 1) { 
        warn "not a well number '$n'";
        return $n;
    }
    elsif ($n <= 96 && $size == 96) {
        if ($orient eq "P") { 
            $row = int(($n - 1) / 12) + 1;
            $col = ($n - (($col - 1) * 12));
        }
        elsif ($orient eq "L") { 
            $col = int(($n-1) / 8) + 1;
            $row = ($n - (($col - 1) * 8));
        }
        if ($row == 0) { $row = 8; }
        $s = chr(64+$row); # I bet no one has EBCDIC anymore
    }
    elsif ($n <= 384 && $size == 384) {
        if ($orient eq "P") { 
            $row = int(($n-1) / 24) + 1;
            $col = ($n - (($col - 1) * 24));
        }
        elsif ($orient eq "L") { 
            $col = int(($n-1) / 16) + 1;
            $row = ($n - (($col - 1) * 16));
        }
        if ($row == 0) { $row = 16; }
        $s = chr(64+$row);
    }
    else {
        warn "bad well number '$n'\n";
    }

    $s .= $col;

    return $s;
}

=head1 EXPORT

No exported functions

=head1 FUNCTIONS

=head2 new

Probes the local machine for connected hardware and returns the
device tree.


=head2 configure

Loads configuration data into memory.  

=item pathname of configuration file in YAML format

Returns:
0 if success, 
1 if file error,
2 if configuration error.


=head2 convertWellStringToNumber

Helper function.

Converts a microtiter plate well string (such as "B7") 
to a well number (such as 39), depending on 
plate size and plate orientation.  Well #1 is defined
as "A1".

Arguments:

=item Well String.  Should be in the range: "A1" .. [total size of plate]

=item Size of plate (number of wells).  Example: 96 or 384.
Default is 96.

=item Orientation of plate, either "L" for landscape 
or "P" for portrait (default "L").  Landscape means, when
looking at the plate on a table, the coordinates are defined 
for the long side running left-to-right, and the beginning
row is the furthest away. 

Returns:

=item Number > 0 (such as 43), if success.

=item 0, if error.

    
=head2 convertWellNumberToString

Helper function.

Converts a microtiter plate well number (such as 54) 
to a co-ordinate string (such as "D5"), depending on 
plate size and plate orientation.  Well #1 is defined
as "A1".

Arguments:

=item Well number.  Should be in the range: 1 .. [total size]

=item Size of plate (number of wells).  Example: 96 or 384.
Default is 96.

=item Orientation of plate, either "L" for landscape 
or "P" for portrait (default "L").  Landscape means, when
looking at the plate on a table, the coordinates are defined 
for the long side running left-to-right. 

Returns:

=item String (such as "A1"), if success.

=item Null string, if error.

    
=head2 convertWellStringToXY

Converts a microtiter plate well string (such as "E8") to an 
(x,y) coordinate array (such as (5,6)).

Arguments:

=item Well coordinate string.  The top left well is
defined as A1.

=item Size of plate (number of wells).  Example: 96 or 384.
Default is 96.

=item Orientation of plate, either "L" for landscape 
or "P" for portrait (default "L").  Landscape means, when
looking at the plate on a table, the coordinates are defined 
for the long side running left-to-right, and the beginning
row is the furthest away. 

Returns:

=item Array (such as (8,8)), if success.

=item 0, if error.

=head2 convertWellNumberToXY

Uses the other convertWell functions to convert a
well number (1 .. (total size)) into (x,y) coordinates.
See previous functions for args and return values.


=head1 AUTHOR

Jonathan Cline, C<< <jcline at ieee.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-robotics at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Robotics>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Robotics


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Robotics>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Robotics>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Robotics>

=item * Search CPAN

L<http://search.cpan.org/dist/Robotics/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Jonathan Cline.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

no Moose;

__PACKAGE__->meta->make_immutable;

1; # End of Robotics

__END__

