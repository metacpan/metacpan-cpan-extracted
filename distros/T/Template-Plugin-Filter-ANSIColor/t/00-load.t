use Test::Most tests => 9;
use Test::Magpie qw{mock verify when};

use Term::ANSIColor;

BEGIN {
    use_ok( 'Template::Plugin::Filter::ANSIColor' );
}

my $filter_instance;
my $text;

lives_ok {
	$filter_instance = Template::Plugin::Filter::ANSIColor->init;
} 'can respond to init query';

isa_ok($filter_instance, 'Template::Plugin::Filter::ANSIColor', 'filter instance');
is($filter_instance->{ _DYNAMIC }, 1, 'dynamic property is set');

lives_ok {
	$text = Template::Plugin::Filter::ANSIColor->filter;
} 'can respond to filter query';

is($text,q{},'filter returns an empty string when called with no arguments');

{
	my $terminfo = mock;
	when($terminfo)->num_by_varname('max_colors')
		->then_return(8);
		
	my $input = 'some text';
	 
	$filter_instance = Template::Plugin::Filter::ANSIColor->init($terminfo);
	$text = $filter_instance->filter($input, ['red', 'on_yellow']);
	is($text, colored(['red on_yellow'],$input), 'filter returns a colored text when colors are enabled' );
}

{
	my $terminfo = mock;
	when($terminfo)->num_by_varname('max_colors')
		->then_return(2);
		
	my $input = 'some text';
	 
	$filter_instance = Template::Plugin::Filter::ANSIColor->init($terminfo);
	$text = $filter_instance->filter($input, ['red', 'on_yellow']);
	is($text, $input, 'filter returns unmodified text when colors are disabled' );
	
}

{
	my $terminfo = mock;
	when($terminfo)->num_by_varname('max_colors')
		->then_return(8);
		
	my $input = 'some text';
	 
	$filter_instance = Template::Plugin::Filter::ANSIColor->init($terminfo, 1);
	$text = $filter_instance->filter($input, ['red', 'on_yellow']);
	is($text, $input, 'filter returns unmodified text when colors are disabled with nocolor = 1' );
	
}