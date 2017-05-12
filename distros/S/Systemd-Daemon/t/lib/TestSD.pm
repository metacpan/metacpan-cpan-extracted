#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
#   file: t/lib/TestSD.pm
#
#   Copyright © 2015 Van de Bugger
#
#   This file is part of perl-Systemd-Daemon.
#
#   perl-Systemd-Daemon is free software: you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation, either version
#   3 of the License, or (at your option) any later version.
#
#   perl-Systemd-Daemon is distributed in the hope that it will be useful, but WITHOUT ANY
#   WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Systemd-Daemon. If not, see <http://www.gnu.org/licenses/>.
#
#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

package TestSD;

use strict;
use warnings;
use parent 'Test::Builder::Module';

use POSIX qw{};
use Devel::Symdump qw{};
use Symbol qw{};

our $CLASS = __PACKAGE__;
our @EXPORT = qw{
    %Symbols @Symbols $Symbols
    test_use
    test_func_is_imported
    test_func_is_not_imported
    test_import_none
    test_import_some
    test_import_all
    test_call_func_no_args
    test_call_func
    test_symbol
};

my $stub = - POSIX::ENOSYS;     # Stub functions return this error.

our %Symbols = (
    # Key   — Synbol name (as used in import list, i. e. scalar names are prefixed with `$`).
    # args  — array of arguments to pass to a function.
    # XS    — expected result from XS implementation.
    # Stub  — Expected result from Stub implementation.
    # value — Expected scalar value.
    sd_listen_fds          => { args => [ 0 ],         XS => 0,              Stub => $stub },
    sd_notify              => { args => [ ( 0 ) x 2 ], XS => 0,              Stub => $stub },
    sd_pid_notify          => { args => [ ( 0 ) x 3 ], XS => 0,              Stub => $stub },
    #~ sd_pid_notify_with_fds =>args =>  5,
    sd_booted              => { args => [],            XS => 1,              Stub => $stub },
    sd_is_fifo             => { args => [ ( 0 ) x 2 ], XS => 0,              Stub => $stub },
    sd_is_socket           => { args => [ ( 0 ) x 4 ], XS => 0,              Stub => $stub },
    #~ sd_is_socket_inet      =>args =>  5,
    sd_is_socket_unix      => { args => [ ( 0 ) x 6 ], XS => 0,              Stub => $stub },
    sd_is_mq               => { args => [ ( 0 ) x 2 ], XS => - POSIX::EBADF, Stub => $stub },
    sd_is_special          => { args => [ ( 0 ) x 2 ], XS => 0,              Stub => $stub },
    #~ sd_watchdog_enabled    =>args =>  2,
    '$SD_LISTEN_FDS_START' => { value => 3     },
    '$SD_EMERG'            => { value => "<0>" },
    '$SD_ALERT'            => { value => "<1>" },
    '$SD_CRIT'             => { value => "<2>" },
    '$SD_ERR'              => { value => "<3>" },
    '$SD_WARNING'          => { value => "<4>" },
    '$SD_NOTICE'           => { value => "<5>" },
    '$SD_INFO'             => { value => "<6>" },
    '$SD_DEBUG'            => { value => "<7>" },
);
our @Symbols = keys( %Symbols );    # Array of symbol names.
our $Symbols = @Symbols;            # Number of symbols.

#   Returns qualified symbol name.
sub symbol($$) {
    my ( $pkg, $name ) = @_;
    $name =~ s{^\$}{};
    return Symbol::qualify( $name, $pkg );
};

#   Returns a glob reference.
sub reference($$) {
    my ( $pkg, $name ) = @_;
    $name =~ s{^\$}{};
    return Symbol::qualify_to_ref( $name, $pkg );
};

sub is_symbol_exists($$) {
    my ( $pkg, $name ) = @_;
    my $symbol = symbol( $pkg, $name );
    my $method = substr( $name, 0, 1 ) eq '$' ? 'scalars' : 'functions';
    return !! grep( { $_ eq $symbol } Devel::Symdump->$method( $pkg ) );
};

sub test_use($$@) {
    my ( $package, $module, @import ) = @_;
    my $tb = $CLASS->builder();
    my $use = "use $module qw{ " . join( ' ', @import ) . " }";
    local $@;
    eval "package $package; $use;";
    return $tb->is_eq( $@, '', $use );
};

sub test_sym_is_imported($$) {
    my ( $pkg, $name ) = @_;
    my $tb = $CLASS->builder();
    return $tb->ok( is_symbol_exists( $pkg, $name ), "symbol $name is in package $pkg" );
};

sub test_sym_is_not_imported($$) {
    my ( $pkg, $name ) = @_;
    my $tb = $CLASS->builder();
    return $tb->ok( ! is_symbol_exists( $pkg, $name ), "symbol $name is not in package $pkg" );
};

sub test_symbol($$) {
    my ( $pkg, $name ) = @_;
    my $tb = $CLASS->builder();
    return $tb->subtest( "test symbol $name", sub {
        if ( substr( $name, 0, 1 ) eq '$' ) {
            #   Check scalar value.
            $tb->is_eq( $${ reference( $pkg, $name ) }, $Symbols{ $name }->{ value } );
        } else {
            #   Call the function.
            my $descr = $Symbols{ $name };
            my $call = sprintf(
                '%s( %s )',
                symbol( $pkg, $name ),
                join( ', ', @{ $descr->{ args } } )
            );
            my $expected = $descr->{ do { ( $_ = $pkg ) =~ s{^.*::}{}; $_; } };
            local $@;
            my $rc;
            eval "\$rc = $call;";
            $tb->is_eq( $@, '', 'no exceptions' )
                and $tb->is_eq( $rc, $expected, 'result' );
        };
        $tb->done_testing;
    } );
};

sub test_import_none($$) {
    my ( $pkg, $module ) = @_;
    my $tb = $CLASS->builder();
    return $tb->subtest( 'import none', sub {
        my $use = test_use( $pkg, $module );
        foreach my $sym ( @Symbols ) {
            if ( $use ) {
                test_sym_is_not_imported( $pkg, $sym );
            } else {
                $tb->skip( 'use failed' );
            };
        };
        $tb->done_testing;
    } );
};

sub test_import_some($$@) {
    my ( $pkg, $module, @import ) = @_;
    my $tb = $CLASS->builder();
    return $tb->subtest( 'import some', sub {
        my $use = test_use( $pkg, $module, @import );
        foreach my $sym ( @Symbols ) {
            if ( $use ) {
                if ( grep( { $_ eq $sym } @import ) ) {
                    test_sym_is_imported( $pkg, $sym );
                } else {
                    test_sym_is_not_imported( $pkg, $sym );
                };
            } else {
                $tb->skip( 'use failed' );
            };
        };
        $tb->done_testing;
    } );
};

sub test_import_all($$) {
    my ( $pkg, $module ) = @_;
    my $tb = $CLASS->builder();
    return $tb->subtest( 'import all', sub {
        my $use = test_use( $pkg, $module, ':all' );
        foreach my $sym ( @Symbols ) {
            if ( $use ) {
                test_sym_is_imported( $pkg, $sym );
            } else {
                $tb->skip( 'use failed' );
            };
        };
        $tb->done_testing;
    } );
};

1;

# end of file #
