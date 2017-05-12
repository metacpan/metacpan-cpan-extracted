use 5.014002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Template::Plugin::Date::FriendlyDelta',
    AUTHOR           => 'Albert Cornelissen <acorn@cpan.org>',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.8.1',
    VERSION_FROM      => 'lib/Template/Plugin/Date/FriendlyDelta.pm',
    PREREQ_PM         => {
    	'DateTime'    => 1.03,
    	'Date::Parse' => 2.30
    },
    META_MERGE => {
    resources => {
        license    => 'http://dev.perl.org/licenses/',
        homepage   => 'https://metacpan.org/module/Template::Plugin::Date::FriendlyDelta',
        bugtracker => 'https://github.com/G3S/template-plugin-date-friendlydelta/issues',
        repository => 'https://github.com/G3S/template-plugin-date-friendlydelta'
    },
    }
);
