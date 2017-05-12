package Shipwright::Base;

use warnings;
use strict;

our @ISA;
require Class::Accessor::Fast;

BEGIN {
    eval { require Class::XSAccessor::Compat };
    push @ISA, $@ ? 'Class::Accessor::Fast' : 'Class::XSAccessor::Compat' ;
}

=head1 NAME

Shipwright::Base - Base

1;

__END__

=head1 AUTHORS

sunnavy  C<< <sunnavy@bestpractical.com> >>

=head1 LICENCE AND COPYRIGHT

Shipwright is Copyright 2007-2015 Best Practical Solutions, LLC.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

