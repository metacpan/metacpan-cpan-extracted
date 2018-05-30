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

        'Archive::Zip'                 => '1.60',
        'AuthCAS'                      => '1.7',
        'CGI'                          => '4.38',
        'CGI::Fast'                    => '2.13',
        'Class::Singleton'             => '1.5',
        'Clone'                        => '0.39',
        'Crypt::CipherSaber'           => '1.01',
        'Crypt::OpenSSL::X509'         => '1.808',
        'Crypt::SMIME'                 => '0.25',
        'DBD::CSV'                     => '0.49',
        'DBD::ODBC'                    => '1.57',
        'DBD::Oracle'                  => '1.74',
        'DBD::Pg'                      => 'v3.7.4',
        'DBD::SQLite'                  => '1.56',
        'DBD::Sybase'                  => '1.16',
        'DBD::mysql'                   => '4.046',
        'DBI'                          => '1.640',
        'Data::Password'               => '1.12',
        'DateTime::Format::Mail'       => '0.403',
        'DateTime::TimeZone'           => '2.17',
        'Digest::MD5'                  => '2.55',
        'Encode'                       => '2.97',
        'Encode::Locale'               => '1.05',
        'FCGI'                         => '0.78',
        'File::Copy::Recursive'        => '0.40',
        'File::NFSLock'                => '1.27',
        'File::Path'                   => '2.15',
        'HTML::FormatText'             => '2.16',
        'HTML::StripScripts::Parser'   => '1.03',
        'HTML::TreeBuilder'            => '5.07',
        'IO::File'                     => '1.25',
        'IO::Scalar'                   => '2.111',
        'IO::Socket::SSL'              => '2.056',
        'LWP::UserAgent'               => '6.33',
        'List::Util::XS'               => '1.50',
        'Locale::Messages'             => '1.29',
        'MIME::Base64'                 => '3.15',
        'MIME::Charset'                => 'v1.012.2',
        'MIME::EncWords'               => 'v1.014.3',
        'MIME::Lite::HTML'             => '1.24',
        'MIME::Tools'                  => '5.509',
        'Mail::Address'                => '2.20',
        'Mail::DKIM::Verifier'         => '0.52',
        'Net::CIDR'                    => '0.18',
        'Net::DNS'                     => '1.15',
        'Net::LDAP'                    => '0.65',
        'Net::SMTP'                    => '3.11',
        'SOAP::Lite'                   => '1.26',
        'Sys::Syslog'                  => '0.35',
        'Template'                     => '2.27',
        'Term::ProgressBar'            => '2.21',
        'Text::LineFold'               => '2017.004',
        'Time::HiRes'                  => '1.9754',
        'URI::Escape'                  => '1.73',
        'Unicode::Normalize'           => '1.25',
        'XML::LibXML'                  => '2.0132',

        # FIXME: those 2 guys are ruining the installation.
        # so i (eiro) put them in quarantine
        # 'MHonArc::UTF8'              => '2.6.18',
        # 'MIME::Lite::HTML'           => '1.23',
    }
);

WriteMakefile(%args);
