use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Net::RRP::Lite',
    'VERSION_FROM' => 'lib/Net/RRP/Lite.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
    },
);
