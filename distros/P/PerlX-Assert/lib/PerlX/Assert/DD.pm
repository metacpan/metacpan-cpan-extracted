use 5.008001;
use strict;
use warnings;
no warnings qw( uninitialized void once );

use Devel::Declare ();
use PerlX::Assert ();

package PerlX::Assert::DD;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.905';
our @ISA       = qw( PerlX::Assert );

# Would be nice to replace this with an XS version
sub _false { !!0 }

sub _install_assert
{
	my $class = shift;
	my ($subname, $globals) = @_;
	my $caller = $globals->{into};
	my $active = $globals->{check};
	
	my $ctx    = 'PerlX::Assert::DD::_Parser'->new($active, $subname);
	my $parser = sub { $ctx->init(@_); $ctx->parse };
	'Devel::Declare'->setup_for(
		$caller,
		{ $subname => { const => $parser } },
	);
	
	no strict qw(refs);
	*{"$caller\::$subname"} = \&_false;
}

{
	package # hide
		PerlX::Assert::DD::_Parser;
	use Devel::Declare::Context::Simple ();
	our @ISA = qw( Devel::Declare::Context::Simple );
	
	my $NULLOP = sub {};
	
	sub new
	{
		my $class = shift;
		my ($active, $subname) = @_;
		my $self = $class->SUPER::new;
		$self->{is_active} = $active;
		$self->{subname}   = $subname || 'assert';
		$self;
	}
	
	sub is_active
	{
		my $self = shift;
		$self->{is_active};
	}
	
	sub get_remainder
	{
		my $self = shift;
		substr($self->get_linestr, $self->offset);
	}
	
	sub strip_quoted_string
	{
		require Text::Balanced;
		
		my $self = shift;
		
		my $line = $self->get_remainder;
		my $str  = Text::Balanced::extract_quotelike($self->get_remainder);
		$self->inc_offset(length $str);
		
		return $str;
	}
	
	sub parse
	{
		my $self = shift;
		
		my $offset1 = $self->offset;
		
		# strip declarator
		my $linestr = $self->get_linestr;
		substr($linestr, $offset1, length($self->{subname})) = '';
		$self->set_linestr($linestr);
		$self->skipspace;
		
		my $name;
		if ($self->get_remainder =~ /\A(qq\b|q\b|'|")/)
		{
			$name = $self->strip_quoted_string;
			$self->skipspace;
			
			if ($self->get_remainder =~ /\A,/)
			{
				$self->inc_offset(1);
				$self->skipspace;
				
				if ($self->get_remainder =~ /\A\{/)
				{
					require Carp;
					Carp::croak("Unexpected comma between assertion name and block");
				};
			};
		}
		
		$linestr = $self->get_linestr;
		my $offset2 = $self->offset;
		substr($linestr, $offset1, $offset2-$offset1) = $self->_injection(
			$name,
			scalar($self->get_remainder =~ /\A\{/),
		);
		$self->set_linestr($linestr);
		
		#die("[[[".$self->get_linestr."]]]");
	}
	
	sub _injection
	{
		my $self = shift;
		my ($name, $do) = @_;
		$do = $do ? "do " : "";
		
		my $spaces = q[ ] x length($self->{subname});
		
		return $spaces."() and $do"
			if not $self->is_active;
		
		return $spaces."die(sprintf q[Assertion failed: %s], $name) unless $do"
			if defined $name;
		
		return $spaces."die(sprintf q[Assertion failed]) unless $do";
	}
}

__PACKAGE__
__END__
