use 5.006;
use strict;
use warnings;
#use feature 'say';
use Module::Build;

##print "Enter 'y' to continue";
##my $go = <>;
##$go =~ /^[y]/  or  exit;

my $distro = 'SudokuTrainer';   # Name of the Distribution (without version suffix)
my $distrib = 'Games::Sudoku::Trainer';   # Namespace of the Distribution
(my $distdir = $distrib) =~ s#::#/#g;     # Dir. of the Distribution

my %args = (
    dist_name           => "$distro",
    dist_version        => '0.01.5',
	# Ohne Par. module_name kommt bei den Kommandos "perl Build.PL", 
	# "Build disttest" und "Build dist" die (sachlich falsche) Meldung
	# "No 'module_name' # was provided ...". Außerdem ist nach der Inst.
	# die Datei
	# ...\lib\perl5\MSWin32-x86-multi-thread\auto\Mymoddir\Mymod\.packlist
	# leer.
	# Das hat wohl nur Auswirkungen auf CPAN, das Modul kann bei lokaler
	# Inst. normal benutzt werden.
    module_name         => "Games::Sudoku::Trainer::Run",
    license             => 'perl',
    dist_author         => q{Klaus Wittrock <Wittrock@cpan.org>},
	dist_abstract       => 'Train on detecting successful Sudoku stategies.' . "\n"
	  . 'Also help to get over an obstacle while solving a Sudoku puzzle.',
#	release_status      => 'testing',
	release_status      => 'stable',
	script_files        => 'script',

#	meta_merge          => {
	meta_add            => {
		no_index => {
#		  file      => [ 'Games/Sudoku/Trainer/Found_info.pm' ],
		  file      => [
#              'Games/Sudoku/Trainer/Cell.pm',
#              'Games/Sudoku/Trainer/Check_pause.pm',
#              'Games/Sudoku/Trainer/Const_structs.pm',
#              'Games/Sudoku/Trainer/Found_info.pm',
#              'Games/Sudoku/Trainer/GUI.pm',
#              'Games/Sudoku/Trainer/GUIdetails.pm',
#              'Games/Sudoku/Trainer/Priorities.pm',
              'Games/Sudoku/Trainer/Run.pm',
#              'Games/Sudoku/Trainer/Strategies.pm',
          ],
#		  directory => [ 'My/Private' ],
		  package   => [ 
              'Games::Sudoku::Trainer::Cell',
#              'Games::Sudoku::Trainer::Check_pause',
#              'Games::Sudoku::Trainer::Const_structs',
#              'Games::Sudoku::Trainer::Found_info',
#              'Games::Sudoku::Trainer::GUI',
#              'Games::Sudoku::Trainer::GUIdetails',
#              'Games::Sudoku::Trainer::Strategies',
 ],
#		  namespace => [ 'My::Module::Sample' ],
		},
    },

    requires            => {
# wait  'perl' => 5.008001,
        'perl' => 0,
# wait  'Tk' => 804.029,
        'Tk' => 0,
#?        'Tk::Balloon' => 0,
#?        'Tk::ErrorDialog' => 0,
#        'Encode' => 0,
#?        'File::Basename' => 0,
#?        'Getopt::Long' => 0,
        'List::MoreUtils' => 0,
    },
	configure_requires  => { 'Module::Build' => 0.38 },
#dupl    create_makefile_pl => 'traditional',
);
#    $args{dist_version} !~ /_/  and  $args{create_makefile_pl} = "traditional";
    $args{dist_version} !~ /_/  and  $args{create_makefile_pl} = 'small';

	my $build = Module::Build->new(%args);
	$build->add_build_element('sudo');
    $build->create_build_script();
