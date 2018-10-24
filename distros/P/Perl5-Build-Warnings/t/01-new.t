# -*- perl -*-
# t/01-new.t - Check constructor

use 5.14.0;
use warnings;
use Test::More;
use Capture::Tiny ':all';

BEGIN { use_ok( 'Perl5::Build::Warnings' ); }

my ($self, $file, $rv, $stdout, @stdout, $wg, $xg);
my ($warnings_count);

##### TESTS OF ERROR CONDITIONS #####

{
    local $@;
    eval { $self = Perl5::Build::Warnings->new(); };
    like($@, qr/Argument to constructor must be hashref/,
        "Got expected error message: no argument for new()");
}

{
    local $@;
    eval { $self = Perl5::Build::Warnings->new( 'file' => 'foo' ); };
    like($@, qr/Argument to constructor must be hashref/,
        "Got expected error message: argument for new() not a hashref");
}

{
    local $@;
    eval { $self = Perl5::Build::Warnings->new( [ 'file' => 'foo' ] ); };
    like($@, qr/Argument to constructor must be hashref/,
        "Got expected error message: argument for new() not a hashref");
}

{
    local $@;
    eval { $self = Perl5::Build::Warnings->new( { foo => 'bar' } ); };
    like($@, qr/Argument to constructor must contain 'file' element/,
        "Got expected error message: argument for new() must contain 'file' element");
}

{
    local $@;
    $file = 'bar';
    eval { $self = Perl5::Build::Warnings->new( { file => $file } ); };
    like($@, qr/Cannot locate $file/,
        "Got expected error message: cannot locate value for 'file' element");
}

##### TESTS OF VALID CODE #####

{
    $file = "./t/data/make.g++-8-list-util-fallthrough.output.txt";
    $self = Perl5::Build::Warnings->new( { file => $file } );
    ok(defined $self, "Constructor returned defined object");
    isa_ok($self, 'Perl5::Build::Warnings');

    $stdout = capture_stdout {
        $self->report_warnings_groups;
    };
    like($stdout, qr/Wimplicit-fallthrough=\s+32/,
        "Reported implicit-fallthrough warning");

    @stdout = split /\n/ => $stdout;
    is(@stdout, 7, "report_warnings_groups(): 7 types of warnings reported");

    $wg = $self->get_warnings_groups;
    is(ref($wg), 'HASH', "get_warnings_groups() returned hashref");
    is(scalar keys %{$wg}, 7, "7 types of warnings found");
    is($wg->{'Wimplicit-fallthrough='}, 32, "Found 32 instances of implicit-fallthrough warnings");
    $warnings_count = 0;
    map { $warnings_count += $_ } values %{$wg};
    is($warnings_count, 50, "Got total of 50 warnings");

    $xg = $self->get_warnings;
    is(ref($xg), 'ARRAY', "get_warnings() returned arrayref");
    is(scalar @{$xg}, $warnings_count, "Got expected number of warnings");
}

done_testing();

