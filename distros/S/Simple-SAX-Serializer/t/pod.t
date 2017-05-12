use warnings;
use strict;

use Test::Pod tests => 4;
 
pod_file_ok('lib/Simple/SAX/Serializer.pm', "should have value lib/Simple/SAX/Serializer.pm POD file" );
pod_file_ok('lib/Simple/SAX/Serializer/Parser.pm', "should have value lib/Simple/SAX/Serializer/Parser.pm POD file");
pod_file_ok('lib/Simple/SAX/Serializer/Element.pm', "should have value lib/Simple/SAX/Serializer/Element.pm file");
pod_file_ok('lib/Simple/SAX/Serializer/Handler.pm', "should have value lib/Simple/SAX/Serializer/Handler.pm file");
