devel:
	cpanm -n -l local --installdeps .

test: devel
	PERL5LIB=local/lib/perl5 prove -I lib -v lib t/

dist:
	cpanm -n -l dzil-local Dist::Zilla
	PERL5LIB=dzil-local/lib/perl5 dzil-local/bin/dzil authordeps --missing | cpanm -n -l dzil-local
	#PERL5LIB=dzil-local/lib/perl5 dzil-local/bin/dzil smoke
	PERL5LIB=dzil-local/lib/perl5 dzil-local/bin/dzil build

