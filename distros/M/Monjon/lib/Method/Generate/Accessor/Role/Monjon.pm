use 5.006;
use strict;
use warnings;

use List::Util ();
use Sub::Quote ();

package Method::Generate::Accessor::Role::Monjon;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

use Moo::Role;

my $_fh;
BEGIN {
	$_fh ||= eval { require Hash::FieldHash;                \&Hash::FieldHash::fieldhashes };
	$_fh ||= eval { require Hash::Util::FieldHash::Compat;  \&Hash::Util::FieldHash::Compat::fieldhash };
	$_fh ||= do   { require Hash::Util::FieldHash;          \&Hash::Util::FieldHash::fieldhash };
};

$_fh->(\(our %FIELDS));
$_fh->(\(my %INV_MAKERS));

sub target_class
{
	my $self = shift;
	if (not defined $INV_MAKERS{$self})
	{
		for my $class (keys %Moo::MAKERS)
		{
			next unless defined $Moo::MAKERS{$class}{accessor};
			next unless $self == $Moo::MAKERS{$class}{accessor};
			return( $INV_MAKERS{$self} = $class );
		}
	}
	return $INV_MAKERS{$self};
}

my $order = 0;
sub _monjon_canonicalize
{
	my $self = shift;
	my ($me, $name, $spec) = @_;
	
	$spec->{_order} =++ $order;
	
	# TODO
}

around generate_method => sub
{
	my $next = shift;
	my $self = shift;
	$self->_monjon_canonicalize(@_);
	no warnings qw(once);
	local $Method::Generate::Accessor::CAN_HAZ_XS = 0;
	$self->$next(@_);
};

my $P = __PACKAGE__ . "::";

sub _generate_simple_has
{
	my $self = shift;
	my ($me, $name, $spec) = @_;
	my $name_str = quotemeta($name);
	"exists(\$${P}FIELDS{${me}}{\"${name_str}\"})";
}

sub _generate_simple_clear
{
	my $self = shift;
	my ($me, $name, $spec) = @_;
	my $name_str = quotemeta($name);
	"delete(\$${P}FIELDS{${me}}{\"${name_str}\"})";
}

sub _generate_simple_get
{
	my $self = shift;
	my ($me, $name, $spec) = @_;
	my $name_str = quotemeta($name);
	"\$${P}FIELDS{${me}}{\"${name_str}\"}";
}

sub _generate_core_set
{
	my $self = shift;
	my ($me, $name, $spec, $value) = @_;
	my $name_str = quotemeta($name);
	"\$${P}FIELDS{${me}}{\"${name_str}\"} = ${value}";
}

sub _generate_xs
{
	die "Can't generate XS accessors for Monjon accessors";
}

sub default_construction_string
{
	my $self = shift;
	
	my $ctor  = 'Monjon'->_constructor_maker_for($self->target_class);
	my $all   = $ctor->all_attribute_specs;
	my $total = List::Util::sum(
		0,
		map {
			$self->_calculate_length(undef, $_, $all->{$_})
		} $ctor->monjon_fields,
	);
		
	sprintf(
		'\(my $s = "\0" x %d)',
		$total,
	);
}

my @generators = qw(
	_generate_simple_has
	_generate_simple_clear
	_generate_simple_get
	_generate_core_set
);
for my $method (@generators)
{
	my $packed_generator = "$method\_packed";
	around $method => sub {
		my $next = shift;
		my $self = shift;
		my ($me, $name, $spec) = @_;
		exists($spec->{pack})
			? $self->$packed_generator(@_)
			: $self->$next(@_);
	};
}

sub _generate_simple_has_packed
{
	return '(1)';
}

sub _generate_simple_clear_packed
{
	die "This attribute cannot have a clearer; bailing out";
}

sub _generate_simple_get_packed
{
	my $self = shift;
	my ($me, $name, $spec) = @_;
	sprintf(
		'unpack(q(%s), substr(${%s}, %d, %d))',
		$spec->{pack},
		$me,
		$self->_calculate_offset(@_),
		$self->_calculate_length(@_),
	);
}

sub _generate_core_set_packed
{
	my $self = shift;
	my ($me, $name, $spec, $value) = @_;
	sprintf(
		'substr(${%s}, %d, %d) = pack(q(%s), %s)',
		$me,
		$self->_calculate_offset(@_),
		$self->_calculate_length(@_),
		$spec->{pack},
		$value,
	);
}

sub _calculate_offset
{
	my $self = shift;
	my ($me, $name, $spec) = @_;
	my $target = $self->target_class;
	
	if (not defined $spec->{_pack_offset}{$target})
	{
		my $ctor   = 'Monjon'->_constructor_maker_for($target);
		my $all    = $ctor->all_attribute_specs;
		
		my $offset = 0;
		for my $field ( $ctor->monjon_fields )
		{
			last if $field eq $name;
			$offset += $self->_calculate_length($me, $field, $all->{$field});
		}
		$spec->{_pack_offset}{$target} = $offset;
	}
	
	$spec->{_pack_offset}{$target};
}

sub _calculate_length
{
	my $self = shift;
	my ($me, $name, $spec) = @_;
	$spec->{_pack_length} ||= length pack($spec->{pack}, 0);
}

1;
