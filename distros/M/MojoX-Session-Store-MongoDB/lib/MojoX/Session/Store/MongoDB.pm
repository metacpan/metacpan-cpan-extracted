package MojoX::Session::Store::MongoDB;

use strict;
use warnings;

use base 'MojoX::Session::Store';
use MongoDB;
use Carp qw(croak);

use namespace::clean;

__PACKAGE__->attr('mongodb');
__PACKAGE__->attr('mongodb_coll');

our $VERSION = '0.52';

sub new {
    my ($class, $param) = @_;
    my $self = $class->SUPER::new();
    bless $self, $class;

    $param ||= {};
    my $database   = delete $param->{database};
    my $collection = delete $param->{collection};
    croak "database and collection parameters required"
      unless ($database or $param->{mongodb}) and $collection;

    $self->mongodb($param->{mongodb} || MongoDB::Connection->new($param)->get_database($database));
    $self->mongodb_coll($self->mongodb->get_collection($collection));

    return $self;
}

sub create {
    my ($self, $sid, $expires, $data) = @_;

    my $new_data = {
        _id     => $sid,
        data    => $data,
        expires => $expires,
    };
    $self->mongodb_coll->update({_id => $sid}, $new_data, {upsert => 1});
    my $err = $self->mongodb->last_error;
    if ($err->{err}) {
        require Data::Dumper;
        warn Data::Dumper::Dumper($err);
        return 0;
    }
    else {
        return 1;
    }
}

sub update {
    shift->create(@_);
}

sub load {
    my ($self, $sid) = @_;
    my $res = $self->mongodb_coll->find_one({_id => $sid});
    return ($res->{expires}, $res->{data});
}

sub delete {
    my ($self, $sid) = @_;
    my $res = $self->mongodb_coll->remove({_id => $sid});
    return 1;
}

1;
__END__

=head1 NAME

MojoX::Session::Store::MongoDB - MongoDB Store for MojoX::Session

=head1 SYNOPSIS

    my $session = MojoX::Session->new(
        tx        => $tx,
        store     => MojoX::Session::Store::MongoDB->new({
            host => '127.0.0.1',
            port => 27017,
            database   => 'some_app',
            collection => 'sessions',
        }),
        transport => MojoX::Session::Transport::Cookie->new,
    );

    # see doc for MojoX::Session

=head1 DESCRIPTION

L<MojoX::Session::Store::MongoDB> is a store for L<MojoX::Session> that stores a
session in a MongoDB database.

=head1 ATTRIBUTES

L<MojoX::Session::Store::MongoDB> implements the following attributes.

=head2 C<mongodb>
    
    my $db = $store->mongodb;

Get and set MongoDB::Database object.

=head2 C<mongodb_coll>
    
    my $collection = $store->mongodb_coll;

Get and set MongoDB::Collection object.

=head1 METHODS

L<MojoX::Session::Store::MongoDB> inherits all methods from
L<MojoX::Session::Store>.

=head2 C<new>

C<new> uses the database and collection parameters for the database
name and the collection name respectively. All other parameters are
passed to C<MongoDB::Connection->new()>.

Instead of the C<database> name you can also pass in a C<mongodb>
parameter with a L<MongoDB::Database> object.

=head2 C<create>

Insert session to MongoDB.

=head2 C<update>

Update session in MongoDB.

=head2 C<load>

Load session from MongoDB.

=head2 C<delete>

Delete session from MongoDB.

=head1 CONTRIBUTE

git repository etc at L<http://github.com/abh/MojoX-Session-Store-MongoDB>.

=head1 AUTHOR

Ask Bjørn Hansen <ask@develooper.com> 

=head1 COPYRIGHT

Copyright (C) 2009 Ask Bjørn Hansen and Develooper LLC.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
