#!/bin/bash

perl -pe '/^=head1 DESCRIPTION/ and print <STDIN>' lib/Sys/Proctitle.pm >README.pod <<EOF
=head1 INSTALLATION

 perl Makefile.PL
 make
 make test
 make install

=head1 DEPENDENCIES

=over 4

=item *

This module works only on linux.

=item *

perl 5.8.0

=back

EOF

perldoc -tU README.pod >README
rm README.pod
