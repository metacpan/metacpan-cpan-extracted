use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'POEx::HTTP::Server',
    VERSION_FROM      => 'lib/POEx/HTTP/Server.pm',
    ABSTRACT_FROM     => 'lib/POEx/HTTP/Server.pm', 
    PREREQ_PM         => {
            'POE'           => 1,
            'POEx::URI'     => 0.0301,
            'POE::Session::Multiplex' => 0.0600,
            'POE::Session::PlainCall' => 0.0300,
            'Data::Dump'    => 1,
            'Scalar::Util'  => 0,
            'Storable'      => 1,
            'HTTP::Status' => 1,
            'HTTP::Request' => 1,
            'HTTP::Response' => 1,
            'HTTP::Date' => 1
		},
    AUTHOR            => 'Philip Gwyn <fil -at- cpan.org>',
    LICENSE           => 'perl',
    dist              => { COMPRESS=>'gzip -9f', EXT=>'gz'},
);
