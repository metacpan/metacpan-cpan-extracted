package Strategic::Wiki::Config;
use Mouse;
use YAML::XS;

has is_wiki => (is => 'ro');
has config_file => (is => 'ro');
has root_dir => (is => 'ro');
has static_dir => (is => 'ro');

around BUILDARGS => sub {
    my ($orig, $class) = splice @_, 0, 2;
    my $config_file = shift || $class->get_config_file;
    return $class->$orig({is_wiki => 0})
        unless $config_file;
    my $hash = YAML::XS::LoadFile($config_file);
    $hash->{is_wiki} = 1;
    $hash->{config_file} = $config_file;
    $class->$orig($hash);
};

sub get_config_file {
    my $class = shift;
    my $file = '.strategic-wiki/config.yaml';
    return -f $file ? $file : '';
}

1;
