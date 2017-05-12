package Net::RNDC::Exception;
{
  $Net::RNDC::Exception::VERSION = '0.003';
}

use strict;
use warnings;

sub new {
	my ($class, $error, $level) = @_;

	$level ||= 1;

	my (undef, $file, $line) = caller($level);

	return bless {
		error => $error,
		file  => $file,
		line  => $line,
	}, $class;
}

sub error {
	my ($self) = @_;

	return "'$self->{error}' at '$self->{file}' line '$self->{line}'";
}

1;
__END__

=head1 NAME

Net::RNDC::Exception - Internal exception class

=head1 VERSION

version 0.003

=head1 SYNOPSIS

For use within Net::RNDC* only.

To throw an error:

  die Net::RNDC::Exception->new("some error");

Typically used with L<Try::Tiny>:

  try {
    something_that_dies_like_above();
  } catch {
    my $err = $_;
    if (UNIVERSAL::isa($err, 'Net::RNDC::Exception')) {
      warn "Error: " . $err->error . "\n";
    }
  };

=head1 DESCRIPTION

This package is used to pass exceptions around internally so that a simple error 
interface can be exposed by the API and any actual exceptions are real problems 
with usage/bugs.

=head2 Constructor

=head3 new

  Net::RNDC::Exception->new($error);

Constructs a new exception with the given B<$error> and attached file/line 
number information to it.

Required Arguments:

=over 4

=item *

B<$error> - A string describing the error.

=back

=head2 Methods

=head3 Error

  my $error = $exception->error;

Returns a string containing the error from object construction, along with a 
file and line identifier.

=head1 AUTHOR

Matthew Horsfall (alh) <WolfSage@gmail.com>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
