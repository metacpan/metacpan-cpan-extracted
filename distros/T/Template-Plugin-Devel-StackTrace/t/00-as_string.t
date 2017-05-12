#!perl -T
use Test::More tests => 4;

BEGIN {
	use_ok( 'Template' );
	use_ok( 'Template::Plugin::Devel::StackTrace' );
}
my $tpl = '[%
USE Devel.StackTrace;
Devel.StackTrace.as_string;
\'Test string\';
%]';
my $out = "";
ok my $template = Template->new,
	"instantiating Template";
	ok $template->process(\$tpl,{},\$out) || die("template->process failed!"),
	"processing template with Devel.StackTrace...";
diag( "Testing Template::Plugin::Devel::StackTrace $Template::Plugin::Devel::StackTrace::VERSION, Perl $], $^X" );
