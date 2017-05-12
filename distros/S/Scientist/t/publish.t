use Test2::Bundle::Extended -target => 'Scientist';

use lib 't/lib';
use Publishing::Scientist;

my $experiment = Publishing::Scientist->new(
    experiment => 'Publish Test',
    use        => sub { 10 },
    try        => sub { 20 },
);

like(
    dies { $experiment->run },
    qr/Publish Test/,
    'Experiment name is in publish die statement as expected.',
);

done_testing;
