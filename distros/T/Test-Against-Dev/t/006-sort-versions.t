# -*- perl -*-
# t/006-sort-versions.t
use 5.14.0;
use warnings;
use Capture::Tiny ( qw| capture_stdout capture_stderr | );
use Carp;
use Data::Dump ( qw| dd pp | );
use Test::More;

BEGIN { use_ok( 'Test::Against::Dev::Sort' ); }

#my $cwd = cwd();
my ($self, $minor_dev);

##### new(): TESTS OF ERROR CONDITIONS #####

{
    local $@;
    $minor_dev = undef;
    eval { $self = Test::Against::Dev::Sort->new($minor_dev); };
    like($@, qr/Minor version must be integer/,
        "new: Got expected error message for undefined argument");
}

{
    local $@;
    $minor_dev = 'foo';
    eval { $self = Test::Against::Dev::Sort->new($minor_dev); };
    like($@, qr/Minor version must be integer/,
        "new: Got expected error message for non-numeric argument");
}

{
    local $@;
    $minor_dev = 42;
    eval { $self = Test::Against::Dev::Sort->new($minor_dev); };
    like($@, qr/Minor version must be odd/,
        "new: Got expected error message for non-odd-numbered argument");
}
{
    local $@;
    $minor_dev = 5;
    eval { $self = Test::Against::Dev::Sort->new($minor_dev); };
    like($@, qr/Minor version must be >= 7/,
        "new: Got expected error message for unsupported Perl version (less than 7)");
}

##### new(): TESTS OF CORRECTLY CONSTRUCTED OBJECTS #####

for my $mv (7, 9, 25, 27, 29) {
    $self = Test::Against::Dev::Sort->new($mv);
    ok(defined $self, "new() returned defined value");
    isa_ok($self, 'Test::Against::Dev::Sort');
    cmp_ok($self->{minor_dev}, '==', $mv, "minor_dev set to $mv as expected");
    my $exp_rc = $mv + 1;
    cmp_ok($self->{minor_rc},  '==', $exp_rc, "minor_rc set to $exp_rc as expected");
}

my @valid_versions = ( qw|
    perl-5.27.10
    perl-5.28.0-RC4
    perl-5.27.0
    perl-5.27.9
    perl-5.28.0-RC1
    perl-5.27.11
| );

{
    $minor_dev = 27;
    $self = Test::Against::Dev::Sort->new($minor_dev);
    ok(defined $self, "new() returned defined value");
    isa_ok($self, 'Test::Against::Dev::Sort');

    my $sort_expected = [ qw|
        perl-5.27.0
        perl-5.27.9
        perl-5.27.10
        perl-5.27.11
        perl-5.28.0-RC1
        perl-5.28.0-RC4
    | ];
    my $aref = $self->sort_dev_and_rc_versions(\@valid_versions);
    is_deeply($aref, $sort_expected, "Got expected sort") and dd($aref);
    is(scalar @{$self->get_non_matches()}, 0, "No non-matches, as expected");
}

{
    $minor_dev = 27;
    $self = Test::Against::Dev::Sort->new($minor_dev);
    ok(defined $self, "new() returned defined value");
    isa_ok($self, 'Test::Against::Dev::Sort');

    my $sort_expected = [ qw|
        perl-5.27.0
        perl-5.27.9
        perl-5.27.10
        perl-5.27.11
        perl-5.28.0-RC1
        perl-5.28.0-RC4
    | ];
    my @these_versions = map {$_} @valid_versions;
    my @bad_versions = (
        'perl-5.28.0',
        'perl-5.25.1',
        'perl-5.26.11',
        'perl-5.26.0-RC1',
        'perl-5.28.1',
        'perl-5.28.1-RC3',
        '5.27.0',
        '5.27.9',
        '5.27.10',
        '5.27.11',
        '5.28.0-RC1',
        '5.28.0-RC4',
        'foo'
    );
    push @these_versions, @bad_versions;
    my $aref = $self->sort_dev_and_rc_versions(\@these_versions);
    is_deeply($aref, $sort_expected, "Got expected sort") and dd($aref);
    is(scalar @{$self->get_non_matches()},
        scalar @bad_versions, "Got expected number of non-matches") or dd($self->get_non_matches());
    my $stdout = capture_stdout {
        $self->dump_non_matches();
    };
    for my $el (@bad_versions) {
        like($stdout, qr/$el/s, "Got expected bad version '$el' in STDOUT");
    }
}


done_testing();
