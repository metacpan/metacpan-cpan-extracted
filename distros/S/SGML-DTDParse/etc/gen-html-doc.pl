#!/usr/bin/perl -w
# $Id: gen-html-doc.pl,v 2.1 2005/07/16 03:43:02 ehood Exp $
# Description: Script to convert POD to HTML
#

use Cwd;
use File::Find;
use File::Path;
use Getopt::Long;
use Pod::Find qw(pod_find);
use Pod::Html;

# Script globals/defaults
my $cwd		      = getcwd;
my $infile_path_root  = $cwd;
my $outfile_path_root = join('/', $cwd, 'doc', 'html');
my $toc_file          = join('/', $outfile_path_root, 'index.html');
my $pod_cache_dir     = join('/', $cwd, 'doc');
my @pod_dirs	      = ('bin', 'lib');

MAIN: {
  # Get command-line options
  my %opt = ( );
  GetOptions(\%opt,
      'inroot=s',
      'outroot=s',
      'cachedir=s',
      'poddir=s@',
  );
  $infile_path_root  = Cwd::abs_path($opt{'inroot'})
      if defined($opt{'inroot'});
  $outfile_path_root = Cwd::abs_path($opt{'outroot'})
      if defined($opt{'outroot'});
  @pod_dirs          = @{$opt{'poddir'}}
      if defined($opt{'poddir'});
  $pod_cache_dir     = Cwd::abs_path($opt{'cachedir'})
      if defined($opt{'cachedir'});

  $toc_file	     = join('/', $outfile_path_root, 'index.html');

  my %pods = pod_find({ -verbose => 0 }, 'bin', 'lib');
  foreach my $key (sort keys %pods) {
    convert_pod($key, $pods{$key});
  }
  build_toc();
}

#############################################################################

sub convert_pod {
  my $podfile = shift;
  my $title   = shift;
  if ($podfile =~ m{$infile_path_root/(.*)/(.*?)(\.p(?:[lm]|od))?$}i) {
    my $path = $1;
    my $name = $2;
    my $ext  = $3 || "";
    my $html_root = $path;
    $html_root =~ s/[^\/]+/../g;

    print STDOUT "Htmlizing $path/$name$ext\n";

    mkpath(join('/', $outfile_path_root, $path));
    pod2html(
	'--cachedir='.$pod_cache_dir,
	'--infile='.$podfile,
	'--outfile='.join('/', $outfile_path_root, $path, $name.'.html'),
	'--podroot='.$infile_path_root,
	'--podpath=bin:lib',
	'--htmlroot='.$html_root,
	#'--title='.$title,
	'--header',
	'--quiet',
    );
  }
}

sub build_toc {
  my $title = shift || "Package Documentation";
  rename $toc_file, $toc_file.'.bak';

  chdir $outfile_path_root;
  my %lib_docs = ();
  my %script_docs = ();
  my %docs = ();

  find(sub {
    return  unless /\.html?$/;
    local *H;
    if (!open(H, $_)) {
      warn qq{Warning: Unable to open "$File::Find::name": $!\n};
      return;
    }
    my $title = $File::Find::name;
    my $l;
    while (defined($l = <H>)) {
      last  if $l =~ /<body/i;
      if ($l =~ m{<title>(.*?)</title>}i) {
	$title = $1;
	last;
      }
    }
    close(H);
    if ($File::Find::name =~ m{(?:/|\b)lib/}) {
      $lib_docs{$File::Find::name} = $title;
    } elsif ($File::Find::name =~ m{(?:/|\b)(?:bin|scripts?)/}) {
      $script_docs{$File::Find::name} = $title;
    } else {
      $docs{$File::Find::name} = $title;
    }
  }, '.');

  local *TOC;
  open(TOC, '>'.$toc_file) ||
      die qq{Error: Unable to create "$toc_file": $!\n};
  print TOC <<"EOT";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
		      "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>$title</title>
</head>
<body style="background-color: white">
<h1>$title</h1>
EOT

  if (%script_docs) {
    print TOC '<h2>Scripts</h2>', "\n";
    print_doc_group(\*TOC, \%script_docs);
  }

  if (%lib_docs) {
    print TOC '<h2>Modules</h2>', "\n";
    print_doc_group(\*TOC, \%lib_docs);
  }

  if (%docs) {
    print TOC '<h2>Other</h2>', "\n";
    print_doc_group(\*TOC, \%docs);
  }

  print TOC <<EOT;
</body>
</html>
EOT

  close(TOC);
  unlink $toc_file.'.bak';
}

sub print_doc_group {
  my $fh = shift;
  my $docs = shift;
  print $fh '<ul>', "\n";
  foreach my $doc (sort { $docs->{$a} cmp $docs->{$b} } keys %$docs) {
    print $fh '<li><a href="', $doc, '">', $docs->{$doc}, '</a></li>', "\n";
  }
  print $fh '</ul>', "\n";
}
