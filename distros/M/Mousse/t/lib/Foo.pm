package Foo;
use Foo::Mousse;
use 5.008003;

has 'this', is => 'rw';

package Foo::Bar;
use Foo::Bar::Baz::Mousse;

has 'that', is => 'rw';

1;

=head1 NAME

Foo - Testing the Mousse

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2010. Ingy döt Net.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
