use 5.00005;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Net::Jaiku',
    'VERSION_FROM'	=> 'lib/Net/Jaiku.pm',
    'PREREQ_PM'		=> {
		'Test::More'     =>  0,
		'LWP::UserAgent' =>  0.14,
		'JSON::Any'      => 0,
		'Params::Validate'	=> 0,
	},
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'lib/Net/Jaiku.pm',
       AUTHOR     => 'Rick Measham <rickm@cpan.org>') : ()),
);
