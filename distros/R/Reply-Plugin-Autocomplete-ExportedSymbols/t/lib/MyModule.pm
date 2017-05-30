package MyModule;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT      = qw/foo bar $baz/;
our @EXPORT_OK   = qw/foo bar $baz foobar foobaz/;
our %EXPORT_TAGS = (qux => [qw/quux corge/]);

1;
