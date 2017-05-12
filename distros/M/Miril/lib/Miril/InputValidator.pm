package Miril::InputValidator;

use strict;
use warnings;
use autodie;

use List::Util qw(first);
use Data::AsObject qw(dao);

### ACCESSORS ###

use Object::Tiny qw(validator_rx);

### CONSTRUCTOR ###

sub new {
	my $class = shift;
	my $self = bless {}, $class;

	$self->{validator_rx} = {
		line_text 		=> qr/.*/,
		paragraph_text 	=> qr/.*/m,
		text_id 		=> qr/^[\w\-]{1,256}$/,
		datetime 		=> qr/.*/,
		integer 		=> qr/^\d{1,8}$/,
	};

	return $self;
}

### PUBLIC METHODS ###

sub validate {
	my ($self, $schema, %data) = @_;
	my %invalid_fields;



	foreach my $key (keys %$schema) {
		my ($type, @other) = split /\s/, $schema->{$key};
		
		my $required = 1 if first { $_ eq 'required'} @other;
		my $list = 1 if first { $_ eq 'list'} @other;

		my @remaining = grep { $_ ne 'required' and $_ ne 'list' } @other;

		if (@remaining) {
			my $plural = 's' if @remaining > 1;
			my @remaining = map {"'$_'"} @remaining;
			die "Invalid option$plural " . join ',', @remaining . " supplied to validate";
		}
		
		if ( $data{$key} ) {
			push my @items_to_check, $list ? split("\0", $data{$key}) : $data{$key};
			foreach my $item_to_check (@items_to_check) {
				$invalid_fields{$key}++ unless $self->_validate_type($type, $data{$key});
			}
		} else {
			die "Required parameter '$key' missing" if $required;
		}
	}
	keys %invalid_fields ? return dao \%invalid_fields : return;
}

### PRIVATE METHODS ###

sub _validate_type {
	my ($self, $type, $string) = @_;
	die "Illegal datatype $type" unless $self->validator_rx->{$type};
	return unless $string =~ $self->validator_rx->{$type};
}

1;
