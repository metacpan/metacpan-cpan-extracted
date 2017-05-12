#!perl

use strict;
use warnings;
use Path::Tiny;
use Archive::Any::Lite;
use CPAN::DistnameInfo;

my $start_id = '';

$Archive::Any::Lite::IGNORE_SYMLINK = 1;
$Archive::Tar::CHMOD = 0;
$Archive::Tar::CHOWN = 0;
my @authors = get_authors();
my %seen;
for my $author (@authors) {
  next if $start_id && $start_id ne $author;
  $start_id = '';

  my $author_path = join '/', substr($author, 0, 1), substr($author, 0, 2), $author;
  my $root = path("$ENV{HOME}/minicpan/authors/id/$author_path");
  my $dest = path("$ENV{HOME}/minicpan_extracted/$author");
  $dest->mkpath;
  for my $file ($root->children) {
    next unless $file =~ /(?:\.tar\.gz|\.zip)$/;
    my $dist = CPAN::DistnameInfo->new("$file")->dist;
    next if $seen{$dist}++;
    next if $dist =~ /Perl6|Pugs|parrot|Perlito|Seis/;
    print "extracting $file...\n";
    eval { Archive::Any::Lite->new("$file")->extract($dest) };
  }
}

sub get_authors {
  my $xmlfile = path("$ENV{HOME}/minicpan/authors/00whois.xml");
  open my $fh, '<', $xmlfile;
  my @authors;
  while(<$fh>) {
    my ($author) = m{<id>(\w+)</id>} or next;
    my $author_path = join '/', substr($author, 0, 1), substr($author, 0, 2), $author;
    push @authors, $author if -e "$ENV{HOME}/minicpan/authors/id/$author_path";
  }
  close $fh;
  @authors;
}
