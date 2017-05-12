use strict;
use warnings;

use Test::More tests => 9;
use Shipwright;
use Shipwright::Test;
Shipwright::Test->init;

my $sw = Shipwright->new(
    repository => 'svk:/test/foo',
    source     => 'cpan:Jifty'
);
isa_ok( $sw->backend, 'Shipwright::Backend::SVK', '$sw->backend' );
isa_ok( $sw->source,  'Shipwright::Source::CPAN', '$sw->source' );

is( $sw->log_file, '-', 'default log_file' );
is( $sw->log_level, 'FATAL', 'default log_level is FATAL' );

$sw = Shipwright->new(
    log_file  => '/tmp/t.log',
    log_level => 'ERROR'
);

is( $sw->backend, undef, 'no repository, no backend' );
is( $sw->source,  undef, 'no source, no backend' );

is( $sw->log_file,  '/tmp/t.log', 'log_file arg is ok' );
is( $sw->log_level, 'ERROR',      'log_level arg is ok' );

$sw = Shipwright->new( repository => 'svk:/test/foo', log_level => 'erROr' );
is( $sw->log_level, 'ERROR', 'log_level which is not upper case is ok' );

