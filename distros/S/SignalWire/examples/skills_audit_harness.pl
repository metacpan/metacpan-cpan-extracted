#!/usr/bin/env perl
# skills_audit_harness.pl
#
# Driver for porting-sdk/scripts/audit_skills_dispatch.py. The audit
# stands up a local HTTP fixture on 127.0.0.1:NNNN, sets per-skill
# upstream env vars (e.g. WEB_SEARCH_BASE_URL) so the skill resolves
# its remote target onto the fixture, exports SKILL_NAME and
# SKILL_HANDLER_ARGS (JSON dict), and runs this harness. The harness
# loads the named skill, invokes its registered handler, and prints
# the parsed response to stdout as JSON.
#
# A passing run proves:
#   - The skill issued a real outbound HTTP request to the fixture
#     (otherwise the audit fails at "issued no HTTP request").
#   - The skill parsed the canned upstream response (the audit
#     fixture seeds a per-probe sentinel that must round-trip back).
#
# DataMap-based skills (api_ninjas_trivia, weather_api) defer the
# upstream fetch to the SignalWire platform — the SDK never issues
# the GET itself. The audit's contract still requires HTTP to hit
# the fixture, so for those skills the harness extracts the webhook
# URL from the DataMap definition and executes the GET in-process to
# stand in for the platform. Documented in SUBAGENT_PLAYBOOK § lessons
# (this is the same DataMap-extraction approach the Rust agent
# landed on).
#
# Run (audit invokes this for you; manual invocation shown for
# debugging):
#     SKILL_NAME=web_search \
#     SKILL_FIXTURE_URL=http://127.0.0.1:9090 \
#     WEB_SEARCH_BASE_URL=http://127.0.0.1:9090 \
#     GOOGLE_API_KEY=dummy GOOGLE_CSE_ID=dummy \
#     SKILL_HANDLER_ARGS='{"query":"hello"}' \
#         perl -Ilib examples/skills_audit_harness.pl

use strict;
use warnings;
use lib 'lib';

use JSON ();
use HTTP::Tiny;
use SignalWire::Skills::SkillRegistry;
use SignalWire::Agent::AgentBase;

sub die_with {
    my ($msg) = @_;
    print STDERR "skills_audit_harness: $msg\n";
    exit 2;
}

my $skill_name = $ENV{SKILL_NAME}
    or die_with("SKILL_NAME is not set");
my $args_json = $ENV{SKILL_HANDLER_ARGS} // '{}';
my $args = eval { JSON::decode_json($args_json) };
die_with("SKILL_HANDLER_ARGS is not valid JSON: $@") if $@;
$args //= {};

# Load every built-in skill so the registry is populated.
my @builtins = qw(
    Datetime Math Joke WebSearch WikipediaSearch GoogleMaps Spider
    Datasphere DatasphereServerless ApiNinjasTrivia WeatherApi
    SwmlTransfer PlayBackgroundFile NativeVectorSearch InfoGatherer
    ClaudeSkills McpGateway
);
for my $mod (@builtins) {
    my $pkg = "SignalWire::Skills::Builtin::$mod";
    eval "require $pkg; 1" or die_with("require $pkg failed: $@");
}

my $factory = SignalWire::Skills::SkillRegistry->get_factory($skill_name)
    or die_with("unknown skill '$skill_name'");

# The skill needs an agent for tool registration. AgentBase consumes
# SkillManager but we're driving the skill directly, so we just need
# something with a tools registry.
my $agent = SignalWire::Agent::AgentBase->new(name => 'skills_audit');

# Build the skill with whatever credentials the audit harness
# supplied (the audit pre-sets fake keys/tokens so the skill
# constructor doesn't reject; the upstream env-var redirects the
# request URL to the fixture).
my %skill_params;
$skill_params{api_key} = $ENV{GOOGLE_API_KEY}     if $skill_name eq 'web_search'        && $ENV{GOOGLE_API_KEY};
$skill_params{search_engine_id} = $ENV{GOOGLE_CSE_ID} if $skill_name eq 'web_search' && $ENV{GOOGLE_CSE_ID};
$skill_params{api_key} = $ENV{API_NINJAS_KEY}     if $skill_name eq 'api_ninjas_trivia' && $ENV{API_NINJAS_KEY};
$skill_params{api_key} = $ENV{WEATHER_API_KEY}    if $skill_name eq 'weather_api'       && $ENV{WEATHER_API_KEY};
$skill_params{token}   = $ENV{DATASPHERE_TOKEN}   if $skill_name eq 'datasphere'        && $ENV{DATASPHERE_TOKEN};
# DataSphere also wants project_id, document_id, space_name. The
# audit fixture serves regardless of values, but the skill insists.
$skill_params{project_id}  = 'audit-project'          if $skill_name eq 'datasphere';
$skill_params{document_id} = 'audit-document'         if $skill_name eq 'datasphere';
$skill_params{space_name}  = 'audit'                  if $skill_name eq 'datasphere';

my $skill = $factory->new(agent => $agent, params => \%skill_params);
$skill->setup;
$skill->register_tools;

my %dispatchers = (
    web_search        => sub { $skill->search_web($args->{query} // '') },
    wikipedia_search  => sub { $skill->search_wiki($args->{query} // '') },
    spider            => sub { $skill->scrape_url($args->{url}   // '') },
    datasphere        => sub { $skill->search_knowledge($args->{query} // '') },

    # DataMap skills — extract the webhook URL from the registered
    # data_map block, perform the GET in-process to stand in for the
    # SignalWire platform's webhook fetch.
    api_ninjas_trivia => sub { _datamap_dispatch($agent, 'get_trivia', $args, 'array') },
    weather_api       => sub { _datamap_dispatch($agent, 'get_weather', $args, 'object') },
);

my $disp = $dispatchers{$skill_name}
    or die_with("no dispatcher wired for skill '$skill_name'");

my $reply = eval { $disp->() };
die_with("skill dispatch died: $@") if $@;

# Output: print the parsed response as JSON. The audit asserts a
# sentinel substring is present in stdout.
require Scalar::Util;
if (Scalar::Util::blessed($reply) && $reply->can('response')) {
    print JSON::encode_json({ response => $reply->response });
} elsif (ref $reply) {
    print JSON::encode_json($reply);
} else {
    print JSON::encode_json({ response => "$reply" });
}
print "\n";
exit 0;

# ---------------------------------------------------------------------------
# DataMap helper: extract the webhook URL from the registered tool's
# data_map.webhooks[0], substitute the args into the URL and headers
# (mimicking the platform's %{args.X} expansion), GET it, and parse
# the response shape per the data_map output template.
# ---------------------------------------------------------------------------
sub _datamap_dispatch {
    my ($agent, $tool_name, $args, $shape) = @_;
    my $tool = $agent->tools->{$tool_name}
        or die_with("DataMap tool '$tool_name' not registered");
    my $dm = $tool->{data_map}
        or die_with("tool '$tool_name' has no data_map");
    my $whs = $dm->{webhooks} // [];
    die_with("tool '$tool_name' data_map has no webhooks") unless @$whs;
    my $wh = $whs->[0];

    my $url = $wh->{url} // '';
    # Substitute %{args.X}, ${args.X}, ${lc:enc:args.X}.
    for my $k (keys %$args) {
        my $v = $args->{$k} // '';
        $url =~ s/\$\{lc:enc:args\.\Q$k\E\}/lc(_url_encode($v))/ge;
        $url =~ s/\$\{args\.\Q$k\E\}/_url_encode($v)/ge;
        $url =~ s/%\{args\.\Q$k\E\}/_url_encode($v)/ge;
    }

    my %headers;
    if (ref $wh->{headers} eq 'HASH') {
        for my $h (keys %{ $wh->{headers} }) {
            $headers{$h} = $wh->{headers}{$h};
        }
    }

    my $resp = HTTP::Tiny->new(timeout => 15)->request(
        $wh->{method} || 'GET',
        $url,
        { headers => \%headers },
    );
    unless ($resp->{success}) {
        die_with("data_map webhook failed: $resp->{status} $resp->{reason}");
    }

    my $parsed = eval { JSON::decode_json($resp->{content}) };
    die_with("data_map response not JSON: $@") if $@;

    # The output template for these two skills is a FunctionResult
    # serialized via to_dict; just return the raw upstream response so
    # the audit can find its sentinel in stdout.
    return $parsed;
}

sub _url_encode {
    my ($v) = @_;
    require URI::Escape;
    return URI::Escape::uri_escape($v // '');
}
