requires 'DBI';
requires 'POSIX';
requires 'Parallel::Prefork';
requires 'Time::HiRes';
recommends 'Scope::Guard';

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.36';
};

on test => sub {
    requires 'Test::mysqld';
}
