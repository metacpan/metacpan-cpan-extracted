use 5.006;
use strict;
use warnings;

use Sub::Quote ();

package Method::Generate::Constructor::Role::Monjon;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

use Moo::Role;

sub monjon_fields
{
	my $all = shift->all_attribute_specs;
	return
		sort {
			(
				defined($all->{$a}{_order})
				and defined($all->{$b}{_order})
				and $all->{$a}{_order} <=> $all->{$b}{_order}
			)
				or $all->{$a}{index} <=> $all->{$b}{index}
		}
		grep { exists($all->{$_}{pack}) }
		keys(%$all);
}

before generate_method => sub
{
	my $self = shift;
	my ($into, $name, $spec, $quote_opts) = @_;
	
	my $maker = 'Monjon'->_accessor_maker_for($into);
	my $all   = $self->all_attribute_specs;
	for my $field ($self->monjon_fields)
	{
		my %spec = %{ $all->{$field} };
		$spec{allow_overwrite} = 1;
		$maker->generate_method($into, $field, \%spec, $quote_opts);
	}
};

around _handle_subconstructor => sub
{
	my $next = shift;
	my $self = shift;
	my ($into, $name) = @_;
	
	return sprintf(
		'$Monjon::INSTANCES_EXIST{"%s"} = 1; %s',
		quotemeta($into),
		$self->$next(@_),
	);
};

1;
