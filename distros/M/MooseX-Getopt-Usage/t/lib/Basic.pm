package Basic;
use strict;
use warnings;

use Moose;
with 'MooseX::Getopt::Usage';

has verbose => ( is => 'ro', isa => 'Bool',
    documentation => qq{Say lots about what we do} );

has greet => ( is => 'ro', isa => 'Str', default => "World",
    documentation => qq{Who to say hello to.} );

# Doesn't count as required as it has a default.
has language => ( is => 'ro', isa => 'Str', required => 1, default => "en",
    documentation => qq{Language to greet in.} );

sub run {
    my $self = shift;
    $self->getopt_usage( exit => 0 ) if $self->help_flag;
}

1;
