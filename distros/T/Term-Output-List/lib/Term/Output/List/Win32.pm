package Term::Output::List::Win32;
use 5.020;
use Moo 2;
use Scalar::Util 'weaken';
use Win32::Console;
use experimental 'signatures';

our $VERSION = '0.05';
with 'Term::Output::List::Role';

=head1 NAME

Term::Output::List::Win32 - output an updateable list of ongoing jobs to a Win32 console

=head1 SYNOPSIS

    my $printer = Term::Output::List->new(
        hook_warnings => 1,
    );
    my @ongoing_tasks = ('file1: frobnicating', 'file2: bamboozling', 'file3: frobnicating');
    $printer->output_list(@ongoing_tasks);

    $printer->output_permanent("Frobnicated gizmos"); # appears above the list

=cut

has '_last_lines' => (
    is => 'rw',
);

=head1 MEMBERS

=head2 C<< fh >>

Filehandle used for output. Default is C<< STDOUT >>.

=cut

has 'fh' => (
    is => 'lazy',
    default => sub { \*STDOUT },
);

has 'ellipsis' => (
    is => 'lazy',
    default => sub { "..." },
);

has 'console' => (
    is => 'lazy',
    default => sub($s) { Win32::Console->new(STD_OUTPUT_HANDLE) },
);

=head2 C<< interactive >>

Whether the script is run interactively and should output intermittent
updateable information

=head2 C<< hook_warnings >>

Install a hook for sending warnings to C<< ->output_permanent >>. This
prevents ugly tearing/overwriting when your code outputs warnings.

=cut

=head1 METHODS

=head2 C<< Term::Output::List::Win32->new() >>

  my $output = Term::Output::List::Win32->new(
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

sub width($self) {
    my ($w,$h) = $self->console->Size();
    return $w
};

=head2 C<< ->scroll_up >>

Helper method to place the cursor at the top of the updateable list.

=cut

sub scroll_up( $self, $count=$self->_last_lines ) {
    if( !$count) {
    } else {
        # Overwrite the number of lines we printed last time
        my ($x,$y) = $self->console->Cursor;
        $y //= 0;
        my $diff = $y-$count;
        $self->console->Title($count);
        my $line = $diff < 0 ? 0 : $diff;
        $self->console->Cursor( 0, $line );
    };
}

=head2 C<<->output_permanent>>

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

        if( @items ) {
            $self->do_clear_eol(scalar @items);
            print { $self->fh }
                  join("\n",
                    map { s/\s*\z//r }
                    map { $self->_trim( $_, $w ) }
                        } @items)."\n";
        };

        my $blank = $total - @items;
        if( $blank > 0 ) {
            $self->do_clear_eol($blank);
        }
        $self->fresh_output();
    }
}

=head2 C<<->output_list @items>>

  $o->output_list("Frobnicating 9 items for job 1",
                  "Frobnicating 2 items for job 3",
  );

Outputs items that can be updated later, as long as no intervening output
(like from C<print>, C<say> or C<warn>) has happened. If you want to output
lines that should not be overwritten later, see C<</->output_permanent>>

=head2 C<<->fresh_output >>

  $o->fresh_output();

Helper subroutine to make all items from the last output list remain as is.

For compatibility between output to a terminal and output without a terminal,
you should use C<< ->output_permanent >> for things that should be permanent
instead.

=head2 C<< ->do_clear_eol >>

    $o->do_clear_eol(10); # clear 10 lines from the cursor down

Helper method to clear lines on the terminal.

=cut

sub do_clear_eol( $self, $count=$self->_last_lines ) {
    if( !$count) {
    } else {
        # Overwrite the number of lines we printed last time
        my $c = $self->console;
        my $w = $self->width;
        my ($x,$y) = $c->Cursor;
        $c->FillChar(' ',$w*$count, 0, $y );
    };
}

1;
