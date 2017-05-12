requires 'parent';
requires 'perl', '5.008005';
requires 'Encode', '2.57';
requires 'Lingua::JA::Numbers';
requires 'Lingua::JA::Regular::Unicode';

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
    requires 'Class::Accessor::Lite';
    requires 'Data::Dumper::AutoEncode';
    requires 'File::Temp';
    requires 'Furl';
    requires 'Guard';
    requires 'Test::Perl::Critic';
    requires 'Text::Extract::Word';
    requires 'URI';
};
