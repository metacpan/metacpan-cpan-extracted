use Test2::V0
    -target => 'OpenSMTPd::Filter',
    qw< ok is like dies diag done_testing >;

use IO::File;

my $has_pledge = do { local $@; eval { local $SIG{__DIE__};
    require OpenBSD::Pledge } };

# Open these before we maybe pledge
my $input  = IO::File->new_tmpfile;
my $output = IO::File->new_tmpfile;

$_->binmode(":raw") for $input, $output;

# Failed tests attempt to load this and cause pledge violations.
{ local $@; eval { local $SIG{__DIE__};
    require Test2::API::Breakage } };

diag "Testing $CLASS on perl $^V" . ( $has_pledge ? " with pledge" : "" );
OpenBSD::Pledge::pledge() || die "Unable to pledge: $!" if $has_pledge;

ok CLASS, "Loaded $CLASS";

ok my $filter = CLASS->new, "Created a new $CLASS instance";

is fileno $filter->{input},  fileno *STDIN,  "input defaults to STDIN";
is fileno $filter->{output}, fileno *STDOUT, "output defaults to STDOUT";

ok $filter->_handle_config('foo|bar|baz'), "Able to handle_config";
is $filter->{_config}, { foo => 'bar|baz' }, "Set config correctly";

like dies { $filter->ready }, qr{\QInput stream is not ready},
    "Trying to go ready without ready from input stream is fatal";

like dies { CLASS->new( on => { nonexist => {}, unsupported => [] } ) },
    qr{\QUnsupported event types nonexist unsupported },
    "Trying to listen on unsupported type throws an exception";

like dies { CLASS->new( on => { report => { nonexist => {} } } ) },
    qr{\QUnsupported event subsystem nonexist },
    "Trying to listen on unsupported subsystems throws an exception";

like dies { CLASS->new( on => {
        report => { 'smtp-in' => { nonexist => {}, unsupported => [] } }
    }) },
    qr{\QUnsupported events nonexist unsupported },
    "Trying to listen on unsupported events throws an exception";

{
    $_->seek( 0, 0 ), $_->truncate(0) for $input, $output;
    $input->say("config|foo|bar");
    $input->say("config|foo|baz");
    $input->say("config|qux|quux");
    $input->say("config|ready");
    $input->say("config|ignored|value");
    $input->flush;
    $input->seek( 0, 0 );

    my $f = CLASS->new( input => $input );

    is $f->{_config}, { foo => 'baz', qux => 'quux' },
        "Config has expected values";
    ok $f->{_ready}, "Read config to ready";

    is $input->getline, "config|ignored|value\n",
        "Values after 'ready' are not read during init";

    $f->_init;

    is $f->{_config}, { foo => 'baz', qux => 'quux' },
        "_init won't read config further after ready";

    $f->_dispatch("config|foo|bar");

    is $f->{_config}, { foo => 'bar', qux => 'quux' },
        "But if we get a config value during processing we update it";
}

{
    $_->seek( 0, 0 ), $_->truncate(0) for $input, $output;

    $input->say("config|ready");
    $input->flush;
    $input->seek( 0, 0 );

    my $f = CLASS->new( input => $input, output => $output );
    $f->ready;

    $output->seek( 0, 0 );

    is [ map { chomp; $_ } $output->getlines ], [
        'register|report|smtp-in|filter-report',
        'register|report|smtp-in|filter-response',
        'register|report|smtp-in|link-auth',
        'register|report|smtp-in|link-connect',
        'register|report|smtp-in|link-disconnect',
        'register|report|smtp-in|link-greeting',
        'register|report|smtp-in|link-identify',
        'register|report|smtp-in|link-tls',
        'register|report|smtp-in|protocol-client',
        'register|report|smtp-in|protocol-server',
        'register|report|smtp-in|timeout',
        'register|report|smtp-in|tx-begin',
        'register|report|smtp-in|tx-commit',
        'register|report|smtp-in|tx-data',
        'register|report|smtp-in|tx-envelope',
        'register|report|smtp-in|tx-mail',
        'register|report|smtp-in|tx-rcpt',
        'register|report|smtp-in|tx-reset',
        'register|report|smtp-in|tx-rollback',
        'register|ready',
    ], "Recieved expected initialization";
}

{
    $_->seek( 0, 0 ), $_->truncate(0) for $input, $output;
    $input->say("config|ready");

    # when happens when a connection sends ^C
    my $fail = join '', map {chr} 0xFF, 0xF4, 0xFF, 0xFD, 0x06;
    $input->say("report|0.6|12345|smtp-in|protocol-client|abcd|$fail");

    $input->flush;
    $input->seek( 0, 0 );

    my $f = CLASS->new( input => $input, output => $output );

    is dies { $f->ready }, undef,
        "The client can send garbage and we just take it";

    like $f->{_sessions}->{abcd}, {
        events => [ { command => $fail } ],
        state  => {
            event   => 'protocol-client',
            command => $fail,
        },
    };
}

done_testing;
