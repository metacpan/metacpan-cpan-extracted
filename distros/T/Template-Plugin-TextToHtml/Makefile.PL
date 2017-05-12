use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Template::Plugin::TextToHtml',
    'VERSION_FROM'	=> 'TextToHtml.pm', # finds $VERSION
    'PREREQ_PM'		=> {
                        HTML::FromText => '1.005',
                        Template       => '2.0',
                       },
);
