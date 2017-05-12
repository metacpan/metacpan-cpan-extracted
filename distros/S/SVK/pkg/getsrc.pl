#!/usr/bin/perl -w
use strict;
use YAML::Syck 'LoadFile';

my $requires = LoadFile('../META.yml')->{requires};
my @deps = ((keys %$requires), qw(SVN::Simple PathTools TermReadKey PerlIO::via::Bzip2 PerlIO::gzip SVN::Dump Test::More Locale::Maketext::Lexicon Locale::Maketext::Simple IO::Pager Log::Log4perl SVN::Mirror Compress::Zlib FreezeThaw Scalar-List-Utils ));


push @deps, qw(Scalar-List-Utils Class-Autouse version Sub-Uplevel Test-Simple Test-Exception Data-Hierarchy PerlIO-via-dynamic PerlIO-via-symlink SVN-Simple PerlIO-eol Algorithm-Diff Algorithm-Annotate Pod-Escapes Pod-Simple IO-Digest TimeDate Getopt-Long Encode PathTools YAML-Syck Locale-Maketext-Simple App-CLI List-MoreUtils Path-Class Class-Data-Inheritable Class-Accessor UNIVERSAL-require File-Temp Log-Log4perl Locale-Maketext-Lexicon TermReadKey IO-Pager);


for my $dep (@deps) {
    $dep =~ s/::/-/g;
    my $file = `locate minicpan | ack '/$dep-(\\d)' | head -1`;
    chomp $file;
#    warn $dep unless $file;
    `cp -f $file src/` if $file;

}
