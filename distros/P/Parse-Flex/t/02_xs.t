use Test::More ;
use Parse::Flex::Generate;

my @func = qw(
	yyget_text
	yyset_in
	yyset_out
	yyget_in
	yyget_out
	yylex
	yylex_int
	yyin
	yyout
	yyget_leng
	yyget_lineno
	yyset_lineno
	yyset_debug
	yyget_debug
	yy_scan_string
	yy_scan_bytes
	yyrestart
	create_push_buffer
	yypop_buffer_state
);

plan tests=> scalar @func  ;

local $_ = xs_content('Flex6') ;

for my $f (@func) {
	ok m/^$f\s*\(/m   => $f ; 
}

__END__
$_ = xs_content 'Flex6'  ;
ok m//                                  =>  'xs_content';
isnt  m/^\t/, 1;

