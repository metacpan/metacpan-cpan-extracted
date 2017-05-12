package ODO::RDFS::Alt::PropertiesContainer;
use strict;
use warnings;

use vars qw( $AUTOLOAD @ISA );
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;
use ODO::RDFS::Container::PropertiesContainer;

@ISA = (  'ODO::RDFS::Container::PropertiesContainer', );

# Methods

1;
