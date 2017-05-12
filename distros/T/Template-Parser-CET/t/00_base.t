# -*- Mode: Perl; -*-

=head1 NAME

00_base.t - Test usage and installtion of Template::Parser::CET

=cut

use strict;
use warnings;
use constant n_tests => 24;
use Test::More tests => n_tests;
use Template;
use Template::Config;

my $module = 'Template::Parser::CET';
use_ok($module);

###----------------------------------------------------------------###

sub process_ok { # process the value and say if it was ok
    my $str  = shift;
    my $test = shift;
    my $vars = shift || {};
    my $conf = local $vars->{'tt_config'} = $vars->{'tt_config'} || [];
    my $obj  = shift || Template->new(@$conf); # new object each time
    my $out  = '';
    my $line = (caller)[2];
    delete $vars->{'tt_config'};

    $obj->process(\$str, $vars, \$out);
    my $ok = ref($test) ? $out =~ $test : $out eq $test;
    if ($ok) {
        ok(1, "Line $line   \"$str\" => \"$out\"");
        return $obj;
    } else {
        ok(0, "Line $line   \"$str\"");
        warn "# Was:\n$out\n# Should've been:\n$test\n";
        print $obj->error if $obj->can('error');
        exit;
    }
}

###----------------------------------------------------------------###

my $orig_class = $Template::Config::PARSER;
if ($orig_class eq $module) {
  SKIP: {
      skip("$module seems to already be the PARSER class - can't do basic tests", n_tests - 1);
  };
}

ok($orig_class, "Found a PARSER in config ($orig_class)");

### try
process_ok("[% 234 %]" => '234', {tt_config => [PARSER => $module->new]});
process_ok("[% {b=>'B'}.b %]" => 'B', {tt_config => [PARSER => $module->new]});
ok($Template::Config::PARSER ne $module, "PARSER is still different");

for (1..2) {
    ### try activating
    ok($module->can('activate'), "$module has an activate method");
    ok(eval { $module->activate }, "Called activate");
    ok($Template::Config::PARSER eq $module, "PARSER now matches");
    process_ok("[% {b=>'B'}.b %]" => 'B', {tt_config => [PARSER => $module->new]});


    ### try deactivating
    ok($module->can('deactivate'), "$module has an activate method");
    ok($module->deactivate,        "Called deactivate");
    ok($Template::Config::PARSER ne $module, "PARSER no longer matches");
}

### try importing
ok(eval("use $module activate => 1; 1"), "Ran use $module activate => 1 ($@)");
ok($Template::Config::PARSER eq $module, "PARSER now matches");
process_ok("[% {b=>'B'}.b %]" => 'B', {tt_config => [PARSER => $module->new]});

### deactivate one more time
ok($module->deactivate,        "Called deactivate");
ok($Template::Config::PARSER ne $module, "PARSER no longer matches");
