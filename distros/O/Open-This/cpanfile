requires "Module::Runtime" => "0";
requires "Path::Tiny" => "0";
requires "Try::Tiny" => "0";
requires "perl" => "5.006";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "Test::Differences" => "0";
  requires "Test::More" => "0";
  requires "perl" => "5.006";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "perl" => "5.006";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Pod::Wordlist" => "0";
  requires "Test::CPAN::Changes" => "0.19";
  requires "Test::Code::TidyAll" => "0.50";
  requires "Test::More" => "0.96";
  requires "Test::Pod::Coverage" => "1.08";
  requires "Test::Spelling" => "0.12";
  requires "Test::Synopsis" => "0";
};

on 'develop' => sub {
  recommends "Dist::Zilla::PluginBundle::Git::VersionManager" => "0.005";
};
