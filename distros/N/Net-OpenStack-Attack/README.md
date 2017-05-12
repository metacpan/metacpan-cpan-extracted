# About

The purpose of this tool is to help with stress testing OpenStack.
It makes asynchronous http requests to slam an OpenStack deployment.
For example, the following makes 50 create server requests in parallel:

    stackattack create 50

# Installation

    sudo cpanm stackattack

or

    curl -L cpanmin.us | perl - --sudo stackattack

or

    sudo cpan Net::OpenStack::Attack
    
To install from a local git checkout, cd to the project directory and run:

    sudo cpanm .

If you do not have cpanm, you can install it via:

    curl -L cpanmin.us | perl - --sudo cpanm

# Usage

After installing, stackattack will be in your system path.
Run `stackattack` and the available commands will be listed.
Make sure to source a novarc file first to have env variables set up.

# Documentation

See [stackattack](https://metacpan.org/module/stackattack)
