#!/bin/bash

while [ 1 ] ; do
	sleep 5 
	perl -i -pe's/"either"/"or"/ || s/"or"/"either"/' samples/html/index.html
    echo "changed"
done
