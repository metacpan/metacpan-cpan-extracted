use Test::More;

use_ok('Mxpress::PDF');

my $pdf = Mxpress::PDF->new_pdf('test',
	page => {
		background => '#000',
		padding => 5
	},
	toc => {
		font => { colour => '#00f' },
	},
	title => {
		font => { colour => '#f00' },
	},
	subtitle => {
		font => { colour => '#0ff' },
	},
	subsubtitle => {
		font => { colour => '#f0f' },
	},
	text => {
		font => { colour => '#fff' },
	},
)->add_page->title->add(
	'This is a title'
)->toc->placeholder->toc->add(
	title => 'This is a title'
)->text->add(
	'Add some text.'
)->toc->add(
	subtitle => 'This is a subtitle'
)->text->add(
	'Add some more text.'
)->toc->add(
	subsubtitle => 'This is a subsubtitle'
)->text->add(
	'Add some more text.'
)->save();

done_testing();
