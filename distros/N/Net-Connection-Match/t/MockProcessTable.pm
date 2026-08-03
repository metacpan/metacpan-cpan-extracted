package MockProcessTable;

use 5.006;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK=( 'mock_process_table' );

=head1 NAME

MockProcessTable - Replaces Proc::ProcessTable with a canned table for testing.

=head1 SYNOPSIS

    use lib './t';
    use MockProcessTable 'mock_process_table';

    mock_process_table(
                       {
                        pid=>1234,
                        cmndline=>'/usr/sbin/sshd -D',
                        wchan=>'kqread',
                        pctcpu=>'10.5',
                        },
                       );

Each hash reference passed becomes a process in the table. The keys are
available both as hash keys and as the accessors the various modules use,
allowing the process table lookup done when a Net::Connection object has no
proc set to be exercised without depending on what is running on the machine
running the tests.

=cut

sub mock_process_table {
	my @procs=@_;

	my @table=map { bless { %{ $_ } }, 'MockProcessTable::Process' } @procs;

	{
		no warnings 'redefine';
		no strict 'refs';
		*{'Proc::ProcessTable::new'}=sub { my $self={}; bless $self, 'Proc::ProcessTable'; return $self; };
		*{'Proc::ProcessTable::table'}=sub { return \@table; };
	}

	return \@table;
}

package MockProcessTable::Process;

sub cmndline { return $_[0]->{cmndline}; }
sub fname    { return $_[0]->{fname};    }
sub wchan    { return $_[0]->{wchan};    }

1;
