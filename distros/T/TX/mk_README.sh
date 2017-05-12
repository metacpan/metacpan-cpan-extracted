#!/bin/bash

perl -pe '/^=head1 DESCRIPTION/ and print <STDIN>' lib/TX.pm >README.pod <<EOF
=head1 INSTALLATION

 perl Makefile.PL
 make
 make test
 make install

=head1 DEPENDENCIES

=over 4

=item B<*> perl 5.8.8

=item B<*> Text::Template::Library

=back

EOF

perldoc -tU README.pod >README
rm README.pod
