use 5.014002;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Net::Sendy::API',
    VERSION_FROM => 'lib/Net/Sendy/API.pm',
    LICENSE => 'perl',
    PREREQ_PM    => {
        'LWP::UserAgent' => undef,
        'URI'            => undef
    },
    (
        $] >= 5.005
        ?
          (
            ABSTRACT_FROM =>
              'lib/Net/Sendy/API.pm',
            AUTHOR => 'Sherzod B. Ruzmetov <sherzodr@cpan.org'
          )
        : ()
    ),
);
