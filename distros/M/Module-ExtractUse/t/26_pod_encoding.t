use strict;
use Test::More tests => 1;

use Module::ExtractUse;

# The following test dies with Pod::Simple >= 3.26
# because of the nested encoding
{
my $p = Module::ExtractUse->new;
is $p->extract_use(\(<<'CODE'))->string, '5.010';
=pod

=head1 NAME

=encoding utf-8

=encoding utf-8

=cut
use 5.010;
CODE
}
