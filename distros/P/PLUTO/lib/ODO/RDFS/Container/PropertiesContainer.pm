package ODO::RDFS::Container::PropertiesContainer;

use strict;
use warnings;

use vars qw( $AUTOLOAD @ISA );
use ODO::RDFS::Resource::PropertiesContainer;
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;
@ISA = (  'ODO::RDFS::Resource::PropertiesContainer', );

# Methods

1;
