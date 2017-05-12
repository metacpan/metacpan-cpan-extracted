package Spork::Shlomify;

use warnings;
use strict;

use 5.008;

our $VERSION = '0.0203';
use Spoon 0.22 -Base;

const config_class => 'Spork::Shlomify::Config';

=head1 NAME

Spork::Shlomify - An improved Spork.

=head1 VERSION

Version 0.0203

=head1 SYNOPSIS

This module is an improved Spork derivative. What it does is:

1. Allow C<[Text http://www.myurl.tld/]> formatting.

2. Create a central C<slide.css> CSS stylesheet.

You can build presentations with it using the shspork executable.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 BUGS

Please report any bugs or feature requests to
C<bug-spork-shlomify@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Spork-Shlomify>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1; # End of Spork::Shlomify
