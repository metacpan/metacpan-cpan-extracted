use 5.012;
use autodie;
use Term::ANSIColor;
use Data::Dumper;

use FindBin qw($Bin); 
use lib "$Bin/../lib/";
use Proch::Cmd;

my $object = {
	'hello' => 'world',
	'list'  => ['a', 'b', 'c'],
};

# Test general settings for the module
my $settings = Proch::Cmd->new(
	command => '', 
	verbose => 1, 
	debug => 1
);


$settings->set_global('working_dir', '/hpc-home/telatina/tmp/');

my $c1 = Proch::Cmd->new(
		command => 'ls -lh /etc/passwd /etc/vimrc hello',
		input_files => ['/etc/passwd' , '/etc/vimrc', 'hello'],
		output_files => [],
		debug => 0,
		verbose => 0,
		object => \$object,
);

my $c2 = Proch::Cmd->new(command => 'find /root -name "mail*"',
		die_on_error => 0,
		save_stderr => 1);
 
my $simple = $c1->simplerun();
my $data = $c2->simplerun();

say $simple->{output};
say 'C1 run again: ', $c1->simplerun()->{output};

 