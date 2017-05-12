package Scalar::Accessors::LikeHash::JSON;

use 5.008;
use strict;
use warnings;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use JSON;

use Role::Tiny::With;
with 'Scalar::Accessors::LikeHash';

my ($j);

sub _empty_structure
{
	q({});
}

sub _to_hash
{
	my ($ref) = @_;
	($j ||= JSON::->new)->decode($$ref);
}

sub _from_hash
{
	my ($ref, $hash) = @_;
	$$ref = ($j ||= JSON::->new)->encode($hash);
}

1;

__END__

=head1 NAME

Scalar::Accessors::LikeHash::JSON - access a JSON scalar string in a hash-like manner

=head1 SYNOPSIS

   my $object = Scalar::Accessors::LikeHash::JSON->new;
   
   $object->store(some_key => 42) unless $object->exists('some_key');
   $object->fetch('some_key');
   $object->delete('some_key');
   
   # The object is internally a blessed scalarref containing JSON
   print $$object; 

=head1 DESCRIPTION

This is a concrete implementation of L<Scalar::Accessors::LikeHash>.

This module requires L<JSON> to be installed.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Scalar-Accessors-LikeHash>.

=head1 SEE ALSO

L<Scalar::Accessors::LikeHash>,
L<JSON>,
L<Acme::MooseX::JSON>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

