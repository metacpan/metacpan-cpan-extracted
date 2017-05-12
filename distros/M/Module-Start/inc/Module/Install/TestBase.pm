#line 1
package Module::Install::TestBase;
use strict;
use warnings;

use Module::Install::Base;

use vars qw($VERSION @ISA);
BEGIN {
    $VERSION = '0.10';
    @ISA     = 'Module::Install::Base';
}

sub use_test_base {
    my $self = shift; 
    $self->build_requires('Test::Base' => '0.50');
    $self->include('Test::Base');
    $self->include('Test::Base::Filter');
    $self->include('Spiffy');
    $self->include('Test::More');
    $self->include('Test::Builder');
    $self->include('Test::Builder::Module');
}

1;

#line 68
