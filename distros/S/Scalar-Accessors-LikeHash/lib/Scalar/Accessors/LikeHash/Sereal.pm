package Scalar::Accessors::LikeHash::Sereal;

use 5.008;
use strict;
use warnings;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Sereal;

use Role::Tiny::With;
with 'Scalar::Accessors::LikeHash';

my ($e, $d);

sub _to_hash
{
	my ($ref) = @_;
	($d ||= Sereal::Decoder::->new)->decode($$ref);
}

sub _from_hash
{
	my ($ref, $hash) = @_;
	$$ref = ($e ||= Sereal::Encoder::->new)->encode($hash);
}

1;

__END__

=head1 NAME

Scalar::Accessors::LikeHash::Sereal - access a Sereal scalar string in a hash-like manner

=head1 SYNOPSIS

   my $object = Scalar::Accessors::LikeHash::Sereal->new;
   
   $object->store(some_key => 42) unless $object->exists('some_key');
   $object->fetch('some_key');
   $object->delete('some_key');
   
   # The object is internally a blessed scalarref containing Sereal
   print $$object; 

=head1 DESCRIPTION

This is a concrete implementation of L<Scalar::Accessors::LikeHash>.

This module requires L<Sereal> to be installed.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Scalar-Accessors-LikeHash>.

=head1 SEE ALSO

L<Scalar::Accessors::LikeHash>, L<Sereal>.

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

