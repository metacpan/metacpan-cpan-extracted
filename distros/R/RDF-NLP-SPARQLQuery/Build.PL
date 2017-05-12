use Module::Build;


 
my $class = Module::Build->subclass(
				    class => "Module::Build::Custom",

code => <<'SUBCLASS' );

sub ACTION_install {
    my $self = shift;
    $self->SUPER::ACTION_install;
}

sub ACTION_fakeinstall {
    my $self = shift;
    $self->SUPER::ACTION_fakeinstall;

}

sub ACTION_build {
    my $self = shift;

    require Config::General;

    $self->SUPER::ACTION_build;
}

sub ACTION_clean {
    my $self = shift;
    $self->SUPER::ACTION_clean;

}

SUBCLASS


my $build = $class->new
    (
     module_name => 'RDF::NLP::SPARQLQuery',
     dist_version_from => 'lib/RDF/NLP/SPARQLQuery.pm',
     license => 'gpl',
     configure_requires => { 'Module::Build' => 0.38,
     },
     requires => {'perl' => '5.10.0',
		  "Config::General" => 0,
		  "Data::Dumper" => 0,
		  "Storable" => 0,
		  "Mouse" => 0,
		  "HTTP::Request" => 0,
		  "LWP::UserAgent" => 0,
		  "URL::Encode" => 0,
		  "Test::More"     => 0.62,
		  "Test::Pod" => 0,
		  "Getopt::Long" => 0,
		  "Pod::Usage" => 0,
		  "Test::Pod::Coverage" => 0,
	      },
     build_requires => {
	 "Module::Build"     => 0.28,
	 Test::More     => 0.62,
     },
     conf_files => {'etc/nlquestion/nlquestion.rc' => 'conf/nlquestion/nlquestion.rc',
		    'etc/nlquestion/SemanticTypeCorresp.rc' => 'conf/nlquestion/SemanticTypeCorresp.rc',
     },
    );

$build->install_base_relpaths( conf => 'etc' );
$build->prefix_relpaths('site', conf => 'etc' );
$build->prefix_relpaths('core', conf => 'etc' );
$build->prefix_relpaths('vendor', conf => 'etc' );
$build->add_build_element('conf');

foreach my $type (keys(%{$build->install_sets})) {
    $build->install_sets->{$type}->{'conf'} = '/etc';
}

$build->install_sets->{'site'}->{'conf'} = '/usr/local/etc';

$build->install_path->{'conf'} = $build->prefix() . '/etc';

$build->create_build_script;

