package Selenium::Driver::Auto;
$Selenium::Driver::Auto::VERSION = '1.02';
#ABSTRACT: Automatically choose the best driver available for your browser choice

use strict;
use warnings;

use Carp qw{confess};
use File::Which;

# Abstract: Automatically figure out which driver you want


sub build_spawn_opts {
    # Uses object call syntax
    my (undef,$object) = @_;

    if ($object->{browser} eq 'firefox') {
        require Selenium::Driver::Gecko;
        return Selenium::Driver::Gecko->build_spawn_opts($object);
    } elsif ($object->{browser} eq 'chrome') {
        require Selenium::Driver::Chrome;
        return Selenium::Driver::Chrome->build_spawn_opts($object);
    } elsif ($object->{browser} eq 'MicrosoftEdge') {
        require Selenium::Driver::Edge;
        return Selenium::Driver::Edge->build_spawn_opts($object);
    } elsif ($object->{browser} eq 'safari') {
        require Selenium::Driver::Safari;
        return Selenium::Driver::Safari->build_spawn_opts($object);
    }
    require Selenium::Driver::SeleniumHQ::Jar;
    return Selenium::Driver::SeleniumHQ::Jar->build_spawn_opts($object);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Selenium::Driver::Auto - Automatically choose the best driver available for your browser choice

=head1 VERSION

version 1.02

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
