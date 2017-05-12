#! /usr/bin/perl
#
#===============================================================================
#
#         FILE:  utility.t
#
#  DESCRIPTION:  Test utility functions
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Geoffrey Leach, <geoff@hughes.net>
#      VERSION:  1.1.11
#      CREATED:  10/25/07 11:30:15 PDT
#     REVISION:  ---
#    COPYRIGHT:  (c) 2008-2010 Geoffrey Leach
#===============================================================================

use 5.006002;

use strict;
use warnings;

use Test::More tests => 9;

BEGIN {
    use_ok(q{Pod::HtmlEasy});
    use_ok( q{Pod::HtmlEasy::Data},
        qw(NL EMPTY css head title headend body podon podoff) );
}

my $htmleasy = Pod::HtmlEasy->new;
ok( defined $htmleasy, q{New HtmlEasy} );

$htmleasy->pod2html(
    \*DATA,
    no_css       => 1,
    no_index     => 1,
    no_generator => 1,
    only_content => 1,
);

#--------------------------- test 4

my $pm_pkg = $htmleasy->pm_package;
is( $pm_pkg, q{Pod::Test}, q{pm_package()} );

#--------------------------- test 5

my $pm_ver = $htmleasy->pm_version;
is( $pm_ver, q{1.0}, q{pm_version()} );

#--------------------------- test 6

my $pm_nam = $htmleasy->pm_name;
is( $pm_nam, q{Testing POD}, q{pm_name()} );

#--------------------------- test 7

my @pm = $htmleasy->pm_package_version_name;
is_deeply( \@pm, [ q{Pod::Test}, q{1.0}, q{Testing POD} ],
    q{pm_package_version_name()} );

#--------------------------- test 8

my @css      = $htmleasy->default_css;
my @css_base = css();
is_deeply( \@css, \@css_base, q{default_css()} );

#--------------------------- test 9

# Pod input from DATA, scalar output
# <DATA> at eof
my $html = $htmleasy->pod2html(
    \*DATA,
    no_css       => 1,
    no_index     => 1,
    no_generator => 1,
);

my @expect = head();
push @expect, title(q{<DATA>});
push @expect, headend();
push @expect, body();
push @expect, podon();
push @expect, podoff();

@expect = map { $_ . NL } @expect;
my $expect = join EMPTY, @expect;
is( $html, $expect, q{Scalar output} );

__END__

package Pod::Test;
my $VERSION = 1.0;
=pod

=head1 NAME Testing POD

=cut
