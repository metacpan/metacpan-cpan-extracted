package String::Normal::Config::AddressStem;
use strict;
use warnings;

use String::Normal::Config;

sub _data {
    my %params = @_;

    my $fh;
    if ($params{address_stem}) {
        open $fh, $params{address_stem} or die "Can't read '$params{address_stem}' $!\n";
    } else {
        $fh = *DATA;
    }

    my %stem = String::Normal::Config::_slurp( $fh );
    return \%stem;
}

1;

=head1 NAME

String::Normal::Config::AddressStem;

=head1 DESCRIPTION

This package defines removals to be performed on Address type.

=head1 STRUCTURE

One entry pair per line: first the value to be matched then the value
to be changed to. For example:

  foo fu

Would change all occurances of C<foo> to C<fu>. See C<__DATA__> block below.

You can provide your own data by creating a text file containing your
values and provide the path to that file via the constructor:

  my $normalizer = String::Normal->new( address_stem => '/path/to/values.txt' );

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
allee aly
alley aly
ally aly
anex anx
annex anx
annx anx
apartment apt
arcade arc
av ave
aven ave
avenu ave
avenue ave
avn ave
avnue ave
basement bsmt
bayoo byu
bayou byu
beach bch
bend bnd
bluf blf
bluff blf
bluffs blf
bot btm
bottm btm
bottom btm
boul blvd
boulevard blvd
boulv blvd
branch br
brdge brg
bridge brg
brnch br
brook brk
brooks brk
building bldg
burg bg
burgs bg
bypa byp
bypas byp
bypass byp
byps byp
camp cp
canyn cyn
canyon cyn
cape cpe
causewa cswy
causeway cswy
cen ctr
cent ctr
center ctr
centr ctr
centre ctr
circ cir
circl cir
circle cir
circles cir
cliff clf
cliffs clf
club clb
cmp cp
cnter ctr
cntr ctr
cnyn cyn
common cmn
commons cmn
corner cor
corners cor
course crse
court ct
courts ct
cove cv
coves cv
crcl cir
crcle cir
creek crk
crescent cres
crest crst
crossing xing
crossroad xrd
crossroads xrd
crsent cres
crsnt cres
crssng xing
cswy cswy
curve curv
dale dl
dam dm
department dept
div dv
divide dv
driv dr
drive dr
drives dr
drv dr
dvd dv
east e
estate est
estates est
expr expy
express expy
expressway expy
expw expy
extension ext
extensions ext
extn ext
extnsn ext
falls fl
ferry fry
field fld
fields fld
flat flt
flats flt
floor fl
ford frd
fords frd
forest frst
forests frst
forg frg
forge frg
forges frg
fork frk
forks frk
fort ft
freeway fwy
freewy fwy
front frnt
frry fry
frt ft
frway fwy
frwy fwy
garden gdn
gardens gdn
gardn gdn
gateway gtwy
gatewy gtwy
gatway gtwy
glen gln
glens gln
grden gdn
grdn gdn
grdns gdn
green grn
greens grn
grov grv
grove grv
groves grv
gtway gtwy
gtwy gtwy
hanger hngr
harb hbr
harbor hbr
harbors hbr
harbr hbr
haven hvn
heights hts
highway hwy
highwy hwy
hill hl
hills hl
hiway hwy
hiwy hwy
hllw holw
hollow holw
hollows holw
holws holw
hrbor hbr
ht hts
hway hwy
inlet inlt
island is
islands is
isles isle
islnd is
islnds is
jction jct
jctn jct
jctns jct
junction jct
junctions jct
junctn jct
juncton jct
key ky
keys ky
knol knl
knoll knl
knolls knl
lake lk
lakes lk
landing lndg
lane ln
ldge ldg
light lgt
lights lgt
lndng lndg
loaf lf
lobby lbby
lock lck
locks lck
lodg ldg
lodge ldg
loops loop
lower lowr
manor mnr
manors mnr
mdws mdw
meadow mdw
meadows mdw
medows mdw
mill ml
mills ml
mission msn
mnt mt
mntain mtn
motorway mtwy
mount mt
mountain mtn
mountains mtn
mountin mtn
mtin mtn
neck nck
north n
northeast ne
northwest nw
office ofc
orchard orch
orchrd orch
overpass opas
ovl oval
parks park
parkway pkwy
parkways pkwy
parkwy pkwy
passage psge
paths path
penthouse ph
pikes pike
pine pne
pines pne
pkway pkwy
pkwys pkwy
pky pkwy
place pl
plain pln
plains pln
plaza plz
point pt
points pt
port prt
ports prt
prairie pr
prk park
prr pr
rad radl
radial radl
radiel radl
ranch rnch
ranches rnch
rapid rpd
rapids rpd
rdge rdg
rest rst
ridge rdg
ridges rdg
river riv
rivr riv
rnchs rnch
road rd
roads rd
room rm
route rte
rvr riv
shoal shl
shoals shl
shoar shr
shoars shr
shore shr
shores shr
skyway skwy
south s
southeast se
southwest sw
space spc
spng spg
spngs spg
spring spg
springs spg
sprng spg
sprngs spg
spurs spur
sqr sq
sqre sq
squ sq
square sq
squares sq
station sta
statn sta
stn sta
str st
strav stra
straven stra
stravenue stra
stravn stra
stream strm
street st
streets st
streme strm
strt st
strvn stra
strvnue stra
suite ste
sumit smt
sumitt smt
summit smt
terr ter
terrace ter
throughway trwy
trace trce
traces trce
track trak
tracks trak
trafficway trfy
trail trl
trailer trlr
trails trl
trk trak
trks trak
trlrs trlr
trls trl
trnpk tpke
tunls tunl
tunnel tunl
tunnels tunl
tunnl tunl
turnpike tpke
turnpk tpke
underpass upas
union un
unions un
upper uppr
valley vly
valleys vly
vally vly
vdct via
viadct via
viaduct via
view vw
views vw
vill vlg
villag vlg
village vlg
villages vlg
ville vl
villg vlg
villiage vlg
vist vis
vista vis
vlly vly
vst vis
vsta vis
walks walk
ways way
well wl
wells wl
west w
wy way
one 1
tenth 10th
eleventh 11th
twelfth 12th
thirteenth 13th
fourteenth 14th
fifteenth 15th
sixteenth 16th
seventeenth 17th
eighteenth 18th
nineteenth 19th
first 1st
twentieth 20th
second 2nd
thirtieth 30th
third 3rd
fortieth 40th
fourth 4th
fiftieth 50th
fifth 5th
sixtieth 60th
sixth 6th
seventh 7th
eighth 8th
ninth 9th
apartments apt
apts apt
bgs bg
bldgs bldg
buildings bldg
blfs blf
bl blvd
blvrd blvd
brks brk
cirs cir
clfs clf
cmns cmn
county cnty
cors cor
corporation corp
corporate corpor
cresent cres
crscnt cres
causway cswy
crt ct
cts ct
centers ctr
centres ctr
ctrs ctr
cvs cv
del de
departments dept
depts dept
drs dr
ests est
exp expy
exts ext
floors fl
flr fl
flds fld
flts flt
forrest forest
frds frd
frgs frg
frks frk
frsts frst
gdns gdn
general gen
generals gen
glns gln
government govern
governments govern
govnmt govern
govnmts govern
govt govern
govts govern
gvrnmnt govern
gvrnmnts govern
grns grn
grvs grv
hbrs hbr
hls hl
height hts
hghts hts
hgts hts
havn hvn
interstate i
industry ind
indstrl indl
industrial indl
international intl
iss is
jcts jct
junior jr
knls knl
kys ky
lcks lck
lodges ldg
lgts lgt
lks lk
lanes ln
malls mall
medcl med
medical med
ml ml
martinlking mlk
martinlutherking mlk
martinlutherkng mlk
mlking mlk
mnrs mnr
missn msn
mssn msn
mntn mtn
mtns mtn
newhampshire nh
olde old
pke pike
plaines pln
plns pln
plza plz
pnes pne
prarie pr
prts prt
pts pt
rds rd
rdgs rdg
rpds rpd
so s
sch schl
school schl
schools schl
shls shl
shopping shop
shpg shop
shrs shr
spgs spg
sqrs sq
sqs sq
stateroad sr
stateroute sr
saint st
sts st
strave stra
tpk tpke
trailers trlr
tunel tunl
texas tx
uns un
unitedstates us
vlgs vlg
vlys vly
vws vw
vws vw
wshngtn washington
wls wl
crssing xing
xrds xrd
