# -*- Mode: Perl; -*-

=head1 NAME

04_text_tmpl.t - Test the ability to parse and play Text::Tmpl

=cut

use vars qw($module $is_tt $compile_perl);
BEGIN {
    $module = 'Template::Alloy';
    if (grep {/tt|tmpl/i} @ARGV) {
        $module = 'Text::Tmpl';
    }
    $is_tt = $module eq 'Text::Tmpl';
};

use strict;
use Test::More tests => (! $is_tt) ? 100 : 25;
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

    my $obj = shift || $module->new(@$conf); # new object each time
    $obj->set_delimiters('#[', ']#');
    $obj->set_strip(0);
    $obj->set_values($vars);
    $obj->set_dir("$test_dir/");
    if ($vars->{'set_loop'}) {
        foreach my $hash (@{$vars->{'set_loop'}}) {
            my $ref = $obj->loop_iteration('loop1');
            $ref->set_values($hash);
        }
    }

    my $out = eval { $obj->parse_string($str) };
    $out = '' if ! defined $out;

    my $ok = ref($test) ? $out =~ $test : $out eq $test;
    if ($ok) {
        ok(1, "Line $line   \"$str\" => \"$out\"");
        return $obj;
    } else {
        ok(0, "Line $line   \"$str\"");
        warn "# Was:\n$out\n# Should've been:\n$test\n";
        if ($obj->can('dump_parse_tree')) {
            print $obj->strerror if $obj->can('strerror');
            local $obj->{'SYNTAX'} = 'tmpl';
            print $obj->dump_parse_tree(\$str);
            print $obj->strerror if $obj->can('strerror');
        } else {
            print eval($module."::strerror()");
        }
        exit;
    }
}

### create some files to include
my $foo_template = "$test_dir/foo.tmpl";
END { unlink $foo_template };
open(my $fh, ">$foo_template") || die "Couldn't open $foo_template: $!";
print $fh "Good Day!";
close $fh;

### create some files to include
my $bar_template = "$test_dir/bar.tmpl";
END { unlink $bar_template };
open($fh, ">$bar_template") || die "Couldn't open $bar_template: $!";
print $fh "(#[echo \$bar]#)";
close $fh;


for $compile_perl (($is_tt) ? (0) : (0, 1)) {
    my $is_compile_perl = "compile perl ($compile_perl)";

###----------------------------------------------------------------###
print "### ECHO ############################################ $is_compile_perl\n";

process_ok("Foo" => "Foo");

process_ok('#[echo $foo]#bar' => "bar");
process_ok('#[echo $foo]#' => "FOO", {foo => "FOO"});
process_ok('#[echo $foo $foo]#' => "FOOFOO", {foo => "FOO"});
process_ok('#[echo $foo "bar" $foo]#' => "FOObarFOO", {foo => "FOO"});
process_ok('#[echo "hi"]#' => "hi", {foo => "FOO"});
process_ok('#[echo \'hi\']#' => "hi", {foo => "FOO"}) if ! $is_tt;
process_ok('#[echo foo]#' => "FOO", {foo => "FOO"}) if ! $is_tt;

###----------------------------------------------------------------###
print "### COMMENT ######################################### $is_compile_perl\n";

process_ok('#[comment]# Hi there #[endcomment]#bar' => "bar", {foo => "FOO"});
process_ok('#[comment]# Hi there #[end]#bar' => "bar", {foo => "FOO"}) if ! $is_tt;

###----------------------------------------------------------------###
print "### IF / ELSIF / ELSE / IFN ######################### $is_compile_perl\n";

process_ok('#[if $foo]#bar#[endif]#bar' => "bar");
process_ok('#[if "1"]#bar#[endif]#' => "bar");
process_ok('#[if $foo]#bar#[endif]#' => "", {foo => ""});
process_ok('#[if $foo]#bar#[endif]#' => "bar", {foo => "1"});
process_ok('#[ifn $foo]#bar#[endifn]#' => "bar", {foo => ""});
process_ok('#[ifn $foo]#bar#[endifn]#' => "", {foo => "1"});
process_ok('#[if foo]#bar#[endif]#' => "", {foo => ""})     if ! $is_tt;
process_ok('#[if foo]#bar#[endif]#' => "bar", {foo => "1"}) if ! $is_tt;
process_ok('#[if $foo]#bar#[else]#bing#[endif]#' => "bing", {foo => ''})  if ! $is_tt;
process_ok('#[if $foo]#bar#[else]#bing#[endif]#' => "bar",  {foo => '1'}) if ! $is_tt;
process_ok('#[if $foo]#bar#[elsif wow]#wee#[else]#bing#[endif]#' => "bar",  {foo => 1})  if ! $is_tt;
process_ok('#[if $foo]#bar#[elsif wow]#wee#[else]#bing#[endif]#' => "wee",  {wow => 1})  if ! $is_tt;
process_ok('#[if $foo]#bar#[elsif wow]#wee#[else]#bing#[endif]#' => "bing", {foo => ''}) if ! $is_tt;

####----------------------------------------------------------------###
print "### INCLUDE ######################################### $is_compile_perl\n";

process_ok('#[include "wow.tmpl"]#bar' => "bar") if $is_tt;
process_ok('#[include "foo.tmpl"]#' => "Good Day!");
process_ok("#[include \"$test_dir/foo.tmpl\"]#" => "Good Day!");

process_ok('#[include "bar.tmpl"]#' => "()");
process_ok('#[include "bar.tmpl"]#' => "(hi)", {bar => 'hi'});

###----------------------------------------------------------------###
print "### LOOP ############################################ $is_compile_perl\n";

process_ok('#[loop "loop1"]#Hi#[endloop]#foo' => "foo");
process_ok('#[loop "loop1"]#Hi#[endloop]#foo' => "Hifoo", {set_loop => [{}]});
process_ok('#[loop "loop1"]##[echo $bar]##[endloop]#foo' => "bingfoo", {set_loop => [{bar => 'bing'}]});
process_ok('#[loop "loop1"]##[echo $bar]##[endloop]#foo' => "bingfoo", {loop1 => [{bar => 'bing'}]}) if ! $is_tt;
process_ok('#[loop "loop1"]##[echo $bar]##[endloop]#foo' => "bingbangfoo", {set_loop => [{bar => 'bing'}, {bar => 'bang'}]});
process_ok('#[loop "loop1"]##[echo $boop]##[endloop]#foo' => "bopfoo", {boop => 'bop', set_loop => [{bar => 'bing'}]});

###----------------------------------------------------------------###
print "### TT3 DIRECTIVES ################################## $is_compile_perl\n";

process_ok('#[GET foo]#' => "FOO", {foo => "FOO"})    if ! $is_tt;
process_ok('#[GET 1+2+3+4]#' => "10", {foo => "FOO"}) if ! $is_tt;

process_ok('#[IF foo]#bar#[ELSIF wow]#wee#[ELSE]#bing#[ENDIF]#' => "bar", {foo => "1"}) if ! $is_tt;

process_ok('#[SET i = "foo"]#(#[VAR i]#)' => "(foo)") if ! $is_tt;
process_ok('#[SET i = "foo"]#(#[GET i]#)' => "(foo)") if ! $is_tt;
process_ok('#[FOR i IN [1..3]]#(#[VAR i]#)#[END]#' => "(1)(2)(3)") if ! $is_tt;

process_ok('#[BLOCK foo]#(#[VAR i]#)#[END]##[PROCESS foo i="bar"]#' => "(bar)") if ! $is_tt;
process_ok('#[BLOCK foo]#(#[VAR i]#)#[END]##[SET wow = PROCESS foo i="bar"]##[VAR wow]#' => "(bar)") if ! $is_tt;

process_ok('#[GET template.foo]##[META foo = "bar"]#' => "bar") if ! $is_tt;

process_ok('#[MACRO bar(n) BLOCK]#You said #[VAR n]##[END]##[GET bar("hello")]#' => 'You said hello') if ! $is_tt;

###----------------------------------------------------------------###
print "### TT3 CHOMPING #################################### $is_compile_perl\n";

process_ok("\n#[GET foo]#" => "\nFOO", {foo => "FOO"}) if ! $is_tt;
process_ok("#[GET foo-]#\n" => "FOO", {foo => "FOO"})  if ! $is_tt;
process_ok("\n#[-GET foo]#" => "FOO", {foo => "FOO"})  if ! $is_tt;

###----------------------------------------------------------------###
print "### TT3 INTERPOLATE ################################# $is_compile_perl\n";

process_ok('$foo #[GET foo]# ${ 1 + 2 }' => '$foo FOO ${ 1 + 2 }', {foo => "FOO"}) if ! $is_tt;
process_ok('$foo #[GET foo]# ${ 1 + 2 }' => 'FOO FOO 3', {foo => "FOO", tt_config => [INTERPOLATE => 1]}) if ! $is_tt;
process_ok('#[CONFIG INTERPOLATE => 1]#$foo #[GET foo]# ${ 1 + 2 }' => 'FOO FOO 3', {foo => "FOO"}) if ! $is_tt;

###----------------------------------------------------------------###
print "### DONE ############################################ $is_compile_perl\n";
} # end of for
