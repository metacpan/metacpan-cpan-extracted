#!/usr/bin/perl

use strict;
use warnings;
no warnings 'uninitialized';

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Shell-EnvImporter.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 744; 
BEGIN { use_ok('Shell::EnvImporter') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


##############################################################################
# Config variables
#

my $file        = 't/test_script';
my $sh_script   = "ADD_VAR=1;MOD_VAR=1;unset DEL_VAR;export ADD_VAR MOD_VAR DEL_VAR";
my $csh_script  = "setenv ADD_VAR 1; setenv MOD_VAR 1; unsetenv DEL_VAR";
my $perl_script = '$ENV{"MOD_VAR"}=1;$ENV{"ADD_VAR"}=1;delete $ENV{"DEL_VAR"};';

my %scripts = (
  sh    => $sh_script,
  bash  => $sh_script,
  zsh   => $sh_script,

  # ksh   => $sh_script,  # Untested, as I don't have ksh

  csh   => $csh_script,
  tcsh  => $csh_script,

  perl  => $perl_script, # just for grins :)
);


##############################################################################
# Just Do Me
#


# 1. The simplest case:  source a Bourne-shell script and auto-import
#    added or modified environment variables
&run_test(
  'sh script auto-import' => {
    setup => sub {
      open(FILE, ">$file") or die "Couldn't create $file: $!";
      print FILE "$sh_script\n";
      close(FILE);
    },
    run => sub {
      my $importer = Shell::EnvImporter->new(
        file => $file,
      );
      return $importer;
    },
    cleanup => sub {
      unlink($file);
    },
    modified => {
      MOD_VAR => 1,
    },
    added => {
      ADD_VAR => 1,
    },
    removed => {
      DEL_VAR => undef,
    },
    imported => [qw(MOD_VAR ADD_VAR)],
  },
);

# 2. The next simplest case:  run some Bourne-shell commands and auto-import
#    added or modified environment variables
&run_test(
  'sh command auto-import' => {
    setup => sub { },
    run => sub {
      my $importer = Shell::EnvImporter->new(
        command => $sh_script,
      );
      return $importer;
    },
    cleanup => sub { },
    modified => {
      MOD_VAR => 1,
    },
    added => {
      ADD_VAR => 1,
    },
    removed => {
      DEL_VAR => undef,
    },
    imported => [qw(MOD_VAR ADD_VAR)],
  },
);




# 3. Run the following tests under each shell
foreach my $shell (sort keys %scripts) {

  # - Simple auto-import from a file
  &run_test(
    "$shell script auto-import" => {
      setup => sub {
        open(FILE, ">$file") or die "Couldn't create $file: $!";
        print FILE $scripts{$shell}, "\n";
        close(FILE);
      },
      run => sub {
        my $importer = Shell::EnvImporter->new(
          file  => $file,
          shell => $shell,
        );
        return $importer;
      },
      cleanup => sub {
        unlink($file);
      },
      modified => {
        MOD_VAR => 1,
      },
      added => {
        ADD_VAR => 1,
      },
      removed => {
        DEL_VAR => undef,
      },
      imported => [qw(MOD_VAR ADD_VAR)],
    },
  );

  # - Simple auto-import from commands
  &run_test(
    "$shell command auto-import" => {
      setup => sub { },
      run => sub {
        my $importer = Shell::EnvImporter->new(
          command => $scripts{$shell},
          shell   => $shell,
        );
        return $importer;
      },
      cleanup => sub { },
      modified => {
        MOD_VAR => 1,
      },
      added => {
        ADD_VAR => 1,
      },
      removed => {
        DEL_VAR => undef,
      },
      imported => [qw(MOD_VAR ADD_VAR)],
    },
  );

  # - Policy auto-import -- modified only
  &run_test(
    "$shell command auto-import -- modified only" => {
      setup => sub { },
      run => sub {
        my $importer = Shell::EnvImporter->new(
          command         => $scripts{$shell},
          shell           => $shell,
          import_modified => 1,
          import_added    => 0,
          import_removed  => 0,
        );
        return $importer;
      },
      cleanup => sub { },
      modified => {
        MOD_VAR => 1,
      },
      added => {
        ADD_VAR => 1,
      },
      removed => {
        DEL_VAR => undef,
      },
      imported => [qw(MOD_VAR)],
    },
  );


  # - Policy auto-import -- added only
  &run_test(
    "$shell command auto-import -- added only" => {
      setup => sub { },
      run => sub {
        my $importer = Shell::EnvImporter->new(
          command         => $scripts{$shell},
          shell           => $shell,
          import_modified => 0,
          import_added    => 1,
          import_removed  => 0,
        );
        return $importer;
      },
      cleanup => sub { },
      modified => {
        MOD_VAR => 1,
      },
      added => {
        ADD_VAR => 1,
      },
      removed => {
        DEL_VAR => undef,
      },
      imported => [qw(ADD_VAR)],
    },
  );



  # - Policy auto-import -- removed only
  &run_test(
    "$shell command auto-import -- removed only" => {
      setup => sub { },
      run => sub {
        my $importer = Shell::EnvImporter->new(
          command         => $scripts{$shell},
          shell           => $shell,
          import_modified => 0,
          import_added    => 0,
          import_removed  => 1,
        );
        return $importer;
      },
      cleanup => sub { },
      modified => {
        MOD_VAR => 1,
      },
      added => {
        ADD_VAR => 1,
      },
      removed => {
        DEL_VAR => undef,
      },
      imported => [qw(DEL_VAR)],
    },
  );


  # - Filter auto-import -- removed only
  &run_test(
    "$shell command auto-import -- removed only" => {
      setup => sub { },
      run => sub {
        my $importer = Shell::EnvImporter->new(
          command         => $scripts{$shell},
          shell           => $shell,
          import_filter   => sub {
                               my($var, $value, $change) = @_;
                               return ($change eq 'removed');
                             },
          import_modified => 0,
          import_added    => 0,
          import_removed  => 1,
        );
        return $importer;
      },
      cleanup => sub { },
      modified => {
        MOD_VAR => 1,
      },
      added => {
        ADD_VAR => 1,
      },
      removed => {
        DEL_VAR => undef,
      },
      imported => [qw(DEL_VAR)],
    },
  );


  # - Policy manual import
  &run_test(
    "$shell manual import by policy" => {
      setup => sub { },
      run => sub {
        my $importer = Shell::EnvImporter->new(
          command         => $scripts{$shell},
          shell           => $shell,
          auto_import     => 0,
          import_modified => 1,
          import_added    => 1,
          import_removed  => 1,
        );

        $importer->env_import();
        return $importer;
      },
      cleanup => sub { },
      modified => {
        MOD_VAR => 1,
      },
      added => {
        ADD_VAR => 1,
      },
      removed => {
        DEL_VAR => undef,
      },
      imported => [qw(MOD_VAR ADD_VAR DEL_VAR)],
    },
  );



  # - Manual import by list
  &run_test(
    "$shell manual import by list" => {
      setup => sub { },
      run => sub {
        my $importer = Shell::EnvImporter->new(
          command         => $scripts{$shell},
          shell           => $shell,
          auto_import     => 0,
        );

        $importer->env_import('MOD_VAR', 'ADD_VAR');
        return $importer;
      },
      cleanup => sub { },
      modified => {
        MOD_VAR => 1,
      },
      added => {
        ADD_VAR => 1,
      },
      removed => {
        DEL_VAR => undef,
      },
      imported => [qw(MOD_VAR ADD_VAR)],
    },
  );


  # - Manual import by arrayref
  &run_test(
    "$shell manual import by arrayref" => {
      setup => sub { },
      run => sub {
        my $importer = Shell::EnvImporter->new(
          command         => $scripts{$shell},
          shell           => $shell,
          auto_import     => 0,
          import_removed  => 0,
        );

        # Note: DEL_VAR should NOT be imported due to policy
        $importer->env_import('MOD_VAR', 'ADD_VAR', 'DEL_VAR');
        return $importer;
      },
      cleanup => sub { },
      modified => {
        MOD_VAR => 1,
      },
      added => {
        ADD_VAR => 1,
      },
      removed => {
        DEL_VAR => undef,
      },
      imported => [qw(MOD_VAR ADD_VAR)],
    },
  );


  # - Manual import by filter
  &run_test(
    "$shell manual import by filter" => {
      setup => sub { },
      run => sub {
        my $importer = Shell::EnvImporter->new(
          command         => $scripts{$shell},
          shell           => $shell,
          auto_import     => 0,
          import_removed  => 0,
        );

        # Note: filter should override import_removed and import DEL_VAR
        $importer->env_import_filtered(
          sub {
            my($var, $value, $change) = @_;
            if (
              ($var eq 'MOD_VAR' or $var eq 'DEL_VAR') and
              ($change eq 'modified' or $change eq 'removed') and
              (! defined($value) or $value == 1)
            ) {
              return 1;
            } else {
              return 0;
            }
          }
        );
        return $importer;
      },
      cleanup => sub { },
      modified => {
        MOD_VAR => 1,
      },
      added => {
        ADD_VAR => 1,
      },
      removed => {
        DEL_VAR => undef,
      },
      imported => [qw(MOD_VAR DEL_VAR)],
    },
  );


  # - Manual run with supplied command
  &run_test(
    "$shell manual run with supplied command" => {
      setup => sub { },
      run => sub {
        my $importer = Shell::EnvImporter->new(
          shell           => $shell,
          auto_run        => 0,
          auto_import     => 1,
        );

        $importer->run($scripts{$shell});

        return $importer;
      },
      cleanup => sub { },
      modified => {
        MOD_VAR => 1,
      },
      added => {
        ADD_VAR => 1,
      },
      removed => {
        DEL_VAR => undef,
      },
      imported => [qw(MOD_VAR ADD_VAR)],
    },
  );


  # - Manual intervention -- change shell params before running command
  &run_test(
    "$shell manual import by filter" => {
      setup => sub { },
      run => sub {
        my $importer = Shell::EnvImporter->new(
          command         => $scripts{$shell},
          shell           => $shell,
          auto_run        => 0,
        );

        my $shellobj = $importer->shellobj;
        $shellobj->ignore_push('MOD_VAR');

        $importer->run();  # ... and auto-import

        return $importer;
      },
      cleanup => sub { },
      modified => {
      },
      added => {
        ADD_VAR => 1,
      },
      removed => {
        DEL_VAR => undef,
      },
      imported => [qw(ADD_VAR)],
    },
  );

}



# 4. Test error handling

#  - Bogus shell
{
  my $testname = 'bogus shell failure test';
  my $errmsg   = "Can't locate \\S+NOSUCHSHELL.pm";

  my $importer = Shell::EnvImporter->new(
    command => $sh_script,
    shell   => 'NOSUCHSHELL',
  );

  ok(defined($@), "$testname -- failed")
    or diag("$testname failed to fail!");

  like($@, qr/$errmsg/, "$testname -- failed well")
    or diag("Bogus shell failure error message: $@");

}



#  - No command
{
  my $testname = 'no command failure test';
  my $errmsg1  = "Can't run without a command";
  my $errmsg2  = "Can't import before a successful run";
  my $errmsg3  = "Can't do filtered import without a filter";
  my $errmsg4  = "Can't restore before a successful run";


  # Auto-run and fail
  my $importer = Shell::EnvImporter->new();

  ok(defined($@), "$testname -- run failed")
    or diag("$testname run failed to fail!");

  like($@, qr/$errmsg1/, "$testname -- run failed well")
    or diag("Bogus run failure error message: $@");


  # Attempt an import without a successful run
  undef($@);
  $importer->env_import();

  ok(defined($@), "$testname -- import failed")
    or diag("$testname import failed to fail!");

  like($@, qr/$errmsg2/, "$testname -- import failed well")
    or diag("Bogus import failure error message: $@");


  # Attempt a filtered import without a filter
  undef($@);
  $importer->env_import_filtered();

  ok(defined($@), "$testname -- filtered import failed")
    or diag("$testname filtered import failed to fail!");

  like($@, qr/$errmsg3/, "$testname -- filtered import failed well")
    or diag("Bogus filtered import failure error message: $@");


  # Attempt a filtered import without a successful run
  undef($@);
  $importer->env_import_filtered(sub {1});

  ok(defined($@), "$testname -- filtered import failed")
    or diag("$testname filtered import failed to fail!");

  like($@, qr/$errmsg2/, "$testname -- import failed well")
    or diag("Bogus filtered import failure error message: $@");



  # Attempt an import without a successful run
  undef($@);
  $importer->restore_env();

  ok(defined($@), "$testname -- restore failed")
    or diag("$testname restore failed to fail!");

  like($@, qr/$errmsg4/, "$testname -- restore failed well")
    or diag("Bogus restore failure error message: $@");

}


#  - Nonexistent file
{
  my $filename = '/var/tmp/NOSUCHFILE';
  my $testname = 'bogus file failure test';
  my $errmsg   = "NOSUCHFILE: No such file or directory";

  my $importer = Shell::EnvImporter->new(
    file  => $filename,
  );
  my $rv = $importer->result;

  ok($rv->failed, "$testname -- died")
    or diag("$testname failed to die!");

  like($rv->stderr, qr/$errmsg/, "$testname -- died well")
    or diag("Bogus error message: $@");

}


# - Broken shell (bad constructor)
{
  use lib qw(t);
  my $testname = 'bad shell constructor';
  my $errmsg   = "Couldn't create shell object";

  my $importer = Shell::EnvImporter->new(
    command => 'true',
    shell   => 'bad_cons_shell',
  );

  ok(defined($@), "$testname -- constructor failed")
    or diag("$testname constructor failed to fail!");

  like($@, qr/$errmsg/, "$testname -- constructor failed well")
    or diag("Bogus constructor failure error message: $@");

}


# - Broken shell (no shell command)
{
  use lib qw(t);
  my $testname = 'bad shell command';
  my $errmsg   = "Command failed -- check status and output";

  my $importer = Shell::EnvImporter->new(
    command => 'true',
    shell   => 'bad_cmd_shell',
  );

  ok(defined($@), "$testname -- command failed")
    or diag("$testname command failed to fail!");

  like($@, qr/$errmsg/, "$testname -- command failed well")
    or diag("Bogus command failure error message: $@");

}




# 5. Miscellaneous tests

#  - Filename containing shell-special characters
{
  my $badname = 'f!>@$';
  &run_test(
    'sh script auto-import' => {
      setup => sub {
        open(FILE, ">$badname") or die "Couldn't create $badname: $!";
        print FILE "$sh_script\n";
        close(FILE);
      },
      run => sub {
        my $importer = Shell::EnvImporter->new(
          file => $badname,
        );
        return $importer;
      },
      cleanup => sub {
        unlink($badname);
      },
      modified => {
        MOD_VAR => 1,
      },
      added => {
        ADD_VAR => 1,
      },
      removed => {
        DEL_VAR => undef,
      },
      imported => [qw(MOD_VAR ADD_VAR)],
    },
  );

}



#  - Restore environment
{

  # Copy unmodified env
  my $env0 = &backup_env();


  # Test:
  # - Set up environment
  $ENV{'DEL_VAR'} = 1;
  $ENV{'MOD_VAR'} = 0;

  # - Make a copy of the modified environment
  my $envbak = &backup_env();

  # - Change env -- add a var, modify a var, delete a var
  my $importer = Shell::EnvImporter->new(
    command => $sh_script,
  );

  # - Restore env to copy
  $importer->restore_env();

  # At this point, the backup environment and %ENV should be the same
  is_deeply(\%ENV, $envbak, 'Restore env')
    or diag("Env and backup env differ");


  # Finally, restore the unmodified env (for subsequent tests, if any)
  &restore_env($env0);


}



# 6. Discovered bugs

#  - Test command that produces empty lines (thanks to G. Leclair)
{
  my $command = q{
    echo '*Warning*  Cycle.log files could not be used';
    echo '';
    echo '';
    echo 'Setting variables for main cycle';
    echo '/farequote/IntegrationK/OTFGenData/setPSCacheLinux was sourced';
    echo 'succesfully for FqA database';
  } . $sh_script;

  &run_test(
    'command that produces empty lines' => {
      setup => sub { },
      run => sub {
        my $importer = Shell::EnvImporter->new(
          shell => 'zsh',
          command => $command,
        );
        return $importer;
      },
      cleanup => sub {},
      modified => {
        MOD_VAR => 1,
      },
      added => {
        ADD_VAR => 1,
      },
      removed => {
        DEL_VAR => undef,
      },
      imported => [qw(MOD_VAR ADD_VAR)],
    },
  );

}


##############################################################################
###############################  Subroutines  ################################
##############################################################################


##############
sub run_test {
##############
  my $testname = shift;
  my $profile  = shift;

  my $envbak = &backup_env();

  # Set delvars and modvars to zero
  foreach my $var (keys %{$profile->{'modified'}}, keys %{$profile->{'removed'}}) {
    $ENV{$var} = 0;
  }

  # Make sure addvars don't exist in the current environment
  foreach my $var (keys %{$profile->{'added'}}) {
    delete($ENV{$var});
  }


  &{$profile->{'setup'}};


  my $importer = &{$profile->{'run'}};
  my $result   = $importer->result;


  &{$profile->{'cleanup'}};


  # Make sure the shell spawned cleanly
  ok($result->shell_status == 0, "$testname -- shell status")
    or diag("\t$testname\n\tShell exit status: " . $result->shell_status);


  # Make sure the shell command(s) executed cleanly
  ok($result->command_status == 0, "$testname -- command status")
    or diag("\t$testname\n\tCommand exit status: " . $result->command_status);


  # Make sure the env command executed cleanly
  ok($result->env_status == 0, "$testname -- env status")
    or diag("\t$testname\n\tEnv exit status: " . $result->env_status);


  # Check that all changes were expected and correct
  foreach my $var (sort $result->changed_keys) {
    my $type   = $result->changed_index($var)->type;
    my $newval = $result->changed_index($var)->value;

    # Did we expect the change?
    ok(exists($profile->{$type}->{$var}),  "$testname -- expected change")
      or diag("\t$testname\n\tUnexpected change: $var was $type (new value $newval)");

    # Is the change what we expected?
    if ($type ne 'removed') {
      my $expected = $profile->{$type}->{$var};
      ok($newval eq $expected, "$testname -- correct change")
        or diag("\t$testname\n\tIncorrect change:  $var should be $expected, is $newval");
    }

  }

  # Check that imports actually happened
  foreach my $var (@{$profile->{'imported'}}) {
    my $type   = $result->changed_index($var)->type;
    my $newval = $result->changed_index($var)->value;

    if ($type eq 'removed') {
      ok(! exists($ENV{$var}), "$testname -- removed variable")
        or diag("\t$testname\n\tImport error:  $var should've been removed, is $ENV{$var}");
    } else {
      ok($ENV{$var} eq $newval, "$testname -- $type variable")
        or diag("\t$testname\n\tImport error:  $var should be $newval, is $ENV{$var}");
    }
  }

  &restore_env($envbak);

}




################
sub backup_env {
################
  my %envbak;
  @envbak{keys %ENV} = values %ENV;

  return \%envbak;

}



#################
sub restore_env {
#################
  my $backup = shift;

  map(delete($ENV{$_}), keys %ENV);

  @ENV{keys %$backup} = values %$backup;

}

