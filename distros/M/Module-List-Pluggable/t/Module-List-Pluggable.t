# Before "make install" is performed this script should be runnable with
#   "make test".
# After "make install" it should work as
#   "perl Module-List-Pluggable.t"

use warnings;
use strict;
$|=1;
my $DEBUG = 0;
use Data::Dumper;

use Test::More;
BEGIN { plan tests => 23 };

use File::Find;
use FindBin qw($Bin);

# There's an argument that this is more robust (so let's do both)
use vars qw( $RealBin );
BEGIN {
  use File::Spec::Functions qw( rel2abs splitpath catpath);
  $RealBin = catpath ((splitpath (rel2abs ($0)))[0,1]);
}

use lib "../../List-Filter/lib"; # development only
use lib "$Bin/../lib", "$RealBin/../lib";
use lib "$Bin/dat/lib", "$RealBin/dat/lib";

my $test_lib = "$Bin/dat/lib"; # same as use lib value above

#1
BEGIN {
  use_ok( 'Module::List::Pluggable', ':all');
}

# 2
ok(1, "Traditional: If we made it this far, we're ok.");

($DEBUG) && print STDERR "test_lib: $test_lib\n";

{#3, #4
  my $testname = "Testing list_modules_under";
  my @modules_via_file_find = ();
  my $module_count_file_find = 0;

  my @dirs = ("$test_lib/Nada");
  find( sub {
          push @modules_via_file_find, $File::Find::name if m{\.pm$}x;
        }, @dirs);

  $module_count_file_find = scalar( @modules_via_file_find );

  my $plugin_root = 'Nada';
  my $plugin_exceptions = [ 'Nada::Zero' ];

  my @expected_modules = sort qw(
                                  Nada::Nuttin
                                  Nada::Zero
                                  Nada::Zip
                                  Nada::Zip::Bupkes
                               );
  # Excludes "Nada" itself, because we're looking under "Nada::"

  my $modules =  list_modules_under($plugin_root);
  ($DEBUG) && print "plugins: ", Dumper($modules), "\n";

  my @mods = @{ $modules };
  my $count = scalar( @mods );
  is( $count, $module_count_file_find,
      "$testname: number of modules looks right: $count");

  my @modules_sorted = sort @mods ;
  is_deeply( \@modules_sorted, \@expected_modules,
             "$testname: names of modules look right" );
}

{#5, 6
  my $testname = "Testing import_modules: using a sub from a plugin";
  my $plugin_root = "DummyPlugins";
  my $plugin_exceptions = undef;

  import_modules( $plugin_root,
                  { exceptions => $plugin_exceptions,
                  } );

  my $result = nothing_much({});
  is( $result, "Nothing much. What's with you?", "$testname: nothing_much");

  my $string = 'Ut!';
  $result = back_atcha({}, $string);
  is( $result, "Do you say: $string", "$testname: back_atcha");

}

SKIP:
{#7, #8
  my $testname = "Testing import_modules: using a module that uses a sub from a plugin";

  my $how_many = 2;
  my $test_module = 'DummyProject::Modulular::Stuff';
  eval "require $test_module";
  skip "because $test_module is not available ", $how_many if $@;

  my $plugin_root = "DummyPlugins";
  my $plugin_exceptions  = undef;

  my $obj = DummyProject::Modulular::Stuff->new(
                                   { plugin_root        => $plugin_root,
                                     plugin_exceptions  => $plugin_exceptions,
                                   });

  ok( $obj->test_method_nothing_much(),
      "$testname: nothing_much");

  ok( $obj->test_method_back_atcha('Ooga'),
      "$testname: back_atcha");
}

SKIP:
{#9
  my $testname = "Testing import_modules: importing a routine from the List::Filter project.";

  my $plugin_root = "List::Filter::Filters";
  my $plugin_exceptions = undef;

  # if there are no plugins located there, just skip this test.
  my $modules =  list_modules_under($plugin_root);
  ($DEBUG) && print "plugins: ", Dumper($modules), "\n";
  my $count = scalar( @{ $modules } );
  unless( $count ) {
    skip "because the List::Filter plugins are not available.", 1;
  }

  import_modules( $plugin_root,
                  { exceptions => $plugin_exceptions,
                  } );

  my $aref_in = [ qw(
                    blah.vb
                    bah.js
                    real_stuff.pl
                    GoodStuff.pm
                    fergetit.vb
                    okay.txt
                    README.not
                 ) ];

  my $regexps = ['\.vb$', '\.js$'];
  my $aref_out = skip_any( {}, { terms=>$regexps }, $aref_in );

  my @expected = sort( (
                        'real_stuff.pl',
                        'GoodStuff.pm',
                        'okay.txt',
                        'README.not',
                      ) );


  my @result = sort @{ $aref_out };

  is_deeply( \@result, \@expected, "$testname");
}

{#10
  my $testname = "Testing list_exports";
  my $plugin_root = "DummyPlugins";

  my $methods = list_exports( $plugin_root );

  ($DEBUG) && print STDERR Dumper( $methods ), "\n";

  my @methods = sort @{ $methods };

  my @expected = (
                  'back_atcha',
                  'nothing_much',
                 );

  is_deeply(\@methods, \@expected,
            "$testname");
}

{#11

  my $testname = "Testing report_export_locations";
  my $plugin_root = "DummyPlugins";

  my $report = report_export_locations( $plugin_root );

  ($DEBUG) && print STDERR Dumper( $report ), "\n";

  my $expected = {
          'back_atcha' => [
                            'DummyPlugins::SomeSubs'
                          ],
          'nothing_much' => [
                              'DummyPlugins::SomeSubs'
                            ]
        };

  is_deeply( $report, $expected, "$testname");
}

{#12

  my $testname = "Testing report_export_locations again";
  my $plugin_root = "Clash::Stub::Plugins";

  my $report = report_export_locations( $plugin_root );

  ($DEBUG) && print STDERR Dumper( $report ), "\n";

  my $expected = {
          'back_atcha' => [
                            'Clash::Stub::Plugins::Alpha'
                          ],
          'maximal_nihilility' => [
                                    'Clash::Stub::Plugins::Epsilon'
                                  ],
          'nada' => [
                      'Clash::Stub::Plugins::Gamma'
                    ],
          'accidents_happen' => [
                                  'Clash::Stub::Plugins::Beta',
                                  'Clash::Stub::Plugins::Gamma'
                                ],
          'parrot_but_not_that_parrot' => [
                                            'Clash::Stub::Plugins::Alpha'
                                          ],
          'much_bupkes' => [
                             'Clash::Stub::Plugins::Beta'
                           ],
          'nothing_much' => [
                              'Clash::Stub::Plugins::Alpha'
                            ]
        };

  @{ $report->{accidents_happen} } = sort @{ $report->{accidents_happen} };

  is_deeply( $report, $expected, "$testname");
}

{#13, #14

  my $testname = "Testing check_plugin_exports";

  my $plugin_root = "Clash::Stub::Plugins";

  my $err_mess = '';
  my $ret = 0;
  eval {

    $ret =
      check_plugin_exports( $plugin_root );
  };
  if ($@) {
    $err_mess = $@;
  }
  is( $ret, 0, "$testname: return code indicates conflict");

  ($DEBUG) && print STDERR "check_plugin_exports:\n$err_mess\n";

  like( $err_mess,
        qr{ ^ Multiple \s+ definitions  \s+ of  \s+ (\w*?) \s+ from \s+ plugins: \s+ }x,
        "$testname: error message looks right");

}

{#15, #16

  my $testname = "Testing check_plugin_exports using exceptions to fix problem";

  my $plugin_root = "Clash::Stub::Plugins";
  my $plugin_exceptions = ['Clash::Stub::Plugins::Beta'];

  my $err_mess = '';
  my $ret = 0;
  eval {

    $ret =
      check_plugin_exports( $plugin_root,
                                  { exceptions => $plugin_exceptions,
                                    });
  };
  if ($@) {
    $err_mess = $@;
  }

  is( $ret, 1, "$testname: return code looks good");

  ($DEBUG) && print STDERR "check_plugin_exports:\n$err_mess\n";

  is( $err_mess, '', "$testname: no error message.");
}

{#17, #18, #19, #20, #21

  my $testname = "Testing import_modules using exceptions to dodge conflict";

  my $plugin_root = "Clash::Stub::Plugins";
  my $plugin_exceptions = ['Clash::Stub::Plugins::Beta'];

  print STDERR "\nNOTE: You may see some \"Subroutine redefined\" warnings: these can be ignored\n";

  my $err_mess = '';
  my $ret = 0;
  eval {
    $ret =
      import_modules( $plugin_root,
                      { exceptions => $plugin_exceptions,
                      } );
  };
  if ($@) {
    $err_mess = $@;
  }
  print STDERR "\n";

  cmp_ok($ret, '>=', 1,
         "$testname: positive count of imported modules: $ret");

  is( $err_mess, '', "$testname: no error message.");

  my $result = nothing_much({});
  is( $result, "Nothing much. What's with you?", "$testname: nothing_much");

  my $string = 'Ut!';
  $result = back_atcha({}, $string);
  is( $result, "Do you say: $string", "$testname: back_atcha");

  chomp(
        my $quip = accidents_happen({})
       );
  $quip =~ s{ ^ \s* }{}x;
  is( $quip, "But sometimes they happen on purpose.", "$testname: accidents_happen");
}

{#22
  my $testname = "Testing that import_modules tosses error on export conflict";
  my $plugin_root = "Clash::Stub::Plugins";

  my $err_mess = '';
  my $ret = 0;
  eval {
    $ret =
      import_modules( $plugin_root );
  };
  if ($@) {
    $err_mess = $@;
  }

  # my $DEBUG = 1;
  ($DEBUG) && print STDERR "import_modules:\n$err_mess\n";

  like( $err_mess,
        qr{ ^ Multiple \s+ definitions  \s+ of  \s+ (\w*?) \s+ from \s+ plugins: \s+ }x,
        "$testname: error message looks right");
}

{#23
  my $testname = "Testing that import_modules of a broken plugin reports problem.";

  my $plugin_root = 'Tree::Limb';

  my $err_mess = '';
  my $ret = 0;
  eval {

    $ret =
      import_modules( $plugin_root );
  };
  if ($@) {
    $err_mess = $@;
  }

  # my $DEBUG = 1;
  ($DEBUG) && print STDERR "$err_mess\n";

   like( $err_mess,
         qr{ \b report_export_locations: \s+ Tree::Limb::Broken: \s+ }x,
         "$testname: error message looks right");
}
