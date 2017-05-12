package Neocracy::ORM::Meta::Display::Defaults;

use Moose::Role;

has 'admin_showable'      => (is => 'rw', default => 1);
has 'item_showable'       => (is => 'rw', default => 1); 
has 'collection_showable' => (is => 'rw', default => 1); 

has 'user_mutable'        => (is => 'rw', default => 1);
has 'admin_mutable'       => (is => 'rw', default => 1);

has 'display_name'        => (is => 'rw');

has 'formatter'           => (is => 'rw', isa => 'CodeRef');
has 'admin_validator'     => (is => 'rw', isa => 'CodeRef');
has 'user_validator'      => (is => 'rw', isa => 'CodeRef');

around 'legal_options_for_inheritance' => sub {
	my $next = shift;
	my $self = shift;
	my @options = $self->$next();
	@options = ( @options, qw(admin_showable item_showable collection_showable formatter) );
	return @options;
};

no Moose;

package Moose::Meta::Attribute::Custom::Trait::AttributeDisplayDefaults;
sub register_implementation {'Neocracy::ORM::Meta::Display::Defaults'}

1;
