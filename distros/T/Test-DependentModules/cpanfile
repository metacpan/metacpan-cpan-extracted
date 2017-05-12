requires "CPAN" => "0";
requires "CPAN::Shell" => "0";
requires "Capture::Tiny" => "0";
requires "Cwd" => "0";
requires "Exporter" => "0";
requires "File::Path" => "0";
requires "File::Spec" => "0";
requires "File::Temp" => "0";
requires "File::chdir" => "0";
requires "IO::Handle::Util" => "0";
requires "IPC::Run3" => "0";
requires "Log::Dispatch" => "0";
requires "MetaCPAN::Client" => "0";
requires "Test::Builder" => "0";
requires "Try::Tiny" => "0";
requires "autodie" => "0";
requires "strict" => "0";
requires "warnings" => "0";
recommends "Parallel::ForkManager" => "v0.7.6";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Copy::Recursive" => "0";
  requires "File::Spec" => "0";
  requires "Module::Build" => "0";
  requires "Module::Build::Tiny" => "0";
  requires "Test::More" => "0.96";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Code::TidyAll" => "0.24";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Perl::Critic" => "1.123";
  requires "Perl::Tidy" => "20140711";
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Changes" => "0.19";
  requires "Test::Code::TidyAll" => "0.24";
  requires "Test::EOL" => "0";
  requires "Test::Mojibake" => "0";
  requires "Test::More" => "0.88";
  requires "Test::NoTabs" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "Test::Pod::LinkCheck" => "0";
  requires "Test::Pod::No404s" => "0";
  requires "Test::Spelling" => "0.12";
  requires "Test::Version" => "1";
};
