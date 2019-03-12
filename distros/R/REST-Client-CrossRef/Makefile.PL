

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'REST::Client::CrossRef',
    VERSION_FROM => 'lib/REST/Client/CrossRef.pm', # finds \$VERSION
    AUTHOR       => 'FranE<ccedil>ois Rappaz (rappazf@gmail.com)',
    ABSTRACT     => 'A REST client for the CrossRef API',
    PREREQ_PM    => {
                     'Test::More' => 1.001014,
                     'Moo' => 2.001001,
                     'JSON' => 2.90,
                     'URI::Escape' =>3.31,
                     'REST::Client' => 273,
                     'Log::Any' => 1.049,
                     'HTTP::Cache::Transparent'=> 1.4,
                     'Carp'=>1.40,
                     'JSON::Path' => 0.420,
                    },
);
