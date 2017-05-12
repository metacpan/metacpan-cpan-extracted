requires "Alien::SVN" => "0";
requires "Carp" => "0";
requires "Encode" => "0";
requires "Exception::Class" => "1.22";
requires "File::Basename" => "0";
requires "File::Path" => "0";
requires "File::Spec" => "0";
requires "File::Temp" => "0";
requires "FindBin" => "0";
requires "IO::File" => "0";
requires "List::Util" => "0";
requires "Locale::Maketext" => "0";
requires "Locale::Maketext::Lexicon" => "0";
requires "Number::Format" => "0";
requires "POSIX" => "0";
requires "Plack" => "0";
requires "Template" => "0";
requires "Template::Plugin::Number::Format" => "0";
requires "Time::Zone" => "0";
requires "URI::Escape" => "0";
requires "YAML" => "0";
requires "base" => "0";
requires "perl" => "5.00404";
requires "strict" => "0";
requires "vars" => "0";
requires "warnings" => "0";
recommends "Cache::Cache" => "0";
recommends "Template::Plugin::Clickable" => "0";
recommends "Template::Plugin::Clickable::Email" => "0";
recommends "Template::Plugin::Subst" => "0";
recommends "Test::Benchmark" => "0";
recommends "Test::HTML::Tidy" => "0";
recommends "XML::RSS::Parser" => "0";

on 'build' => sub {
  requires "File::Copy" => "0";
  requires "File::Find" => "0";
};

on 'test' => sub {
  requires "Cwd" => "0";
  requires "File::Path" => "0";
  requires "Test::More" => "0";
  requires "Test::WWW::Mechanize" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.30";
};
