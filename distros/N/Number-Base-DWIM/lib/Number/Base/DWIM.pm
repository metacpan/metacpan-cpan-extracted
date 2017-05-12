package Number::Base::DWIM;

use strict;
use warnings;

use 5.006002;

use overload;
use Scalar::Util qw(dualvar);

our $VERSION = 0.04;

=head1 NAME

Number::Base::DWIM - delay parsing of based constants as long as possible.

=head1 SYNOPSIS

    use Numbers::Base::DWIM

    my $x = 011;
    print $x, "\n";  # prints 9
    print "$x\n";    # prints 011

    print oct($x)    # prints 011

=head1 DESCRIPTION

This module will delay parsing of based numeric constants (0b010101,
0655, 0xff) until the last possible moment.  This means that if you
use the constant as a string, then it will evaluate to the same form
that the constant was declared in.

This module was developed after an discussion where some people found
the behavior of C<perl -e 'print oct 011, "\n";'> to be confusing.
This module works around this by overloading the parsing of binary,
hexidecimal and octal numeric constants.  It then stores them in a
C<dualvar>, as provided by L<Scalar::Util>.

=head1 NOTES

Originally this was implemented as a class, and the overload function
returned an object with numification and stringification methods.
Thanks to Brian D. Foy for suggesting that it use C<dualvar> instead.

=head1 BUGS

Due to a bug in L<overload>, constants inside of and C<eval '...'>
won't be handled specially.

=head1 AUTHOR

Clayton OE<apos>Neill <CMO@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006 by Clayton OE<apos>Neill

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub import {
  my $self = shift;
  overload::constant binary => sub { dualvar(oct $_[0], $_[0]) };
  
  return;
}

1;
