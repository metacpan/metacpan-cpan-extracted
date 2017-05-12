package # hide from PAUSE
	Net::Bamboo::Build;

use Moose;
use Moose::Util::TypeConstraints;

use DateTimeX::Easy;

subtype DateTime => as Object	=> where { $_->isa('DateTime') };
coerce  DateTime => from Str	=> via { new DateTimeX::Easy $_ => tz => 'local' };

has plan			=> (isa => 'Net::Bamboo::Plan',	is => 'ro');
has key				=> (isa => 'Str',				is => 'ro');
has number			=> (isa => 'Int',				is => 'ro');
has state			=> (isa => 'Str',				is => 'ro');
has reason			=> (isa => 'Str',				is => 'ro');
has date_started	=> (isa => 'DateTime',			is => 'ro', coerce => 1);
has date_completed	=> (isa => 'DateTime',			is => 'ro', coerce => 1);
has num_tests_ok	=> (isa => 'Int',				is => 'ro');
has num_tests_fail	=> (isa => 'Int',				is => 'ro');
#has link	=> (isa => Uri,					is => 'ro', coerce => 1);

sub duration
{
	my $self = shift;

	return $self->date_completed - $self->date_started;
}

sub succeeded
{
	shift->state eq 'Successful';
}

sub failed
{
	shift->state eq 'Failed';
}

1;

