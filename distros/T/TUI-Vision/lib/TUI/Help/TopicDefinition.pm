package TUI::Help::TopicDefinition;
# ABSTRACT: linked help-topic definition

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TTopicDefinition
  new_TTopicDefinition
);

use TUI::toolkit;
use TUI::toolkit::Types qw(
  is_Object
  :types
);

use TUI::Objects::Object;

sub TTopicDefinition() { __PACKAGE__ }
sub new_TTopicDefinition { __PACKAGE__->from(@_) }

extends TObject;

has topic => ( is => 'rw' );
has value => ( is => 'rw' );
has next  => ( is => 'rw', default => undef );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      topic => Str,
      value => PositiveOrZeroInt,
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return { %$args };
}

sub from {    # $definition ($aTopic, $aValue)
  state $sig = signature(
    method => 1,
    pos    => [Str, PositiveOrZeroInt],
  );
  my ( $class, $aTopic, $aValue ) = $sig->( @_ );
  return $class->new( topic => $aTopic, value => $aValue );
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert( is_Object $self );
  undef $self->{topic};
  undef $self->{next};
  return;
}

1

__END__

=pod

=head1 NAME

TUI::Help::TopicDefinition - linked help-topic definition

=head1 HIERARCHY

  TObject
    TTopicDefinition

=head1 SYNOPSIS

  use TUI::Help;

  my $first = new_TTopicDefinition( 'Introduction', 100 );
  my $second = new_TTopicDefinition( 'Details', 101 );
  $first->next( $second );

=head1 DESCRIPTION

C<TTopicDefinition> associates a topic name with its numeric help-context
value. Definitions can be linked through C<next> to form a list, as in the
original Borland help compiler.

Construction stores the supplied name and value and initializes C<next>
to C<undef>. Perl scalar storage replaces the original string allocation
and copying.

No streaming interface or C<Storable> integration is provided.

=head1 ATTRIBUTES

All three attributes are read/write. The type names below describe expected
values using
L<TUI::toolkit::Types>; attribute setters do not enforce these types.

=over

=item topic

C<Str>. Topic name, supplied to the constructor.

=item value

C<PositiveOrZeroInt>. Numeric topic value, supplied to the constructor.

=item next

C<Maybe[Object]>. Reference to the next C<TTopicDefinition>, or C<undef>
at the end of the chain. Initially C<undef>.

=back

=head1 CONSTRUCTOR

=head2 new

  my $definition = TTopicDefinition->new(
    topic => 'Introduction',
    value => 100,
  );

Requires C<topic> as C<Str> and C<value> as C<PositiveOrZeroInt>.
Creates a definition with no successor.

=head2 new_TTopicDefinition

  my $definition = new_TTopicDefinition( 'Introduction', 100 );

Positional factory taking the topic name and numeric value.

=head1 SEE ALSO

L<TUI::Help>, L<TUI::Help::HelpBase>, L<TObject|TUI::Objects::Object>,
L<TUI::toolkit::Types>

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
