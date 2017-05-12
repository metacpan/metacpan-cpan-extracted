requires "DBIx::Class::Core" => "0";
requires "DBIx::Class::ResultSet" => "0";
requires "DBIx::Class::Schema" => "0";
requires "Moose" => "0";
requires "base" => "0";
requires "strict" => "0";
requires "warnings" => "0";
requires 'DBIx::Class::EncodedColumn::Crypt::Eksblowfish::Bcrypt';
requires 'DBIx::Class::TimeStamp';

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "Test::More" => "0.96";
  requires 'Test::DBIx::Class';
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
  requires "perl" => "5.006";
};
