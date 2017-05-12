# -*- Mode: Perl; -*-

=head1 NAME

01_includes.t - Test the file include functionality of Template::Alloy - including some edge cases

=cut

use vars qw($module $is_tt $compile_perl $use_stream);
BEGIN {
    $module = 'Template::Alloy';
    if ($ENV{'USE_TT'} || grep {/tt/i} @ARGV) {
        $module = 'Template';
    }
    $is_tt = $module eq 'Template';
};

use strict;
use Test::More tests => (! $is_tt) ? 351 : 106;
use constant test_taint => 0 && eval { require Taint::Runtime };

use_ok($module);

Taint::Runtime::taint_start() if test_taint;

### find a place to allow for testing
my $test_dir = $0 .'.test_dir';
END { unlink "$test_dir/stream.out"; rmdir $test_dir }
mkdir $test_dir, 0755;
ok(-d $test_dir, "Got a test dir up and running");
mkdir "$test_dir/nested", 0755;
END { rmdir "$test_dir/nested" }
ok(-d $test_dir, "Got a nested test dir up and running");

sub process_ok { # process the value and say if it was ok
    my $str  = shift;
    my $test = shift;
    my $vars = shift || {};
    my $conf = local $vars->{'tt_config'} = $vars->{'tt_config'} || [];
    push @$conf, (COMPILE_PERL => $compile_perl) if $compile_perl;
    push @$conf, (STREAM => 1) if $use_stream;
    my $obj  = shift || $module->new(@$conf, ABSOLUTE => 1, INCLUDE_PATH => $test_dir); # new object each time
    my $out  = '';
    my $line = (caller)[2];
    delete $vars->{'tt_config'};

    Taint::Runtime::taint(\$str) if test_taint;

    my $fh;
    if ($use_stream) {
        open($fh, ">", "$test_dir/stream.out") || return ok(0, "Line $line   \"$str\" - Can't open stream.out: $!");
        select $fh;
    }

    $obj->process(\$str, $vars, \$out);

    if ($use_stream) {
        select STDOUT;
        close $fh;
        open($fh, "<", "$test_dir/stream.out") || return ok(0, "Line $line   \"$str\" - Can't read stream.out: $!");
        $out = '';
        read($fh, $out, -s "$test_dir/stream.out");
    }

    my $ok = ref($test) ? $out =~ $test : $out eq $test;
    if ($ok) {
        ok(1, "Line $line   \"$str\" => \"$out\"");
        return $obj;
    } else {
        ok(0, "Line $line   \"$str\"");
        warn "# Was:\n$out\n# Should've been:\n$test\n";
        print map {"$_\n"} grep { defined } $obj->error if $obj->can('error');
        print $obj->dump_parse_tree(\$str) if $obj->can('dump_parse_tree');
        if ($compile_perl && $obj->can('compile_template')) {
            foreach my $key (sort keys %{ $obj->{'_documents'} }) {
                my $v = $obj->{'_documents'}->{$key};
                print "--------------------- $key ---------------------\n";
                print ${ $obj->compile_template($v) };
            }
        }
        exit;
    }
}

### create some files to include
my @files;
END { unlink @files };
sub write_file {
    my ($file, $content) = @_;
    push @files, $file;
    open(my $fh, ">", $file) || die "Couldn't open $file: $!";
    print $fh $content;
    close $fh;
}

write_file("$test_dir/foo.tt",         "([% template.foo %][% INCLUDE bar.tt %])");
write_file("$test_dir/bar.tt",         "[% blue %]BAR");
write_file("$test_dir/baz.tt",         "[% SET baz = 42 %][% baz %][% bing %]");
write_file("$test_dir/wrap.tt",        "Hi[% baz; template.foo; baz = 'wrap' %][% content %]there");
write_file("$test_dir/meta.tt",        "[% META bar='meta.tt' %]Metafoo([% component.foo %]) Metabar([% component.bar %])");
write_file("$test_dir/catch.tt",       "Error ([% error.type %]) - ([% error.info %])");
write_file("$test_dir/catch2.tt",      "Error2 ([% error.type %]) - ([% error.info %])");
write_file("$test_dir/die.tt",         "[% THROW bing 'blang' %])");
write_file("$test_dir/config.tt",      "[% CONFIG DUMP => {html => 1} %][% DUMP foo %]");
write_file("$test_dir/config2.tt",     "[% PROCESS nested %][% BLOCK nested %][% CONFIG DUMP => {html => 0} %][% DUMP foo %][% END %]");
write_file("$test_dir/template.tt",    "<<[% PROCESS \$template %][% content %]>>");
write_file("$test_dir/nested/foo.tt",  "(Nested foo [% INCLUDE bar.tt %])");
write_file("$test_dir/nested/bar.tt",  "Nested bar");
write_file("$test_dir/nested/foo2.tt", "(Nested foo [% INCLUDE bar2.tt %])");
write_file("$test_dir/nested/bar2.tt", "Nested bar2");
write_file("$test_dir/blocks.tt", "
[%~ BLOCK bar %]bar[% END ~%]
[%~ BLOCK foo %]I am [% text || 'foo' %] - [% template.blam %][% PROCESS bar %][% END ~%]
[%~ MACRO foo_m(text) BLOCK %]I am [% text || 'foo_m' %] - [% template.blam %][% END ~%]
[%~ META blam = 'BLAM' ~%]
");

for my $opt ('normal', 'compile_perl', 'stream') {
    $compile_perl = ($opt eq 'compile_perl');
    $use_stream   = ($opt eq 'stream');
    next if $is_tt && ($compile_perl || $use_stream);
    my $engine_option = "engine_option ($opt)";

###----------------------------------------------------------------###
print "### INSERT ########################################## $engine_option\n";

process_ok("([% INSERT bar.tt %])" => '([% blue %]BAR)');
process_ok("([% SET file = 'bar.tt' %][% INSERT \$file %])"     => '([% blue %]BAR)');
process_ok("([% SET file = 'bar.tt' %][% INSERT \${file} %])"   => '([% blue %]BAR)') if ! $is_tt;
process_ok("([% SET file = 'bar.tt' %][% INSERT \"\$file\" %])" => '([% blue %]BAR)');
process_ok("([% SET file = 'bar' %][% INSERT \"\${file}.tt\" %])" => '([% blue %]BAR)');

###----------------------------------------------------------------###
print "### INCLUDE ######################################### $engine_option\n";

process_ok("([% INCLUDE bar.tt %])" => '(BAR)');
process_ok("[% PROCESS foo.tt %]" => '(BAR)');
process_ok("[% PROCESS meta.tt %]" => 'Metafoo() Metabar(meta.tt)');
process_ok("[% META foo = 'string'; PROCESS meta.tt %]" => 'Metafoo() Metabar(meta.tt)');
process_ok("[% PROCESS meta.tt %][% template.bar %]" => 'Metafoo() Metabar(meta.tt)');
process_ok("[% META foo = 'meta'; PROCESS foo.tt %]" => '(metaBAR)');
process_ok("([% SET file = 'bar.tt' %][% INCLUDE \$file %])" => '(BAR)');
process_ok("([% SET file = 'bar.tt' %][% INCLUDE \${file} %])" => '(BAR)') if ! $is_tt;
process_ok("([% SET file = 'bar.tt' %][% INCLUDE \"\$file\" %])" => '(BAR)');
process_ok("([% SET file = 'bar' %][% INCLUDE \"\${file}.tt\" %])" => '(BAR)');

process_ok("([% INCLUDE baz.tt %])" => '(42)');
process_ok("([% INCLUDE baz.tt %])[% baz %]" => '(42)');
process_ok("[% SET baz = 21 %]([% INCLUDE baz.tt %])[% baz %]" => '(42)21');

process_ok("([% META blam = 5; INCLUDE blocks.tt %])" => '()');
process_ok("([% META blam = 5; INCLUDE blocks.tt %])([% PROCESS foo text => 'bar' %])" => ($use_stream ? '()(' : ''));
process_ok("([% META blam = 5; INCLUDE blocks.tt %])([% foo_m('hey') %])" => '()()');
process_ok("([% META blam = 5; INCLUDE blocks.tt/foo text => 'bar' %])" => ($use_stream ? '(' : ''));
process_ok("([% META blam = 5; INCLUDE blocks.tt/bar %])" => '(bar)', {tt_config => [EXPOSE_BLOCKS => 1]});
process_ok("([% META blam = 5; INCLUDE blocks.tt/foo text => 'bar' %])" => ($use_stream ? '(I am bar - 5' : ''), {tt_config => [EXPOSE_BLOCKS => 1]});

###----------------------------------------------------------------###
print "### PROCESS ######################################### $engine_option\n";

process_ok("([% PROCESS bar.tt %])" => '(BAR)');
process_ok("[% PROCESS foo.tt %]" => '(BAR)');
process_ok("[% PROCESS meta.tt %]" => 'Metafoo() Metabar(meta.tt)');
process_ok("[% META foo = 'string'; PROCESS meta.tt %]" => 'Metafoo() Metabar(meta.tt)');
process_ok("[% PROCESS meta.tt %][% template.bar %]" => 'Metafoo() Metabar(meta.tt)');
process_ok("[% META foo = 'meta'; PROCESS foo.tt %]" => '(metaBAR)');
process_ok("([% SET file = 'bar.tt' %][% PROCESS \$file %])" => '(BAR)');
process_ok("([% SET file = 'bar.tt' %][% PROCESS \${file} %])" => '(BAR)') if ! $is_tt;
process_ok("([% SET file = 'bar.tt' %][% PROCESS \"\$file\" %])" => '(BAR)');
process_ok("([% SET file = 'bar' %][% PROCESS \"\${file}.tt\" %])" => '(BAR)');

process_ok("([% PROCESS baz.tt %])" => '(42)');
process_ok("([% PROCESS baz.tt %])[% baz %]" => '(42)42');
process_ok("[% SET baz = 21 %]([% PROCESS baz.tt %])[% baz %]" => '(42)42');

process_ok("[% PROCESS nested/foo.tt %]" => '(Nested foo BAR)');
process_ok("[% PROCESS nested/foo.tt %]" => '(Nested foo Nested bar)', {tt_config => [ADD_LOCAL_PATH => 1]}) if ! $is_tt;
process_ok("[% PROCESS nested/foo.tt %]" => '(Nested foo BAR)', {tt_config => [ADD_LOCAL_PATH => -1]}) if ! $is_tt;
process_ok("[% CONFIG ADD_LOCAL_PATH => 1 ; PROCESS nested/foo.tt %]" => '(Nested foo Nested bar)') if ! $is_tt;

process_ok("[% PROCESS nested/foo2.tt %]" => ($use_stream ? '(Nested foo ' : ''));
process_ok("[% PROCESS nested/foo2.tt %]" => '(Nested foo Nested bar2)', {tt_config => [ADD_LOCAL_PATH => 1]}) if ! $is_tt;
process_ok("[% PROCESS nested/foo2.tt %]" => '(Nested foo Nested bar2)', {tt_config => [ADD_LOCAL_PATH => -1]}) if ! $is_tt;
process_ok("[% CONFIG ADD_LOCAL_PATH => 1 ; PROCESS nested/foo2.tt %]" => '(Nested foo Nested bar2)') if ! $is_tt;

process_ok("([% META blam = 5; PROCESS blocks.tt %])" => '()');
process_ok("([% META blam = 5; PROCESS blocks.tt %])([% PROCESS foo text => 'bar' %])" => '()(I am bar - 5bar)');
process_ok("([% META blam = 5; PROCESS blocks.tt %])([% foo_m('hey') %])" => '()(I am hey - 5)');
process_ok("([% META blam = 5; PROCESS blocks.tt/foo text => 'bar' %])" => ($use_stream ? '(' : ''));
process_ok("([% META blam = 5; PROCESS blocks.tt/bar %])" => '(bar)', {tt_config => [EXPOSE_BLOCKS => 1]});
process_ok("([% META blam = 5; PROCESS blocks.tt/foo text => 'bar' %])" => ($use_stream ? '(I am bar - 5' : ''), {tt_config => [EXPOSE_BLOCKS => 1]});

###----------------------------------------------------------------###
print "### WRAPPER ######################################### $engine_option\n";

process_ok("([% WRAPPER wrap.tt %])" => '');
process_ok("([% WRAPPER wrap.tt %] one [% END %])" => '(Hi one there)');
process_ok("([% WRAPPER wrap.tt %] ([% baz %]) [% END %])" => '(Hi () there)');
process_ok("([% WRAPPER wrap.tt %] one [% END %])" => '(HiBAZ one there)', {baz => 'BAZ'});
process_ok("([% WRAPPER wrap.tt %] ([% baz; baz='-local' %]) [% END %][% baz %])" => '(Hi-local () there-local)');
process_ok("([% WRAPPER wrap.tt %][% META foo='BLAM' %] [% END %])" => '(HiBLAM there)');

###----------------------------------------------------------------###
print "### CONFIG PRE_PROCESS ############################## $engine_option\n";

process_ok("Foo" => "BARFoo",      {tt_config => [PRE_PROCESS => 'bar.tt']});
process_ok("Foo" => "BARFoo",      {tt_config => [PRE_PROCESS => ['bar.tt']]});
process_ok("Foo" => "(BAR)BARFoo", {tt_config => [PRE_PROCESS => ['foo.tt', 'bar.tt']]});
process_ok("Foo" => "BlueBARFoo",  {tt_config => [PRE_PROCESS => 'bar.tt'], blue => 'Blue'});
process_ok("Foo[% blue='Blue' %]" => "BARFoo", {tt_config => [PRE_PROCESS => 'bar.tt']});
process_ok("Foo[% META foo='meta' %]" => "(metaBAR)Foo", {tt_config => [PRE_PROCESS => 'foo.tt']});
process_ok("([% WRAPPER wrap.tt %] one [% END %])" => 'BAR(Hi one there)', {tt_config => [PRE_PROCESS => 'bar.tt']});

process_ok("Foo" => "<<Foo>>Foo",  {tt_config => [PRE_PROCESS => 'template.tt']});

###----------------------------------------------------------------###
print "### CONFIG POST_PROCESS ############################# $engine_option\n";

process_ok("Foo" => "FooBAR",      {tt_config => [POST_PROCESS => 'bar.tt']});
process_ok("Foo" => "FooBAR",      {tt_config => [POST_PROCESS => ['bar.tt']]});
process_ok("Foo" => "Foo(BAR)BAR", {tt_config => [POST_PROCESS => ['foo.tt', 'bar.tt']]});
process_ok("Foo" => "FooBlueBAR",  {tt_config => [POST_PROCESS => 'bar.tt'], blue => 'Blue'});
process_ok("Foo[% blue='Blue' %]" => "FooBlueBAR", {tt_config => [POST_PROCESS => 'bar.tt']});
process_ok("Foo[% META foo='meta' %]" => "Foo(metaBAR)", {tt_config => [POST_PROCESS => 'foo.tt']});
process_ok("([% WRAPPER wrap.tt %] one [% END %])" => '(Hi one there)BAR', {tt_config => [POST_PROCESS => 'bar.tt']});

process_ok("Foo" => "Foo<<Foo>>",  {tt_config => [POST_PROCESS => 'template.tt']});

###----------------------------------------------------------------###
print "### CONFIG PROCESS ################################## $engine_option\n";

process_ok("Foo" => "BAR",      {tt_config => [PROCESS => 'bar.tt']});
process_ok("Foo" => "BAR",      {tt_config => [PROCESS => ['bar.tt']]});
process_ok("Foo" => "(BAR)BAR", {tt_config => [PROCESS => ['foo.tt', 'bar.tt']]});
process_ok("Foo" => "BlueBAR",  {tt_config => [PROCESS => 'bar.tt'], blue => 'Blue'});
process_ok("Foo[% META foo='meta' %]" => "(metaBAR)", {tt_config => [PROCESS => 'foo.tt']});
process_ok("Foo[% META foo='meta' %]" => "BAR(metaBAR)", {tt_config => [PRE_PROCESS => 'bar.tt', PROCESS => 'foo.tt']});
process_ok("Foo[% META foo='meta' %]" => "(metaBAR)BAR", {tt_config => [POST_PROCESS => 'bar.tt', PROCESS => 'foo.tt']});

process_ok("Foo" => "<<Foo>>",  {tt_config => [PROCESS => 'template.tt']});

###----------------------------------------------------------------###
print "### CONFIG WRAPPER ################################## $engine_option\n";

process_ok(" one " => 'Hi one there', {tt_config => [WRAPPER => 'wrap.tt']});
process_ok(" one " => 'Hi one there', {tt_config => [WRAPPER => ['wrap.tt']]});
process_ok(" one " => 'HiwrapHi one therethere', {tt_config => [WRAPPER => ['wrap.tt', 'wrap.tt']]});
process_ok(" ([% baz %]) " => 'Hi () there', {tt_config => [WRAPPER => 'wrap.tt']});
process_ok(" one " => 'HiBAZ one there', {baz => 'BAZ', tt_config => [WRAPPER => 'wrap.tt']});;
process_ok(" ([% baz; baz='-local' %]) " => 'Hi-local () there', {tt_config => [WRAPPER => 'wrap.tt']});
process_ok("[% META foo='BLAM' %] " => 'HiBLAM there', {tt_config => [WRAPPER => 'wrap.tt']});

process_ok(" one " => 'BARHi one there', {tt_config => [WRAPPER => 'wrap.tt', PRE_PROCESS => 'bar.tt']});
process_ok(" one " => 'HiBARthere', {tt_config => [WRAPPER => 'wrap.tt', PROCESS => 'bar.tt']});
process_ok(" one " => 'Hi one thereBAR', {tt_config => [WRAPPER => 'wrap.tt', POST_PROCESS => 'bar.tt']});

process_ok("Foo" => "<<FooFoo>>",  {tt_config => [WRAPPER => 'template.tt']});

###----------------------------------------------------------------###
print "### CONFIG ERRORS ################################### $engine_option\n";

process_ok("[% THROW foo 'bar' %]" => 'Error (foo) - (bar)',  {tt_config => [ERROR  => 'catch.tt']});
process_ok("[% THROW foo 'bar' %]" => 'Error (foo) - (bar)',  {tt_config => [ERRORS => 'catch.tt']});
process_ok("[% THROW foo 'bar' %]" => 'Error (foo) - (bar)',  {tt_config => [ERROR  => {default => 'catch.tt'}]});
process_ok("[% THROW foo 'bar' %]" => 'Error (foo) - (bar)',  {tt_config => [ERRORS => {default => 'catch.tt'}]});
process_ok("[% THROW foo 'bar' %]" => 'Error2 (foo) - (bar)', {tt_config => [ERRORS => {foo => 'catch2.tt', default => 'catch.tt'}]});
process_ok("[% THROW foo.baz 'bar' %]" => 'Error2 (foo.baz) - (bar)', {tt_config => [ERRORS => {foo => 'catch2.tt', default => 'catch.tt'}]});
process_ok("[% THROW foo.baz 'bar' %]" => 'Error2 (foo.baz) - (bar)', {tt_config => [ERRORS => {'foo.baz' => 'catch2.tt', default => 'catch.tt'}]});
process_ok("[% THROW foo 'bar' %]" => 'Error (foo) - (bar)', {tt_config => [ERRORS => {'foo.baz' => 'catch2.tt', default => 'catch.tt'}]});
process_ok("[% THROW foo.baz 'bar' %]" => 'Error2 (foo.baz) - (bar)', {tt_config => [ERRORS => {foo => 'catch2.tt', default => 'catch.tt'}]});

process_ok("[% THROW foo 'bar' %]" => 'BARError (foo) - (bar)',  {tt_config => [ERROR  => 'catch.tt', PRE_PROCESS => 'bar.tt']});
process_ok("[% THROW foo 'bar' %]" => 'Error (bing) - (blang)',  {tt_config => [ERROR  => 'catch.tt', PROCESS => 'die.tt']});
process_ok("[% THROW foo 'bar' %]" => 'Error (bing) - (blang)',  {tt_config => [ERROR  => 'catch.tt', PROCESS => ['bar.tt', 'die.tt']]}) if ! $use_stream;
process_ok("[% THROW foo 'bar' %]" => 'BARError (bing) - (blang)',  {tt_config => [ERROR  => 'catch.tt', PROCESS => ['bar.tt', 'die.tt']]}) if $use_stream;
process_ok("[% THROW foo 'bar' %]" => 'Error (foo) - (bar)BAR',  {tt_config => [ERROR  => 'catch.tt', POST_PROCESS => 'bar.tt']});
process_ok("[% THROW foo 'bar' %]" => 'HiError (foo) - (bar)there', {tt_config => [ERROR  => 'catch.tt', WRAPPER => 'wrap.tt']});

process_ok("(outer)[% PROCESS 'die.tt' %]" => 'Error (bing) - (blang)',  {tt_config => [ERROR  => 'catch.tt']}) if ! $use_stream;
process_ok("(outer)[% PROCESS 'die.tt' %]" => '(outer)Error (bing) - (blang)',  {tt_config => [ERROR  => 'catch.tt']}) if $use_stream;
process_ok("(outer)[% TRY %][% PROCESS 'die.tt' %][% CATCH %] [% END %]" => '(outer) ',  {tt_config => [ERROR  => 'catch.tt']});

process_ok(" one " => '',  {tt_config => [ERROR  => 'catch.tt', PRE_PROCESS => 'die.tt']});
process_ok(" one " => ($use_stream ? ' one ' : ''),  {tt_config => [ERROR  => 'catch.tt', POST_PROCESS => 'die.tt']});
process_ok(" one " => '',  {tt_config => [ERROR  => 'catch.tt', WRAPPER => 'die.tt']});

###----------------------------------------------------------------###
print "### CONFIG and DUMP ################################# $engine_option\n";

process_ok("[% CONFIG DUMP => {html => 0}; DUMP foo; PROCESS config.tt; DUMP foo %]" => qq{DUMP: File "input text" line 1
    foo = 'FOO';
<b>DUMP: File "config.tt" line 1</b><pre>foo = &apos;FOO&apos;;
</pre>DUMP: File "input text" line 1
    foo = 'FOO';
}, {foo => 'FOO'}) if ! $is_tt;

process_ok("[% PROCESS 'config2.tt' %]" => qq{DUMP: File "config2.tt/nested" line 1
    foo = 'FOO';
}, {foo => 'FOO'}) if ! $is_tt;

###----------------------------------------------------------------###
print "### NOT FOUND CACHE ################################# $engine_option\n";

process_ok("[% BLOCK foo; TRY; PROCESS blurty.tt; CATCH %]([% error.type %])([% error.info %])\n[% END; END; PROCESS foo; PROCESS foo %]" => "(file)(blurty.tt: not found)\n(file)(blurty.tt: not found (cached))\n", {tt_config => [NEGATIVE_STAT_TTL => 2]}) if ! $is_tt;
process_ok("[% BLOCK foo; TRY; PROCESS blurty.tt; CATCH %]([% error.type %])([% error.info %])\n[% END; END; PROCESS foo; PROCESS foo %]" => "(file)(blurty.tt: not found)\n(file)(blurty.tt: not found)\n", {tt_config => [NEGATIVE_STAT_TTL => -1]}) if ! $is_tt;
process_ok("[% BLOCK foo; TRY; PROCESS blurty.tt; CATCH %]([% error.type %])([% error.info %])\n[% END; END; PROCESS foo; PROCESS foo %]" => "(file)(blurty.tt: not found)\n(file)(blurty.tt: not found)\n", {tt_config => [STAT_TTL => -1]}) if ! $is_tt;

###----------------------------------------------------------------###
print "### DONE ############################################ $engine_option\n";
} # end of for
