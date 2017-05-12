requires 'Carp', 0;
requires 'Compiler::Lexer', '0.22';
requires 'CPAN::Meta::Requirements', '2.125';
requires 'Module::Path';
requires 'parent', 0;
requires 'perl', '5.008005';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on test => sub {
    requires 'Test::Deep';
    requires 'Test::More', '0.98';
};

on develop => sub {
    requires 'Perl::PrereqScanner';
    requires 'autodie';
    requires 'Test::Perl::Critic';
    requires 'Benchmark::Forking';
};
