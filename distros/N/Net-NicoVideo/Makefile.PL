use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'              => 'Net::NicoVideo',
    'AUTHOR'            => 'WATANABE Hiroaki <hwat@cpan.org>',
    'VERSION_FROM'      => 'lib/Net/NicoVideo.pm', # finds $VERSION
    'LICENSE'           => 'perl',
    'MIN_PERL_VERSION'  => '5.008001',
    'PREREQ_PM'         => {
'CGI::Simple'           => 0,
'Class::Accessor::Fast' => 0,
'Encode'                => 0,
'JSON'                  => '2.01',
'LWP::UserAgent'        => 0,
'HTML::Parser'          => '3.00',
'HTTP::Cookies'         => 0,
'HTTP::Request::Common' => 0,
'Test::More'            => '0.32',
'XML::TreePP'           => 0,
'XML::FeedPP'           => 0,
        },
    );
