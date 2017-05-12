#!/usr/bin/perl

=head1 NAME

meta-from-extracted - get meta information from a perl module

=head1 SYNOPSIS

meta-from-extracted <perl-module-directory> <meta-info-directory>

=head1 DESCRIPTION


The program creates or updates the B<meta-info-directory> from the
contents of the B<perl-module-directory>.  The
B<perl-module-directory> should contain perl module distribution files
(.tar.gz)

The meta information is placed into a series of directories in the
C<meta-info-directory> with the same name as the module distribution
file.

This meta information can then be used during perl module packaging.

E.g.

   cp PerlModule.tar.gz PerlModule2.tar.gz /build/modules/
   mkdir /build/meta
   meta-from-perl-mods.pl /build/modules /build/meta
   cpanflute --meta-info=/build/meta /build/modules/PerlModule2.tar.gz

If you have a version of cpanflute which understands how to read the
meta information.

=head1 PERL META INFORMATION STORAGE

The meta information is currently stored in various separate files in
a directory.  There have been various other proposals for a format for
storing meta info for perl.  These include using a single hash in a
file and using XML.  I like the directory system because a) it is
simple and b) it is simple and c) it can be changed later anyway.  c)
means that this interface may be changed.  If you start to write
software that relies on having a consistent interface then please tell
me first.

Once the meta information has been gathered it can be used in module
creation with a piece of software which understands the format of the
directory.

=head1 AUTHORS

Michael De La Rue.  +48 601 270 between 08 and 20 GMT.  N.B. this
number is expensive from everywhere in the world.

Email me as mikedlr@tardis.ed.ac.uk.  Response within approx 6 months.
Not guarateed.

C<meta-from-perl-mods> a program for extracting meta information from
perl modules is released under the GNU General Public license, version
2 or (at your option) later.  A copy of the GNU General Public License
should have been included in your distribution.

=head1 META INFORMATION

=item *

description

=item *

requirements

=item *

summary ???

=item *

list of documentation files

=head1 NON-META INFO

=cut

use warnings;
use strict;
use Module::MetaInfo;
use Getopt::Long;

my $verbose=undef;
my $scratchdir=undef;

GetOptions( 'verbose|v' => \$verbose, 'scratchdir|s' => \$scratchdir );

$scratchdir && do {
  Module::MetaInfo->scratch_dir($scratchdir);
};
$verbose && do {
  Module::MetaInfo->verbose($verbose);
};

my $mod_dir=shift;
my $meta_dir=shift;

$meta_dir or die "usage: meta-from-modules <mod_dir> <meta_dir>";

opendir MODDIR, $mod_dir || die "cant opendir $mod_dir: $!";

-d $meta_dir or die "the meta dir directory $meta_dir doesn't exist";

sub junk(){};

while (my $modfile=readdir MODDIR) {
  next unless $modfile =~ m/(\.tar\.gz)|(\.tgz)$/;
  my $meta=new Module::MetaInfo $mod_dir . "/" . $modfile;
  my $desc=$meta->description();
  my @doc=$meta->doc_files();
  my $mmdir=$meta_dir . "/" . $modfile;
  mkdir $mmdir || die "Couldn't create directory $mmdir: $!";
  die "can't cope with filenames with newlines!!!"
    if grep ( /\n/, @doc );
  if ( $desc ) {
    my $descfile = ">" . $mmdir . "/description";
    print STDERR "printing description to $descfile\n";
    open DESC, $descfile or die "couldn't open file $descfile: $!";
    print DESC $desc;
    close DESC or die "couldn't close file $descfile: $!";
  }
  if ( @doc ) {
    my $docfile = ">" . $mmdir . "/docs";
    print STDERR "printing doc files to $docfile\n";
    open DOC, $docfile or die "couldn't open file $docfile: $!";
    print DOC "%doc ", ( join "\n%doc ", @doc), "\n";
    close DOC or die "couldn't close file $docfile: $!";
  }

}
print STDERR "hmm.. finished\n";
