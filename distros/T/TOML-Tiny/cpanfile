requires 'perl'         => '>= 5.018';
requires 'Carp'         => '0';
requires 'Data::Dumper' => '0';
requires 'Exporter'     => '0';
requires 'Encode'       => '0';
requires 'Math::BigInt' => '>= 1.999718';
requires 'DateTime::Format::RFC3339' => '0';
requires 'DateTime::Format::ISO8601' => '0';

recommends 'Types::Serialiser' => 0;

on test => sub{
  requires 'Data::Dumper'              => '0';
  requires 'Test2::V0'                 => '0';

  recommends 'Unicode::GCString'       => '0';
};

on 'develop' => sub {
  requires 'TOML::Parser'              => '0';
};
