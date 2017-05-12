use strict;
use warnings;
use Test::More tests => 2;

# FIXME: Dist::Zilla would make this file redundant (and add a few dozen other features)

# The two modules in this dist have been released under two different dist names.
# MojoX-Renderer-Haml only defined a $VERSION for MojoX::Renderer::Haml.
# Mojolicious-Plugin-HamlRenderer only defined a $VERSION Mojolicious::Plugin::HamlRenderer.
# So now to keep PAUSE (and 02packages.details.txt.gz) happy
# we should ensure both modules get an updated $VERSION.

my @modules = qw(
  MojoX::Renderer::Haml
  Mojolicious::Plugin::HamlRenderer
);

eval "require $_" || die $@
  for @modules;

&is( (map { $_->VERSION } @modules), 'module versions match' );

my $version = $modules[0]->VERSION;

my $changes = do {
  open(my $fh, '<', 'Changes') or die "open changelog: $!";
  while( my $line = <$fh> ){
    last if $line =~ /^\s*$/; # stop at first blank line
  };
  <$fh>; # return next line
};

like $changes, qr/^$version \d{4}-\d{2}-\d{2}.+$/, 'current version is at top of changelog';
