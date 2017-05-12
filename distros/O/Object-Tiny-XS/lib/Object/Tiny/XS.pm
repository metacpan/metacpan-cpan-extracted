package Object::Tiny::XS;
use strict 'vars', 'subs';

BEGIN {
	require 5.004;
	$Object::Tiny::XS::VERSION = '1.01';
}

sub import {
	return unless shift eq 'Object::Tiny::XS';
	my $pkg   = caller;
	my $child = !! @{"${pkg}::ISA"};
	eval join "\n",
		"package $pkg;",
		($child ? () : "\@${pkg}::ISA = 'Object::Tiny::XS';"),
                "use Class::XSAccessor getters => {",
		(map {
			defined and ! ref and /^[^\W\d]\w*$/s
			or die "Invalid accessor name '$_'";
			"'$_' => '$_',"
		} @_),
                "};";
	die "Failed to generate $pkg" if $@;
	return 1;
}

use Class::XSAccessor
  constructor => 'new';

1;

__END__

=pod

=head1 NAME

Object::Tiny::XS - Class building as simple as it gets and FAST

=head1 SYNOPSIS

  # Define a class
  package Foo;
  
  use Object::Tiny::XS qw{ bar baz };
  
  1;
  
  
  # Use the class
  my $object = Foo->new( bar => 1 );
  
  print "bar is " . $object->bar . "\n";

=head1 DESCRIPTION

This module does the same that L<Object::Tiny> does, but it uses
C<Class::XSAccessor> to generate faster accessors and constructors.

For details on the little interface there is, please check
C<Object::Tiny>.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Object-Tiny-XS>

For other issues, contact the author.

=head1 AUTHOR

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Object::Tiny>

L<Class::XSAccessor>

=head1 COPYRIGHT

Copyright 2008 Adam Kennedy, Steffen Mueller.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
