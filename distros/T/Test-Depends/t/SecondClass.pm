
package SecondClass;

our $VERSION = "1.01";

use base qw(Exporter);

our @EXPORT_OK = qw(somefunc);

sub somefunc {
    "func-y";
}

1;
