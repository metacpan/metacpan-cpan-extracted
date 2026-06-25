#!/usr/bin/env perl
use strict;
use warnings;
use 5.016;

use Template::Sluz;
use Time::HiRes;
use Getopt::Long qw(GetOptions);

my $ITERATIONS = 5000;
my $filter;

GetOptions(
    "filter=s"       => \$filter,
    "iterations|n=i" => \$ITERATIONS,
) or die "Usage: $0 [--filter REGEX] [-n ITERATIONS]\n";

if (@ARGV && !$filter) {
    $ITERATIONS = $ARGV[0];
}

################################################################################
################################################################################

my $sluz      = Template::Sluz->new();
my %vars      = get_tpl_vars();
my %templates = get_templates();

$sluz->assign(%vars);

# Print header
my $line = "-" x 61;
printf "%-30s %8s %10s %10s\n", "Benchmark", "Iters", "Millis", "Iter /s";
print "$line\n";

my $total_time = 0;
my %results;

for my $name (sort keys %templates) {
    my $t    = $templates{$name};
    my $tpl  = $t->{tpl};
    my $desc = $t->{desc};

    if ($filter && $name !~ /$filter/i && $desc !~ /$filter/i) { next; }

    # Warmup
    $sluz->parse_string($tpl) for 1..10;

    my $start = millis();
    for (1..$ITERATIONS) {
        $sluz->parse_string($tpl);
    }
    my $elapsed = millis() - $start;
    $total_time += $elapsed;

    my $per_sec;
    if ($elapsed > 0) {
        $per_sec = ($ITERATIONS * 1000) / $elapsed;
    } else {
        $per_sec = 0;
    }

    printf "%-30s %8d %10d %10.1f\n", $desc, $ITERATIONS, $elapsed, $per_sec;
    $results{$name} = { elapsed => $elapsed, per_sec => $per_sec };
}

print "$line\n";
printf "%-30s %8s %10d\n", "TOTAL", "", $total_time;

################################################################################

sub get_tpl_vars {
    return (
        name     => "Scott Baker",
        age      => 42,
        email    => 'scott@perturb.org',
        city     => "Portland",
        state    => "OR",
        active   => 1,
        verified => 0,
        items    => [qw(apple banana cherry date elderberry fig grape)],
        users    => [
            { name => "Alice", age => 30, role => "admin" },
            { name => "Bob",   age => 25, role => "user" },
            { name => "Carol", age => 35, role => "mod" },
        ],
        config => {
            theme    => "dark",
            lang     => "en",
            per_page => 25,
        },
        empty_list => [],
        undef_var  => undef,
        big_list   => [1..100],
    );
}

sub get_templates {
    return (
        variables_simple => {
            desc => "Simple variable output",
            tpl  => 'Hello {$name}, you are {$age} years old.',
        },
        variables_dotted => {
            desc => "Dotted path variables",
            tpl  => 'Theme: {$config.theme}, Lang: {$config.lang}, Per page: {$config.per_page}',
        },
        modifiers => {
            desc => "Variable modifiers",
            tpl  => '{$name|uc} {$name|lc} {$name|ucfirst} {$name|substr:0,5}',
        },
        modifiers_chained => {
            desc => "Chained modifiers",
            tpl  => '{$name|lc|ucfirst} {$name|uc|substr:0,5}',
        },
        modifiers_default => {
            desc => "Default modifier",
            tpl  => '{$undef_var|default:"N/A"} {$name|default:"Unknown"}',
        },
        if_simple => {
            desc => "Simple if/else",
            tpl  => '{if $active}ACTIVE{else}INACTIVE{/if}',
        },
        if_nested => {
            desc => "Nested if blocks",
            tpl  => '{if $active}{if $verified}VERIFIED{else}UNVERIFIED{/if}{else}DISABLED{/if}',
        },
        if_elseif => {
            desc => "If/elseif/else chains",
            tpl  => '{if $age > 50}SENIOR{elseif $age > 30}ADULT{elseif $age > 18}YOUNG{else}MINOR{/if}',
        },
        if_negated => {
            desc => "Negated conditions",
            tpl  => '{if !$verified}NOT VERIFIED{/if}{if !$undef_var}IS UNDEF{/if}',
        },
        foreach_array => {
            desc => "Foreach over array",
            tpl  => '{foreach $items as $item}[{$item}]{/foreach}',
        },
        foreach_array_with_index => {
            desc => "Foreach with index/first/last",
            tpl  => '{foreach $items as $item}{$__FOREACH_INDEX}:{$item}{if $__FOREACH_LAST}!{/if} {/foreach}',
        },
        foreach_hash => {
            desc => "Foreach over hash",
            tpl  => '{foreach $config as $k => $v}{$k}={$v} {/foreach}',
        },
        foreach_nested => {
            desc => "Nested foreach",
            tpl  => '{foreach $users as $u}{foreach $items as $i}{if $i eq "banana"}{$u.name}:{$i} {/if}{/foreach}{/foreach}',
        },
        foreach_empty => {
            desc => "Foreach over empty list",
            tpl  => 'BEFORE{foreach $empty_list as $item}{$item}{/foreach}AFTER',
        },
        comments => {
            desc => "Comments (should be stripped)",
            tpl  => '{* this is a comment *}Hello {$name}!',
        },
        literal => {
            desc => "Literal blocks",
            tpl  => '{literal}function foo() { return {$x}; }{/literal}',
        },
        expression => {
            desc => "Expression/function blocks",
            tpl  => 'Count: {$items|count} Joined: {$items|join:"-"}',
        },
        mixed => {
            desc => "Mixed template features",
            tpl  => <<'TPL',
<div class="user-list">
{* Display each user *}
{foreach $users as $u}
  <div class="user {if $u.role eq "admin"}admin{else}regular{/if}">
    <span class="name">{$u.name|ucfirst}</span>
    <span class="age">({$u.age})</span>
    {if $u.age > 28}
      <span class="senior">Senior</span>
    {/if}
  </div>
{/foreach}
</div>
TPL
        },
        foreach_large => {
            desc => "Large foreach (100 items)",
            tpl  => '{foreach $big_list as $i}{$i} {/foreach}',
        },
    );
}

sub millis {
	my $ret = int(Time::HiRes::time() * 1000);

	return $ret;
}
