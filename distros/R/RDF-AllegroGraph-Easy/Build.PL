use v5.10;
use strict;
use warnings;
use Module::Build;

use Module::Build;
my $class = Module::Build->subclass(
    class => "Module::Build::Custom",
    code => <<'SUBCLASS' );

sub ACTION_upload {
    my $self = shift;
    my $v = $self->dist_version();
    $self->do_system(('cpan-upload', "RDF-AllegroGraph-Easy-$v.tar.gz"));
}
SUBCLASS

$class->new(
    module_name         => 'RDF::AllegroGraph::Easy',
    license             => 'perl',
    dist_author         => 'Robert Barta <rho@devc.at>',
    dist_version_from   => 'lib/RDF/AllegroGraph/Easy.pm',
    build_requires => {
        'Test::More'          => 0,
	'JSON'                => 0,
	'LWP'                 => 0,
	'URI::Escape'         => 0,
	'Regexp::Common'      => 0,
	'Test::Pod::Coverage' => 0,
	'Test::Exception'     => 0,
	'DateTime'            => 0,
	'Time::HiRes'         => 0,
    },
    add_to_cleanup      => [ 'RDF-AllegroGraph-Easy-*' ],
    create_makefile_pl => 'traditional',
)->create_build_script();



__END__

