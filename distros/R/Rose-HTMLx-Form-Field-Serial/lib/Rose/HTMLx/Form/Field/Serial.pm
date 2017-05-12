package Rose::HTMLx::Form::Field::Serial;

use warnings;
use strict;
use base qw( Rose::HTML::Form::Field::Hidden );

our $VERSION = '0.002';

=head1 NAME

Rose::HTMLx::Form::Field::Serial - represent auto-increment columns in a form

=head1 SYNOPSIS

 # see Rose::HTML::Form::Field::Hidden

=head1 DESCRIPTION

Rose::HTMLx::Form::Field::Serial is a subclass of Rose::HTML::Form::Field::Hidden.
It exists simply to isolate a particular kind of form field that should
not be updated via form but may need to be passed as a param or viewed
in a (x)html serialized format. The namespace is reserved in the event that future
functionality may be added, but mostly to uniquely identify this field type
for use with Rose::DBx::Garden.
 
=head1 METHODS

Currently no methods are overridden.

=cut

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-rose-htmlx-form-field-serial@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

