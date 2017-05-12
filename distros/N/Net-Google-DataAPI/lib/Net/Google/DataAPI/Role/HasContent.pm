package Net::Google::DataAPI::Role::HasContent;
use Any::Moose '::Role';
our $VERSION='0.03';

requires 'update';

has content => (
    isa => 'HashRef',
    is => 'rw',
    lazy_build => 1,
    trigger => sub { $_[0]->update },
);

sub _build_content { +{} }

sub param {
    my ($self, $arg) = @_;
    return $self->content unless $arg;
    if (ref $arg eq 'HASH') {
        return $self->content(
            {
                %{$self->content},
                %$arg,
            }
        );
    } else {
        return $self->content->{$arg};
    }
}

no Any::Moose '::Role';

1;

__END__

=pod

=head1 NAME

Net::Google::DataAPI::Role::HasContent - provides 'param' method to Entry

=head1 SYNOPSIS

    package MyEntry;
    use Any::Moose;
    with qw(
        Net::Google::DataAPI::Role::Entry
        Net::Google::DataAPI::Role::HasContent
    );

    1;

=head1 DESCRIPTION

Net::Google::DataAPI::Role::HasContent provides 'param' method to Entry.

=head1 AUTHOR

Nobuo Danjou E<lt>danjou@soffritto.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
