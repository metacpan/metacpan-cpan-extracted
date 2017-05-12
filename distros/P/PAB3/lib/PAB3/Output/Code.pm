package PAB3::Output::Code;

use strict;
no strict 'refs';

use vars qw($VERSION);

BEGIN {
	$VERSION = '1.0.0';
}

sub TIEHANDLE {
    my $class = shift;
    my $code = shift;
    bless $code, $class;
}

sub PRINT {
	my $code = shift;
	$code->( @_ );
}

sub PRINTF {
	my $code = shift;
	$code->( @_ );
}

sub WRITE {
	my $code = shift;
	$code->( @_ );
}

sub UNTIE {
}

1;
