#!/usr/bin/env perl
# t/53_surface_audit.t — Layer B symbol-level surface audit smoke tests.
#
# Lightweight checks on scripts/enumerate_surface.pl so a broken enumerator
# fails at `prove` time instead of at CI-diff time. The full comparison
# (port_surface.json vs. porting-sdk/python_surface.json) lives in the
# surface-audit GitHub workflow.

use strict;
use warnings;
use Test::More;
use FindBin ();
use File::Spec ();
use JSON ();

my $REPO = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $SCRIPT = File::Spec->catfile($REPO, 'scripts', 'enumerate_surface.pl');

ok(-f $SCRIPT, 'enumerator script present');

# Syntax-check the enumerator without running it.
my $syntax = `perl -I$REPO/lib -c $SCRIPT 2>&1`;
like($syntax, qr/syntax OK/, 'enumerator parses cleanly');

# Run it, capture JSON on stdout.
my $out = `perl -I$REPO/lib $SCRIPT --stdout 2>/dev/null`;
ok(length $out, 'enumerator produced output');

my $snap = eval { JSON->new->utf8->decode($out) };
ok(!$@, 'enumerator emitted valid JSON') or diag $@;

is($snap->{version}, '1', 'version field present');
ok(exists $snap->{generated_from}, 'generated_from present');
ok(exists $snap->{modules} && ref($snap->{modules}) eq 'HASH', 'modules object present');

# Spot-check a few known mappings. Any of these failing means a refactor
# silently broke the Python-reference name translation.
my %modules = %{ $snap->{modules} };
ok(exists $modules{'signalwire.core.agent_base'}, 'agent_base module present');
ok(exists $modules{'signalwire.core.agent_base'}{classes}{AgentBase},
   'AgentBase class present');
ok((grep { $_ eq 'get_full_url' } @{ $modules{'signalwire.core.agent_base'}{classes}{AgentBase} }),
   'AgentBase.get_full_url recorded');

ok(exists $modules{'signalwire.core.mixins.prompt_mixin'}{classes}{PromptMixin},
   'PromptMixin translated from AgentBase prompt_* subs');
ok((grep { $_ eq 'set_prompt_text' } @{ $modules{'signalwire.core.mixins.prompt_mixin'}{classes}{PromptMixin} }),
   'PromptMixin.set_prompt_text mapped correctly');

ok(exists $modules{'signalwire.core.function_result'}{classes}{FunctionResult},
   'FunctionResult class present');
ok((grep { $_ eq 'to_dict' } @{ $modules{'signalwire.core.function_result'}{classes}{FunctionResult} }),
   'FunctionResult.to_dict mapped from Perl to_hash');

# Private subs (underscore-prefixed) must NOT appear anywhere.
for my $mod (keys %modules) {
    for my $cls (keys %{ $modules{$mod}{classes} }) {
        for my $m (@{ $modules{$mod}{classes}{$cls} }) {
            like($m, qr/^[A-Za-z_]/, "method name looks public: $mod.$cls.$m");
            unlike($m, qr/^_[^_]/, "no single-underscore private method: $mod.$cls.$m");
        }
    }
}

done_testing();
