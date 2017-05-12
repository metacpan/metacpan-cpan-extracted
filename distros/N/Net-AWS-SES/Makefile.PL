

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Net::AWS::SES',
    VERSION_FROM => 'lib/Net/AWS/SES.pm',
    PREREQ_PM    => {
        'Digest::HMAC_SHA1' => undef,
        'MIME::Base64'      => undef,
        'Time::Piece'       => undef,
        'LWP::UserAgent'    => undef,
        'HTTP::Headers'     => undef,
        'MIME::Entity'      => undef,
        'XML::Simple'       => undef
    },
    (
        $] >= 5.005
        ? (
            ABSTRACT_FROM => 'lib/Net/AWS/SES.pm',
            AUTHOR        => 'Sherzod Ruzmetov <sherzodr@cpan.org>'
          )
        : ()
    ),
);
