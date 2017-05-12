#!/usr/bin/perl --  ========================================== -*-perl-*-
#
# t/20-references.t
#
# Test the Latex plugin's ability to re-run Latex to resolve forward references
#
# Written by Andrew Ford <a.ford@ford-mason.co.uk>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use strict;
use warnings;
use FindBin qw($Bin);
use Cwd qw(abs_path);
use lib ( abs_path("$Bin/../lib"), "$Bin/lib" );
use Template;
use Template::Test;
use Template::Test::Latex;
use File::Spec;

my $run_tests = $ENV{LATEX_TESTING} || $ENV{ALL_TESTING};


my $out = 'output';
my $dir = -d 't' ? File::Spec->catfile('t', $out) : $out;

require_dvitype();

my $files = {
    pdf => 'test1.pdf',
    ps  => 'test1.ps',
    dvi => 'test1.dvi',
};
clean_file($_) for values %$files;

    
my $ttcfg = {
    OUTPUT_PATH  => $dir,
    INCLUDE_PATH => [ "$FindBin::Bin/input" ],
    VARIABLES => {
        dir   => $dir,
        file  => $files,
        check => \&check_file,
	grep_dvi => sub { grep_dvi($dir, @_) },
    },
};

if ($run_tests){
    test_expect(\*DATA, $ttcfg);
} else {
    skip_all 'Tests skipped, LATEX_TESTING and ALL_TESTING not set';
}

sub clean_file {
    my $file = shift;
    my $path = File::Spec->catfile($dir, $file);
    unlink($file);
}

sub check_file {
    my $file = shift;
    my $path = File::Spec->catfile($dir, $file);
    return -f $path ? "PASS - $file exists" : "FAIL - $file does not exist";
}



__END__

# Check that forward references work
-- test --
[% USE Latex;
   FILTER latex(file.dvi)
-%]
\documentclass{article}
\begin{document}
\section{Introduction}
See page~\pageref{pagetwo}.
\par
\pagebreak
This is the second page\label{pagetwo}.
\end{document}
[% END -%]
[% grep_dvi(file.dvi, 'See page 2') %]
-- expect --
-- process --
PASS - found 'See page 2'



