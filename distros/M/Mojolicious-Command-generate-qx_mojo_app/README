Qooxdoo&Mojolicious App Generator
=================================

[![Build Status](https://travis-ci.org/oetiker/qx-mojo-app.svg?branch=master)](https://travis-ci.org/oetiker/qx-mojo-app)
[![Coverage Status](https://img.shields.io/coveralls/oetiker/qx-mojo-app.svg)](https://coveralls.io/r/oetiker/qx-mojo-app?branch=master)

A Mojolicious generator template for creating JavaScript web applications.

With qx-mojo-app you can create web apps with a server part written in Perl
and a client part written in JavaScript using the Qooxdoo framework.

The app comes complete with an automake configure system, ready for distribution.

Quickstart
----------
The following was tested on a fresh xubuntu 12.04 and 14.04 x64

```

# --------------------
# install dependencies
# --------------------
sudo apt-get install curl
sudo apt-get install automake

# -----------
# get qooxdoo
# -----------
cd
mkdir sdk
cd sdk
wget http://downloads.sourceforge.net/qooxdoo/qooxdoo-4.0.1-sdk.zip
unzip qooxdoo-4.0.1-sdk.zip

# -----------------------------------
# install mojo, set env, generate app
# -----------------------------------
PREFIX=$HOME/opt/mojolicious
export PERL_CPANM_HOME=$PREFIX
export PERL_CPANM_OPT="--local-lib $PREFIX"
export PERL5LIB=$PREFIX/lib/perl5
export PATH=$PREFIX/bin:$PATH
curl -L cpanmin.us \
  | perl - -n https://github.com/oetiker/qx-mojo-app/archive/master.tar.gz

# --------
# make app
# --------
mkdir -p ~/src
cd ~/src
mojo generate qx_mojo_app Demo
cd demo

# ..continue reading README in demo/ (see below)
```

Et voilà, you are looking at your first Qooxdoo/Mojolicious app. Have a look
at the README in the demo directory for further instructions.


Enjoy

Tobi Oetiker <tobi@oetiker.ch>
