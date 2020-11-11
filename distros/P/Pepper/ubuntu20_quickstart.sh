#!/bin/sh
# Shell script to quickly install, set up, and start Pepper
# should be able to run: curl https://raw.githubusercontent.com/ericschernoff/Pepper/ginger/ubuntu20_quickstart.sh | sh

echo "Installing the needed system packages"

sudo apt -y install build-essential cpanminus libmysqlclient-dev perl-doc zlib1g-dev

echo "Installing Pepper"

sudo cpanm Pepper

echo "Setting up Pepper - Please answer carefully"

pepper setup

echo "Starting Pepper"
pepper start

echo "Pepper now running at http://127.0.0.1:5000"
