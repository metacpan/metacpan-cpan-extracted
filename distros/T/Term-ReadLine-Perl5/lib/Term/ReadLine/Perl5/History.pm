#  Copyright (C) 2014 Rocky Bernstein <rocky@cpan.org>
package Term::ReadLine::Perl5::History;
eval "use rlib '.' ";  # rlib is now optional
use Term::ReadLine::Perl5::OO::History;
=pod

=head1 NAME

Term::ReadLine::Perl5::History

=head1 DESCRIPTION

Variables and functions supporting L<Term::ReadLine::Perl5>'s command
history. This pretends to be OO code even though it isn't. It makes
use of global package variables and wraps that up as an object to pass
to the corresponding OO routine.

The underlying OO routines are in
L<Term::ReadLine::Perl5::OO::History>.

=cut

use warnings; use strict;

use vars qw(@EXPORT @ISA @rl_History $rl_HistoryIndex $rl_history_length
            $rl_MaxHistorySize $rl_max_input_history $history_base
            $history_stifled);

@ISA = qw(Exporter);
@EXPORT  = qw(@rl_History $rl_HistoryIndex $rl_history_length
              &add_line_to_history
              $rl_MaxHistorySize $rl_max_input_history $history_stifled);

# FIXME: eventually we will remove these variables when we are fully OO.
@rl_History = ();
$rl_MaxHistorySize = 100;
$rl_history_length = 0;
$rl_max_input_history = 0;
$rl_history_length = $rl_max_input_history = 0;

$history_stifled = 0;
$history_base    = 0;

=head1 SUBROUTINES

=head2 add_line_to_history

B<add_line_to_history>(I<$line>, I<$minlength>)

Insert I<$line> into history list if I<$line> is:

=over

=item *

bigger than the minimal length I<$minlength>

=item *

not same as last entry

=back

=cut

# Fake up a needed object using global state
sub _fake_self() {
    {
	rl_History           => \@rl_History,
	rl_MaxHistorySize    => $rl_MaxHistorySize,
	rl_HistoryIndex      => $rl_HistoryIndex,
	rl_history_length    => $rl_history_length,
	rl_max_input_history => $rl_max_input_history,
	history_stifled      => $history_stifled,
    };
}


# FIXME: DRY this adding a common routine to fake $self.
sub add_line_to_history
{
    my ($line, $minlength) = @_;

    my $self = _fake_self();
    Term::ReadLine::Perl5::OO::History::add_line_to_history(
	$self, $line, $minlength);
}


sub add_history
{
    shift;
    my $self = _fake_self();
    Term::ReadLine::Perl5::OO::History::add_history($self, @_);
    $rl_MaxHistorySize = $self->{rl_MaxHistorySize};
    $rl_HistoryIndex   = $self->{rl_HistoryIndex};
    $rl_history_length = $self->{rl_history_length};
}

sub clear_history()
{
    my $self = _fake_self();
    Term::ReadLine::Perl5::OO::History::clear_history($self);
    @rl_History = @{$self->{rl_History}};
    $rl_MaxHistorySize = $self->{rl_MaxHistorySize};
    $rl_HistoryIndex   = $self->{rl_HistoryIndex};
    $rl_history_length = $self->{rl_history_length};
}


sub GetHistory()
{
    Term::ReadLine::Perl5::OO::History::GetHistory(_fake_self());
}

sub history_is_stifled($) {
  shift;
  my $self = _fake_self();
  return Term::ReadLine::Perl5::OO::History::history_is_stifled($self);
}

sub read_history($$) {
    my ($unused, $filename) = @_;
    my $self = _fake_self();
    my $ret = Term::ReadLine::Perl5::OO::History::read_history($self,
							       $filename);
    @rl_History = @{$self->{rl_History}};
    $rl_MaxHistorySize = $self->{rl_MaxHistorySize};
    $rl_HistoryIndex   = $self->{rl_HistoryIndex};
    $rl_history_length = $self->{rl_history_length};
    return $ret;
}

sub ReadHistory($$) {
    my ($unused, $filename) = @_;
    ! read_history($unused, $filename);
}

sub remove_history($)
{
    shift;
    my ($which) = @_;
    my $self = _fake_self();
    Term::ReadLine::Perl5::OO::History::remove_history($self, $which);
    @rl_History = @{$self->{rl_History}};
    $rl_MaxHistorySize = $self->{rl_MaxHistorySize};
    $rl_HistoryIndex   = $self->{rl_HistoryIndex};
    $rl_history_length = $self->{rl_history_length};
}

sub replace_history_entry {
  shift;
  my ($which, $data) = @_;
  my $self = _fake_self();
  my $replaced =
      Term::ReadLine::Perl5::OO::History::replace_history_entry($self,
								$which,
								$data);
  @rl_History = @{$self->{rl_History}};
  $rl_MaxHistorySize = $self->{rl_MaxHistorySize};
  $rl_HistoryIndex   = $self->{rl_HistoryIndex};
  $rl_history_length = $self->{rl_history_length};
  return $replaced;
}

sub SetHistory
{
    shift;
    # Fake up a needed object using global state
    my $self = _fake_self();
    Term::ReadLine::Perl5::OO::History::SetHistory($self, @_);
    @rl_History = @{$self->{rl_History}};
    $rl_MaxHistorySize = $self->{rl_MaxHistorySize};
    $rl_HistoryIndex   = $self->{rl_HistoryIndex};
    $rl_history_length = $self->{rl_history_length};
}

sub unstifle_history($)
{
    shift;
    my $self = _fake_self();
    Term::ReadLine::Perl5::OO::History::unstifle_history($self);
    $history_stifled = $self->{history_stifled};
}

sub write_history($$) {
    my ($unused, $filename) = @_;
    my $self = _fake_self();
    Term::ReadLine::Perl5::OO::History::write_history($self,
						      $filename);
}

sub WriteHistory($$) {
    my ($unused, $filename) = @_;
    my $self = _fake_self();
    Term::ReadLine::Perl5::OO::History::WriteHistory($self,
						     $filename);
}


1;
