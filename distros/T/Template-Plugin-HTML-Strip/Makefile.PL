use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Template::Plugin::HTML::Strip',
    VERSION_FROM      => 'lib/Template/Plugin/HTML/Strip.pm', # finds $VERSION
    PREREQ_PM         => {
        'Test::More'     => 0.62,
        'HTML::Strip'    => 1.04,
        'Template'       => 2.14,
        'Template::Test' => 2.70,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Template/Plugin/HTML/Strip.pm', # retrieve abstract from module
       AUTHOR         => 'Geoff Simmons <gsimmons@cpan.org>') : ()),
);
