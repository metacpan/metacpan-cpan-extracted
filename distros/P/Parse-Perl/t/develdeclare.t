use warnings;
use strict;

BEGIN {
	eval {
		require Devel::Declare;
		Devel::Declare->VERSION(0.006002);
	};
	if($@ ne "") {
		require Test::More;
		Test::More::plan(skip_all => "good Devel::Declare unavailable");
	}
}

use Parse::Perl qw(current_environment parse_perl);
use Test::More tests => 2;

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

sub my_quote($) { $_[0] }

sub my_quote_parser {
	my($declarator, $offset) = @_;
	$offset += Devel::Declare::toke_move_past_token($offset);
	$offset += Devel::Declare::toke_skipspace($offset);
	my $len = Devel::Declare::toke_scan_str($offset);
	my $content = Devel::Declare::get_lex_stuff();
	Devel::Declare::clear_lex_stuff();
	my $linestr = Devel::Declare::get_linestr();
	die "surprising len=undef" if !defined($len);
	die "surprising len=$len" if $len <= 0;
	$content =~ s/ //g;
	$content =~ s/([^a-z])/sprintf("\\x{%x}", ord($1))/seg;
	substr $linestr, $offset, $len, "(\"$content\")";
	Devel::Declare::set_linestr($linestr);
}

Devel::Declare->setup_for(__PACKAGE__, {
	my_quote => { const => \&my_quote_parser },
});

my $orig_source = q{
	{;}
	my_quote[    foo    ];
;};
my $source = $orig_source;
my $func = parse_perl(current_environment, $source);
is $source, $orig_source;
is $func->(), "foo";

1;
