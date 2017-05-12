#===============================================================================
#
#  DESCRIPTION:  Tests Parser
#
#       AUTHOR:  Ivan Baidakou, <dmol@cpan.org>
#===============================================================================
package main;
use strict;
use warnings;
use Test::More tests => 2;
use Data::Dumper;
use Perl6::Pod::Utl;


{
    my $t = Perl6::Pod::Utl::parse_pod(<<T, default_pod=>1);
=begin para
P

=begin code
a = 5;
=end code
=end code

=end para
T
    ok !$t, "Wrong pod6 isn't parsable";
}


{
    my $t = Perl6::Pod::Utl::parse_pod(<<T, default_pod=>1);
=begin para
P

=begin code
a = 5;
=end code

=end para
T
    ok $t, "Right pod6 is parsable";
}
