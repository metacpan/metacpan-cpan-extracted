use Test::More tests => 10;

use Module::Install::GetProgramLocations;
use Config;

my $path_to_perl = $Config{perlpath};

#1
my $gpls = new Module::Install::GetProgramLocations;
ok(defined $gpls, 'Module::Install::GetProgramLocations creation');

#2
ok($gpls->version_matches_range('1.0.2', '[1.0,)'), 'Greater than minimum');

#3
ok($gpls->version_matches_range('1.0.2', '(,1.4)'), 'Less than maximum');

#4
ok(!$gpls->version_matches_range('1.0.2', '(1.0.2,1.4)'), 'Not equal boundary');

#5
ok($gpls->version_matches_range('1.0.2', '[1.0.2,1.4)'), 'Equal boundary');

#6
ok($gpls->version_matches_range('1.0.2', '[1.0,)'), 'Greater than minimum subversion');

#7
ok($gpls->version_matches_range('1.0.2', '[0.5,0.8] (1.0,1.4)'), 'In second range');

#8
ok(!$gpls->version_matches_range('1.9.2', '[1,1.7], [1.8,1.9]'), 'Not in two ranges');

{
  my %info = (
    'TestProgram' => { types => {
                         'Test' => { fetch => \&Get_Test_Program_Version,
                                     numbers => '[1.2.3,)', },
                       },
                     },
  );

  # 9
  ok($gpls->Module::Install::GetProgramLocations::_program_version_is_valid(
    'TestProgram',"$path_to_perl t/dummy_program.pl",\%info),
    'Check valid program version');
}

{
  my %info = (
    'TestProgram' => { types => {
                         'Test' => { fetch => \&Get_Test_Program_Version,
                                     numbers => '[1.2.4,)', },
                       },
                     },
  );

  # 10
  ok(!$gpls->Module::Install::GetProgramLocations::_program_version_is_valid(
    'TestProgram',"$path_to_perl t/dummy_program.pl",\%info),
    'Check invalid program version');
}

#--------------------------------------------------------------------------------

sub Get_Test_Program_Version
{
  my $program = shift;
  
  my $version = `$program`;
  chomp $version;

  return $version;
}
