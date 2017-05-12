use 5.008;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Net::UPCDatabase',
    'VERSION_FROM'	=> 'UPCDatabase.pm',
    'PREREQ_PM'		=> { Frontier::Client => 0, Frontier::RPC2 => 0 },
    ($] >= 5.005 ? ('AUTHOR' => 'Dusty Wilson <cpan-Net-UPCDatabase@dusty.hey.nu>') : ()),
    'LIBS'		=> [''],
    'DEFINE'		=> '',
    'INC'		=> '-I.',
);
