#! /bin/sh

for f in "$@";
do
	echo "---"
	echo "in: $f"
  o=`echo $f | sed -e 's/\.\(ml\)\?pod$//'`
	
	echo "mixed: $o.mix.html"
	mlpod2html --langs=ja,en $f > $o.mix.html
	
	echo "japanese: $o.ja.html"
	mlpod2html --langs=ja $f > $o.ja.html
	
	echo "english: $o.en.html"
	mlpod2html --langs=en $f > $o.en.html
done
