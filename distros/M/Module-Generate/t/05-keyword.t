use Test::More;

our $loaded;
BEGIN {
	eval {
		require Moo;
		Moo->can('is_class');
		1;
	} or do {
		print $@;
		plan skip_all => "Moo is not available";
		done_testing();
	};
	use Module::Generate;
	Module::Generate->lib('./t/lib')
		->tlib('./t/lib')
		->author('LNATION')
		->email('email@lnation.org')
		->version('0.01')
		->keyword('with', sub {
			my ($meta) = @_;
			return qq|with $meta->{with};|;
		})
		->keyword('has', 
			CODE => sub {
				my ($meta) = @_;
				$meta->{is} ||= q|'ro'|;
				my $attributes = join ', ', map { 
					($meta->{$_} ? (sprintf "%s => %s", $_, $meta->{$_}) : ()) 
				} qw/is required/;
				my $code = qq|
					has $meta->{has} => ( $attributes );|;
				return $code;
			}, 
			KEYWORDS => [qw/is required/], 
			POD_TITLE => 'ATTRIBUTES',
			POD_POD => 'get or set $keyword',
			POD_EXAMPLE => "\$obj->\$keyword;\n\n\t\$obj->\$keyword(\$value);"  
		)
		->class('Keyword')
			->use('Moo')
			->with(qw/'Keyword::Role'/)
				->test(
					['ok', q|my $obj = Keyword->new( thing => 'abc', test => 'def' )|],
					['is', q|$obj->test|, q|'def'|]
				)
			->has('thing')->required(1)
				->test(
					['ok', q|my $obj = Keyword->new( thing => 'abc' )|],
					['is', q|$obj->thing|, q|'abc'|],
					['eval', q|$obj = Keyword->new()|, 'required'] 
				)
		->class('Keyword::Role')
			->use('Moo::Role')
			->has('test')->is(q|'rw'|)
				->test(
					['ok', q|my $obj = do { eval q{
						package FooBar;
						use Moo;
						with 'Keyword::Role';
						1;
					}; 1; } && FooBar->new| ],
					['is', q|$obj->test|, q|undef|],
					['ok', q|$obj->test('abc')|],
					['is', q|$obj->test|, q|'abc'|]
				)
	->generate;
	ok(1, 'GENERATE');
}

use lib 't/lib';
use Keyword;

my $foo = Keyword->new( thing => 'abc' );

is($foo->test, undef);

my $lame = 't/lib/Keyword.t';
open my $fh, '<', $lame;
my $content  = do { local $/; <$fh> };
close $fh;
$content =~ s/done_testing\(\);//g;
eval $content;

$lame = 't/lib/Keyword-Role.t';
open my $fh, '<', $lame;
my $content  = do { local $/; <$fh> };
close $fh;
eval $content;
