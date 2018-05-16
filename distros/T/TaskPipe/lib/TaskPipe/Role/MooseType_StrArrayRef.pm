package TaskPipe::Role::MooseType_StrArrayRef;

use Moose::Role;
use Moose::Util::TypeConstraints;


subtype 'StrArrayRef', as 'ArrayRef';

coerce 'StrArrayRef', from 'Str', via {
    my @vals = split(',',$_);
    for my $i (0..$#vals){
        $vals[$i] =~ s/^\s+//;
        $vals[$i] =~ s/\s+//;
    }
    return \@vals;
};


=head1 NAME

TaskPipe::Role::MooseType_StrArrayRef - array ref represented as a string type constraint

=head1 DESCRIPTION

A moose subtype to be included as a role

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

1;
