# -*- Mode: Perl; -*-

=head1 NAME

04_text_tmpl.t - Test the ability to parse and play Text::Tmpl

=cut

use strict;

use Template;
use Template::Parser::CET;
Template::Parser::CET->activate;

use Test::More tests => 44;
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
    push(@$conf, 'SYNTAX', 'tmpl', START_TAG => qr{\#\[}, END_TAG => qr{\]\#}) if ! grep {/SYNTAX/i} @$conf;
    push @$conf, 'INCLUDE_PATH', $test_dir;
    my $obj  = shift || Template->new(@$conf); # new object each time
    my $out  = '';
    my $line = (caller)[2];
    delete $vars->{'tt_config'};

    Taint::Runtime::taint(\$str) if test_taint;

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


###----------------------------------------------------------------###
print "### ECHO #############################################################\n";

process_ok("Foo" => "Foo");

process_ok('#[echo $foo]#bar' => "bar");
process_ok('#[echo $foo]#' => "FOO", {foo => "FOO"});
process_ok('#[echo $foo $foo]#' => "FOOFOO", {foo => "FOO"});
process_ok('#[echo $foo "bar" $foo]#' => "FOObarFOO", {foo => "FOO"});
process_ok('#[echo "hi"]#' => "hi", {foo => "FOO"});
process_ok('#[echo \'hi\']#' => "hi", {foo => "FOO"}) ;
process_ok('#[echo foo]#' => "FOO", {foo => "FOO"}) ;

###----------------------------------------------------------------###
print "### COMMENT ##########################################################\n";

process_ok('#[comment]# Hi there #[endcomment]#bar' => "bar", {foo => "FOO"});
process_ok('#[comment]# Hi there #[end]#bar' => "bar", {foo => "FOO"}) ;

###----------------------------------------------------------------###
print "### IF / ELSIF / ELSE / IFN ##########################################\n";

process_ok('#[if $foo]#bar#[endif]#bar' => "bar");
process_ok('#[if "1"]#bar#[endif]#' => "bar");
process_ok('#[if $foo]#bar#[endif]#' => "", {foo => ""});
process_ok('#[if $foo]#bar#[endif]#' => "bar", {foo => "1"});
process_ok('#[ifn $foo]#bar#[endifn]#' => "bar", {foo => ""});
process_ok('#[ifn $foo]#bar#[endifn]#' => "", {foo => "1"});
process_ok('#[if foo]#bar#[endif]#' => "", {foo => ""})     ;
process_ok('#[if foo]#bar#[endif]#' => "bar", {foo => "1"}) ;
process_ok('#[if $foo]#bar#[else]#bing#[endif]#' => "bing", {foo => ''})  ;
process_ok('#[if $foo]#bar#[else]#bing#[endif]#' => "bar",  {foo => '1'}) ;
process_ok('#[if $foo]#bar#[elsif wow]#wee#[else]#bing#[endif]#' => "bar",  {foo => 1})  ;
process_ok('#[if $foo]#bar#[elsif wow]#wee#[else]#bing#[endif]#' => "wee",  {wow => 1})  ;
process_ok('#[if $foo]#bar#[elsif wow]#wee#[else]#bing#[endif]#' => "bing", {foo => ''}) ;

####----------------------------------------------------------------###
print "### INCLUDE ##########################################################\n";

#process_ok('#[include "wow.tmpl"]#bar' => "bar") if $is_tt;
process_ok('#[include "foo.tmpl"]#' => "Good Day!");
#process_ok("#[include \"$test_dir/foo.tmpl\"]#" => "Good Day!");

process_ok('#[include "bar.tmpl"]#' => "()");
process_ok('#[include "bar.tmpl"]#' => "(hi)", {bar => 'hi'});

###----------------------------------------------------------------###
print "### LOOP #############################################################\n";

process_ok('#[loop "loop1"]#Hi#[endloop]#foo' => "foo");
#process_ok('#[loop "loop1"]#Hi#[endloop]#foo' => "Hifoo", {set_loop => [{}]});
#process_ok('#[loop "loop1"]##[echo $bar]##[endloop]#foo' => "bingfoo", {set_loop => [{bar => 'bing'}]});
#process_ok('#[loop "loop1"]##[echo $bar]##[endloop]#foo' => "bingfoo", {loop1 => [{bar => 'bing'}]}) ;
#process_ok('#[loop "loop1"]##[echo $bar]##[endloop]#foo' => "bingbangfoo", {set_loop => [{bar => 'bing'}, {bar => 'bang'}]});
#process_ok('#[loop "loop1"]##[echo $boop]##[endloop]#foo' => "bopfoo", {boop => 'bop', set_loop => [{bar => 'bing'}]});

###----------------------------------------------------------------###
print "### TT3 DIRECTIVES ###################################################\n";

process_ok('#[GET foo]#' => "FOO", {foo => "FOO"})    ;
process_ok('#[GET 1+2+3+4]#' => "10", {foo => "FOO"}) ;

process_ok('#[IF foo]#bar#[ELSIF wow]#wee#[ELSE]#bing#[ENDIF]#' => "bar", {foo => "1"}) ;

process_ok('#[SET i = "foo"]#(#[VAR i]#)' => "(foo)") ;
process_ok('#[SET i = "foo"]#(#[GET i]#)' => "(foo)") ;
process_ok('#[FOR i IN [1..3]]#(#[VAR i]#)#[END]#' => "(1)(2)(3)") ;

process_ok('#[BLOCK foo]#(#[VAR i]#)#[END]##[PROCESS foo i="bar"]#' => "(bar)") ;
process_ok('#[BLOCK foo]#(#[VAR i]#)#[END]##[SET wow = PROCESS foo i="bar"]##[VAR wow]#' => "(bar)") ;

process_ok('#[GET template.foo]##[META foo = "bar"]#' => "bar") ;

process_ok('#[MACRO bar(n) BLOCK]#You said #[VAR n]##[END]##[GET bar("hello")]#' => 'You said hello') ;

###----------------------------------------------------------------###
print "### TT3 CHOMPING #####################################################\n";

process_ok("\n#[GET foo]#" => "\nFOO", {foo => "FOO"}) ;
process_ok("#[GET foo-]#\n" => "FOO", {foo => "FOO"})  ;
process_ok("\n#[-GET foo]#" => "FOO", {foo => "FOO"})  ;

###----------------------------------------------------------------###
print "### TT3 INTERPOLATE ##################################################\n";

process_ok('$foo #[GET foo]# ${ 1 + 2 }' => '$foo FOO ${ 1 + 2 }', {foo => "FOO"}) ;
process_ok('$foo #[GET foo]# ${ 1 + 2 }' => 'FOO FOO 3', {foo => "FOO", tt_config => [INTERPOLATE => 1]}) ;
process_ok('#[CONFIG INTERPOLATE => 1]#$foo #[GET foo]# ${ 1 + 2 }' => 'FOO FOO 3', {foo => "FOO"}) ;

###----------------------------------------------------------------###
print "### DONE #############################################################\n";
