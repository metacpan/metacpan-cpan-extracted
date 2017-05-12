use Perlilog;
init;

$top = template->new(name => 'top',
		      tfile => 'top.pt');

$test = template->new(name => 'test',
		      tfile => 'wb_master.pt',
		      parent => $top);

$rom = template->new(name => 'rom',
		     tfile => 'simple_rom.pt',
		     parent => $top);

interface($rom->getport('wbport'), $test->getport('wbport'),
	  $top->getport('clkrst'));

execute;

silos->new(name => 'silos_configfile_creator')->makesilosfile;


