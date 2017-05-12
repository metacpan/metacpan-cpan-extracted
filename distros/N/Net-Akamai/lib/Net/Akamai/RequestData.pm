package Net::Akamai::RequestData;

use Moose;
use MooseX::AttributeHelpers;
use SOAP::Lite;
use Net::Akamai::RequestData::Types;

=head1 NAME
    
Net::Akamai::RequestData - Object to hold request data 
    
=head1 DESCRIPTION

Data container for an akamai purge request

=cut

=head1 Attributes

=head2 user 

akamai login user

=cut
has 'user' => (
	is => 'rw', 
	isa => 'Str',
	required => 1,
);

=head2 pwd 

password of the akamai user

=cut
has 'pwd' => (
	is => 'rw', 
	isa => 'Str',
	required => 1,
);

=head2 network 

akamai network (do not change)

=cut
has 'network' => (
	is => 'ro', 
	isa => 'Str',
	default => 'ff',
);

=head2 ptype 

akamai purge type (cpcode|arl)

=cut
has 'ptype' => (
	is => 'ro', 
	isa => 'Net::Akamai::RequestData::Types::PurgeType',
	default => 'arl',
	predicate => 'has_ptype',
);

=head2 action 

default akamai purge action (invalidate|remove)

=cut
has 'action' => (
	is => 'ro', 
	isa => 'Net::Akamai::RequestData::Types::PurgeAction',
	predicate => 'has_action',
	default => 'remove',
);

=head2 email 

email purge request will be sent to

=cut
has 'email' => (
	is => 'rw', 
	isa => 'Str',
	predicate => 'has_email',
);

=head2 urls 

array of urls to purge

=cut
has 'urls' => (
	metaclass => 'Collection::Array',
	is        => 'rw',
	isa       => 'ArrayRef[Object]',
	default   => sub { [] },
	provides  => {
		'push' => 'add_url',
		'pop'  => 'remove_last_url',
	},
);

around 'add_url' => sub { 
	my $next = shift; 
	my $self = shift;
	my $arg = shift; 

	my $soap_data = SOAP::Data->type('string')->value($arg);
	$self->$next($soap_data, @_);
};

=head2 options 

array of soap options 

=cut

has 'options' => (
	is        => 'rw',
	isa       => 'Net::Akamai::RequestData::Types::PurgeOptionsArrayRef',
	coerce    => 1,
	lazy_build => 1,
);

sub _build_options {
	my $self = shift;
	my @ret;

	push @ret, "email-notification=".$self->email if $self->has_email;
	push @ret, "type=".$self->ptype;
	push @ret, "action=".$self->action;
	# This terminates this list of options and insures the options array is not null
	push @ret, "";
	\@ret;
};

=head1 AUTHOR

John Goulah  <jgoulah@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


1;
