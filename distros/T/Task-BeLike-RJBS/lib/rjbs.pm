package rjbs 20210619.000;
# ABSTRACT: all the junk that rjbs likes in his one-offs

use 5.20.0;
use feature ();
use experimental ();


sub import {
  strict->import;
  warnings->import;
  feature->import(':5.20');
  experimental->import(qw( signatures postderef lexical_subs ));

  $] >= 5.022000 && experimental->import(qw( bitwise refaliasing ));
  $] >= 5.026000 && experimental->import(qw( declared_refs ));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

rjbs - all the junk that rjbs likes in his one-offs

=head1 VERSION

version 20210619.000

=head1 OVERVIEW

When you C<use rjbs> you get a whole bunch of other pragmata turned on.  It
turns on strict, warnings, all the v5.20 features, signatures, postfix
dereferencing, lexical subs, and if possible: unambiguous bitwise operators and
reference aliasing.

The exact behavior of this module is subject to change.  Consider it the "toy
inside" Task::BeLike::RJBS.

=head1 TASK CONTENTS

=head1 AUTHOR

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
