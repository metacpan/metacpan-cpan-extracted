package TaskPipe::Role::MooseType_IterateMode;

use Moose::Role;
use Moose::Util::TypeConstraints;

subtype 'IterateMode',
    as 'Str',
    where {
            $_ eq 'once'
        ||  $_ eq 'repeat'
    };


=head1 NAME

TaskPipe::Role::MooseType_IterateMode - iterate mode type constraint

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
