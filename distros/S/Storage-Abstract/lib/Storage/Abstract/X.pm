package Storage::Abstract::X;
$Storage::Abstract::X::VERSION = '0.005';
use v5.14;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Types::Common -types;
use namespace::autoclean;

use overload
	q{""} => "as_string",
	fallback => 1;

has param 'message' => (
	isa => Str,
	writer => -hidden,
);

has field 'caller' => (
	default => sub {
		for my $call_level (1 .. 10) {
			my @data = caller $call_level;
			return \@data
				if $data[1] !~ /^\(eval/ && $data[0] !~ /^Storage::Abstract/;
		}
		return undef;
	},
);

sub raise
{
	my ($self, $error) = @_;

	if (defined $error) {
		$self = $self->new(message => $error);
	}

	die $self;
}

sub as_string
{
	my ($self) = @_;

	my $raised = $self->message;
	$raised =~ s/\s+\z//;

	if (my $caller = $self->caller) {
		$raised .= ' (raised at ' . $caller->[1] . ', line ' . $caller->[2] . ')';
	}

	my $class = ref $self;
	my $pkg = __PACKAGE__;
	$class =~ s/${pkg}:://;

	return "Storage::Abstract exception: [$class] $raised";
}

## SUBCLASSES

package Storage::Abstract::X::NotFound {
$Storage::Abstract::X::NotFound::VERSION = '0.005';
use parent -norequire, 'Storage::Abstract::X';
}

package Storage::Abstract::X::Readonly {
$Storage::Abstract::X::Readonly::VERSION = '0.005';
use parent -norequire, 'Storage::Abstract::X';
}

package Storage::Abstract::X::PathError {
$Storage::Abstract::X::PathError::VERSION = '0.005';
use parent -norequire, 'Storage::Abstract::X';
}

package Storage::Abstract::X::HandleError {
$Storage::Abstract::X::HandleError::VERSION = '0.005';
use parent -norequire, 'Storage::Abstract::X';
}

package Storage::Abstract::X::StorageError {
$Storage::Abstract::X::StorageError::VERSION = '0.005';
use parent -norequire, 'Storage::Abstract::X';
}

1;

__END__

=head1 NAME

Storage::Abstract::X - Exceptions for Storage::Abstract

=head1 SYNOPSIS

	try {
		my $fh = $storage->retrieve('some/file');
	}
	catch ($e) {
		# $e is (usually) one of subclasses of Storage::Abstract::X
	}


=head1 DESCRIPTION

This is a small exception module for L<Storage::Abstract>. It can stringify
automatically and keeps a L</caller> and a L</message>.

=head2 Subclasses

=head3 NotFound

This exception is raised when a file is not found.

=head3 PathError

This exception is raised when a path passed in a method call is not well formed.

=head3 HandleError

This exception is raised when there is a problem with the handle passed to a
method call or created from data passed to a method call.

=head3 StorageError

This exception is raised when a problem occurs with the underlying file storage.

=head1 INTERFACE

=head2 Attributes

=head3 message

B<Required> - Human-readable description of the problem.

=head3 caller

A three-element array as returned by C<caller> Perl function. The module will
try to find a caller most useful to the user - if it fails, this attribute will
be C<undef>.

It cannot be used in the constructor.

=head2 Methods

=head3 new

	$ex = Storage::Abstract::X::NotFound->new(%args)

Moose-flavored constructor.

=head3 raise

	Storage::Abstract::X::NotFound->raise($message)
	$ex->raise;

Same as calling C<< die $class->new(message => $message) >>. If there is no
C<$message> then it must be called on an object instance.

=head3 as_string

	$string = $ex->as_string()

Method used to stringify the exception.

