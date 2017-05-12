package ODO::RDFS::Properties::range::PropertiesContainer;
use strict;
use warnings;
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;
use vars qw( $AUTOLOAD @ISA );
use ODO::RDFS::Class::PropertiesContainer;
use ODO::RDFS::Property::PropertiesContainer;
@ISA = (
		 'ODO::RDFS::Class::PropertiesContainer',
		 'ODO::RDFS::Property::PropertiesContainer',
);

# Methods
1;
