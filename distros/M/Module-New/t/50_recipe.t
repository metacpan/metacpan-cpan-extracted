use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use Module::New;
use Path::Tiny;

# for Dist

subtest normal_run_dist => sub {
  my $current = path('.')->absolute;
  my $testapp = setup_testapp_dist();

  test_recipe_dist('MyApp');

  test_files_dist($testapp->child('MyApp'));

  chdir $current;
  $testapp->remove_tree;
};

subtest no_dirs => sub {
  my $current = path('.')->absolute;
  my $testapp = setup_testapp_dist();

  Module::New->context->config->set( no_dirs => 1 );

  test_recipe_dist('MyApp');

  test_files_dist($testapp);

  chdir $current;
  $testapp->remove_tree;
};

subtest default_makemaker => sub {
  my $current = path('.')->absolute;
  my $testapp = setup_testapp_dist();

  test_recipe_dist('MyApp');

  my $maker = $testapp->child('MyApp/Makefile.PL');
  ok $maker->exists, 'Makefile.PL exists';
  ok grep(/ExtUtils::MakeMaker/, $maker->lines), 'and it uses ExtUtils::MakeMaker';

  chdir $current;
  $testapp->remove_tree;
};

subtest makemaker => sub {
  my $current = path('.')->absolute;
  my $testapp = setup_testapp_dist();

  Module::New->context->config->set( make => 'MakeMaker' );

  test_recipe_dist('MyApp');

  my $maker = $testapp->child('MyApp/Makefile.PL');
  ok $maker->exists, 'Makefile.PL exists';
  ok grep(/ExtUtils::MakeMaker/, $maker->lines), 'and it uses ExtUtils::MakeMaker';

  chdir $current;
  $testapp->remove_tree;
};

subtest module_build => sub {
  my $current = path('.')->absolute;
  my $testapp = setup_testapp_dist();

  Module::New->context->config->set( make => 'ModuleBuild' );

  test_recipe_dist('MyApp');

  my $maker = $testapp->child('MyApp/Build.PL');
  ok $maker->exists, 'Build.PL exists';
  ok grep(/Module::Build/, $maker->lines), 'and it uses Module::Build';

  chdir $current;
  $testapp->remove_tree;
};

subtest xs => sub {
  my $current = path('.')->absolute;
  my $testapp = setup_testapp_dist();

  Module::New->context->config->set( xs => 1 );

  test_recipe_dist('MyApp');

  ok $testapp->child('MyApp/MyApp.xs')->exists, 'main .xs exists';
  ok $testapp->child('MyApp/MyApp.h')->exists, 'main .h exists';
  SKIP: {
    eval { require Devel::PPPort };
    skip "requires Devel::PPPort", 1 if $@;
    ok $testapp->child('MyApp/ppport.h'), 'ppport.h exists';
  }
  my $main_pm = $testapp->child('MyApp/lib/MyApp.pm')->slurp;
  like $main_pm => qr/XSLoader/, 'MyApp.pm loads XSLoader';

  chdir $current;
  $testapp->remove_tree;
};

sub setup_testapp_dist {
  my ($path) = @_;

  $path ||= 't/TestApp';

  my $testapp = path($path)->absolute;
     $testapp->mkpath;
     $testapp->child('MyApp')->remove_tree;

  my $context = Module::New->setup('Module::New::ForTest');
  $context->path->set_root( $testapp->relative );
  $context->config->set( silent => 1 );

  return $testapp;
}

sub test_recipe_dist {
  my (@args) = @_;

  my $recipe = load_recipe_dist();
  local $@;
  eval { $recipe->run(@args) };
  ok !$@, 'created a distribution';
  diag $@ if $@;
}

sub load_recipe_dist {
  delete $INC{'Module/New/Recipe/Dist.pm'};
  require Module::New::Recipe::Dist;
  return 'Module::New::Recipe::Dist';
}

sub test_files_dist {
  my ($root) = @_;

  ok $root->child('lib/MyApp.pm')->exists, 'MyApp.pm exists';
  ok $root->child('README')->exists, 'README exists';
  ok $root->child('Changes')->exists, 'Changes exists';
  ok $root->child('MANIFEST')->exists, 'MANIFEST exists';
  ok $root->child('MANIFEST.SKIP')->exists, 'MANIFEST.SKIP exists';
  ok $root->child('t/00_load.t')->exists, 'load test exists';
  ok $root->child('xt/99_pod.t')->exists, 'pod test exists';
  ok $root->child('xt/99_podcoverage.t')->exists, 'pod coverage test exists';
}

# for File

subtest normal_run_file => sub {
  my $current = path('.')->absolute;
  my $testapp = setup_testapp_file();

  run_recipe_file('MyApp::File');

  ok $testapp->child('MANIFEST')->exists, 'MANIFEST is created';
  ok $testapp->child('lib/MyApp/File.pm')->exists, 'and the file is correct';

  chdir $current;
  $testapp->remove_tree;
};

subtest file_in_subdir => sub {
  my $current = path('.')->absolute;
  my $testapp = setup_testapp_file();

  Module::New->context->config->set( subdir => 't' );

  run_recipe_file('MyApp::File');

  ok $testapp->child('MANIFEST')->exists, 'MANIFEST is created';
  ok $testapp->child('MANIFEST')->exists, 'MANIFEST is created';
  ok !$testapp->child('t/MANIFEST')->exists, 'MANIFEST is not in t/';

  chdir $current;
  $testapp->remove_tree;
};

subtest testfile => sub {
  my $current = path('.')->absolute;
  my $testapp = setup_testapp_file();

  run_recipe_file('t/test.t');

  ok $testapp->child('MANIFEST')->exists, 'MANIFEST is created';
  ok $testapp->child('t/test.t')->exists, 'and the file is correct';
  ok grep(/use Test::More/, $testapp->child('t/test.t')->lines), 'and its content has "use Test::More"';

  chdir $current;
  $testapp->remove_tree;
};

subtest script => sub {
  my $current = path('.')->absolute;
  my $testapp = setup_testapp_file();

  run_recipe_file('bin/script');

  ok $testapp->child('MANIFEST')->exists, 'MANIFEST is created';
  ok $testapp->child('bin/script')->exists, 'and the file is correct';
  ok grep(/#!perl/, $testapp->child('bin/script')->lines), 'and its content has a shebang line';

  chdir $current;
  $testapp->remove_tree;
};

sub setup_testapp_file {
  my ($path) = @_;

  $path ||= 't/TestApp';

  my $testapp = path($path)->absolute;
     $testapp->mkpath;
     $testapp->child('Makefile.PL')->touch;
     $testapp->child('lib')->mkpath;

  my $context = Module::New->setup('Module::New::ForTest');
  $context->path->set_root( $testapp->relative );
  $context->config->set( silent => 1 );

  return $testapp;
}

sub run_recipe_file {
  my (@args) = @_;

  my $recipe = load_recipe_file();
  local $@;
  eval { $recipe->run(@args) };
  ok !$@, 'created a file';

  if ($@) {
    warn $@;
    Module::New->context->dump_logs;
  }
}

sub load_recipe_file {
  delete $INC{'Module/New/Recipe/File.pm'};
  require Module::New::Recipe::File;
  return 'Module::New::Recipe::File';
}

done_testing;
