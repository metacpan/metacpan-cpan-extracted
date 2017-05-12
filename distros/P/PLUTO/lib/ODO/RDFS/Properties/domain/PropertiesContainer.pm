package ODO::RDFS::Properties::domain::PropertiesContainer;

use strict;
use warnings;

use vars qw( $AUTOLOAD @ISA );
use ODO::RDFS::Class::PropertiesContainer;
use ODO::RDFS::Property::PropertiesContainer;
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

@ISA = (  'ODO::RDFS::Class::PropertiesContainer',  'ODO::RDFS::Property::PropertiesContainer', );

# Methods

1;
