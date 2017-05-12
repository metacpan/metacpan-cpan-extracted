use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Net::XIPCloud',
    'VERSION_FROM' => 'XIPCloud.pm', # finds $VERSION
    'PREREQ_PM' => {
       'LWP::UserAgent' => '0',
       'IO::Socket::SSL' => '0',
       'File::stat' => '0',
       'HTTP::Request' => '0',
       'Data::Dumper' => '0',
       'Fcntl' => '0'
    }
);
