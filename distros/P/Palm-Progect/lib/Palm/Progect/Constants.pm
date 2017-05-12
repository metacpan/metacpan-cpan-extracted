
use strict;
package Palm::Progect::Constants;

use Exporter;

use vars qw(@ISA @EXPORT);

@ISA = 'Exporter';

@EXPORT = qw(
    EOL_TYPE_PC
    EOL_TYPE_UNIX
    EOL_TYPE_MAC
    RECORD_TYPE_PROGRESS
    RECORD_TYPE_NUMERIC
    RECORD_TYPE_ACTION
    RECORD_TYPE_INFO
    RECORD_TYPE_EXTENDED
    RECORD_TYPE_LINK
);

use constant EOL_TYPE_PC   => "\r\n";
use constant EOL_TYPE_UNIX => "\n";
use constant EOL_TYPE_MAC  => "\r";

use constant RECORD_TYPE_NONE     => 0;
use constant RECORD_TYPE_PROGRESS => 1;
use constant RECORD_TYPE_NUMERIC  => 2;
use constant RECORD_TYPE_ACTION   => 3;
use constant RECORD_TYPE_INFO     => 4;
use constant RECORD_TYPE_EXTENDED => 5;
use constant RECORD_TYPE_LINK     => 6;

1;
