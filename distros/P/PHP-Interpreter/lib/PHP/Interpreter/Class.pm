package PHP::Interpreter::Class;

use strict;

use vars qw/$AUTOLOAD @ISA/;

sub AUTOLOAD {
  my $self = shift;
  my $sub = $AUTOLOAD;
  (my $method = $sub) =~ s/.*:://;
  unshift @_, $method;
  unshift @_, $self;
  goto &_AUTOLOAD;
}

1;

__END__

=head1 NAME

PHP::Interpreter::Class - PHP interpreter classes

=head1 DESCRIPTION

This class is the opaque base class for PHP object containers. PHP objects
returned into PHP will be wrapped in objects of type
PHP::Interpreter::Class::$CLASSNAME, which is a descendent of
PHP::Interpreter::Class. All method calls and attribute accesses which could
be performed on the PHP object are performable on the Perl wrapper as well.

See L<PHP::Interpreter|PHP::Interpreter>.

=head1 INTERFACE

This class has no public methods outside of the AUTOLOAD method supporting its
proxy pattern.

=begin comment

=head3 create

Fool Test::Pod::Coverage, which seems to think that there's a create() method
here.

=end comment

=head1 BUGS

Please send bug reports to <bug-php-interpreter@rt.cpan.org>.

=head1 AUTHORS

George Schlossnagle <george@omniti.com>

=head1 CREDITS

Development sponsored by Portugal Telecom - SAPO.pt.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 Kineticode, Inc. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
