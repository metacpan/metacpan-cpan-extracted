use strict;
use warnings;

use Test2::V0;
use Test2::Plugin::NoWarnings;
use Test2::Require::Module 'Sub::Util';

use Params::ValidationCompiler qw( validation_for );

{
    my $sub = validation_for(
        name   => 'Check for X',
        params => { foo => 1 },
    );

    my $e = dies { $sub->() };
    like(
        $e->trace->as_string,
        qr/main::Check for X/,
        'got expected sub name in stack trace',
    );
}

done_testing();
