package Term::Output::List;
use 5.020;
use feature 'signatures';
no warnings 'experimental::signatures';

use Module::Load 'load';

our $VERSION = '0.03';

=head1 NAME

Term::Output::List - output an updateable list of ongoing jobs

=head1 SYNOPSIS

    my $printer = Term::Output::List->new();
    my @ongoing_tasks = ('file1: frobnicating', 'file2: bamboozling', 'file3: frobnicating');
    $printer->output_list(@ongoing_tasks);

    $printer->output_permanent("Frobnicated gizmos"); # appears above the list

=cut

sub detect_terminal_type($os = $^O) {
	if( $os eq 'MSWin32' ) {
		require Win32::Console;
		if( Win32::Console->Mode & 0x0004 ) { #ENABLE_VIRTUAL_TERMINAL_PROCESSING 
			return 'ansi';
		} else {
			return 'win32'
		}
	} else {
		return 'ansi';
	}
}

sub new($class,%args) {
	my $ttype = detect_terminal_type();
	
	my $impl = 'Term::Output::List::ANSI';
	if( $ttype eq 'win32' ) {
	    $impl = 'Term::Output::List::Win32';
	}
	load $impl;
	return $impl->new( %args )
}

=head1 METHODS

=head2 C<< Term::Output::List->new() >>

=cut

=head2 C<< ->scroll_up >>

Helper method to place the cursor at the top of the updateable list.

=head2 C<< ->output_permanent >>

  $o->output_permanent("Frobnicated 3 items for job 2");
  $o->output_list("Frobnicating 9 items for job 1",
                  "Frobnicating 2 items for job 3",
  );

Outputs items that should go on the permanent record. It is expected to
output the (remaining) list of ongoing jobs after that.

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
