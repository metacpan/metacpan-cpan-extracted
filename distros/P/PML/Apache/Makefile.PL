package Apache::mod_pml;

use ExtUtils::MakeMaker;
use Apache::ExtUtils qw(command_table);
use Apache::src ();

my @directives = (
	{
		'name'		=> 'PMLStore',
		'errmsg'	=> 'turn storing on or off',
		'args_how'	=> 'TAKE1',
		'req_override'	=> 'OR_OPTIONS',
		'func'		=> 'apache_config_callback_pmlstore',
	},
);

command_table(\@directives);

WriteMakefile(
    'NAME'		=> __PACKAGE__,
    'VERSION_FROM'	=> 'mod_pml.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'INC'		=> Apache::src->new->inc,
);
