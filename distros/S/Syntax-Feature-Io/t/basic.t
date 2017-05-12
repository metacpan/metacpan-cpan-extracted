use strictures  1;
use Test::More  0.96;
use Test::Fatal 0.003;

# !TESTMARKER! do not remove or tests will fail

use syntax qw( io );

do {
    my @lines = io(__FILE__)->getlines;
    ok scalar(grep m{!TESTMARKER!}, @lines), 'found testmarker';
};

use syntax io => { -as => 'fhtagn' };

do {
    my @lines = fhtagn(__FILE__)->getlines;
    ok scalar(grep m{!TESTMARKER!}, @lines), 'found testmarker via renamed';
};

use syntax io => { -as => 'strict_io', -import => [-strict] };

do {
    like exception { strict_io('unknown.txt')->getlines },
         qr{ unknown \. txt }xi,
         'strict option with passed import arguments';
};

do {
    package TestDirectImportArgs;
    use syntax io => [-strict];

    ::like
        ::exception { io('notthere.txt')->getlines },
        qr{ notthere \. txt }xi,
        'strict option directly passed';
};

like exception {
        Syntax::Feature::Io->install(
            into    => 'null',
            options => 'foo',
        );
    },
    qr{
            options \s+ for \s+ Syntax::Feature::Io
        \s+ have \s+ to \s+ be
        .+  array .+ hash .+ ref
    }xism,
    'invalid options';

like exception {
        Syntax::Feature::Io->install(
            into    => 'null',
            options => { -import => 'foo' },
        );
    },
    qr{
            option \s+ -import
        .+  has \s+ to \s+ be
        .+  array .+ ref
    }xism,
    'invalid options';

done_testing;
