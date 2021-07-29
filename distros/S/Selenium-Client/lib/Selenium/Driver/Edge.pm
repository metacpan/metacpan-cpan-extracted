package Selenium::Driver::Edge;
$Selenium::Driver::Edge::VERSION = '1.05';
use strict;
use warnings;

use v5.28;

no warnings 'experimental';
use feature qw/signatures/;

use parent qw{Selenium::Driver::Chrome};

#ABSTRACT: Tell Selenium::Client how to spawn edgedriver


sub _driver {
    return 'msedgedriver.exe';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Selenium::Driver::Edge - Tell Selenium::Client how to spawn edgedriver

=head1 VERSION

version 1.05

=head1 Mode of Operation

Like edge, this is a actually chrome.  So refer to Selenium::Driver::Chrome documentation.

=head1 AUTHOR

George S. Baugh <george@troglodyne.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by George S. Baugh.

This is free software, licensed under:

  The MIT (X11) License

=cut
