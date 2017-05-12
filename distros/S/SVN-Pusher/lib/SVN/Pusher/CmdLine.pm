package SVN::Pusher::CmdLine;

use strict;
use warnings;

use 5.008;

use base 'SVN::Pusher';

sub report
{
    my $self = shift;
    my $spec = shift;

    my $op = $spec->{'op'};

    if ($op eq "file")
    {
        print sprintf("   %c %s\n", ord($spec->{'file_op'}), $spec->{'path'});
    }
    elsif ($op eq "msg")
    {
        print $spec->{'msg'} . "\n";
    }
}

1;
