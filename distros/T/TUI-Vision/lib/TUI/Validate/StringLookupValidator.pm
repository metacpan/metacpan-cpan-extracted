package TUI::Validate::StringLookupValidator;
# ABSTRACT: lookup validator backed by a string list

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TStringLookupValidator
  new_TStringLookupValidator
);

use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  :is
  :types
);

use TUI::MsgBox::Const qw(
  mfError
  mfOKButton
);
use TUI::MsgBox::MsgBoxText qw( messageBox );
use TUI::Validate::LookupValidator;

sub TStringLookupValidator() { __PACKAGE__ }
sub name() { 'TStringLookupValidator' };
sub new_TStringLookupValidator { __PACKAGE__->from(@_) }

extends TLookupValidator;

# declare global variables
our $errorMsg = "Input is not in list of valid strings";

# protected attributes
has strings => ( is => 'ro', default => sub { die 'required' } );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      strings => Object, { alias => 'aStrings' },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return { %$args };
}

sub from {    # $obj ($aStrings)
  state $sig = signature(
    method => 1,
    pos    => [Object],
  );
  my ( $class, $aStrings ) = $sig->( @_ );
  return $class->new( strings => $aStrings );
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Bool $in_global_destruction );
  $self->newStringList( undef ) unless $in_global_destruction;
  return;
}

sub error {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  messageBox( mfError | mfOKButton, $errorMsg );
  return;
}

my $stringMatch = sub {    #  $bool ($a1, $a2)
  my ( $a1, $a2 ) = @_;
  assert ( @_ == 2 );
  assert ( is_Str $a1 );
  assert ( is_Str $a2 );
  return $a1 eq $a2;
};

sub lookup {    # $bool ($s)
  state $sig = signature(
    method => Object,
    pos    => [Str],
  );
  my ( $self, $s ) = $sig->( @_ );
  return $self->{strings}
      && defined $self->{strings}->firstThat( $stringMatch, $s );
}

sub newStringList {    # void ($aStrings|undef)
  state $sig = signature(
    method => Object,
    pos    => [Maybe[Object]],
  );
  my ( $self, $aStrings ) = $sig->( @_ );
  $self->destroy( $self->{strings} )
    if ( $self->{strings} );
  $self->{strings} = $aStrings;
  return;
}

1

__END__

=pod

=head1 NAME

TUI::Validate::StringLookupValidator - lookup validator backed by a string list

=head1 HIERARCHY

  TObject
    TValidator
      TLookupValidator
        TStringLookupValidator

=head1 SYNOPSIS

  use TUI::Validate::StringLookupValidator;

  my $v = new_TStringLookupValidator( $stringCollection );

  if ( $v->isValid($input) ) {
    # string was found in the configured collection
  }

  # replace lookup data at runtime
  $v->newStringList( $other_collection );

=head1 DESCRIPTION

C<TStringLookupValidator> validates input by checking whether the text exists
in a configured collection object. The actual lookup happens in C<lookup>,
which uses the collection's C<firstThat> method with an exact string comparator
(C<eq>). Validation therefore is case-sensitive unless the supplied collection
contains normalized values.

This class is a concrete subclass of 
L<TLookupValidator|TUI::Validate::LookupValidator> and is useful for fields 
that must match one of a predefined set of tokens.

=head2 Commonly Used Features

Typical usage is to build a collection with allowed values and pass it to
L</new> (or L</new_TStringLookupValidator>). The field then accepts only 
strings present in that collection. You can replace the active collection later 
via L</newStringList>; the previous list is disposed before assignment.

=head1 VARIABLES

=head2 $errorMsg

  our $errorMsg = "Input is not in list of valid strings";

Package-global message shown by C<error()> when validation fails.

=head1 ATTRIBUTES

=head2 strings

  my $list = $v->strings;

Read-only reference to the currently configured lookup collection
(L<TStringCollection|TUI::Objects::StringCollection>).
The object is expected to provide C<firstThat> with the callback signature used
internally by C<lookup>.

If C<strings> is C<undef>, C<lookup> always returns false.

=head1 CONSTRUCTOR

=head2 new

  my $v = TStringLookupValidator->new( strings => $strings );

Creates a validator bound to the given string collection object. 

=over

=item strings

The C<strings> argument is mandatory collection 
(L<TStringCollection|TUI::Objects::StringCollection>) of strings (I<Str>).

=back

=head2 new_TStringLookupValidator

  my $v = new_TStringLookupValidator( $aStrings );

Convenience factory with a positional collection argument. Exported by default.

=head1 METHODS

=head2 error

  $v->error();

Displays a modal error message using C<$errorMsg>.

=head2 lookup

  my $ok = $v->lookup( $string );

Returns true if C<$string> matches an entry in C<strings> by exact equality
(C<eq>).  Returns false when no collection is configured or when no matching
entry is found.

=head2 newStringList

  $v->newStringList( $strings|undef );

Replaces the active lookup collection. If an existing collection is present,
it is disposed via C<destroy> before the new one is stored. Passing C<undef>
removes the current list.

=head1 SEE ALSO

L<TLookupValidator|TUI::Validate::LookupValidator>,
L<TValidator|TUI::Validate::Validator>,
L<TStringCollection|TUI::Objects::StringCollection>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
