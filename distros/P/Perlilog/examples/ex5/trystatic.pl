use Perlilog;
init;

$top = template->new(name => 'top',
		      tfile => 'top.pt');

$test = template->new(name => 'test',
		      tfile => 'wb_master.pt',
		      parent => $top);

$rom1 = template->new(name => 'rom1',
		      tfile => 'simple_rom.pt',
		      parent => $top);

$rom1->getport('wbport')->const('wb_adr_bits', 2);
$rom1->getport('wbport')->const('wb_adr_select', 0);

$rom2 = static->new(name => 'rom2',
		    source => 'therom.v',
		    parent => $top);

foreach $name ('zero', 'one', 'two', 'three') {
  $rom2->addvar($name, 'output', 'out', '[7:0]');
}

$romport = vars->new(name => 'JustSomeName',
		     parent => $rom2,
		     labels => [ r0 => 'zero',
				 r1 => 'one',
				 r2 => 'two',
				 r3 => 'three']);

$rom2->const(['user_port_names', 'wbport'], $romport);

$rom2->getport('wbport')->const('wb_adr_bits', 2);
$rom2->getport('wbport')->const('wb_adr_select', 1);


interface($rom1->getport('wbport'), $rom2->getport('wbport'),
	  $test->getport('wbport'), $top->getport('clkrst'));

execute;

silos->new(name => 'silos_configfile_creator')->makesilosfile;
