<%= ${class} %>
===========
Version: #VERSION#
Date: #DATE#

<%= ${class} %> is a cool web application.

It comes complete with a classic "configure - make - install" setup.

Setup
-----
In your app source directory and start building.

```console
./configure --prefix=$HOME/opt/<%= ${filename} %>
make
```

Configure will check if all requirements are met and give
hints on how to fix the situation if something is missing.

Any missing perl modules will be downloaded and built.

Development
-----------

While developing the application it is convenient to NOT have to install it
before runnning. You can actually serve the Qooxdoo source directly
using the built-in Mojo webserver.

```console
./bin/<%= ${filename} %>-source-mode.sh
```

You can now connect to the CallBackery app with your web browser.

If you need any additional perl modules, write their names into the PERL_MODULES
file and run ./bootstrap.

Installation
------------

To install the application, just run

```console
make install
```

You can now run <%= ${filename} %>.pl in reverse proxy mode.

```console
cd $HOME/opt/<%= ${filename} %>/bin
./<%= ${filename} %>.pl prefork

Packaging
---------

Before releasing, make sure to update CHANGES, VERSION and run ./bootstrap

You can also package the application as a nice tar.gz file, it will contain
a mini copy of CPAN, so that all perl modules can be rebuilt at the
destination.  If you want to make sure that your project builds with perl
5.22, make sure to set the PERL environment variable to a perl 5.22
interpreter, make sure to delete any PERL5LIB environment variable, and run
`make clean && make`. Now all modules to build your
project with any perl from 5.22 on upward will be included in the distribution.

```console
make dist
```

Enjoy!

<%= "${fullName} <${email}>" %>
