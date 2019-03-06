package Net::RDAP::Base;
use Net::RDAP::Event;
use Net::RDAP::ID;
use Net::RDAP::Link;
use Net::RDAP::Notice;
use Net::RDAP::Object::Autnum;
use Net::RDAP::Object::Domain;
use Net::RDAP::Object::Entity;
use Net::RDAP::Object::IPNetwork;
use Net::RDAP::Object::Nameserver;
use Net::RDAP::Remark;
use strict;

#
# Constructor method. Expects a hashref as an argument.
#
sub new {
	my ($package, $args) = @_;
	my %self = %{$args};
	return bless(\%self, $package);
}

#
# Returns a (potentially empty) array of <$class> objects
# generated from the hashrefs in C<$ref>, which is
# expected to be a reference to an array.
#
# This should not be used directly.
#
sub objects {
	my ($self, $class, $ref) = @_;

	my @list;

	if (defined($ref) && 'ARRAY' eq ref($ref)) {
		foreach my $item (@{$ref}) {

			my $object = $class->new($item);

			# new object doesn't have a "self" link, but we might be able to create one:
			if ($class =~ /^Net::RDAP::Object/) {
				if (!$object->self) {
					my $base = $self->self->href;
					if ($base) {
						my ($type, $handle);
						if ($class =~ /^Net::RDAP::Object::Domain$/)		{ $type = 'domain'	; $handle = $object->name		}
						elsif ($class =~ /^Net::RDAP::Object::Nameserver$/)	{ $type = 'nameserver'	; $handle = $object->name		}
						elsif ($class =~ /^Net::RDAP::Object::Entity$/)		{ $type = 'entity'	; $handle = $object->handle		}
						elsif ($class =~ /^Net::RDAP::Object::IPNetwork$/)	{ $type = 'ip'		; $handle = $object->range->prefix	}
						elsif ($class =~ /^Net::RDAP::Object::Autnum$/)		{ $type = 'autnum'	; $handle = $object->start		}

						push(@{$object->{'links'}}, {
							'rel' => 'self',
							'type' => 'application/rdap+json',
							'href' => URI->new_abs(sprintf('../%s/%s', $type, $handle), $base)->as_string,
						});
					}
				}
			}

			push(@list, $object);
		}
	}

	return @list;
}

=pod

=head1 NAME

L<Net::RDAP::Base> - base module for some L<Net::RDAP>:: modules.

=head1 DESCRIPTION

You don't use L<Net::RDAP::Base> directly, instead, various other
modules extend it.

=head1 METHODS

=head2 Links

	@links = $object->links;

Returns a (potentially empty) array of L<Net::RDAP::Link> objects.

=cut

sub links { $_[0]->objects('Net::RDAP::Link', $_[0]->{'links'}) }

=pod

=head2 "Self" Link

	$self = $object->self;

Returns a L<Net::RDAP::Link> object corresponding to the C<self>
link of this object (if one is available).

=cut

sub self { (grep { 'self' eq $_->rel } $_[0]->links)[0] }

=pod

=head1 COPYRIGHT

Copyright 2019 CentralNic Ltd. All rights reserved.

=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted,
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in
supporting documentation, and that the name of the author not be used
in advertising or publicity pertaining to distribution of the software
without specific prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut

1;
