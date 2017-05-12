#!/usr/bin/perl -w

=head1 NAME

bench_various_templaters.pl - test the relative performance of several different types of template engines.

=cut

use strict;
use Benchmark qw(timethese cmpthese);

use Template;
use Template::Stash;
use Template::Stash::XS;
use Template::Parser::CET;
use Text::Template;
use Text::Tmpl;
use HTML::Template;
use HTML::Template::Compiled;
use HTML::Template::Expr;
use HTML::Template::JIT;
use Template::Alloy;
use Template::Alloy::XS;
use POSIX qw(tmpnam);
use File::Path qw(mkpath rmtree);

###----------------------------------------------------------------###

my $names = {
  TA           => 'Template::Alloy using TT interface',
  TA_NOCACHE   => 'Template::Alloy with string ref caching off using process_simple',
  TA_H_NOCACHE => 'Template::Alloy with string ref caching off using HTML::Template interface',
  TA_P         => 'Template::Alloy - Perl code eval based',
  TA_S         => 'Template::Alloy::XS using TT interface using process_simple',
  TA_X         => 'Template::Alloy::XS using TT interface',
  TA_PS        => 'Template::Alloy - Perl code eval based using process_simple',
  TA_XS        => 'Template::Alloy::XS - using process_simple',
  TA_XP        => 'Template::Alloy::XS - Perl code eval based',
  TA_XPS       => 'Template::Alloy::XS - Perl code eval based using process_simple',
  TA_H         => 'Template::Alloy using HTML::Template interface',
  TA_H_X       => 'Template::Alloy::XS using HTML::Template interface',
  TA_H_XP      => 'Template::Alloy::XS using HTML::Template interface - Perl code eval based',
  TA_XTMPL     => 'CGI::Ex::Temmplate::XS using Text::Tmpl interface',
  HT           => 'HTML::Template',
  HTE          => 'HTML::Template::Expr',
  HTJ          => 'HTML::Template::JIT - Compiled to C template',
  HTC          => 'HTML::Template::Compiled',
  TextTemplate => 'Text::Template - Perl code eval based',
  TT           => 'Template::Toolkit',
  TTX          => 'Template::Toolkit with Stash::XS',
  TTXCET       => 'Template::Toolkit with Stash::XS and Template::Parser::CET',
  TMPL         => 'Text::Tmpl - Engine is C based',
  RAW          => 'Raw perl - no template engine',

  mem          => 'Compiled in memory',
  file         => 'Loaded from file',
  str          => 'From string ref - cached if possible',
};

###----------------------------------------------------------------###
### get cache and compile dirs ready

my $dir  = tmpnam;
my $dir2 = "$dir.cache";
mkpath($dir);
mkpath($dir2);
END {rmtree $dir; rmtree $dir2};
my @dirs = ($dir);

###----------------------------------------------------------------###

my $form = {
  foo => 'bar',
  pass_in_something => 'what ever you want',
};

my $filler = ((" foo" x 10)."\n") x 10;

my $stash_t = {
  shell_header => "This is a header",
  shell_footer => "This is a footer",
  shell_start  => "<html>",
  shell_end    => "<end>",
  a_stuff      => [qw(one two three four)],
};

my $stash_ht = {
  shell_header => "This is a header",
  shell_footer => "This is a footer",
  shell_start  => "<html>",
  shell_end    => "<end>",
  a_stuff      => [map {{name => $_}} qw(one two three four)],
};

$FOO::shell_header = $FOO::shell_footer = $FOO::shell_start = $FOO::shell_end = $FOO::a_stuff;
$FOO::shell_header = "This is a header";
$FOO::shell_footer = "This is a footer";
$FOO::shell_start  = "<html>";
$FOO::shell_end    = "<end>";
$FOO::a_stuff      = [qw(one two three four)];


###----------------------------------------------------------------###
### TT style template

my $content_tt = <<"DOC";
[% shell_header %]
[% shell_start %]
$filler

[% IF foo %]
This is some text.
[% END %]

[% FOREACH i IN a_stuff %][% i %][% END %]
[% pass_in_something %]

$filler
[% shell_end %]
[% shell_footer %]
DOC

if (open (my $fh, ">$dir/foo.tt")) {
    print $fh $content_tt;
    close $fh;
}

###----------------------------------------------------------------###
### HTML::Template style

my $content_ht = <<"DOC";
<TMPL_VAR NAME=shell_header>
<TMPL_VAR NAME=shell_start>
$filler

<TMPL_IF NAME=foo>
This is some text.
</TMPL_IF>

<TMPL_LOOP NAME=a_stuff><TMPL_VAR NAME=name></TMPL_LOOP>
<TMPL_VAR NAME=pass_in_something>

$filler
<TMPL_VAR NAME=shell_end>
<TMPL_VAR NAME=shell_footer>
DOC

if (open (my $fh, ">$dir/foo.ht")) {
    print $fh $content_ht;
    close $fh;
}

###----------------------------------------------------------------###
### Text::Template style template

my $content_p = <<"DOC";
{\$shell_header}
{\$shell_start}
$filler

{ if (\$foo) {
    \$OUT .= "
This is some text.
";
  }
}

{  \$OUT .= \$_ foreach \@\$a_stuff; }
{\$pass_in_something}

$filler
{\$shell_end}
{\$shell_footer}
DOC

###----------------------------------------------------------------###
### Tmpl style template

my $content_tmpl = <<"DOC";
<!--echo \$shell_header-->
<!--echo \$shell_start-->
$filler

<!-- if \$foo -->
This is some text.
<!-- endif -->

<!-- loop "a_stuff" --><!-- echo \$name --><!-- endloop -->
<!-- echo \$pass_in_something -->

$filler
<!-- echo \$shell_end -->
<!-- echo \$shell_footer -->
DOC

if (open (my $fh, ">$dir/foo.tmpl")) {
    print $fh $content_tmpl;
    close $fh;
}

###----------------------------------------------------------------###
### Pure perl base case

my $content_raw = sub {
    my $args = shift;

    return "$args->{shell_header}
$args->{shell_start}
$filler

".($args->{foo} ? "
This is some text.
" : "")."

".(do {
    my $t = '';
    $t .= $_ foreach @{ $args->{a_stuff} };
    $t;
})."
$args->{pass_in_something}

$filler
$args->{shell_end}
$args->{shell_footer}
";
};

###----------------------------------------------------------------###
### The TT interface allows for a single object to be cached and reused.

my %Alloy_DOCUMENTS;
my %AlloyX_DOCUMENTS;
my %AlloyXP_DOCUMENTS;

my $tt    = Template->new(           INCLUDE_PATH => \@dirs, STASH => Template::Stash->new($stash_t));
my $ttx   = Template->new(           INCLUDE_PATH => \@dirs, STASH => Template::Stash::XS->new($stash_t));
my $ta    = Template::Alloy->new(    INCLUDE_PATH => \@dirs, VARIABLES => $stash_t);
my $tap   = Template::Alloy->new(    INCLUDE_PATH => \@dirs, VARIABLES => $stash_t, COMPILE_PERL => 1);
my $taps  = Template::Alloy->new(    INCLUDE_PATH => \@dirs, COMPILE_PERL => 1);
my $tax   = Template::Alloy::XS->new(INCLUDE_PATH => \@dirs, VARIABLES => $stash_t);
my $taxs  = Template::Alloy::XS->new(INCLUDE_PATH => \@dirs, VARIABLES => $stash_t);
my $taxp  = Template::Alloy::XS->new(INCLUDE_PATH => \@dirs, VARIABLES => $stash_t, COMPILE_PERL => 1);
my $taxps = Template::Alloy::XS->new(INCLUDE_PATH => \@dirs, COMPILE_PERL => 1);

###----------------------------------------------------------------###


my $tests = {

    ###----------------------------------------------------------------###
    ### str infers that we are pulling from a string reference

    TextTemplate_str => sub {
        my $pt = Text::Template->new(
            TYPE   => 'STRING',
            SOURCE => $content_p,
            HASH   => $form);
        my $out = $pt->fill_in(PACKAGE => 'FOO', HASH => $form);
    },

    TT_str => sub {
        my $t = Template->new(STASH => Template::Stash->new($stash_t));
        my $out = ""; $t->process(\$content_tt, $form, \$out); $out;
    },
    TTX_str => sub {
        my $t = Template->new(STASH => Template::Stash::XS->new($stash_t));
        my $out = ""; $t->process(\$content_tt, $form, \$out); $out;
    },
    TTXCET_str => sub {
        my $t = Template->new(STASH => Template::Stash::XS->new($stash_t), PARSER => Template::Parser::CET->new);
        my $out = ""; $t->process(\$content_tt, $form, \$out); $out;
    },
    TA_str => sub {
        my $t = Template::Alloy->new(VARIABLES => $stash_t);
        $t->{'_documents'} = \%Alloy_DOCUMENTS;
        my $out = ""; $t->process(\$content_tt, $form, \$out); $out;
    },
    TA_NOCACHE_str => sub {
        my $t = Template::Alloy->new(CACHE_STR_REFS => 0);
        my $out = ""; $t->process_simple(\$content_tt, {%$stash_t, %$form}, \$out); $out;
    },
    TA_X_str => sub {
        my $t = Template::Alloy::XS->new(VARIABLES => $stash_t);
        $t->{'_documents'} = \%AlloyX_DOCUMENTS;
        my $out = ""; $t->process(\$content_tt, $form, \$out); $out;
    },
    TA_XP_str => sub {
        my $t = Template::Alloy::XS->new(VARIABLES => $stash_t, COMPILE_PERL => 1);
        $t->{'_documents'} = \%AlloyXP_DOCUMENTS;
        my $out = ""; $t->process(\$content_tt, $form, \$out); $out;
    },
    TA_XPS_str => sub {
        my $t = Template::Alloy::XS->new(COMPILE_PERL => 1);
        $t->{'_documents'} = \%AlloyXP_DOCUMENTS;
        my $out = ""; $t->process_simple(\$content_tt, {%$stash_t, %$form}, \$out); $out;
    },

    TA_H_str => sub {
        my $t = Template::Alloy->new(    type => 'scalarref', source => \$content_ht, case_sensitve=>1, cache => 1);
        $t->{'_documents'} = \%Alloy_DOCUMENTS;
        $t->param($stash_ht); $t->param($form); my $out = $t->output;
    },
    TA_H_NOCACHE_str => sub {
        my $t = Template::Alloy->new(    type => 'scalarref', source => \$content_ht, case_sensitve=>1, CACHE_STR_REFS => 1);
        $t->param($stash_ht); $t->param($form); my $out = $t->output;
    },
    TA_H_X_str => sub {
        my $t = Template::Alloy::XS->new(type => 'scalarref', source => \$content_ht, case_sensitve=>1, cache => 1);
        $t->{'_documents'} = \%AlloyX_DOCUMENTS;
        $t->param($stash_ht); $t->param($form); my $out = $t->output;
    },
    TA_H_XP_str => sub {
        my $t = Template::Alloy::XS->new(type => 'scalarref', source => \$content_ht, case_sensitve=>1, COMPILE_PERL => 1, cache => 1);
        $t->{'_documents'} = \%AlloyXP_DOCUMENTS;
        $t->param($stash_ht); $t->param($form); my $out = $t->output;
    },
    HT_str => sub {
        my $t = HTML::Template->new(       type => 'scalarref', source => \$content_ht, case_sensitve=>1);
        $t->param($stash_ht); $t->param($form); my $out = $t->output;
    },
    HTE_str => sub {
        my $t = HTML::Template::Expr->new( type => 'scalarref', source => \$content_ht, case_sensitve=>1);
        $t->param($stash_ht); $t->param($form); my $out = $t->output;
    },
    HTC_str => sub {
        my $t = HTML::Template::Compiled->new(type => 'scalarref', source => \$content_ht, case_sensitve=>1, cache => 1);
        $t->param($stash_ht); $t->param($form); my $out = $t->output;
    },
    TMPL_str => sub {
        my $t = Text::Tmpl->new;
        for my $ref (@{ $stash_ht->{'a_stuff'} }) {
            $t->loop_iteration('a_stuff')->set_values($ref);
        }
        $t->set_values($stash_ht);
        $t->set_values($form);
        $t->set_delimiters('<!--','-->');
        $t->set_dir("$dir/");
        $t->set_strip(0);
        my $out = $t->parse_string($content_tmpl);
    },

    ###----------------------------------------------------------------###
    ### compile means item was compiled to optree or perlcode and stored on disk
    ### this should try to load the template from disk each time

    TT_file => sub {
        my $tt = Template->new(INCLUDE_PATH => \@dirs, STASH => Template::Stash->new($stash_t), COMPILE_DIR => $dir2);
        my $out = ""; $tt->process('foo.tt', $form, \$out); $out;
    },
    TTX_file => sub {
        my $tt = Template->new(INCLUDE_PATH => \@dirs, STASH => Template::Stash::XS->new($stash_t), COMPILE_DIR => $dir2);
        my $out = ""; $tt->process('foo.tt', $form, \$out); $out;
    },
    TA_file => sub {
        my $t = Template::Alloy->new(INCLUDE_PATH => \@dirs, VARIABLES => $stash_t, COMPILE_DIR  => $dir2);
        my $out = ''; $t->process('foo.tt', $form, \$out); $out;
    },
    TA_P_file => sub {
        my $t = Template::Alloy->new(INCLUDE_PATH => \@dirs, VARIABLES => $stash_t, COMPILE_DIR => $dir2, COMPILE_PERL => 1);
        my $out = ''; $t->process('foo.tt', $form, \$out); $out;
    },
    TA_S_file => sub {
        my $t = Template::Alloy->new(INCLUDE_PATH => \@dirs, COMPILE_DIR => $dir2);
        my $out = ''; $t->process_simple('foo.tt', {%$stash_t, %$form}, \$out); $out;
    },
    TA_X_file => sub {
        my $t = Template::Alloy::XS->new(INCLUDE_PATH => \@dirs, VARIABLES => $stash_t, COMPILE_DIR => $dir2);
        my $out = ''; $t->process('foo.tt', $form, \$out); $out;
    },
    TA_XS_file => sub {
        my $t = Template::Alloy::XS->new(INCLUDE_PATH => \@dirs, COMPILE_DIR => $dir2);
        my $out = ''; $t->process_simple('foo.tt', {%$stash_t, %$form}, \$out); $out;
    },
    TA_XP_file => sub {
        my $t = Template::Alloy::XS->new(INCLUDE_PATH => \@dirs, VARIABLES => $stash_t, COMPILE_DIR => $dir2, COMPILE_PERL => 1);
        my $out = ''; $t->process('foo.tt', $form, \$out); $out;
    },
    TA_XPS_file => sub {
        my $t = Template::Alloy::XS->new(INCLUDE_PATH => \@dirs, COMPILE_DIR => $dir2, COMPILE_PERL => 1);
        my $out = ""; $t->process_simple(\$content_tt, {%$stash_t, %$form}, \$out); $out;
    },

    TA_H_file => sub {
        my $t = Template::Alloy->new(type => 'filename', source => "foo.ht", file_cache => 1, path => \@dirs, file_cache_dir => $dir2, case_sensitve=>1);
        $t->param($stash_ht); $t->param($form); my $out = $t->output;
    },
    TA_H_X_file => sub {
        my $t = Template::Alloy::XS->new(type => 'filename', source => "foo.ht", file_cache => 1, path => \@dirs, file_cache_dir => $dir2, case_sensitve=>1);
        $t->param($stash_ht); $t->param($form); my $out = $t->output;
    },
    TA_H_XP_file => sub {
        my $t = Template::Alloy::XS->new(type => 'filename', source => "foo.ht", file_cache => 1, path => \@dirs, file_cache_dir => $dir2,
                                         case_sensitve=>1, compile_perl => 1);
        $t->param($stash_ht); $t->param($form); my $out = $t->output;
    },
    HT_file => sub {
        my $t = HTML::Template->new(type => 'filename', source => "foo.ht", file_cache => 1, path => \@dirs, file_cache_dir => $dir2, case_sensitve=>1);
        $t->param($stash_ht); $t->param($form); my $out = $t->output;
    },
    HTC_file => sub {
        my $t = HTML::Template::Compiled->new(type => 'filename', source => "foo.ht", file_cache => 1, path => \@dirs, file_cache_dir => $dir2, case_sensitve=>1, cache => 0);
        $t->param($stash_ht); $t->param($form); my $out = $t->output;
#        $t->clear_cache; # caches in memory by default - can't disable it
#        return $out;
    },
    TMPL_file => sub {
        my $t = Text::Tmpl->new;
        for my $ref (@{ $stash_ht->{'a_stuff'} }) {
            $t->loop_iteration('a_stuff')->set_values($ref);
        }
        $t->set_values($stash_ht);
        $t->set_values($form);
        $t->set_delimiters('<!--','-->');
        $t->set_dir("$dir/");
        $t->set_strip(0);
        my $out = $t->parse_file("foo.tmpl");
    },
    TA_XTMPL_file => sub {
        my $t = Template::Alloy::XS->new;
        for my $ref (@{ $stash_ht->{'a_stuff'} }) {
            $t->loop_iteration('a_stuff')->set_values($ref);
        }
        $t->set_values($stash_ht);
        $t->set_values($form);
        $t->set_delimiters('<!--','-->');
        $t->set_dir("$dir/");
        $t->set_strip(0);
        my $out = $t->parse_file("foo.tmpl");
    },


    ###----------------------------------------------------------------###
    ### mem indicates that the compiled form is stored in memory

    TT_mem     => sub { my $out = ""; $tt->process(  'foo.tt', $form, \$out); $out },
    TTX_mem    => sub { my $out = ""; $ttx->process( 'foo.tt', $form, \$out); $out },
    TA_mem     => sub { my $out = ""; $ta->process(  'foo.tt', $form, \$out); $out },
    TA_PS_mem  => sub { my $out = ""; $taps->process_simple( 'foo.tt', {%$stash_t, %$form}, \$out); $out },
    TA_X_mem   => sub { my $out = ""; $tax->process( 'foo.tt', $form, \$out); $out },
    TA_XP_mem  => sub { my $out = ""; $taxp->process('foo.tt', $form, \$out); $out },
    TA_XPS_mem => sub { my $out = ""; $taxps->process_simple('foo.tt', {%$stash_t, %$form}, \$out); $out },
    TA_P_mem   => sub { my $out = ""; $tap->process( 'foo.tt', $form, \$out); $out },

    TA_H_mem => sub {
        my $t = Template::Alloy->new(    filename => "foo.ht", path => \@dirs, cache => 1, case_sensitve=>1);
        $t->{'_documents'} = \%Alloy_DOCUMENTS;
        $t->param($stash_ht); $t->param($form); my $out = $t->output;
    },
    TA_H_X_mem => sub {
        my $t = Template::Alloy::XS->new(filename => "foo.ht", path => \@dirs, cache => 1, case_sensitve=>1);
        $t->{'_documents'} = \%AlloyX_DOCUMENTS;
        $t->param($stash_ht); $t->param($form); my $out = $t->output;
    },
    TA_H_XP_mem => sub {
        my $t = Template::Alloy::XS->new(filename => "foo.ht", path => \@dirs, cache => 1, case_sensitve=>1, compile_perl => 1, cache => 1);
        $t->{'_documents'} = \%AlloyXP_DOCUMENTS;
        $t->param($stash_ht); $t->param($form); my $out = $t->output;
    },
    HT_mem => sub {
        my $t = HTML::Template->new(       filename => "foo.ht", path => \@dirs, cache => 1, case_sensitve=>1);
        $t->param($stash_ht); $t->param($form); my $out = $t->output;
    },
    HTC_mem => sub {
        my $t = HTML::Template::Compiled->new(       filename => "foo.ht", path => \@dirs, cache => 1, case_sensitve=>1);
        $t->param($stash_ht); $t->param($form); my $out = $t->output;
    },
    HTE_mem => sub {
        my $t = HTML::Template::Expr->new( filename => "foo.ht", path => \@dirs, cache => 1, case_sensitve=>1);
        $t->param($stash_ht); $t->param($form); my $out = $t->output;
    },
    HTJ_mem => sub { # this is interesting - it is compiled - but it is pulled into memory just once
        my $t = HTML::Template::JIT->new(  filename => "foo.ht", path => \@dirs, jit_path => $dir2, case_sensitve=>1);
        $t->param($stash_ht); $t->param($form); my $out = $t->output;
    },
    #RAW_mem => sub {
    #    my $out = $content_raw->({%$stash_t, %$form});
    #},
};

my $test = $tests->{'TT_str'}->();
foreach my $name (sort keys %$tests) {
    if ($test ne $tests->{$name}->()) {
        print "--------------------------TT_str-------\n";
        print $test;
        print "--------------------------$name--------\n";
        print $tests->{$name}->();
        die "$name did not match TT_str output\n";
    }
    $name =~ /(\w+)_(\w+)/;
    print "$name - $names->{$1} - ($names->{$2})\n";
}

###----------------------------------------------------------------###
### and now - the tests - grouped by common capability

my %mem_tests = map {my $k=$_; $k=~s/_mem$//;  $k => $tests->{$_}} grep {/_mem$/} keys %$tests;
my %cpl_tests = map {my $k=$_; $k=~s/_file$//; $k => $tests->{$_}} grep {/_file$/} keys %$tests;
my %str_tests = map {my $k=$_; $k=~s/_str$//;  $k => $tests->{$_}} grep {/_str$/} keys %$tests;

print "---Match Run Through----------------------------------------------------\n";
my $match; # run through once to make sure they are working
foreach my $key (sort keys %$tests) {
    my $out = $tests->{$key}->();
    if ($match) { die "$key didn't match" if $out ne $match } else { $match = $out }
}
print "  All test output matched!\n";

print "---STR------------------------------------------------------------------\n";
print "From a string or scalarref tests\n";
cmpthese timethese (-2, \%str_tests);

print "---FILE-----------------------------------------------------------------\n";
print "Compiled and cached on the file system tests\n";
cmpthese timethese (-2, \%cpl_tests);

print "---MEM------------------------------------------------------------------\n";
print "Cached in memory tests\n";
cmpthese timethese (-2, \%mem_tests);

#print "------------------------------------------------------------------------\n";
#print "All variants together\n";
#cmpthese timethese (-2, $tests);

###----------------------------------------------------------------###

__END__

=head1 VERSIONS

    Template::Alloy          1.009
    Template                 2.19
    Template::Parser::CET    0.05
    Text::Tmpl               0.30
    Text::Template           1.44
    HTML::Template           2.9
    HTML::Template::Expr     0.07
    HTML::Template::JIT      0.05
    HTML::Template::Compiled 0.89

=head1 SAMPLE OUTPUT

    HTC_file - HTML::Template::Compiled - (Loaded from file)
    HTC_mem - HTML::Template::Compiled - (Compiled in memory)
    HTC_str - HTML::Template::Compiled - (From string ref - cached if possible)
    HTE_mem - HTML::Template::Expr - (Compiled in memory)
    HTE_str - HTML::Template::Expr - (From string ref - cached if possible)
    HTJ_mem - HTML::Template::JIT - Compiled to C template - (Compiled in memory)
    HT_file - HTML::Template - (Loaded from file)
    HT_mem - HTML::Template - (Compiled in memory)
    HT_str - HTML::Template - (From string ref - cached if possible)
    TA_H_NOCACHE_str - Template::Alloy with string ref caching off using HTML::Template interface - (From string ref - cached if possible)
    TA_H_XP_file - Template::Alloy::XS using HTML::Template interface - Perl code eval based - (Loaded from file)
    TA_H_XP_mem - Template::Alloy::XS using HTML::Template interface - Perl code eval based - (Compiled in memory)
    TA_H_XP_str - Template::Alloy::XS using HTML::Template interface - Perl code eval based - (From string ref - cached if possible)
    TA_H_X_file - Template::Alloy::XS using HTML::Template interface - (Loaded from file)
    TA_H_X_mem - Template::Alloy::XS using HTML::Template interface - (Compiled in memory)
    TA_H_X_str - Template::Alloy::XS using HTML::Template interface - (From string ref - cached if possible)
    TA_H_file - Template::Alloy using HTML::Template interface - (Loaded from file)
    TA_H_mem - Template::Alloy using HTML::Template interface - (Compiled in memory)
    TA_H_str - Template::Alloy using HTML::Template interface - (From string ref - cached if possible)
    TA_NOCACHE_str - Template::Alloy with string ref caching off using process_simple - (From string ref - cached if possible)
    TA_PS_mem - Template::Alloy - Perl code eval based using process_simple - (Compiled in memory)
    TA_P_file - Template::Alloy - Perl code eval based - (Loaded from file)
    TA_P_mem - Template::Alloy - Perl code eval based - (Compiled in memory)
    TA_S_file - Template::Alloy::XS using TT interface using process_simple - (Loaded from file)
    TA_XPS_file - Template::Alloy::XS - Perl code eval based using process_simple - (Loaded from file)
    TA_XPS_mem - Template::Alloy::XS - Perl code eval based using process_simple - (Compiled in memory)
    TA_XPS_str - Template::Alloy::XS - Perl code eval based using process_simple - (From string ref - cached if possible)
    TA_XP_file - Template::Alloy::XS - Perl code eval based - (Loaded from file)
    TA_XP_mem - Template::Alloy::XS - Perl code eval based - (Compiled in memory)
    TA_XP_str - Template::Alloy::XS - Perl code eval based - (From string ref - cached if possible)
    TA_XS_file - Template::Alloy::XS - using process_simple - (Loaded from file)
    TA_XTMPL_file - CGI::Ex::Temmplate::XS using Text::Tmpl interface - (Loaded from file)
    TA_X_file - Template::Alloy::XS using TT interface - (Loaded from file)
    TA_X_mem - Template::Alloy::XS using TT interface - (Compiled in memory)
    TA_X_str - Template::Alloy::XS using TT interface - (From string ref - cached if possible)
    TA_file - Template::Alloy using TT interface - (Loaded from file)
    TA_mem - Template::Alloy using TT interface - (Compiled in memory)
    TA_str - Template::Alloy using TT interface - (From string ref - cached if possible)
    TMPL_file - Text::Tmpl - Engine is C based - (Loaded from file)
    TMPL_str - Text::Tmpl - Engine is C based - (From string ref - cached if possible)
    TTXCET_str - Template::Toolkit with Stash::XS and Template::Parser::CET - (From string ref - cached if possible)
    TTX_file - Template::Toolkit with Stash::XS - (Loaded from file)
    TTX_mem - Template::Toolkit with Stash::XS - (Compiled in memory)
    TTX_str - Template::Toolkit with Stash::XS - (From string ref - cached if possible)
    TT_file - Template::Toolkit - (Loaded from file)
    TT_mem - Template::Toolkit - (Compiled in memory)
    TT_str - Template::Toolkit - (From string ref - cached if possible)
    TextTemplate_str - Text::Template - Perl code eval based - (From string ref - cached if possible)
    ---Match Run Through----------------------------------------------------
      All test output matched!
    ---STR------------------------------------------------------------------
    From a string or scalarref tests
    Benchmark: running HT, HTC, HTE, TA, TA_H, TA_H_NOCACHE, TA_H_X, TA_H_XP, TA_NOCACHE, TA_X, TA_XP, TA_XPS, TMPL, TT, TTX, TTXCET, TextTemplate for at least 2 CPU seconds...
            HT:  2 wallclock secs ( 2.08 usr +  0.00 sys =  2.08 CPU) @ 1230.29/s (n=2559)
           HTC:  2 wallclock secs ( 2.09 usr +  0.00 sys =  2.09 CPU) @ 210.53/s (n=440)
           HTE:  3 wallclock secs ( 2.17 usr +  0.00 sys =  2.17 CPU) @ 884.79/s (n=1920)
            TA:  3 wallclock secs ( 2.12 usr +  0.00 sys =  2.12 CPU) @ 3617.92/s (n=7670)
          TA_H:  3 wallclock secs ( 2.17 usr +  0.01 sys =  2.18 CPU) @ 3793.58/s (n=8270)
    TA_H_NOCACHE:  2 wallclock secs ( 2.02 usr +  0.01 sys =  2.03 CPU) @ 1400.99/s (n=2844)
        TA_H_X:  2 wallclock secs ( 2.15 usr +  0.00 sys =  2.15 CPU) @ 5321.40/s (n=11441)
       TA_H_XP:  2 wallclock secs ( 2.19 usr +  0.00 sys =  2.19 CPU) @ 5293.15/s (n=11592)
    TA_NOCACHE:  2 wallclock secs ( 2.00 usr +  0.01 sys =  2.01 CPU) @ 1292.04/s (n=2597)
          TA_X:  2 wallclock secs ( 2.06 usr +  0.01 sys =  2.07 CPU) @ 5607.73/s (n=11608)
         TA_XP:  2 wallclock secs ( 2.16 usr +  0.00 sys =  2.16 CPU) @ 7106.48/s (n=15350)
        TA_XPS:  2 wallclock secs ( 2.12 usr +  0.00 sys =  2.12 CPU) @ 8063.68/s (n=17095)
          TMPL:  2 wallclock secs ( 2.02 usr +  0.02 sys =  2.04 CPU) @ 8107.35/s (n=16539)
            TT:  2 wallclock secs ( 2.14 usr +  0.01 sys =  2.15 CPU) @ 312.09/s (n=671)
           TTX:  2 wallclock secs ( 2.16 usr +  0.01 sys =  2.17 CPU) @ 326.27/s (n=708)
        TTXCET:  2 wallclock secs ( 2.16 usr +  0.01 sys =  2.17 CPU) @ 516.13/s (n=1120)
    TextTemplate:  2 wallclock secs ( 1.99 usr +  0.01 sys =  2.00 CPU) @ 1197.50/s (n=2395)
                   Rate   HTC    TT   TTX TTXCET  HTE TextTemplate   HT TA_NOCACHE TA_H_NOCACHE   TA TA_H TA_H_XP TA_H_X TA_X TA_XP TA_XPS TMPL
    HTC           211/s    --  -33%  -35%   -59% -76%         -82% -83%       -84%         -85% -94% -94%    -96%   -96% -96%  -97%   -97% -97%
    TT            312/s   48%    --   -4%   -40% -65%         -74% -75%       -76%         -78% -91% -92%    -94%   -94% -94%  -96%   -96% -96%
    TTX           326/s   55%    5%    --   -37% -63%         -73% -73%       -75%         -77% -91% -91%    -94%   -94% -94%  -95%   -96% -96%
    TTXCET        516/s  145%   65%   58%     -- -42%         -57% -58%       -60%         -63% -86% -86%    -90%   -90% -91%  -93%   -94% -94%
    HTE           885/s  320%  184%  171%    71%   --         -26% -28%       -32%         -37% -76% -77%    -83%   -83% -84%  -88%   -89% -89%
    TextTemplate 1197/s  469%  284%  267%   132%  35%           --  -3%        -7%         -15% -67% -68%    -77%   -77% -79%  -83%   -85% -85%
    HT           1230/s  484%  294%  277%   138%  39%           3%   --        -5%         -12% -66% -68%    -77%   -77% -78%  -83%   -85% -85%
    TA_NOCACHE   1292/s  514%  314%  296%   150%  46%           8%   5%         --          -8% -64% -66%    -76%   -76% -77%  -82%   -84% -84%
    TA_H_NOCACHE 1401/s  565%  349%  329%   171%  58%          17%  14%         8%           -- -61% -63%    -74%   -74% -75%  -80%   -83% -83%
    TA           3618/s 1619% 1059% 1009%   601% 309%         202% 194%       180%         158%   --  -5%    -32%   -32% -35%  -49%   -55% -55%
    TA_H         3794/s 1702% 1116% 1063%   635% 329%         217% 208%       194%         171%   5%   --    -28%   -29% -32%  -47%   -53% -53%
    TA_H_XP      5293/s 2414% 1596% 1522%   926% 498%         342% 330%       310%         278%  46%  40%      --    -1%  -6%  -26%   -34% -35%
    TA_H_X       5321/s 2428% 1605% 1531%   931% 501%         344% 333%       312%         280%  47%  40%      1%     --  -5%  -25%   -34% -34%
    TA_X         5608/s 2564% 1697% 1619%   986% 534%         368% 356%       334%         300%  55%  48%      6%     5%   --  -21%   -30% -31%
    TA_XP        7106/s 3276% 2177% 2078%  1277% 703%         493% 478%       450%         407%  96%  87%     34%    34%  27%    --   -12% -12%
    TA_XPS       8064/s 3730% 2484% 2371%  1462% 811%         573% 555%       524%         476% 123% 113%     52%    52%  44%   13%     --  -1%
    TMPL         8107/s 3751% 2498% 2385%  1471% 816%         577% 559%       527%         479% 124% 114%     53%    52%  45%   14%     1%   --
    ---FILE-----------------------------------------------------------------
    Compiled and cached on the file system tests
    Benchmark: running HT, HTC, TA, TA_H, TA_H_X, TA_H_XP, TA_P, TA_S, TA_X, TA_XP, TA_XPS, TA_XS, TA_XTMPL, TMPL, TT, TTX for at least 2 CPU seconds...
            HT:  3 wallclock secs ( 2.10 usr +  0.05 sys =  2.15 CPU) @ 1902.33/s (n=4090)
           HTC:  2 wallclock secs ( 2.18 usr +  0.02 sys =  2.20 CPU) @ 867.73/s (n=1909)
            TA:  2 wallclock secs ( 2.10 usr +  0.08 sys =  2.18 CPU) @ 2462.84/s (n=5369)
          TA_H:  3 wallclock secs ( 2.03 usr +  0.06 sys =  2.09 CPU) @ 2345.93/s (n=4903)
        TA_H_X:  3 wallclock secs ( 2.09 usr +  0.06 sys =  2.15 CPU) @ 2937.67/s (n=6316)
       TA_H_XP:  2 wallclock secs ( 2.03 usr +  0.05 sys =  2.08 CPU) @ 1229.81/s (n=2558)
          TA_P:  2 wallclock secs ( 2.15 usr +  0.04 sys =  2.19 CPU) @ 1302.74/s (n=2853)
          TA_S:  2 wallclock secs ( 1.92 usr +  0.10 sys =  2.02 CPU) @ 2575.74/s (n=5203)
          TA_X:  2 wallclock secs ( 2.04 usr +  0.11 sys =  2.15 CPU) @ 3330.23/s (n=7160)
         TA_XP:  2 wallclock secs ( 2.04 usr +  0.06 sys =  2.10 CPU) @ 1522.38/s (n=3197)
        TA_XPS:  2 wallclock secs ( 2.05 usr +  0.05 sys =  2.10 CPU) @ 1556.19/s (n=3268)
         TA_XS:  2 wallclock secs ( 2.06 usr +  0.11 sys =  2.17 CPU) @ 3534.10/s (n=7669)
      TA_XTMPL:  2 wallclock secs ( 2.11 usr +  0.02 sys =  2.13 CPU) @ 1201.41/s (n=2559)
          TMPL:  2 wallclock secs ( 1.90 usr +  0.20 sys =  2.10 CPU) @ 6977.14/s (n=14652)
            TT:  2 wallclock secs ( 2.09 usr +  0.03 sys =  2.12 CPU) @ 756.13/s (n=1603)
           TTX:  2 wallclock secs ( 2.14 usr +  0.03 sys =  2.17 CPU) @ 824.88/s (n=1790)
               Rate   TT  TTX  HTC TA_XTMPL TA_H_XP TA_P TA_XP TA_XPS   HT TA_H   TA TA_S TA_H_X TA_X TA_XS TMPL
    TT        756/s   --  -8% -13%     -37%    -39% -42%  -50%   -51% -60% -68% -69% -71%   -74% -77%  -79% -89%
    TTX       825/s   9%   --  -5%     -31%    -33% -37%  -46%   -47% -57% -65% -67% -68%   -72% -75%  -77% -88%
    HTC       868/s  15%   5%   --     -28%    -29% -33%  -43%   -44% -54% -63% -65% -66%   -70% -74%  -75% -88%
    TA_XTMPL 1201/s  59%  46%  38%       --     -2%  -8%  -21%   -23% -37% -49% -51% -53%   -59% -64%  -66% -83%
    TA_H_XP  1230/s  63%  49%  42%       2%      --  -6%  -19%   -21% -35% -48% -50% -52%   -58% -63%  -65% -82%
    TA_P     1303/s  72%  58%  50%       8%      6%   --  -14%   -16% -32% -44% -47% -49%   -56% -61%  -63% -81%
    TA_XP    1522/s 101%  85%  75%      27%     24%  17%    --    -2% -20% -35% -38% -41%   -48% -54%  -57% -78%
    TA_XPS   1556/s 106%  89%  79%      30%     27%  19%    2%     -- -18% -34% -37% -40%   -47% -53%  -56% -78%
    HT       1902/s 152% 131% 119%      58%     55%  46%   25%    22%   -- -19% -23% -26%   -35% -43%  -46% -73%
    TA_H     2346/s 210% 184% 170%      95%     91%  80%   54%    51%  23%   --  -5%  -9%   -20% -30%  -34% -66%
    TA       2463/s 226% 199% 184%     105%    100%  89%   62%    58%  29%   5%   --  -4%   -16% -26%  -30% -65%
    TA_S     2576/s 241% 212% 197%     114%    109%  98%   69%    66%  35%  10%   5%   --   -12% -23%  -27% -63%
    TA_H_X   2938/s 289% 256% 239%     145%    139% 125%   93%    89%  54%  25%  19%  14%     -- -12%  -17% -58%
    TA_X     3330/s 340% 304% 284%     177%    171% 156%  119%   114%  75%  42%  35%  29%    13%   --   -6% -52%
    TA_XS    3534/s 367% 328% 307%     194%    187% 171%  132%   127%  86%  51%  43%  37%    20%   6%    -- -49%
    TMPL     6977/s 823% 746% 704%     481%    467% 436%  358%   348% 267% 197% 183% 171%   138% 110%   97%   --
    ---MEM------------------------------------------------------------------
    Cached in memory tests
    Benchmark: running HT, HTC, HTE, HTJ, TA, TA_H, TA_H_X, TA_H_XP, TA_P, TA_PS, TA_X, TA_XP, TA_XPS, TT, TTX for at least 2 CPU seconds...
            HT:  2 wallclock secs ( 2.10 usr +  0.04 sys =  2.14 CPU) @ 2670.56/s (n=5715)
           HTC:  3 wallclock secs ( 2.00 usr +  0.05 sys =  2.05 CPU) @ 8212.68/s (n=16836)
           HTE:  2 wallclock secs ( 2.16 usr +  0.01 sys =  2.17 CPU) @ 1543.78/s (n=3350)
           HTJ:  2 wallclock secs ( 1.99 usr +  0.08 sys =  2.07 CPU) @ 6197.58/s (n=12829)
            TA:  2 wallclock secs ( 2.08 usr +  0.03 sys =  2.11 CPU) @ 3872.51/s (n=8171)
          TA_H:  2 wallclock secs ( 2.11 usr +  0.02 sys =  2.13 CPU) @ 3882.63/s (n=8270)
        TA_H_X:  2 wallclock secs ( 2.07 usr +  0.05 sys =  2.12 CPU) @ 5396.70/s (n=11441)
       TA_H_XP:  2 wallclock secs ( 2.15 usr +  0.03 sys =  2.18 CPU) @ 5248.17/s (n=11441)
          TA_P:  2 wallclock secs ( 2.11 usr +  0.03 sys =  2.14 CPU) @ 4565.42/s (n=9770)
         TA_PS:  2 wallclock secs ( 2.08 usr +  0.04 sys =  2.12 CPU) @ 4829.72/s (n=10239)
          TA_X:  2 wallclock secs ( 2.07 usr +  0.02 sys =  2.09 CPU) @ 6225.36/s (n=13011)
         TA_XP:  2 wallclock secs ( 2.06 usr +  0.06 sys =  2.12 CPU) @ 8068.40/s (n=17105)
        TA_XPS:  2 wallclock secs ( 2.09 usr +  0.07 sys =  2.16 CPU) @ 9045.83/s (n=19539)
            TT:  2 wallclock secs ( 2.22 usr +  0.01 sys =  2.23 CPU) @ 2297.31/s (n=5123)
           TTX:  2 wallclock secs ( 2.10 usr +  0.02 sys =  2.12 CPU) @ 3377.36/s (n=7160)
              Rate  HTE   TT   HT  TTX   TA TA_H TA_P TA_PS TA_H_XP TA_H_X  HTJ TA_X TA_XP  HTC TA_XPS
    HTE     1544/s   -- -33% -42% -54% -60% -60% -66%  -68%    -71%   -71% -75% -75%  -81% -81%   -83%
    TT      2297/s  49%   -- -14% -32% -41% -41% -50%  -52%    -56%   -57% -63% -63%  -72% -72%   -75%
    HT      2671/s  73%  16%   -- -21% -31% -31% -42%  -45%    -49%   -51% -57% -57%  -67% -67%   -70%
    TTX     3377/s 119%  47%  26%   -- -13% -13% -26%  -30%    -36%   -37% -46% -46%  -58% -59%   -63%
    TA      3873/s 151%  69%  45%  15%   --  -0% -15%  -20%    -26%   -28% -38% -38%  -52% -53%   -57%
    TA_H    3883/s 152%  69%  45%  15%   0%   -- -15%  -20%    -26%   -28% -37% -38%  -52% -53%   -57%
    TA_P    4565/s 196%  99%  71%  35%  18%  18%   --   -5%    -13%   -15% -26% -27%  -43% -44%   -50%
    TA_PS   4830/s 213% 110%  81%  43%  25%  24%   6%    --     -8%   -11% -22% -22%  -40% -41%   -47%
    TA_H_XP 5248/s 240% 128%  97%  55%  36%  35%  15%    9%      --    -3% -15% -16%  -35% -36%   -42%
    TA_H_X  5397/s 250% 135% 102%  60%  39%  39%  18%   12%      3%     -- -13% -13%  -33% -34%   -40%
    HTJ     6198/s 301% 170% 132%  84%  60%  60%  36%   28%     18%    15%   --  -0%  -23% -25%   -31%
    TA_X    6225/s 303% 171% 133%  84%  61%  60%  36%   29%     19%    15%   0%   --  -23% -24%   -31%
    TA_XP   8068/s 423% 251% 202% 139% 108% 108%  77%   67%     54%    50%  30%  30%    --  -2%   -11%
    HTC     8213/s 432% 257% 208% 143% 112% 112%  80%   70%     56%    52%  33%  32%    2%   --    -9%
    TA_XPS  9046/s 486% 294% 239% 168% 134% 133%  98%   87%     72%    68%  46%  45%   12%  10%     --

=cut
