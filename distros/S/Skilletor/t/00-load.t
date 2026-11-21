#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  Skilletor
  Skilletor::AgentsMD
  Skilletor::Apply
  Skilletor::Backend
  Skilletor::Briefing
  Skilletor::Bundles
  Skilletor::Cache
  Skilletor::CLI
  Skilletor::Catalog
  Skilletor::ClaudeSettings
  Skilletor::Commands
  Skilletor::Config
  Skilletor::Convert
  Skilletor::Engine
  Skilletor::Entry
  Skilletor::Error
  Skilletor::Error::Ambiguous
  Skilletor::Error::Apply
  Skilletor::Error::Block
  Skilletor::Error::Bundle
  Skilletor::Error::CacheRejected
  Skilletor::Error::Catalog
  Skilletor::Error::Command
  Skilletor::Error::Config
  Skilletor::Error::Convert
  Skilletor::Error::Frontmatter
  Skilletor::Error::JSON
  Skilletor::Error::Lock
  Skilletor::Error::LockTimeout
  Skilletor::Error::Render
  Skilletor::Error::Source
  Skilletor::Error::Spec
  Skilletor::Error::TOML
  Skilletor::Error::Tar
  Skilletor::Error::Target
  Skilletor::Error::Unsupported
  Skilletor::FSUtil
  Skilletor::Frontmatter
  Skilletor::GitEnv
  Skilletor::Gitignore
  Skilletor::Gzip
  Skilletor::JSON
  Skilletor::JSON::OrderedHash
  Skilletor::JSString
  Skilletor::Lock
  Skilletor::Probe
  Skilletor::Process
  Skilletor::Render
  Skilletor::Render::Loader
  Skilletor::Report
  Skilletor::Resolver
  Skilletor::Role::Source
  Skilletor::Source::Git
  Skilletor::Source::Local
  Skilletor::Source::Url
  Skilletor::Spec
  Skilletor::State
  Skilletor::TOML
  Skilletor::Tar
  Skilletor::Targets
  Skilletor::URL
)) {
  use_ok($_);
}

done_testing;
