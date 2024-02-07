package Selenium::Driver::Safari;
$Selenium::Driver::Safari::VERSION = '2.00';
use strict;
use warnings;

use v5.28;

no warnings 'experimental';
use feature qw/signatures/;

use Carp qw{confess};
use File::Which;

#ABSTRACT: Tell Selenium::Client how to spawn safaridriver


sub build_spawn_opts ( $class, $object ) {
    $object->{driver_class} = $class;
    $object->{driver_version} //= '';
    $object->{log_file}       //= "$object->{client_dir}/perl-client/selenium-$object->{port}.log";
    $object->{driver_file} = File::Which::which('safaridriver');

    my @config = ( '--port', $object->{port} );

    # Build command string
    $object->{command} //= [
        $object->{driver_file},
        @config,
    ];
    return $object;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Selenium::Driver::Safari - Tell Selenium::Client how to spawn safaridriver

=head1 VERSION

version 2.00

=head1 Mode of Operation

Spawns a geckodriver server on the provided port (which the caller will assign randomly)
Relies on geckodriver being in your $PATH
Pipes log output to ~/.selenium/perl-client/$port.log

=head1 SUBROUTINES

=head2 build_spawn_opts($class,$object)

Builds a command string which can run the driver binary.
All driver classes must build this.

=head1 AUTHOR

George S. Baugh <george@troglodyne.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by George S. Baugh.

This is free software, licensed under:

  The MIT (X11) License

=cut
