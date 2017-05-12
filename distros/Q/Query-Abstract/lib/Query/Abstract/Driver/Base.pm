package Query::Abstract::Driver::Base;

our $VERSION = '0.01';

use v5.10;
use strict;
use warnings;


sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}

sub init {

}


1;