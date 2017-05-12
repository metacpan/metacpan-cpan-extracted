#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use Test::Trap qw( trap $trap :flow:stderr(systemsafe):stdout(systemsafe):warn );

trap {
   system($^X, '-e', <<'EOF');
use lib 'lib', 't/lib';
use Test::Aggregate;

my $dump = 'dump.t';
my $tests = Test::Aggregate->new( { dirs => 'aggtests', verbose => 0,} );
$tests->run;
EOF
};

my $stderr = $trap->stderr();

unlike ($stderr, qr{^\#\s*ok\s+-\s+aggtests/}ms, 
    'With verbose => 0, no traces of ok are shown.'
);
#ok -f $dump, '... and we should have written out a dump file';
#unlink $dump or warn "Cannot unlink ($dump): $!";
