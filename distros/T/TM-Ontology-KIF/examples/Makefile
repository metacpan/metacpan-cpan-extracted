.SUFFIXES: .atm .kif

all: sumo.atm

sumo.kif:
	GET 'http://cvs.sourceforge.net/viewcvs.py/*checkout*/sigmakee/KBs/Merge.txt?rev=1.1.1.1' > sumo.kif

.kif.atm:
	echo "This may take a looong time..."
	cat $< | perl -I../lib ../bin/kif2atm --warn --stats > $@

clean:
	rm -rf *.atm *.kif

publish: sumo.atm
	scp sumo.atm dido:/var/apps/astma/htdocs/examples/
	scp sumo.atm namod:projects/topicmaps/maps/internet/semantic-web/ontology/sumo.atm
	echo "copy this onto the topic maps site"
	echo "conversion to XTM does not work yet"
