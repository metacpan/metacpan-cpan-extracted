package SmokeRunner::Multi::Reporter::Test;

use strict;
use warnings;

use base 'SmokeRunner::Multi::Reporter';
__PACKAGE__->mk_ro_accessors('output');


sub report
{
    my $self = shift;

    $self->{output} = $self->runner()->output();
}


1;
