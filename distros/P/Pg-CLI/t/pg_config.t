use strict;
use warnings;

use lib 't/lib';

use Pg::CLI::pg_config;
use Test::More 0.88;

{
    my $pg_config = Pg::CLI::pg_config->new( executable => 'foo' );

    my %config = (
        bindir            => q{/usr/lib/postgresql/8.4/bin},
        docdir            => q{/usr/share/doc/postgresql},
        htmldir           => q{/usr/share/doc/postgresql},
        includedir        => q{/usr/include/postgresql},
        pkgincludedir     => q{/usr/include/postgresql},
        includedir_server => q{/usr/include/postgresql/8.4/server},
        libdir            => q{/usr/lib},
        pkglibdir         => q{/usr/lib/postgresql/8.4/lib},
        localedir         => q{/usr/share/locale},
        mandir            => q{/usr/share/postgresql/8.4/man},
        sharedir          => q{/usr/share/postgresql/8.4},
        sysconfdir        => q{/etc/postgresql-common},
        pgxs => q{/usr/lib/postgresql/8.4/lib/pgxs/src/makefiles/pgxs.mk},
        configure =>
            q{'--build=x86_64-linux-gnu' '--prefix=/usr' '--includedir=/usr/include' '--mandir=/usr/share/man' '--infodir=/usr/share/info' '--sysconfdir=/etc' '--localstatedir=/var' '--libexecdir=/usr/lib/postgresql-8.4' '--disable-maintainer-mode' '--disable-dependency-tracking' '--disable-silent-rules' '--srcdir=.' '--mandir=/usr/share/postgresql/8.4/man' '--with-docdir=/usr/share/doc/postgresql-doc-8.4' '--sysconfdir=/etc/postgresql-common' '--datadir=/usr/share/postgresql/8.4' '--bindir=/usr/lib/postgresql/8.4/bin' '--includedir=/usr/include/postgresql/' '--enable-nls' '--enable-integer-datetimes' '--enable-thread-safety' '--enable-debug' '--disable-rpath' '--with-tcl' '--with-perl' '--with-python' '--with-pam' '--with-krb5' '--with-gssapi' '--with-openssl' '--with-libxml' '--with-libxslt' '--with-ldap' '--with-ossp-uuid' '--with-gnu-ld' '--with-tclconfig=/usr/lib/tcl8.5' '--with-tkconfig=/usr/lib/tk8.5' '--with-includes=/usr/include/tcl8.5' '--with-system-tzdata=/usr/share/zoneinfo' '--with-pgport=5432' 'CFLAGS=-g -O2 -g -Wall -O2 -fPIC' 'LDFLAGS=-Wl,-Bsymbolic-functions -Wl,--as-needed' 'build_alias=x86_64-linux-gnu' 'CPPFLAGS='},
        cc => q{gcc},
        cppflags =>
            q{-D_GNU_SOURCE -I/usr/include/libxml2 -I/usr/include/tcl8.5},
        cflags =>
            q{-g -O2 -g -Wall -O2 -fPIC -Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement -Wendif-labels -fno-strict-aliasing -fwrapv -g},
        cflags_sl => q{-fpic},
        ldflags =>
            q{-Wl,-Bsymbolic-functions -Wl,--as-needed -Wl,--as-needed},
        ldflags_sl => undef,
        libs =>
            q{-lpgport -lxslt -lxml2 -lpam -lssl -lcrypto -lkrb5 -lcom_err -lgssapi_krb5 -lz -lreadline -lcrypt -ldl -lm },
        version => q{PostgreSQL 8.4.5},
    );

    my @output = map {
        my $key = uc $_;
        $key = 'INCLUDEDIR-SERVER' if $key eq 'INCLUDEDIR_SERVER';
        $key . ' = ' . ( defined $config{$_} ? $config{$_} : q{ } ) . "\n"
    } sort keys %config;

    no warnings 'redefine';
    local *Pg::CLI::pg_config::_pg_config_output = sub {@output};

    for my $key ( keys %config ) {
        is(
            $pg_config->$key(), $config{$key},
            "got expected value for $key"
        );
    }
}

done_testing();

