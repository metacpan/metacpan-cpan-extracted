package SignalWire::Contexts::ContextBuilder;
# Copyright (c) 2025 SignalWire
# Licensed under the MIT License.
#
# This file is a thin loader: the real SignalWire::Contexts::ContextBuilder
# package (along with Context, Step, GatherInfo, GatherQuestion, and helpers)
# is defined inside lib/SignalWire/Contexts.pm. Loading the parent module
# defines all of those packages in one shot.
#
# Earlier this file shipped a 28-line stub that overrode the real
# implementation when AgentBase did `require SignalWire::Contexts::ContextBuilder`.
# Now we just re-load the canonical source so the require yields the full DSL.

use strict;
use warnings;

require SignalWire::Contexts;

1;
