use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Params::Clean',
    dist_abstract       => 'Clean and simple parsing of args by position/name/flag/list/type',
    dist_author         => 'David Green <plato@cpan.org>',
    license             => 'perl',
    requires            =>{'UID'=>0, 'Devel::Caller::Perl'=>0, version=>0, perl=>'5.6.0'},
    
    build_requires      =>{'Test::More' => 0, },
    add_to_cleanup      =>['Params-Clean-*'],
);

$builder->create_build_script();
