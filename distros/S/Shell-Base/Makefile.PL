use strict;

# ----------------------------------------------------------------------
# $Id: Makefile.PL,v 1.4 2004/04/09 22:18:48 dlc Exp $
# ----------------------------------------------------------------------
# Makefile.PL for Shell::Base
# ----------------------------------------------------------------------

use ExtUtils::MakeMaker;

my %PREREQ_PM = (
    'Carp'              => 0,
    'Env'               => 0,
    'IO::File'          => 0,
    'Term::ReadLine'    => 0,
    'Term::Size'        => 0.2,
    'Text::Shellwords'  => 0,
    'Text::Wrap'        => 0,
);

my %clean = (
    FILES => '$(DISTVNAME).tar$(SUFFIX) distdir',
);

my %dist = (
    PREOP => 'perldoc -t Base.pm > README; cpansign -s',
);

WriteMakefile(
    NAME        => "Shell::Base",
    VERSION     => "0.05",
    PREREQ_PM   => \%PREREQ_PM,
    clean       => \%clean,
    dist        => \%dist,
);

package MY;
use File::Basename qw(basename);

sub libscan {
    my ($self, $file) = @_;
    my $bfile = basename($file);

    return if $bfile =~ /\.swp$/;
    return if $bfile =~ /^\.(?:cvs)?ignore$/;

    return $self->SUPER::libscan($file);
}

