use Test2::V0 -target => 'OpenSMTPd::Filter',
    qw< ok is like
       warning dies
       hash field E etc
       diag subtest done_testing >;

use IO::File;

my $has_pledge = do { local $@; eval { local $SIG{__DIE__};
    require OpenBSD::Pledge } };

# Open these before possibly pledging
my $input  = IO::File->new_tmpfile;
my $output = IO::File->new_tmpfile;

# Failed tests attempt to load this and cause pledge violations.
{ local $@; eval { local $SIG{__DIE__};
    require Test2::API::Breakage } };

diag "Testing $CLASS on perl $^V" . ( $has_pledge ? " with pledge" : "" );

# for some reason "warning" requires rpath
OpenBSD::Pledge::pledge('rpath') || die "Unable to pledge: $!" if $has_pledge;

is CLASS->new(
    output    => $output,
    _sessions => { abc => {} },
    on        => {
        filter => {
            'smtp-in' => {
                connect => sub {'proceed'}
            }
        }
})->_handle_filter('0.6|123|smtp-in|connect|abc|def|localhost|[::1]'), {
    version        => '0.6',
    timestamp      => '123',
    subsystem      => 'smtp-in',
    phase          => 'connect',
    session        => 'abc',
    'opaque-token' => 'def',
}, "Able to handle_filter for a link-connect";

$output->seek( 0, 0 );
is $output->getline,
    "filter-result|abc|def|proceed\n",
    "Handled the message with our expected result";
$output->seek( 0, 0 );

{
    my $filter = CLASS->new;

    like dies { $filter->_handle_filter('') },
        qr/^\QUnsupported filter undef|undef at /,
        "Died when trying to handle an empty filter";

    like dies { $filter->_handle_filter('0.5|1576146008.006099') },
        qr{^\QUnsupported filter undef|undef at },
        "Undef filter event throws exception";

    like dies { $filter->_handle_filter('0.5|1576146008.006099|xxx|') },
        qr{^\QUnsupported filter 'xxx'|'' at },
        "Unsupported (blank) filter type throws exception";

    like dies { $filter->_handle_filter('0.5|1576146008.006099|xxx|yyy') },
        qr{^\QUnsupported filter 'xxx'|'yyy' at },
        "Unsupported filter type throws exception";

    like dies {
        $filter->_handle_filter('0.5|1576146008.006099|smtp-in|unknown')
    },
        qr{^\QUnsupported filter 'smtp-in'|'unknown' at },
        "Unsupported filter event throws exception";
}

{
    my $filter = CLASS->new( output => $output, _sessions => { abc => {} } );

    like warning {
        $filter->_handle_filter('0.6|123|smtp-in|helo|abc|def|mail')
    },
        qr/^\QNo handler for filter 'smtp-in'|'helo', proceeding at/,
        "Warned that we got a filter request we weren't prepared to handle";
}

{
    my @params;
    my $filter = CLASS->new(
        output    => $output,
        _sessions => { aaa => {}, bbb => {}, ccc => {} },
        on        => {
            filter => {
                'smtp-in' => {
                    helo => sub { push @params, \@_; 'incorrect' },
                    ehlo => sub { push @params, \@_; 'junk', 'do not like' },
                    data => sub { push @params, \@_; 'rewrite' },
                }
            }
        }
    );

    like dies { $filter->_handle_filter('0.6|123|smtp-in|auth') },
        qr{^\QUnknown session undef in filter 'smtp-in'|'auth' at },
        "Unsupported filter event throws exception";

    like dies { $filter->_handle_filter('0.6|123|smtp-in|commit|xxx|def|') },
        qr{^\QUnknown session 'xxx' in filter 'smtp-in'|'commit' at },
        "Unsupported filter event throws exception";

    like warning {
        $filter->_handle_filter('0.6|123|smtp-in|helo|aaa|def|mail')
    },
        qr/^\QUnknown return from filter 'smtp-in'|'helo': incorrect at /,
        "Warned that the filter returned an invalid response";

    like \@params, [
        [   helo => {
                events => [
                    {   subsystem => 'smtp-in',
                        phase     => 'helo',
                        identity  => 'mail',
                    }
                ]
            }
        ]
    ], "Passed expected params to filter";
    @params = ();

    is $filter->{_sessions}->{aaa}, {
        events => [
            {   'request'      => 'filter',
                'version'      => '0.6',
                'timestamp'    => '123',
                'subsystem'    => 'smtp-in',
                'session'      => 'aaa',
                'opaque-token' => 'def',
                'phase'        => 'helo',
                'identity'     => 'mail',
            }
        ]
    }, "First session filled as expected";

    like warning {
        $filter->_handle_filter('0.6|123|smtp-in|ehlo|bbb|def|mail')
    },
        qr/^\QIncorrect params from filter 'smtp-in'|'ehlo', expected 'decision' got 'junk' 'do not like' at /,
        "Warned that the filter returned unexpected params";

    like \@params, [
        [   ehlo => {
                events => [
                    {   subsystem => 'smtp-in',
                        phase     => 'ehlo',
                        identity  => 'mail',
                    }
                ]
            }
        ]
    ], "Passed expected params to filter";
    @params = ();

    is $filter->{_sessions}->{bbb}, {
        events => [
            {   'request'      => 'filter',
                'version'      => '0.6',
                'timestamp'    => '123',
                'subsystem'    => 'smtp-in',
                'session'      => 'bbb',
                'opaque-token' => 'def',
                'phase'        => 'ehlo',
                'identity'     => 'mail',
            }
        ]
    }, "Second session filled as expected";

    like warning {
        $filter->_handle_filter('0.6|123|smtp-in|data|ccc|def')
    },
        qr/^\QIncorrect params from filter 'smtp-in'|'data', expected 'decision' 'parameter' got 'rewrite' at /,
        "Warned that the filter returned unexpected params";

    like \@params, [
        [   data => {
                events => [
                    {   subsystem => 'smtp-in',
                        phase     => 'data',
                    }
                ]
            }
        ]
    ], "Passed expected params to filter";
    @params = ();

    is $filter->{_sessions}->{ccc}, {
        events => [
            {   'request'      => 'filter',
                'version'      => '0.6',
                'timestamp'    => '123',
                'subsystem'    => 'smtp-in',
                'session'      => 'ccc',
                'opaque-token' => 'def',
                'phase'        => 'data',
            }
        ]
    }, "Third session filled as expected";
}

subtest "fill in error on response" => sub {
    $output->seek( 0, 0 );
    $output->truncate(0);

    my @params;
    my $filter = CLASS->new(
        output    => $output,
        _sessions => { abc => {} },
        on        => { filter => { 'smtp-in' => {
            'mail-from' => sub { push @params, \@_; 'reject' },
            'rcpt-to'   => sub { push @params, \@_; 'disconnect' },
        } } }
    );

    like warning {
        $filter->_handle_filter('0.6|123|smtp-in|mail-from|abc|def|andrew')
    }, undef, "No warnings for missing filled-in prarms";

    like \@params, [
        [   'mail-from' => {
                events => [
                    {   subsystem => 'smtp-in',
                        phase     => 'mail-from',
                        address   => 'andrew',
                    }
                ]
            }
        ]
    ], "Passed expected params to filter";
    @params = ();

    like warning {
        $filter->_handle_filter('0.6|123|smtp-in|rcpt-to|abc|def|afresh1')
    }, undef, "No warnings for missing filled-in prarms";

    like \@params, [
        [   'rcpt-to' => {
                events => [
                    {   subsystem => 'smtp-in',
                        phase     => 'mail-from',
                        address   => 'andrew',
                    },
                    {   subsystem => 'smtp-in',
                        phase     => 'rcpt-to',
                        address   => 'afresh1',
                    }
                ]
            }
        ]
    ], "Passed expected params to filter";
    @params = ();

    is $filter->{_sessions}->{abc}, {
        events => [
            {   'request'      => 'filter',
                'version'      => '0.6',
                'timestamp'    => '123',
                'subsystem'    => 'smtp-in',
                'session'      => 'abc',
                'opaque-token' => 'def',
                'phase'        => 'mail-from',
                'address'      => 'andrew',
            },
            {   'request'      => 'filter',
                'version'      => '0.6',
                'timestamp'    => '123',
                'subsystem'    => 'smtp-in',
                'session'      => 'abc',
                'opaque-token' => 'def',
                'phase'        => 'rcpt-to',
                'address'      => 'afresh1',
            }
        ]
    }, "Second session filled as expected";

    $output->seek( 0, 0 );
    is [ map { chomp; $_ } $output->getlines ], [
        'filter-result|abc|def|reject|550 Nope',
        'filter-result|abc|def|disconnect|550 Nope',
    ], "Wrote the filter respose we expected";
};

my $data_lines = <<'EOL';
filter|0.6|001|smtp-in|data-line|abc|def|From: Andrew
filter|0.6|002|smtp-in|data-line|abc|def|To: AFresh1
filter|0.6|003|smtp-in|data-line|abc|def|
filter|0.6|004|smtp-in|data-line|abc|def|Hello!
filter|0.6|005|smtp-in|data-line|abc|def|
filter|0.6|006|smtp-in|data-line|abc|def|...
filter|0.6|007|smtp-in|data-line|abc|def|..
filter|0.6|008|smtp-in|data-line|abc|def|
filter|0.6|009|smtp-in|data-line|abc|def|There!
filter|0.6|010|smtp-in|data-line|abc|def|.
EOL

my @data_lines = (
    'From: Andrew', 'To: AFresh1',
    '',
    'Hello!', '', '...', '..', '', 'There!',
    '.',
);

{
    $output->seek( 0, 0 );
    $output->truncate(0);

    my @lines = @_;
    my $f     = CLASS->new(
        output    => $output,
        _sessions => { abc => { messages => [ {}, {} ] } },
        on        => {
            filter => {
                'smtp-in' => {
                    'data-line' => sub {
                        push @lines, \@_; my $l = $_[-1];
                        $l && $l eq '.' ? () : $l ? "x $l" : $l;
                    },
                    'data-lines' => sub {
                        push @lines, \@_;
                        map { $_ && $_ ne '.' ? "y $_" : $_ } @{ $_[-1] };
                    },
                }
            }
        }
    );

    $f->_dispatch($_) for ( split /\n/, $data_lines )[ 3, 8, 9 ];

    my %event = (
        'version'      => '0.6',
        'request'      => 'filter',
        'subsystem'    => 'smtp-in',
        'phase'        => 'data-line',
        'session'      => 'abc',
        'opaque-token' => 'def',
    );

    my %expect = (
        'abc' => {
            events => [
                { %event, 'timestamp' => '004', 'line' => 'Hello!' },
                { %event, 'timestamp' => '009', 'line' => 'There!' },
                { %event, 'timestamp' => '010', 'line' => '.' },
            ],
            messages => [
                {},
                {   'data-line' => [ @data_lines[ 3, 8, 9 ] ],
                    'sent-dot'  => 1
                }
            ],
        }
    );

    is $f->{_sessions}, \%expect, "Got the sessions we expected";

    my $session = hash {
        field events   => E();
        field messages => E();
        etc();
    };

    is \@lines, [
        ( map { [ 'data-line' => $session, $_ ] } @data_lines[ 3, 8, 9 ] ),
        [ 'data-lines' => $session, [ @data_lines[ 3, 8, 9 ] ]],
    ], "Got the filter params we expected";

    $output->seek( 0, 0 );
    is [ map { chomp; $_ } $output->getlines ], [
        map {"filter-dataline|abc|def|$_"}
            ( map { $_ ? "x $_" : $_ } @data_lines[ 3, 8 ] ),
        ( map { $_ ? "y $_" : $_ } @data_lines[ 3, 8 ] ),
        '.',
    ], "Wrote the filter respose we expected";
}

subtest 'filter data-line' => sub {
    $_->seek( 0, 0 ), $_->truncate(0) for $input, $output;

    $input->print( "config|ready\n", $data_lines );
    $input->flush;
    $input->seek( 0, 0 );

    my @lines = @_;
    my $f     = CLASS->new(
        input     => $input,
        output    => $output,
        _sessions => { abc => { messages => [ {}, {} ] } },
        on        => { filter => { 'smtp-in' => {
            'data-line' => sub {
                push @lines, \@_; my $l = $_[-1];
                $l && $l ne '.' ? "x $l" : $l;
            }
        } } }
    );

    $f->ready;

    my %event = (
        'version'      => '0.6',
        'request'      => 'filter',
        'subsystem'    => 'smtp-in',
        'phase'        => 'data-line',
        'session'      => 'abc',
        'opaque-token' => 'def',
    );

    my %expect = (
        'abc' => {
            events => [
                { %event, 'timestamp' => '001', 'line' => 'From: Andrew' },
                { %event, 'timestamp' => '002', 'line' => 'To: AFresh1' },
                { %event, 'timestamp' => '003', 'line' => undef },
                { %event, 'timestamp' => '004', 'line' => 'Hello!' },
                { %event, 'timestamp' => '005', 'line' => undef },
                { %event, 'timestamp' => '006', 'line' => '...' },
                { %event, 'timestamp' => '007', 'line' => '..' },
                { %event, 'timestamp' => '008', 'line' => undef },
                { %event, 'timestamp' => '009', 'line' => 'There!' },
                { %event, 'timestamp' => '010', 'line' => '.' },
            ],
            messages =>
                [ {}, { 'sent-dot' => 1 } ],
        }
    );

    is $f->{_sessions}, \%expect, "Got the sessions we expected";

    my $session = hash {
        field events   => E();
        field messages => E();
        etc();
    };

    is \@lines, [ map { [ 'data-line' => $session, $_ ] } @data_lines ],
        "Got the filter params we expected";

    $output->seek( 0, 0 );
    is [ map { chomp; $_ } grep {/^filter/} $output->getlines ], [
        map {"filter-dataline|abc|def|$_"}
        map { $_ && $_ ne '.' ? "x $_" : $_ } @data_lines
    ], "Wrote the filter respose we expected";
};

subtest 'filter data-lines' => sub {
    $output->seek( 0, 0 );
    $output->truncate(0);

    my @lines = @_;
    my $f     = CLASS->new(
        output    => $output,
        _sessions => { abc => { messages => [ {}, {} ] } },
        on        => { filter => { 'smtp-in' => {
            'data-lines' => sub {
                push @lines, \@_;
                map { $_ && $_ ne '.' ? "y $_" : $_ } @{ $_[-1] };
            }
        } } }
    );

    $f->_dispatch($_) for split /\n/, $data_lines;

    my %event = (
        'version'      => '0.6',
        'request'      => 'filter',
        'subsystem'    => 'smtp-in',
        'phase'        => 'data-line',
        'session'      => 'abc',
        'opaque-token' => 'def',
    );

    my %expect = (
        'abc' => {
            events => [
                { %event, 'timestamp' => '001', 'line' => 'From: Andrew' },
                { %event, 'timestamp' => '002', 'line' => 'To: AFresh1' },
                { %event, 'timestamp' => '003', 'line' => undef },
                { %event, 'timestamp' => '004', 'line' => 'Hello!' },
                { %event, 'timestamp' => '005', 'line' => undef },
                { %event, 'timestamp' => '006', 'line' => '...' },
                { %event, 'timestamp' => '007', 'line' => '..' },
                { %event, 'timestamp' => '008', 'line' => undef },
                { %event, 'timestamp' => '009', 'line' => 'There!' },
                { %event, 'timestamp' => '010', 'line' => '.' },
            ],
            messages =>
                [ {}, { 'data-line' => [@data_lines], 'sent-dot' => 1 } ],
        }
    );

    is $f->{_sessions}, \%expect, "Got the sessions we expected";

    my $session = hash {
        field events   => E();
        field messages => E();
        etc();
    };

    is \@lines, [ [ 'data-lines' => $session, \@data_lines ] ],
        "Got the filter params we expected";

    $output->seek( 0, 0 );
    is [ map { chomp; $_ } $output->getlines ], [
        map {"filter-dataline|abc|def|$_"}
        map { $_ && $_ ne '.' ? "y $_" : $_ } @data_lines
    ], "Wrote the filter respose we expected";
};

done_testing;
