package ComposedMopClass;

use strict;
use warnings;
use 5.012;
use Carp;

use mop;

# the :: is there to install methods into ComposedMopClass, without it
# they go into ComposedMopClass::ComposedMopClass...
class ::ComposedMopClass
    extends PureMopClass
    with PureMopRole {
    has $!composed_private_stuff;
    has $!composed_public_stuff is ro;
    method composed_i_am_covered { ... }
    method composed_i_am_not_covered { ... }
    method _composed_i_look_private { ... }
}

__END__
=pod

=head1 NAME

ComposedMopClass -- test class

=head1 SYNOPSIS

  use ComposedMopClass;
  # TODO write synopsis

=head1 DESCRIPTION

TODO write this

=head1 ATTRIBUTES

=head2 composed_public_stuff

TODO write this

=head1 METHODS

=head2 composed_i_am_covered

  # TODO write synopsis

TODO write this

=head1 SEE ALSO

TODO links to other pods and documentation

=head1 AUTHOR

Fabrice Gabolde <fabrice.gabolde@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Fabrice Gabolde

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
