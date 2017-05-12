use Perlilog;
init;

$top = template->new(name => 'top',
		      tfile => 'top.pt');

$test = template->new(name => 'test',
		      tfile => 'wb_master.pt',
		      parent => $top);

$rom1 = template->new(name => 'rom1',
		      tfile => 'perl_rom.pt',
		      parent => $top,
		      romdata => [69, 108, 105, 10]);

$rom1->getport('wbport')->const('wb_adr_bits', 2);
$rom1->getport('wbport')->const('wb_adr_select', 0);

$rom2 = template->new(name => 'rom2',
		      tfile => 'perl_rom.pt',
		      parent => $top,
		      romdata => [65, 66, 67, 10]);

$rom2->getport('wbport')->const('wb_adr_bits', 2);
$rom2->getport('wbport')->const('wb_adr_select', 1);


interface($rom1->getport('wbport'), $rom2->getport('wbport'),
	  $test->getport('wbport'), $top->getport('clkrst'));

execute;

silos->new(name => 'silos_configfile_creator')->makesilosfile;


