use strict;
use warnings;
use Test::More;
use Test::Deep;

use Plack::ResponseHelper pdf => [Attachment => {content_type => 'application/pdf'}];

my $filename = 'report.pdf';
my $data = 123;

cmp_deeply(
    respond(pdf => {filename => $filename, data => $data}),
    [
        200,
        [
            'Content-Type' => 'application/pdf',
            'Content-Disposition' => qq[attachment; filename="$filename"],
        ],
        [
            $data
        ]
    ],
    'ok'
);

done_testing;
