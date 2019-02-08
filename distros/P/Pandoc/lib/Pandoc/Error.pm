package Pandoc::Error;
use 5.014;
use warnings;

our $VERSION = '0.9.0';

use overload '""' => 'message', fallback => 1;
use Carp;

$Carp::CarpInternal{ (__PACKAGE__) }++;   # don't include package in stack trace

sub new {
    my ( $class, %fields ) = @_ % 2 ? @_ : ( shift, message => @_ );
    $fields{message} = Carp::shortmess( $fields{message} // $class );
    bless \%fields, $class;
}

sub throw {
    die ref $_[0] ? $_[0] : shift->new(@_);
}

sub message {
    $_[0]->{message};
}

1;

=head1 NAME

Pandoc::Error - Pandoc document processing error

=head1 SYNOPSIS

  use Try::Tiny;

  try {
      ...
  } catch {
      if ( blessed $_ && $_->isa('Pandoc::Error') ) {
          ...
      }
  };

=head1 METHODS

=head2 throw( [ %fields ] )

Throw an existing error or create and throw a new error. Setting field
C<message> is recommended. The message is enriched with error location.  A
stack trace can be added with L<$Carp::Verbose|Carp/$Carp::Verbose> or
L<Carp::Always>.

=head2 message

The error message. Also returned on stringification.

=head1 SEE ALSO

This class does not inherit from L<Throwable>, L<Exception::Class> or
L<Class::Exception> but may do so in a future version.

=cut
