use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Net::DAAP::Server::AAC',
    'VERSION_FROM' => 'lib/Net/DAAP/Server/AAC.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
        Net::DAAP::Server => 0.03,
        MP4::Info => 1.05,
    },
);
