requires "PerlX::Define" => "0";
requires "PerlX::Maybe" => "0";
requires "Sub::Infix" => "0";
requires "Syntax::Feature::Try" => "0";
requires "constant" => "0";
requires "feature" => "0";
requires "match::simple" => "0";
requires "mro" => "0";
requires "perl" => "5.010_000";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::Modern" => "0";
  requires "Test::More" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Test::Pod" => "1.41";
};
