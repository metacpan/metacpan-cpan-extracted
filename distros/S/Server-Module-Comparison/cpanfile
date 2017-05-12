requires "Moo" => "0";
requires "Path::Tiny" => "0";
requires "Types::Standard" => "0";
requires "strictures" => "2";
requires "Capture::Tiny" => 0;
requires "failures" => 0;
requires "Perl::Version" => 0;

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "Test::More" => "0.96";
  requires "Test::Most" => "0";
  requires "strict" => "0";
  requires "warnings" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::More" => "0";
  requires "Test::Pod" => "1.41";
  requires "blib" => "1.01";
  requires "perl" => "5.008";
  requires "strict" => "0";
  requires "warnings" => "0";
};
