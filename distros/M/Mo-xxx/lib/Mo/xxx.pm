package Mo::xxx;my$M="Mo::";
$VERSION='0.12';
use constant XXX_skip=>1;my$dm='YAML::XS';*{$M.'xxx::e'}=sub{my($P,$e)=@_;$e->{WWW}=sub{require XXX;local$XXX::DumpModule=$dm;XXX::WWW(@_)};$e->{XXX}=sub{require XXX;local$XXX::DumpModule=$dm;XXX::XXX(@_)};$e->{YYY}=sub{require XXX;local$XXX::DumpModule=$dm;XXX::YYY(@_)};$e->{ZZZ}=sub{require XXX;local$XXX::DumpModule=$dm}};
