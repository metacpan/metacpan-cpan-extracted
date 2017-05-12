package Nagios::Plugin::OverHTTP::Parser;

use 5.008001;
use strict;
use warnings 'all';

###########################################################################
# METADATA
our $AUTHORITY = 'cpan:DOUGDUDE';
our $VERSION   = '0.16';

###########################################################################
# MOOSE ROLE
use Moose::Role 0.74;

###########################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(meta)];

###########################################################################
# REQUIRED METHODS
requires qw(
	parse
);

1;

__END__

=head1 NAME

Nagios::Plugin::OverHTTP::Parser - Moose role for output parsers

=head1 VERSION

This documentation refers to L<Nagios::Plugin::OverHTTP::Parser> version 0.16

=head1 SYNOPSIS

  package My::Custom::Parser;

  use Moose;

  with 'Nagios::Plugin::OverHTTP::Parser'; # use the role (required)

  # Implement the parser and define
  # any required methods

  no Moose; # unimport Moose

  1;

=head1 DESCRIPTION

This module is a Moose role that defines the required API for parsers.

=head1 REQUIRED METHODS

=head2 parse

This must return a new instance of L<Nagios::Plugin::OverHTTP::Response>.
The only argument accepted is a L<HTTP::Response> object.

  my $parsed = $parser->parse($http_response);

=head1 METHODS

This module has no methods.

=head1 DEPENDENCIES

This module is dependent on the following modules:

=over 4

=item * L<Moose::Role> 0.74

=item * L<namespace::clean> 0.04

=back

=head1 AUTHOR

Douglas Christopher Wilson, C<< <doug at somethingdoug.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-nagios-plugin-overhttp at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Nagios-Plugin-OverHTTP>. I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Douglas Christopher Wilson, all rights reserved.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back
