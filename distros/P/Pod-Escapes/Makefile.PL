# This -*- perl -*- script writes the Makefile for Class::BlackHole
# Time-stamp: "2004-04-27 19:28:38 ADT"
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
require 5.004;
use strict;
use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) {
    # developer release
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

WriteMakefile(
    'NAME'	       => 'Pod::Escapes',
    'VERSION_FROM' => 'lib/Pod/Escapes.pm',
    'dist'         => { COMPRESS => 'gzip -6f', SUFFIX => 'gz', },

    PREREQ_PM      => {
        'Exporter' => 0,
        'strict'   => 0,
        'warnings' => 0,
        'vars'     => 0,
    },

    ($mm_ver >= 6.31
        ? (LICENSE => 'perl')
        : ()
    ),

    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.006)
        : ()
    ),

    ($mm_ver <= 6.45
        ? ()
        : (META_MERGE => {
            'meta-spec' => { version => 2 },
            resources => {
                bugtracker  => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Escapes',
                repository  => {
                    type => 'git',
                    web  => 'https://github.com/neilbowers/Pod-Escapes',
                    url  => 'git://github.com/neilbowers/Pod-Escapes.git',
                },
            },
          })
    ),

);

package MY;

sub libscan
{ # Determine things that should *not* be installed
    my($self, $path) = @_;
    return '' if $path =~ m/~/;
    $path;
}

__END__
