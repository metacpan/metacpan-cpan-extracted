package Q::S::L;

our $VERSION = '1.11';

use v5.24;
use warnings;

use parent 'Quantum::Superpositions::Lazy';
use Quantum::Superpositions::Lazy qw(:all);

our @EXPORT = @Quantum::Superpositions::Lazy::EXPORT;
our @EXPORT_OK = @Quantum::Superpositions::Lazy::EXPORT_OK;
our %EXPORT_TAGS = %Quantum::Superpositions::Lazy::EXPORT_TAGS;

1;
__END__

=head1 NAME

Q::S::L - Shortcut for Quantum::Superpositions::Lazy

=head1 SYNOPSIS

	use Q::S::L qw(superpos every_state ...);

	my $position_1 = superpos(1 .. 10);

	# continue as with regular Quantum::Superpositions::Lazy

=head1 DESCRIPTION

This module is just a shorter name for L<Quantum::Superpositions::Lazy>. See
its documentation for details.

