#!perl -w

use strict;

=head1 NAME

eg.t - Tests that C<eg/ClassClassWithTestsAtTheEnd.pm> works

=cut

system($^X, "eg/ClassWithTestsAtTheEnd.pm");
1;
