# t/01-new.t
use 5.014;
use warnings;
use Perl5::TestEachCommit;
use File::Temp qw(tempfile tempdir);
use File::Spec::Functions;
use Test::More tests => 55;
use Data::Dump qw(dd pp);
use Capture::Tiny qw(capture_stdout);

my $opts = {
    branch => "blead",
    configure_command => "sh ./Configure -des -Dusedevel",
    end => "002",
    make_test_harness_command => "make test_harness",
    make_test_prep_command => "make test_prep",
    skip_test_harness => "",
    start => "001",
    verbose => "",
    workdir => "/tmp",
};

my $self = Perl5::TestEachCommit->new( $opts );
ok($self, "new() returned true value");
isa_ok($self, 'Perl5::TestEachCommit',
    "object is a Perl5::TestEachCommit object");

note("Testing error conditions and defaults in new()");

{
    local $@;
    my %theseopts = map { $_ => $opts->{$_} } keys %{$opts};
    delete $theseopts{start};
    my $self;
    eval { $self = Perl5::TestEachCommit->new( \%theseopts ); };
    like($@,
        qr/Must supply SHA of first commit to be studied to 'start'/,
        "Got exception for lack of 'start'");
}

{
    local $@;
    my %theseopts = map { $_ => $opts->{$_} } keys %{$opts};
    delete $theseopts{end};
    my $self;
    eval { $self = Perl5::TestEachCommit->new( \%theseopts ); };
    like($@,
        qr/Must supply SHA of last commit to be studied to 'end'/,
        "Got exception for lack of 'end'");
}

{
    local $@;
    my %theseopts = map { $_ => $opts->{$_} } keys %{$opts};
    delete $theseopts{workdir};
    local $ENV{SECONDARY_CHECKOUT_DIR} = undef;
    my $self;
    eval { $self = Perl5::TestEachCommit->new( \%theseopts ); };
    like($@,
        qr/Unable to locate workdir/,
        "Got exception for lack of for 'workdir'");
}

{
    local $@;
    my %theseopts = map { $_ => $opts->{$_} } keys %{$opts};
    delete $theseopts{workdir};
    my $tdir = '/tmp';
    ok(-d $tdir, "okay to use $tdir during testing");
    local $ENV{SECONDARY_CHECKOUT_DIR} = $tdir;
    my $self;
    eval { $self = Perl5::TestEachCommit->new( \%theseopts ); };
    ok(! $@, "No exceptions, indicating $tdir assigned to 'workdir'");
}

{
    local $@;
    my %theseopts = map { $_ => $opts->{$_} } keys %{$opts};
    undef $theseopts{workdir};
    my $tdir = '/tmp';
    ok(-d $tdir, "okay to use $tdir during testing");
    local $ENV{SECONDARY_CHECKOUT_DIR} = $tdir;
    my $self;
    eval { $self = Perl5::TestEachCommit->new( \%theseopts ); };
    ok(! $@, "No exceptions, indicating that in absence of 'workdir' argument, 'SECONDARY_CHECKOUT_DIR' was assigned thereto");
}

{
    my %theseopts = map { $_ => $opts->{$_} } keys %{$opts};
    delete $theseopts{branch};
    delete $theseopts{configure_command};
    delete $theseopts{make_test_prep_command};
    delete $theseopts{make_test_harness_command};
    delete $theseopts{skip_test_harness};
    delete $theseopts{verbose};
    my $self = Perl5::TestEachCommit->new( \%theseopts );
    is($self->{branch}, 'blead', "'branch' defaulted to blead");
    is($self->{configure_command}, 'sh ./Configure -des -Dusedevel',
        "'configure_command' set to default");
    is($self->{make_test_prep_command}, 'make test_prep',
        "'make_test_prep_command' set to default");
    is($self->{make_test_harness_command}, 'make test_harness',
        "'make_test_harness_command' set to default");
    ok(! $self->{skip_test_harness}, "'skip_test_harness' defaulted to off");
    ok(! $self->{verbose}, "'verbose' defaulted to off");
}

{
    my %theseopts = map { $_ => $opts->{$_} } keys %{$opts};
    delete $theseopts{branch};
    delete $theseopts{configure_command};
    delete $theseopts{make_test_prep_command};
    delete $theseopts{make_test_harness_command};
    $theseopts{skip_test_harness} = 1;
    $theseopts{verbose} = 1;
    my $self = Perl5::TestEachCommit->new( \%theseopts );
    is($self->{branch}, 'blead', "'branch' defaulted to blead");
    is($self->{configure_command}, 'sh ./Configure -des -Dusedevel',
        "'configure_command' set to default");
    is($self->{make_test_prep_command}, 'make test_prep',
        "'make_test_prep_command' set to default");
    is($self->{make_test_harness_command}, 'make test_harness',
        "'make_test_harness_command' set to default");
    ok($self->{skip_test_harness}, "'skip_test_harness' set to true value");
    ok($self->{verbose}, "'verbose' set to true value");
}

note("Testing display_plan()");

{
    my $cnull = "sh ./Configure -des -Dusedevel 1>/dev/null";
    my $mtpnull = "make test_prep 1>/dev/null";
    my $mthnull = "make_test_harness 1>/dev/null";
    my %theseopts = map { $_ => $opts->{$_} } keys %{$opts};
    $theseopts{configure_command} = $cnull;
    $theseopts{make_test_prep_command} = $mtpnull;
    $theseopts{make_test_harness_command} = $mthnull;
    my $self = Perl5::TestEachCommit->new( \%theseopts );
    my $rv;
    my $stdout = capture_stdout {
        $rv = $self->display_plan();
    };
    ok($rv, "display_plan returned true value");
    my @lines = split /\n/, $stdout;
    for my $l (@lines[1..3]) {
        like($l,
            qr/command .*? 1>\/dev\/null/x,
            "Got expected portion of display_plan output");
    }
}

{
    my $cnull = "sh ./Configure -des -Dusedevel 1>/dev/null";
    my $mtpnull = "make test_prep 1>/dev/null";
    my $mthnull = "make_test_harness 1>/dev/null";
    my %theseopts = map { $_ => $opts->{$_} } keys %{$opts};
    $theseopts{configure_command} = $cnull;
    $theseopts{make_test_prep_command} = $mtpnull;
    $theseopts{make_test_harness_command} = $mthnull;
    $theseopts{skip_test_harness} = 1;
    my $self = Perl5::TestEachCommit->new( \%theseopts );
    my $rv;
    my $stdout = capture_stdout {
        $rv = $self->display_plan();
    };
    ok($rv, "display_plan returned true value");
    my @lines = split /\n/, $stdout;
    for my $l (@lines[1..2]) {
        like($l,
            qr/command .*? 1>\/dev\/null/x,
            "Got expected portion of display_plan output");
    }
    like($lines[3], qr/Skipping 'make test_harness'/,
        "Plan reported skipping make_test_harness");
}

note("Testing miniperl-level options");

my $miniopts = {
    branch => "blead",
    configure_command => "sh ./Configure -des -Dusedevel",
    end => "002",
    make_test_prep_command => "make test_prep",
    make_test_harness_command => "make test_harness",
    make_minitest_prep_command => "make minitest_prep",
    make_minitest_command => "make minitest",
    skip_test_harness => "",
    start => "001",
    verbose => "",
    workdir => "/tmp",
};

my $miniself = Perl5::TestEachCommit->new( $miniopts );
ok($miniself, "new() returned true value");
isa_ok($miniself, 'Perl5::TestEachCommit',
    "object is a Perl5::TestEachCommit object");

{
    my %theseopts = map { $_ => $miniopts->{$_} } keys %{$miniopts};
    delete $theseopts{branch};
    delete $theseopts{configure_command};
    delete $theseopts{skip_test_harness};
    delete $theseopts{verbose};
    my $self = Perl5::TestEachCommit->new( \%theseopts );
    ok($self, "new() returned true value");
    isa_ok($self, 'Perl5::TestEachCommit', "object is a Perl5::TestEachCommit object");
    is($self->{branch}, 'blead', "'branch' defaulted to blead");
    is($self->{configure_command}, 'sh ./Configure -des -Dusedevel',
        "'configure_command' set to default");
    ok(! $self->{make_test_prep_command},
        "testing miniperl-level options: 'make_test_prep_command' set to false");
    ok(!$self->{make_test_harness_command},
        "testing miniperl-level options: 'make_test_harness_command' set to false");
    is($self->{make_minitest_prep_command}, 'make minitest_prep',
        "testing miniperl-level options: 'make_minitest_prep_command' set to default");
    is($self->{make_minitest_command}, 'make minitest',
        "testing miniperl-level options: 'make_minitest_command' set to default");
    my $rv;
    my $stdout = capture_stdout {
        $rv = $self->display_plan();
    };
    ok($rv, "display_plan returned true value");
    my @lines = split /\n/, $stdout;
    for my $l (@lines[1..3]) {
        like($l,
            qr/command .*?/x,
            "Got expected portion of display_plan output");
    }
}

{
    my %theseopts = map { $_ => $miniopts->{$_} } keys %{$miniopts};
    delete $theseopts{branch};
    delete $theseopts{configure_command};
    delete $theseopts{skip_test_harness};
    $theseopts{verbose} = 1;
    my $self = Perl5::TestEachCommit->new( \%theseopts );
    ok($self, "new() returned true value");
    isa_ok($self, 'Perl5::TestEachCommit', "object is a Perl5::TestEachCommit object");
    is($self->{branch}, 'blead', "'branch' defaulted to blead");
    is($self->{configure_command}, 'sh ./Configure -des -Dusedevel',
        "'configure_command' set to default");
    ok(! $self->{make_test_prep_command},
        "testing miniperl-level options: 'make_test_prep_command' set to false");
    ok(!$self->{make_test_harness_command},
        "testing miniperl-level options: 'make_test_harness_command' set to false");
    is($self->{make_minitest_prep_command}, 'make minitest_prep',
        "testing miniperl-level options: 'make_minitest_prep_command' set to default");
    is($self->{make_minitest_command}, 'make minitest',
        "testing miniperl-level options: 'make_minitest_command' set to default");
    my $rv;
    my $stdout = capture_stdout {
        $rv = $self->display_plan();
    };
    ok($rv, "display_plan returned true value");
    my @lines = split /\n/, $stdout;
    for my $l (@lines[1..3]) {
        like($l,
            qr/command .*?/x,
            "Got expected portion of display_plan output");
    }
}
