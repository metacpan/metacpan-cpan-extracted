requires "MRO::Compat" => "0";
requires "Message::Passing::Output::ZeroMQ" => "0";
requires "Plack::Middleware::AccessLog::Structured" => "0";
requires "parent" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'build' => sub {
  requires "Module::Build" => "0.28";
};

on 'test' => sub {
  requires "AnyEvent" => "0";
  requires "Carp" => "0";
  requires "File::Find" => "0";
  requires "File::Temp" => "0";
  requires "HTTP::Request::Common" => "0";
  requires "Message::Passing::Filter::Decoder::JSON" => "0";
  requires "Message::Passing::Input::ZeroMQ" => "0";
  requires "Message::Passing::Output::Test" => "0";
  requires "Plack::Test" => "0";
  requires "Test::Class" => "0";
  requires "Test::Deep" => "0";
  requires "Test::More" => "0.88";
  requires "Test::TCP" => "0";
  requires "lib" => "0";
};

on 'configure' => sub {
  requires "Module::Build" => "0.28";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Changes" => "0.19";
  requires "Test::CPAN::Meta" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "version" => "0.9901";
};
