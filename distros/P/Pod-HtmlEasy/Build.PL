use strict;
use warnings;

use Module::Build;
use English qw{ -no_match_vars };

my $builder = Module::Build->new (
    module_name         => 'Pod::HtmlEasy' ,
    license             => 'perl',
    dist_author         => 'Geoffrey Leach <geoff@hughes.net>',
    dist_version_from   => 'lib/Pod/HtmlEasy.pm',
    dist_abstract       => 'The purpose of this module is to generate HTML data from POD in a easy and personalized mode. By default the HTML generated is similar to the CPAN site style for module documentation.',
    requires            => {
                        'perl'            => '5.6.3',
                        'Carp'            => 0,
                        'English'         => 0,
                        'Exporter::Easy'  => '0.16',
                        'File::Slurp'     => '9999.13',
                        'Getopt::Auto'    => '1.009006',
                        'HTML::EasyTags'  => 0,
                        'List::MoreUtils' => 0,
                        'Pod::Escapes'    => '1.04',
                        'Pod::Parser'     => '1.37',
                        'Pod::ParseLink'  => '1.06',
                        'Readonly'        => '1.03',
                        'Regexp::Common'  => '2.120',
                        'Pod::ParseLink'  => '1.06',
                        'Regexp::Common::Email::Address' => '1.01',
                         ($PERL_VERSION >= 5.012 ? (
                                 'feature'        => 1.16,
                         ) : (
                                 'Switch'         => 2.13,
                         )),
                        'Uniq'            => 0,
                        'version'         => '0.82',
},
    configure_requires  => {
                        'Module::Build'   => 0.4206,
},
    build_requires      => {
                        'Test::More'      => '0.94',
                        'IPC::Run'        => '0.80',
},
    add_to_cleanup     => [ 'Pod-HtmlEasy-*' ],
    create_makefile_pl => 'traditional',
    script_files       => [ qw ( scripts/pod2indexed_html.pl )
                          ],
);

$builder->create_build_script();
