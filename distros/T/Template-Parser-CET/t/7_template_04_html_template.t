# -*- Mode: Perl; -*-

=head1 NAME

03_html_template.t - Test the ability to parse and play html template

=cut

use strict;

use Template;
use Template::Parser::CET;
Template::Parser::CET->activate;

use Test::More tests => 87;
use constant test_taint => 0 && eval { require Taint::Runtime };

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
    push(@$conf, 'SYNTAX', 'hte') if ! grep {/SYNTAX/i} @$conf;
    push @$conf, 'INCLUDE_PATH', $test_dir;
    my $obj  = shift || Template->new(@$conf); # new object each time
    my $out  = '';
    my $line = (caller)[2];
    delete $vars->{'tt_config'};

    Taint::Runtime::taint(\$str) if test_taint;

    Template::Parser::CET->add_top_level_functions($vars);
    $obj->process(\$str, $vars, \$out);
    my $ok = ref($test) ? $out =~ $test : $out eq $test;
    if ($ok) {
        ok(1, "Line $line   \"$str\" => \"$out\"");
        return $obj;
    } else {
        ok(0, "Line $line   \"$str\"");
        warn "# Was:\n$out\n# Should've been:\n$test\n";
        print $obj->error if $obj->can('error');
        print Template::Alloy->dump_parse_tree(\$str);
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

###----------------------------------------------------------------###
print "### VAR ##############################################################\n";

process_ok("Foo" => "Foo");

process_ok("<TMPL_VAR foo>" => "FOO", {foo => "FOO"});
process_ok("<TMPL_VAR foo>" => "FOO", {foo => "FOO"});
process_ok("<TMPL_VAR name=foo>" => "FOO", {foo => "FOO"});
process_ok("<TMPL_VAR NAME=foo>" => "FOO", {foo => "FOO"});
process_ok("<TMPL_VAR NAME=\"foo\">" => "FOO", {foo => "FOO"});
process_ok("<TMPL_VAR NAME='foo'>" => "FOO", {foo => "FOO"});
process_ok("<TMPL_VAR NAME='foo' >" => "FOO", {foo => "FOO"});
process_ok("<TMPL_VAR foo >" => "FOO", {foo => "FOO"});

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
#process_ok("<TMPL_VAR ESCAPE=JS       foo>" => "<>\\n\\r\t\\\"\\\'", {foo => "<>\n\r\t\"\'"});

process_ok("<TMPL_VAR foo ESCAPE=html>" => "&lt;&gt;", {foo => "<>"});
process_ok("<TMPL_VAR NAME=foo ESCAPE=html>" => "&lt;&gt;", {foo => "<>"});
process_ok("<TMPL_VAR ESCAPE=html NAME=foo>" => "&lt;&gt;", {foo => "<>"});
process_ok("<TMPL_VAR ESCAPE=html NAME=foo ESCAPE=js>" => "&lt;&gt;", {foo => "<>"});

process_ok("<TMPL_VAR DEFAULT=bar NAME=foo>" => "FOO", {foo => "FOO", bar => "BAR"});
process_ok("<TMPL_VAR DEFAULT=bar NAME=foo>d" => "bard", {foo => undef, bar => "BAR"});
process_ok("<TMPL_VAR NAME=foo DEFAULT=bar>d" => "bard", {foo => undef, bar => "BAR"});
process_ok("<TMPL_VAR DEFAULT=bar NAME=foo DEFAULT=bing>d" => "bard");

process_ok("<!--TMPL_VAR foo-->" => "FOO", {foo => "FOO"});
process_ok("<!--TMPL_VAR NAME='foo'-->" => "FOO", {foo => "FOO"});

###----------------------------------------------------------------###
print "### IF / ELSE / UNLESS ###############################################\n";

process_ok("<TMPL_IF foo>bar</TMPL_IF>" => "", {foo => ""});
process_ok("<TMPL_IF foo>bar</TMPL_IF>" => "bar", {foo => "1"});
process_ok("<TMPL_IF foo>bar<TMPL_ELSE>bing</TMPL_IF>" => "bing", {foo => ''});
process_ok("<TMPL_IF foo>bar<TMPL_ELSE>bing</TMPL_IF>" => "bar",  {foo => '1'});
process_ok("<TMPL_UNLESS foo>bar</TMPL_UNLESS>" => "bar", {foo => ""});
process_ok("<TMPL_UNLESS foo>bar</TMPL_UNLESS>" => "", {foo => "1"});

process_ok("<TMPL_IF ESCAPE=HTML foo>bar</TMPL_IF>baz" => "", {foo => "1"});
process_ok("<TMPL_IF DEFAULT=bar foo>bar</TMPL_IF>baz" => "", {foo => "1"});

###----------------------------------------------------------------###
print "### INCLUDE ##########################################################\n";

process_ok("<TMPL_INCLUDE blah>bar" => "");
process_ok("<TMPL_INCLUDE foo.ht>" => "Good Day!");
process_ok("<TMPL_INCLUDE NAME=foo.ht>" => "Good Day!");
process_ok("<TMPL_INCLUDE NAME='foo.ht'>" => "Good Day!");
#process_ok("<TMPL_INCLUDE NAME='foo.ht'>" => "", {tt_config => [no_includes => 1]});

process_ok("<TMPL_INCLUDE ESCAPE=HTML NAME='foo.ht'>" => "");
process_ok("<TMPL_INCLUDE DEFAULT=bar NAME='foo.ht'>" => "");

process_ok("<TMPL_INCLUDE EXPR=\"'foo.ht'\">" => "Good Day!")                ;
process_ok("<TMPL_INCLUDE EXPR=\"foo\">" => "Good Day!", {foo => 'foo.ht'})  ;
process_ok("<TMPL_INCLUDE EXPR=\"sprintf('%s', 'foo.ht')\">" => "Good Day!") ;

process_ok("<TMPL_INCLUDE bar.ht>" => "()");
process_ok("<TMPL_INCLUDE bar.ht>" => "(hi)", {bar => 'hi'});

###----------------------------------------------------------------###
print "### EXPR #############################################################\n";

process_ok("<TMPL_VAR ESCAPE=HTML EXPR=\"sprintf('%s', foo)\">" => "", {foo => "<>"});
process_ok("<TMPL_VAR DEFAULT=bar EXPR=foo>" => "", {foo => "FOO", bar => "BAR"});


###----------------------------------------------------------------###
print "### LOOP #############################################################\n";

process_ok("<TMPL_LOOP blah></TMPL_LOOP>foo" => "foo");
process_ok("<TMPL_LOOP blah>Hi</TMPL_LOOP>foo" => "foo", {blah => 1}) ;
process_ok("<TMPL_LOOP blah>Hi</TMPL_LOOP>foo" => "Hifoo", {blah => {wow => 1}}) ;
process_ok("<TMPL_LOOP blah>Hi</TMPL_LOOP>foo" => "HiHifoo", {blah => [{}, {}]});
process_ok("<TMPL_LOOP blah>(<TMPL_VAR i>)</TMPL_LOOP>foo" => "(1)(2)(3)foo", {blah => [{i=>1}, {i=>2}, {i=>3}]});
process_ok("<TMPL_LOOP NAME=\"blah\">(<TMPL_VAR i>)</TMPL_LOOP>foo" => "(1)(2)(3)foo", {blah => [{i=>1}, {i=>2}, {i=>3}]});
process_ok("<TMPL_LOOP EXPR=\"blah\">(<TMPL_VAR i>)</TMPL_LOOP>foo" => "(1)(2)(3)foo", {blah => [{i=>1}, {i=>2}, {i=>3}]}) ;
process_ok("<TMPL_LOOP blah>(<TMPL_VAR i>)(<TMPL_VAR blue>)</TMPL_LOOP>foo" => "(1)(B)(2)(B)(3)(B)foo", {blah => [{i=>1}, {i=>2}, {i=>3}], blue => 'B', tt_config => [GLOBAL_VARS => 1]});

process_ok("<TMPL_LOOP blah>(<TMPL_VAR i>)(<TMPL_VAR blue>)</TMPL_LOOP>foo" => "(1)()(2)()(3)()foo", {blah => [{i=>1}, {i=>2}, {i=>3}], blue => 'B', tt_config => [SYNTAX => 'ht']}) ;
process_ok("<TMPL_LOOP blah>(<TMPL_VAR i>)(<TMPL_VAR blue>)</TMPL_LOOP>foo" => "(1)(B)(2)(B)(3)(B)foo", {blah => [{i=>1}, {i=>2}, {i=>3}], blue => 'B', tt_config => [GLOBAL_VARS => 1, SYNTAX => 'ht']}) ;

process_ok("<TMPL_LOOP blah>(<TMPL_VAR i>)</TMPL_LOOP>foo" => "(1)()(3)foo", {blah => [{i=>1}, undef, {i=>3}]});

process_ok("<TMPL_LOOP blah>\n(<TMPL_VAR __first__>|<TMPL_VAR __last__>|<TMPL_VAR __odd__>|<TMPL_VAR __inner__>|<TMPL_VAR __counter__>)</TMPL_LOOP>foo" => "
(||||)
(||||)
(||||)foo", {blah => [undef, undef, undef]});

local $Template::Stash::PRIVATE = 0;
process_ok("<TMPL_LOOP blah>\n(<TMPL_VAR __first__>|<TMPL_VAR __last__>|<TMPL_VAR __odd__>|<TMPL_VAR __inner__>|<TMPL_VAR __counter__>)</TMPL_LOOP>foo" => "
(1|0|1|0|1)
(0|0|0|1|2)
(0|1|1|0|3)foo", {blah => [undef, undef, undef], tt_config => [LOOP_CONTEXT_VARS => 1]});

process_ok("<TMPL_LOOP blah>\n(<TMPL_VAR __first__>|<TMPL_VAR __last__>|<TMPL_VAR __odd__>|<TMPL_VAR __inner__>|<TMPL_VAR __counter__>)</TMPL_LOOP>foo" => "
(1|0|1|0|1)
(0|0|0|1|2)
(0|1|1|0|3)foo", {blah => [undef, undef, undef], tt_config => [LOOP_CONTEXT_VARS => 1]}) ;


###----------------------------------------------------------------###
print "### TT3 DIRECTIVES ###################################################\n";

process_ok("<TMPL_GET foo>" => "FOO", {foo => "FOO"})    ;
process_ok("<TMPL_GET foo>" => "", {foo => "FOO", tt_config => [NO_TT => 1]}) ;
process_ok("<TMPL_GET foo>" => "", {foo => "FOO", tt_config => [SYNTAX => 'ht']}) ;
process_ok("<TMPL_GET 1+2+3+4>" => "10", {foo => "FOO"}) ;

process_ok("<TMPL_IF foo>bar<TMPL_ELSIF wow>wee<TMPL_ELSE>bing</TMPL_IF>" => "bar", {foo => "1"}) ;

process_ok("<TMPL_SET i = 'foo'>(<TMPL_VAR i>)" => "(foo)") ;
process_ok("<TMPL_SET i = 'foo'>(<TMPL_GET i>)" => "(foo)") ;
process_ok("<TMPL_FOR i IN [1..3]>(<TMPL_VAR i>)</TMPL_FOR>" => "(1)(2)(3)") ;

process_ok("<TMPL_BLOCK foo>(<TMPL_VAR i>)</TMPL_BLOCK><TMPL_PROCESS foo i='bar'>" => "(bar)") ;
process_ok("<TMPL_BLOCK foo>(<TMPL_VAR i>)</TMPL_BLOCK><TMPL_SET wow = PROCESS foo i='bar'><TMPL_VAR wow>" => "(bar)") ;

process_ok("<TMPL_GET template.foo><TMPL_META foo = 'bar'>" => "bar") ;

process_ok('<TMPL_MACRO bar(n) BLOCK>You said <TMPL_VAR n></TMPL_MACRO><TMPL_GET bar("hello")>' => 'You said hello') ;

###----------------------------------------------------------------###
print "### TT3 CHOMPING #####################################################\n";

process_ok("\n<TMPL_GET foo>" => "\nFOO", {foo => "FOO"}) ;
process_ok("<TMPL_GET foo->\n" => "FOO", {foo => "FOO"})  ;
process_ok("\n<-TMPL_GET foo>" => "FOO", {foo => "FOO"})  ;

###----------------------------------------------------------------###
print "### TT3 INTERPOLATE ##################################################\n";

process_ok('$foo <TMPL_GET foo> ${ 1 + 2 }' => '$foo FOO ${ 1 + 2 }', {foo => "FOO"}) ;
process_ok('$foo <TMPL_GET foo> ${ 1 + 2 }' => 'FOO FOO 3', {foo => "FOO", tt_config => [INTERPOLATE => 1]}) ;
process_ok('<TMPL_CONFIG INTERPOLATE => 1>$foo <TMPL_GET foo> ${ 1 + 2 }' => 'FOO FOO 3', {foo => "FOO"}) ;

process_ok('Foo $a Bar $!a Baz'     => "Foo 7 Bar 7 Baz", {a => 7, tt_config => ['INTERPOLATE' => 1]}) ;
process_ok('Foo $a Bar $!{a} Baz'   => "Foo 7 Bar 7 Baz", {a => 7, tt_config => ['INTERPOLATE' => 1]}) ;
process_ok('Foo $a Bar $!a Baz'     => "Foo 7 Bar 7 Baz", {a => 7, tt_config => ['INTERPOLATE' => 1, SHOW_UNDEFINED_INTERP => 1]}) ;
process_ok('Foo $a Bar $!{a} Baz'   => "Foo 7 Bar 7 Baz", {a => 7, tt_config => ['INTERPOLATE' => 1, SHOW_UNDEFINED_INTERP => 1]}) ;
#process_ok('Foo $a Bar $!a Baz'     => "Foo \$a Bar  Baz",   {tt_config => ['INTERPOLATE' => 1, SHOW_UNDEFINED_INTERP => 1]}) ;
#process_ok('Foo ${a} Bar $!{a} Baz' => "Foo \${a} Bar  Baz", {tt_config => ['INTERPOLATE' => 1, SHOW_UNDEFINED_INTERP => 1]}) ;

###----------------------------------------------------------------###
print "### DONE #############################################################\n";
