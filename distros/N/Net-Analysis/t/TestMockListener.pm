package t::TestMockListener;
# $Id: TestMockListener.pm 131 2005-10-02 17:24:31Z abworrall $

use 5.008000;
our $VERSION = '0.01';
use strict;
use warnings;
use Carp qw(carp croak confess);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(mock_listener);

use Test::MockObject;

#### A listener object needs mocking more carefully.
#
sub mock_listener {
    my ($mock) = Test::MockObject->new();
    $mock->mock ('emit', sub{1}); # All listeners need this method
    $mock->mock ($_, sub{1}) foreach (@_);

    return $mock;
}

# Routines for examining / compariing mock output ??

1;
