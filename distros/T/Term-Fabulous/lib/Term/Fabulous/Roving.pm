package Term::Fabulous::Roving;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Exporter 'import';
our @EXPORT_OK = qw(roving_target);

use List::Util qw(first max min);

# Key name => how it moves: a number of entries (page: a page of them),
# or to the first or the last entry.
my %MOVE_BY_KEY = (
	Left            => -1,
	Up              => -1,
	Right           =>  1,
	Down            =>  1,
	'Ctrl+PageUp'   => -1,
	'Ctrl+PageDown' =>  1,
	PageUp          => 'page_back',
	PageDown        => 'page_forward',
	Home            => 'first',
	End             => 'last',
);

# The keys each kind of widget answers.
my %KEYS_OF = (
	arrows   => [qw(Left Up Right Down Home End)],
	vertical => [qw(Up Down Home End)],
	list     => [qw(Up Down PageUp PageDown Home End)],
	pages    => [ 'Ctrl+PageUp', 'Ctrl+PageDown' ],
);

my %IS_POLICY = map { $_ => 1 } qw(wrap clamp);

# The entry a key moves to among the enabled ones, or undef when the key
# is none of the kind's or no entry is enabled.
sub roving_target ( $enabled, $current, $key, %options ) {
	my @unknown = grep { !/\A(?:keys|policy|page)\z/ } sort keys %options;
	die "Term::Fabulous::Roving: roving_target does not take @unknown (known: keys, page, policy)" if @unknown;
	my $keys   = $KEYS_OF{ $options{keys} // 'arrows' } // die "Term::Fabulous::Roving: unknown keys '$options{keys}' (known: " . join( ', ', sort keys %KEYS_OF ) . ")";
	my $policy = $options{policy}                       // 'wrap';
	die "Term::Fabulous::Roving: policy must be wrap or clamp, got '$policy'" unless $IS_POLICY{$policy};
	die "Term::Fabulous::Roving: the enabled entries must be an array reference" unless ref $enabled eq 'ARRAY';

	return undef unless defined $key && @$enabled && grep { $_ eq $key } @$keys;
	my $move = $MOVE_BY_KEY{$key};
	return $enabled->[0] if $move eq 'first';
	return $enabled->[-1] if $move eq 'last';

	my $by = $move eq 'page_back' ? -( $options{page} // 1 ) : $move eq 'page_forward' ? $options{page} // 1 : $move;
	my $at = defined $current ? first { $enabled->[$_] == $current } 0 .. $#$enabled : undef;
	return $by > 0 ? $enabled->[0] : $enabled->[-1] unless defined $at;
	return $enabled->[ ( $at + $by ) % @$enabled ] if $policy eq 'wrap';
	return $enabled->[ max( 0, min( $#$enabled, $at + $by ) ) ];
}

1;

__END__

=head1 NAME

Term::Fabulous::Roving - Which entry an arrow key moves to

=head1 SYNOPSIS

	use Term::Fabulous::Roving qw(roving_target);

	# Segments 0 .. 4, segment 2 disabled, segment 3 selected:
	my $next = roving_target( [ 0, 1, 3, 4 ], 3, 'Right' );                       # 4
	my $wrap = roving_target( [ 0, 1, 3, 4 ], 4, 'Right' );                       # 0: around
	my $stop = roving_target( [ 0, 1, 3, 4 ], 4, 'Down', policy => 'clamp', keys => 'vertical' );    # 4
	my $none = roving_target( [ 0, 1, 3, 4 ], 3, 'Tab' );                         # undef

=head1 DESCRIPTION

Widgets that hold a row or a column of entries, of which some may be
disabled, move a selection, a cursor or the focus between them with the
arrow keys: segments, tabs, radio buttons, accordion headers, the
options of a dropdown. This module has the one rule for all of them, as
a pure function. Nothing is exported by default.

=head1 FUNCTIONS

=head2 roving_target

	my $index = roving_target( \@enabled, $current, $key_name, %options );

C<\@enabled> holds the indexes of the enabled entries, in order;
C<$current> is the index of the current entry, or C<undef>; C<$key_name>
is a key name such as L<Term::Fabulous::Event::KeyPress/main_key_name>
returns. Returns the index of the entry the key moves to, or C<undef>
when the key is not one of the C<keys> or no entry is enabled.

A key that steps moves by one enabled entry (disabled entries are
skipped), C<PageUp> and C<PageDown> by C<page> of them. From a current
entry that is not enabled (or none), a step forward goes to the first
enabled entry and a step back to the last. C<Home> and C<End> go to the
first and the last enabled entry. Options:

=over

=item C<keys>

Which keys move: C<arrows> (the default: C<Left>, C<Up>, C<Right>,
C<Down>, C<Home>, C<End>), C<vertical> (C<Up>, C<Down>, C<Home>,
C<End>), C<list> (C<vertical> and C<PageUp>, C<PageDown>) or C<pages>
(C<Ctrl+PageUp>, C<Ctrl+PageDown>, the keys that turn the pages of a
L<Term::Fabulous::Widget::Tabs>).

=item C<policy>

C<wrap> (the default): a step past the last entry goes on at the first
and the other way round. C<clamp>: it stays at the end.

=item C<page>

How many entries C<PageUp> and C<PageDown> move. Default: 1.

=back

Unknown options, kinds of keys and policies die.

=head1 SEE ALSO

L<Term::Fabulous::OptionList>, L<Term::Fabulous::Widget::SegmentedControl>,
L<Term::Fabulous::Widget::Dropdown>.

=cut
