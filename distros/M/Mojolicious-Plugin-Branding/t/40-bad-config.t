use strict;
use warnings;
use Test::More;
use FindBin qw< $Bin >;
use lib "$Bin/lib";
use BrandingTest;

subtest 'rainy: no config at all' => sub {
   for my $conf ({}, {individual => undef}, {individual => {}}) {
      my $t = eval { t_for({%generic, %foo}, $conf, brand_hook()) };
      ok $t, 'plugin registers' or diag $@;
      $t->get_ok('/' => \%FOO)->content_is("generic page\n") if $t;
   }
};

subtest 'rainy: empty or missing paths leave the app alone' => sub {
   for my $paths ([], undef, [undef], ['missing'], ['brands/empty']) {
      my $t = t_for({%generic, %foo, 'brands/empty/other.txt' => 'nothing'},
         {individual => {paths => $paths}}, brand_hook());
      $t->get_ok('/' => \%FOO)->content_is("generic page\n");
      $t->get_ok('/site.css' => \%FOO)->content_is('generic css');
   }
};

subtest 'rainy: undef items do not stop the following ones' => sub {
   my $t = t_for({%generic, %foo},
      {individual => {paths => [undef, 'missing', 'brands/foo']}}, brand_hook());
   $t->get_ok('/' => \%FOO)->content_is("foo page\n");
};

subtest 'rainy: individual is not a hash reference' => sub {
   for my $case (['string', 'brands'], ['array ref', ['brands/foo']]) {
      my ($name, $individual) = $case->@*;
      eval { t_for({%generic}, {individual => $individual}) };
      like $@, qr{individual requires a hash reference}, "croaks on $name";
   }
};

subtest 'rainy: invalid individual paths' => sub {
   for my $case (
         ['hash ref', {}, qr{invalid path, either Mojo::File or plain string}],
         ['array ref item', [[1]], qr{invalid path, either Mojo::File or plain string}],
         ['empty string item', [''], qr{invalid empty path}]) {
      my ($name, $paths, $error) = $case->@*;
      eval { t_for({%generic}, {individual => {paths => $paths}}) };
      like $@, $error, "croaks on $name";
   }
};

done_testing();
