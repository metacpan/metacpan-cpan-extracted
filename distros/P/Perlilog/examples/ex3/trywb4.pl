use Perlilog;
init;

$top = template->new(name => 'top',
		      tfile => 'top.pt');

$test = template->new(name => 'test',
		      tfile => 'wb_master.pt',
		      parent => $top);

$unit1 = template->new(name => 'adder',
		       tfile => 'adder.pt',
		       parent => $top);

$unit1->getport('theport')->const('wb_adr_bits', 2);
$unit1->getport('theport')->const('wb_adr_select', 0);

$unit2 = template->new(name => 'logic',
		       tfile => 'logic.pt',
		       parent => $top);

$unit2->getport('theport')->const('wb_adr_bits', 2);
$unit2->getport('theport')->const('wb_adr_select', 1);


interface($unit1->getport('theport'), $unit2->getport('theport'),
	  $test->getport('wbport'), $top->getport('clkrst'));

execute;

silos->new(name => 'silos_configfile_creator')->makesilosfile;


