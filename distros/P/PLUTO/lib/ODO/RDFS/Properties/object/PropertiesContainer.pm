package ODO::RDFS::Properties::object::PropertiesContainer;

use strict;
use warnings;

use vars qw( $AUTOLOAD @ISA );
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;
use ODO::RDFS::Resource::PropertiesContainer;
use ODO::RDFS::Property::PropertiesContainer;

@ISA = (  'ODO::RDFS::Property::PropertiesContainer',  'ODO::RDFS::Resource::PropertiesContainer', );

# Methods

1;
