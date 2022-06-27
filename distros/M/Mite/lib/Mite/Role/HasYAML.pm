package Mite::Role::HasYAML;
use Mite::MyMoo -Role;

sub yaml_load {
    my ( $class, $yaml ) = ( shift, @_ );

    require YAML::XS;
    return YAML::XS::Load($yaml);
}

sub yaml_dump {
    my ( $class, $data ) = ( shift, @_ );

    require YAML::XS;
    return YAML::XS::Dump($data);
}

1;
