#!/usr/bin/env perl

# Enumeration of the test classes in the test suite.

package t::AllTests;

use strict;
use warnings;

use t::Correctness::OneCFile;
use t::Correctness::TwoCFiles;
use t::Correctness::IncludeFiles;
use t::Correctness::DependencyGraphIsNotATree;
use t::Correctness::CDepender;
use t::Correctness::DependingPbsfile;
use t::ErrorHandling::NonExisting;
use t::ErrorHandling::BuildError;
use t::ErrorHandling::CyclicDependencies;
use t::Rules::Dependencies;
use t::Rules::Builder;
use t::Rules::NodeSubs;
use t::Rules::NodeAttributes;
use t::Rules::ReplaceRule;
use t::Misc::AddConfig;
use t::Misc::PbsUse;
use t::Misc::Subpbs;
use t::Misc::Nodetypes;
use t::Misc::SourceDirectory;
use t::Misc::Targets;
use t::Misc::ExtraDependencies;
use t::Misc::CommandLineFlags;
use t::Misc::CDependencyGraph;
use t::Misc::Triggers;

1;
