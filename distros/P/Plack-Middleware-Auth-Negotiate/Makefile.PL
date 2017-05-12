use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Plack::Middleware::Auth::Negotiate',
    AUTHOR              => q{Adrian Kreher <avuserow@cpan.org>},
    VERSION_FROM        => 'lib/Plack/Middleware/Auth/Negotiate.pm',
    ABSTRACT_FROM       => 'lib/Plack/Middleware/Auth/Negotiate.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'bsd')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'GSSAPI' => 0,
        'MIME::Base64' => 0,
        'Scalar::Util' => 0,
        'Plack::Middleware' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Plack-Middleware-Auth-Negotiate-*' },
);
