#!/home/ben/software/install/bin/perl
use warnings;
use strict;
my $rm = $ENV{REQUEST_METHOD};
if (! $rm) {
    die "No request method";
}
if ($rm eq 'POST') {
    print <<EOF;
Status: 405
Allow: GET, HEAD

EOF
}
elsif ($rm eq 'GET') {
    print <<EOF;
Content-Type: text/plain

Greetings
EOF
}
elsif ($rm eq 'HEAD') {
    print <<EOF;
Content-Type: text/plain

EOF
}
else {
    print <<EOF;
Status: 501

EOF
}

