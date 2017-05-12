use Perlilog;
init;

$top = verilog->new(name => 'top');

$ff = template->new(name => 'flipflop',
		    tfile => 'myff.pt',
		    parent => $top);

$test = template->new(name => 'test',
		      tfile => 'mytest.pt',
		      parent => $top);

interface($ff->getport('ffport'), $test->getport('testport'));

execute;

silos->new(name => 'silos_configfile_creator')->makesilosfile;


