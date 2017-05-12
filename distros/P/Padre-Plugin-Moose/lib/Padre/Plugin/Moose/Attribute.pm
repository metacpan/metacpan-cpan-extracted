package Padre::Plugin::Moose::Attribute;

use Moose;

our $VERSION = '0.21';

extends 'Padre::Plugin::Moose::ClassMember';

with 'Padre::Plugin::Moose::Role::CanGenerateCode';
with 'Padre::Plugin::Moose::Role::CanProvideHelp';
with 'Padre::Plugin::Moose::Role::CanHandleInspector';

has 'access_type'   => ( is => 'rw', isa => 'Str' );
has 'type'          => ( is => 'rw', isa => 'Str' );
has 'trigger'       => ( is => 'rw', isa => 'Str' );
has 'required'      => ( is => 'rw', isa => 'Bool' );
has 'class_has'     => ( is => 'rw', isa => 'Bool' );
has 'coerce'        => ( is => 'rw', isa => 'Bool' );
has 'does'          => ( is => 'rw', isa => 'Str' );
has 'weak_ref'      => ( is => 'rw', isa => 'Bool' );
has 'lazy'          => ( is => 'rw', isa => 'Bool' );
has 'builder'       => ( is => 'rw', isa => 'Str' );
has 'default'       => ( is => 'rw', isa => 'Str' );
has 'clearer'       => ( is => 'rw', isa => 'Str' );
has 'predicate'     => ( is => 'rw', isa => 'Str' );
has 'documentation' => ( is => 'rw', isa => 'Str' );

my @FIELDS = qw(
	name access_type type class_has required trigger coerce does weak_ref
	lazy builder default clearer predicate documentation);

sub generate_moose_code {
	my $self    = shift;
	my $options = shift;
	my $comment = $options->{comments};

	my $has_code = '';
	$has_code .= ( "\tis  => '" . $self->access_type . "',\n" )
		if defined $self->access_type && $self->access_type ne '';
	$has_code .= ( "\tisa => '" . $self->type . "',\n" )      if defined $self->type    && $self->type    ne '';
	$has_code .= ("\trequired => 1,\n")                       if $self->required;
	$has_code .= ( "\ttrigger => " . $self->trigger . ",\n" ) if defined $self->trigger && $self->trigger ne '';

	my $has = ( $self->class_has ) ? 'class_has' : 'has';
	return "$has '" . $self->name . "'" . ( $has_code ne '' ? qq{ => (\n$has_code)} : q{} ) . ";\n";
}

# Generate Mouse code!
sub generate_mouse_code {
	my $self    = shift;
	my $options = shift;
	my $comment = $options->{comments};

	my $has_code = '';
	$has_code .= ( "\tis  => '" . $self->access_type . "',\n" )
		if defined $self->access_type && $self->access_type ne '';
	$has_code .= ( "\tisa => '" . $self->type . "',\n" )      if defined $self->type    && $self->type    ne '';
	$has_code .= ("\trequired => 1,\n")                       if $self->required;
	$has_code .= ( "\ttrigger => " . $self->trigger . ",\n" ) if defined $self->trigger && $self->trigger ne '';

	return "has '" . $self->name . "'" . ( $has_code ne '' ? qq{ => (\n$has_code)} : q{} ) . ";\n";
}

sub generate_moosex_declare_code {
	return $_[0]->generate_moose_code(@_);
}

sub provide_help {
	require Wx;
	return Wx::gettext('An attribute is a property that every member of a class has.');
}

sub read_from_inspector {
	my $self = shift;
	my $grid = shift;

	my $row = 0;
	for my $field (@FIELDS) {
		$self->$field( $grid->GetCellValue( $row++, 1 ) );
	}
}

sub write_to_inspector {
	my $self = shift;
	my $grid = shift;

	my $row = 0;
	for my $field (@FIELDS) {
		$grid->SetCellValue( $row++, 1, $self->$field );
	}
}

sub get_grid_data {
	require Wx;
	return [
		{ name => Wx::gettext('Name:') },
		{ name => Wx::gettext('Access type:'), choices => [qw(rw ro bare)] },
		{   name    => Wx::gettext('Type:'),
			choices => [
				qw(Any Item Bool Maybe[] Undef Defined Value Str Num Int ClassName RoleName Ref ScalarRef[] ArrayRef[] HashRef[] CodeRef RegexpRef GlobRef FileHandle Object)
			]
		},
		{ name => Wx::gettext('Class Attribute?'), is_bool => 1 },
		{ name => Wx::gettext('Required?'),        is_bool => 1 },
		{ name => Wx::gettext('Trigger:') },
		{ name => Wx::gettext('Coerce?'),          is_bool => 1 },
		{ name => Wx::gettext('Does role:') },
		{ name => Wx::gettext('Weak Ref?'),        is_bool => 1 },
		{ name => Wx::gettext('lazy?'),            is_bool => 1 },
		{ name => Wx::gettext('Builder:') },
		{ name => Wx::gettext('Default:') },
		{ name => Wx::gettext('Clearer:') },
		{ name => Wx::gettext('Predicate:') },
		{ name => Wx::gettext('Documentation:') },
	];
}

__PACKAGE__->meta->make_immutable;

no Moose;
1;
