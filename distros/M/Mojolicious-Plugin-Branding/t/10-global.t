use strict;
use warnings;
use Test::More;
use FindBin qw< $Bin >;
use lib "$Bin/lib";
use BrandingTest;
use Mojo::File qw< tempdir path >;

subtest 'sunny: global override' => sub {
   my $t = t_for({%generic,
      'global/templates/index.html.ep' => 'global page',
      'global/public/site.css'         => 'global css'},
      {global => ['global']});
   $t->get_ok('/' => \%BAR)->content_is("global page\n");
   $t->get_ok('/site.css' => \%BAR)->content_is('global css');
};

# point 1
subtest 'sunny: global only, no individual section' => sub {
   my $t = eval {
      t_for({%generic, 'global/templates/index.html.ep' => 'global page'},
         {global => ['global']});
   };
   ok $t, 'plugin registers' or diag $@;
   $t->get_ok('/' => \%BAR)->content_is("global page\n") if $t;
};

subtest 'sunny: global as a plain string' => sub {
   my $t = t_for({%generic, 'global/templates/index.html.ep' => 'global page'},
      {global => 'global'});
   $t->get_ok('/' => \%BAR)->content_is("global page\n");
};

subtest 'sunny: first global dir wins' => sub {
   my $t = t_for({%generic,
      'a/templates/index.html.ep' => 'a page',
      'a/public/site.css'         => 'a css',
      'b/templates/index.html.ep' => 'b page',
      'b/public/site.css'         => 'b css',
      'b/public/only-b.css'       => 'only b'},
      {global => ['a', 'b']});
   $t->get_ok('/' => \%BAR)->content_is("a page\n");
   $t->get_ok('/site.css' => \%BAR)->content_is('a css');
   $t->get_ok('/only-b.css' => \%BAR)->content_is('only b');
};

subtest 'sunny: global as Mojo::File objects' => sub {
   my $tmp = write_files(tempdir, {'templates/index.html.ep' => 'global page'});
   my $dir = path("$tmp");    # plain Mojo::File; $tmp keeps the dir alive
   for my $case (['in an array', [$dir]], ['alone', $dir]) {
      my ($name, $global) = $case->@*;
      my $t = eval { t_for({%generic}, {global => $global}) };
      ok $t, "plugin registers, $name" or diag $@;
      $t->get_ok('/' => \%BAR)->content_is("global page\n") if $t;
   }
};

done_testing();
