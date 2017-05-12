#===============================================================================
#
#         FILE:  Exceptions.pm
#      CREATED:  07/13/2008 07:00:36 AM ART
#===============================================================================

use strict;
use warnings;

package SQL::Bibliosoph::Exceptions;

use Exception::Class ( 
    'SQL::Bibliosoph::Exception::QuerySyntaxError' => { 
        description => 'Syntax Error',
        fields      => [ qw(desc) ],
    },
    'SQL::Bibliosoph::Exception::CallError' => { 
        description => 'Function Call Error',
        fields      => [ qw(desc) ],
    },
    'SQL::Bibliosoph::Exception::CatalogFileError' => { 
        description => 'Catalog File Error',
        fields      => [ qw(desc) ],
    },
);

1;
