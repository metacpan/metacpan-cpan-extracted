use strict        ;
use warnings      ;
use Module::Build ;

my $builder = Module::Build->new(
    module_name         => 'Net::IRC2'                         ,
    license             => 'gpl'                               ,
    dist_author         => 'Karl Y. Pradene <knotty@cpan.org>' ,
    dist_version_from   => 'lib/Net/IRC2.pm'                   ,
    requires => {
	'perl'                  => '' ,
	'IO::Socket::INET'      => '' ,
        'Parse::RecDescent'     => '' ,
	'Test::More'            => '' ,
    },
    add_to_cleanup      => [ 'Net-IRC2-*' ] ,
) ;

$builder->create_build_script() ;
