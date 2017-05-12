#!/usr/bin/env bash

if [ -z $ES_VERSION ]; then
    echo "No ES_VERSION specified";
    exit 1;
fi;

ES_DIR="elasticsearch-$ES_VERSION"

killall java 2>/dev/null

if [ ! -d $ES_DIR ]; then
    echo "Downloading Elasticsearch v${ES_VERSION}"
    ES_URL="https://download.elasticsearch.org/elasticsearch/elasticsearch/${ES_DIR}.zip"
    curl -O $ES_URL
    unzip "${ES_DIR}.zip"
fi;

git clone https://github.com/elasticsearch/elasticsearch-perl.git

ES_HOME=./$ES_DIR prove -I elasticsearch-perl/lib -l -v t/*.t
RESULT=$?
cat log
killall java 2>/dev/null
exit $RESULT
