# -*- Mode: Perl; -*-

=head1 NAME

05_velocity.t - Test the ability to parse and play VTL (Velocity Template Language)

=cut

use vars qw($module $compile_perl);
BEGIN {
    $module = 'Template::Alloy';
};

use strict;
use Test::More tests => 202;
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
    my $obj  = shift || $module->new(INCLUDE_PATH => $test_dir, @$conf); # new object each time
    my $out  = '';
    my $line = (caller)[2];
    delete $vars->{'tt_config'};

    Taint::Runtime::taint(\$str) if test_taint;

    $obj->merge(\$str, $vars, \$out);
    my $ok = ref($test) ? $out =~ $test : $out eq $test;
    if ($ok) {
        ok(1, "Line $line   \"$str\" => \"$out\"");
        return $obj;
    } else {
        ok(0, "Line $line   \"$str\"");
        warn "# Was:\n$out\n# Should've been:\n$test\n";
        print $obj->error if $obj->can('error') && $obj->error;
        if ($obj->can('dump_parse_tree')) {
            local $obj->{'SYNTAX'} = 'velocity';
            print $obj->dump_parse_tree(\$str);
        }
        exit;
    }
}


### create some files to include
my $foo_template = "$test_dir/foo.vel";
END { unlink $foo_template };
open(my $fh, ">$foo_template") || die "Couldn't open $foo_template: $!";
print $fh "Good Day!";
close $fh;

### create some files to include
my $bar_template = "$test_dir/bar.vel";
END { unlink $bar_template };
open($fh, ">$bar_template") || die "Couldn't open $bar_template: $!";
print $fh "(\$bar)";
close $fh;

for $compile_perl (0, 1) {
    my $is_compile_perl = "compile perl ($compile_perl)";

###----------------------------------------------------------------###
print "### VARIABLES ####################################### $is_compile_perl\n";

process_ok("Foo" => "Foo");
process_ok('$mud_Slinger_9' => "bar",    {mud_Slinger_9 => 'bar'});
process_ok('$!mud_Slinger_9' => "bar",   {mud_Slinger_9 => 'bar'});
process_ok('${mud_Slinger_9}' => "bar",  {mud_Slinger_9 => 'bar'});
process_ok('$!{mud_Slinger_9}' => "bar", {mud_Slinger_9 => 'bar'});
process_ok('$mud_Slinger_9<<' => "\$mud_Slinger_9<<",    {});
process_ok('$!mud_Slinger_9<<' => "<<",   {});
process_ok('${mud_Slinger_9}<<' => "\${mud_Slinger_9}<<",  {});
process_ok('$!{mud_Slinger_9}<<' => "<<", {});

###----------------------------------------------------------------###
print "### SET ############################################# $is_compile_perl\n";

process_ok('#set($foo = "bar")$foo' => 'bar');

process_ok('#set($monkey = $bill)$monkey' => 'Bill', {bill => 'Bill'});
process_ok('#set($monkey.Friend = \'monica\')$monkey.Friend' => 'monica');
process_ok('#set($monkey.Blame = $whitehouse.Leak)$monkey.Blame' => 'from_velocity_ref_guide', {whitehouse => {Leak => 'from_velocity_ref_guide'}});
process_ok('#set($monkey.Plan = $spindoctor.weave($web))$monkey.Plan' => '(spider)', {spindoctor => {weave => sub {"($_[0])"}}, web => 'spider'});
process_ok('#set($monkey.Number = 123)$monkey.Number' => '123');
process_ok('#set($monkey.Numbers = [1..3])$monkey.Numbers.2' => '3');
process_ok('#set($monkey.Map = {"banana" : "good"})$monkey.Map.banana' => 'good');

process_ok('#set($value = $foo + 1)$value' => '9',     {foo => 8, bar => 4});
process_ok('#set($value = $bar - 1)$value' => '3',     {foo => 8, bar => 4});
process_ok('#set($value = $foo * $bar)$value' => '32', {foo => 8, bar => 4});
process_ok('#set($value = $foo / $bar)$value' => '2',  {foo => 8, bar => 4});
process_ok('#set($value = $foo % $bar)$value' => '0',  {foo => 8, bar => 4});

process_ok('#set($!value = $foo + 1)$value' => '',     {foo => 8, bar => 4}); # error because $!value is not a valid variable name in directives

###----------------------------------------------------------------###
print "### QUOTED STRINGS ################################## $is_compile_perl\n";

process_ok('#set($value = "($foo)")$value' => '(bar)',                {foo => 'bar'});
process_ok('#set($value = "(#get($foo))")$value' => '(bar)',          {foo => 'bar'});
process_ok('#set($value = "($foo)")$value' => '(bar)',                {foo => 'bar', tt_config => [AUTO_EVAL => 0]});
process_ok('#set($value = "(#get($foo))")$value' => '(#get(bar))',    {foo => 'bar', tt_config => [AUTO_EVAL => 0]});
process_ok('#set($value = \'($foo)\')$value' => '($foo)',             {foo => 'bar'});
process_ok('#set($value = \'(#get($foo))\')$value' => '(#get($foo))', {foo => 'bar'});

process_ok('#set($value = "($foo)")$value' => '($foo)',               {});
process_ok('#set($value = "(#get($foo))")$value' => '()',             {});
process_ok('#set($value = "($foo)")$value' => '($foo)',               {tt_config => [AUTO_EVAL => 0]});
process_ok('#set($value = "(#get($foo))")$value' => '(#get($foo))',   {tt_config => [AUTO_EVAL => 0]});

process_ok('#set($value = "($!foo)")$value' => '()',                  {});
process_ok('#set($value = "(#get($!foo))")$value' => '',              {}); # error because $!foo is not a valid variable name in directives
process_ok('#set($value = "($!foo)")$value' => '()',                  {tt_config => [AUTO_EVAL => 0]});
process_ok('#set($value = "(#get($!foo))")$value' => '(#get())',      {tt_config => [AUTO_EVAL => 0]});

###----------------------------------------------------------------###
print "### COMMENTS ######################################## $is_compile_perl\n";

process_ok("Foo##interesting\nBar" => 'FooBar');
process_ok("Foo##interesting\n\nBar" => "Foo\nBar");
process_ok("Foo##interesting" => 'Foo');
process_ok("Foo#*interesting\n" => '');
process_ok("Foo#*interesting\n\n\n*#" => 'Foo');
process_ok("Foo#*interesting\n\n\n*#Bar" => 'FooBar');

###----------------------------------------------------------------###
print "### ESCAPING ######################################## $is_compile_perl\n";

process_ok(('\\'x0).'$email' => 'foo', {email => 'foo'});
process_ok(('\\'x1).'$email' => '$email', {email => 'foo'});
process_ok(('\\'x2).'$email' => '\\foo', {email => 'foo'});
process_ok(('\\'x3).'$email' => '\\$email', {email => 'foo'});

process_ok(('\\'x0).'$email' => '$email');
process_ok(('\\'x1).'$email' => '$email');   # according to VTL spec this is wrong - but that means that the VTL spec parses inconsistently
process_ok(('\\'x2).'$email' => '\\$email');
process_ok(('\\'x3).'$email' => '\\$email'); # according to VTL spec this is wrong

###----------------------------------------------------------------###
print "### IF / ELSEIF / ELSE ############################## $is_compile_perl\n";

process_ok('#if($foo)bar#{end}bar' => "bar");
process_ok('#if("1")bar#end' => "bar");
process_ok('#if($foo)bar#end' => "", {foo => ""});
process_ok('#if($foo)bar#end' => "bar", {foo => "1"});
process_ok('#if($foo)bar#{else}baz#end' => "bar", {foo => "1"});
process_ok('#if($foo)bar#{else}baz#end' => "baz", {foo => ""});
process_ok('#if($foo)bar#elseif($bing)bang#{else}baz#end' => "baz", {bing => ""});
process_ok('#if($foo)bar#elseif($bing)bang#{else}baz#end' => "bang", {bing => "1"});

###----------------------------------------------------------------###
print "### FOREACH  ######################################## $is_compile_perl\n";

process_ok("#foreach( foo )bar#{end}" => 'bar', {foo => 1});
process_ok("#foreach( f IN foo )bar\$f#{end}" => 'bar1bar2', {foo => [1,2]});
process_ok("#foreach( f = foo )bar\$f#{end}" => 'bar1bar2', {foo => [1,2]});
process_ok("#foreach( f = [1,2] )bar\$f#{end}" => 'bar1bar2');
process_ok("#foreach( f = [1..3] )bar\$f#{end}" => 'bar1bar2bar3');
process_ok("#foreach( f = [{a=>'A'},{a=>'B'}] )bar\$f.a#{end}" => 'barAbarB');
process_ok("#foreach( [{a=>'A'},{a=>'B'}] )bar\$a#{end}" => 'barAbarB');
process_ok("#foreach( [{a=>'A'},{a=>'B'}] )bar\$a#{end}\$!a" => 'barAbarB');
process_ok("#foreach( f = [1..3] )\$loop.count/\$loop.size #{end}" => '1/3 2/3 3/3 ');


####----------------------------------------------------------------###
print "### INCLUDE ######################################### $is_compile_perl\n";

process_ok('#include("foo.vel")' => "Good Day!");
process_ok('#parse($foo)' => "Good Day!", {foo => "foo.vel"});
process_ok('#include("bar.vel")' => "(\$bar)");
process_ok('#include("bar.vel")' => "(\$bar)", {bar => 'foo'});

####----------------------------------------------------------------###
print "### PARSE ############################################ $is_compile_perl\n";

process_ok('#parse("foo.vel")' => "Good Day!");
process_ok('#parse($foo)' => "Good Day!", {foo => "foo.vel"});
process_ok('#parse("bar.vel")' => "(\$bar)");
process_ok('#parse("bar.vel")' => "(foo)", {bar => 'foo'});

###----------------------------------------------------------------###
print "### STOP ############################################ $is_compile_perl\n";

process_ok("#stop" => '');
process_ok("One#{stop}Two" => 'One');
process_ok("#block('foo')One#{stop}Two#{end}First#process('foo')Last" => 'FirstOne');
process_ok("#foreach( \$f = [1..3] )\$f#if(loop.first)#end\$f#end" => '112233');
process_ok("#foreach( \$f = [1..3] )\$f#if(loop.first)#stop#end#end" => '1');
process_ok("#foreach( \$f = [1..3] )#if(loop.first)#stop#end\$f#end" => '');

###----------------------------------------------------------------###
print "### EVALUATE ######################################## $is_compile_perl\n";

process_ok('#set($f = \'>#try#evaluate($f)#{catch}caught#end\')#evaluate($f)' => '>>>>>caught', {tt_config => [MAX_EVAL_RECURSE => 5]});
process_ok('#set($f = \'>#try#eval($f)#{catch}foo#end\')#eval($f)#EVALUATE($f)' => '>>foo>>foo', {tt_config => [MAX_EVAL_RECURSE => 2]});

###----------------------------------------------------------------###
print "### MACRO ########################################### $is_compile_perl\n";

process_ok("#macro(foo PROCESS bar )#block(bar)Hi#end\$foo" => 'Hi');
process_ok("#macro(foo BLOCK)Hi#end\$foo" => 'Hi');
process_ok('#macro(foo $n BLOCK)Hi$n#end$foo' => 'Hi$n');
process_ok('#macro(foo $n BLOCK)Hi$n#end$foo(2)' => 'Hi2');
process_ok('#macro(foo(n) BLOCK)Hi$n#end$foo' => 'Hi$n');
process_ok('#macro(foo(n) BLOCK)Hi$n#end$foo(2)' => 'Hi2');
process_ok('#macro(foo $n)Hi$n#end$foo' => 'Hi$n');
process_ok('#macro(foo $n)Hi$n#end$foo(2)' => 'Hi2');
process_ok('#macro(foo $n)Hi$n#end#foo(2)' => 'Hi2');
process_ok('#macro(foo $n $m)Hi($n)($m)#end#foo(2 3)' => 'Hi(2)(3)');

process_ok('#macro( inner $foo )
  inner : $foo
#end

#macro( outer $foo )
   #set($bar = "outerlala")
   outer : $foo
#end

#set($bar = "calltimelala")
#outer( "#inner($bar)" )' => '  outer :  inner : calltimelala', {tt_config => [POST_CHOMP => '=', PRE_CHOMP => '~']});

process_ok('#macro( inner $foo )
  inner : $foo
#end

#macro( outer $foo )
   #set($bar = "outerlala")
   outer : $foo|eval
#end

#set($bar = "calltimelala")
#outer( "#inner(\'$bar\')" )' => '  outer :  inner : outerlala', {tt_config => [POST_CHOMP => '=', PRE_CHOMP => '~']});

###----------------------------------------------------------------###
print "### TT3 CHOMPING #################################### $is_compile_perl\n";

process_ok("\n#get( \$foo )" => "\nFOO", {foo => "FOO"});
process_ok("#get( \$foo -)\n" => "FOO", {foo => "FOO"});
process_ok("\n#get(- \$foo)" => "FOO", {foo => "FOO"});
process_ok("\n#get( -\$foo)" => "\n-7", {foo => "7"});

###----------------------------------------------------------------###
print "### DONE ############################################ $is_compile_perl\n";
} # end of for
