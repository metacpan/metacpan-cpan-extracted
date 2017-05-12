use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(
    class => "Module::Build::Custom",
    code => <<'SUBCLASS' );

sub ACTION_upload {
    my $self = shift;
    my $v = $self->dist_version();
    $self->do_system(('cpan-upload', "RDF-Trine-AllegroGraph-$v.tar.gz"));
}
SUBCLASS


my $builder = $class->new(
    module_name         => 'RDF::Trine::AllegroGraph',
    license             => 'perl',
    dist_author         => 'Robert Barta <drrho@cpan.org>',
    dist_version_from   => 'lib/RDF/Trine/AllegroGraph.pm',
    build_requires => {
        'Test::More'                 => 0,
	'Test::Exception'            => undef,
	'RDF::Trine'                 => 0.134,
	'RDF::Endpoint'              => 0.01,
	'RDF::AllegroGraph::Easy'    => undef,
	'RDF::Query'                 => 2.905,
	'HTTP::Request::Common'      => undef,
        'Test::WWW::Mechanize::PSGI' => undef,
	'List::MoreUtils'            => undef,
	'LWP::UserAgent'             => undef,
    },
    add_to_cleanup      => [ 'RDF-Trine-AllegroGraph-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
