use 5.012000;
use strict;
use warnings;
no warnings qw( uninitialized void once );

use Keyword::Simple ();
use PerlX::Assert ();

package PerlX::Assert::Keyword;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.905';
our @ISA       = qw( PerlX::Assert );

sub _install_assert
{
	my $class = shift;
	my ($subname, $globals) = @_;
	my $caller = $globals->{into};
	my $active = $globals->{check};

	Keyword::Simple::define($subname, sub
	{
		my $ref = shift;
		_eat_space($ref);

		my $name;
		if ($$ref =~ /\A(qq\b|q\b|'|")/)
		{
			require Text::Balanced;
			$name = Text::Balanced::extract_quotelike($$ref);
			_eat_space($ref);
			
			if ($$ref =~ /\A,/)
			{
				substr($$ref, 0, 1) = '';
				_eat_space($ref);
				if ($$ref =~ /\A\{/)
				{
					require Carp;
					Carp::croak("Unexpected comma between assertion name and block");
				};
			}
		}
		
		substr($$ref, 0, 0) = $class->_injection(
			$active,
			$name,
			scalar($$ref =~ /\A\{/),
		);
	});
}
 
sub _eat_space
{
	my $ref = shift;
	my $X;
	while (
		($$ref =~ m{\A( \s+ )}x and $X = 1)
		or ($$ref =~ m{\A\#} and $X = 2)
	) {
		$X==2
			? ($$ref =~ s{\A\#.+?\n}{}sm)
			: (substr($$ref, 0, length($1)) = '');
	}
	return;
}

sub _injection
{
	shift;
	my ($active, $name, $do) = @_;
	$do = $do ? "do " : "";
	
	return "() and $do"
		if not $active;
	
	return "die sprintf q[Assertion failed: %s], $name unless $do"
		if defined $name;
	
	return "die q[Assertion failed] unless $do";
}

__PACKAGE__
__END__
