use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'POE::Filter::XML::RPC',
    license             => 'gpl',
    dist_author         => 'Nicholas R. Perez <nperez@cpan.org>',
    dist_version_from   => 'lib/POE/Filter/XML/RPC.pm',
	dist_abstract		=> 'A high level abstraction for (de)serializing XML-RPC requests',
    create_readme       => 1,
    build_requires => {
        'Test::More'		    => 0.8,
		'POE'				    => 1.003,
		'POE::Filter::XML'	    => 0.35,
        'Regexp::Common::time'  => 0.04,
        'perl'                  => 5.010
    },
    add_to_cleanup      => [ 'POE-Filter-XML-RPC-*' ],
);

$builder->create_build_script();
