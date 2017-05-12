use strict;
use warnings;

use Test::More;

# FILENAME: 03_fake_system.t
# CREATED: 26/03/12 13:28:04 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Simulate a Fake Installed System and test no-require features

use Test::Fatal;
use FindBin;
use Path::Tiny qw( path );

my $tlib  = path($FindBin::RealBin)->child('03_t');
my $gtlib = path($FindBin::RealBin)->child('tlib');

unshift @INC, "$gtlib";
require Whitelist;

my $wl = Whitelist->new();
$wl->whitelist(qw( Module::Data Test::More Data::Dumper warnings ));
$wl->whitelist(qw( Module::Runtime overload Path::Tiny ));
$wl->whitelist(qw( Path::ScanINC Scalar::Util ));
$wl->whitelist(qw( Module::Metadata strict version ));
$wl->noload_whitelist(qw( Test::A Test::B Test::C Test::D ));
$wl->noload_whitelist(qw( TB2::History TB2::StackBuilder Carp TB2::Mouse ));
$wl->noload_whitelist(qw( TB2::Types TB2::Mouse::Exporter TB2::Mouse::Meta::Role::Composite ));
$wl->noload_whitelist(qw( TB2::Mouse::Meta::Role::Application ));

$wl->freeze;

my $newinc  = $wl->{whitelist_inc};
my $realinc = $wl->{real_inc};

{
  local %INC;
  %INC = ( %{$newinc} );

  @INC = (
    $wl->checker(),
    $tlib->child('lib/site_perl/VERSION/ARCH-linux')->stringify,
    $tlib->child('lib/site_perl/VERSION')->stringify,
    $tlib->child('lib/VERSION/ARCH-linux')->stringify,
    $tlib->child('lib/VERSION')->stringify, @INC,
  );

  my @mods;
  for my $mod (qw( Test::A Test::B Test::C Test::D )) {
    is(
      exception {
        push @mods, Module::Data->new($mod);
      },
      undef,
      "Making MD for $mod works"
    );
  }

  for my $mod (qw( Test::A Test::B Test::C Test::D )) {
    my $key = Module::Runtime::module_notional_filename($mod);
    is( $INC{$key}, undef, "Module $mod wasn't loaded into global context" );
  }

  for my $mod (@mods) {
    my $path;
    is(
      exception {
        $path = $mod->path;
      },
      undef,
      "->path works for " . $mod->package
    );

    #		note $path;
  }

  for my $mod (qw( Test::A Test::B Test::C Test::D )) {
    my $key = Module::Runtime::module_notional_filename($mod);
    is( $INC{$key}, undef, "Module $mod wasn't loaded into global context" );
  }

  for my $mod (@mods) {
    my $root;
    is(
      exception {
        $root = $mod->root;
      },
      undef,
      "->root works for " . $mod->package
    );

    #		note $root;
  }

  for my $mod (qw( Test::A Test::B Test::C Test::D )) {
    my $key = Module::Runtime::module_notional_filename($mod);
    is( $INC{$key}, undef, "Module $mod wasn't loaded into global context" );
  }

  for my $mod (@mods) {
    my $version;
    is(
      exception {
        $version = $mod->version;
      },
      undef,
      "->version works for " . $mod->package
    );

    #		note $version;
  }

  for my $mod (qw( Test::A Test::B Test::C Test::D )) {
    my $key = Module::Runtime::module_notional_filename($mod);
    is( $INC{$key}, undef, "Module $mod wasn't loaded into global context" );
  }

  for my $mod (@mods) {
    my $version;
    is(
      exception {
        $version = $mod->_version_perl;
      },
      undef,
      "->_version_perl works for " . $mod->package
    );

    #		note $version;
  }
  for my $mod (qw( Test::A Test::B Test::C Test::D )) {
    my $key = Module::Runtime::module_notional_filename($mod);
    isnt( $INC{$key}, undef, "Module $mod WAS loaded into global context" );
  }
  for my $mod (qw( Test::A Test::B Test::C Test::D )) {
    my $e = $mod;
    $e =~ s/^Test:://;
    my $v;
    is(
      exception {
        $v = $mod->example();
      },
      undef,
      "Calls to $mod Work ( mod is definately loaded )"
    );
    is( $v, $e, "Value is as expected from $mod" );

    #		note explain { got => $v, want => $e };
  }
}

done_testing;

