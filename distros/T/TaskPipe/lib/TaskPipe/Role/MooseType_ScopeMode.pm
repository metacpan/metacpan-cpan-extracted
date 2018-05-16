package TaskPipe::Role::MooseType_ScopeMode;

use Moose::Role;
use Moose::Util::TypeConstraints;

subtype 'ScopeMode',
    as 'Str',
    where { 
            $_ eq 'project'
        ||  $_ eq 'global'
    };


=head1 NAME

TaskPipe::Role::MooseType_ScopeMode - scope mode type constraint

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
