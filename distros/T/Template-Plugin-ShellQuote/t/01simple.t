use Test::More qw(no_plan);
use Template::Plugin::ShellQuote;
use Template;
use String::ShellQuote;
use strict;

my $tt   = Template->new({});
my $vars = {};
my $out;



my $s = '\\';

my @input;
#push @input, '';
push @input, 'foo';
push @input, 'foo bar';
push @input, "'foo*'";
push @input, "'foo bar'";
push @input, "'foo'$s''bar'";
push @input, "$s''foo'";
push @input, "foo 'bar*'";
push @input, "'foo'$s''foo' bar 'baz'$s'";
push @input, "'$s'";
push @input, "$s'";
push @input, "'$s'$s'";

my $expected = <<'EOF';
foo
'foo bar'
\''foo*'\'
\''foo bar'\'
\''foo'\''\'\'''\''bar'\'
'\'\'''\''foo'\'
'foo '\''bar*'\'
\''foo'\''\'\'''\''foo'\'' bar '\''baz'\''\'\'
\''\'\'
'\'\'
\''\'\''\'\'
EOF



$vars->{input} = \@input;

ok($tt->process(\*DATA, $vars, \$out));
is($out,$expected); 


__DATA__
[%- USE ShellQuote -%] 
[%- FOREACH line = input %]
[%- line FILTER shellquote %]
[% END -%]
