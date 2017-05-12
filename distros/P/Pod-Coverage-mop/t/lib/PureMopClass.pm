package PureMopClass;

use strict;
use warnings;
use 5.012;
use Carp;

use mop;

# the :: is there to install methods into PureMopClass, without it
# they go into PureMopClass::PureMopClass...
class ::PureMopClass {
    has $!class_private_stuff;
    has $!class_public_stuff is ro;
    method class_i_am_covered { ... }
    method class_i_am_not_covered { ... }
    method _class_i_look_private { ... }
}

__END__
=pod

=head1 NAME

PureMopClass -- test class

=head1 SYNOPSIS

  use PureMopClass;
  # TODO write synopsis

=head1 DESCRIPTION

TODO write this

=head1 ATTRIBUTES

=head2 class_public_stuff

TODO write this

=head1 METHODS

=head2 class_i_am_covered

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
