# -*- Mode: Perl; -*-

=head1 NAME

05_tt_base.t - Test the basic language functionality of Template::Alloy - including many edge cases

=cut

use 5.006;
our ($module, $is_tt, $compile_perl, $use_stream, $five_six, $five_eight, $has_tt_filter);
BEGIN {
    $module = 'Template::Alloy';
    if ($ENV{'USE_TT'} || grep {/tt/i} @ARGV) {
        $module = 'Template';
    }
    $is_tt = $module eq 'Template';
    $five_six   = ($^V < 5.007) ? 1 : 0;
    $five_eight = ($^V < 5.009) ? 1 : 0;
    $has_tt_filter = !eval { require Template::Filters } ? 0 : $is_tt ? 1 : 3;
};

use strict;
use Test::More tests => (! $is_tt ? 3260 : 674) - (!$five_six ? 0 : 3*($is_tt ? 1 : 3)) + $has_tt_filter;
use constant test_taint => 0 && eval { require Taint::Runtime };
use Data::Dumper;

use_ok($module);

Taint::Runtime::taint_start() if test_taint;

my $test_dir = $0 .'.test_dir';
END { unlink "$test_dir/stream.out"; rmdir $test_dir }
mkdir $test_dir, 0755;
ok(-d $test_dir, "Got a test dir up and running");

###----------------------------------------------------------------###

sub process_ok { # process the value and say if it was ok
    my $str  = shift;
    my $test = shift;
    my $vars = shift || {};
    my $conf = local $vars->{'tt_config'} = $vars->{'tt_config'} || [];
    push @$conf, (COMPILE_PERL => $compile_perl) if $compile_perl;
    push @$conf, (STREAM => 1) if $use_stream;
    my $obj  = shift || $module->new(@$conf); # new object each time
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
        my ($k,$v) = each %{ $obj->{'_documents'} };
        #local $Data::Dumper::Terse = 1;
        #local $Data::Dumper::Indent = 0;
        #print "    ".Data::Dumper::Dumper($v->{'_tree'}),"\n";
        exit;
    }
}

###----------------------------------------------------------------###

### set up some dummy packages for various tests
local $INC{'MyTestPlugin/FooTest.pm'} = $0;
local $INC{'FooTest2.pm'} = $0;
{
    package MyTestPlugin::FooTest;
    sub load { $_[0] }
    sub new {
        my $class   = shift;
        my $context = shift;  # note the plugin style object that needs to shift off context
        my $args    = shift || {};
        return bless $args, $class;
    }
    sub bar { my $self = shift; return join('', map {"$_$self->{$_}"} sort keys %$self) }
    sub seven { 7 }
    sub many { return 1, 2, 3 }
    sub echo { my $self = shift; $_[0] }
}
{
    package FooTest2;
    use base qw(MyTestPlugin::FooTest);
    use vars qw($AUTOLOAD);
    sub new {
        my $class   = shift;
        my $args    = shift || {}; # note - no plugin context
        return bless $args, $class;
    }
    sub leave {}      # hacks to allow tt to do the plugins passed via PLUGINS
    sub delocalise {} # hacks to allow tt to do the plugins passed via PLUGINS
}

my $cctx_last;
my $cctx_data = {};;
my $cctx = {
    last_context => sub { $cctx_last || '' },
    call_me => sub { $cctx_last = (wantarray ? 'list' : defined(wantarray) ? 'scalar' : 'void').(shift || '') },
    array   => sub { return my @a = (1, 2, 3) },
    array2  => sub { return my @a = (4) },
    list    => sub { return (5, 6, 7) },
    scalar  => sub { return 8 },
    dataref => sub { return $cctx_data },
    clear   => sub { $cctx_last = undef; $cctx_data = {} },
};
{
    package CallContext;
    our $AUTOLOAD;
    sub AUTOLOAD {
        my $self = shift;
        my $meth = ($AUTOLOAD =~ /::(\w+)$/) ? $1 : die "Invalid method";
        return $cctx->{$meth}->(@_) if ref($cctx->{$meth}) eq 'CODE';
        return $cctx->{$meth} if $cctx->{$meth};
        die "Invalid method $AUTOLOAD\n" if $meth ne 'DESTROY';
    }
}
my $cctxo = bless {}, 'CallContext';

my $obj  = FooTest2->new;
my $vars;
my $stash = {foo => 'Stash', bingo => 'bango'};
$stash = Template::Stash->new($stash) if eval{require Template::Stash};

for my $opt ('normal', 'compile_perl', 'stream') {
    $compile_perl = ($opt eq 'compile_perl');
    $use_stream   = ($opt eq 'stream');
    next if $is_tt && ($compile_perl || $use_stream);
    my $engine_option = "engine_option ($opt)";

###----------------------------------------------------------------###
print "### GET ############################################# $engine_option\n";

process_ok("[% foo %]" => "");
process_ok("[% foo %]" => "7",       {foo => 7});
process_ok("[% foo %]" => "7",       {tt_config => [VARIABLES => {foo => 7}]});
process_ok("[% foo %]" => "7",       {tt_config => [PRE_DEFINE => {foo => 7}]});
process_ok("[% foo %]" => "Stash",   {tt_config => [STASH      => $stash]});
process_ok("[% foo %]" => "V",       {tt_config => [VARIABLES => {foo => 'V'}, PRE_DEFINE => {foo => 'PD'}]});
process_ok("[% bar %]" => "",        {tt_config => [VARIABLES => {foo => 'V'}, PRE_DEFINE => {bar => 'PD'}]});
process_ok("[% foo %]" => "Stash",   {tt_config => [VARIABLES => {foo => 'V'}, STASH      => $stash]});
process_ok("[% bar %]" => "",        {tt_config => [VARIABLES => {bar => 'V'}, STASH      => $stash]});
process_ok("[% foo %]" => "Stash",   {tt_config => [STASH     => $stash,       VARIABLES  => {foo => 'V'}]});
process_ok("[% foo %]" => "Stash",   {tt_config => [STASH     => $stash,       PRE_DEFINE => {foo => 'PD'}]});
process_ok("[% foo %][% foo %][% foo %]" => "777", {foo => 7});
process_ok("[% foo() %]" => "7",     {foo => 7});
process_ok("[% foo.bar %]" => "");
process_ok("[% foo.bar %]" => "",    {foo => {}});
process_ok("[% foo.bar %]" => "7",   {foo => {bar => 7}});
process_ok("[% foo().bar %]" => "7", {foo => {bar => 7}});
process_ok("[% foo.0 %]" => "7",     {foo => [7, 2, 3]});
process_ok("[% foo.10 %]" => "",     {foo => [7, 2, 3]});
process_ok("[% foo %]" => 7,         {foo => sub { 7 }});
process_ok("[% foo(7) %]" => 7,      {foo => sub { $_[0] }});
process_ok("[% foo.length %]" => 1,  {foo => sub { 7 }});
process_ok("[% foo.0 %]" => 7,       {foo => sub { return 7, 2, 3 }});
process_ok("[% foo(bar) %]" => 7,    {foo => sub { $_[0] }, bar => 7});
process_ok("[% foo(bar.baz) %]" => 7,{foo => sub { $_[0] }, bar => {baz => 7}});
process_ok("[% foo.seven %]" => 7,   {foo => $obj});
process_ok("[% foo.seven() %]" => 7, {foo => $obj});
process_ok("[% foo.seven.length %]" => 1, {foo => $obj});
process_ok("[% foo.echo(7) %]" => 7, {foo => $obj});
process_ok("[% foo.many.0 %]" => 1,  {foo => $obj});
process_ok("[% foo.many.10 %]" => '',{foo => $obj});
process_ok("[% foo.nomethod %]" => '',{foo => $obj});
process_ok("[% foo.nomethod.0 %]" => '',{foo => $obj});

process_ok("[% GET foo %]" => "");
process_ok("[% GET foo %]" => "7",     {foo => 7});
process_ok("[% GET foo.bar %]" => "");
process_ok("[% GET foo.bar %]" => "",  {foo => {}});
process_ok("[% GET foo.bar %]" => "7", {foo => {bar => 7}});
process_ok("[% GET foo.0 %]" => "7",   {foo => [7, 2, 3]});
process_ok("[% GET foo %]" => 7,       {foo => sub { 7 }});
process_ok("[% GET foo(7) %]" => 7,    {foo => sub { $_[0] }});

process_ok("[% \$name %]" => "",        {name => 'foo'});
process_ok("[% \$name %]" => "7",       {name => 'foo', foo => 7});
process_ok("[% \$name.bar %]" => "",    {name => 'foo'});
process_ok("[% \$name.bar %]" => "",    {name => 'foo', foo => {}});
process_ok("[% \$name.bar %]" => "7",   {name => 'foo', foo => {bar => 7}});
process_ok("[% \$name().bar %]" => "7", {name => 'foo', foo => {bar => 7}});
process_ok("[% \$name.0 %]" => "7",     {name => 'foo', foo => [7, 2, 3]});
process_ok("[% \$name %]" => 7,         {name => 'foo', foo => sub { 7 }});
process_ok("[% \$name(7) %]" => 7,      {name => 'foo', foo => sub { $_[0] }});

process_ok("[% GET \$name %]" => "",      {name => 'foo'});
process_ok("[% GET \$name %]" => "7",     {name => 'foo', foo => 7});
process_ok("[% GET \$name.bar %]" => "",  {name => 'foo'});
process_ok("[% GET \$name.bar %]" => "",  {name => 'foo', foo => {}});
process_ok("[% GET \$name.bar %]" => "7", {name => 'foo', foo => {bar => 7}});
process_ok("[% GET \$name.0 %]" => "7",   {name => 'foo', foo => [7, 2, 3]});
process_ok("[% GET \$name %]" => 7,       {name => 'foo', foo => sub { 7 }});
process_ok("[% GET \$name(7) %]" => 7,    {name => 'foo', foo => sub { $_[0] }});

process_ok("[% \$name %]" => "",     {name => 'foo foo', foo => 7});
process_ok("[% GET \$name %]" => "", {name => 'foo foo', foo => 7});

process_ok("[% \${name} %]" => "",        {name => 'foo'});
process_ok("[% \${name} %]" => "7",       {name => 'foo', foo => 7});
process_ok("[% \${name}.bar %]" => "",    {name => 'foo'});
process_ok("[% \${name}.bar %]" => "",    {name => 'foo', foo => {}});
process_ok("[% \${name}.bar %]" => "7",   {name => 'foo', foo => {bar => 7}});
process_ok("[% \${name}().bar %]" => "7", {name => 'foo', foo => {bar => 7}});
process_ok("[% \${name}.0 %]" => "7",     {name => 'foo', foo => [7, 2, 3]});
process_ok("[% \${name} %]" => 7,         {name => 'foo', foo => sub { 7 }});
process_ok("[% \${name}(7) %]" => 7,      {name => 'foo', foo => sub { $_[0] }});

process_ok("[% GET \${name} %]" => "",      {name => 'foo'});
process_ok("[% GET \${name} %]" => "7",     {name => 'foo', foo => 7});
process_ok("[% GET \${name}.bar %]" => "",  {name => 'foo'});
process_ok("[% GET \${name}.bar %]" => "",  {name => 'foo', foo => {}});
process_ok("[% GET \${name}.bar %]" => "7", {name => 'foo', foo => {bar => 7}});
process_ok("[% GET \${name}.0 %]" => "7",   {name => 'foo', foo => [7, 2, 3]});
process_ok("[% GET \${name} %]" => 7,       {name => 'foo', foo => sub { 7 }});
process_ok("[% GET \${name}(7) %]" => 7,    {name => 'foo', foo => sub { $_[0] }});

process_ok("[% \${name} %]" => "",     {name => 'foo foo', foo => 7});
process_ok("[% GET \${name} %]" => "", {name => 'foo foo', foo => 7});
process_ok("[% GET \${'foo'} %]" => 'bar', {foo => 'bar'});

process_ok("[% foo.\$name %]" => '', {name => 'bar'});
process_ok("[% foo.\$name %]" => 7, {name => 'bar', foo => {bar => 7}});
process_ok("[% foo.\$name.baz %]" => '', {name => 'bar', bar => {baz => 7}});

process_ok("[% \"hi\" %]" => 'hi');
process_ok("[% \"hi %]" => '');
process_ok("[% 'hi' %]" => 'hi');
process_ok("[% 'hi %]"  => '');
process_ok("[% \"\$foo\" %]"   => '7', {foo => 7});
process_ok("[% \"hi \$foo\" %]"   => 'hi 7', {foo => 7});
process_ok("[% \"hi \${foo}\" %]" => 'hi 7', {foo => 7});
process_ok("[% 'hi \$foo' %]"   => 'hi $foo', {foo => 7});
process_ok("[% 'hi \${foo}' %]" => 'hi ${foo}', {foo => 7});
process_ok("[% 7 %]" => 7);
process_ok("[% -7 %]" => -7);

process_ok("[% \"hi \${foo.seven}\" %]"   => 'hi 7', {foo => $obj});
process_ok("[% \"hi \${foo.echo(7)}\" %]" => 'hi 7', {foo => $obj});

process_ok("[% _foo %]2" => '2', {_foo => 1});
process_ok("[% \$bar %]2" => '2', {_foo => 1, bar => '_foo'});
process_ok("[% __foo %]2" => '2', {__foo => 1});

process_ok("[% qw/Foo Bar Baz/.0 %]" => 'Foo') if ! $is_tt;
process_ok('[% [0..10].-1 %]' => '10') if ! $is_tt;
process_ok('[% [0..10].${ 2.3 } %]' => '2') if ! $is_tt;

process_ok("[% (1 + 2)() %]" => ''); # parse error
process_ok("[% (1 + 2) %]" => '3');
process_ok("[% (a) %]" => '2', {a => 2});
process_ok("[% ('foo') %]" => 'foo');
process_ok("[% (a(2)) %]" => '2', {a => sub { $_[0] }});

# make sure JS stub functions don't interfere with existing uses
process_ok("[% JS 3 %]" => "3") if ! $is_tt;
process_ok("[% JS 3 %]" => "43", {JS => 4}) if ! $is_tt;
process_ok("[% JS; 3; END %]" => "");

###----------------------------------------------------------------###
print "### SET ############################################# $engine_option\n";

process_ok("[% SET foo bar %][% foo %]" => '');
process_ok("[% SET foo = 1 %][% foo %]" => '1');
process_ok("[% SET foo = 1  bar = 2 %][% foo %][% bar %]" => '12');
process_ok("[% SET foo  bar = 1 %][% foo %]" => '');
process_ok("[% SET foo = 1 ; bar = 1 %][% foo %]" => '1');
process_ok("[% SET foo = 1 %][% SET foo %][% foo %]" => '');

process_ok("[% SET foo = [] %][% foo.0 %]" => "");
process_ok("[% SET foo = [1, 2, 3] %][% foo.1 %]" => 2);
process_ok("[% SET foo = {} %][% foo.0 %]" => "");
process_ok("[% SET foo = {1 => 2} %][% foo.1 %]" => "2") if ! $is_tt;
process_ok("[% SET foo = {'1' => 2} %][% foo.1 %]" => "2");

process_ok("[% SET name = 1 %][% SET foo = name %][% foo %]" => "1");
process_ok("[% SET name = 1 %][% SET foo = \$name %][% foo %]" => "");
process_ok("[% SET name = 1 %][% SET foo = \${name} %][% foo %]" => "");
process_ok("[% SET name = 1 %][% SET foo = \"\$name\" %][% foo %]" => "1");
process_ok("[% SET name = 1 foo = name %][% foo %]" => '1');
process_ok("[% SET name = 1 %][% SET foo = {\$name => 2} %][% foo.1 %]" => "2");
process_ok("[% SET name = 1 %][% SET foo = {\"\$name\" => 2} %][% foo.1 %]" => "2") if ! $is_tt;
process_ok("[% SET name = 1 %][% SET foo = {\${name} => 2} %][% foo.1 %]" => "2");

process_ok("[% SET name = 7 %][% SET foo = {'2' => name} %][% foo.2 %]" => "7");
process_ok("[% SET name = 7 %][% SET foo = {'2' => \"\$name\"} %][% foo.2 %]" => "7");

process_ok("[% SET name = 7 %][% SET foo = [1, name, 3] %][% foo.1 %]" => "7");
process_ok("[% SET name = 7 %][% SET foo = [1, \"\$name\", 3] %][% foo.1 %]" => "7");

process_ok("[% SET foo = { bar => { baz => [0, 7, 2] } } %][% foo.bar.baz.1 %]" => "7");

process_ok("[% SET foo.bar = 1 %][% foo.bar %]" => '1');
process_ok("[% SET foo.bar.baz.bing = 1 %][% foo.bar.baz.bing %]" => '1');
process_ok("[% SET foo.bar.2 = 1 %][% foo.bar.2 %] [% foo.bar.size %]" => '1 1');
process_ok("[% SET foo.bar = [] %][% SET foo.bar.2 = 1 %][% foo.bar.2 %] [% foo.bar.size %]" => '1 3');

process_ok("[% SET name = 'two' %][% SET \$name = 3 %][% two %]" => 3);
process_ok("[% SET name = 'two' %][% SET \${name} = 3 %][% two %]" => 3);
process_ok("[% SET name = 2 %][% SET foo.\$name = 3 %][% foo.2 %]" => 3);
process_ok("[% SET name = 2 %][% SET foo.\$name = 3 %][% foo.\$name %]" => 3);
process_ok("[% SET name = 2 %][% SET foo.\${name} = 3 %][% foo.2 %]" => 3);
process_ok("[% SET name = 2 %][% SET foo.\${name} = 3 %][% foo.2 %]" => 3);
process_ok("[% SET name = 'two' %][% SET \$name.foo = 3 %][% two.foo %]" => 3);
process_ok("[% SET name = 'two' %][% SET \${name}.foo = 3 %][% two.foo %]" => 3);
process_ok("[% SET name = 'two' %][% SET foo.\$name.foo = 3 %][% foo.two.foo %]" => 3);
process_ok("[% SET name = 'two' %][% SET foo.\${name}.foo = 3 %][% foo.two.foo %]" => 3);

process_ok("[% SET foo = [1..10] %][% foo.6 %]" => 7);
process_ok("[% SET foo = [10..1] %][% foo.6 %]" => '');
process_ok("[% SET foo = [-10..-1] %][% foo.6 %]" => -4);
process_ok("[% SET foo = [1..10, 21..30] %][% foo.12 %]" => 23)         if ! $is_tt;
process_ok("[% SET foo = [..100] bar = 7 %][% bar %][% foo.0 %]" => '');
process_ok("[% SET foo = [100..] bar = 7 %][% bar %][% foo.0 %]" => '');
process_ok("[% SET foo = ['a'..'z'] %][% foo.6 %]" => 'g');
process_ok("[% SET foo = ['z'..'a'] %][% foo.6 %]" => '');
process_ok("[% SET foo = ['a'..'z'].reverse %][% foo.6 %]" => 't')      if ! $is_tt;

process_ok("[% foo = 1 %][% foo %]" => '1');
process_ok("[% foo = 1 ; bar = 2 %][% foo %][% bar %]" => '12');
process_ok("[% foo.bar = 2 %][% foo.bar %]" => '2');

process_ok('[% a = "a" %]|[% (b = a) %]|[% a %]|[% b %]' => '|a|a|a');
process_ok('[% a = "a" %][% (c = (b = a)) %][% a %][% b %][% c %]' => 'aaaa');

process_ok("[% a = qw{Foo Bar Baz} ; a.2 %]" => 'Baz') if ! $is_tt;

process_ok("[% _foo = 1 %][% _foo %]2" => '2');
process_ok("[% foo._bar %]2" => '2', {foo => {_bar =>1}});

###----------------------------------------------------------------###
print "### multiple statements in same tag ################# $engine_option\n";

process_ok("[% foo; %]" => '1', {foo => 1});
process_ok("[% GET foo; %]" => '1', {foo => 1});
process_ok("[% GET foo; GET foo %]" => '11', {foo => 1});
process_ok("[% GET foo GET foo %]" => '11', {foo => 1}) if ! $is_tt;
process_ok("[% GET foo GET foo %]" => '', {foo => 1, tt_config => [SEMICOLONS => 1]});

process_ok("[% foo = 1 bar = 2 %][% foo %][% bar %]" => '12');
process_ok("[% foo = 1 bar = 2 %][% foo = 3 bar %][% foo %][% bar %]" => '232') if ! $is_tt;
process_ok("[% a = 1 a = a + 2 a %]" => '3') if ! $is_tt;

process_ok("[% foo = 1 bar = 2 %][% foo %][% bar %]" => '', {tt_config => [SEMICOLONS => 1]}) if ! $is_tt;
process_ok("[% foo = 1 bar = 2 %][% foo = 3 bar %][% foo %][% bar %]" => '', {tt_config => [SEMICOLONS => 1]});
process_ok("[% a = 1 a = a + 2 a %]" => '', {tt_config => [SEMICOLONS => 1]});


###----------------------------------------------------------------###
print "### CALL / DEFAULT ################################## $engine_option\n";

process_ok("[% DEFAULT foo = 7 %][% foo %]" => 7);
process_ok("[% SET foo = 5 %][% DEFAULT foo = 7 %][% foo %]" => 5);
process_ok("[% DEFAULT foo.bar.baz.bing = 6 %][% foo.bar.baz.bing %]" => 6);

my $t = 0;
process_ok("[% foo %]"      => 'hi', {foo => sub {$t++; 'hi'}});
process_ok("[% GET  foo %]" => 'hi', {foo => sub {$t++; 'hi'}});
process_ok("[% CALL foo %]" => '',   {foo => sub {$t++; 'hi'}});
ok($t == 3, "CALL method actually called var");
die if $t != 3;

###----------------------------------------------------------------###
print "### scalar vmethods ################################# $engine_option\n";

process_ok("[% n.0 %]" => '7', {n => 7}) if ! $is_tt;
process_ok("[% n.abs %]" => '7', {n => 7}) if ! $is_tt;
process_ok("[% n.abs %]" => '7', {n => -7}) if ! $is_tt;
process_ok("[% n.atan2.substr(0, 6) %]" => '1.5707', {n => 7}) if ! $is_tt;
process_ok("[% (4 * n.atan2(1)).substr(0, 7) %]" => '3.14159', {n => 1}) if ! $is_tt;
process_ok("[% n.chunk(3).join %]" => 'abc def g', {n => 'abcdefg'});
process_ok("[% n.chunk(-3).join %]" => 'a bcd efg', {n => 'abcdefg'});
process_ok("[% n|collapse %]" => "a b", {n => '  a  b  '}); # TT2 filter
process_ok("[% n.cos.substr(0,5) %]" => "1", {n => 0}) if ! $is_tt;
process_ok("[% n.cos.substr(0,5) %]" => "0.707", {n => atan2(1,1)}) if ! $is_tt;
process_ok("[% n.defined %]" => "1", {n => ''});
process_ok("[% n.defined %]" => "", {n => undef});
process_ok("[% n.defined %]" => "1", {n => '1'});
process_ok("[% n.dquote %]" => "(\\n|\\\\|\\\")", {n => "(\n|\\|\")"});
process_ok("[% n.exp.substr(0,5) %]" => "2.718", {n => 1}) if ! $is_tt;
process_ok("[% n.exp.log.substr(0,5) %]" => "8", {n => 8}) if ! $is_tt;
process_ok("[% n.fmt %]" => '7', {n => 7}) if ! $is_tt;
process_ok("[% n.fmt('%02d') %]" => '07', {n => 7}) if ! $is_tt;
process_ok("[% n.fmt('%0*d', 3) %]" => '007', {n => 7}) if ! $is_tt;
process_ok("[% n.fmt('(%s)') %]" => "(a\nb)", {n => "a\nb"}) if ! $is_tt;
process_ok("[% n|format('%02d') %]" => '07', {n => 7}); # TT2 filter
process_ok("[% n|format('%0*d', 3) %]" => '007', {n => 7}) if ! $is_tt;
process_ok("[% n|format('(%s)') %]" => "(a)\n(b)", {n => "a\nb"}); # TT2 filter
process_ok("[% n.hash.items.1 %]" => "b", {n => {a => "b"}});
process_ok("[% n.hex %]" => "255", {n => "FF"}) if ! $is_tt;
process_ok("[% n|html %]" => "&amp;&lt;&gt;&quot;'", {n => '&<>"\''}); # TT2 filter
process_ok("[% n|html_entity %]" => "&amp;", {n => '&'}) if $has_tt_filter; # TT2 native filter
process_ok("[% n|xml %]"  => "&amp;&lt;&gt;&quot;&apos;", {n => '&<>"\''}); # TT2 filter
process_ok("[% n|indent %]" => "    a\n    b", {n => "a\nb"}); # TT2 filter
process_ok("[% n|indent(2) %]" => "  a\n  b", {n => "a\nb"}); # TT2 filter
process_ok("[% n|indent('wow ') %]" => "wow a\nwow b", {n => "a\nb"}); # TT2 filter
process_ok("[% n.int %]" => "123", {n => "123.234"}) if ! $is_tt;
process_ok("[% n.int %]" => "123", {n => "123gggg"}) if ! $is_tt;
process_ok("[% n.int %]" => "0", {n => "ff123.234"}) if ! $is_tt;
process_ok("[% n.item %]" => '7', {n => 7});
process_ok("[% n.lc %]" => 'abc', {n => "ABC"}) if ! $is_tt;
process_ok("[% n|lcfirst %]" => 'fOO', {n => "FOO"}); # TT2 filter
process_ok("[% n.length %]" => 3, {n => "abc"});
process_ok("[% n.list.0 %]" => 'abc', {n => "abc"});
process_ok("[% n.log.substr(0,5) %]" => "4.605", {n => 100}) if ! $is_tt;
process_ok("[% n|lower %]" => 'abc', {n => "ABC"}); # TT2 filter
process_ok("[% n.match('foo').join %]" => '', {n => "bar"});
process_ok("[% n.match('foo').join %]" => '1', {n => "foo"});
process_ok("[% n.match('foo',1).join %]" => 'foo', {n => "foo"});
process_ok("[% n.match('(foo)').join %]" => 'foo', {n => "foo"});
process_ok("[% n.match('(foo)').join %]" => 'foo', {n => "foofoo"});
process_ok("[% n.match('(foo)',1).join %]" => 'foo foo', {n => "foofoo"});
process_ok("[% n.null %]" => '', {n => "abc"});
process_ok("[% n.oct %]" => "255", {n => "377"}) if ! $is_tt;
process_ok("[% n.rand %]" => qr{^\d+\.\d+}, {n => "2"}) if ! $is_tt;
process_ok("[% n.rand %]" => qr{^\d+\.\d+}, {n => "ab"}) if ! $is_tt;
process_ok("[% n.remove('bc') %]" => "a", {n => "abc"});
process_ok("[% n.remove('bc') %]" => "aa", {n => "abcabc"});
process_ok("[% n.repeat %]" => '1',     {n => 1}) if ! $is_tt; # tt2 virtual method defaults to 0
process_ok("[% n.repeat(0) %]" => '',   {n => 1});
process_ok("[% n.repeat(1) %]" => '1',  {n => 1});
process_ok("[% n.repeat(2) %]" => '11', {n => 1});
process_ok("[% n.repeat(2,'|') %]" => '1|1', {n => 1}) if ! $is_tt;
process_ok("[% n.replace('foo', 'bar') %]" => 'barbar', {n => 'foofoo'});
process_ok("[% n.replace('(foo)', 'bar\$1') %]" => 'barfoobarfoo', {n => 'foofoo'}) if ! $is_tt;
process_ok("[% n.replace('foo', 'bar', 0) %]" => 'barfoo', {n => 'foofoo'}) if ! $is_tt;
process_ok("[% n.search('foo') %]" => '', {n => "bar"});
process_ok("[% n.search('foo') %]" => '1', {n => "foo"});
process_ok("[% n.sin.substr(0,5) %]" => "0", {n => 0}) if ! $is_tt;
process_ok("[% n.sin.substr(0,5) %]" => "1", {n => 2*atan2(1,1)}) if ! $is_tt;
process_ok("[% n.size %]" => '1', {n => "foo"});
process_ok("[% n.split.join('|') %]" => "abc", {n => "abc"});
process_ok("[% n.split.join('|') %]" => "a|b|c", {n => "a b c"});
process_ok("[% n.split.join('|') %]" => "a|b|c", {n => "a b c"});
process_ok("[% n.split(u,2).join('|') %]" => "a|b c", {n => "a b c", u => undef}) if ! $is_tt;
process_ok("[% n.split(u,2).join('|') %]" => "a| b c", {n => "a b c", u => undef}) if $is_tt;
process_ok("[% n.split('/').join('|') %]" => "a|b|c", {n => "a/b/c"});
process_ok("[% n.split('/', 2).join('|') %]" => "a|b/c", {n => "a/b/c"});
process_ok("[% n.sprintf(7) %]" => '7', {n => '%d'}) if ! $is_tt;
process_ok("[% n.sprintf(3, 7, 12) %]" => '007 12', {n => '%0*d %d'}) if ! $is_tt;
process_ok("[% n.sqrt %]" => "3", {n => 9}) if ! $is_tt;
process_ok("[% n.squote %]" => "(\n|\\\\|\\\')", {n => "(\n|\\|\')"});
process_ok("[% n.srand; 12 %]" => "12", {n => 9}) if ! $is_tt;
process_ok("[% n.stderr %]" => "", {n => "# testing stderr ... ok\r"});
process_ok("[% n|trim %]" => "a  b", {n => '  a  b  '}); # TT2 filter
process_ok("[% n.uc %]" => 'FOO', {n => "foo"}) if ! $is_tt; # TT2 filter
process_ok("[% n|ucfirst %]" => 'Foo', {n => "foo"}); # TT2 filter
process_ok("[% n|upper %]" => 'FOO', {n => "foo"}); # TT2 filter
process_ok("[% n|uri %]" => 'a%20b', {n => "a b"}); # TT2 filter

process_ok("[% n.fmt('%c') %]" => 'B', {n => 66}) if ! $is_tt;
process_ok("[% n.fmt('%3X') %]" => '  C', {n => 12}) if ! $is_tt;
process_ok("[% n.fmt('%-3X') %]" => 'C  ', {n => 12}) if ! $is_tt;
process_ok("[% n.fmt('%03X') %]" => '00C', {n => 12}) if ! $is_tt;
process_ok("[% n.fmt('%03X') %]" => '00C', {n => 12}) if ! $is_tt;
process_ok("[% n.fmt('%#03X') %]" => '0XC', {n => 12}) if ! $is_tt;
process_ok("[% n.fmt('%#07X') %]" => '0X0000C', {n => 12}) if ! $is_tt;

process_ok("[% n.fmt('%o') %]" => '10', {n => 8}) if ! $is_tt;
process_ok("[% n.fmt('%#o') %]" => '010', {n => 8}) if ! $is_tt;
process_ok("[% n.fmt('%#o') %]" => '0', {n => 0}) if ! $is_tt;

process_ok("[% n.fmt('%02d') %]" => '07', {n => 7}) if ! $is_tt;
process_ok("[% n.fmt('%04.2d') %]" => ($five_eight ? '0007' : '  07'), {n => 7}) if ! $is_tt;
process_ok("[% n.fmt('%+04.2d') %]" => ($five_eight ? '+007' : ' +07'), {n => 7}) if ! $is_tt;
process_ok("[% n.fmt('% 04.2d') %]" => ($five_eight ? ' 007' : '  07'), {n => 7}) if ! $is_tt;
process_ok("[% n.fmt('% +04.2d') %]" => ($five_eight ? '+007' : ' +07'), {n => 7}) if ! $is_tt;
process_ok("[% n.fmt('%02f') %]" => '7.000000', {n => 7}) if ! $is_tt;
process_ok("[% n.fmt('%04.2f') %]" => '7.00', {n => 7}) if ! $is_tt;
process_ok("[% n.fmt('%05.2f') %]" => '07.00', {n => 7}) if ! $is_tt;
process_ok("[% n.fmt('% 5.2f') %]" => ' 7.00', {n => 7}) if ! $is_tt;
process_ok("[% n.fmt('%+04.2f') %]" => '+7.00', {n => 7}) if ! $is_tt;
process_ok("[% n.fmt('% 04.2f') %]" => ' 7.00', {n => 7}) if ! $is_tt;
process_ok("[% n.fmt('% +6.2f') %]" => ' +7.00', {n => 7}) if ! $is_tt;
process_ok("[% n.fmt('%0+6.2f') %]" => '+07.00', {n => 7}) if ! $is_tt;
process_ok("[% n.fmt('%.5g') %]" => '12345', {n => 12345}) if ! $is_tt;
process_ok("[% n.fmt('%.5g') %]" => qr/^1\.2346e\+0*6$/, {n => 1234567}) if ! $is_tt;

###----------------------------------------------------------------###
print "### list vmethods ################################### $engine_option\n";

process_ok("[% a.defined %]" => '1', {a => [2,3]});
process_ok("[% a.defined(1) %]" => '1', {a => [2,3]});
process_ok("[% a.defined(3) %]" => '', {a => [2,3]});
process_ok("[% a.first %]" => '2', {a => [2..10]});
process_ok("[% a.first(3).join %]" => '2 3 4', {a => [2..10]});
process_ok("[% a.fmt %]" => '2 3', {a => [2,3]}) if ! $is_tt;
process_ok("[% a.fmt('%02d') %]" => '02 03', {a => [2,3]}) if ! $is_tt;
process_ok("[% a.fmt('%02d',' ') %]" => '02 03', {a => [2,3]}) if ! $is_tt;
process_ok("[% a.fmt('%02d','|') %]" => '02|03', {a => [2,3]}) if ! $is_tt;
process_ok("[% a.fmt('%0*d','|', 3) %]" => '002|003', {a => [2,3]}) if ! $is_tt;
process_ok("[% a.grep.join %]" => '2 3', {a => [2,3]});
process_ok("[% a.grep(2).join %]" => '2', {a => [2,3]});
process_ok("[% a.grep(->(n){n % 2}).join %]" => '3 5 7', {a => [2..7]}) if ! $is_tt;
process_ok("[% a.hash.items.join %]" => '2 3', {a => [2,3]});
process_ok("[% a.hash(5).items.sort.join %]" => '2 3 5 6', {a => [2,3]});
process_ok("[% a.import(5) %]|[% a.join %]" => '|2 3', {a => [2,3]}) if ! $is_tt;
process_ok("[% a.import(5) %]|[% a.join %]" => qr{^ARRAY.+|2 3$ }x, {a => [2,3]}) if $is_tt;
process_ok("[% a.import([5]) %]|[% a.join %]" => '|2 3 5', {a => [2,3]}) if ! $is_tt;
process_ok("[% a.import([5]) %]|[% a.join %]" => qr{ARRAY.+|2 3 5$ }x, {a => [2,3]}) if $is_tt;
process_ok("[% a.item %]" => '2', {a => [2,3]});
process_ok("[% a.item(1) %]" => '3', {a => [2,3]});
process_ok("[% a.join %]" => '2 3', {a => [2,3]});
process_ok("[% a.join('|') %]" => '2|3', {a => [2,3]});
process_ok("[% a.last %]" => '10', {a => [2..10]});
process_ok("[% a.last(3).join %]" => '8 9 10', {a => [2..10]});
process_ok("[% a.list.join %]" => '2 3', {a => [2, 3]});
process_ok("[% a.map(->(n){ n.repeat(3) }).join %]" => '222 333', {a => [2,3]}) if ! $is_tt;
process_ok("[% a.max %]" => '1', {a => [2, 3]});
process_ok("[% a.merge(5).join %]" => '2 3', {a => [2,3]});
process_ok("[% a.merge([5]).join %]" => '2 3 5', {a => [2,3]});
process_ok("[% a.merge([5]).null %][% a.join %]" => '2 3', {a => [2,3]});
process_ok("[% a.nsort.join %]" => '1 2 3', {a => [2, 3, 1]});
process_ok("[% a.nsort('b').0.b %]" => '7', {a => [{b => 23}, {b => 7}]});
process_ok("[% a.pop %][% a.join %]" => '32', {a => [2, 3]});
process_ok("[% a.push(3) %][% a.join %]" => '2 3 3', {a => [2, 3]});
process_ok("[% a.pick %]" => qr{ ^[23]$ }x, {a => [2, 3]}) if ! $is_tt;
process_ok("[% a.pick(5).join('') %]" => qr{ ^[23]{5}$ }x, {a => [2, 3]}) if ! $is_tt;
process_ok("[% a.reverse.join %]" => '3 2', {a => [2, 3]});
process_ok("[% a.shift %][% a.join %]" => '23', {a => [2, 3]});
process_ok("[% a.size %]" => '2', {a => [2, 3]});
process_ok("[% a.slice.join %]" => '2 3 4 5', {a => [2..5]});
process_ok("[% a.slice(2).join %]" => '4 5', {a => [2..5]});
process_ok("[% a.slice(0,2).join %]" => '2 3 4', {a => [2..5]});
process_ok("[% a.sort.join %]" => '1 2 3', {a => [2, 3, 1]});
process_ok("[% a.sort('b').0.b %]" => 'wee', {a => [{b => "wow"}, {b => "wee"}]});
process_ok("[% c.sort(->(a,b){ a.k cmp b.k }).map(->{this.k}).join %]" => 'a wee wow', {c => [{k => "wow"}, {k => "wee"}, {k => "a"}]}) if ! $is_tt;
process_ok("[% a.splice.join %]|[% a.join %]" => '2 3 4 5|', {a => [2..5]});
process_ok("[% a.splice(2).join %]|[% a.join %]" => '4 5|2 3', {a => [2..5]});
process_ok("[% a.splice(0,2).join %]|[% a.join %]" => '2 3|4 5', {a => [2..5]});
process_ok("[% a.splice(0,2,'hrm').join %]|[% a.join %]" => '2 3|hrm 4 5', {a => [2..5]});
process_ok("[% a.unique.join %]" => '2 3', {a => [2,3,3,3,2]});
process_ok("[% a.unshift(3) %][% a.join %]" => '3 2 3', {a => [2, 3]});

###----------------------------------------------------------------###
print "### hash vmethods ################################### $engine_option\n";

process_ok("[% h.defined %]" => "1", {h => {}});
process_ok("[% h.defined('a') %]" => "1", {h => {a => 1}});
process_ok("[% h.defined('b') %]" => "", {h => {a => 1}});
process_ok("[% h.defined('a') %]" => "", {h => {a => undef}});
process_ok("[% h.delete('a') %]|[% h.keys.0 %]" => "|b", {h => {a => 1, b=> 2}});
process_ok("[% h.delete('a', 'b').join %]|[% h.keys.0 %]" => "|", {h => {a => 1, b=> 2}});
process_ok("[% h.delete('a', 'c').join %]|[% h.keys.0 %]" => "|b", {h => {a => 1, b=> 2}});
process_ok("[% h.each.sort.join %]" => "1 2 a b", {h => {a => 1, b=> 2}});
process_ok("[% h.exists('a') %]" => "1", {h => {a => 1}});
process_ok("[% h.exists('b') %]" => "", {h => {a => 1}});
process_ok("[% h.exists('a') %]" => "1", {h => {a => undef}});
process_ok("[% h.fmt %]" => "b\tB\nc\tC", {h => {b => "B", c => "C"}}) if ! $is_tt;
process_ok("[% h.fmt('%s => %s') %]" => "b => B\nc => C", {h => {b => "B", c => "C"}}) if ! $is_tt;
process_ok("[% h.fmt('%s => %s', '|') %]" => "b => B|c => C", {h => {b => "B", c => "C"}}) if ! $is_tt;
process_ok("[% h.fmt('%*s=>%s', '|', 3) %]" => "  b=>B|  c=>C", {h => {b => "B", c => "C"}}) if ! $is_tt;
process_ok("[% h.fmt('%*s=>%*s', '|', 3, 4) %]" => "  b=>   B|  c=>   C", {h => {b => "B", c => "C"}}) if ! $is_tt;
process_ok("[% h.hash.fmt %]" => "b\tB\nc\tC", {h => {b => "B", c => "C"}}) if ! $is_tt;
process_ok("[% h.import('a') %]|[% h.items.sort.join %]" => "|b B c C", {h => {b => "B", c => "C"}});
process_ok("[% h.import({'b' => 'boo'}) %]|[% h.items.sort.join %]" => "|b boo c C", {h => {b => "B", c => "C"}});
process_ok("[% h.item('a') %]" => 'A', {h => {a => 'A'}});
process_ok("[% h.item('_a') %]" => '', {h => {_a => 'A'}}) if ! $is_tt;
process_ok("[% h.items.sort.join %]" => "1 2 a b", {h => {a => 1, b=> 2}});
process_ok("[% h.keys.sort.join %]" => "a b", {h => {a => 1, b=> 2}});
process_ok("[% h.list('each').sort.join %]" => "1 2 a b", {h => {a => 1, b=> 2}});
process_ok("[% h.list('keys').sort.join %]" => "a b", {h => {a => 1, b=> 2}});
process_ok("[% h.list('pairs').0.items.sort.join %]" => "1 a key value", {h => {a => 1, b=> 2}});
process_ok("[% h.list('values').sort.join %]" => "1 2", {h => {a => 1, b=> 2}});
process_ok("[% h.null %]" => "", {h => {}});
process_ok("[% h.nsort.join %]" => "b a", {h => {a => 7, b => 2}});
process_ok("[% h.pairs.0.items.sort.join %]" => "1 a key value", {h => {a => 1, b=> 2}});
process_ok("[% h.size %]" => "2", {h => {a => 1, b=> 2}});
process_ok("[% h.sort.join %]" => "b a", {h => {a => "BBB", b => "A"}});
process_ok("[% h.values.sort.join %]" => "1 2", {h => {a => 1, b=> 2}});

###----------------------------------------------------------------###
print "### vmethods as functions ########################### $engine_option\n";

process_ok("[% sprintf('%d %d', 7, 8) %] d" => '7 8 d') if ! $is_tt;
process_ok("[% sprintf('%d %d', 7, 8) %] d" => '7 8 d', {tt_config => [VMETHOD_FUNCTIONS => 1]}) if ! $is_tt;
process_ok("[% sprintf('%d %d', 7, 8) %] d" => ' d', {tt_config => [VMETHOD_FUNCTIONS => 0]}) if ! $is_tt;
process_ok("[% int(2.234) %]" => '2') if ! $is_tt;

process_ok("[% int(2.234) ; int = 44; int(2.234) ; SET int; int(2.234) %]" => '2442') if ! $is_tt; # hide and unhide

###----------------------------------------------------------------###
print "### more virtual methods / filters ################## $engine_option\n";

process_ok("[% [0 .. 10].reverse.1 %]" => 9) if ! $is_tt;
process_ok("[% {a => 'A'}.a %]" => 'A') if ! $is_tt;
process_ok("[% 'This is a string'.length %]" => 16) if ! $is_tt;
process_ok("[% 123.length %]" => 3) if ! $is_tt;
process_ok("[% 123.2.length %]" => 5) if ! $is_tt;
process_ok("[% -123.2.length %]" => -5) if ! $is_tt; # the - doesn't bind as tight as the dot methods
process_ok("[% (-123.2).length %]" => 6) if ! $is_tt;
process_ok("[% a = 23; a.0 %]" => 23) if ! $is_tt; # '0' is a scalar_op
process_ok('[% 1.rand %]' => qr/^0\.\d+(?:e-?\d+)?$/) if ! $is_tt;

process_ok("[% n.size %]", => 'SIZE', {n => {size => 'SIZE', a => 'A'}});
process_ok("[% n|size %]", => '2',    {n => {size => 'SIZE', a => 'A'}}) if ! $is_tt; # tt2 | is alias for FILTER

process_ok('[% "1" | indent(2) %]' => '  1');

process_ok("[% n FILTER size %]", => '1', {n => {size => 'SIZE', a => 'A'}}) if ! $is_tt; # tt2 doesn't have size

process_ok("[% n FILTER repeat %]" => '1',     {n => 1});
process_ok("[% n FILTER repeat(0) %]" => '',   {n => 1});
process_ok("[% n FILTER repeat(1) %]" => '1',  {n => 1});
process_ok("[% n FILTER repeat(2) %]" => '11', {n => 1});
process_ok("[% n FILTER repeat(2,'|') %]" => '1|1', {n => 1}) if ! $is_tt;

process_ok("[% n FILTER echo = repeat(2) %][% n FILTER echo %]" => '1111', {n => 1});
process_ok("[% n FILTER echo = repeat(2) %][% n | echo %]" => '1111', {n => 1});
process_ok("[% n FILTER echo = repeat(2) %][% n|echo.length %]" => '112', {n => 1}) if ! $is_tt;
process_ok("[% n FILTER echo = repeat(2) %][% n FILTER \$foo %]" => '1111', {n => 1, foo => 'echo'});
process_ok("[% n FILTER echo = repeat(2) %][% n | \$foo %]" => '1111', {n => 1, foo => 'echo'});
process_ok("[% n FILTER echo = repeat(2) %][% n|\$foo.length %]" => '112', {n => 1, foo => 'echo'}) if ! $is_tt;

process_ok('[% "hi" FILTER $foo %]' => 'hihi', {foo => sub {sub {$_[0]x2}}}); # filter via a passed var
process_ok('[% FILTER $foo %]hi[% END %]' => 'hihi', {foo => sub {sub {$_[0]x2}}}); # filter via a passed var
process_ok('[% "hi" FILTER foo %]' => 'hihi', {tt_config => [FILTERS => {foo => sub {$_[0]x2}}]});
process_ok('[% "hi" FILTER foo %]' => 'hihi', {tt_config => [FILTERS => {foo => [sub {$_[0]x2},0]}]});
process_ok('[% "hi" FILTER foo(2) %]' => 'hihi', {tt_config => [FILTERS => {foo => [sub {my$a=$_[1];sub{$_[0]x$a}},1]}]});

process_ok('[% ["0".."9"].pick %]' => qr/^[0-9]/) if ! $is_tt;

process_ok("[% ' ' | uri %]" => '%20');

process_ok('[% "one".fmt %]' => "one") if ! $is_tt;
process_ok('[% 2.fmt("%02d") %]' => "02") if ! $is_tt;

process_ok('[% [1..3].fmt %]' => "1 2 3") if ! $is_tt;
process_ok('[% [1..3].fmt("%02d") %]' => '01 02 03') if ! $is_tt;
process_ok('[% [1..3].fmt("%s", ", ") %]' => '1, 2, 3') if ! $is_tt;

process_ok('[% {a => "B", c => "D"}.fmt %]' => "a\tB\nc\tD") if ! $is_tt;
process_ok('[% {a => "B", c => "D"}.fmt("%s:%s") %]' => "a:B\nc:D") if ! $is_tt;
process_ok('[% {a => "B", c => "D"}.fmt("%s:%s", "; ") %]' => "a:B; c:D") if ! $is_tt;

process_ok('[% 1|format("%s") %]' => '1') if ! $is_tt;
process_ok('[% 1|format("%*s", 6) %]' => '     1') if ! $is_tt;
process_ok('[% 1|format("%-*s", 6) %]' => '1     ') if ! $is_tt;

process_ok('[% 1.fmt("%-*s", 6) %]' => '1     ') if ! $is_tt;
process_ok('[% [1,2].fmt("%-*s", "|", 6) %]' => '1     |2     ') if ! $is_tt;
process_ok('[% {1=>2,3=>4}.fmt("%*s:%*s", "|", 3, 3) %]' => '  1:  2|  3:  4') if ! $is_tt;

process_ok('[% foo %]', => '&amp;', {foo => '&', tt_config => [AUTO_FILTER => 'html']}) if ! $is_tt;
process_ok('[% "&" %]', => '&amp;', {foo => '&', tt_config => [AUTO_FILTER => 'html']}) if ! $is_tt;
process_ok('[% foo | none %]', => '&', {foo => '&', tt_config => [AUTO_FILTER => 'html']}) if ! $is_tt;
process_ok('[% foo.bar %]', => '&amp;', {foo => {bar => '&'}, tt_config => [AUTO_FILTER => 'html']}) if ! $is_tt;
process_ok('[% foo.bar | none %]', => '&', {foo => {bar => '&'}, tt_config => [AUTO_FILTER => 'html']}) if ! $is_tt;
process_ok('[% GET foo %]', => '&amp;', {foo => '&', tt_config => [AUTO_FILTER => 'html']}) if ! $is_tt;
process_ok('[% GET "&" %]', => '&amp;', {foo => '&', tt_config => [AUTO_FILTER => 'html']}) if ! $is_tt;
process_ok('[% GET foo | none %]', => '&', {foo => '&', tt_config => [AUTO_FILTER => 'html']}) if ! $is_tt;
process_ok('[% Text.length(foo) %]', => '1', {foo => '&', tt_config => [AUTO_FILTER => 'html']}) if ! $is_tt;

###----------------------------------------------------------------###
print "### virtual objects ################################# $engine_option\n";

process_ok('[% a = "foobar" %][% Text.length(a) %]' => 6) if ! $is_tt;
process_ok('[% a = [1 .. 10] %][% List.size(a) %]' => 10) if ! $is_tt;
process_ok('[% a = {a=>"A", b=>"B"} ; Hash.size(a) %]' => 2) if ! $is_tt;

process_ok('[% a = Text.new("This is a string") %][% a.length %]' => 16) if ! $is_tt;
process_ok('[% a = List.new("one", "two", "three") %][% a.size %]' => 3) if ! $is_tt;
process_ok('[% a = Hash.new("one", "ONE") %][% a.one %]' => 'ONE') if ! $is_tt;
process_ok('[% a = Hash.new(one = "ONE") %][% a.one %]' => 'ONE') if ! $is_tt;
process_ok('[% a = Hash.new(one => "ONE") %][% a.one %]' => 'ONE') if ! $is_tt;

process_ok('[% {a => 1, b => 2} | Hash.keys | List.sort | List.join(", ") %]' => 'a, b') if ! $is_tt;

###----------------------------------------------------------------###
print "### chomping ######################################## $engine_option\n";

process_ok(" [% foo %]" => ' ');
process_ok(" [%- foo %]" => '');
process_ok("\n[%- foo %]" => '');
process_ok("\n [%- foo %]" => '');
process_ok("\n\n[%- foo %]" => "\n");
process_ok(" \n\n[%- foo %]" => " \n");
process_ok(" \n[%- foo %]" => " ") if ! $is_tt;
process_ok(" \n \n[%- foo %]" => " \n ") if ! $is_tt;

process_ok("[% 7 %] " => '7 ');
process_ok("[% 7 -%] " => '7 ');
process_ok("[% 7 -%]\n" => '7');
process_ok("[% 7 -%] \n" => '7');
process_ok("[% 7 -%]\n " => '7 ');
process_ok("[% 7 -%]\n\n\n" => "7\n\n");
process_ok("[% 7 -%] \n " => '7 ');

###----------------------------------------------------------------###
print "### string operators ################################ $engine_option\n";

process_ok('[% a = "foo"; a _ "bar" %]' => 'foobar');
process_ok('[% a = "foo"; a ~ "bar" %]' => 'foobar') if ! $is_tt;
process_ok('[% a = "foo"; a ~= "bar"; a %]' => 'foobar') if ! $is_tt;
process_ok('[% "b" gt "c" %]<<<' => '<<<') if ! $is_tt;
process_ok('[% "b" gt "a" %]<<<' => '1<<<') if ! $is_tt;
process_ok('[% "b" ge "c" %]<<<' => '<<<') if ! $is_tt;
process_ok('[% "b" ge "b" %]<<<' => '1<<<') if ! $is_tt;
process_ok('[% "b" lt "c" %]<<<' => '1<<<') if ! $is_tt;
process_ok('[% "b" lt "a" %]<<<' => '<<<') if ! $is_tt;
process_ok('[% "b" le "a" %]<<<' => '<<<') if ! $is_tt;
process_ok('[% "b" le "b" %]<<<' => '1<<<') if ! $is_tt;
process_ok('[% "a" cmp "b" %]<<<' => '-1<<<') if ! $is_tt;
process_ok('[% "b" cmp "b" %]<<<' => '0<<<') if ! $is_tt;
process_ok('[% "c" cmp "b" %]<<<' => '1<<<') if ! $is_tt;

###----------------------------------------------------------------###
print "### math operators ################################## $engine_option\n";

process_ok("[% 1 + 2 %]" => 3);
process_ok("[% 1 + 2 + 3 %]" => 6);
process_ok("[% (1 + 2) %]" => 3);
process_ok("[% 2 - 1 %]" => 1);
process_ok("[% -1 + 2 %]" => 1);
process_ok("[% -1+2 %]" => 1);
process_ok("[% 2 - 1 %]" => 1);
process_ok("[% 2-1 %]" => 1) if ! $is_tt;
process_ok("[% 2 - -1 %]" => 3);
process_ok("[% 4 * 2 %]" => 8);
process_ok("[% 4 / 2 %]" => 2);
process_ok("[% 10 / 3 %]" => qr/^3.333/);
process_ok("[% 10 div 3 %]" => '3');
process_ok("[% 2 ** 3 %]" => 8) if ! $is_tt;
process_ok("[% 1 + 2 * 3 %]" => 7);
process_ok("[% 3 * 2 + 1 %]" => 7);
process_ok("[% (1 + 2) * 3 %]" => 9);
process_ok("[% 3 * (1 + 2) %]" => 9);
process_ok("[% 1 + 2 ** 3 %]" => 9) if ! $is_tt;
process_ok("[% 2 * 2 ** 3 %]" => 16) if ! $is_tt;
process_ok("[% SET foo = 1 %][% foo + 2 %]" => 3);
process_ok("[% SET foo = 1 %][% (foo + 2) %]" => 3);

process_ok("[% a = 1; (a += 2) %]"  => 3)  if ! $is_tt;
process_ok("[% a = 1; (a -= 2) %]"  => -1) if ! $is_tt;
process_ok("[% a = 4; (a /= 2) %]"  => 2)  if ! $is_tt;
process_ok("[% a = 1; (a *= 2) %]"  => 2)  if ! $is_tt;
process_ok("[% a = 3; (a **= 2) %]" => 9)  if ! $is_tt;
process_ok("[% a = 1; (a %= 2) %]"  => 1)  if ! $is_tt;
process_ok("[% a = 1; (a += 2 + 3) %]"  => 6)  if ! $is_tt;
process_ok("[% a = 1; b = 2; (a += b += 3) %]|[% a %]|[% b %]" => "6|6|5")  if ! $is_tt;
process_ok("[% a = 1; b = 2; (a += (b += 3)) %]|[% a %]|[% b %]" => "6|6|5")  if ! $is_tt;

process_ok('[% a += 1 %]-[% a %]-[% a += 1 %]-[% a %]' => '-1--2') if ! $is_tt;
process_ok('[% (a += 1) %]-[% (a += 1) %]' => '1-2') if ! $is_tt;

process_ok('[% a = 2; a -= 3; a %]' => '-1') if ! $is_tt;
process_ok('[% a = 2; a *= 3; a %]' => '6') if ! $is_tt;
process_ok('[% a = 2; a /= .5; a %]' => '4') if ! $is_tt;
process_ok('[% a = 8; a %= 3; a %]' => '2') if ! $is_tt;
process_ok('[% a = 2; a **= 3; a %]' => '8') if ! $is_tt;

process_ok('[% a = 1 %][% ++a %][% a %]' => '22') if ! $is_tt;
process_ok('[% a = 1 %][% a++ %][% a %]' => '12') if ! $is_tt;
process_ok('[% a = 1 %][% --a %][% a %]' => '00') if ! $is_tt;
process_ok('[% a = 1 %][% a-- %][% a %]' => '10') if ! $is_tt;
process_ok('[% a++ FOR [1..3] %]' => '012') if ! $is_tt;
process_ok('[% --a FOR [1..3] %]' => '-1-2-3') if ! $is_tt;

process_ok('[% 2 >  3 %]<<<' => '<<<');
process_ok('[% 2 >  1 %]<<<' => '1<<<');
process_ok('[% 2 >= 3 %]<<<' => '<<<');
process_ok('[% 2 >= 2 %]<<<' => '1<<<');
process_ok('[% 2 < 3 %]<<<' => '1<<<');
process_ok('[% 2 < 1 %]<<<' => '<<<');
process_ok('[% 2 <= 1 %]<<<' => '<<<');
process_ok('[% 2 <= 2 %]<<<' => '1<<<');
process_ok('[% 1 <=> 2 %]<<<' => '-1<<<') if ! $is_tt;
process_ok('[% 2 <=> 2 %]<<<' => '0<<<') if ! $is_tt;
process_ok('[% 3 <=> 2 %]<<<' => '1<<<') if ! $is_tt;

###----------------------------------------------------------------###
print "### boolean operators ############################### $engine_option\n";

process_ok("[% 5 && 6 %]" => 6);
process_ok("[% 5 || 6 %]" => 5);
process_ok("[% 0 || 6 %]" => 6);
process_ok("[% 0 && 6 %]" => 0);
process_ok("[% 0 && 0 %]" => 0);
process_ok("[% 5 && 6 && 7%]" => 7);
process_ok("[% 0 || 1 || 2 %]" => 1);

process_ok("[% 5 + (0 || 5) %]" => 10);


process_ok("[% 1 ? 2 : 3 %]" => '2');
process_ok("[% 0 ? 2 : 3 %]" => '3');
process_ok("[% 0 ? (1 ? 2 : 3) : 4 %]" => '4');
process_ok("[% 0 ? 1 ? 2 : 3 : 4 %]" => '4');

process_ok("[% t = 1 || 0 ? 3 : 4 %][% t %]" => 3);
process_ok("[% t = 0 or 1 ? 3 : 4 %][% t %]" => 3);
process_ok("[% t = 1 or 0 ? 3 : 4 %][% t %]" => 1) if ! $is_tt;

process_ok("[% 0 ? 2 : 3 %]" => '3');
process_ok("[% 1 ? 2 : 3 %]" => '2');
process_ok("[% 0 ? 1 ? 2 : 3 : 4 %]" => '4');
process_ok("[% t = 0 ? 1 ? [1..4] : [2..4] : [3..4] %][% t.0 %]" => '3');
process_ok("[% t = 1 || 0 ? 0 : 1 || 2 ? 2 : 3 %][% t %]" => '0');
process_ok("[% t = 0 or 0 ? 0 : 1 or 2 ? 2 : 3 %][% t %]" => '1') if ! $is_tt;
process_ok("[% t = 0 or 0 ? 0 : 0 or 2 ? 2 : 3 %][% t %]" => '2');

process_ok("[% 0 ? 1 ? 1 + 2 * 3 : 1 + 2 * 4 : 1 + 2 * 5 %]" => '11');

process_ok("[% foo //= 2 ; foo %]" => 2) if ! $is_tt;
process_ok("[% foo = 3; foo //= 2; foo %]" => 3) if ! $is_tt;
process_ok("[% foo = 3; SET foo; foo //= 2; foo %]" => 2) if ! $is_tt;

process_ok("[% 5 // 6 %]" => 5) if ! $is_tt;
process_ok("[% foo // 6 %]" => 6) if ! $is_tt;
process_ok("[% foo // 6 %]" => 6, {foo => undef}) if ! $is_tt;
process_ok("[% foo // 6 %]" => '', {foo => ''}) if ! $is_tt;
process_ok("[% foo // 6 %]" => 'bar', {foo => 'bar'}) if ! $is_tt;

process_ok("[% foo err 6 %]" => 6, {foo => undef}) if ! $is_tt;
process_ok("[% foo ERR 6 %]" => 6, {foo => undef}) if ! $is_tt;

###----------------------------------------------------------------###
print "### regex ########################################### $engine_option\n";

if (! $is_tt) {
process_ok("[% 'foo'.match(/foo/)        ? 1 : 0 %]" => '1');
process_ok("[% 'foo'.match(/foo)         ? 1 : 0 %]" => '');
process_ok("[% 'foo'.match(/fo o/x)      ? 1 : 0 %]" => '1');
process_ok("[% 'foo'.match(/Foo/i)       ? 1 : 0 %]" => '1');
process_ok("[% 'f\no'.match(/f.o/s)      ? 1 : 0 %]" => '1');
process_ok("[% '\nfoo'.match(/^foo/m)    ? 1 : 0 %]" => '1');
process_ok("[% 'foo'.match(/foo/e)       ? 1 : 0 %]" => '');
process_ok("[% 'foo'.match(/foo/g)       ? 1 : 0 %]" => '');
process_ok("[% 'foo'.match(/foo)         ? 1 : 0 %]" => '');
process_ok("[% 'foo'.match(/foo**/)      ? 1 : 0 %]" => '');
process_ok("[% 'fo/o'.match(/fo\\/o/)    ? 1 : 0 %]" => '1');
process_ok("[% 'foobar'.match(/(f\\w\\w)/).0 %]" => 'foo');
}

###----------------------------------------------------------------###
print "### BLOCK / PROCESS / INCLUDE / WRAPPER ############# $engine_option\n";

process_ok("[% PROCESS foo %]one" => '');
process_ok("[% BLOCK foo %]one" => '');
process_ok("[% BLOCK foo %][% END %]one" => 'one');
process_ok("[% BLOCK %][% END %]one" => 'one');
process_ok("[% BLOCK foo %]hi there[% END %]one" => 'one');
process_ok("[% BLOCK foo %][% BLOCK foo %][% END %][% END %]" => '');
process_ok("[% BLOCK foo %]hi there[% END %][% PROCESS foo %]" => 'hi there');
process_ok("[% PROCESS foo %][% BLOCK foo %]hi there[% END %]" => 'hi there');
process_ok("[% BLOCK foo %]hi there[% END %][% PROCESS foo foo %]" => 'hi therehi there') if ! $is_tt;
process_ok("[% BLOCK foo %]hi there[% END %][% PROCESS foo, foo %]" => 'hi therehi there') if ! $is_tt;
process_ok("[% BLOCK foo %]hi there[% END %][% PROCESS foo + foo %]" => 'hi therehi there');
process_ok("[% BLOCK foo %]hi [% one %] there[% END %][% PROCESS foo %]" => 'hi ONE there', {one => 'ONE'});
process_ok("[% BLOCK foo %]hi [% IF 1 %]Yes[% END %] there[% END %]<<[% PROCESS foo %]>>" => '<<hi Yes there>>');
process_ok("[% BLOCK foo %]hi [% one %] there[% END %][% PROCESS foo one = 'two' %]" => 'hi two there');
process_ok("[% BLOCK foo %]hi [% one.two %] there[% END %][% PROCESS foo one.two = 'two' %]" => 'hi two there');
process_ok("[% BLOCK foo %]hi [% one.two %] there[% END %][% PROCESS foo + foo one.two = 'two' %]" => 'hi two there'x2);
process_ok("[% BLOCK foo %][% BLOCK bar %]hi [% one %] there[% END %][% END %][% PROCESS foo/bar one => 'two' %]" => 'hi two there');

process_ok("[% BLOCK b %]Ta-Da[% END %][% self = {a => 'b'} %][% PROCESS \$self.a self = 'blah' %]" => 'Ta-Da');
process_ok("[% BLOCK b %]Ta-Da[% END %][% self = {a => 'b'} %][% INCLUDE \$self.a self = 'blah' %]" => 'Ta-Da') if ! $five_six;
process_ok("[% BLOCK b %]Ta-Da[% END %][% self = 'b' %][% PROCESS \$self self = 'blah'; self %]" => 'Ta-Dablah');
process_ok("[% BLOCK b %]Ta-Da[% END %][% self = 'b' %][% INCLUDE \$self self = 'blah'; self %]" => 'Ta-Dab') if ! $five_six;

process_ok("[% BLOCK foo %]hi [% one %] there[% END %][% PROCESS foo one = 'two' %][% one %]" => 'hi two theretwo');
process_ok("[% BLOCK foo %]hi [% one %] there[% END %][% INCLUDE foo one = 'two' %][% one %]" => 'hi two there') if ! $five_six;

process_ok("[% BLOCK foo %]FOO[% IF ! a ; a = 1; PROCESS bar; END %][% END %][% BLOCK bar %]BAR[% PROCESS foo %][% END %][% PROCESS foo %]" => "") if ! $is_tt && ! $use_stream;
process_ok("[% BLOCK foo %]FOO[% IF ! a ; a = 1; PROCESS bar; END %][% END %][% BLOCK bar %]BAR[% PROCESS foo %][% END %][% PROCESS foo %]d" => "FOOBAR") if $use_stream;
process_ok("[% BLOCK foo %]FOO[% IF ! a ; a = 1; PROCESS bar; END %][% END %][% BLOCK bar %]BAR[% PROCESS foo %][% END %][% PROCESS foo %]" => "FOOBARFOO", {tt_config => [RECURSION => 1]});

process_ok("[% BLOCK foo %]([% content %])[% END %][% WRAPPER foo %]hi there[% END %]" => "(hi there)");
process_ok("[% BLOCK foo %]([% one = 1; content %])[% END %][% WRAPPER foo %]hi there[% END %][% one %]" => "(hi there)won", {one => 'won'});

process_ok('[% a = 23; PROCESS $foo %]' => 'bar 23 baz', {foo => \ "bar [% a %] baz"});

###----------------------------------------------------------------###
print "### IF / UNLESS / ELSIF / ELSE ###################### $engine_option\n";

process_ok("[% IF 1 %]Yes[% END %]" => 'Yes');
process_ok("[% IF 0 %]Yes[% END %]" => '');
process_ok("[% IF 0 %]Yes[% ELSE %]No[% END %]" => 'No');
process_ok("[% IF 0 %]Yes[% ELSIF 1 %]No[% END %]" => 'No');
process_ok("[% IF 0 %]Yes[% ELSIF 0 %]No[% END %]" => '');
process_ok("[% IF 0 %]Yes[% ELSIF 0 %]No[% ELSE %]hmm[% END %]" => 'hmm');

process_ok("[% UNLESS 1 %]Yes[% END %]" => '');
process_ok("[% UNLESS 0 %]Yes[% END %]" => 'Yes');
process_ok("[% UNLESS 0 %]Yes[% ELSE %]No[% END %]" => 'Yes');
process_ok("[% UNLESS 1 %]Yes[% ELSIF 1 %]No[% END %]" => 'No');
process_ok("[% UNLESS 1 %]Yes[% ELSIF 0 %]No[% END %]" => '');
process_ok("[% UNLESS 1 %]Yes[% ELSIF 0 %]No[% ELSE %]hmm[% END %]" => 'hmm');

###----------------------------------------------------------------###
print "### comments ######################################## $engine_option\n";

process_ok("[%# one %]f" => 'f', {one => 'ONE'});
process_ok("[%#\n one %]f" => 'f', {one => 'ONE'});
process_ok("[%-#\n one %]f" => 'f', {one => 'ONE'})     if ! $is_tt;
process_ok("[% #\n one %]f" => 'ONEf', {one => 'ONE'});
process_ok("[% # one %]\n one %]f" => "\n one %]f", {one => "ONE"}) if $is_tt || !$five_eight;
process_ok("[% # one %]\n one %]f" => "ONEf", {one => "ONE"}) if !$is_tt && $five_eight; # I personally think this is the more correct behavior
process_ok("[%# BLOCK one %]" => '');
process_ok("[%# BLOCK one %]two" => 'two');
process_ok("[%# BLOCK one %]two[% END %]" => '');
process_ok("[%# BLOCK one %]two[% END %]three" => '');
process_ok("[% %]" => '');
process_ok("[%
  # Some comment
CALL 1 -%]
foo" => "foo");

###----------------------------------------------------------------###
print "### FOREACH / NEXT / LAST ########################### $engine_option\n";

process_ok("[% FOREACH foo %]" => '');
process_ok("[% FOREACH foo %][% END %]" => '');
process_ok("[% FOREACH foo %]bar[% END %]" => '');
process_ok("[% FOREACH foo %]bar[% END %]" => 'bar', {foo => 1});
process_ok("[% FOREACH f IN foo %]bar[% f %][% END %]" => 'bar1bar2', {foo => [1,2]});
process_ok("[% FOREACH f = foo %]bar[% f %][% END %]" => 'bar1bar2', {foo => [1,2]});
process_ok("[% FOREACH f = [1,2] %]bar[% f %][% END %]" => 'bar1bar2');
process_ok("[% FOREACH f = [1..3] %]bar[% f %][% END %]" => 'bar1bar2bar3');
process_ok("[% FOREACH f = [{a=>'A'},{a=>'B'}] %]bar[% f.a %][% END %]" => 'barAbarB');
process_ok("[% FOREACH [{a=>'A'},{a=>'B'}] %]bar[% a %][% END %]" => 'barAbarB');
process_ok("[% FOREACH [{a=>'A'},{a=>'B'}] %]bar[% a %][% END %][% a %]" => 'barAbarB');
process_ok("[% FOREACH f = [1..3] %][% loop.count %]/[% loop.size %] [% END %]" => '1/3 2/3 3/3 ');
process_ok("[% FOREACH f = [1..3] %][% IF loop.first %][% f %][% END %][% END %]" => '1');
process_ok("[% FOREACH f = [1..3] %][% IF loop.last %][% f %][% END %][% END %]" => '3');
process_ok("[% FOREACH f = [1..3] %][% IF loop.first %][% NEXT %][% END %][% f %][% END %]" => '23');
process_ok("[% FOREACH f = [1..3] %][% IF loop.first %][% LAST %][% END %][% f %][% END %]" => '');
process_ok("[% FOREACH f = [1..3] %][% f %][% IF loop.first %][% NEXT %][% END %][% END %]" => '123');
process_ok("[% FOREACH f = [1..3] %][% f %][% IF loop.first %][% LAST %][% END %][% END %]" => '1');
process_ok("[% loop.odd    FOREACH [1..5] %]" => '10101');
process_ok("[% loop.even   FOREACH [1..5] %]" => '01010');
process_ok("[% loop.parity FOREACH [1..5] %]" => 'oddevenoddevenodd');

process_ok('[% a = ["Red", "Blue"] ; FOR [0..3] ; a.${ loop.index % a.size } ; END %]' => 'RedBlueRedBlue') if ! $is_tt;

### TT is not consistent in what is localized - well it is documented
### if you set a variable in the FOREACH tag, then nothing in the loop gets localized
### if you don't set a variable - everything gets localized
process_ok("[% foo = 1 %][% FOREACH [1..10] %][% foo %][% foo = 2 %][% END %]" => '1222222222');
process_ok("[% f = 1 %][% FOREACH i = [1..10] %][% i %][% f = 2 %][% END %][% f %]" => '123456789102');
process_ok("[% f = 1 %][% FOREACH [1..10] %][% f = 2 %][% END %][% f %]" => '1');
process_ok("[% f = 1 %][% FOREACH f = [1..10] %][% f %][% END %][% f %]" => '1234567891010');
process_ok("[% FOREACH [1] %][% SET a = 1 %][% END %][% a %]" => '');
process_ok("[% a %][% FOREACH [1] %][% SET a = 1 %][% END %][% a %]" => '');
process_ok("[% a = 2 %][% FOREACH [1] %][% SET a = 1 %][% END %][% a %]" => '2');
process_ok("[% a = 2 %][% FOREACH [1] %][% a = 1 %][% END %][% a %]" => '2');
process_ok("[% a = 2 %][% FOREACH i = [1] %][% a = 1 %][% END %][% a %]" => '1');
process_ok("[% FOREACH i = [1] %][% SET a = 1 %][% END %][% a %]" => '1');
process_ok("[% f.b = 1 %][% FOREACH f.b = [1..10] %][% f.b %][% END %][% f.b %]" => '1234567891010') if ! $is_tt;
process_ok("[% a = 1 %][% FOREACH [{a=>'A'},{a=>'B'}] %]bar[% a %][% END %][% a %]" => 'barAbarB1');
process_ok("[% FOREACH [1..3] %][% loop.size %][% END %][% loop.size %]" => '333');
process_ok("[% FOREACH i = [1..3] %][% loop.size %][% END %][% loop.size %]" => '333') if ! $is_tt;
process_ok("[% FOREACH i = [1..3] %][% loop.size %][% END %][% loop.size %]" => '3331') if $is_tt;

process_ok('[% FOREACH f = [1..3]; 1; END %]' => '111');
process_ok('[% FOREACH f = [1..3]; f; END %]' => '123');
process_ok('[% FOREACH f = [1..3]; "$f"; END %]' => '123');
process_ok('[% FOREACH f = [1..3]; f + 1; END %]' => '234');
process_ok('[% FOREACH f IN [2,3,4]; FOREACH g IN [6,7,8]; f;g;", "; END; END %]' => '26, 27, 28, 36, 37, 38, 46, 47, 48, ');

{
    package TEST_HASH_OBJ;
    sub n { shift->{'n'} }
}
{
    package TEST_ARRAY_OBJ;
    sub n { shift->[0] }
}
my @objs = map { bless {n => $_}, 'TEST_HASH_OBJ' } 1..3;
process_ok('[% FOREACH i IN foo; i.n; END %]' => '123', {foo => sub { \@objs }});
process_ok('[% FOREACH i IN foo; i.n; END %]' => '1', {foo => sub { [$objs[0]] }});
process_ok('[% FOREACH i IN foo; i.n; END %]' => '123', {foo => sub { @objs }});
process_ok('[% FOREACH i IN foo; i.n; END %]' => '1', {foo => sub { $objs[0] }});
@objs = map { bless [$_], 'TEST_ARRAY_OBJ' } 1..3;
process_ok('[% FOREACH i IN foo; i.n; END %]' => '123', {foo => sub { \@objs }});
process_ok('[% FOREACH i IN foo; i.n; END %]' => '1', {foo => sub { [$objs[0]] }});
process_ok('[% FOREACH i IN foo; i.n; END %]' => '123', {foo => sub { @objs }});
process_ok('[% FOREACH i IN foo; i.n; END %]' => '1', {foo => sub { $objs[0] }});

###----------------------------------------------------------------###
print "### LOOP ############################################ $engine_option\n";

process_ok("[% var = [{key => 'a'}, {key => 'b'}] -%]
[% LOOP var -%]
  ([% key %])
[% END %]" => "  (a)\n  (b)\n") if ! $is_tt;

if (! $is_tt) {
    local $Template::Alloy::QR_PRIVATE = 0;
    local $Template::Alloy::QR_PRIVATE = 0; # warn clean

    process_ok("[% var = [{key => 'a'}, {key => 'b'}, {key => 'c'}] -%]
[% LOOP var -%]
([% key; '|'; __first__; '|'; __last__; '|'; __inner__; '|'; __odd__ %])
[% END -%]" => "(a|1|0|0|1)
(b|0|0|1|0)
(c|0|1|0|1)
", {tt_config => [LOOP_CONTEXT_VARS => 1]});
}

###----------------------------------------------------------------###
print "### WHILE ########################################### $engine_option\n";

process_ok("[% WHILE foo %]" => '');
process_ok("[% WHILE foo %][% END %]" => '');
process_ok("[% WHILE (foo = foo - 1) %][% END %]" => '');
process_ok("[% WHILE (foo = foo - 1) %][% foo %][% END %]" => '21', {foo => 3});
process_ok("[% WHILE foo %][% foo %][% foo = foo - 1 %][% END %]" => '321', {foo => 3});

process_ok("[% WHILE 1 %][% foo %][% foo = foo - 1 %][% LAST IF foo == 1 %][% END %]" => '32', {foo => 3});
process_ok("[% f = 10; WHILE f; f = f - 1 ; f ; END %]" => '9876543210');
process_ok("[% f = 10; WHILE f; f = f - 1 ; f ; END ; f %]" => '98765432100');
process_ok("[% f = 10; a = 2; WHILE f; f = f - 1 ; f ; a=3; END ; a%]" => '98765432103');

process_ok("[% f = 10; WHILE (g=f); f = f - 1 ; f ; END %]" => '9876543210');
process_ok("[% f = 10; WHILE (g=f); f = f - 1 ; f ; END ; f %]" => '98765432100');
process_ok("[% f = 10; a = 2; WHILE (g=f); f = f - 1 ; f ; a=3; END ; a%]" => '98765432103');
process_ok("[% f = 10; a = 2; WHILE (a=f); f = f - 1 ; f ; a=3; END ; a%]" => '98765432100');

###----------------------------------------------------------------###
print "### STOP / RETURN / CLEAR ########################### $engine_option\n";

process_ok("[% STOP %]" => '');
process_ok("One[% STOP %]Two" => 'One');
process_ok("[% BLOCK foo %]One[% STOP %]Two[% END %]First[% PROCESS foo %]Last" => 'FirstOne');
process_ok("[% FOREACH f = [1..3] %][% f %][% IF loop.first %][% STOP %][% END %][% END %]" => '1');
process_ok("[% FOREACH f = [1..3] %][% IF loop.first %][% STOP %][% END %][% f %][% END %]" => '');

process_ok("[% RETURN %]" => '');
process_ok("One[% RETURN %]Two" => 'One');
process_ok("[% BLOCK foo %]One[% RETURN %]Two[% END %]First[% PROCESS foo %]Last" => 'FirstOneLast');
process_ok("[% FOREACH f = [1..3] %][% f %][% IF loop.first %][% RETURN %][% END %][% END %]" => '1');
process_ok("[% FOREACH f = [1..3] %][% IF loop.first %][% RETURN %][% END %][% f %][% END %]" => '');

process_ok("[% CLEAR %]" => '');
process_ok("One[% CLEAR %]Two" => 'Two') if ! $use_stream;
process_ok("[% BLOCK foo %]One[% CLEAR %]Two[% END %]First[% PROCESS foo %]Last" => 'FirstTwoLast') if ! $use_stream;
process_ok("[% FOREACH f = [1..3] %][% f %][% IF loop.first %][% CLEAR %][% END %][% END %]" => '23') if ! $use_stream;
process_ok("[% FOREACH f = [1..3] %][% IF loop.first %][% CLEAR %][% END %][% f %][% END %]" => '123') if ! $use_stream;
process_ok("[% FOREACH f = [1..3] %][% f %][% IF loop.last %][% CLEAR %][% END %][% END %]" => '') if ! $use_stream;
process_ok("[% FOREACH f = [1..3] %][% IF loop.last %][% CLEAR %][% END %][% f %][% END %]" => '3') if ! $use_stream;

###----------------------------------------------------------------###
print "### post opererative directives ##################### $engine_option\n";

process_ok("[% GET foo IF 1 %]" => '1', {foo => 1});
process_ok("[% f FOREACH f = [1..3] %]" => '123');

process_ok("2[% GET foo IF 1 IF 2 %]" => '21', {foo => 1})      if ! $is_tt;
process_ok("2[% GET foo IF 1 IF 0 %]" => '2',  {foo => 1})      if ! $is_tt;
process_ok("[% f FOREACH f = [1..3] IF 1 %]" => '123')          if ! $is_tt;
process_ok("[% f FOREACH f = [1..3] IF 0 %]" => '')             if ! $is_tt;
process_ok("[% f FOREACH f = g FOREACH g = [1..3] %]" => '123') if ! $is_tt;
process_ok("[% f FOREACH f = g.a FOREACH g = [{a=>1}, {a=>2}, {a=>3}] %]" => '123') if ! $is_tt;
process_ok("[% f FOREACH f = a FOREACH [{a=>1}, {a=>2}, {a=>3}] %]" => '123')       if ! $is_tt;

process_ok("[% FOREACH f = [1..3] IF 1 %]([% f %])[% END %]" => '(1)(2)(3)')        if ! $is_tt;
process_ok("[% FOREACH f = [1..3] IF 0 %]([% f %])[% END %]" => '')                 if ! $is_tt;

process_ok("[% BLOCK bar %][% foo %][% foo = foo - 1 %][% END %][% PROCESS bar WHILE foo %]" => '321', {foo => 3});

###----------------------------------------------------------------###
print "### capturing ####################################### $engine_option\n";

process_ok("[% foo = BLOCK %]Hi[% END %][% foo %][% foo %]" => 'HiHi');
process_ok("[% BLOCK foo %]Hi[% END %][% bar = PROCESS foo %]-[% bar %]" => '-Hi');
process_ok("[% foo = IF 1 %]Hi[% END %][% foo %]" => 'Hi');
process_ok("[% BLOCK foo %]([% i %])[% END %][% wow = PROCESS foo i='bar' %][% wow %]" => "(bar)");
process_ok("[% BLOCK foo %]([% i %])[% END %][% SET wow = PROCESS foo i='bar' %][% wow %]" => "(bar)") if ! $is_tt;

###----------------------------------------------------------------###
print "### TAGS ############################################ $engine_option\n";

process_ok("[% TAGS asp       %]<% 1 + 2 %>" => 3);
process_ok("[% TAGS default   %][% 1 + 2 %]" => 3);
process_ok("[% TAGS html      %]<!-- 1 + 2 -->" => '3');
process_ok("[% TAGS mason     %]<% 1 + 2 >"  => 3);
process_ok("[% TAGS metatext  %]%% 1 + 2 %%" => 3);
process_ok("[% TAGS php       %]<? 1 + 2 ?>" => 3);
process_ok("[% TAGS star      %][* 1 + 2 *]" => 3);
process_ok("[% TAGS template  %][% 1 + 2 %]" => 3);
process_ok("[% TAGS template1 %][% 1 + 2 %]" => 3);
process_ok("[% TAGS template1 %]%% 1 + 2 %%" => 3);
process_ok("[% TAGS tt2       %][% 1 + 2 %]" => 3);

process_ok("[% TAGS html %] <!--- 1 + 2 -->" => '3');
process_ok("[% TAGS html %]<!-- 1 + 2 --->" => '3') if ! $is_tt;
process_ok("[% TAGS html %]<!-- 1 + 2 --->\n" => '3');
process_ok("[% BLOCK foo %][% TAGS html %]<!-- 1 + 2 --><!-- END --><!-- PROCESS foo --> <!-- 1 + 2 -->" => '3 3');
process_ok("[% BLOCK foo %][% TAGS html %]<!-- 1 + 2 -->[% END %][% PROCESS foo %] [% 1 + 2 %]" => '');

process_ok("[% TAGS <!-- --> %]<!-- 1 + 2 -->" => '3');

process_ok("[% TAGS [<] [>]          %][<] 1 + 2 [>]" => 3);
process_ok("[% TAGS '[<]' '[>]'      %][<] 1 + 2 [>]" => 3) if ! $is_tt;
process_ok("[% TAGS /[<]/ /[>]/      %]<   1 + 2 >"  => 3) if ! $is_tt;
process_ok("[% TAGS ** **            %]**  1 + 2 **" => 3);
process_ok("[% TAGS '**' '**'        %]**  1 + 2 **" => 3) if ! $is_tt;
process_ok("[% TAGS /**/ /**/        %]**  1 + 2 **" => "") if ! $is_tt;

process_ok("[% TAGS html --><!-- 1 + 2 -->" => '3') if ! $is_tt;
process_ok("[% TAGS html ; 7 --><!-- 1 + 2 -->" => '73') if ! $is_tt;
process_ok("[% TAGS html ; 7 %]<!-- 1 + 2 -->" => '') if ! $is_tt; # error - the old closing tag must come next

###----------------------------------------------------------------###
print "### SWITCH / CASE ################################### $engine_option\n";

process_ok("[% SWITCH 1 %][% END %]hi" => 'hi');
process_ok("[% SWITCH 1 %][% CASE %]bar[% END %]hi" => 'barhi');
process_ok("[% SWITCH 1 %]Pre[% CASE %]bar[% END %]hi" => 'barhi');
process_ok("[% SWITCH 1 %][% CASE DEFAULT %]bar[% END %]hi" => 'barhi');
process_ok("[% SWITCH 1 %][% CASE 0 %]bar[% END %]hi" => 'hi');
process_ok("[% SWITCH 1 %][% CASE 1 %]bar[% END %]hi" => 'barhi');
process_ok("[% SWITCH 1 %][% CASE foo %][% CASE 1 %]bar[% END %]hi" => 'barhi');
process_ok("[% SWITCH 1 %][% CASE [1..10] %]bar[% END %]hi" => 'barhi');
process_ok("[% SWITCH 11 %][% CASE [1..10] %]bar[% END %]hi" => 'hi');

process_ok("[% SWITCH 1.0 %][% CASE [1..10] %]bar[% END %]hi" => 'barhi');

###----------------------------------------------------------------###
print "### TRY / THROW / CATCH / FINAL ##################### $engine_option\n";

process_ok("[% TRY %][% END %]hi" => 'hi');
process_ok("[% TRY %]Foo[% END %]hi" => 'Foohi');
process_ok("[% TRY %]Foo[% THROW foo 'for fun' %]bar[% END %]hi" => ($use_stream ? 'Foo' : ''));
process_ok("[% TRY %]Foo[% THROW foo 'for fun' %]bar[% CATCH %][% END %]hi" => 'Foohi') if ! $is_tt;
process_ok("[% TRY %]Foo[% THROW foo 'for fun' %]bar[% CATCH %]there[% END %]hi" => 'Footherehi');
process_ok("[% TRY %]Foo[% THROW foo 'for fun' %]bar[% CATCH foo %]there[% END %]hi" => 'Footherehi');
process_ok("[% TRY %]Foo[% TRY %]Foo[% THROW foo 'for fun' %][% CATCH bar %]one[% END %][% CATCH %]two[% END %]hi" => 'FooFootwohi');
process_ok("[% TRY %]Foo[% TRY %]Foo[% THROW foo 'for fun' %][% CATCH bar %]one[% END %][% CATCH s %]two[% END %]hi" => ($use_stream ? 'FooFoo' : ''));
process_ok("[% TRY %]Foo[% THROW foo.bar 'for fun' %][% CATCH foo %]one[% CATCH foo.bar %]two[% END %]hi" => 'Footwohi');

process_ok("[% TRY %]Foo[% FINAL %]Bar[% END %]hi" => 'FooBarhi');
process_ok("[% TRY %]Foo[% THROW foo %][% FINAL %]Bar[% CATCH %]one[% END %]hi" => '');
process_ok("[% TRY %]Foo[% THROW foo %][% CATCH %]one[% FINAL %]Bar[% END %]hi" => 'FoooneBarhi');
process_ok("[% TRY %]Foo[% THROW foo %][% CATCH bar %]one[% FINAL %]Bar[% END %]hi" => ($use_stream ? 'Foo' : ''));

process_ok("[% TRY %][% THROW foo 'bar' %][% CATCH %][% error %][% END %]" => 'foo error - bar');
process_ok("[% TRY %][% THROW foo 'bar' %][% CATCH %][% error.type %][% END %]" => 'foo');
process_ok("[% TRY %][% THROW foo 'bar' %][% CATCH %][% error.info %][% END %]" => 'bar');
process_ok("[% TRY %][% THROW foo %][% CATCH %][% error.type %][% END %]" => 'undef');
process_ok("[% TRY %][% THROW foo %][% CATCH %][% error.info %][% END %]" => 'foo');

###----------------------------------------------------------------###
print "### named args ###################################### $engine_option\n";

process_ok("[% foo(bar = 'one', baz = 'two') %]" => "baronebaztwo",
               {foo=>sub{my $n=$_[-1];join('',map{"$_$n->{$_}"} sort keys %$n)}});
process_ok("[%bar='ONE'%][% foo(\$bar = 'one') %]" => "ONEone",
               {foo=>sub{my $n=$_[-1];join('',map{"$_$n->{$_}"} sort keys %$n)}});

###----------------------------------------------------------------###
print "### USE ############################################# $engine_option\n";

my @config_p = (PLUGIN_BASE => 'MyTestPlugin', LOAD_PERL => 1);
process_ok("[% USE son_of_gun_that_does_not_exist %]one" => '', {tt_config => \@config_p});
process_ok("[% USE Iterator([3..6]) %]hey[% CALL Iterator.get_first; Iterator.size %]" => "hey4");
process_ok("[% USE FooTest %]one" => 'one', {tt_config => \@config_p});
process_ok("[% USE FooTest2 %]one" => 'one', {tt_config => \@config_p});
process_ok("[% USE FooTest(bar = 'baz') %]one[% FooTest.bar %]" => 'onebarbaz', {tt_config => \@config_p});
process_ok("[% USE FooTest2(bar = 'baz') %]one[% FooTest2.bar %]" => 'onebarbaz', {tt_config => \@config_p});
process_ok("[% USE FooTest(bar = 'baz') %]one[% FooTest.bar %]" => 'onebarbaz', {tt_config => \@config_p});
process_ok("[% USE d = FooTest(bar = 'baz') %]one[% d.bar %]" => 'onebarbaz', {tt_config => \@config_p});
process_ok("[% USE d.d = FooTest(bar = 'baz') %]one[% d.d.bar %]" => '', {tt_config => \@config_p});
process_ok("[% USE FooTest(somerand = 8) %]one[% FooTest.somerand %]" => 'one8', {tt_config => \@config_p});

process_ok("[% USE a(bar = 'baz') %]one[% a.seven %]" => '',     {tt_config => [@config_p, PLUGINS => {a=>'FooTest'}, ]});
process_ok("[% USE a(bar = 'baz') %]one[% a.seven %]" => 'one7', {tt_config => [@config_p, PLUGINS => {a=>'FooTest2'},]});

@config_p = (PLUGIN_BASE => ['NonExistant', 'MyTestPlugin'], LOAD_PERL => 1);
process_ok("[% USE FooTest %]three" => 'three', {tt_config => \@config_p});

###----------------------------------------------------------------###
print "### MACRO ########################################### $engine_option\n";

process_ok("[% MACRO foo PROCESS bar %][% BLOCK bar %]Hi[% END %][% foo %]" => 'Hi');
process_ok("[% MACRO foo BLOCK %]Hi[% END %][% foo %]" => 'Hi');
process_ok("[% MACRO foo BLOCK %]Hi[% END %][% foo %]" => 'Hi');
process_ok("[% MACRO foo(n) BLOCK %]Hi[% n %][% END %][% foo(2) %]" => 'Hi2');
process_ok("[%n=1%][% MACRO foo(n) BLOCK %]Hi[% n %][% END %][% foo(2) %][%n%]" => 'Hi21');
process_ok("[%n=1%][% MACRO foo BLOCK %]Hi[% n = 2%][% END %][% foo %][%n%]" => 'Hi1');
process_ok("[% MACRO foo(n) FOREACH i=[1..n] %][% i %][% END %][% foo(3) %]" => '123');

process_ok('[% MACRO f BLOCK %]>[% TRY; f ; CATCH ;  "caught" ; END %][% END %][% f %]' => '>>>caught', {tt_config => [MAX_MACRO_RECURSE => 3]}) if ! $is_tt;

if (! $is_tt) {
    process_ok("[% foo = ->{ 'Hi' } %][% foo %]" => 'Hi');
    process_ok("[% foo = ->{ 'Hi'; this } %][% foo(2) %]" => 'Hi2');
    process_ok("[% foo = ->(n){ 'Hi'; n } %][% foo(2) %]" => 'Hi2');
    process_ok("[%n=1%][% foo = ->(n) { 'Hi' ; n } %][% foo(2) %][%n%]" => 'Hi21');
    process_ok("[% foo = ->(n) { FOREACH i=[1..n]; i ; END } %][% foo(3) %]" => '123');
}

###----------------------------------------------------------------###
print "### DEBUG ########################################### $engine_option\n";

process_ok("\n\n[% one %]" => "\n\n\n## input text line 3 : [% one %] ##\nONE", {one=>'ONE', tt_config => ['DEBUG' => 8]});
process_ok("[% one %]" => "\n## input text line 1 : [% one %] ##\nONE", {one=>'ONE', tt_config => ['DEBUG' => 8]});
process_ok("[% one %]\n\n" => "(1)ONE\n\n", {one=>'ONE', tt_config => ['DEBUG' => 8, 'DEBUG_FORMAT' => '($line)']});
process_ok("1\n2\n3[% one %]" => "1\n2\n3(3)ONE", {one=>'ONE', tt_config => ['DEBUG' => 8, 'DEBUG_FORMAT' => '($line)']});
process_ok("[% one;\n one %]" => "(1)ONE(2)ONE", {one=>'ONE', tt_config => ['DEBUG' => 8,
                                                                            'DEBUG_FORMAT' => '($line)']}) if ! $is_tt;
process_ok("[% DEBUG format '(\$line)' %][% one %]" => qr/\(1\)/, {one=>'ONE', tt_config => ['DEBUG' => 8]});

process_ok("[% TRY %][% abc %][% CATCH %][% error %][% END %]" => "undef error - abc is undefined\n", {tt_config => ['DEBUG' => 2]});
process_ok("[% TRY %][% abc.def %][% CATCH %][% error %][% END %]" => "undef error - def is undefined\n", {abc => {}, tt_config => ['DEBUG' => 2]}) if $is_tt;
process_ok("[% TRY %][% abc.def %][% CATCH %][% error %][% END %]" => "undef error - abc.def is undefined\n", {abc => {}, tt_config => ['DEBUG' => 2]}) if !$is_tt;

###----------------------------------------------------------------###
print "### constants ####################################### $engine_option\n";

my @config_c = (
    CONSTANTS => {
        harry => sub {'do_this_once'},
        foo  => {
            bar => {baz => 42},
            bim => 57,
        },
        bing => 'baz',
        bang => 'bim',
    },
    VARIABLES => {
        bam  => 'bar',
    },
);
process_ok("[% constants.harry %]" => 'do_this_once', {constants => {harry => 'foo'}, tt_config => \@config_c});
process_ok("[% constants.harry.length %]" => '12', {tt_config => \@config_c});
process_ok("[% SET constants.something = 1 %][% constants.something %]one" => '1one', {tt_config => \@config_c});
process_ok("[% SET constants.harry = 1 %][% constants.harry %]one" => 'do_this_onceone', {tt_config => \@config_c});
process_ok("[% constants.foo.\${constants.bang} %]" => '57', {tt_config => [@config_c]});
process_ok("[% constants.foo.\$bam.\${constants.bing} %]" => '42', {tt_config => [@config_c]}) if ! $is_tt;
process_ok("[% bam = 'somethingelse' %][% constants.foo.\$bam.\${constants.bing} %]" => '42', {tt_config => [@config_c]}) if ! $is_tt;

process_ok('[% constants.${"harry"} %]' => 'do_this_once', {constants => {harry => 'foo'}, tt_config => \@config_c});
process_ok('[% ${"constants"}.harry %]' => 'foo', {constants => {harry => 'foo'}, tt_config => \@config_c}) if ! $is_tt;
process_ok('[% ${"constants"}.harry %]' => 'do_this_once', {constants => {harry => 'foo'}, tt_config => \@config_c}) if $is_tt;
process_ok('[% ${"con${"s"}tants"}.harry %]' => 'foo', {constants => {harry => 'foo'}, tt_config => \@config_c}) if ! $is_tt;

###----------------------------------------------------------------###
print "### CONTEXT ######################################### $engine_option\n";

$cctx->{'bang'} = 'bing';
process_ok("[% CALL cctx.call_me  %][% cctx.last_context %]" => "list", {cctx => $cctx});
process_ok("[% cctx.array  %]" => qr{^ARRAY}, {cctx => $cctx});
process_ok("[% cctx.array2 %]" => "4",        {cctx => $cctx});
process_ok("[% cctx.list   %]" => qr{^ARRAY}, {cctx => $cctx});
process_ok("[% cctx.scalar %]" => "8",        {cctx => $cctx});
process_ok("[% cctx.bang   %]" => "bing",     {cctx => $cctx});

if (! $is_tt) {
    $cctx->{'clear'}->();
    process_ok('[% CALL cctx.call_me %][% cctx.last_context %]'    => "list",   {cctx => $cctx});
    process_ok('[% CALL @(cctx.call_me) %][% cctx.last_context %]' => "list",   {cctx => $cctx});
    process_ok('[% CALL $(cctx.call_me) %][% cctx.last_context %]' => "scalar", {cctx => $cctx});
    process_ok('[% CALL call_cctx %][% cctx.last_context %]'    => "list",   {cctx => $cctx, call_cctx => sub { $cctx->{'call_me'}->() }});
    process_ok('[% CALL @(call_cctx) %][% cctx.last_context %]' => "list",   {cctx => $cctx, call_cctx => sub { $cctx->{'call_me'}->() }});
    process_ok('[% CALL $(call_cctx) %][% cctx.last_context %]' => "scalar", {cctx => $cctx, call_cctx => sub { $cctx->{'call_me'}->() }});
    process_ok('[% CALL cctx.call_me %][% cctx.last_context %]' => "list",   {cctx => $cctx, tt_config => [CALL_CONTEXT => 'smart']});
    process_ok('[% CALL cctx.call_me %][% cctx.last_context.0 %]' => "list", {cctx => $cctx, tt_config => [CALL_CONTEXT => 'list']});
    process_ok('[% CALL cctx.call_me %][% cctx.last_context %]' => "scalar", {cctx => $cctx, tt_config => [CALL_CONTEXT => 'item']});
    process_ok('[% cctx.array %]'    => qr{^ARRAY},  {cctx => $cctx});
    process_ok('[% @(cctx.array) %]' => qr{^ARRAY},  {cctx => $cctx});
    process_ok('[% $(cctx.array) %]' => '3',         {cctx => $cctx});
    process_ok('[% cctx.array2 %]'    => '4',        {cctx => $cctx});
    process_ok('[% @(cctx.array2) %]' => qr{^ARRAY}, {cctx => $cctx});
    process_ok('[% $(cctx.array2) %]' => '1',        {cctx => $cctx});
    process_ok('[% cctx.list %]'    => qr{^ARRAY},   {cctx => $cctx});
    process_ok('[% @(cctx.list) %]' => qr{^ARRAY},   {cctx => $cctx});
    process_ok('[% $(cctx.list) %]' => '7',          {cctx => $cctx});
    process_ok('[% cctx.scalar %]'    => '8',        {cctx => $cctx});
    process_ok('[% @(cctx.scalar) %]' => qr{^ARRAY}, {cctx => $cctx});
    process_ok('[% $(cctx.scalar) %]' => '8',        {cctx => $cctx});
    process_ok('[% cctx.bang   %] ~'    => 'bing ~', {cctx => $cctx});
    process_ok('[% @(cctx.bang)   %] ~' => 'bing ~', {cctx => $cctx});
    process_ok('[% $(cctx.bang)   %] ~' => 'bing ~', {cctx => $cctx});
    $cctx->{'clear'}->();
    process_ok('[% CONFIG CALL_CONTEXT => "list"; CALL cctx.call_me; CONFIG CALL_CONTEXT => "smart" %][% cctx.last_context %]' => "list", {cctx => $cctx});
    $cctx->{'clear'}->();
    process_ok('[% CONFIG CALL_CONTEXT => "item"; CALL cctx.call_me %][% cctx.last_context %]' => "scalar", {cctx => $cctx});
    delete $cctx->{'data'};
    process_ok('[% cctx.dataref.0.foo = 7; cctx.dataref.0.foo %]' => "7", {cctx => $cctx});
    delete $cctx->{'data'};
    process_ok('[% @(cctx.dataref).0.foo = 7; cctx.dataref.foo %]' => "7", {cctx => $cctx});
    delete $cctx->{'data'};
    process_ok('[% $(cctx.dataref).0.foo = 7; cctx.dataref.0.foo %]'=> "7", {cctx => $cctx});
    delete $cctx->{'data'};
    process_ok('[% CONFIG CALL_CONTEXT => "list"; cctx.dataref.0.foo = 7; CONFIG CALL_CONTEXT => "item"; cctx.dataref.foo %]'=> "7", {cctx => $cctx});
}

# call context with methods
process_ok("[% cctxo.data = 1 %] ~" => "",   {cctxo => $cctxo})   if $is_tt; # TT lets you read but not write - weird
process_ok("[% cctxo.bang = 1 %] ~" => " ~", {cctxo => $cctxo});
process_ok("[% cctxo.dataref.foo = 7; cctxo.dataref.foo %]" => "7", {cctxo => $cctxo});
if (! $is_tt) {
    process_ok('[% CALL cctxo.call_me %][% cctxo.last_context %]'    => "list",   {cctxo => $cctxo});
    process_ok('[% CALL @(cctxo.call_me) %][% cctxo.last_context %]' => "list",   {cctxo => $cctxo});
    process_ok('[% CALL $(cctxo.call_me) %][% cctxo.last_context %]' => "scalar", {cctxo => $cctxo});
    process_ok('[% CALL call_cctxo %][% cctxo.last_context %]'    => "list",   {cctxo => $cctxo, call_cctxo => sub { $cctxo->call_me }});
    process_ok('[% CALL @(call_cctxo) %][% cctxo.last_context %]' => "list",   {cctxo => $cctxo, call_cctxo => sub { $cctxo->call_me }});
    process_ok('[% CALL $(call_cctxo) %][% cctxo.last_context %]' => "scalar", {cctxo => $cctxo, call_cctxo => sub { $cctxo->call_me }});
    process_ok('[% CALL cctxo.call_me %][% cctxo.last_context %]' => "list",   {cctxo => $cctxo, tt_config => [CALL_CONTEXT => 'smart']});
    process_ok('[% CALL cctxo.call_me %][% cctxo.last_context.0 %]' => "list", {cctxo => $cctxo, tt_config => [CALL_CONTEXT => 'list']});
    process_ok('[% CALL cctxo.call_me %][% cctxo.last_context %]' => "scalar", {cctxo => $cctxo, tt_config => [CALL_CONTEXT => 'item']});
    process_ok('[% cctxo.array %]'    => qr{^ARRAY},  {cctxo => $cctxo});
    process_ok('[% @(cctxo.array) %]' => qr{^ARRAY},  {cctxo => $cctxo});
    process_ok('[% $(cctxo.array) %]' => '3',         {cctxo => $cctxo});
    process_ok('[% cctxo.array2 %]'    => '4',        {cctxo => $cctxo});
    process_ok('[% @(cctxo.array2) %]' => qr{^ARRAY}, {cctxo => $cctxo});
    process_ok('[% $(cctxo.array2) %]' => '1',        {cctxo => $cctxo});
    process_ok('[% cctxo.list %]'    => qr{^ARRAY},   {cctxo => $cctxo});
    process_ok('[% @(cctxo.list) %]' => qr{^ARRAY},   {cctxo => $cctxo});
    process_ok('[% $(cctxo.list) %]' => '7',          {cctxo => $cctxo});
    process_ok('[% cctxo.scalar %]'    => '8',        {cctxo => $cctxo});
    process_ok('[% @(cctxo.scalar) %]' => qr{^ARRAY}, {cctxo => $cctxo});
    process_ok('[% $(cctxo.scalar) %]' => '8',        {cctxo => $cctxo});
    process_ok('[% cctxo.bang   %] ~'    => 'bing ~', {cctxo => $cctxo});

    $cctx->{'clear'}->();
    process_ok('[% SET cctxo.call_me    = 2 %][% cctxo.last_context %]' => "list2", {cctxo => $cctxo});
    $cctx->{'clear'}->();
    process_ok('[% CALL @(cctxo.call_me = 3) %][% cctxo.last_context %]' => "list3", {cctxo => $cctxo});
    $cctx->{'clear'}->();
    process_ok('[% CALL $(cctxo.call_me = 4) %][% cctxo.last_context %]' => "scalar4", {cctxo => $cctxo});
}

###----------------------------------------------------------------###
print "### INTERPOLATE ##################################### $engine_option\n";

process_ok("Foo \$one Bar" => 'Foo ONE Bar', {one => 'ONE', tt_config => ['INTERPOLATE' => 1]});
process_ok("[% PERL %] my \$n=7; print \$n [% END %]" => '7', {tt_config => ['INTERPOLATE' => 1, 'EVAL_PERL' => 1]});
process_ok("[% TRY ; PERL %] my \$n=7; print \$n [% END ; END %]" => '7', {tt_config => ['INTERPOLATE' => 1, 'EVAL_PERL' => 1]});

my $slash = '\\';
my $interp_i = 0;
process_ok("Foo $slash Bar"        => "Foo $slash Bar",       {tt_config => ['INTERPOLATE' => 1]});
process_ok("Foo $slash$slash Bar"  => "Foo $slash$slash Bar", {tt_config => ['INTERPOLATE' => 1]});
process_ok("Foo ${slash}n Bar"     => "Foo ${slash}n Bar",    {tt_config => ['INTERPOLATE' => 1]});
process_ok("Foo $slash\$a Bar"             => "Foo \$a Bar",             {a=>7, tt_config => ['INTERPOLATE' => 1]});
process_ok("Foo $slash$slash\$a Bar"       => "Foo $slash${slash}7 Bar", {a=>7, tt_config => ['INTERPOLATE' => 1]});
process_ok("Foo $slash$slash$slash\$a Bar" => "Foo $slash$slash\$a Bar", {a=>7, tt_config => ['INTERPOLATE' => 1]});
process_ok('Foo $a.B Bar'           => 'Foo 7 Bar', {a=>{B=>7,b=>{c=>sub{"(@_)"}}}, tt_config => ['INTERPOLATE' => 1]});
process_ok('Foo ${ a.B } Bar'       => 'Foo 7 Bar', {a=>{B=>7,b=>{c=>sub{"(@_)"}}}, tt_config => ['INTERPOLATE' => 1]});
process_ok('Foo $a.b.c("hi") Bar'   => "Foo <hi> Bar",     {a=>{B=>7,b=>{c=>sub{"<@_>"}}}, tt_config => ['INTERPOLATE' => 1]}) if ! $is_tt;
process_ok('Foo $a.b.c("hi") Bar'   => "Foo <>(\"hi\") Bar", {a=>{B=>7,b=>{c=>sub{"<@_>"}}}, tt_config => ['INTERPOLATE' => 1]}) if $is_tt;
process_ok('Foo ${a.b.c("hi")} Bar' => "Foo <hi> Bar", {a=>{B=>7,b=>{c=>sub{"<@_>"}}}, tt_config => ['INTERPOLATE' => 1]});
process_ok('Foo $a Bar $!a Baz'     => "Foo 7 Bar 7 Baz", {a => 7, tt_config => ['INTERPOLATE' => 1]}) if ! $is_tt;
process_ok('Foo $a Bar $!{a} Baz'   => "Foo 7 Bar 7 Baz", {a => 7, tt_config => ['INTERPOLATE' => 1]}) if ! $is_tt;
process_ok('Foo $a Bar $!a Baz'     => "Foo 7 Bar 7 Baz", {a => 7, tt_config => ['INTERPOLATE' => 1, SHOW_UNDEFINED_INTERP => 1]}) if ! $is_tt;
process_ok('Foo $a Bar $!{a} Baz'   => "Foo 7 Bar 7 Baz", {a => 7, tt_config => ['INTERPOLATE' => 1, SHOW_UNDEFINED_INTERP => 1]}) if ! $is_tt;
process_ok('Foo $a Bar $!a Baz'     => "Foo \$a Bar  Baz",   {tt_config => ['INTERPOLATE' => 1, SHOW_UNDEFINED_INTERP => 1]}) if ! $is_tt;
process_ok('Foo ${a} Bar $!{a} Baz' => "Foo \${a} Bar  Baz", {tt_config => ['INTERPOLATE' => 1, SHOW_UNDEFINED_INTERP => 1]}) if ! $is_tt;

###----------------------------------------------------------------###
print "### ANYCASE / TRIM ################################## $engine_option\n";

process_ok("[% GET %]" => '', {GET => 'ONE'});
process_ok("[% GET GET %]" => 'ONE', {GET => 'ONE'}) if ! $is_tt;
process_ok("[% get one %]" => 'ONE', {one => 'ONE', tt_config => ['ANYCASE' => 1]});
process_ok("[% get %]" => '', {get => 'ONE', tt_config => ['ANYCASE' => 1]});
process_ok("[% get get %]" => 'ONE', {get => 'ONE', tt_config => ['ANYCASE' => 1]}) if ! $is_tt;

process_ok("[% BLOCK foo %]\nhi\n[% END %][% PROCESS foo %]" => "\nhi\n");
process_ok("[% BLOCK foo %]\nhi[% END %][% PROCESS foo %]" => ($use_stream ? "\nhi" : "hi"), {tt_config => [TRIM => 1]});
process_ok("[% BLOCK foo %]hi\n[% END %][% PROCESS foo %]" => ($use_stream ? "hi\n" : "hi"), {tt_config => [TRIM => 1]});
process_ok("[% BLOCK foo %]hi[% nl %][% END %][% PROCESS foo %]" => ($use_stream ? "hi\n" : "hi"), {nl => "\n", tt_config => [TRIM => 1]});
process_ok("[% BLOCK foo %][% nl %]hi[% END %][% PROCESS foo %]" => ($use_stream ? "\nhi" : "hi"), {nl => "\n", tt_config => [TRIM => 1]});
process_ok("A[% TRY %]\nhi\n[% END %]" => ($use_stream ? "A\nhi\n" : "A\nhi"), {tt_config => [TRIM => 1]});

process_ok("[% FOO %]" => 'foo', {foo => 'foo', tt_config => [LOWER_CASE_VAR_FALLBACK => 1]}) if ! $is_tt;

###----------------------------------------------------------------###
print "### V1DOLLAR ######################################## $engine_option\n";

process_ok('[% a %]|[% $a %]|[% ${ a } %]|[% ${ "a" } %]' => 'A|bar|bar|A', {a => 'A', A => 'bar'});
process_ok('[% a %]|[% $a %]|[% ${ a } %]|[% ${ "a" } %]' => 'A|A|bar|A', {a => 'A', A => 'bar', tt_config => [V1DOLLAR => 1]});

$vars = {a => {b => {c=>'Cb'}, B => {c=>'CB'}}, b => 'B', Cb => 'bar', CB => 'Bar'};
process_ok('[% a.b.c %]|[% $a.b.c %]|[% a.$b.c %]|[% ${ a.b.c } %]' => 'Cb||CB|bar', $vars);
process_ok('[% a.b.c %]|[% $a.b.c %]|[% a.$b.c %]|[% ${ a.b.c } %]' => 'Cb|Cb|Cb|bar', {%$vars, tt_config => [V1DOLLAR => 1]});

process_ok('[% "$a" %]/$a/[% "${a}" %]/${a}' => 'A/$a/A/${a}', {a => 'A', A => 'bar'});
process_ok('[% "$a" %]/$a/[% "${a}" %]/${a}' => 'A/$a/A/${a}', {a => 'A', A => 'bar', tt_config => [V1DOLLAR => 1]});
process_ok('[% "$a" %]/$a/[% "${a}" %]/${a}' => 'A/A/A/A',     {a => 'A', A => 'bar', tt_config => [INTERPOLATE => 1]});
process_ok('[% "$a" %]/$a/[% "${a}" %]/${a}' => 'A/A/A/A',     {a => 'A', A => 'bar', tt_config => [V1DOLLAR => 1, INTERPOLATE => 1]});

process_ok('[% constants.a %]|[% $constants.a %]|[% constants.$a %]' => 'A|A|A', {tt_config => [V1DOLLAR => 1, CONSTANTS => {a => 'A'}]});

###----------------------------------------------------------------###
print "### V2PIPE / V2EQUALS ############################### $engine_option\n";

process_ok("[%- BLOCK a %]b is [% b %]
[% END %]
[%- PROCESS a b => 237 | repeat(2) %]" => "b is 237
b is 237\n", {tt_config => [V2PIPE => 1]});

process_ok("[%- BLOCK a %]b is [% b %]
[% END %]
[%- PROCESS a b => 237 | repeat(2) %]" => "b is 237237\n") if ! $is_tt;

process_ok("[% ('a' == 'b') || 0 %]" => 0);
process_ok("[% ('a' != 'b') || 0 %]" => 1);
process_ok("[% ('a' == 'b') || 0 %]" => 0, {tt_config => [V2EQUALS => 1]}) if ! $is_tt;
process_ok("[% ('a' != 'b') || 0 %]" => 1, {tt_config => [V2EQUALS => 1]}) if ! $is_tt;
process_ok("[% ('a' == 'b') || 0 %]" => 1, {tt_config => [V2EQUALS => 0]}) if ! $is_tt;
process_ok("[% ('a' != 'b') || 0 %]" => 0, {tt_config => [V2EQUALS => 0]}) if ! $is_tt;
process_ok("[% ('7' == '7.0') || 0 %]" => 0);
process_ok("[% ('7' == '7.0') || 0 %]" => 1, {tt_config => [V2EQUALS => 0]}) if ! $is_tt;
process_ok("[% (7 == 7.0) || 0 %]" => 1);
process_ok("[% (7 == 7.0) || 0 %]" => 1, {tt_config => [V2EQUALS => 0]}) if ! $is_tt;

###----------------------------------------------------------------###
print "### configuration ################################### $engine_option\n";

process_ok('[% a = 7 %]$a' => 7, {tt_config => ['INTERPOLATE' => 1]});
process_ok('[% a = 7 %]$a' => 7, {tt_config => ['interpolate' => 1]}) if ! $is_tt;

###----------------------------------------------------------------###
print "### PERL ############################################ $engine_option\n";

process_ok("[% TRY %][% PERL %][% END %][% CATCH ; error; END %]" => 'perl error - EVAL_PERL not set');
process_ok("[% PERL %] print \"[% one %]\" [% END %]" => 'ONE', {one => 'ONE', tt_config => ['EVAL_PERL' => 1]});
process_ok("[% PERL %] print \$stash->get('one') [% END %]" => 'ONE', {one => 'ONE', tt_config => ['EVAL_PERL' => 1]});
process_ok("[% PERL %] print \$stash->set('a.b.c', 7) [% END %][% a.b.c %]" => '77', {tt_config => ['EVAL_PERL' => 1]});
process_ok("[% RAWPERL %]\$output .= 'interesting'[% END %]" => 'interesting', {tt_config => ['EVAL_PERL' => 1]});

###----------------------------------------------------------------###
print "### recursion prevention ############################ $engine_option\n";

process_ok("[% BLOCK foo %][% PROCESS bar %][% END %][% BLOCK bar %][% PROCESS foo %][% END %][% PROCESS foo %]" => '') if ! $is_tt;

###----------------------------------------------------------------###
print "### META ############################################ $engine_option\n";

process_ok("[% template.name %]" => 'input text');
process_ok("[% META foo = 'bar' %][% template.foo %]" => 'bar');
process_ok("[% META name = 'bar' %][% template.name %]" => 'bar');
process_ok("[% META foo = 'bar' %][% component.foo %]" => 'bar');
process_ok("[% META foo = 'bar' %][% component = '' %][% component.foo %]|foo" => '|foo');
process_ok("[% META foo = 'bar' %][% template = '' %][% template.foo %]|foo" => '|foo');

###----------------------------------------------------------------###
print "### references ###################################### $engine_option\n";

process_ok("[% a=3; b=\\a; b; a %]" => 33);
process_ok("[% a=3; b=\\a; a=7; b; a %]" => 77);

process_ok("[% a={}; a.1=7; b=\\a.1; b; a.1 %]" => '77');
process_ok("[% a={}; a.1=7; b=\\a.20; a.20=7; b; a.20 %]" => '77');

process_ok("[% a=[]; a.1=7; b=\\a.1; b; a.1 %]" => '77');
process_ok("[% a=[]; a.1=7; b=\\a.20; a.20=7; b; a.20 %]" => '77');

process_ok("[% \\a %]" => qr/^CODE/, {a => sub { return "a sub [@_]" } });
process_ok("[% b=\\a; b %]" => 'a sub []', {a => sub { return "a sub [@_]" } });
process_ok("[% b=\\a(1); b %]" => 'a sub [1]', {a => sub { return "a sub [@_]" } });
process_ok("[% b=\\a; b(2) %]" => 'a sub [2]', {a => sub { return "a sub [@_]" } });
process_ok("[% b=\\a(1); b(2) %]" => 'a sub [1 2]', {a => sub { return "a sub [@_]" } });
process_ok("[% f=\\j.k; j.k=7; f %]" => '7', {j => {k => 3}});

process_ok('[% a = "a" ; f = {a=>"A",b=>"B"} ; foo = \f.$a ; foo %]' => 'A');
process_ok('[% a = "a" ; f = {a=>"A",b=>"B"} ; foo = \f.$a ; a = "b" ; foo %]' => 'A');
process_ok('[% a = "ab" ; f = "abcd"; foo = \f.replace(a, "-AB-") ; a = "cd"; foo %]' => '-AB-cd');
process_ok('[% a = "ab" ; f = "abcd"; foo = \f.replace(a, "-AB-").replace("-AB-", "*") ; a = "cd"; foo %]' => '*cd');

process_ok('[% a = "ab" ; f = "abcd"; foo = \f.replace(a, "-AB-") ; f = "ab"; foo %]' => '-AB-cd');
process_ok('[% a = "ab" ; f = "abcd"; foo = \f.replace(a, "-AB-").replace("-AB-", "*") ; f = "ab"; foo %]' => '*cd');

###----------------------------------------------------------------###
print "### reserved words ################################## $engine_option\n";

$vars = {
    GET => 'named_get',
    get => 'lower_named_get',
    named_get => 'value of named_get',
    hold_get => 'GET',
};
process_ok("[% GET %]" => '', $vars);
process_ok("[% GET GET %]" => 'named_get', $vars) if ! $is_tt;
process_ok("[% GET get %]" => 'lower_named_get', $vars);
process_ok("[% GET \${'GET'} %]" => 'bar', {GET => 'bar'});

process_ok("[% GET = 1 %][% GET GET %]" => '', $vars);
process_ok("[% SET GET = 1 %][% GET GET %]" => '1', $vars) if ! $is_tt;

process_ok("[% GET \$hold_get %]" => 'named_get', $vars);
process_ok("[% GET \$GET %]" => 'value of named_get', $vars) if ! $is_tt;
process_ok("[% BLOCK GET %]hi[% END %][% PROCESS GET %]" => 'hi') if ! $is_tt;
process_ok("[% BLOCK foo %]hi[% END %][% PROCESS foo a = GET %]" => 'hi', $vars) if ! $is_tt;
process_ok("[% BLOCK foo %]hi[% END %][% PROCESS foo GET = 1 %]" => '');
process_ok("[% BLOCK foo %]hi[% END %][% PROCESS foo IF GET %]" => 'hi', $vars) if ! $is_tt;

###----------------------------------------------------------------###
print "### embedded items ################################## $engine_option\n";

process_ok('[% " \" " %]' => ' " ');
process_ok('[% " \$foo " %]' => ' $foo ');
process_ok('[% " \${foo} " %]' => ' ${foo} ');
process_ok('[% " \n " %]' => " \n ");
process_ok('[% " \t " %]' => " \t ");
process_ok('[% " \r " %]' => " \r ");

process_ok("[% 'foo\\'bar' %]"  => "foo'bar");
process_ok('[% "foo\\"bar" %]'  => 'foo"bar');
process_ok('[% qw(foo \)).1 %]' => ')') if ! $is_tt;
process_ok('[% qw|foo \||.1 %]' => '|') if ! $is_tt;

process_ok("[% ' \\' ' %]" => " ' ");
process_ok("[% ' \\r ' %]" => ' \r ');
process_ok("[% ' \\n ' %]" => ' \n ');
process_ok("[% ' \\t ' %]" => ' \t ');
process_ok("[% ' \$foo ' %]" => ' $foo ');

process_ok('[% A = "bar" ; ${ "A" } %]' => 'bar');
process_ok('[% A = "bar" ; "(${ A })" %]' => '(bar)');
process_ok('[% A = "bar" ; ${ {a => "A"}.a } %]' => 'bar') if ! $is_tt;
process_ok('[% A = "bar" ; "(${ {a => "A"}.a })" %]' => '(A)') if ! $is_tt;
process_ok('[% A = "bar" ; "(${ ${ {a => "A"}.a } })" %]' => '(bar)') if ! $is_tt;
process_ok('[% A = "bar" %](${ {a => "A"}.a })' => '(A)', {tt_config => [INTERPOLATE => 1]}) if ! $is_tt;
process_ok('[% A = "bar" %](${ ${ {a => "A"}.a } })' => '(bar)', {tt_config => [INTERPOLATE => 1]}) if ! $is_tt;

process_ok('[% "[%" %]' => '[%') if ! $is_tt;
process_ok('[% "%]" %]' => '%]') if ! $is_tt;
process_ok('[% a = "[%  %]" %][% a %]' => '[%  %]') if ! $is_tt;
process_ok('[% qw([%  1  +  2  %]).join %]' => '[% 1 + 2 %]') if ! $is_tt;

###----------------------------------------------------------------###
print "### STRICT ########################################## $engine_option\n";
process_ok("[% TRY; foo; CATCH; error; END %]" => qr'var.undef error - undefined variable: foo.*', {tt_config => [STRICT => 1]});
process_ok("[% TRY; foo.bar(1); CATCH; error; END %]" => qr'var.undef error - undefined variable: foo\.bar\(1\).*', {tt_config => [STRICT => 1]});
process_ok("[% TRY; 1 IF foo.bar.baz; CATCH; error; END %]" => qr'var.undef error - undefined variable: foo\.bar\.baz.*', {tt_config => [STRICT => 1]});
if (! $is_tt) {
process_ok("[% foo.bar() %]ok" => 'ok', {tt_config => [STRICT => 1, STRICT_THROW => sub { my ($t, $y, $m, $args) = @_; return if $args->{'name'} eq 'foo.bar()'; $t->throw($y,$m)}]});
process_ok("[% foo.baz() %]ok" => '',   {tt_config => [STRICT => 1, STRICT_THROW => sub { my ($t, $y, $m, $args) = @_; return if $args->{'name'} eq 'foo.bar()'; $t->throw($y,$m)}]});
}

###----------------------------------------------------------------###
print "### EVALUATE ######################################## $engine_option\n";

process_ok('[% foo | eval %]' => 'baz', {foo => '[% bar %]', bar => 'baz'});

process_ok('[% "[% 1 + 2 %]" | eval %]' => '3') if ! $is_tt;
process_ok('[% qw([%  1  +  2  %]).join.eval %]' => '3') if ! $is_tt;

process_ok('[% f = ">[% TRY; f.eval ; CATCH; \'caught\' ; END %]"; f.eval %]' => '>>>>>caught', {tt_config => [MAX_EVAL_RECURSE => 5]}) if ! $is_tt;
process_ok('[% f = ">[% TRY; f.eval ; CATCH; \'caught\' ; END %]"; f.eval; f.eval %]' => '>>>>>caught>>>>>caught', {tt_config => [MAX_EVAL_RECURSE => 5]}) if ! $is_tt;
process_ok('[% f = ">[% TRY; f.eval ; CATCH; \'foo\' ; END %]"; f.eval;f.eval %]' => '>>foo>>foo', {tt_config => [MAX_EVAL_RECURSE => 2]}) if ! $is_tt;
process_ok("[% '#set(\$foo = 12)'|eval(syntax => 'velocity') %]|[% foo %]" => '|12') if ! $is_tt;

process_ok('[% f = ">[% TRY; f.eval ; CATCH; \'caught\' ; END %]"; EVALUATE f %]' => '>>>>>caught', {tt_config => [MAX_EVAL_RECURSE => 5]}) if ! $is_tt;
process_ok('[% f = ">[% TRY; f.eval ; CATCH; \'foo\' ; END %]"; EVALUATE f; EVALUATE f %]' => '>>foo>>foo', {tt_config => [MAX_EVAL_RECURSE => 2]}) if ! $is_tt;
process_ok("[% EVALUATE '#set(\$foo = 12)' syntax => 'velocity' %]|[% foo %]" => '|12') if ! $is_tt;
if (!$is_tt) {
process_ok("[% TRY; '[% bar %]'.eval(STRICT => 1); CATCH; error; END %]" => 'var.undef error - undefined variable: bar in input text');
process_ok("[% TRY; CONFIG STRICT => 1; '[% bar %]'.eval(STRICT => 0); CATCH; error; END %]" => 'eval_strict error - Cannot disable STRICT once it is enabled');
process_ok("[% TRY; '[% bar %]'.eval(STRICT => 1); CATCH; error.type; END; bing %] - ok" => 'var.undef - ok'); # restricted to sub components
}

###----------------------------------------------------------------###
print "### DUMP ############################################ $engine_option\n";

if (! $is_tt) {
local $ENV{'REQUEST_METHOD'} = 0;
process_ok("[% DUMP a %]" => "DUMP: File \"input text\" line 1\n    a = undef;\n");
process_ok("[% p = DUMP a; p.collapse %]" => 'DUMP: File "input text" line 1 a = undef;');
process_ok("[% p = DUMP a; p.collapse %]" => 'DUMP: File "input text" line 1 a = \'s\';', {a => "s"});
process_ok("[%\n p = DUMP a; p.collapse %]" => 'DUMP: File "input text" line 2 a = \'s\';', {a => "s"});
process_ok("[% p = DUMP a, b; p.collapse %]" => 'DUMP: File "input text" line 1 a, b = [ \'s\', undef ];', {a => "s"});
process_ok("[% p = DUMP a Useqq => 'b'; p.collapse %]" => 'DUMP: File "input text" line 1 a Useqq => \'b\' = [ \'s\', { \'Useqq\' => \'b\' } ];', {a => "s"});
process_ok("[% p = DUMP a; p.collapse %]" => 'DUMP: File "input text" line 1 a = "s";', {a => "s", tt_config => [DUMP => {Useqq => 1}]});
process_ok("[% p = DUMP a; p.collapse %]|foo" => '|foo', {a => "s", tt_config => [DUMP => 0]});
process_ok("[% p = DUMP _a, b; p.collapse %]" => 'DUMP: File "input text" line 1 _a, b = [ undef, \'c\' ];', {_a => "s", b=> "c"});
process_ok("[% p = DUMP {a => 'b'}; p.collapse %]" => 'DUMP: File "input text" line 1 {a => \'b\'} = { \'a\' => \'b\' };');
process_ok("[% p = DUMP _a; p.collapse %]" => 'DUMP: File "input text" line 1 _a = undef;', {_a => "s"});
process_ok("[% p = DUMP a; p.collapse %]" => 'DUMP: File "input text" line 1 a = { \'b\' => \'c\' };', {a => {b => 'c'}});
process_ok("[% p = DUMP a; p.collapse %]" => 'DUMP: File "input text" line 1 a = {};', {a => {_b => 'c'}});
process_ok("[% p = DUMP a; p.collapse %]" => 'DUMP: File "input text" line 1 a = {};', {a => {_b => 'c'}, tt_config => [DUMP => {Sortkeys => 1}]});
process_ok("[% p = DUMP a; p.collapse %]" => 'DUMP: File "input text" line 1 Dump(7)', {a => 7, tt_config => [DUMP => {handler=>sub {"Dump(@_)"}}]});
process_ok("[% p = DUMP a; p.collapse %]" => 'a = \'s\';', {a => "s", tt_config => [DUMP => {header => 0}]});
process_ok("[% p = DUMP a; p.collapse %]" => '<pre>a = &apos;s&apos;; </pre>', {a => "s", tt_config => [DUMP => {header => 0, html => 1}]});
local $ENV{'REQUEST_METHOD'} = 1;
process_ok("[% p = DUMP a; p.collapse %]" => '<pre>a = &apos;s&apos;; </pre>', {a => "s", tt_config => [DUMP => {header => 0}]});
process_ok("[% p = DUMP a; p.collapse %]" => 'a = \'s\';', {a => "s", tt_config => [DUMP => {header => 0, html => 0}]});
local $ENV{'REQUEST_METHOD'} = 0;
process_ok("[% SET global; p = DUMP; p.collapse %]" => "DUMP: File \"input text\" line 1 EntireStash = { 'a' => 'b', 'global' => undef };", {a => 'b', tt_config => [DUMP => {Sortkeys => 1}]});
process_ok("[% SET global; p = DUMP; p.collapse %]" => "DUMP: File \"input text\" line 1 EntireStash = { 'a' => 'b', 'global' => undef };", {a => 'b', tt_config => [DUMP => {Sortkeys => 1, EntireStash => 1}]});
process_ok("[% SET global; p = DUMP; p.collapse %]" => "DUMP: File \"input text\" line 1", {a => 'b', tt_config => [DUMP => {Sortkeys => 1, EntireStash => 0}]});
}

###----------------------------------------------------------------###
print "### SYNTAX ########################################## $engine_option\n";

if (! $is_tt) {
process_ok("[%- BLOCK a %]b is [% b %][% END %][% PROCESS a b => 237 | repeat(2) %]" => "", {tt_config => [SYNTAX => 'garbage']});
process_ok("[%- BLOCK a %]b is [% b %][% END %][% PROCESS a b => 237 | repeat(2) %]" => "b is 237237");
process_ok("[%- BLOCK a %]b is [% b %][% END %][% PROCESS a b => 237 | repeat(2) %]" => "b is 237237", {tt_config => [SYNTAX => 'alloy']});
process_ok("[%- BLOCK a %]b is [% b %][% END %][% PROCESS a b => 237 | repeat(2) %]" => "b is 237237", {tt_config => [SYNTAX => 'tt3']});
process_ok("[%- BLOCK a %]b is [% b %][% END %][% PROCESS a b => 237 | repeat(2) %]" => "b is 237b is 237", {tt_config => [SYNTAX => 'tt2']});
process_ok("[%- BLOCK a %]b is [% b %][% END %][% PROCESS a b => 237 | repeat(2) %]" => "b is 237b is 237", {tt_config => [SYNTAX => 'tt1']});
process_ok("[%- BLOCK a %]b is [% b %][% END %][% PROCESS a b => 237 | repeat(2) %]" => "b is 237b is 237", {tt_config => [SYNTAX => 'tt1']});


process_ok('[% a %]|[% $a %]|[% ${ a } %]|[% ${ "a" } %]' => 'A|bar|bar|A', {a => 'A', A => 'bar'});
process_ok('[% a %]|[% $a %]|[% ${ a } %]|[% ${ "a" } %]' => 'A|bar|bar|A', {a => 'A', A => 'bar', tt_config => [SYNTAX => 'tt2']});
process_ok('[% a %]|[% $a %]|[% ${ a } %]|[% ${ "a" } %]' => 'A|A|bar|A', {a => 'A', A => 'bar', tt_config => [SYNTAX => 'tt1']});

process_ok("<TMPL_VAR name=foo>" => "FOO", {foo => "FOO", tt_config => [SYNTAX => 'ht']});
process_ok("<TMPL_VAR EXPR='sprintf(\"%d %d\", 7, 8)'>" => "7 8", {tt_config => [SYNTAX => 'hte']});
process_ok("<TMPL_VAR EXPR='7 == \"7.0\"'>" => "1", {tt_config => [SYNTAX => 'hte']});
process_ok("<TMPL_VAR EXPR='\"a\" == \"b\"'>" => "1", {tt_config => [SYNTAX => 'hte']});
process_ok("<TMPL_VAR EXPR='sprintf(\"%d %d\", 7, 8)'>d" => "", {tt_config => [SYNTAX => 'ht']});

process_ok("[% \"<TMPL_VAR EXPR='1+2+3'>\"|eval(syntax => 'hte') %] = [% 6 %]" => "6 = 6");
process_ok("[% \"<TMPL_VAR EXPR='1+2+3'>\"|eval(syntax => 'ht') %] = [% 6 %]" => "");
process_ok("[% \"<TMPL_VAR NAME='foo'>\"|eval(syntax => 'ht') %] = [% 12 %]" => "12 = 12", {foo => 12});

}

###----------------------------------------------------------------###
print "### CONFIG ########################################## $engine_option\n";

if (! $is_tt) {
process_ok("[% CONFIG ANYCASE     => 1   %][% get 234 %]" => 234);
process_ok("[% CONFIG anycase     => 1   %][% get 234 %]" => 234);
process_ok("[% CONFIG PRE_CHOMP   => '-' %]\n[% 234 %]" => 234);
process_ok("[% CONFIG POST_CHOMP  => '-' %][% 234 %]\n" => 234);
process_ok("[% CONFIG INTERPOLATE => 1 %]\${ 234 }"   => 234);
process_ok("[% CONFIG V1DOLLAR    => 1   %][% a = 234 %][% \$a %]"   => 234);
process_ok("[% CONFIG V2PIPE => 1 %][% BLOCK a %]b is [% b %][% END %][% PROCESS a b => 234 | repeat(2) %]"   => "b is 234b is 234");
process_ok("[% CONFIG V2EQUALS => 1 %][% ('7' == '7.0') || 0 %]" => 0);
process_ok("[% CONFIG V2EQUALS => 0 %][% ('7' == '7.0') || 0 %]" => 1);

process_ok("[% CONFIG BOGUS => 2 %]bar" => '');

process_ok("[% CONFIG ANYCASE %]|[% CONFIG ANYCASE => 1 %][% CONFIG ANYCASE %]" => 'CONFIG ANYCASE = undef|CONFIG ANYCASE = 1');
process_ok("[% CONFIG ANYCASE %]|[% CONFIG ANYCASE => 1 %][% CONFIG ANYCASE %]" => 'CONFIG ANYCASE = undef|CONFIG ANYCASE = 1');

process_ok("[% \"[% GET 1+2+3 %]\" | eval %] = [% get 6 %]"                          => "",      {tt_config => [SEMICOLONS => 1]}) if ! $is_tt;
process_ok("[% CONFIG ANYCASE => 1 %][% get 6 %]"                                    => "6",     {tt_config => [SEMICOLONS => 1]}) if ! $is_tt;
process_ok("[% CONFIG ANYCASE => 1 %][% \"[% get 1+2+3 %]\" | eval %] = [% get 6 %]" => "6 = 6", {tt_config => [SEMICOLONS => 1]}) if ! $is_tt;
process_ok("[% \"[% CONFIG ANYCASE => 1 %][% get 1+2+3 %]\" | eval %] = [% get 6 %]" => "",      {tt_config => [SEMICOLONS => 1]}) if ! $is_tt;
process_ok("[% \"[% CONFIG ANYCASE => 1 %][% get 1+2+3 %]\" | eval %] = [% GET 6 %]" => "6 = 6", {tt_config => [SEMICOLONS => 1]}) if ! $is_tt;
process_ok("[% CONFIG SYNTAX => 'hte' %][% \"<TMPL_VAR EXPR='1+2+3'>\"|eval %] = [% 6 %]" => "6 = 6");
process_ok("[% \"[% get 1+2+3 %]\" | eval(ANYCASE => 1) %] = [% GET 6 %]" => "6 = 6",            {tt_config => [SEMICOLONS => 1]}) if ! $is_tt;

process_ok("[% CONFIG DUMP    %]|[% CONFIG DUMP    => 0 %][% DUMP           %]bar" => 'CONFIG DUMP = undef|bar');
process_ok("[% CONFIG DUMP => {Useqq=>1, header=>0, html=>0} %][% DUMP 'foo' %]" => "'foo' = \"foo\";\n");
process_ok("[% CONFIG VMETHOD_FUNCTIONS => 0 %][% sprintf('%d %d', 7, 8) %] d" => ' d');
process_ok("[% TRY; foo; CONFIG STRICT => 1; bar; CATCH; error; END %]" => 'var.undef error - undefined variable: bar in input text');
process_ok("[% TRY; foo; CONFIG STRICT => 1; CONFIG STRICT => 0; bar; CATCH; error; END %]" => 'config.strict error - Cannot disable STRICT once it is enabled');
process_ok("[% BLOCK foo; CONFIG STRICT => 1; baz; END; TRY; bam; PROCESS foo; bar; CATCH; error.type; END; bing %] - ok" => 'var.undef - ok'); # restricted to sub components

process_ok('[% CONFIG AUTO_FILTER => "html"; foo %]', => '&amp;', {foo => '&'}) if ! $is_tt;
}

###----------------------------------------------------------------###
print "### DONE ############################################ $engine_option\n";
} # end of for
