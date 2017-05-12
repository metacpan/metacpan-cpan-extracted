package PurePerlClass;

use strict;
use warnings;
use 5.012;
use Carp;

sub pp_i_am_covered { ... }
sub pp_i_am_not_covered { ... }
sub _pp_i_look_private { ... }

1;
__END__
=pod

=head1 NAME

PurePerlClass -- test class

=head1 SYNOPSIS

  use PurePerlClass;
  # TODO write synopsis

=head1 DESCRIPTION

TODO write this

=head1 ATTRIBUTES

None.

=head1 METHODS

=head2 pp_i_am_covered

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
