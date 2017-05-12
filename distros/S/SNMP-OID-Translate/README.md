[![Build Status](https://travis-ci.org/rfdrake/p5-SNMP-OID-Translate.svg?branch=master)](https://travis-ci.org/rfdrake/p5-SNMP-OID-Translate)
[![Coverage Status](https://coveralls.io/repos/rfdrake/p5-SNMP-OID-Translate/badge.svg?branch=master&service=github)](https://coveralls.io/github/rfdrake/p5-SNMP-OID-Translate?branch=master)

# SNMP::OID::Translate - nothing but translateObj

This is a stripped copy of the perl SNMP.pm XS module.  It comes from version
5.0404.  The reason for this is because I'm using Net::SNMP for everything
except translateObj, but SNMP.pm is nearly impossible to build in a way that
travis+perlbrew are happy with.

# Synopsis

    use SNMP::OID::Translate;
    my $output = SNMP::OID::Translate::translateObj($input);

# Special hacks needed for this module

## Removed net-snmp-config usage

This will probably break some OS but it cleans the Makefile and makes it work
better under perlbrew.  I only anticipate this causing an issue on (possibly)
windows.

## Added MIBS environment variable

We also need to say MIBS=+IF-MIB in environment to get it to load a MIB for
testing.

# Code changes behind the scenes

## Got rid of $\` and $&

Because these can be slow on older perl it's better to avoid them.
Especially since it slows down any regex after they are used.

# Things I tried before doing this

This is an incomplete list of things I've tried.  I'm including them in case
they help others in similar quests.

## Copying system modules over to perlbrew

    find /usr -name "SNMP.pm" -exec cp {} $HOME/perl5/lib/perl5 \; -quit


The problem with this approach is if there are other SNMP modules installed,
like AnyEvent::SNMP, it can't detect which one is the right SNMP.pm.

So how about:

    find /usr -name '*[0-9]/SNMP.pm' -exec cp {} $HOME/perl5/lib/perl5 \; -quit

That assumes the directory is going to be called /5.20/ or whatever the perl
version is.  It might break with dev/blead releases and other things.

## So let's make perl find the module

We could use Module::Find, except our "before_install" commands run long after
we're switched into perlbrew, so our @INC space wouldn't include the normal
system @INC.

but the system perl is in an easy to find place.. so let's try this:

    - "cp $(/usr/bin/perl $(which mpath) SNMP) $HOME/perl5/lib/perl5"

## Testing this locally seems to work, so now we just need to see if we've made travis happy.

    * E: Unable to locate package libmodule-path-perl

ok, we can fix that by running "cpanm Module::Path"

## next run

    * Can't locate Module/Path.pm in @INC (@INC contains: /etc/perl

So we're not looking in the local directories when using the system perl.
Let's see if we can get cpanm to install into a system directory using "sudo
cpanm Module::Path"

## next run

    * sudo: cpanm: command not found

(╯°□°)╯︵ ┻━┻


Lets hardcode more paths.  I went ahead and overrode perl to make sure cpanm
would see the system's @INC instead of the local one.

    sudo /usr/bin/perl $HOME/perl5/perlbrew/bin/cpanm Module::Path

## next run

    * cp: cannot create regular file `/home/travis/perl5/lib/perl5': No such file or directory

So hardcoding the destination path wasn't a good idea either

    cp $(/usr/bin/perl $(which mpath) SNMP) $(perl -E 'say @INC[0]')

## next run

    * Error:  Can't locate GD/Image.pm in @INC

Wow.. finally, tests are running.  But we still failed because it couldn't
find some submodules we didn't copy.

SNMP is a single file so it might run on it's own.

## after adding some tests for SNMP.pm we get more module failures

Turns out SNMP isn't a single file.  They have a second module in a different
namespace for unexplainable reasons (probably historic).

    - "cp -r $(dirname $(/usr/bin/perl $(which mpath) NetSNMP/default_store.pm)) $(perl -E 'say @INC[0]')"

## and again...

    Can't locate auto/NetSNMP/default_store/autosplit.ix

At this point I think we should get off the tangent of trying to fix perlbrew
with file copying and attempt to do things the right way again, by building
the module.

## trying to build the module with env var

Once i had a chance to download the SNMP.pm module source and build-deps, I
saw there is a flag to ignore the version difference and run anyway.  This
would probably work for us since we only want translateObj.

    env:
      - NETSNMP_DONT_CHECK_VERSION=1

So I did this.  SNMP still bombed.  Attempting to troubleshoot here I found
that even with "apt-get build-deps SNMP" you don't get enough of net-snmp to
build the module.

## turns out we need libsnmp-dev

This gives us net-snmp-config and some other files which are important to
building.

## Now we're failing SNMP.pm tests because snmpd isn't found

    cpanm --notest SNMP

## the module installs and is unusable

    t/10-snmp.t ............. Can't locate NetSNMP/default_store.pm in @INC (you may need to install the NetSNMP::default_store module)

Somehow installing libsnmp-perl fixes this (at least on my machine, I don't
think I tried it with travis)

But then we get to another error:

    Can't load '/home/rdrake/perl5/lib/perl5/x86_64-linux-gnu-thread-multi/auto/SNMP/SNMP.so' for module SNMP: /home/rdrake/perl5/lib/perl5/ x86_64-linux-gnu-thread-multi/auto/SNMP/SNMP.so: undefined symbol: memdup at /usr/lib/x86_64-linux-gnu/perl/5.22/DynaLoader.pm line 187.


I think this (and maybe the previous problem) are caused by the mismatched
versions.  More specifically, I think the version shipped with debian might be newer than
what is on CPAN.

## asking cpanm to install the same version as debian doesn't work

    cpanm --notest SNMP@$(perl -MSNMP -e 'print $SNMP::VERSION')
    Found SNMP 5.0404 which doesn't satisfy == 5.0703.

## my final travis.yml

    language: perl
    sudo: true

    env:
      - NETSNMP_DONT_CHECK_VERSION=1
    before_install:
        - "sudo apt-get -yq update"
        - "sudo apt-get -yq install libsnmp-perl libsnmp-dev"
        - "cpanm --notest SNMP"
        - eval $(curl https://travis-perl.github.io/init) --auto

    perl:
        - "5.20"
        - "5.18"
        - "5.16"
        - "5.14"

    matrix:
      include:
        - perl: 5.18
          env: COVERAGE=1   # enables coverage+coveralls reporting
      allow_failures:
        - perl: blead       # ignore failures for blead perl
        - perl: dev         # ignore failures for dev perl


Note that this still doesn't work, but it might be a starting point for
someone who doesn't want to commit 40 times attempting to make this happen.

# TODO

## Changing strcpy and sprintf to strncopy/snprintf

Even though I'm reasonably sure the code is safe after looking at how they're
used, I would rather not leave them because of the possibility of a refactor
that overruns a buffer without checking.

# Final notes

1. The SNMP.pm module should either be removed from CPAN or every available
version should be uploaded so that we can pull a compatible version.  The fact
that Net-SNMP ships with the correctly syncronized version means it's of
dubious benefit to keep it on CPAN.

2. NetSNMP::default_store doesn't make use of autosplit.  I believe "use
AutoLoader" should be removed from the module.

