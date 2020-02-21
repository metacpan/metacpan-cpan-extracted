MojoliciousAutomake
===================

![Unit Tests](https://github.com/oposs/mojolicious-automake/workflows/Unit%20Tests/badge.svg)

MojoliciousAutomake is a mojolicious app skeleton generator which sets up
mojolicious projects with automake support.

Currently the following templates are supported

* automake_app - a simple mojolicious app with full automake support
* callbackery_app - a sample [callbackery app](https://github.com/oetiker/callbackery)

Quickstart
----------

Open a terminal and follow the instructions below. We have tested them on
Ubuntu but they should work on any recent linux system with at least
perl 5.24 installed.

First make sure you have gcc, perl curl and automake installed. The following commands
will work on Debian and Ubuntu. 

```console
sudo apt-get install curl automake perl gcc unzip libssl-dev
```

For Redhat try

```console
sudo yum install curl automake perl-core openssl-devel gcc unzip
```

Now setup MojoAutomake and all its requirements. You can set the `PREFIX` to
wherever you want MojoAutomake to be installed.

```console
PREFIX=$HOME/opt/mojolicious-automake
export PERL_CPANM_HOME=$PREFIX
export PERL_CPANM_OPT="--local-lib $PREFIX"
export PERL5LIB=$PREFIX/lib/perl5
export PATH=$PREFIX/bin:$PATH
curl -L cpanmin.us \
  | perl - -n --no-lwp https://github.com/oposs/mojolicious-automake/archive/master.tar.gz
```

Finally, lets generate a sample application.

```console
mkdir -p ~/src
cd ~/src
mojo generate automake_app AmApp
cd am-app
```

Et voilà, you are looking at your first Mojolicious app with full automake support. To get the
sample application up and running, follow the instructions in the 
README.md you find in the `am-app` directory.


Enjoy

Tobi Oetiker <tobi@oetiker.ch>
