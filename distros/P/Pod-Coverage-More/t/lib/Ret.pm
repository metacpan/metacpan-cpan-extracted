package Ret;

use 5.036;
use warnings FATAL => q{all};

# The return values here are idioms that the analyzer must read, and these policies forbid some of them:
# a value that falls off the end of a sub, the unused variable that it returns, and one-argument bless.
## no critic (Subroutines::RequireFinalReturn Variables::ProhibitUnusedVarsStricter ClassHierarchies::ProhibitOneArgBless)

=head1 t/Ret.pm - Test return values

=head2 ret1

Returns 1.

=cut

#Test base returns
sub ret1 {
    return 1;
}

=head2 ret2

Returns undef.

=cut

sub ret2 {
    return undef;
}

=head2 ret3

returns undef

=cut

sub ret3 {
    return;
}

=head2 ret4

returns SCALAR.

=cut

sub ret4 {
    my $sym;
    return $sym;
}

=head2 ret5

returns ARRAY.

=cut

#Fall-through return
sub ret5 {
    my @other_sym;
}

=head2 ret6

returns ARRAYREF of integers.

=cut

#Compound data types
sub ret6 {
    return [ 1, 2, 3 ];
}

=head2 ret7

returns ARRAY of integers.

=cut

sub ret7 {
    return ( 1, 2, 3 );
}

=head2 ret8

returns HASHREF.

=cut

sub ret8 {
    return { 'a' => 'b', 'c' => 'd' };
}

=head2 ret9

returns HASH.

=cut

sub ret9 {
    return ( 'a' => 'b', 'c' => 'd' );
}

=head2 ret10

returns someClass object.

=cut

#Check objects
sub ret10 {
    return bless( 'a', 'someClass' );
}

=head2 ret11

returns output of function ret1.

=cut

#The big kahuna -- walk functions
sub ret11 {
    return ret1( 'a', 'b' );
}

=head2 ret12(abcd)

Returns MIXED: 1 or 0

=cut

#Test conditional returns
sub ret12 {
    if (1) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 ret13

Returns MIXED: 1 or 0

=cut

sub ret13 {
    unless (1) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 ret14

returns MIXED: whee or zop

=cut

sub ret14 {
    return 'whee' if 1;
    return "zop";
}

=head2 ret15

return MIXED: eeny oony wanah

=cut

sub ret15 {
    return 'eee' unless 1;
    return 0 ? 'nny' : 'wnnh';
}

=head2 ret16

returns instance of class 'eee'.

=cut

sub ret16 {
    return bless 'whee', 'eee';
}

=head2 ret17

returns instance of class 'eee'

=cut

sub ret17 {
    return ( bless 'whee', 'eee' );
}

=head2 ret18

Returns new Ret object.

=cut

sub ret18 {
    return bless 'ehee';
}

=head2 ret19

Returns new "b" object.

=cut

sub ret19 {
    return bless( 'a', 'b' );
}

=head2 ret20

Returns STRING gravy.

=cut

#Test stupid things like assignment as the return (common in oo)
sub ret20 {
    return my $nugs = 'gravy';
}

#TODO other useless BS like switch statements, etc

1;
