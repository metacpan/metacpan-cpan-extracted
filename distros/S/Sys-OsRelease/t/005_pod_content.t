#
#===============================================================================
#         FILE: 005_pod_content.t
#  DESCRIPTION: POD content tests for Sys::OsRelease
#       AUTHOR: Ian Kluft (IKLUFT)
#      VERSION: 1.0
#      CREATED: 08/19/2026 10:32:01 PM
#===============================================================================

## no critic (Modules::RequireExplicitPackage)
use strict;
use warnings;
use autodie;
use Carp qw(croak);
use Pod::Simple::SimpleTree;
use Sys::OsRelease;

use Test::More;                      # last test to print

# configuration constants
my $MODULE = "Sys::OsRelease";  # do not optimize: source code is filtered in ...::Lite to modify module name
my $FILENAME = 'lib/' . join( '/', split( '::', $MODULE )) . '.pm';
my $SEARCH_HEAD2 = 'The os-release Standard';
my $SEARCH_TEXT = 'Current attributes recognized by ';
my $TEXTLEN = length( $SEARCH_TEXT );

# search a section's text for the line with the list of supported attributes
sub search_section
{
    my $root = shift;
    my $i = shift;
    my $offset = 1;
    while (( exists $root->[$i + $offset]) and substr( $root->[$i + $offset][0], 0, 4 ) ne 'head' ) {
        if ( $root->[$i + $offset][0] eq 'Para' ) {
            foreach my $str ( @{$root->[$i + $offset]} ) {
                next if ref $str;
                if ( substr( $str, 0, $TEXTLEN ) eq $SEARCH_TEXT ) {
                    return $str;  # found the paragraph with the attribute names
                }
            }
        }
        $offset++;
    }
    return;
}

# extract line with list of supported attributes
# this requires intricate digging into the POD tree data
sub get_attr_line
{
    my $tree = Pod::Simple::SimpleTree->new->parse_file( $FILENAME );
    if ( ref $tree ne "Pod::Simple::SimpleTree" ) {
        croak "Pod::Simple::SimpleTree returned ref expected, got " . ( ref $tree );
    }
    my $root = $tree->root();
    for ( my $i=0; $i < scalar @$root; $i++ ) {
        if ( ref $root->[$i] eq "ARRAY" ) {
            if ( $root->[$i][0] eq 'head2' and $root->[$i][2] eq $SEARCH_HEAD2 ) {
                my $value = search_section( $root, $i );
                if ( defined $value ) {
                    return $value;
                }
                last;
            }
        }
    }
    return;
}

# test mainline
my @std_attrs = Sys::OsRelease::std_attrs();
plan tests => ( scalar @std_attrs );

# check that each attribute used occurs in the POD documentation
# POD scanning borrowed from Test::Pod::Content, didn't use it because it would re-open file for each attr
my $attr_line = get_attr_line();
foreach my $attr_name ( @std_attrs ) {
    like $attr_line, qr( \b $attr_name \b )ix, "found $attr_name in POD";
}
1;
