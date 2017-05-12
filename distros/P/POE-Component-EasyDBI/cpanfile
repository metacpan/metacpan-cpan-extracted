requires 'perl', '5.00600';
requires 'strict';
requires 'warnings';
requires 'Carp';
requires 'Scalar::Util';
requires 'Params::Util';
requires 'DBI', '1.38';
requires 'POE', '0.3101';
requires 'Try::Tiny';

on configure => sub {
	requires 'Module::Build';
};

on test => sub {
	requires 'Test::More';
	requires 'Test::Requires', '0.08';
	recommends 'DBD::SQLite';
	recommends 'Time::Stopwatch';
};

on develop => sub {
	requires 'CPAN::Meta', '2.143240';
	requires 'DBD::SQLite';
	requires 'Time::Stopwatch';
};
