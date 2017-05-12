use strict;
use warnings;

package Petal::CodePerl::Modifiers;
use Petal::CodePerl::Expr;

use Scalar::Util qw(reftype);

my @mods;

package Petal::CodePerl::Modifiers::true;

sub process_value
{
	my $class = shift;
	my $hash = shift;
	my $value = shift;

	return defined($value) ?
		(ref($value) && (reftype($value) eq "ARRAY") ? scalar @$value : 1) :
		$value;
}

sub inline
{
	my $self = shift;

	my $hash_expr = shift;
	my $expr = shift;

	my $perlf = <<'EOM';
do{
	my $value = %s;
	defined($value) ?
	(ref($value) && (reftype($value) eq "ARRAY") ? scalar @$value : 1) :
	$value;
}
EOM

	chomp($perlf);

	return Petal::CodePerl::Expr::perlsprintf($perlf, $expr);
}

push @mods , __PACKAGE__;

package Petal::CodePerl::Modifiers::false;

sub process_value
{
	my $class = shift;

	return ! Petal::CodePerl::Modifiers::->process_value(@_);
}

sub inline
{
	my $class = shift;

	my $true_perl = Petal::CodePerl::Modifiers::true->inline(@_);

	Petal::CodePerl::Expr::perlsprintf("! %s", $true_perl);
}

push @mods , __PACKAGE__;

package Petal::CodePerl::Modifiers::encode;

sub process_value
{
	my $class = shift;
	my $hash = shift;
	my $value = shift;

	return $value;
}

push @mods , __PACKAGE__;

=head1 A MODIFIER STUB

package Petal::CodePerl::Modifiers::;

sub process_value
{
	my $class = shift;
	my $hash = shift;
	my $value = shift;
}

sub inline
{
	my $self = shift;

	my $hash_expr = shift;
	my $expr = shift;

	my $perlf = <<'EOM';
EOM

	chomp($perlf);

	return Petal::CodePerl::Expr::perlsprintf($perlf, $expr);
}

push @mods , __PACKAGE__;

=cut

################################

# install the modifiers

foreach my $mod (@mods)
{
	my ($name) = reverse (split( "::", $mod));

	$Petal::Hash::MODIFIERS{"$name:"} = $mod;
}

1;
