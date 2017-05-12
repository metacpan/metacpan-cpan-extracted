#!/usr/bin/perl -w                                         # -*- perl -*-

use strict;
use lib qw( ./lib ../lib );
use Pod::POM::Test;
#$Pod::POM::Node::DEBUG = 1;
my $DEBUG = 1;

ntests(2);

my $text;
{   local $/ = undef;
    $text = <DATA>;
}

my $parser = Pod::POM->new();
my $pom = $parser->parse_text($text);
assert( defined $pom );

my $out = "$pom";

$out =~ s/\s+$//;

match( $out, $text );

__DATA__
=over 4

=item Foo

This is Foo

=item Bar

This is Bar

=over 4

=item Bar/Baz

This is Bar/Baz

=back

=item Baz

This is Baz

=back