package ODO::RDFS::Properties::label::PropertiesContainer;

use strict;
use warnings;

use vars qw( $AUTOLOAD @ISA );

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

use ODO::RDFS::Literal::PropertiesContainer;
use ODO::RDFS::Property::PropertiesContainer;

@ISA = (  'ODO::RDFS::Literal::PropertiesContainer',  'ODO::RDFS::Property::PropertiesContainer', );

# Methods

1;
