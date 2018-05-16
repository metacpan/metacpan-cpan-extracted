package TaskPipe::Role::MooseType_UserAgentType;

use Moose::Role;
use Moose::Util::TypeConstraints;

subtype 'UserAgentType',
    as 'Any',
    where {
            ref $_
        &&  (ref $_ eq 'LWP::UserAgent'
        ||  ref $_ eq 'WWW::Mechanize::PhantomJS')
    };

=head1 NAME

TaskPipe::Role::MooseType_UserAgentType - user agent type type constraint

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
