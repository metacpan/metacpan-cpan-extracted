use Modern::Perl;
package Net::OpenXchange::Module;
BEGIN {
  $Net::OpenXchange::Module::VERSION = '0.001';
}

use Moose::Role;
use namespace::autoclean;

# ABSTRACT: Role for OpenXchange modules

use Readonly;

requires qw(path class);

Readonly my $MICROSECOND => 1000;

has conn => (
    is       => 'ro',
    isa      => 'Net::OpenXchange::Connection',
    required => 1,
    handles  => { _send => 'send', },
);

has columns => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_columns',
);

sub _build_columns {
    my ($self) = @_;
    return join q{,}, $self->class->get_ox_columns;
}

sub req_uri {
    my ($self, %params) = @_;
    return $self->conn->req_uri($self->path, %params);
}

sub ox_time {
    my ($self, $dt) = @_;
    return $dt->epoch * $MICROSECOND;
}

sub ox_date {
    my ($self, $dt) = @_;
    return $dt->clone->truncate(to => 'day')->epoch * $MICROSECOND;
}

1;


__END__
=pod

=head1 NAME

Net::OpenXchange::Module - Role for OpenXchange modules

=head1 VERSION

version 0.001

=head1 SYNOPSIS

Net::OpenXchange::Module is a role to be consumed by classes implementing
methods for the OpenXchange API

=head1 ATTRIBUTES

=head2 conn

Required constructor argument, the L<Net::OpenXchange::Connection|Net::OpenXchange::Connection> object.

=head2 columns

A string representing all attribute IDs to be used in 'columns' fields in
requests.

=head1 METHODS

=head2 ox_time

    my $time = $module->ox_time($dt);

Convert the given DateTime object into an OpenXchange datetime.

=head2 ox_date

    my $date = $module->ox_date($dt);

Convert the given DateTime object into an OpenXchange date.

=head2 req_uri

    my $uri = $module->req_uri($path, %params);

    my $uri = $module->req_uri('folder', action => 'all');
    # $uri is https://yourox/ajax/folder?action=all

Construct a URI by appending the given path to the root URI and adding the
params as URI query parameters.

=head1 AUTHOR

Maximilian Gass <maximilian.gass@credativ.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Maximilian Gass.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

