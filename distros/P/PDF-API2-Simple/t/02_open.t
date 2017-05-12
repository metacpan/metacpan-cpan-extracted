use Test::More tests => 8;

use_ok(PDF::API2::Simple);

eval{ PDF::API2::Simple->open(); };

ok( $@, 'Caught missing open_file.');

like( $@, qr/Must provide an open_file param for open/, 'Correct error message.');
my $pdf = PDF::API2::Simple->open(
    open_file => 't/files/test.pdf',
    open_page => 2,
    file => 't/files/outfile.pdf',
);

ok( $pdf, 'Got a pdf object back.' );

ok( $pdf->add_font('Arial'), 'Added a font.');

ok( $pdf->text('some text'), 'Added some text.');

$pdf->save();

ok( (-e 't/files/outfile.pdf'), 'File created.');

ok( (unlink 't/files/outfile.pdf'), 'File removed.');
