package Term::Output::List::ANSI;
use 5.020;
use Moo 2;
use Term::Cap;
use Scalar::Util 'weaken';
use experimental 'signatures';

our $VERSION = '0.06';

=head1 NAME

Term::Output::List::ANSI - output an updateable list of ongoing jobs to an ANSI terminal

=head1 SYNOPSIS

    my $printer = Term::Output::List->new(
        hook_warnings => 1,
    );
    my @ongoing_tasks = ('file1: frobnicating', 'file2: bamboozling', 'file3: frobnicating');
    $printer->output_list(@ongoing_tasks);

    $printer->output_permanent("Frobnicated gizmos"); # appears above the list

=cut

=head1 MEMBERS

=head2 C<< fh >>

Filehandle used for output. Default is C<< STDOUT >>.

=cut

has 'terminfo' => (
    is => 'lazy',
    default => sub { Term::Cap->Tgetent({ OSPEED => 112000 })},
);

has 'term_scroll_up' => (
    is => 'lazy',
    default => sub { $_[0]->terminfo->Tputs('UP') },
);

has 'term_clear_eol' => (
    is => 'lazy',
    default => sub { $_[0]->terminfo->Tputs('ce') },
);

=head2 C<< interactive >>

Whether the script is run interactively and should output intermittent
updateable information

=head2 C<< hook_warnings >>

Install a hook for sending warnings to C<< ->output_permanent >>. This
prevents ugly tearing/overwriting when your code outputs warnings.

=cut

=head1 METHODS

=head2 C<< Term::Output::List::ANSI->new() >>

  my $output = Term::Output::List::ANSI->new(
      hook_warnings => 1,
  )

=over 4

=item C<< hook_warnings >>

Install a hook for sending warnings to C<< ->output_permanent >>. This
prevents ugly tearing/overwriting when your code outputs warnings.

=back

=cut

=head2 C<< width >>

Width of the terminal. This is initialized at first use. You may (or may not)
want to set up a C<< $SIG{WINCH} >> handler to set the terminal width when
the terminal size changes.

=cut

has 'width' => (
    is => 'lazy',
    default => sub { `tput cols` },
);

=head1 METHODS

=head2 C<< Term::Output::List->new() >>

=cut

=head2 C<< ->scroll_up >>

Helper method to place the cursor at the top of the updateable list.

=cut

has 'ellipsis' => (
    is => 'lazy',
    default => sub { "\N{HORIZONTAL ELLIPSIS}" },
);

with 'Term::Output::List::Role';

sub scroll_up( $self, $count=$self->_last_lines ) {
    if( !$count) {
    } else {
        # Overwrite the number of lines we printed last time
        print { $self->fh } "\r" . sprintf $self->term_scroll_up(), ${count};
        #sleep 1;
    };
}

=head2 C<< ->output_permanent >>

  $o->output_permanent("Frobnicated 3 items for job 2");
  $o->output_list("Frobnicating 9 items for job 1",
                  "Frobnicating 2 items for job 3",
  );

Outputs items that should go on the permanent record. It is expected to
output the (remaining) list of ongoing jobs after that.

=cut

sub output_permanent( $self, @items ) {
    my $total = $self->_last_lines // 0;
    if( !$self->interactive ) {
        print { $self->fh } join("\n", @items) . "\n";

    } else {
        $self->scroll_up($total);
        my $w = $self->width;
        my $clear_eol = $self->term_clear_eol;

        if( @items ) {

            print { $self->fh }
                  join("$clear_eol\n",
                    map { $self->_trim( $_, $w ) }
                    map { s/\s*\z//r }
                    @items
                  )."$clear_eol\n";
        };

        # If we have fewer items than before, clear the lines of the vanished items
        my $blank = $total - @items;
        if( $blank > 0 ) {
            print { $self->fh } "$clear_eol\n"x ($blank);
            $self->scroll_up( $blank );
        }
        $self->fresh_output();
    }
}

=head2 C<< ->output_list @items >>

  $o->output_list("Frobnicating 9 items for job 1",
                  "Frobnicating 2 items for job 3",
  );

Outputs items that can be updated later, as long as no intervening output
(like from C<print>, C<say> or C<warn>) has happened. If you want to output
lines that should not be overwritten later, see C<</->output_permanent>>

=head2 C<< ->fresh_output >>

  $o->fresh_output();

Helper subroutine to make all items from the last output list remain as is.

For compatibility between output to a terminal and output without a terminal,
you should use C<< ->output_permanent >> for things that should be permanent
instead.

=cut

1;
