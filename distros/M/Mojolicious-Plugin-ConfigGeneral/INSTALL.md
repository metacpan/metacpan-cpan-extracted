# INSTALLATION INSTRUCTIONS

    perl Makefile.PL
    make
    make test
    make install
    make clean

# INSTALLATION ON RHEL 8 (ROCKY LINUX 8.x)

1. Install the epel and abalama repository

    sudo dnf install epel-release
    sudo rpm -Uvh https://dist.suffit.org/repo/rhel8/abalama-release-1.00-1.el8.noarch.rpm
    sudo dnf clean all
    sudo dnf update

2. Install the project

    sudo dnf install perl-Mojolicious-Plugin-ConfigGeneral

# INSTALLATION ON UBUNTU 20.x

    sudo add-apt-repository ppa:abalama/v1.00
    sudo apt update
    sudo apt install libmojolicious-plugin-configgeneral-perl
