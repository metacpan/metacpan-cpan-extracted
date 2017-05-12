package SNMP::Effective::VarList;

=head1 NAME

SNMP::Effective::VarList - Helper module for SNMP::Effective::Host

=head1 DESCRIPTION

Thist module allows oid/oid-methods to be specified in different ways.

=head1 SYNOPSIS

    use SNMP::Effective::VarList;
    tie @varlist, 'SNMP::Effective::VarList';

    push @varlist, [$method1, $oid1], [$method2, $oid2];
    push @varlist, [$method1, $Varbind_obj1], [$method2, $Varbind_obj2];
    push @varlist, [$method1, $VarList_obj1], [$method2, $VarList_obj2];

=cut

use warnings;
use strict;
use SNMP;
use Tie::Array;
use Carp qw/ confess /;

use base qw/ Tie::StdArray /;

sub PUSH {
    my $self = shift;
    my @args = @_;

    LIST:
    for my $list (@args) {
        unless(ref $list eq 'ARRAY') {
            confess "A list of array-refs are required to push()";
        }
        unless(@$list > 1) {
            confess "Each array-ref to push() must have more than one element";
        }
        unless($SNMP::Effective::Dispatch::METHOD{$list->[0]}) {
            confess "The first element in the array-ref to push() must exist in \%SNMP::Effective::Dispatch::METHOD";
        }

        my $method = $list->[0];
        my $i = 0;
        my @varlist;

        OID:
        for my $oid (@$list) {
            next unless($i++); # skip the first element, containing the method

            if(ref $oid eq '') { # create varbind
                $oid = SNMP::Varbind->new([ $oid ]);
            }
            if(ref $oid eq 'SNMP::Varbind') { # append varbind
                push @varlist, $oid;
                next OID;
            }
            if(ref $oid eq 'SNMP::VarList') { # append varlist
                push @varlist, @$oid;
                next OID;
            }
        }

        if(@varlist) {
            push @$self, [ $method, SNMP::VarList->new(@varlist) ];
        }
    }

    return $self->FETCHSIZE;
}

=head1 AUTHOR

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

See L<SNMP::Effective>

=cut

1;
