use Test::More;

use Mxpress::PDF;
use Mxpress::PDF::Mechanize;
use WWW::Mechanize::Chrome;
use Log::Log4perl qw(:easy);
	

ok(my $pdf = Mxpress::PDF->new_pdf('test',
	plugins => [qw/screenshot/]
), 'add a page');

ok(my $screenshot = $pdf->screenshot);

is(ref $screenshot, 'Mxpress::PDF::Plugin::Mechanize::Screenshot', 'class');
is($screenshot->align, 'fill', 'align');
is($screenshot->mech_class, 'WWW::Mechanize::Chrome', 'mech');
ok($screenshot->can('add'), 'add');

done_testing();
