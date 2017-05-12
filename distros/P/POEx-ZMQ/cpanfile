requires "perl" => "5.016";

requires "strictures"     => "2";
requires "POSIX"          => "0";
requires "Time::HiRes"    => "0";

requires "Exporter::Tiny" => "0";
requires "Import::Into"   => "0";
requires "Try::Tiny"      => "0";

requires "FFI::Raw"       => "0";

requires "Math::Int64"    => "0";
# See upstream zmq-ffi GH#14:
requires "Math::BigInt"   => "1.997";

requires "List::Objects::WithUtils" => "2.016";
requires "List::Objects::Types"     => "1.002";
requires "Module::Runtime"          => "0";
requires "Moo"                      => "0";
requires "MooX::late"               => "0.014";
requires "namespace::clean"         => "0";
requires "Throwable"                => "0";
requires "Type::Tiny"               => "0.04";

requires "POE"                      => "1";
requires "MooX::Role::POE::Emitter" => "0.12";

recommends "Convert::Z85" => "0";
recommends "Crypt::ZCert" => "0";

on 'test' => sub {
  requires "Test::More" => "0.96";
};
