=head1 NAME

OpenFrame::WebApp::Error - base class for WebApp Errors.

=head1 SYNOPSIS

  # meant to be sub-classed:
  use OpenFrame::WebApp::Error::SomeClass;

  # should export some error flags to your namespace

  use Error qw( :try );
  try {
      throw OpenFrame::WebApp::Error::SomeClass( flag => eSomeError );
  } catch OpenFrame::WebApp::Error::SomeClass with {
      my $e = shift;
      do { ... } if ($e->flag == eSomeError);
  }

=cut


package OpenFrame::WebApp::Error;

use utf8;
use strict;
use warnings::register;

our $VERSION = (split(/ /, ' $Revision: 1.3 $ '))[2];

use base qw( Error );

sub new {
    my $class = shift;
    local $Error::Depth = $Error::Depth + 1;
    $class->SUPER::new(map { /^\-?flag$/ ? '-text' : $_; } @_);
}

# store flag in '-text' as it's hard-coded into Error.pm
sub flag {
    my $self = shift;
    if (@_) {
	$self->{-text} = shift;
	return $self;
    } else {
	return $self->{-text};
    }
}


1;


__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This is the base class for Error exceptions in OpenFrame-WebApp.  It introduces
an error flag to the C<Error> module in an attempt to make localization easier.

Descriptive error flags should be exported from each subclass:

  use base qw( Exporter OpenFrame::WebApp::Error );
  our @EXPORT = qw( eSomethingBad );
  use constant eSomethingBad => 'something.bad';

The value of these constants can then be used as localization keys with the
likes of C<Locale::Gettext> or C<Locale::Maketext>.

=head1 CONSTRUCTOR

C<new> recognizes '-flag' as a synonym for '-text'.  The '-' is optional:

  throw Some::Error( flag => eSomethingBad );

=head1 METHODS

=over 4

=item flag

set/get the error flag.

=back

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<Error>, L<OpenFrame::WebApp>

=cut

