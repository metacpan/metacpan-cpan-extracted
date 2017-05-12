use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::MyCommerce::API',
    AUTHOR              => q{Doug Hatfield <dhatfield@digitalriver.com>},
    VERSION_FROM        => 'lib/Net/MyCommerce/API.pm',
    ABSTRACT            => 'Net/MyCommerce/API.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'apache')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
       'Encode' => 0,
       'JSON::Parse' => 0,
       'JSON::XS' => 0,
       'MIME::Base64' => 0,
       'REST::Client' => 0,
       'Test::More' => 0,
       'Try::Tiny' => 0,
       'URI::Escape' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-MyCommerce-API-*' },
);
