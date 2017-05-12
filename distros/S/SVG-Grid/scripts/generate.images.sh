#!/bin/bash

scripts/cell.sh

perl -Ilib scripts/synopsis.pl

cp data/*.svg $DR/assets/images/articles
cp data/*.svg ~/savage.net.au/assets/images/articles
