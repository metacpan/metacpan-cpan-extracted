package String::Normal::Config::BusinessCompress;
use strict;
use warnings;

use String::Normal::Config;

sub _data {
    my %params = @_;

    my $fh;
    if ($params{business_compress}) {
        open $fh, $params{business_compress} or die "Can't read '$params{business_compress}' $!\n";
    } else {
        $fh = *DATA;
    }

    my %compress;
    for (String::Normal::Config::_expand_ranges( String::Normal::Config::_slurp( $fh ) )) {
        String::Normal::Config::_attach( \%compress, split '-', $_ );
    }

    return \%compress;
}

1;

=head1 NAME

String::Normal::Config::BusinessCompress;

=head1 DESCRIPTION

This package defines compressions to be performed on Business types.

=head1 STRUCTURE

One entry per line, each entry contains the multi word term joined by dashes (C<->):

  foo-bar-baz

Would compress C<foo> C<bar> and C<baz> so long as they are found in that order
in the token list. Consider the many different varations of the word "barbecue" and
you might see where this kind of transformation is valuable in detecting potential
duplicates.

You can provide your own data by creating a text file containing your
values and provide the path to that file via the constructor:

  my $normalizer = String::Normal->new( business_compress => '/path/to/values.txt' );

=head1 AUTHOR

Jeff Anderson, C<< <jeffa at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2024 Jeff Anderson.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

__DATA__
1-2-1
1-2-3
1-800 
1-850
1-866
1-877
1-888 
3-[a-z]
4-[a-z]
5-[a-z]
6-[a-z]
7-[a-z]
8-[a-z]
9-[a-z]
9-1-1
a-1 
a-c
air-cond
air-condition 
air-conditioning
all-state
a-way
babies-r-us
bar-b-cue
bar-be-que
barber-shop
barb-q
bar-bq
bar-b-q
bar-b-que
bar-b-ques
b-b-q
b-b-que
built-in
built-ins
carry-out
car-wash
check-in
chem-dry
child-care
chik-fil-a
clean-up
close-out
close-outs
coffee-house
coffee-houses
coffee-shop
coffee-shops
co-op
co-ops
co-ordinator
d-1
d-2
day-care
day-spa
disc-jockey
d-j
d-js
drive-in
drive-inn
drive-ins
dry-clean
dry-cleaner
dry-cleaners
dry-cleaning
dry-clnr
dry-clnrs
dry-wall
e-commerce
eye-care
hair-care
hair-cut
hair-cuts
hair-cutting
hair-styling
hair-stylist
hair-stylists
hand-craft
hand-crafted
hand-wash
handy-man
head-quarter
head-quarters
health-care
hide-away
hide-a-way
high-school
home-care
i-[2-5]
i-10
i-101
i-105
i-15
i-16
i-17
i-20
i-2000
i-205
i-24
i-240
i-25
i-26
i-27
i-271
i-275
i-29
i-295
i-30
i-35
i-37
i-40
i-43
i-44
i-440
i-45
i-475
i-49
i-495
i-500
i-515
i-55
i-57
i-59
i-630
i-64
i-65
i-68
i-69
i-70
i-71
i-74
i-75
i-76
i-77
i-78
i-79
i-80
i-81
i-84
i-85
i-86
i-880
i-90
i-93
i-94
i-95
i-96
i-99
ice-cream
in-line
in-n-out
inter-continental
inter-state
i-phone
jiu-jitsu
ju-jitsu
k-[1-16]
k-101
k-105
k-106 
k-119
k-24
k-25
k-38
k-40
k-911
k-97
k-99
kinder-care
k-mart
knock-out
l-1
l-10
l-14
l-2 
l-3
l-4
l-5
l-6
l-a
lawn-care
la-z-boy
lock-smith
m-[1-9]
m-104
m-120
m-13
m-140
m-15
m-18
m-19
m-20
m-21
m-24
m-25
m-28
m-30
m-32
m-33
m-34
m-37
m-40
m-44 
m-45
m-46
m-50
m-51
m-52
m-55
m-57
m-59
m-60
m-64
m-65
m-66
m-72
m-80
m-82
m-89
m-90
m-97
m-99
make-up
med-care
medi-care
medi-spa
mid-town
mid-way
mid-west
multi-media
neighbor-hood 
nor-cal
north-east
north-shore
north-west
n-y
ob-gyn
ob-gyne
on-line
on-site
ox-bow
pay-less
pet-sitter
pet-sitters
pet-sitting
pick-up
pipe-line
pop-corn
pre-k
pre-kindergarten
pre-kndrgrtn
pre-owned 
pre-paid
pre-sch
pre-schl
pre-schls
pre-school
pre-schools
price-less
radio-shack
re-cycle
re-new
r-v
sub-way
super-market
super-markets
t-[1-9]
taekwon-do
tae-kwon-do
take-out
t-bone
t-bones
tee-shirt
tee-shirts
time-out
t-mobile
t-n-t
toys-r-us
trans-america
trans-atlantic
trans-continental
t-rex
tri-star
tri-state
t-shirt
t-shirts
t-v
u-[1-5]
u-box
u-haul
up-state
u-s
v-[1-9]
w-[1-9]
walk-in
wal-mart
world-wide
x-[1-9]
x-15
x-19
x-change
x-pert
x-perts
x-press
x-ray
x-rays
x-tra
x-treme
y-[1-9]
y-12
z-[1-9]
z-93
