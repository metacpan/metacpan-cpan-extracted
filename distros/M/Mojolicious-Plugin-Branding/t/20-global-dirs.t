use strict;
use warnings;
use Test::More;
use FindBin qw< $Bin >;
use lib "$Bin/lib";
use BrandingTest;

subtest 'rainy: missing global dir does not stop the following ones' => sub {
   my $t = t_for({%generic, 'global/templates/index.html.ep' => 'global page'},
      {global => ['missing', 'global']});
   $t->get_ok('/' => \%BAR)->content_is("global page\n");
};

subtest 'rainy: undef global items are skipped' => sub {
   for my $global (undef, [undef], [undef, 'global']) {
      my $t = t_for({%generic, 'global/templates/index.html.ep' => 'global page'},
         {global => $global});
      my $expected = ref($global) && $global->@* > 1 ? 'global' : 'generic';
      $t->get_ok('/' => \%BAR)->content_is("$expected page\n");
   }
};

subtest 'rainy: dir without templates/ or public/ is skipped' => sub {
   my $t = t_for({%generic, 'empty/other/file.txt' => 'nothing to see'},
      {global => ['empty']});
   $t->get_ok('/' => \%BAR)->content_is("generic page\n");
   $t->get_ok('/site.css' => \%BAR)->content_is('generic css');
};

# a hash ref is a specification as for a brand, with its own checks
subtest 'rainy: invalid global specification' => sub {
   for my $case (
         ['unknown key', {global => 1}, qr{unknown keys in global: global}],
         ['unknown sub-spec key', {templates => {ignore => 1}},
            qr{unknown keys in templates for global: ignore}],
         ['ignore_app_paths', {templates => {ignore_app_paths => 1}},
            qr{ignore_app_paths not allowed}],
         ['code ref', sub {}, qr{invalid specification for global}]) {
      my ($name, $global, $error) = $case->@*;
      eval { t_for({%generic}, {global => $global}) };
      like $@, $error, "croaks on $name";
   }
};

subtest 'rainy: invalid items in global array' => sub {
   for my $case (
         ['array ref', [1], qr{invalid path, either Mojo::File or plain string}],
         ['hash ref', {}, qr{invalid path, either Mojo::File or plain string}],
         ['empty string', '', qr{invalid empty path}]) {
      my ($name, $item, $error) = $case->@*;
      eval { t_for({%generic}, {global => [$item]}) };
      like $@, $error, "croaks on $name";
   }
};

my %two_looks = (%generic,
   'one/templates/index.html.ep' => 'one page',
   'one/public/site.css'         => 'one css',
   'two/templates/index.html.ep' => 'two page');

# LIFO: the last registered global wins, earlier ones are still fallbacks
subtest 'sunny: a later global comes before the earlier one' => sub {
   my $t = t_for({%two_looks}, {global => 'one'});
   $t->app->plugin(Branding => {global => 'two'});
   $t->get_ok('/' => \%BAR)->content_is("two page\n");
   $t->get_ok('/site.css' => \%BAR)->content_is('one css', 'one still used');
};

subtest 'sunny: a registration without global keeps it' => sub {
   my $t = t_for({%two_looks}, {global => 'one'});
   $t->app->plugin(Branding => {individual => {brands => {foo => 'brands/foo'}}});
   $t->get_ok('/' => \%BAR)->content_is("one page\n");
   $t->get_ok('/site.css' => \%BAR)->content_is('one css');
};

# replacing global must not drop directories added by others in between
subtest 'sunny: other directories survive a later global' => sub {
   my $t = t_for({%two_looks, 'extra/other.html.ep' => 'extra page'},
      {global => 'one'});
   my $app = $t->app;
   push @{$app->renderer->paths}, $app->home->child('extra')->to_string;
   $app->plugin(Branding => {global => 'two'});
   $app->routes->get('/other' => sub { shift->render(template => 'other') });
   $t->get_ok('/other' => \%BAR)->content_is("extra page\n");
   $t->get_ok('/' => \%BAR)->content_is("two page\n");
};

done_testing();
