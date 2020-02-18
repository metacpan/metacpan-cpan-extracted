use Test::More;

use Mxpress::PDF;
use Mxpress::PDF::Mechanize;

ok(my $pdf = Mxpress::PDF->new_pdf('test',
	plugins => [qw/screenshot/]
), 'add a page');

ok(my $screenshot = $pdf->screenshot);

is(ref $screenshot, 'Mxpress::PDF::Plugin::Mechanize::Screenshot', 'class');
is($screenshot->align, 'fill', 'align');
is($screenshot->mech_class, 'WWW::Mechanize::Chrome', 'mech');
ok($screenshot->can('add'), 'add');
ok($screenshot->can('take'), 'take');

$pdf->save;

done_testing();
