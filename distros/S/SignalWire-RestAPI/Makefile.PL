use 5.010001;
use ExtUtils::MakeMaker;

## look for previously installed version
COMPAT: {
    eval 'require SignalWire::RestAPI';
    last COMPAT if $@;

    eval 'die "flatulence" if $SignalWire::RestAPI::VERSION < 0.15';
    last COMPAT unless $@;

    sleep 1;
    warn <<'_COMPAT_';
======================================================================

        *** WARNING *** ACHTUNG *** CUIDADO ***

It looks like you have previously installed a version of
SignalWire::RestAPI which is incompatible with this current release.

You have two options:

1) don't upgrade unless you need a new feature (note that 0.15
   contains no code changes other than the default API).

2) upgrade using one of the two methods found in the documentation
   under "COMPATIBILITY NOTICE".

Thanks for using SignalWire::RestAPI!

======================================================================
_COMPAT_
}

WriteMakefile(
    NAME              => 'SignalWire::RestAPI',
    VERSION_FROM      => 'lib/SignalWire/RestAPI.pm',
    PREREQ_PM         => { LWP::UserAgent => 2.030,
                           LWP::Protocol::https => 0,
                           URI::Escape    => 3.28,
                           List::Util     => 1.29, },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/SignalWire/RestAPI.pm', # retrieve abstract from module
       AUTHOR         => 'Scott Wiersdorf <scott@perlcode.org>') : ()),
);
