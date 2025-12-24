requires "Carp"                   => "0";
requires "CellBIS::Random"        => "0";
requires "CellBIS::SQL::Abstract" => "1.2";
requires "Mojo::SQLite"           => "0";
requires "Mojolicious"            => "0";
requires "String::Random"         => "0";

feature 'mariadb', 'MariaDB/MySQL backend' => sub {
  recommends "Mojo::mysql" => "0";
};

feature 'pg', 'PostgreSQL backend' => sub {
  recommends "Mojo::Pg" => "0";
};

on 'test' => sub {
  requires "Mojolicious::Lite" => "0";
  requires "Test::Mojo"        => "0";
  requires "Test::More"        => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "7.12";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::More"              => "0";
  requires "Test::Pod"               => "1.41";
  requires "Test::Pod::Coverage"     => "1.08";
};
