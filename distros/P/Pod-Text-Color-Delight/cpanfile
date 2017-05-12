requires 'Pod::Text::Color', '2.07';
requires 'Syntax::Highlight::Perl::Improved';
requires 'Term::ANSIColor', '4.02';
requires 'parent';
requires 'perl', '5.008005';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on test => sub {
    requires 'Test::More', '0.98';
    requires 'Capture::Tiny';
};
