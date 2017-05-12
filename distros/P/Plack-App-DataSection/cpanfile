requires 'Data::Section::Simple';
requires 'HTTP::Date';
requires 'MIME::Base64';
requires 'Path::Class';
requires 'Plack';
requires 'autodie';
requires 'parent';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
    requires 'perl', '5.008_001';
};

on test => sub {
    requires 'Plack';
    requires 'HTTP::Message';
    requires 'Test::More', "0.98";
};

on develop => sub {
    requires 'Test::Perl::Critic';
};
