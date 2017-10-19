#  Copyright (C) 2014 Rocky Bernstein <rocky@cpan.org>
package Term::ReadLine::Perl5::OO::History;
=pod

=head1 NAME

Term::ReadLine::Perl5::OO:History

=head1 DESCRIPTION

Variables and functions supporting L<Term::ReadLine::Perl5>'s and
L<Term::ReadLine::Perl5::OO>'s command history.

=cut

use warnings; use strict;

=head1 SUBROUTINES

=head2 add_line_to_history

#B<add_line_to_history>(I<$line>, I<$minlength>)

Insert I<$line> into history list if I<$line> is:

=over

=item *

bigger than the minimal length I<$minlength>

=item *

not same as last entry

=back

=cut

use File::HomeDir; use File::Spec;
my $HOME = File::HomeDir->my_home;

sub add_line_to_history
{
    my ($self, $line, $minlength) = @_;
    my $rl_History = $self->{rl_History};
    my $rl_MaxHistorySize = $self->{rl_MaxHistorySize};
    if (length($line) >= $minlength
        && (!@$rl_History || $rl_History->[$#$rl_History] ne $line)
       ) {
        ## if the history list is full, shift out an old one first....
        while (@$rl_History >= $self->{rl_MaxHistorySize}) {
            shift(@$rl_History);
            $self->{rl_HistoryIndex}--;
        }

        push(@$rl_History, $line); ## tack new one on the end
    }
}

=head2 add_history

#B<add_history>(I<$line1>, ...)

Place lines in array I<@_> at the end of the history list unless the
history is stifled, or there are already too many items.

=cut

sub add_history {
    my $self = shift;
    if ($self->{history_stifled} &&
	($self->{rl_history_length} ==
	 $self->{rl_max_input_history})) {
	# If the history is stifled, and history_length is zero,
	# and it equals max_input_history, we don't save items.
	return if $self->{rl_max_input_history} == 0;
	shift @{$self->{rl_History}};
    }
    push @{$self->{rl_History}}, @_;
    $self->{rl_HistoryIndex}   += scalar @_;
    $self->{rl_history_length} = scalar @{$self->{rl_History}};
}


=head2 read_history

#B<read_history>(I<$filename>)

Add the contents of I<$filename> to the history list, a line at a time. If
filename is undef, then read from `~/.history'. Returns 0 if
successful, or I<$!> if not.

=cut

sub read_history($;$) {
    my ($self, $filename) = @_;
    $filename = File::Spec->catfile($HOME, '.history') unless $filename;
    my @history;
    open(my $fh, '<:encoding(utf-8)', $filename ) or return $!;
    while (my $hist = <$fh>) {
	chomp($hist);
	push @history, $hist;
    };
    # Use non OO form since this can be called in a non-OO way.
    SetHistory($self, @history);
    close $fh;
    return 0;
}

=head2 remove_history

#B<remove_history>(I<unused>, I<$which>)

Remove history element C<$which> from the history. The removed
element is returned.

=cut

sub remove_history($$) {
    my ($self, $which) = @_;
    return undef if
	$which < 0 || $which >= $self->{rl_history_length};
    my $removed = splice @{$self->{rl_History}}, $which, 1;
    $self->{rl_history_length}--;
    $self->{rl_HistoryIndex} =
	$self->{rl_history_length} if
	$self->{rl_history_length} <
	$self->{rl_HistoryIndex};
    return $removed;
}

=head2 GetHistory

B<GetHistory>

returns the history of input as a list.

=cut

sub GetHistory {
    my $self = shift;
    @{$self->{rl_History}};
}

=head2 SetHistory

#B<SetHistory>(I<$line1> [, I<$line2>, ...])

Sets the history of input, from where it can be used.

=cut

sub SetHistory {
    my $self = shift;
    $self->{rl_History} = \@_;
    $self->{rl_HistoryIndex} =
	$self->{rl_history_length} = $self->{rl_max_input_history} = scalar(@_);
}

=head2 history_is_stifled

C<history_is_stifled>

Returns I<true> if saved history has a limited (stifled) or I<false>
if there is no limit (unstifled).

=cut

sub history_is_stifled {
  my ($self) = shift;
  $self->{history_stifled} ? 1 : 0;
}

=head2 unstifle_history

C<unstifle_history>

Unstifle or remove limit the history list.

Theprevious maximum number of history entries is returned.  The value
is positive if the history was stifled and negative if it wasn't.

=cut

sub unstifle_history($) {
    my $self = shift;
    if ($self->{history_stifled}) {
	$self->{history_stifled }= 0;
	return (scalar @{$self->{rl_History}});
    } else {
	return - scalar @{$self->{rl_History}};
    }
}

=head2 replace_history_entry

#B<replace_history_entry(I<$which>, I<$data>)>

Make the history entry at I<$which> have I<$data>.  This returns the old
entry. In the case of an invalid I<$which>, I<undef> is returned.

=cut

sub replace_history_entry {
  my $self = shift;
  my ($which, $data) = @_;
  return undef if $which < 0 || $which >= $self->{rl_history_length};
  my $replaced = splice @{$self->{rl_History}}, $which, 1, $data;
  return $replaced;
}

=head2 clear_history

#B<clear_history>()

Clear or reset readline history.

=cut

sub clear_history($) {
  my $self = shift;
  $self->{rl_History} = [];
  $self->{rl_HistoryIndex} =
      $self->{rl_history_length} = 0;
}

sub history_list($)
{
    my $self = shift;
    my @rl_History =  @{$self->{rl_History}};
    @rl_History[1..$#rl_History]
}

=head2 write_history
#B<write_history>(I<$filename>)

Write the current history to filename, overwriting filename if
necessary. If filename is NULL, then write the history list to
`~/.history'. Returns 0 on success, or errno on a read or write error.

I<read_history()> and I<write_history()> follow GNU Readline's C
convention of returning 0 for success and 1 for failure.

=cut

sub write_history($$) {
    my ($self, $filename) = @_;
    open(my $fh, '>:encoding(utf-8)', $filename ) or return $!;
    for my $hist (@{$self->{rl_History}}) {
        next unless $hist =~ /\S/;
        print $fh $hist . "\n";
    }
    close $fh;
    return 0;
}

=head2 ReadHistory

#B<ReadHistory>([I<$filename> [,I<$from> [,I<$to>]]])

	$i = ReadHistory('~/.history')

Adds the contents of I<$filename> to the history list, a line at a
time.  If $<filename> is false, then read from F<~/.history>.  Start
reading at line I<$from> and end at I<$to>.  If I<$from> is omitted or
zero, start at the beginning.  If I<$to> is omitted or less than
I<$from>, then read until the end of the file.  Returns true if
successful, or false if not.

I<Note:> the return code is the negation of
L<read_history>. Otherwise, it's the same.

=cut

sub ReadHistory {
    my ($self, $filename) = @_;
    # Use non-OO form since this can be called in a non-OO way
    ! read_history($self, $filename);
}

=head2 WriteHistory

#B<WriteHistory>([I<$filename>])

	$i = WriteHistory('~/.history')

Writes the current history to I<$filename>, overwriting I<$filename>
if necessary.  If I<$filename> is false, then write the history list
to F<~/.history>.  Returns true if successful, or false if
not. I<Note:> the return code is the negation of
L<write_history>. Otherwise, it's the same.

=cut

sub WriteHistory {
    # Use non-OO form since this can be called in a non-OO way
    my ($self, $filename) = @_;
    ! write_history($self, $filename);
}
=head1 AUTHOR

Rocky Bernstein

=head1 SEE ALSO

L<Term::ReadLine::Perl5>

=cut

1;
