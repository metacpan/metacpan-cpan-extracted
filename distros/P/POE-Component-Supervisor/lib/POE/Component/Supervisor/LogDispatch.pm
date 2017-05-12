package POE::Component::Supervisor::LogDispatch;

our $VERSION = '0.09';

use Moose::Role;
use namespace::autoclean;

with qw(MooseX::LogDispatch);

# borked due to role impl... =P
# has '+use_logger_singleton' => ( default => 1 );

has 'use_logger_singleton' => (
    is => "rw",
    isa => "Bool",
    default => 1
);

__PACKAGE__

__END__

=pod

=head1 NAME

POE::Component::Supervisor::LogDispatch - Logging role

=head1 VERSION

version 0.09

=head1 SYNOPSIS

    with qw(POE::Component::Supervisor::LogDispatch);

=head1 DESCRIPTION

This is a variation on L<MooseX::LogDispatch> that ensures that a global
L<Log::Dispatch::Config> singleton will be respected.

=cut
