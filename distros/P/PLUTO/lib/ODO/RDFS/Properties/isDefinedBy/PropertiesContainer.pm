package ODO::RDFS::Properties::isDefinedBy::PropertiesContainer;

use strict;
use warnings;

use vars qw( $AUTOLOAD @ISA );
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;
use ODO::RDFS::Properties::seeAlso::PropertiesContainer;
use ODO::RDFS::Resource::PropertiesContainer;

@ISA = (  'ODO::RDFS::Properties::seeAlso::PropertiesContainer',  'ODO::RDFS::Resource::PropertiesContainer', );

# Methods

1;
