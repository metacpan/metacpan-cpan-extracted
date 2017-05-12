package Railsish::Record;
our $VERSION = '0.21';

use Any::Moose;
use DateTime;

use Railsish::Database;

has created_at => (
    isa => "DateTime",
    is => "ro",
    default => sub { DateTime->now }
);

{
    my $db;
    sub db {
        return $db if defined $db;
        $db = Railsish::Database->new;
    }
}

sub find {
    my ($self, $id) = @_;
    db->lookup($id);
}

sub find_all {
    my ($self, @args) = @_;
    db->search(CLASS => (ref($self) || $self), @args);
}

sub id {
    my ($self) = @_;
    return db->object_to_id($self);
}

sub save {
    my ($self) = @_;
    db->store($self);
}

sub destroy {
    my ($self) = @_;
    db->delete($self);
}

__PACKAGE__->meta->make_immutable;


__END__
=head1 NAME

Railsish::Record

=head1 VERSION

version 0.21

=head1 AUTHOR

  Liu Kang-min <gugod@gugod.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Liu Kang-min <gugod@gugod.org>.

This is free software, licensed under:

  The MIT (X11) License

