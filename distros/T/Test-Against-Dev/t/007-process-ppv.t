# -*- perl -*-
# t/007-process-ppv.t
use 5.14.0;
use warnings;
use Carp;
use Cwd;
use Data::Dump ( qw| dd pp | );
use File::Copy;
use File::Path 2.15 ( qw| make_path | );
use File::Spec;
use File::Temp qw( tempdir );
use Path::Tiny;
use Test::More;
use Test::Against::Dev::ProcessPSV;

my $start_dir = cwd();
my $title = 'cpan-river-1000';
my $v = 'perl-5.27';

my $v0 = "${v}.0";
my $baseline_psv = "$title-$v0.psv";
my $fbaseline_psv = File::Spec->catfile($start_dir, 't', 'data', $baseline_psv);

my $v1 = "${v}.1";
my $next_psv = "$title-$v1.psv";
my $fnext_psv = File::Spec->catfile($start_dir, 't', 'data', $next_psv);

my ($fbaseline_target, $fnext_target) = ('') x 2;

for my $f ($fbaseline_psv, $fnext_psv) {
    ok(-f $f, "Located $f for testing");
}

{
    my @created = ();
    my $tdir = tempdir(CLEANUP => 1);
    chdir $tdir or croak "Unable to chdir to $tdir";
    my $results_dir = File::Spec->catdir($tdir, 'results');
    @created = make_path($results_dir, { mode => 0711 })
        or croak "Unable to create $results_dir";
    ok(-d $results_dir, "Created $results_dir for testing");
    my %dirs_needed = ();
    for my $pv ($v0, $v1) {
        my $storage_dir = File::Spec->catdir($results_dir, $pv, 'storage');
        $dirs_needed{"${pv}_storage"} = $storage_dir;
    }
    #dd(\%dirs_needed);
    for my $d (keys %dirs_needed) {
        @created = make_path($dirs_needed{$d}, { mode => 0711 })
            or croak "Unable to create $dirs_needed{$d}";
        ok(-d $dirs_needed{$d}, "Created $dirs_needed{$d} for testing");
    }

    $fbaseline_target = File::Spec->catfile(
        $dirs_needed{'perl-5.27.0_storage'},
        $baseline_psv,
    );
    copy $fbaseline_psv => $fbaseline_target
        or croak "Unable to copy $fbaseline_psv to $dirs_needed{'perl-5.27.0_storage'}";
    ok(-f $fbaseline_target,
        "Copied $fbaseline_psv to $dirs_needed{'perl-5.27.0_storage'} for testing");

    #my (@lines_in, $master_data, $verbose, $columns, $expected_columns,
    my (@lines_in, $verbose, $columns_seen, $expected_columns,
        $lines_out, @lines_out,
        $master_columns_ref, $master_psv, $rv,
        $message,
    );

    @lines_in = path($fbaseline_target)->lines_utf8;
    #$master_data = {};
    $verbose = 1;
    my $ppsv = Test::Against::Dev::ProcessPSV->new( { verbose => $verbose } );
    ok(defined $ppsv, "new() returned defined value");
    isa_ok($ppsv, 'Test::Against::Dev::ProcessPSV');

    $columns_seen = $ppsv->read_one_psv( {
        psvfile => $fbaseline_target,
    } );

    $expected_columns = [
      "dist",
      "perl-5.27.0.author",
      "perl-5.27.0.distname",
      "perl-5.27.0.distversion",
      "perl-5.27.0.grade",
    ];
    is_deeply($columns_seen, $expected_columns,
        "Got expected columns when reading $fbaseline_target");
    $lines_out = scalar keys %{$ppsv->{master_data}};
    # The number of elements in $master_data should be 1 less than
    # the line count in the .psv file -- that 1 being the header row.
    cmp_ok($lines_out, '==', scalar(@lines_in) - 1, "Got expected count");

   # Before going on to the next month, we write the first instance of the
   # master psv file.

    $master_columns_ref = [
      "dist",
      "perl-5.27.0.author",
      "perl-5.27.0.distname",
      "perl-5.27.0.distversion",
      "perl-5.27.0.grade",
    ];
    $master_psv = File::Spec->catfile(
        $results_dir,
        "$title-$v-master.psv",
    );
    ok(! -f $master_psv, "Master PSV file $master_psv does not yet exist");

    $rv = $ppsv->write_master_psv({
        master_columns  => $master_columns_ref,
        master_psvfile  => $master_psv,
     });
    ok($rv, "write_master_psv() returned true value");
    ok(-f $master_psv, "Consolidated PSV files into $master_psv");
    @lines_out = path($master_psv)->lines_utf8;
    cmp_ok(scalar(@lines_out), '==', scalar(@lines_in),
        "Only 1 month so far, so line count in master psv matches line count in monthly psv",
    );

    # Now we simulate the next month.

    $fnext_target = File::Spec->catfile(
        $dirs_needed{'perl-5.27.1_storage'},
        $next_psv,
    );
    copy $fnext_psv => $fnext_target
        or croak "Unable to copy $fnext_psv to $dirs_needed{'perl-5.27.1_storage'}";
    ok(-f $fnext_target,
        "Copied $fnext_psv to $dirs_needed{'perl-5.27.1_storage'} for testing");

    @lines_in = path($fnext_target)->lines_utf8;
    my $ppsv2 = Test::Against::Dev::ProcessPSV->new();
    ok(defined $ppsv2, "new() returned defined value");
    isa_ok($ppsv2, 'Test::Against::Dev::ProcessPSV');
    $columns_seen = $ppsv2->read_one_psv( {
        psvfile => $fnext_target,
    } );
    $expected_columns = [
      "dist",
      "perl-5.27.1.author",
      "perl-5.27.1.distname",
      "perl-5.27.1.distversion",
      "perl-5.27.1.grade",
    ];
    is_deeply($columns_seen, $expected_columns,
        "Got expected columns when reading $fnext_target");
    $lines_out = scalar keys %{$ppsv2->{master_data}};
    # The number of elements in $ppsv2->{master_data} should be 1 less than
    # the line count in the .psv file -- that 1 being the header row.
    cmp_ok($lines_out, '==', scalar(@lines_in) - 1, "Got expected count");

    $master_columns_ref = [
      "dist",
      "perl-5.27.0.author",
      "perl-5.27.0.distname",
      "perl-5.27.0.distversion",
      "perl-5.27.0.grade",
      "perl-5.27.1.author",
      "perl-5.27.1.distname",
      "perl-5.27.1.distversion",
      "perl-5.27.1.grade",
    ];
    $rv = $ppsv2->write_master_psv({
        master_columns  => $master_columns_ref,
        master_psvfile  => $master_psv,
     });
    ok($rv, "write_master_psv() returned true value");
    ok(-f $master_psv, "Consolidated PSV files into $master_psv");
    @lines_out = path($master_psv)->lines_utf8;
    $message = "The line count in master psv $master_psv is now " . scalar(@lines_out) . "\n";
    $message .= "It may differ from the line count in the most recent monthly psv, $fnext_target, which is " . scalar(@lines_in);
    pass($message);

    chdir $start_dir or croak "Unable to chdir back to $start_dir";
}

done_testing();
