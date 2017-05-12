package ODO::RDFS::Seq::PropertiesContainer;

use strict;
use warnings;

use ODO::RDFS::Container::PropertiesContainer;
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;
use vars qw( $AUTOLOAD @ISA );

@ISA = (  'ODO::RDFS::Container::PropertiesContainer', );

# Methods

1;
