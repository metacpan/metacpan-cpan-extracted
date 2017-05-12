package ODO::RDFS::Properties::first::PropertiesContainer;

use strict;
use warnings;

use vars qw( $AUTOLOAD @ISA );
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;
@ISA = (  'ODO::RDFS::Property::PropertiesContainer',  'ODO::RDFS::Resource::PropertiesContainer', );

# Methods

1;
