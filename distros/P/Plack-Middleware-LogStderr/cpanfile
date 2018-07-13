requires "Capture::Tiny" => "0";
requires "Plack::Middleware" => "0";
requires "Plack::Util::Accessor" => "0";
requires "Scalar::Util" => "0";
requires "parent" => "0";
requires "strict" => "0";
requires "warnings" => "0";
requires "warnings::register" => "0";

on 'build' => sub {
  requires "Module::Build" => "0.28";
};

on 'test' => sub {
  requires "HTTP::Request::Common" => "0";
  requires "Plack::Test" => "0";
  requires "Test::Fatal" => "0";
  requires "Test::More" => "0.96";
  requires "if" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "Module::Build" => "0.28";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::EOL" => "0";
  requires "Test::More" => "0.88";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
};
