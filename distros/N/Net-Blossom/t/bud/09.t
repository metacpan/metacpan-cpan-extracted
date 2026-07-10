use strictures 2;

use Test::More;
use JSON ();

use Net::Blossom::Client;

sub dies(&) {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

{
    package Local::UA;
    use strictures 2;
    sub new { bless { requests => [], responses => [@_[1 .. $#_]] }, $_[0] }
    sub request {
        my ($self, $method, $url, $opts) = @_;
        push @{$self->{requests}}, [$method, $url, $opts || {}];
        return shift @{$self->{responses}};
    }
    sub requests { @{$_[0]->{requests}} }
}

my $HASH = 'b1674191a88ec5cdd733e4240a81803105dc412d6c6708d53ab94fc248f4f553';
my $EVENT = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
my $PUBKEY = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
my $SIG = 'b' x 128;
my $JSON = JSON->new->utf8->canonical;

sub report_event {
    return {
        id         => $EVENT,
        pubkey     => $PUBKEY,
        created_at => 1725909682,
        kind       => 1984,
        tags       => [
            ['x', $HASH, 'malware'],
            ['e', $EVENT],
            ['p', $PUBKEY],
        ],
        content => 'This blob should be reviewed.',
        sig     => $SIG,
    };
}

subtest 'BUD-09 PUT /report sends signed NIP-56 report event JSON' => sub {
    my $event = report_event();
    my $ua = Local::UA->new({
        status  => 202,
        reason  => 'Accepted',
        headers => {},
        content => '',
    });
    my $client = Net::Blossom::Client->new(server => 'https://cdn.example.com', ua => $ua);

    my $response = $client->report_blob($event);
    is($response->status, 202, 'success response returned');

    my ($method, $url, $opts) = @{($ua->requests)[0]};
    # Encode a fresh event: report_blob normalizes JSON types, and validating
    # the passed-in $event stringifies its numeric fields in place.
    my $body = $JSON->encode(report_event());
    is($method, 'PUT', 'PUT method');
    is($url, 'https://cdn.example.com/report', 'report endpoint');
    is($opts->{content}, $body, 'canonical event JSON body');
    is($opts->{headers}{'Content-Type'}, 'application/json', 'JSON content type');
    is($opts->{headers}{'Content-Length'}, length($body), 'content length header');
};

subtest 'BUD-09 PUT /report accepts any 2xx success status' => sub {
    for my $status (200, 201, 202, 204) {
        my $ua = Local::UA->new({
            status  => $status,
            reason  => 'Success',
            headers => {},
            content => '',
        });
        my $client = Net::Blossom::Client->new(server => 'https://cdn.example.com', ua => $ua);

        is($client->report_blob(report_event())->status, $status, "$status response accepted");
    }
};

subtest 'BUD-09 report callback receives report action context' => sub {
    my @seen;
    my $ua = Local::UA->new({
        status  => 200,
        reason  => 'OK',
        headers => {},
        content => '',
    });
    my $client = Net::Blossom::Client->new(
        server => 'https://cdn.example.com',
        ua     => $ua,
        auth   => sub {
            push @seen, { @_ };
            return undef;
        },
    );

    $client->report_blob(report_event());

    is(scalar @seen, 1, 'auth callback called once');
    is($seen[0]{method}, 'PUT', 'method context');
    is($seen[0]{url}, 'https://cdn.example.com/report', 'url context');
    is($seen[0]{action}, 'report', 'action context');
    is($seen[0]{sha256}, undef, 'no single implied blob hash');
};

subtest 'BUD-09 rejection statuses preserve X-Reason diagnostics' => sub {
    my $ua = Local::UA->new({
        status  => 400,
        reason  => 'Bad Request',
        headers => { 'x-reason' => 'invalid report event' },
        content => 'no',
    });
    my $client = Net::Blossom::Client->new(server => 'https://cdn.example.com', ua => $ua);

    my $error = dies { $client->report_blob(report_event()) };
    isa_ok($error, 'Net::Blossom::Error');
    is($error->status, 400, 'status');
    is($error->x_reason, 'invalid report event', 'x-reason diagnostic');
};

subtest 'BUD-09 report event shape is validated locally' => sub {
    my $client = Net::Blossom::Client->new(server => 'https://cdn.example.com', ua => Local::UA->new);

    like(dies { $client->report_blob() },
        qr/report event must be a hash reference/, 'missing report rejected');

    my %wrong_kind = %{ report_event() };
    $wrong_kind{kind} = 1;
    like(dies { $client->report_blob(\%wrong_kind) },
        qr/report event kind must be 1984/, 'wrong kind rejected');

    my %missing_sig = %{ report_event() };
    delete $missing_sig{sig};
    like(dies { $client->report_blob(\%missing_sig) },
        qr/report event sig must be 128-char lowercase hex/, 'missing sig rejected');

    my %missing_x = %{ report_event() };
    $missing_x{tags} = [['e', $EVENT]];
    like(dies { $client->report_blob(\%missing_x) },
        qr/report event must contain at least one x tag/, 'missing x tag rejected');

    my %bad_x = %{ report_event() };
    $bad_x{tags} = [['x', 'A' x 64, 'malware']];
    like(dies { $client->report_blob(\%bad_x) },
        qr/report x tag hash must be 64-char lowercase hex/, 'bad x hash rejected');
};

done_testing;
