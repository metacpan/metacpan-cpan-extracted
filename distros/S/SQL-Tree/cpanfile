#!perl

on configure => sub {
    requires 'ExtUtils::MakeMaker::CPANfile';
    requires 'File::ShareDir::Install' => 0;
};

on runtime => sub {
    requires 'File::ShareDir::Dist' => 0;
    requires 'OptArgs2'             => 0;
    requires 'Template::Tiny'       => 0;
};

on test => sub {
    requires 'Test2::V0' => 0;
};

on develop => sub {
    requires 'Class::Inline'   => 0;
    requires 'Test::More'      => 0;
    requires 'Test::Exception' => 0;
    requires 'Test::Database'  => 0;
    requires 'DBI'             => 0;
    requires 'DBD::SQLite'     => 0;
};
