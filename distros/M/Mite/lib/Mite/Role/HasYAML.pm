package Mite::Role::HasYAML;

use feature ':5.10';
use Mouse::Role;
use Method::Signatures;

method yaml_load($yaml) {
    require YAML::XS;
    return YAML::XS::Load($yaml);
}

method yaml_dump($data) {
    require YAML::XS;
    return YAML::XS::Dump($data);
}

1;
