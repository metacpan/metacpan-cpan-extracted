use ExtUtils::MakeMaker;
use strict;

my $module  = 'lib/Template/Plugin/Chump.pm';
my %depends = ( 'Text::Chump' => 0,
                'Template'    => 0,
                'Test::More'  => 0,
              );

# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'            => 'Template::Plugin::Chump',
    'VERSION_FROM'    => $module, # finds $VERSION
    'PREREQ_PM'       => \%depends,
    'AUTHOR'          => 'Simon Wistow <simon@thegestalt.org>',
) if $0 =~ m/makefile.pl/i;

sub MY::postamble {
    return <<EOF
README: $module Changes ../makereadme
\t../makereadme $module \$(NAME) \$(VERSION) > README

dist: README

EOF
}

1;
