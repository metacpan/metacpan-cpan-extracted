requires 'File::Spec::Memoized';
requires 'Memoize';
requires 'Sledge';
requires 'Text::Xslate';
requires 'parent';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
    requires 'perl', '5.008_001';
};

on test => sub {
    requires 'Class::Accessor';
    requires 'Sledge';
    requires 'Test::More';
};

on develop => sub {
    requires 'Test::Perl::Critic';
};
