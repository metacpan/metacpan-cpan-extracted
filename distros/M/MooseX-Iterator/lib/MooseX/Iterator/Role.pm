package MooseX::Iterator::Role;
use Moose::Role;

our $VERSION   = '0.11';
our $AUTHORITY = 'cpan:RLB';

requires $_ for qw{
    next
    has_next
    peek
};


1;
