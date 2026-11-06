package Demo::Config;
use strict;
use warnings;

# Return sample configuration without secrets.
sub get {
    return { app => 'Perl CodeMap sample', debug => 0 };
}
1;
