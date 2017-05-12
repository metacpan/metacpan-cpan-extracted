package Object::Tiny::RW::XS;

use strict 'vars', 'subs';
BEGIN {
	require 5.004;
	$Object::Tiny::RW::XS::VERSION = '0.03';
}

sub import {
	return unless shift eq 'Object::Tiny::RW::XS';
	my $pkg   = caller;
	my $child = !! @{"${pkg}::ISA"};
	eval join "\n",
		"package $pkg;",
		($child ? () : "\@${pkg}::ISA = 'Object::Tiny::RW::XS';"),
			"use Class::XSAccessor accessors => {",
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

Object::Tiny::RW::XS - Class building as simple as it gets (with rw accessors and XS compatibility)

=head1 SYNOPSIS

  # Define a class
  package Foo;
  
  use Object::Tiny::RW::XS qw{ bar baz };
  
  1;
  
  
  # Use the class
  my $object = Foo->new( bar => 1 );
  
  print "bar is " . $object->bar . "\n";       # 1
  $object->bar(2);
  print "bar is now " . $object->bar . "\n";   # 2

=head1 DESCRIPTION

This module is a fork of Object::Tiny::RW. The only difference is that it
uses L<Class::XSAccessor> to generate faster accessors and constructors.

Please see L<Object::Tiny> and L<Object::Tiny::RW> for all the original ideas.

To use Object::Tiny::RW::XS, just call it with a list of accessors to be
created.

  use Object::Tiny::RW::XS 'foo', 'bar';

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Object-Tiny-RW-XS>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt> for original Object::Tiny.

Steffen Schwigon E<lt>ss5@renormalist.netE<gt> for the Object::Tiny::RW variant.

Adam Hopkins E<lt>srchulo@cpan.org<gt> for the Object::Tiny::RW::XS variant.

=head1 SEE ALSO

L<Config::Tiny>

=head1 COPYRIGHT

Copyright 2007 - 2008 Adam Kennedy.

Copyright 2009-2011 Steffen Schwigon.

Copyright 2013 Adam Hopkins

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
