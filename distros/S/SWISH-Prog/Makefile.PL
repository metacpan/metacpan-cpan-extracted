use strict;
use warnings;
use inc::Module::Install;
use 5.008003;

name 'SWISH-Prog';
all_from 'lib/SWISH/Prog.pm';
requires 'Search::Tools'      => '0.82';
requires 'File::Basename'     => 0;
requires 'Time::HiRes'        => 0;
requires 'MIME::Types'        => 0;
requires 'Path::Class'        => 0;
requires 'File::Rules'        => '0.02';
requires 'SWISH::Filter'      => '0.15';
requires 'Rose::DateTime'     => 0;
requires 'Rose::ObjectX::CAF' => 0;         # Search::Tools also requires this
requires 'File::Temp'         => 0;
requires 'Data::Dump'         => 0;         # Search::Tools also requires this
requires 'Config::General'    => '2.31';
requires 'Scalar::Util'       => 0;
requires 'Test::More'         => 0;
requires 'File::Slurp'        => 0;         # Search::Tools also requires this
requires 'XML::Simple'        => 0;
requires 'Search::Query'      => 0.17;
requires 'SWISH::3'           => 1.000005;

# recommended Aggregator support

# FF should be part of base install just like Carp
recommends 'File::Find'                   => 0;
recommends 'LWP::RobotUA'                 => 0;
recommends 'HTML::Tagset'                 => 0;
recommends 'HTML::LinkExtor'              => 0;
recommends 'HTTP::Message'                => 0;
recommends 'HTTP::Server::Simple'         => 0;
recommends 'HTTP::Server::Simple::Authen' => 0;
recommends 'Test::HTTP::Server::Simple'   => 0;
recommends 'XML::Feed'                    => 0;
recommends 'WWW::Sitemap::XML'            => 0;
recommends 'URI'                          => 0;
recommends 'SWISH::API::Object'           => 0.13;  # native searcher requires
recommends 'YAML::Syck'                   => '0.72';
recommends 'JSON'                         => 2.0;
recommends 'Mail::Box'                    => 0;
recommends 'DBI'                          => 0;
recommends 'Term::ProgressBar'            => 0;

perl_version '5.8.3';
license 'http://dev.perl.org/licenses/';
homepage 'http://dev.swish-e.org/wiki/perl';
bugtracker 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Prog';
repository 'http://svn.swish-e.org/perl/SWISH-Prog/';

install_script 'examples/swish3';

WriteMakefile(
    PL_FILES => {},
    dist     => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean    => {
        FILES => join(
            ' ',
            qw(
                t/dbi.index
                t/swishobjects
                t/testindex
                t/object.index
                t/xapian.index
                t/index.swish
                t/spider.index
                t/mail.index
                SWISH-Prog-*
                )
        )
    }
);
