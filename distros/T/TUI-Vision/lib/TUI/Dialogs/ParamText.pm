package TUI::Dialogs::ParamText;
# ABSTRACT: displays formatted dynamic text inside a dialog

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT = qw(
  TParamText
  new_TParamText
);

use Carp ();
use TUI::toolkit;
use TUI::toolkit::Types qw( :types );

use TUI::Dialogs::StaticText;
use TUI::toolkit;

sub TParamText()   { __PACKAGE__ }
sub name()         { 'TParamText' }
sub new_TParamText { __PACKAGE__->from( @_ ) }

extends TStaticText;

# protected attributes
has str => ( is => 'ro', default => '' );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named => [
      bounds => Object,
    ],
    caller_level => +1,
  );
  my ( $class, $args1 ) = $sig->( @_ );
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  my $args2 = $class->SUPER::BUILDARGS(
    bounds => $args1->{bounds},
    text   => '',
  );
  return { %$args1, %$args2 };
}

sub from {    # $obj ($bounds)
  state $sig = signature(
    method => 1,
    pos    => [Object],
  );
  my ( $class, $bounds ) = $sig->( @_ );
  return $class->new( bounds => $bounds );
}

sub getText {    # void (\$s)
  state $sig = signature(
    method => Object,
    pos    => [ScalarRef],
  );
  my ( $self, $s ) = $sig->( @_ );
  $$s = defined $self->{str} ? $self->{str} : '';
  return;
}

sub getTextLen {    # $len ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return defined $self->{str} ? length $self->{str} : 0;
}

sub setText {    # void ($fmt, @args)
  state $sig = signature(
    method => Object,
    pos    => [
      Str,
      ArrayRef, { slurpy => 1 }
    ],
  );
  my ( $self, $fmt, $args ) = $sig->( @_ );
  $self->{str} = sprintf( $fmt, @$args );
  $self->drawView();
  return;
}

1

__END__

=pod

=head1 NAME

TUI::Dialogs::ParamText - formatted dynamic text control for dialogs

=head1 HIERARCHY

  TObject
    TView
      TStaticText
        TLabel
          TParamText

=head1 SYNOPSIS

  use TUI::Dialogs;

  my $bounds = TRect->new(ax => 1, ay => 1, bx => 30, by => 2);
  my $paramText = TParamText->new( bounds => $bounds );

  $paramText->setText('Value: %d, Name: %s', 42, 'John');

  my $text = '';
  $paramText->getText(\$text);

  print "Current text: $text\n";

=head1 DESCRIPTION

C<TParamText> is a dynamic text control derived from C<TStaticText>. It allows
formatted text to be displayed inside dialogs using printf-style format
strings.

The control maintains an internal string buffer and recomputes its displayed
text whenever C<setText> is called. This mirrors the original Turbo Vision
behavior, where formatted strings are generated using the C<FormatStr>
procedure.

C<TParamText> is typically used for status messages, confirmations, or prompts
that include variable data.

=head2 Commonly Used Features

In practice you will call C<new_TParamText> to create the control, call
C<setText> once to supply the format string together with any arguments, and
then insert the control into the dialog. Unlike the Pascal original, which
required manually assigning a pointer to a parameter record, the Perl
implementation accepts the format string and its arguments directly in
C<setText>, so no separate data structure needs to be maintained. When the
dialog data changes you simply call C<setText> again with the new values;
C<getText> is rarely needed outside of tests.

=head1 CONSTRUCTOR

=head2 new

  my $paramText = TParamText->new(
    bounds => $bounds
  );

Creates a new parameterized text control.

=over

=item bounds

Bounding rectangle of the control (I<TRect>).

=back

=head2 new_TParamText

  my $paramText = new_TParamText($bounds);

Factory-style constructor using positional arguments.

This constructor is provided for compatibility with traditional Turbo Vision
construction patterns.

=head1 ATTRIBUTES

The following attributes are managed internally and exposed as read-only
accessors.

=over

=item str

Internal formatted text buffer (I<Str>).

=back

=head1 METHODS

=head2 getText

  $paramText->getText(\$string);

Retrieves the current formatted text and writes it into the supplied scalar.

=head2 getTextLen

  my $len = $paramText->getTextLen();

Returns the length of the formatted text currently stored in the buffer.

=head2 setText

  $paramText->setText($format, @args);

Formats and stores text using a printf-style format string and triggers a
redraw of the view.

=head1 SEE ALSO

L<TUI::Dialogs::StaticText>,
L<TUI::Dialogs::Label>,
L<TUI::Dialogs::Dialog>

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
