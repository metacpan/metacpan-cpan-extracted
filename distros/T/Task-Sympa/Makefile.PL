use strict;
use warnings;

use ExtUtils::MakeMaker;
use English qw(-no_match_vars);

my %args = (
    NAME          => 'Task-Sympa',
    ABSTRACT_FROM => 'lib/Task/Sympa.pm',
    VERSION_FROM  => 'lib/Task/Sympa.pm',
    LICENSE       => 'GPL_2',
    PREREQ_PM     => {
        'Archive::Zip'               => '1.05',
        'CGI'                        => '3.51',
        'DB_File'                    => '1.75',
        'DBI'                        => '1.48',
        'Digest::MD5'                => '2.00',
        'Encode'                     => '0',
        'File::Copy::Recursive'      => '0.36',
        'HTML::FormatText'           => '0',
        'HTML::StripScripts::Parser' => '1.03',
        'HTML::TreeBuilder'          => '0',
        'IO::Scalar'                 => '0',
        'Locale::Messages'           => '0',
        'Mail::Address'              => '1.70',
        'Mail::DKIM'                 => '0.36',
        'MHonArc::UTF8'              => '2.6.18',
        'MIME::Base64'               => '3.03',
        'MIME::Charset'              => '1.010',
        'MIME::EncWords'             => '1.014',
        'MIME::Lite::HTML'           => '1.23',
        'MIME::Tools'                => '5.423',
        'Template'                   => '0',
        'Term::ProgressBar'          => '2.09',
        'Text::LineFold'             => '2011.05',
        'Time::HiRes'                => '1.29',
        'URI::Escape'                => '1.35',
        'XML::LibXML'                => '0'
    }
);

WriteMakefile(%args);
