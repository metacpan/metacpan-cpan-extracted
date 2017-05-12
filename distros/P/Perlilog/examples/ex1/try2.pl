use Perlilog;
init;

$test = template->new(name => 'test',
		      tfile => 'mytest.pt');

$ff = template->new(name => 'flipflop',
		    tfile => 'myff.pt',
		    parent => $test);

interface($ff->getport('ffport'), $test->getport('testport'));

execute;

silos->new(name => 'silos_configfile_creator')->makesilosfile;


