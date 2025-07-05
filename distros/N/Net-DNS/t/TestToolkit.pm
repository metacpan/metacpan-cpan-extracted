# $Id: TestToolkit.pm 2017 2025-06-27 13:48:03Z willem $	-*-perl-*-

package TestToolkit;

=head1 NAME

TestToolkit - Convenient tools to simplify test script construction.

=cut

use strict;
use warnings;
use Carp;
use Test::Builder;
use Test::More;

use base qw(Exporter);
our @EXPORT = qw(exception noexception NonFatalBegin NonFatalEnd);


=head1 exception noexception

	[no]exception( 'test description', sub { code fragment } );

Executes the supplied code fragment and reports a raised exception or
warning using the Test::More ok() mechanism.

=cut

sub exception {
	my ( $name, $code ) = @_;

	my $exception = _execute($code);
	my $boolean   = $exception ? 1 : 0;

	my $tb = Test::Builder->new;
	return $tb->ok( $boolean, "$name\t[$exception]" );
}

sub noexception {
	my ( $name, $code ) = @_;

	my $exception = _execute($code);
	my $boolean   = $exception ? 0 : 1;

	my $tb = Test::Builder->new;
	return $tb->ok( $boolean, $exception ? "$name\t[$exception]" : $name );
}

sub _execute {
	my $code = shift;
	my @warning;
	local $SIG{__WARN__} = sub { push @warning, "@_" };
	local ( $@, $!, $SIG{__DIE__} );	## isolate eval
	eval {
		&$code;
		die "$_\n" for @warning;
	};
	my ($exception) = split /[\r\n]+/, "$@\n";
	return $exception;
}


########################################
#
# Test::More test functions all eventually call Test::Builder::ok
# (on the (singular) builder instance) to report the status.
# The NonFatal package defines a subclass derived from Test::Builder,
# with a redefined ok method that overrides the completion status
# seen by the test harness.
#
# Note: Modified behaviour is enabled by the 't/online.nonfatal' file.
#

=head1 NonFatalBegin NonFatalEnd

Tests that are between these functions will always appear to succeed.
The failure report itself is not suppressed.

=cut

sub NonFatalBegin { return bless Test::Builder->new, qw(NonFatal) }

sub NonFatalEnd { return bless Test::Builder->new, qw(Test::Builder) }


package NonFatal;
use base qw(Test::Builder);

my $enabled = eval { -e 't/online.nonfatal' };
my @failed;

sub ok {
	my ( $self, $test, @name ) = @_;
	return $self->SUPER::ok( $test, @name ) if $test;

	if ($enabled) {
		my $number = $self->current_test + 1;
		push @failed, join( "\t", $number, @name );
		@name = "NOT OK (tolerating failure)	@name";
	}

	return $self->SUPER::ok( $enabled, @name );
}

END {
	my $n  = scalar(@failed) || return;
	my $s  = ( $n == 1 ) ? '' : 's';
	my $tb = __PACKAGE__->SUPER::new();
	$tb->diag( join "\n", "\nDisregarding $n failed sub-test$s", @failed );
}

1;

__END__

