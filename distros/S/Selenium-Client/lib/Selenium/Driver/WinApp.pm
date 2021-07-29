package Selenium::Driver::WinApp;
$Selenium::Driver::WinApp::VERSION = '1.05';
use strict;
use warnings;

no warnings 'experimental';
use feature qw/signatures/;

use Carp qw{confess};
use File::Which;

#ABSTRACT: Tell Selenium::Client how to spawn the Windows Application Driver


sub _driver {
    return 'WinAppDriver.exe';
}

sub build_spawn_opts($class,$object) {
    $object->{driver_class}       = $class;
    $object->{driver_version}     //= '';
    $object->{log_file}           //= "$object->{client_dir}/perl-client/selenium-$object->{port}.log";
    $object->{driver_file} = File::Which::which($class->_driver());
    die "Could not find driver!" unless $object->{driver_file};
    #XXX appears that escaping from system() does not work correctly on win32 thanks to the join() I have? to do later, sigh
    $object->{driver_file} = qq/"$object->{driver_file}"/;

    my @config = ($object->{port});

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

Selenium::Driver::WinApp - Tell Selenium::Client how to spawn the Windows Application Driver

=head1 VERSION

version 1.05

=head1 Mode of Operation

Spawns a WinAppDriver server on the provided port (which the caller will assign randomly)
Relies on WinAppDriver being in your $PATH (put in this to your user's PATH env var:)

    %PROGRAMFILES(X86)%\Windows Application Driver

Pipes log output to ~/.selenium/perl-client/$port.log

=head1 SUBROUTINES

=head2 build_spawn_opts($class,$object)

Builds a command string which can run the driver binary.
All driver classes must build this.

=head1 AUTHOR

George S. Baugh <george@troglodyne.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by George S. Baugh.

This is free software, licensed under:

  The MIT (X11) License

=cut
