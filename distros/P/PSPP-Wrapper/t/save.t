use Test::More tests => 2;
use File::Temp;
use File::Spec;

BEGIN {
    use_ok('PSPP::Wrapper');
}

# Generate output files to tmp dir
my $tmpdir = File::Temp->newdir();
my $outfile1 = File::Spec->catfile( $tmpdir, 'test1.sav');
my $outfile2 = File::Spec->catfile( $tmpdir, 'test2.sav');
my $pspp     = PSPP::Wrapper->new( verbose => 0 );
my $rows     = [
    [ "AMC Concord",   22, 2930, 4099 ],
    [ "AMC Pacer",     17, 3350, 4749 ],
    [ "AMC Spirit",    22, 2640, 3799 ],
    [ "Buick Century", 20, 3250, 4816 ],
    [ "Buick Electra", 15, 4080, 7827 ],
];
$pspp->save(
    variables => 'make (A15) mpg weight price',
    rows      => $rows,
    outfile   => $outfile1,
) or warn "An error occurred";

# Generate a csv file ourselves from $rows
my $csv = Text::CSV_XS->new( { binary => 1 } );
my $fh = File::Temp->new( SUFFIX => '.csv' );
for my $row (@$rows) {
    $csv->print( $fh, $row );
    print $fh "\n";
}
$fh->close;

$pspp->save(
    variables => 'make (A15) mpg weight price',
    infile    => $fh->filename,
    outfile   => $outfile2,
) or warn "An error occurred";

use IPC::Run qw( run timeout );
run [ 'diff', $outfile1, $outfile2 ], \undef, \( my $out ) or die "diff: $!";
is( $out, '', 'Outfiles are identical' );
