use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'SmsAero',
    VERSION_FROM => 'lib/SmsAero.pm',
    AUTHOR       => 'SmsAero <admin@smsaero.ru>',
    ABSTRACT     => 'Send SMS via smsaero.ru',
    LICENSE      => 'mit',
    PREREQ_PM     => {
        'JSON'                => 0,
        'LWP::UserAgent'      => 0,
        'LWP::Protocol::https'=> 0,
        'HTTP::Request'       => 0,
        'URI::Escape'         => 0,
        'Email::Valid'        => 0,
        'Time::Piece'         => 0,
        'Log::Log4perl'       => 0,
        'Exception::Class'    => 0,
        'MIME::Base64'        => 0,
        'Getopt::Long'        => 0,
        'Pod::Usage'          => 0,
    },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/smsaero/smsaero_perl',
        },
    },
);

