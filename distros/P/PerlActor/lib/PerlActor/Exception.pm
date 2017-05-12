package PerlActor::Exception;

use Error qw( :try );
use base qw (Error::Simple);

sub new
{
	my $proto = shift;
	my $class = ref $proto || $proto;
	my $text = shift;
	$text = '' unless $text;
	my $value = shift;
	return $class->SUPER::new($text, $value);
}

# Keep Perl happy.
1;
