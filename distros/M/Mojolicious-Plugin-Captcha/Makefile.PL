use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Mojolicious::Plugin::Captcha',
    VERSION_FROM      => 'lib/Mojolicious/Plugin/Captcha.pm',
    PREREQ_PM         => {
        'Mojolicious'       => 0,
        'GD::SecurityImage' => 0,
        'Test::More'        => 0,
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Mojolicious/Plugin/Captcha.pm',
       AUTHOR         => 'zar <zar@cpan.org>') : ()),
);
