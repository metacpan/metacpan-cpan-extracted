* weired net list to test spice.pm package.

.Global vdd vss
.subckt inv a y
+ wp=0 wn=0 lp=1.0e-07 ln=1.0e-07
m1 y a vdd vdd p l=lp w=wp m=1
m2 y a vss vss n l=ln w=wn m=1
.ends

.subckt nand2 a b y
+ wnC=0 wpC=0 wp1=wpC wp2=wpC wn1=wnC wn2=wnC lp1=1.0e-07 lp2=1.0e-07
+ ln1=1.5e-07 ln2=1.5e-07
m14 y a net14 vss n l=ln1 w=wn1 m=1
m15 net14 b vss vss n l=ln2 w=wn2 m=1
m16 y a vdd vdd p l=lp1 w=wp1 m=1
m17 y b vdd vdd p l=lp2 w=wp2 m=1
.ends

.subckt nor2 a b y
x0 a ai inv
x1 b bi inv
x2 ai bi no nand2
x3 no y inv
.ends

.subckt and2 a b y
x0 a b iy nand2
x1 iy y inv
.ends

.subckt or2 a b y
x0 a b iy nor2
x1 iy y inv
.ends

.subckt mux2 a b sel y
xo sel seli inv
x1 seli a aseli and2
x2 sel  b bsel  and2
x3 aseli bsel yi or2
R1 yi y 2.0M
C1 y gnd 3.5pF
.ends

.end
