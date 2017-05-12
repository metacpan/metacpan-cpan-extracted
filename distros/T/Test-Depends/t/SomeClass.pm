
package SomeClass;

our $VERSION = "1.00";

use base qw(Exporter);

our @EXPORT_OK = qw(somefunc);

sub somefunc {
    "func-y";
}

1;
