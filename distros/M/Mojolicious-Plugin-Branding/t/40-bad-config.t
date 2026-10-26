use strict;
use warnings;
use Test::More;
use FindBin qw< $Bin >;
use lib "$Bin/lib";
use BrandingTest;
use Mojo::File qw< tempdir >;

sub brands { return {individual => {brands => {@_}}} }

subtest 'rainy: no config at all' => sub {
   for my $conf ({}, {individual => undef}, {individual => {}},
         {individual => {brands => undef}}, brands()) {
      my $t = eval { t_for({%generic, %foo}, $conf, brand_hook()) };
      ok $t, 'plugin registers' or diag $@;
      $t->get_ok('/' => \%FOO)->content_is("generic page\n") if $t;
   }
};

subtest 'rainy: empty or missing paths leave the app alone' => sub {
   for my $spec ([], undef, [undef], ['missing'], ['brands/empty'], '/missing',
         {paths => undef}, {templates => undef, public => {paths => undef}},
         {templates => [undef], public => {paths => [undef]}}) {
      my $t = eval {
         t_for({%generic, %foo, 'brands/empty/other.txt' => 'nothing'},
            brands(foo => $spec), brand_hook());
      };
      ok $t, 'plugin registers' or diag $@;
      next unless $t;
      $t->get_ok('/' => \%FOO)->content_is("generic page\n");
      $t->get_ok('/site.css' => \%FOO)->content_is('generic css');
   }
};

subtest 'rainy: undef items do not stop the following ones' => sub {
   for my $spec ([undef, 'missing', 'brands/foo'],
         {templates => [undef, 'brands/foo/templates'],
          public    => {paths => [undef, 'brands/foo/public']}}) {
      my $t = t_for({%generic, %foo}, brands(foo => $spec), brand_hook());
      $t->get_ok('/' => \%FOO)->content_is("foo page\n");
      $t->get_ok('/site.css' => \%FOO)->content_is('foo css');
   }
};

subtest 'rainy: undef brand is skipped' => sub {
   my $t = t_for({%generic, %foo}, brands(nope => undef, foo => 'brands/foo'),
      brand_hook());
   $t->get_ok('/' => \%FOO)->content_is("foo page\n");
   $t->get_ok('/?b=nope')->content_is("generic page\n");
};

# a missing absolute path must not be looked up under the app home
subtest 'rainy: missing absolute path is not relative to home' => sub {
   my $t = t_for({%generic, %foo}, brands(foo => '/templates'), brand_hook());
   $t->get_ok('/' => \%FOO)->content_is("generic page\n");
   $t->get_ok('/site.css' => \%FOO)->content_is('generic css');
};

# such a brand has no files at all, its directories are probably missing
subtest 'rainy: warning for an empty brand that ignores the application' => sub {
   for my $case (
         ['templates', 1, {paths => 'missing', templates => {ignore_app_paths => 1}}],
         ['public',    1, {paths => 'missing', public => {ignore_app_paths => 1}}],
         ['own directories', 0,
            {paths => 'brands/foo', templates => {ignore_app_paths => 1}}],
         ['app not ignored', 0, {paths => 'missing'}]) {
      my ($name, $expected, $spec) = $case->@*;
      my @warnings;
      my $t = t_for({%generic, %foo}, brands(foo => $spec), sub {
         # collect instead of printing
         my $log = shift->log->level('warn')->unsubscribe('message');
         $log->on(message => sub { push @warnings, $_[2] if $_[1] eq 'warn' });
      });
      is scalar(@warnings), $expected, "warnings, $name";
      like $warnings[0], qr{brand "foo" has no $name directories}, "message, $name"
         if $expected;
   }
};

subtest 'rainy: individual is not a hash reference' => sub {
   for my $case (['string', 'brands'], ['array ref', ['brands/foo']]) {
      my ($name, $individual) = $case->@*;
      eval { t_for({%generic}, {individual => $individual}) };
      like $@, qr{individual requires a hash reference}, "croaks on $name";
   }
};

subtest 'rainy: brands is not a hash reference' => sub {
   for my $brands ('foo', ['brands/foo']) {
      eval { t_for({%generic}, {individual => {brands => $brands}}) };
      like $@, qr{invalid brands in individual}, "croaks on <$brands>";
   }
};

# with many brands, e.g. from environment variables, the error must say
# where the problem is
subtest 'rainy: invalid paths are reported with their location' => sub {
   for my $case (
         ['empty brand spec', brands(foo => ''), qr{invalid empty path},
            [qr{brand 'foo'}]],
         ['empty item', brands(foo => ['brands/foo', '']), qr{invalid empty path},
            [qr{brand 'foo'}]],
         ['hash ref item', brands(foo => [{}]), qr{invalid path},
            [qr{brand 'foo'}]],
         ['empty sub-spec item', brands(foo => {public => ['']}),
            qr{invalid empty path}, [qr{brand 'foo'}, qr{\bpublic\b}]],
         ['empty global', {global => ''}, qr{invalid empty path},
            [qr{\bglobal\b}]],
         ['empty global sub-spec item', {global => {templates => ['']}},
            qr{invalid empty path}, [qr{\bglobal\b}, qr{\btemplates\b}]]) {
      my ($name, $conf, $error, $where) = $case->@*;
      eval { t_for({%generic, %foo}, $conf) };
      like $@, $error, "croaks on $name";
      like $@, $_, "location in message, $name" for $where->@*;
   }
};

# nothing must change in the application if the configuration is invalid
subtest 'rainy: invalid individual leaves global alone' => sub {
   my %files = (%generic, %foo, 'global/templates/index.html.ep' => 'global page',
      'global/public/site.css' => 'global css');
   for my $case (
         ['unknown individual key', {bogus => 1}],
         ['unknown brand key', {brands => {foo => {bogus => 1}}}],
         ['invalid brand path', {brands => {foo => ['']}}],
         ['stash_key conflict', {stash_key => 'other'}]) {
      my ($name, $individual) = $case->@*;
      my $t = t_for(\%files, {individual => {brands => {foo => 'brands/foo'}}});
      my $app = $t->app;
      my @renderer = @{$app->renderer->paths};
      my @static   = @{$app->static->paths};
      ok !eval { $app->plugin(Branding =>
         {global => 'global', individual => $individual}); 1 }, "croaks, $name";
      is_deeply $app->renderer->paths, \@renderer, "renderer paths, $name";
      is_deeply $app->static->paths, \@static, "static paths, $name";
      $t->get_ok('/')->content_is("generic page\n", "page, $name");
   }
};

subtest 'rainy: retry after an invalid configuration' => sub {
   my $t = t_for({%generic, 'global/templates/index.html.ep' => 'global page'}, {});
   my $app = $t->app;
   eval { $app->plugin(Branding => {global => 'global', individual => {bogus => 1}}) };
   $app->plugin(Branding => {global => 'global'});
   my $global = $app->home->child('global', 'templates');
   is scalar(grep { $_ eq $global } @{$app->renderer->paths}), 1,
      'global templates added once';
   $t->get_ok('/')->content_is("global page\n");
};

subtest 'rainy: invalid brand specifications' => sub {
   my $invalid = qr{invalid path, either Mojo::File or plain string};
   for my $case (
         ['code ref spec', sub {}, qr{invalid specification for brand 'foo'}],
         ['hash ref paths', {paths => {}}, $invalid],
         ['array ref item', [[1]], $invalid],
         ['hash ref item', [{}], $invalid],
         ['hash ref sub-spec item', {templates => [{}]}, $invalid],
         ['empty string item', [''], qr{invalid empty path}],
         ['empty string spec', '', qr{invalid empty path}],
         ['empty sub-spec item', {public => ['']}, qr{invalid empty path}],
         ['unknown brand key', {templat => {}},
            qr{unknown keys in brand 'foo': templat}],
         ['unknown sub-spec key', {templates => {ignore => 1}},
            qr{unknown keys in templates for brand 'foo': ignore}]) {
      my ($name, $spec, $error) = $case->@*;
      eval { t_for({%generic, %foo}, brands(foo => $spec)) };
      like $@, $error, "croaks on $name";
   }
};

# a 0.002 config used individual => {paths => ...}, now brands
subtest 'rainy: unknown keys in individual and at the top level' => sub {
   for my $case (
         ['0.002 paths', {individual => {paths => ['brands']}},
            qr{unknown keys.*\bpaths\b}],
         ['brand instead of brands',
            {individual => {brand => {foo => 'brands/foo'}}},
            qr{unknown keys.*\bbrand\b}],
         ['globals instead of global', {globals => ['global']},
            qr{unknown keys.*\bglobals\b}]) {
      my ($name, $conf, $error) = $case->@*;
      eval { t_for({%generic, %foo}, $conf) };
      like $@, $error, "croaks on $name";
   }
};

subtest 'rainy: stash_key changed in a later registration' => sub {
   my $t = t_for({%generic, %foo},
      {individual => {brands => {foo => 'brands/foo'}, stash_key => 'tenant'}},
      brand_hook('tenant'));
   eval { $t->app->plugin(Branding => {individual => {stash_key => 'other'}}) };
   like $@, qr{stash_key 'other' conflicts with 'tenant'},
      'croaks on a different stash_key';
   ok eval { $t->app->plugin(Branding => {individual => {stash_key => 'tenant'}}); 1 },
      'same stash_key is fine' or diag $@;
   ok eval { $t->app->plugin(Branding => {individual => {}}); 1 },
      'no stash_key inherits the first one' or diag $@;
   $t->get_ok('/' => \%FOO)->content_is("foo page\n");
};

done_testing();
