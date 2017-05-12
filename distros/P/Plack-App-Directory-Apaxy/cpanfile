requires "Number::Bytes::Human" => "0";
requires "Path::Tiny" => "0";
requires "Plack" => "0";
requires "Time::Piece" => "0";
requires "URI::Escape" => "0";
requires "parent" => "0";

on 'test' => sub {
  requires "HTTP::Message" => "0";
  requires "Test::More" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.30";
  requires "File::ShareDir::Install" => "0.03";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
};
