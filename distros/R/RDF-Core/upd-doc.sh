#!/bin/sh

if test ! -d doc/RDF; then mkdir doc/RDF; fi
if test ! -d doc/RDF/Core; then mkdir doc/RDF/Core; fi
if test ! -d doc/RDF/Core/Enumerator; then mkdir doc/RDF/Core/Enumerator; fi
if test ! -d doc/RDF/Core/Storage; then mkdir doc/RDF/Core/Storage; fi
if test ! -d doc/RDF/Core/Model; then mkdir doc/RDF/Core/Model; fi

cd lib/RDF
FILES=`ls`
for file in $FILES; do
    if test -f $file; then 
    echo $file; 
    pod2html $file > "../../doc/RDF/$file.html";
    fi
done
rm -f pod2htm*

cd Core
FILES=`ls`
for file in $FILES; do
    if test -f $file; then 
    echo $file; 
    pod2html $file > "../../../doc/RDF/Core/$file.html";
    fi
done
rm -f pod2htm*

cd Enumerator
FILES=`ls`
for file in $FILES; do
    if test -f $file; then 
    echo $file; 
    pod2html $file > "../../../../doc/RDF/Core/Enumerator/$file.html";
    fi
done
rm -f pod2htm*

cd ../Storage
FILES=`ls`
for file in $FILES; do
    if test -f $file; then 
    echo $file; 
    pod2html $file > "../../../../doc/RDF/Core/Storage/$file.html";
    fi
done
rm -f pod2htm*

cd ../Model
FILES=`ls`
for file in $FILES; do
    if test -f $file; then 
    echo $file; 
    pod2html $file > "../../../../doc/RDF/Core/Model/$file.html";
    fi
done
rm -f pod2htm*
