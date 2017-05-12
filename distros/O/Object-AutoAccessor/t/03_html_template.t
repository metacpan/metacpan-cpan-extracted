use strict;
use Test::More qw(no_plan);
use Object::AutoAccessor;

my $obj = Object::AutoAccessor->new;

$obj->foo('test');
is($obj->foo, 'test');

SKIP: {
	eval { require HTML::Template; };
	skip "HTML::Template not installed", 2 if $@;
	
	$obj->bar([]);
	$obj->bar->[0] = {foo=>1,bar=>2};
	$obj->bar->[1] = {foo=>3,bar=>4,baz=>[{foo=>1,bar=>2}]};
	$obj->bar->[2] = {foo=>5,bar=>6};
	
	my $tmpl = HTML::Template->new(
		filehandle	=> *DATA,
		associate	=> [$obj],
		die_on_bad_params	=> 0,
	);
	
	isa_ok($tmpl, "HTML::Template");
	
	is($tmpl->output(), "TMPL:test[LOOP:BAR 12[LOOP:BAZ ]34[LOOP:BAZ 12]56[LOOP:BAZ ]]:END");
}

__END__
TMPL:<tmpl_var name="foo">[LOOP:BAR <tmpl_loop name="bar"><tmpl_var name="foo"><tmpl_var name="bar">[LOOP:BAZ <tmpl_loop name="baz"><tmpl_var name="foo"><tmpl_var name="bar"></tmpl_loop>]</tmpl_loop>]:END