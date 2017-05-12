package NetStumbler::MapPoint;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

use Carp qw(cluck croak);
use Win32::OLE qw(in with);
use Win32::OLE::Const;
our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS);
#
# Exported Functions by request
#
@EXPORT_OK = qw(
hasLibrary
initializeMap
newMap
loadMap
showMap
saveMap
addPushpinSet
getPushpinSet
delPushpinSet
gotoPushpinSet
addSymbol
delSymbol
getLocation
gotoLocation
addPushpin
findPushpin
setPushpinProperty
addPushpinToSet
delPushpin
setSaveFlag
selectItem
findCity);  # symbols to export on request

our $VERSION = '0.02';


# Preloaded methods go here.
=head1 Object Methods

=head2 new()

Returns a new Wap object. NOTE: this method may take some time to execute
as it loads the list into memory at construction time

=cut

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    $Win32::OLE::Warn = 3; # die on errors...
    $self->{hasMappoint} = 1;
    $self->{mapPoint} = undef;
    $self->{initialized} = 0;
    bless ($self, $class);
    eval
    {
        use Win32::OLE::Const 'Microsoft MapPoint';
    };
    if($@)
    {
        $self->{hasMappoint} = 0;
    }
    return $self;
}

=head2 hasLibrary()

Params:
	none
Returns:
	true if library exists
Example:
	if($obj->hasLibrary)
	{
		# do something here
	}

=cut

sub hasLibrary
{
    my $self = shift;
    return $self->{hasMappoint};
}

=head2 initializeMap()

Params:
	none
Returns:
	none
Example:
	$obj->initializeMap

=cut

sub initializeMap
{
    my $self = shift;
    if($self->{hasMappoint})
    {
        # grab the running instance or create an instance
        $self->{mapPoint} = Win32::OLE->GetActiveObject('MapPoint.Application') ||
        Win32::OLE->new('MapPoint.Application','Quit');
        $self->{initialized} = 1;
    }
}

=head2 newMap()

create a new empty map
Params:
	none
Returns:
	none
Example:
        $obj->newMap;

=cut

sub newMap
{
    my $self = shift;
    if($self->{hasMappoint})
    {
        unless($self->{initialized})
        {
            $self->initializeMap();
        }
        $self->{mapPoint}->NewMap();
    }
}

=head2 loadMap($file)

Open an existing map
Params:
	-string map file to load
Returns:
	none croaks on failure
Example:
	$obj->loadMap($file

=cut

sub loadMap
{
    my $self = shift;
    if($self->{hasMappoint})
    {
        unless($self->{initialized})
        {
            $self->initializeMap();
        }
        my $file = shift;
        if(-e $file)
        {
            $self->{mapPoint}->OpenMap($file,1);
        }
        else
        {
            croak "Map $file did not exist!";
        }
    }
}

=head2 showMap()

Makes the map visible on screen
Params:
	none
Returns:
	none
Example:
	$obj->showMap

=cut

sub showMap
{
    my $self = shift;
    if($self->{hasMappoint})
    {
        $self->{mapPoint}->{UserControl} = 0;
        $self->{mapPoint}->{Visible} = 1;
        $self->{mapPoint}->Activate();
    }
}

=head2 saveMap([$filename])

If a filename is passed in, it gets saved as such, otherwise it is the same
as using File-->Save
Params:
	optional filename to save the map as
Returns:
	none
Example:
        $obj->saveMap;
        # save the map to file x
        $obj->saveMap($x);

=cut

sub saveMap
{
    my $self = shift;
    if($self->{hasMappoint})
    {
        my $file = shift;
        unless($file)
        {
            $self->{mapPoint}->{ActiveMap}->Save;
        }
        else
        {
            $self->{mapPoint}->{ActiveMap}->SaveAs($file);
        }
    }
}

=head2 setSaveFlag()

Toggle the save flag on the map, doing so will make mappoint not prompt on exit
to save the current map
Params:
	none
Returns:
	none
Example:
	$obj->setSaveFlag

=cut

sub setSaveFlag
{
    my $self = shift;
    if($self->{hasMappoint})
    {
        $self->{mapPoint}->{ActiveMap}->{Saved} = -1;
    }
}

=head2 selectItem($item)

Transparent call to select on the come object

Params:
	object An object retrieved from a create/load/get call in this library
Returns:
	none
Example:
        my $pushpin = $obj->addPushPin("pin name");
	$obj->selectItem($pushpin);

=cut

sub selectItem
{
    my $self = shift;
    if($self->{hasMappoint})
    {
        my $item = shift;
        $item->Select();
    }
}

=head2 addPushpinSet($name)

If the set already exits this method will return the existing set
Params:
	-string name of this pushpinset
Returns:
	the created pushpinset
Example:
        my $set = $obj->addPushPinSet("test set");

=cut

sub addPushpinSet
{
    my $self = shift;
    if($self->{hasMappoint})
    {
        my $setName = shift;
        # Try to lookup this dataset
        my $pp = undef;
        eval
        {
            $pp = $self->{mapPoint}->{ActiveMap}->{DataSets}->Item($setName);
        };
        if($@)
        {
            $pp = $self->{mapPoint}->{ActiveMap}->{DataSets}->AddPushPinSet($setName);
        }
        return $pp;
    }
}

=head2 gotoPushpinSet($myset)

This will cause the activemap to zoom to the given pushpin set
Params:
	object - A pushpinset retrieved with get or add
Returns:
	none
Example:
        $obj->gotoPushpinSet($myset);

=cut

sub gotoPushpinSet
{
    my $self = shift;
    if($self->{hasMappoint})
    {
        my $set = shift;
        # Try to lookup this dataset
        eval
        {
            $set->ZoomTo;
        };
    }
}

=head2 getPushpinSet($name)

Params:
	string Name of the set
Returns:
	the set if found
Example:
        $obj->getPushpinSet("bogus");

=cut

sub getPushpinSet
{
    my $self = shift;
    if($self->{hasMappoint})
    {
        my $setName = shift;
        # Try to lookup this dataset
        my $pp;
        eval
        {
            $pp = $self->{mapPoint}->{ActiveMap}->{DataSets}->Item($setName);
        };
        return $pp;
    }
}

=head2 delPushpinSet()

Params:
	string Name of pushpin set
Returns:
	none
Example:
        $obj->delPushpinSet("Bogus");

=cut

sub delPushpinSet
{
    my $self = shift;
    if($self->{hasMappoint})
    {
        my $setName = shift;
        # Try to lookup this dataset
        eval
        {
            $self->{mapPoint}->{ActiveMap}->{DataSets}->Item($setName).Delete();
        };
    }
}

=head2 addSymbol($name,$file)

Params:
	-string Name of symbol
        -string File to load symbol from (windows icon file)
Returns:
	symbol id or 0
Example:
        $obj->addSymbol("goodStrength",$file);

=cut

sub addSymbol
{
    my $self = shift;
    if($self->{hasMappoint})
    {
        my $name = shift;
        my $file = shift;
        my $symbol;
        eval
        {
            $symbol = $self->{mapPoint}->{ActiveMap}->{Symbols}->Add($file);
        };
        if($@)
        {
            return 0;
        }
        else
        {
            return $symbol->{ID};
        }
    }
}

=head2 hasSymbol($symbolname)

Params:
	-string name of the symbol
Returns:
	true if symbol exists
Example:
	if($obj->hasSymbol($sym)
	{
		# do something here
	}

=cut

sub hasSymbol
{
    my $self = shift;
    if($self->{hasMappoint})
    {
        my $name = shift;
        my $symbol;
        eval
        {
            $symbol = $self->{mapPoint}->{ActiveMap}->{Symbols}->Item($name);
        };
        if($symbol)
        {
            return "1";
        }
        return undef;
    }
}


=head2 delSymbol($sym)

Params:
	-stirng name of symbol to delete
Returns:
	none
Example:
        $obj->delSymbol("test");

=cut

sub delSymbol
{
    my $self = shift;
    if($self->{hasMappoint})
    {
        my $name = shift;
        eval
        {
            $self->{mapPoint}->{ActiveMap}->{Symbols}->Item($name).Delete();
        };
    }
}

=head2 getLocation($lon,$lat,[$alt])

numbers need to be in std GIS format i.e.
N 86.0000 should be 86.00000
S 86.0000 should be -86.0000
E 37.0000 should be 37.00000
W 37.0000 should be -37.0000

Params:
	-double Longitude
        -double Latitude
        -double Altitude [Optional]
Returns:
	location object if the location is valid or undef
Example:
        $loc = $obj->getLocation(23.000000,56.000000,50);

=cut

sub getLocation
{
    my $self = shift;
    if($self->{hasMappoint})
    {
        my ($lat,$lon,$alt) = @_;
        my $location = undef;
        eval
        {
            if($alt)
            {
                $location = $self->{mapPoint}->{ActiveMap}->GetLocation($lat,$lon,$alt);
            }
            else
            {
                $location = $self->{mapPoint}->{ActiveMap}->GetLocation($lat,$lon);
            }
        };
        return $location;
    }
}

=head2 gotoLocation($locationObject)

Params:
	-object a Location object
Returns:
        none
Example:
        $obj->gotoLocation($loc);

=cut

sub gotoLocation
{
    my $self = shift;
    if($self->{hasMappoint})
    {
        my $location = shift;
        eval
        {
            $location->GoTo();
        };
    }
}

=head2 addPushpin($locationObject,[$title])

Params:
	-object a Location object
        -string Title [Optional]
Returns:
        Pushpin Object
Example:
        $obj->addPushPin($loc,"my pin");
        $obj->addPushPin($loc); # willl create the pin with a title of No-Title

=cut

sub addPushpin
{
    my $self = shift;
    if($self->{hasMappoint})
    {
        my $location = shift;
        my $title = shift;
        my $pp = undef;
        unless($title)
        {
            $title = "No-title";
        }
        eval
        {
            $pp = $self->{mapPoint}->{ActiveMap}->AddPushpin($location,$title);
        };
        return $pp;
    }
}

=head2 findPushpin($title)

Find a pushpin by title
Params:
        -string Title
Returns:
        Pushpin Object
Example:
        my $pin = $obj->findPushPin($loc,"my pin");

=cut

sub findPushpin
{
    my $self = shift;
    if($self->{hasMappoint})
    {
        my $title = shift;
        my $pp = undef;;
        eval
        {
            $pp = $self->{mapPoint}->{ActiveMap}->FindPushpin($title);
        };
        return $pp;
    }
}

=head2 setPushpinProperty($pushpinObject,$property,$value)

For a reference to pushpin properties see MSDN
Params:
	-object a PushPin object
        -string Property
        -any Value
Returns:
        none
Example:
        $obj->setPushPinProperty($pin,"Symbol","1"); # set the pin symbol to 1
        $obj->setPushPinProperty($pin,"Location",$loc); # set the pin location to $loc

=cut

sub setPushpinProperty
{
    my $self = shift;
    if($self->{hasMappoint})
    {
        my $pp = shift;
        my $prop = shift;
        my $val = shift;
        eval
        {
            $pp->{$prop} = $val;
        };
    }
}

=head2 getPushpinProperty($pushpinObject,$property)

For a reference to pushpin properties see MSDN
Params:
	-object a PushPin object
        -string Property
Returns:
        the associated value
Example:
        $obj->getPushPinProperty($pin,"Symbol"); # get the pin symbol

=cut

sub getPushpinProperty
{
    my $self = shift;
    if($self->{hasMappoint})
    {
        my $pp = shift;
        my $prop = shift;
        my $val;
        eval
        {
            $val = $pp->{$prop};
        };
        return $val;
    }
}

=head2 addPushpinToSet($pushpinObject,$pushpinSet)

Params:
	-object a PushPin object
        -object a PushPinSet Object
Returns:
        none
Example:
        $obj->addPushPinToSet($pin,$set); # set the pin symbol to 1

=cut

sub addPushpinToSet
{
    my $self = shift;
    if($self->{hasMappoint})
    {
        my $pp = shift;
        my $set = shift;
        eval
        {
            $pp->MoveTo($set);
        };
    }
}

=head2 delPushpin($title)

Params:
        -string Title of pushpin
Returns:
        none
Example:
        $obj->delPushpin("bogus");

=cut

sub delPushpin
{
    my $self = shift;
    if($self->{hasMappoint})
    {
        my $pp = shift;
        eval
        {
            $self->{mapPoint}->{ActiveMap}->FindPushpin($pp).Delete();
        };
    }
}

=head2 findCity($city)

Params:
        -string City in form of "City, State"
Returns:
        location object if the city is found
Example:
        my $location - $obj->findCity("Atlanta, GA");

=cut

sub findCity
{
    my $self = shift;
    if($self->{hasMappoint})
    {
        my $city = shift;
        my $location = undef;
        eval
        {
            my $res = $self->{mapPoint}->{ActiveMap}->FindResults($city);
            $location = $res->{1};
        };
        return $location;
    }
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

NetStumbler::MapPoint - MapPoint tools for NetStumbler

=head1 SYNOPSIS

  use NetStumbler::MapPoint;
  my $maplib = NetStumbler::MapPoint->new();
  $maplib->newMap();
  $maplib->showMap();

=head1 DESCRIPTION

 This module handles interaction with Microsoft MapPoint libraries
 as I find a map libraries for use on linux/mac I will add support for those
 this module is fail fast, meaning if you dont have mappoint the method call do
 nothing and do not throw errors

=head2 EXPORT

These functions avaibale for export
hasLibrary
initializeMap
newMap
loadMap
showMap
saveMap
addPushpinSet
getPushpinSet
delPushpinSet
gotoPushpinSet
addSymbol
delSymbol
getLocation
gotoLocation
addPushpin
findPushpin
setPushpinProperty
addPushpinToSet
delPushpin
setSaveFlag
selectItem
findCity

=head1 SEE ALSO

Win32API and MSDN For MapPoint API examples

=head1 AUTHOR

Salvatore E. ScottoDiLuzio<lt>washu@olypmus.net<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Salvatore ScottoDiLuzio

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
