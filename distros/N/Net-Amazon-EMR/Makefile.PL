use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Amazon::EMR',
    AUTHOR              => q{Jon Schutz <jon.schutz@youramigo.com>},
    VERSION_FROM        => 'lib/Net/Amazon/EMR.pm',
    ABSTRACT_FROM       => 'lib/Net/Amazon/EMR.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'blib'                         => 0,
        'Data::Dumper'                 => 0,
        'DateTime'                     => 0,
        'DateTime::Format::ISO8601'    => 0,
        'DateTime::Format::Builder'    => 0,
        'Digest::SHA'                  => 0,
        'Exception::Class'             => 0,
        'LWP::Protocol::https'         => 0,
        'LWP::UserAgent'               => 0,
        'Log::Log4perl'                => 0,
        'MIME::Base64'                 => 0,
        'Moose'                        => 0.38,
        'Moose::Role'                  => 0.0,
        'Moose::Util::TypeConstraints' => 0,
        'MooseX::Params::Validate'     => 0,
        'MooseX::Log::Log4perl'        => 0,
        'Net::Amazon::EC2'             => '0.22',
        'POSIX'                        => 0,
        'Params::Validate'             => 0,
        'Test::More'                   => 0,
        'URI'                          => 0,
        'URI::Escape'                  => 0,
        'XML::Simple'                  => 2.18,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Amazon-EMR-*' },
);
