package OpenTracing::Interface;

use Carp;

BEGIN {
    carp <<END_OF_MESSAGE;
Do not 'use' "OpenTracing::Interface" !!!

it does not provide anything!
check the documentation on how to consume the roles provided
END_OF_MESSAGE

}

our $VERSION = 'v0.206.1';

1;
