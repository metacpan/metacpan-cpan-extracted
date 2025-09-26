package NetBox::API::Common;
use strict;
use warnings 'FATAL' => 'all';
use version;

our $VERSION = version->declare('v0.1.3')->stringify();

use constant {
    E_OK             => [   0, '' ],
    E_NOCLASS        => [   1, '%s module can not be loaded' ],
    E_NOMETHOD       => [   2, '%s class does not implement method %s' ],
    E_REQFAIL        => [   3, 'request failed: %s' ],
    E_TIMEOUT        => [   4, 'operation timed out' ],
    E_DECFAIL        => [   5, 'failed to decode data from response JSON' ],
    E_BADQUERY       => [   6, 'invalid GraphQL query at line %s, column %s: %s' ],
    E_NOTIMPLEMENTED => [   7, 'X_list query generation is not implemented yet, use raw instead' ],
    E_UNKNOWN        => [ 255, 'unknown error occured' ],
};

BEGIN {
    require Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT = qw();
}

1;
