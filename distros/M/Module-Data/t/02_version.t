use strict;
use warnings;

use Test::More;
use FindBin;
use Path::Tiny qw(path);

# FILENAME: 02_version.t
# CREATED: 24/03/12 04:29:05 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test version lookup

my $gtlib = path($FindBin::RealBin)->child('tlib');

unshift @INC, "$gtlib";
require Whitelist;

my $wl = Whitelist->new();

$wl->whitelist(qw( Module::Data Test::More Data::Dumper warnings ));
$wl->whitelist(qw( Module::Runtime overload ));
$wl->noload_whitelist(qw( TB2::History Carp TB2::Mouse TB2::Types TB2::StackBuilder ));
$wl->noload_whitelist(qw( TB2::Mouse::Exporter TB2::Mouse::Meta::Role::Composite ));
$wl->noload_whitelist(qw( TB2::Mouse::Meta::Role::Application ));
$wl->freeze;

my $newinc  = $wl->{whitelist_inc};
my $realinc = $wl->{real_inc};

{
  unshift @INC, $wl->checker();

  local %INC;

  %INC = ( %{$newinc} );

  my $module = Module::Data->new('Test::More');    # because we know its loaded already

  isnt( $module->version, undef, 'Module->version  works' );

  note explain [ $module->version ];
}
done_testing;

