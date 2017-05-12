use strict;
use warnings;

use Test::More;
use Test::Differences qw( eq_or_diff );
use Test::Fatal qw( exception );

# FILENAME: core_inflate.t
# ABSTRACT: Test my core magic

require Pod::Weaver::PluginBundle::Author::KENTNL::Core;
require Pod::Weaver::Config::Assembler;

sub get_plug {
  my ($name) = @_;
  my $module = Pod::Weaver::Config::Assembler->expand_package($name);
  use_ok($module);
  return $module;
}

eq_or_diff(
  [ get_plug('@Author::KENTNL::Core')->mvp_bundle_config ],
  [

    [ '@A:KNL:Core/@CorePrep/EnsurePod5', 'Pod::Weaver::Plugin::EnsurePod5',     {} ],
    [ '@A:KNL:Core/@CorePrep/H1Nester',   'Pod::Weaver::Plugin::H1Nester',       {} ],
    [ '@A:KNL:Core/-SingleEncoding',      'Pod::Weaver::Plugin::SingleEncoding', {} ],

  ],
  "Core inflates as intended"
);

is( exception { get_plug('@Author::KENTNL')->mvp_bundle_config() }, undef, 'Full bundle stack does not err' );

done_testing;

