requires "DateTime" => "0";
requires "DateTime::Format::ISO8601" => "0";
requires "Neovim::RPC::Plugin" => "0";
requires "Promises" => "0";
requires "Taskwarrior::Kusarigama::Wrapper" => "0";
requires "experimental" => "0";
requires "perl" => "v5.20.0";
requires "warnings" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::More" => "0";
  requires "strict" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Test::More" => "0.96";
  requires "Test::Vars" => "0";
};
