requires "CPAN::Changes" => "0.30";
requires "CPAN::Meta" => "0";
requires "Class::Method::Modifiers" => "0";
requires "File::Slurp" => "0";
requires "Getopt::Long::Descriptive" => "0";
requires "Hash::Util" => "0";
requires "List::Util" => "1.33";
requires "Module::CoreList" => "0";
requires "Moo" => "0";
requires "Moo::Role" => "0";
requires "MooX::HandlesVia" => "0";
requires "Path::Tiny" => "0";
requires "Pod::Simple" => "0";
requires "Role::Tiny" => "0";
requires "Scalar::Util" => "0";
requires "Try::Tiny" => "0";
requires "Type::Tiny" => "1.000000";
requires "Types::Standard" => "0";
requires "namespace::autoclean" => "0";
requires "perl" => "v5.10.1";
recommends "Pod::Man" => "0";
recommends "Pod::Markdown" => "0";
recommends "Pod::Markdown::Github" => "0";
recommends "Pod::Simple::HTML" => "0";
recommends "Pod::Simple::LaTeX" => "0";
recommends "Pod::Simple::RTF" => "0";
recommends "Pod::Simple::Text" => "0";
recommends "Pod::Simple::XHTML" => "0";
recommends "Type::Tiny::XS" => "0";

on 'test' => sub {
  requires "Cwd" => "0";
  requires "File::Compare" => "0";
  requires "File::Spec" => "0";
  requires "IO::String" => "0";
  requires "Module::Metadata" => "0";
  requires "Pod::Simple::Text" => "0";
  requires "Test::Deep" => "0";
  requires "Test::Exception" => "0";
  requires "Test::Kit" => "0";
  requires "Test::More" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'develop' => sub {
  requires "Test::CleanNamespaces" => "0.15";
  requires "Test::EOF" => "0";
  requires "Test::EOL" => "0";
  requires "Test::Kwalitee" => "1.21";
  requires "Test::MinimumVersion" => "0";
  requires "Test::More" => "0.88";
  requires "Test::NoTabs" => "0";
  requires "Test::Perl::Critic" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Portability::Files" => "0";
  requires "Test::TrailingSpace" => "0.0203";
};
