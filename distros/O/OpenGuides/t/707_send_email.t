use strict;
use OpenGuides::Config;
use OpenGuides::Utils;
use Test::More;

plan tests => 6;

my $config = OpenGuides::Config->new(
    vars => {
        contact_email => 'admin@example.com'
    }
);

my $output = OpenGuides::Utils->send_email(
    config        => $config,
    return_output => 1,
    to            => [ 'user@example.com' ],
    subject       => 'Test subject',
    body          => 'Test body'
);

like( $output, qr|^From: admin\@example\.com|m, "From address shown" );
like( $output, qr|^To: user\@example\.com|m, "To address shown correctly" );
like( $output, qr|^Subject: Test subject|m, "Subject shown correctly" );
like( $output, qr|^Test body|m, "Body text appears at the start of a line" );

$output = OpenGuides::Utils->send_email(
    config        => $config,
    return_output => 1,
    admin         => 1,
    subject       => 'Test subject',
    body          => 'Test body'
);

like( $output, qr|^To: admin\@example\.com|m, "Admin address used ".
    "appropriately" );

eval { $output = OpenGuides::Utils->send_email(
    config        => $config,
    return_output => 1,
    subject       => 'Test subject',
    body          => 'Test body'
); };

like( $@, qr|No recipients specified|, "No recipients error caught" );
