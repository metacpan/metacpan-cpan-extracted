use Mojo::Base -strict;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::Mojo;
use Test::More;

my $root_namespace = 'Mojolicious::Plugin::AdvancedMod';

use_ok( $root_namespace );

my $t              = Test::Mojo->new( 'MyApp' );
my $available_mods = eval "\$$root_namespace" . "::AVAILABLE_MODS";

foreach my $mod ( keys %$available_mods ) {
  if( !$available_mods->{$mod} || $mod =~ /Fake/ ) {
    diag "$root_namespace::$mod ... Skipped";
    next;
  }

  my $key = "$root_namespace/$mod.pm";
  $key =~ s/::/\//g;

 ok exists $INC{$key}, "$root_namespace::$mod ... Loaded";
}

ok !exists $INC{'Mojolicious/Plugin/AdvancedMod/Fake.pm'}, "Mojolicious::Plugin::AdvancedMod::Fake ... Skipped";

done_testing();
