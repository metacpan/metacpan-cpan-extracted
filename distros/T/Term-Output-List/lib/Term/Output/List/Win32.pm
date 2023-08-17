package Term::Output::List::Win32;
use strict;
use warnings;
use Moo 2;
use Win32::Console;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

=head1 NAME

Term::Output::List::Win32 - output an updateable list of ongoing jobs to a Win32 console

=head1 SYNOPSIS

    my $printer = Term::Output::List->new();
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

has 'console' => (
    is => 'lazy',
    default => sub($s) { Win32::Console->new(STD_OUTPUT_HANDLE) },
);

has 'interactive' => (
    is => 'lazy',
    default => sub { -t $_[0]->fh },
);

=head1 METHODS

=head2 C<< Term::Output::List::Win32->new() >>

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
    if( $self->interactive ) {
        $self->scroll_up($total);
        my $w = $self->width;
        if( @items ) {
            $self->do_clear_eol(scalar @items);
            print { $self->fh }
                  join("\n",
                    map { length($_) > $w - 1 ? (substr($_,0,$w-3).'..'): $_
                        } @items)."\n";
        };
    } else {
        print { $self->fh } join("\n", @items) . "\n";
    }
    #sleep 1;

    if( $self->interactive ) {
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

=cut

sub output_list( $self, @items ) {
    if( $self->interactive ) {
        $self->output_permanent(@items);
        #sleep 1;
        $self->_last_lines( 0+@items);
    }
}

=head2 C<<->fresh_output >>

  $o->fresh_output();

Helper subroutine to make all items from the last output list remain as is.

For compatibility between output to a terminal and output without a terminal,
you should use C<< ->output_permanent >> for things that should be permanent
instead.

=cut

sub fresh_output( $self ) {
    $self->_last_lines( 0 );
}

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
