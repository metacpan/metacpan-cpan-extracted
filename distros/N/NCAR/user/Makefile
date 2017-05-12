all: libuser.a

agchax.o: agchax.F
	g77 -c -DAGCHAX=NCARAGCHAX agchax.F
agchcu.o: agchcu.F
	g77 -c -DAGCHCU=NCARAGCHCU agchcu.F
agchil.o: agchil.F
	g77 -c -DAGCHIL=NCARAGCHIL agchil.F
agchnl.o: agchnl.F
	g77 -c -DAGCHNL=NCARAGCHNL agchnl.F
agpwrt.o: agpwrt.F
	g77 -c -DAGPWRT=NCARAGPWRT agpwrt.F
agutol.o: agutol.F
	g77 -c -DAGUTOL=NCARAGUTOL agutol.F
cpchcf.o: cpchcf.F
	g77 -c -DCPCHCF=NCARCPCHCF cpchcf.F
cpchcl.o: cpchcl.F
	g77 -c -DCPCHCL=NCARCPCHCL cpchcl.F
cpchhl.o: cpchhl.F
	g77 -c -DCPCHHL=NCARCPCHHL cpchhl.F
cpchil.o: cpchil.F
	g77 -c -DCPCHIL=NCARCPCHIL cpchil.F
cpchll.o: cpchll.F
	g77 -c -DCPCHLL=NCARCPCHLL cpchll.F
cpmpxy.o: cpmpxy.F
	g77 -c -DCPMPXY=NCARCPMPXY cpmpxy.F
fdum.o: fdum.F
	g77 -c -DFDUM=NCARFDUM fdum.F
lbfill.o: lbfill.F
	g77 -c -DLBFILL=NCARLBFILL lbfill.F
mapeod.o: mapeod.F
	g77 -c -DMAPEOD=NCARMAPEOD mapeod.F
mapusr.o: mapusr.F
	g77 -c -DMAPUSR=NCARMAPUSR mapusr.F
mpchln.o: mpchln.F
	g77 -c -DMPCHLN=NCARMPCHLN mpchln.F
pcmpxy.o: pcmpxy.F
	g77 -c -DPCMPXY=NCARPCMPXY pcmpxy.F
slubkg.o: slubkg.F
	g77 -c -DSLUBKG=NCARSLUBKG slubkg.F
vvumxy.o: vvumxy.F
	g77 -c -DVVUMXY=NCARVVUMXY vvumxy.F
libuser.a: agchax.o agchcu.o agchil.o agchnl.o agpwrt.o agutol.o cpchcf.o cpchcl.o cpchhl.o cpchil.o cpchll.o cpmpxy.o fdum.o lbfill.o mapeod.o mapusr.o mpchln.o pcmpxy.o slubkg.o vvumxy.o
	ar rv libuser.a agchax.o agchcu.o agchil.o agchnl.o agpwrt.o agutol.o cpchcf.o cpchcl.o cpchhl.o cpchil.o cpchll.o cpmpxy.o fdum.o lbfill.o mapeod.o mapusr.o mpchln.o pcmpxy.o slubkg.o vvumxy.o
clean:
	\rm -f agchax.o agchcu.o agchil.o agchnl.o agpwrt.o agutol.o cpchcf.o cpchcl.o cpchhl.o cpchil.o cpchll.o cpmpxy.o fdum.o lbfill.o mapeod.o mapusr.o mpchln.o pcmpxy.o slubkg.o vvumxy.o libuser.a
	\mv Makefile Makefile.old

test:

