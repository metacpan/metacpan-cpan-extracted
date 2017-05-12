#!/bin/bash



perl -I ../lib ../bin/autopod -d in --poddir out/pod --verbose


perl ./makehtml.pl





