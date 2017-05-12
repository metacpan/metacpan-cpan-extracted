use ExtUtils::MakeMaker;
WriteMakefile(
        'NAME' => "SF::SF_form_secure",
        'AUTHOR' => 'Nicholas K. Alberto <sflex@cpan.org>',
        'VERSION_FROM' => 'SF_form_secure.pm',
        'ABSTRACT' => 'Data integrity for forms, links, cookie or other things.',
        'PREREQ_PM' => {'Digest::SHA1' => 0}
);
