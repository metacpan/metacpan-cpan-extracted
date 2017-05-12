requires "IPC::Open3" => "0";
requires "List::AllUtils" => "0";
requires "Symbol" => "0";
requires "autodie" => "2.25";
requires "parent" => "0";
requires "perl" => "v5.14.0";
requires "strict" => "0";
requires "warnings" => "0";
requires "warnings::register" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::CheckDeps" => "0.010";
  requires "Test::More" => "0.94";
  requires "Test::Skip::UnlessExistsExecutable" => "0";
  requires "perl" => "v5.14.0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "Devel::CheckBin" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "perl" => "v5.14.0";
};

on 'develop' => sub {
  requires "Dist::Zilla::PluginBundle::RSRCHBOY" => "0.066";
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Pod::Wordlist" => "0";
  requires "Test::EOL" => "0";
  requires "Test::More" => "0.88";
  requires "Test::NoTabs" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "Test::Pod::LinkCheck" => "0";
  requires "Test::Spelling" => "0.12";
};
