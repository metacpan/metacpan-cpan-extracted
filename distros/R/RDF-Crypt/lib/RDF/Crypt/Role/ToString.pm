package RDF::Crypt::Role::ToString;

use 5.010;
use Any::Moose 'Role';

use namespace::clean;
#use overload
#	q[""]    => 'to_string',
#	q[bool]  => sub { 1 },
#	fallback => 1;
use constant _LENGTH => 72;

BEGIN {
	$RDF::Crypt::Role::ToString::AUTHORITY = 'cpan:TOBYINK';
	$RDF::Crypt::Role::ToString::VERSION   = '0.002';
}

sub to_string
{
	my ($self, $title) = @_;
	$title //= ref $self;
	
	my $str;
	$str .= ('=' x $self->_LENGTH) . "\n";
	$str .= $title . "\n";
	if ($self->can('private_key'))
	{
		$str .= $self->_key_to_string($self->private_key, 'Private Key');
	}
	if ($self->can('public_keys'))
	{
		my @keys = @{ $self->public_keys || [] };
		$str .= $self->_key_to_string($keys[$_], "Public Key $_") for 0 .. $#keys;
	}
	$str .= ('=' x $self->_LENGTH) . "\n";
	return $str;
}

sub _key_to_string
{
	my ($self, $key, $title) = @_;
	my $str;
	$str .= ('-' x $self->_LENGTH) . "\n";
	$str .= $title . "\n";
	$str .= $key->get_public_key_string;
	return $str;
}

1;

__END__

=head1 NAME

RDF::Crypt::Role::ToString - provides a data dump

=head1 DESCRIPTION

This is fairly handy as Data::Dumper doesn't peek inside Crypt::OpenSSL::RSA
keys.

=head2 Object Method

=over

=item C<< to_string($title) >>

Returns a string representing the object, with an optional title.

=back

Ultimately this will probably use L<overload>, but it doesn't right now.

=head1 SEE ALSO

L<RDF::Crypt>,
L<RDF::Crypt::Encrypter>,
L<RDF::Crypt::Decrypter>,
L<RDF::Crypt::Signer>,
L<RDF::Crypt::Verifier>.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2010, 2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

