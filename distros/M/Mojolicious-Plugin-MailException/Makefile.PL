use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Mojolicious::Plugin::MailException',
    VERSION_FROM      => 'lib/Mojolicious/Plugin/MailException.pm',
    PREREQ_PM         => {
        'Mojolicious'   => 0,
        'MIME::Words'   => 0,
        'MIME::Lite'    => 0,
    },
    ($] >= 5.005 ? 
      (ABSTRACT_FROM  => 'lib/Mojolicious/Plugin/MailException.pm',
       AUTHOR         => 'Dmitry E. Oboukhov <unera@debian.org>') : ()),
       LICENSE        => 'Perl',

       META_MERGE => {
            resources => {
                homepage => 'https://github.com/dr-co/libmojolicious-plugin-mail_exception',
                repository => 'https://github.com/dr-co/libmojolicious-plugin-mail_exception',
                bugtracker => 'https://github.com/dr-co/libmojolicious-plugin-mail_exception/issues',
            }
       }
);

open my $fh, '>>', 'Makefile' or exit 0;
print $fh "\n\nTEST_VERBOSE=1\n\n";
