use Modern::Perl;
package Net::OpenXchange::Module::User;
BEGIN {
  $Net::OpenXchange::Module::User::VERSION = '0.001';
}

use Moose;
use namespace::autoclean;

# ABSTRACT: OpenXchange user module

use HTTP::Request::Common;
use Net::OpenXchange::Object::User;

has 'path' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'user',
);

has 'class' => (
    is      => 'ro',
    isa     => 'ClassName',
    default => 'Net::OpenXchange::Object::User',
);

with 'Net::OpenXchange::Module';

sub all {
    my ($self) = @_;

    my $req = GET(
        $self->req_uri(
            action  => 'all',
            columns => $self->columns,
        )
    );

    my $res = $self->_send($req);
    return map { $self->class->thaw($_) } @{ $res->{data} };
}

sub list {
    my ($self, @ids) = @_;

    my $req = PUT(
        $self->req_uri(
            action  => 'list',
            columns => $self->columns
        ),
        Content => encode_json(\@ids),
    );

    my $res = $self->_send($req);
    return map { $self->class->thaw($_) } @{ $res->{data} };
}

__PACKAGE__->meta->make_immutable;
1;


__END__
=pod

=head1 NAME

Net::OpenXchange::Module::User - OpenXchange user module

=head1 VERSION

version 0.001

=head1 SYNOPSIS

L<Net::OpenXchange::Module::User|Net::OpenXchange::Module::User> interfaces
with the user API of OpenXchange. It works with instances of
L<Net::OpenXchange::Object::User|Net::OpenXchange::Object::User>.

When using L<Net::OpenXchange|Net::OpenXchange>, an instance of this class is
provided as the C<user> attribute.

=head1 METHODS

=head2 all

    my @users = $module_user->all();

Fetch all users and return a list of them.

=head2 list

    my @users = $module_user->list(@ids);

Fetch users with given IDs and return a list of them.

=head1 AUTHOR

Maximilian Gass <maximilian.gass@credativ.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Maximilian Gass.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

