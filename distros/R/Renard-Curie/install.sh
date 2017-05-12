#! /bin/sh
sudo apt-get update
sudo apt-get upgrade

sudo xargs apt-get install \
  -y --no-install-recommends \
  < debian-packages

sudo apt-get install perlbrew
sudo perlbrew install-cpanm
sudo cpan App::cpanminus
sudo apt-get install cpanminus

sudo cpanm --installdeps .

sudo apt-get install mupdf mupdf-tools
