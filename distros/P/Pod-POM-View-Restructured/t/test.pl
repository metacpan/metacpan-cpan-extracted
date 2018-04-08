#!/usr/local/bin/perl

# Original authors: don
# $Revision: $


use strict;
use warnings;
use Carp;
use Getopt::Long qw(:config no_ignore_case bundling);
use Pod::POM;

# main
{
    # local($SIG{__DIE__}) = sub { &Carp::confess };
    my $self = bless { };

    my $top_dir;
    # Set up @INC to get right version of module
    use File::Spec ();
    BEGIN {
        my $path = File::Spec->rel2abs($0);
        (my $dir = $path) =~ s{(?:/[^/]+){2}\Z}{};
        # unshift @INC, $dir . "/blib/lib", $dir . "/blib/arch";
        unshift @INC, $dir . "/lib";

        $top_dir = $dir;
    }

    my $test_dir = $top_dir . "/test_doc/source";

    use Pod::POM::View::Restructured;

    my $view = Pod::POM::View::Restructured->new;
    my $parser = Pod::POM->new;
    my $pom = $parser->parse_file("$top_dir/lib/Pod/POM/View/Restructured.pm");
    my $out = $pom->present($view);

    my $out_file = $test_dir . "/restructured.rst";
    open(my $out_fh, '>', $out_file) or die "couldn't open output file $out_file";
    binmode($out_fh, ':utf8');
    print $out_fh $out;
    close $out_fh;
    
    # print "output:\n\n$out\n";
    
}

exit 0;

###############################################################################
# Subroutines
