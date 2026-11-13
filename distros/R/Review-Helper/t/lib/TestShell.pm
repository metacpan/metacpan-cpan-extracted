package TestShell;
use v5.36;

use Exporter 'import';
our @EXPORT_OK = qw/posix_sh/;

# The POSIX shell to run the dispatcher with: /bin/sh, or /usr/bin/sh where
# only that exists; undef when there is neither.
sub posix_sh() {
    return (grep { -x } '/bin/sh', '/usr/bin/sh')[0];
}

1;
