# Migrating to SignalWire SDK 2.0

## Distribution Rename

```bash
# Before
cpanm SignalWire::Agents

# After
cpanm SignalWire
```

## Use Statement Changes

```perl
# Before
use SignalWire::Agents::AgentBase;
use SignalWire::Agents::Core::FunctionResult;
use SignalWire::Agents::Rest::SignalWireClient;
use SignalWire::Agents::Skills::DateTime;

my $agent  = SignalWire::Agents::AgentBase->new();
my $client = SignalWire::Agents::Rest::SignalWireClient->new(
    project_id => $project_id,
    token      => $token,
    space_url  => $space_url,
);

# After
use SignalWire::AgentBase;
use SignalWire::Core::FunctionResult;
use SignalWire::Rest::RestClient;
use SignalWire::Skills::DateTime;

my $agent  = SignalWire::AgentBase->new();
my $client = SignalWire::Rest::RestClient->new(
    project_id => $project_id,
    token      => $token,
    space_url  => $space_url,
);
```

## Class Renames

| Before | After |
|--------|-------|
| `SignalWire::Agents::AgentBase` | `SignalWire::AgentBase` |
| `SignalWire::Agents::Rest::SignalWireClient` | `SignalWire::Rest::RestClient` |
| `SignalWire::Agents::*` (all packages) | `SignalWire::*` |

## Quick Migration

Find and replace in your project:
```bash
# Flatten namespace (remove ::Agents level)
find . -name '*.pl' -o -name '*.pm' | xargs sed -i 's/SignalWire::Agents::/SignalWire::/g'

# Rename client class
find . -name '*.pl' -o -name '*.pm' | xargs sed -i 's/SignalWireClient/RestClient/g'

# Update use statements for the distribution itself
find . -name '*.pl' -o -name '*.pm' | xargs sed -i 's/use SignalWire::Agents;/use SignalWire;/g'
```

## What Didn't Change

- All method names (set_prompt_text, define_tool, add_skill, etc.)
- All parameter shapes
- SWML output format
- RELAY protocol
- REST API paths
- Skills, contexts, DataMap -- all the same
