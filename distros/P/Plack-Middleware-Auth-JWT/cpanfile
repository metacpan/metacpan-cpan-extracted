requires "Crypt::JWT" => "0.020";
requires "Plack::Middleware" => "0";
requires "Plack::Request" => "0";
requires "Plack::Util" => "0";
requires "Plack::Util::Accessor" => "0";
requires "parent" => "0";
requires "perl" => "5.010";
requires "strict" => "0";
requires "warnings" => "0";

on 'build' => sub {
  requires "Module::Build" => "0.28";
};

on 'test' => sub {
  requires "FindBin" => "0";
  requires "HTTP::Request::Common" => "0";
  requires "Plack::Builder" => "0";
  requires "Plack::Test" => "0";
  requires "Test::More" => "0";
};

on 'configure' => sub {
  requires "Module::Build" => "0.28";
};
