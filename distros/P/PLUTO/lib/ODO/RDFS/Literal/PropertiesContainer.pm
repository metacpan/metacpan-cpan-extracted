package ODO::RDFS::Literal::PropertiesContainer;

use strict;
use warnings;

use vars qw( $AUTOLOAD @ISA );
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;
use ODO::RDFS::Resource::PropertiesContainer; 

@ISA = (  'ODO::RDFS::Resource::PropertiesContainer', );

# Methods

1;
