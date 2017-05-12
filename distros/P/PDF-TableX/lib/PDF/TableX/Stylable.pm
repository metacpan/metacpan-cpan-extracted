package PDF::TableX::Stylable;

use Moose::Role;
use PDF::TableX::Types qw/StyleDefinition/;

# public attributes for styles
has padding          => (is => 'rw', isa => StyleDefinition, coerce => 1, default => sub{[1,1,1,1]} );
has border_width     => (is => 'rw', isa => StyleDefinition, coerce => 1, default => sub{[1,1,1,1]} );
has border_color     => (is => 'rw', isa => StyleDefinition, coerce => 1, default => 'black' );
has border_style     => (is => 'rw', isa => StyleDefinition, coerce => 1, default => 'solid' );
has background_color => (is => 'rw', isa => 'Str', default => '' );
has text_align       => (is => 'rw', isa => 'Str', default => 'left');
has font             => (is => 'rw', isa => 'Any', default => 'Times');
has font_color       => (is => 'rw', isa => 'Str', default => 'black');
has font_size        => (is => 'rw', isa => 'Num', default => 12);
has margin           => (is => 'rw', isa => StyleDefinition, coerce => 1, default => (10 / 25.4 *72) );

has _children => (is => 'ro', init_arg => undef, isa => 'ArrayRef[ Object ]', default => sub {[]});

for my $attr  ( __PACKAGE__->attributes ) {
	around $attr => sub {
		my ($orig, $self, $value) = @_;
		if ( defined $value ) {
			$self->$orig($value);
			for (@{$self->{_children}}) {
				$_->$attr( $value );
			}
			return $self;
		} else {
			return $self->$orig;
		}
	};
}

sub attributes {
	return (grep !/^_/, __PACKAGE__->meta->get_attribute_list);
}

1;

=head1 NAME

PDF::TableX::Stalable

=head1 VERSION

 TODO

=head1 SYNOPSIS

 TODO

=head1 METHODS

=head2 attributes

 TODO

=head1 AUTHOR

Grzegorz Papkala, C<< <grzegorzpapkala at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests at: L<https://github.com/grzegorzpapkala/PDF-TableX/issues>

=head1 SUPPORT

PDF::TableX is hosted on GitHub L<https://github.com/grzegorzpapkala/PDF-TableX>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2013 Grzegorz Papkala, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
