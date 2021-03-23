# -*- Mode: Perl; -*-

=head1 NAME

03_html_template.t - Test the ability to parse and play html template

=cut

our ($module, $is_ht, $is_hte, $is_ta, $compile_perl);
BEGIN {
    $module = 'Template::Alloy';
    if (grep {/hte/i} @ARGV) {
        $module = 'HTML::Template::Expr';
    } elsif (grep {/ht/i} @ARGV) {
        $module = 'HTML::Template';
    }
    $is_hte = $module eq 'HTML::Template::Expr';
    $is_ht  = $module eq 'HTML::Template';
    $is_ta = $module eq 'Template::Alloy';
};
use strict;
use Test::More tests => ($is_ta) ? 250 : ($is_ht) ? 75 : 82;
use constant test_taint => 0 && eval { require Taint::Runtime };

use_ok($module);

Taint::Runtime::taint_start() if test_taint;

### find a place to allow for testing
my $test_dir = $0 .'.test_dir';
END { rmdir $test_dir }
mkdir $test_dir, 0755;
ok(-d $test_dir, "Got a test dir up and running");


sub process_ok { # process the value and say if it was ok
    my $str  = shift;
    my $test = shift;
    my $vars = shift || {};
    my $conf = local $vars->{'tt_config'} = $vars->{'tt_config'} || [];
    push @$conf, (COMPILE_PERL => $compile_perl) if $compile_perl;
    my $line = (caller)[2];
    delete $vars->{'tt_config'};

    Taint::Runtime::taint(\$str) if test_taint;

    my $obj;
    my $out;
    eval {
        $obj = shift || $module->new(scalarref => \$str, die_on_bad_params => 0, path => $test_dir, @$conf); # new object each time
        $obj->param($vars);
        $out = $obj->output;
    };
    my $err = $@;
    $out = '' if ! defined $out;

    my $ok = ref($test) ? $out =~ $test : $out eq $test;
    if ($ok) {
        ok(1, "Line $line   \"$str\" => \"$out\"");
        return $obj;
    } else {
        ok(0, "Line $line   \"$str\"");
        warn "# Was:\n$out\n# Should've been:\n$test\n";
        print "$err\n";
        if ($obj && $obj->can('dump_parse_tree')) {
            local $obj->{'SYNTAX'} = 'hte';
            print $obj->dump_parse_tree(\$str);
            print $err;
        }
        exit;
    }
}

### create some files to include
my $foo_template = "$test_dir/foo.ht";
END { unlink $foo_template };
open(my $fh, ">$foo_template") || die "Couldn't open $foo_template: $!";
print $fh "Good Day!";
close $fh;

### create some files to include
my $bar_template = "$test_dir/bar.ht";
END { unlink $bar_template };
open($fh, ">$bar_template") || die "Couldn't open $bar_template: $!";
print $fh "(<TMPL_VAR bar>)";
close $fh;

for $compile_perl ((! $is_ta) ? (0) : (0, 1)) {
    my $is_compile_perl = "compile perl ($compile_perl)";

###----------------------------------------------------------------###
print "### VAR ############################################# $is_compile_perl\n";

process_ok("Foo" => "Foo");

process_ok("<TMPL_VAR foo>" => "FOO", {foo => "FOO"});
process_ok("<TMPL_VAR foo>" => "FOO", {foo => "FOO"});
process_ok("<TMPL_VAR name=foo>" => "FOO", {foo => "FOO"});
process_ok("<TMPL_VAR NAME=foo>" => "FOO", {foo => "FOO"});
process_ok("<TMPL_VAR NAME=\"foo\">" => "FOO", {foo => "FOO"});
process_ok("<TMPL_VAR NAME='foo'>" => "FOO", {foo => "FOO"});
process_ok("<TMPL_VAR NAME='foo' >" => "FOO", {foo => "FOO"});
process_ok("<TMPL_VAR \"foo\">" => "FOO", {foo => "FOO"});
process_ok("<TMPL_VAR \'foo\'>" => "FOO", {foo => "FOO"});
process_ok("<TMPL_VAR foo >" => "FOO", {foo => "FOO"});
process_ok("<TMPL_VAR NAME=foo >" => "FOO", {foo => "FOO"});
process_ok("<TMPL_VAR NAME=\"foo\" >" => "FOO", {foo => "FOO"});
process_ok("<TMPL_VAR \"foo\" >" => "FOO", {foo => "FOO"});

process_ok("<TMPL_VAR                 foo>" => "<>",       {foo => "<>"});
process_ok("<TMPL_VAR                 foo>" => "&lt;&gt;", {foo => "<>", tt_config => [default_escape => 'html']});
process_ok("<TMPL_VAR ESCAPE=html     foo>" => "&lt;&gt;", {foo => "<>"});
process_ok("<TMPL_VAR ESCAPE=HTML     foo>" => "&lt;&gt;", {foo => "<>"});
process_ok("<TMPL_VAR ESCAPE=\"HTML\" foo>" => "&lt;&gt;", {foo => "<>"});
process_ok("<TMPL_VAR ESCAPE='HTML'   foo>" => "&lt;&gt;", {foo => "<>"});
process_ok("<TMPL_VAR ESCAPE=1        foo>" => "&lt;&gt;", {foo => "<>"});
process_ok("<TMPL_VAR ESCAPE=0        foo>" => "<>", {foo => "<>"});
process_ok("<TMPL_VAR ESCAPE=NONE     foo>" => "<>", {foo => "<>"});
process_ok("<TMPL_VAR ESCAPE=URL      foo>" => "%3C%3E", {foo => "<>"});
process_ok("<TMPL_VAR ESCAPE=JS       foo>" => "<>\\n\\r\t\\\"\\\'", {foo => "<>\n\r\t\"\'"});

process_ok("<TMPL_VAR foo ESCAPE=html>" => "&lt;&gt;", {foo => "<>"});
process_ok("<TMPL_VAR NAME=foo ESCAPE=html>" => "&lt;&gt;", {foo => "<>"});
process_ok("<TMPL_VAR ESCAPE=html NAME=foo>" => "&lt;&gt;", {foo => "<>"});
process_ok("<TMPL_VAR ESCAPE=html NAME=foo ESCAPE=js>" => "&lt;&gt;", {foo => "<>"});

process_ok("<TMPL_VAR DEFAULT=bar NAME=foo>" => "FOO", {foo => "FOO", bar => "BAR"});
process_ok("<TMPL_VAR DEFAULT=bar foo>" => "FOO", {foo => "FOO", bar => "BAR"});
process_ok("<TMPL_VAR DEFAULT=bar \"foo\">" => "FOO", {foo => "FOO", bar => "BAR"});
process_ok("<TMPL_VAR DEFAULT=bar NAME=foo>d" => "bard", {foo => undef, bar => "BAR"});
process_ok("<TMPL_VAR NAME=foo DEFAULT=bar>d" => "bard", {foo => undef, bar => "BAR"});
process_ok("<TMPL_VAR DEFAULT=bar NAME=foo DEFAULT=bing>d" => "bard");

process_ok("<!--TMPL_VAR foo-->" => "FOO", {foo => "FOO"}) if $is_ta;
process_ok("<!--TMPL_VAR NAME='foo'-->" => "FOO", {foo => "FOO"});

process_ok("<TMPL_VAR NAME=foo>" => '&amp;', {foo => '&', tt_config => [AUTO_FILTER => 'html']}) if $is_ta;

###----------------------------------------------------------------###
print "### IF / ELSE / UNLESS ############################## $is_compile_perl\n";

process_ok("<TMPL_IF foo>bar</TMPL_IF>" => "", {foo => ""});
process_ok("<TMPL_IF foo>bar</TMPL_IF>" => "bar", {foo => "1"});
process_ok("<TMPL_IF foo>bar<TMPL_ELSE>bing</TMPL_IF>" => "bing", {foo => ''});
process_ok("<TMPL_IF foo>bar<TMPL_ELSE>bing</TMPL_IF>" => "bar",  {foo => '1'});
process_ok("<TMPL_IF name=foo>bar<TMPL_ELSE>bing</TMPL_IF>" => "bar",  {foo => '1'});
process_ok("<TMPL_IF name='foo'>bar<TMPL_ELSE>bing</TMPL_IF>" => "bar",  {foo => '1'});
process_ok("<TMPL_IF name=\"foo\">bar<TMPL_ELSE>bing</TMPL_IF>" => "bar",  {foo => '1'});
process_ok("<TMPL_IF \"foo\">bar<TMPL_ELSE>bing</TMPL_IF>" => "bar",  {foo => '1'});
process_ok("<TMPL_IF expr=\"73\">bar<TMPL_ELSE>bing</TMPL_IF>" => "bar")     if ! $is_ht;
process_ok("<TMPL_IF expr=\"1 - 1\">bar<TMPL_ELSE>bing</TMPL_IF>" => "bing") if ! $is_ht;
process_ok("<TMPL_IF expr=\"73\" >bar<TMPL_ELSE>bing</TMPL_IF>" => "bar")    if ! $is_ht;
process_ok("<TMPL_IF expr=\"73>bar</TMPL_IF>" => "")                         if ! $is_ht;
process_ok("<TMPL_IF expr=1 + 2>bar<TMPL_ELSE>bing</TMPL_IF>" => "bar")      if $is_ta;
process_ok("<TMPL_IF 0>bar</TMPL_IF>baz" => "baz");
process_ok("<TMPL_UNLESS foo>bar</TMPL_UNLESS>" => "bar", {foo => ""});
process_ok("<TMPL_UNLESS foo>bar</TMPL_UNLESS>" => "", {foo => "1"});
process_ok("<TMPL_UNLESS 0>bar</TMPL_UNLESS>baz" => "barbaz");
process_ok("<TMPL_UNLESS expr=\"73\">bar<TMPL_ELSE>bing</TMPL_UNLESS>" => "bing")   if ! $is_ht;
process_ok("<TMPL_UNLESS expr=\"1 - 1\">bar<TMPL_ELSE>bing</TMPL_UNLESS>" => "bar") if ! $is_ht;

process_ok("<TMPL_IF ESCAPE=HTML foo>bar</TMPL_IF>baz" => "", {foo => "1"});
process_ok("<TMPL_IF DEFAULT=bar foo>bar</TMPL_IF>baz" => "", {foo => "1"});

###----------------------------------------------------------------###
print "### INCLUDE ######################################### $is_compile_perl\n";

process_ok("<TMPL_INCLUDE blah>bar" => "");
process_ok("<TMPL_INCLUDE foo.ht>" => "Good Day!");
process_ok("<TMPL_INCLUDE $test_dir/foo.ht>" => "Good Day!", {tt_config => [path => '']});
process_ok("<TMPL_INCLUDE NAME=foo.ht>" => "Good Day!");
process_ok("<TMPL_INCLUDE NAME=\"foo.ht\">" => "Good Day!");
process_ok("<TMPL_INCLUDE NAME='foo.ht'>" => "Good Day!");
process_ok("<TMPL_INCLUDE \"foo.ht\">" => "Good Day!");
process_ok("<TMPL_INCLUDE NAME='foo.ht'>" => "", {tt_config => [no_includes => 1]});

process_ok("<TMPL_INCLUDE ESCAPE=HTML NAME='foo.ht'>" => "");
process_ok("<TMPL_INCLUDE DEFAULT=bar NAME='foo.ht'>" => "");

process_ok("<TMPL_INCLUDE EXPR=\"'foo.ht'\">" => "Good Day!")                if $is_ta;
process_ok("<TMPL_INCLUDE EXPR=\"foo\">" => "Good Day!", {foo => 'foo.ht'})  if $is_ta;
process_ok("<TMPL_INCLUDE EXPR=\"sprintf('%s', 'foo.ht')\">" => "Good Day!") if $is_ta;

process_ok("<TMPL_INCLUDE bar.ht>" => "()");
process_ok("<TMPL_INCLUDE bar.ht>" => "(hi)", {bar => 'hi'});

###----------------------------------------------------------------###
print "### EXPR ############################################ $is_compile_perl\n";

process_ok("<TMPL_VAR EXPR=\"sprintf('%d', foo)\">" => "777", {foo => "777"}) if ! $is_ht;
process_ok("<TMPL_VAR EXPR=\"sprintf('%d', foo)\">" => "777", {foo => "777"}) if ! $is_ht;
process_ok("<TMPL_VAR EXPR='sprintf(\"%d\", foo)'>" => "777", {foo => "777"}) if ! $is_ht && ! $is_hte; # odd that HTE can't parse this
process_ok("<TMPL_VAR EXPR=\"sprintf(\"%d\", foo)\">" => "777", {foo => "777"}) if ! $is_ht && ! $is_hte;
process_ok("<TMPL_VAR EXPR=sprintf(\"%d\", foo)>" => "777", {foo => "777"}) if ! $is_ht && ! $is_hte;
process_ok("<TMPL_VAR EXPR=\"sprintf('%s', foo)\">" => "<>", {foo => "<>"}) if ! $is_ht;
process_ok("<TMPL_VAR ESCAPE=HTML EXPR=\"sprintf('%s', foo)\">" => "", {foo => "<>"}) if ! $is_hte;
process_ok("<TMPL_VAR DEFAULT=bar EXPR=foo>" => "", {foo => "FOO", bar => "BAR"});

process_ok("<!--TMPL_VAR EXPR=\"foo\"-->" => "FOO", {foo => "FOO"}) if ! $is_ht && ! $is_hte;

process_ok("<TMPL_VAR EXPR=foo>" => '&amp;', {foo => '&', tt_config => [AUTO_FILTER => 'html']}) if $is_ta;
process_ok("<TMPL_VAR EXPR=foo|none>" => '&', {foo => '&', tt_config => [AUTO_FILTER => 'html']}) if $is_ta;

###----------------------------------------------------------------###
print "### LOOP ############################################ $is_compile_perl\n";

process_ok("<TMPL_LOOP blah></TMPL_LOOP>foo" => "foo");
process_ok("<TMPL_LOOP blah>Hi</TMPL_LOOP>foo" => "foo", {blah => 1}) if $is_ta;
process_ok("<TMPL_LOOP blah>Hi</TMPL_LOOP>foo" => "Hifoo", {blah => {wow => 1}}) if $is_ta;
process_ok("<TMPL_LOOP blah>Hi</TMPL_LOOP>foo" => "HiHifoo", {blah => [{}, {}]});
process_ok("<TMPL_LOOP blah>(<TMPL_VAR i>)</TMPL_LOOP>foo" => "(1)(2)(3)foo", {blah => [{i=>1}, {i=>2}, {i=>3}]});
process_ok("<TMPL_LOOP NAME=\"blah\">(<TMPL_VAR i>)</TMPL_LOOP>foo" => "(1)(2)(3)foo", {blah => [{i=>1}, {i=>2}, {i=>3}]});
process_ok("<TMPL_LOOP EXPR=\"blah\">(<TMPL_VAR i>)</TMPL_LOOP>foo" => "(1)(2)(3)foo", {blah => [{i=>1}, {i=>2}, {i=>3}]}) if $is_ta;
process_ok("<TMPL_LOOP blah>(<TMPL_VAR i>)(<TMPL_VAR blue>)</TMPL_LOOP>foo" => "(1)()(2)()(3)()foo", {blah => [{i=>1}, {i=>2}, {i=>3}], blue => 'B'}) if $is_ht;
process_ok("<TMPL_LOOP blah>(<TMPL_VAR i>)(<TMPL_VAR blue>)</TMPL_LOOP>foo" => "(1)(B)(2)(B)(3)(B)foo", {blah => [{i=>1}, {i=>2}, {i=>3}], blue => 'B', tt_config => [GLOBAL_VARS => 1]});

process_ok("<TMPL_LOOP blah>(<TMPL_VAR i>)(<TMPL_VAR blue>)</TMPL_LOOP>foo" => "(1)()(2)()(3)()foo", {blah => [{i=>1}, {i=>2}, {i=>3}], blue => 'B', tt_config => [SYNTAX => 'ht']}) if $is_ta;
process_ok("<TMPL_LOOP blah>(<TMPL_VAR i>)(<TMPL_VAR blue>)</TMPL_LOOP>foo" => "(1)(B)(2)(B)(3)(B)foo", {blah => [{i=>1}, {i=>2}, {i=>3}], blue => 'B', tt_config => [GLOBAL_VARS => 1, SYNTAX => 'ht']}) if $is_ta;

process_ok("<TMPL_LOOP blah>(<TMPL_VAR i>)</TMPL_LOOP>foo" => "(1)()(3)foo", {blah => [{i=>1}, undef, {i=>3}]});

process_ok("<TMPL_LOOP blah>\n(<TMPL_VAR __first__>|<TMPL_VAR __last__>|<TMPL_VAR __odd__>|<TMPL_VAR __inner__>|<TMPL_VAR __counter__>)</TMPL_LOOP>foo" => "
(||||)
(||||)
(||||)foo", {blah => [undef, undef, undef]});

process_ok("<TMPL_LOOP blah>\n(<TMPL_VAR __first__>|<TMPL_VAR __last__>|<TMPL_VAR __odd__>|<TMPL_VAR __inner__>|<TMPL_VAR __counter__>)</TMPL_LOOP>foo" => "
(1||1|0|1)
(0|0||1|2)
(0|1|1|0|3)foo", {blah => [undef, undef, undef], tt_config => [LOOP_CONTEXT_VARS => 1]}) if ! $is_ta;

process_ok("<TMPL_LOOP blah>\n(<TMPL_VAR __first__>|<TMPL_VAR __last__>|<TMPL_VAR __odd__>|<TMPL_VAR __inner__>|<TMPL_VAR __counter__>)</TMPL_LOOP>foo" => "
(1|0|1|0|1)
(0|0|0|1|2)
(0|1|1|0|3)foo", {blah => [undef, undef, undef], tt_config => [LOOP_CONTEXT_VARS => 1]}) if $is_ta;


###----------------------------------------------------------------###
print "### TT3 DIRECTIVES ################################## $is_compile_perl\n";

process_ok("<TMPL_GET foo>" => "FOO", {foo => "FOO"})    if $is_ta;
process_ok("<TMPL_GET foo>" => "", {foo => "FOO", tt_config => [NO_TT => 1]}) if $is_ta;
process_ok("<TMPL_GET foo>" => "", {foo => "FOO", tt_config => [SYNTAX => 'ht']}) if $is_ta;
process_ok("<TMPL_GET 1+2+3+4>" => "10", {foo => "FOO"}) if $is_ta;

process_ok("<TMPL_IF foo>bar<TMPL_ELSIF wow>wee<TMPL_ELSE>bing</TMPL_IF>" => "bar", {foo => "1"}) if $is_ta;

process_ok("<TMPL_SET i = 'foo'>(<TMPL_VAR i>)" => "(foo)") if $is_ta;
process_ok("<TMPL_SET i = 'foo'>(<TMPL_GET i>)" => "(foo)") if $is_ta;
process_ok("<TMPL_FOR i IN [1..3]>(<TMPL_VAR i>)</TMPL_FOR>" => "(1)(2)(3)") if $is_ta;

process_ok("<TMPL_BLOCK foo>(<TMPL_VAR i>)</TMPL_BLOCK><TMPL_PROCESS foo i='bar'>" => "(bar)") if $is_ta;
process_ok("<TMPL_BLOCK foo>(<TMPL_VAR i>)</TMPL_BLOCK><TMPL_SET wow = PROCESS foo i='bar'><TMPL_VAR wow>" => "(bar)") if $is_ta;

process_ok("<TMPL_GET template.foo><TMPL_META foo = 'bar'>" => "bar") if $is_ta;

process_ok('<TMPL_MACRO bar(n) BLOCK>You said <TMPL_VAR n></TMPL_MACRO><TMPL_GET bar("hello")>' => 'You said hello') if $is_ta;

process_ok("<TMPL_GET foo>" => '&amp;', {foo => '&', tt_config => [AUTO_FILTER => 'html']}) if $is_ta;
process_ok("<TMPL_GET foo|none>" => '&', {foo => '&', tt_config => [AUTO_FILTER => 'html']}) if $is_ta;

###----------------------------------------------------------------###
print "### TT3 CHOMPING #################################### $is_compile_perl\n";

process_ok("\n<TMPL_GET foo>" => "\nFOO", {foo => "FOO"}) if $is_ta;
process_ok("<TMPL_GET foo->\n" => "FOO", {foo => "FOO"})  if $is_ta;
process_ok("\n<-TMPL_GET foo>" => "FOO", {foo => "FOO"})  if $is_ta;

###----------------------------------------------------------------###
print "### TT3 INTERPOLATE ################################# $is_compile_perl\n";

process_ok('$foo <TMPL_GET foo> ${ 1 + 2 }' => '$foo FOO ${ 1 + 2 }', {foo => "FOO"}) if $is_ta;
process_ok('$foo <TMPL_GET foo> ${ 1 + 2 }' => 'FOO FOO 3', {foo => "FOO", tt_config => [INTERPOLATE => 1]}) if $is_ta;
process_ok('<TMPL_CONFIG INTERPOLATE => 1>$foo <TMPL_GET foo> ${ 1 + 2 }' => 'FOO FOO 3', {foo => "FOO"}) if $is_ta;

process_ok('Foo $a Bar $!a Baz'     => "Foo 7 Bar 7 Baz", {a => 7, tt_config => ['INTERPOLATE' => 1]}) if $is_ta;
process_ok('Foo $a Bar $!{a} Baz'   => "Foo 7 Bar 7 Baz", {a => 7, tt_config => ['INTERPOLATE' => 1]}) if $is_ta;
process_ok('Foo $a Bar $!a Baz'     => "Foo 7 Bar 7 Baz", {a => 7, tt_config => ['INTERPOLATE' => 1, SHOW_UNDEFINED_INTERP => 1]}) if $is_ta;
process_ok('Foo $a Bar $!{a} Baz'   => "Foo 7 Bar 7 Baz", {a => 7, tt_config => ['INTERPOLATE' => 1, SHOW_UNDEFINED_INTERP => 1]}) if $is_ta;
process_ok('Foo $a Bar $!a Baz'     => "Foo \$a Bar  Baz",   {tt_config => ['INTERPOLATE' => 1, SHOW_UNDEFINED_INTERP => 1]}) if $is_ta;
process_ok('Foo ${a} Bar $!{a} Baz' => "Foo \${a} Bar  Baz", {tt_config => ['INTERPOLATE' => 1, SHOW_UNDEFINED_INTERP => 1]}) if $is_ta;

###----------------------------------------------------------------###
print "### DONE ############################################ $is_compile_perl\n";
} # end of for
