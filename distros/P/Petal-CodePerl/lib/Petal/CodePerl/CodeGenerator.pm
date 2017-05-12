use strict;
use warnings;

package Petal::CodePerl::CodeGenerator;

use Petal::CodeGenerator;
our @ISA = qw( Petal::CodeGenerator );

# bring in the base in case we were loaded independently
use Petal::CodePerl;
use Petal::CodePerl::Compiler;

use Code::Perl::Expr qw( scal );

use Data::Dumper qw(Dumper);

# the root
my $hash = scal("hash");

# with the CodePerl code generator, we don't cache things so there's no need
# to blow away the cache at every loop

sub need_new_hash
{
	return 0;
}

sub comp_expr
{
	my $self = shift;
	my $expr = shift;

	# make sure the root is in place for the parser

	$Petal::CodePerl::Compiler::root->setExpr($hash);

	if ($expr =~ s/^set:\s+//)
	{
		(my $name, $expr) = split(/\s+/, $expr, 2);
		my $expr_perl = comp($expr);
		my $name_perl = comp($name);

#		print "name = $name\n";
#		print "np = $name_perl\n";
#		print "expr = $expr\n";
#		print "ep = $expr_perl\n";
		return qq{do {$name_perl = $expr_perl;""}}
	}
	else
	{
		my $struct = $expr =~ s/^structure\s+//;
		my $expr_perl = comp($expr);

		return $struct ?
			$expr_perl :
			"Petal::XML_Encode_Decode::encode($expr_perl)";
	}
}

sub comp
{
# this compiles an expression down to Perl code

	my $expr = shift;

	my $perl;

	# get rid of Petal's quoting before trying to parse
	$expr = eval "'$expr'";
	$expr =~ s/\\;/;/g;

	if (($expr =~ /^[a-z][a-z0-9_]*:/) and ($expr !~ /^(path|string|exists|not|perl):/))
	{
		# using a modifier not built into TALES so fall back to $hash->get()
		return '$hash->get("'.quotemeta($expr).'")';
	}
	else
	{
		my $comp = Petal::CodePerl::Compiler->compile(\$expr);

		return $comp->perl;
	}
}

# ignore from here down!!

sub call_modifier
{
	my $hash = shift;
	my $modifier = shift;
	my $value = shift;

	$hash = Petal::CodePerl::Hash->new($value);

	my $module = $Petal::Hash::MODIFIERS->{$modifier};

	defined($module) or die "No module '$modifier'";

	return ref($module) eq "CODE" ? $module->($hash, $value) :
	                                $module->process($hash, $value);
}

package Petal::CodePerl::Hash;

sub new
{
	my $pkg = shift;
	my $value = shift;

	return bless \$value, $pkg;
}

sub get
{
	my $self = shift;

	return $$self;
}

sub fetch
{
	my $self = shift;

	return $$self;
}

1;
