# run this on a fresh image to setup everything
sudo apt-get update
sudo apt-get install -y openssl

sudo apt-get install -y git

sudo apt-get install -y perl
sudo apt-get install -y perl-doc

sudo apt-get install -y liblocal-lib-perl
perl -Mlocal::lib >> ~/.bashrc
source ~/.bashrc

sudo apt-get install -y cpanminus

sudo apt-get install -y nano

sudo apt-get install -y gcc
sudo apt-get install -y xsltproc
sudo apt-get install -y libexpat1

sudo apt-get install -y redis-server
sudo apt-get install -y postgresql postgresql-contrib
sudo apt-get install -y sqlite3 libsqlite3-dev


cpanm --notest Task::MojoLearningEnvironment


shared_files/bin/mojo_static daemon
