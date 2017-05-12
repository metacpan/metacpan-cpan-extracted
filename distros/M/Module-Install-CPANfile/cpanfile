requires 'Module::Install';
requires 'Module::CPANfile', '0.9034';

on test => sub {
    requires 'Test::More', '0.90';
};

on develop => sub {
    requires 'CPAN::Meta::Check'; # can't bootstrap this but a warning will be given
};
