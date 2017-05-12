package Net::Google::DataAPI::Role::Entry;
use Any::Moose '::Role';
use Carp;
use XML::Atom;
use XML::Atom::Entry;
our $VERSION = '0.02';

has container => (
    isa => 'Maybe[Net::Google::DataAPI::Role::Entry]',
    is => 'ro',
);

has service => (
    does => 'Net::Google::DataAPI::Role::Service',
    is => 'ro',
    required => 1,
    lazy_build => 1,
    weak_ref => 1,
    handles => ['ns'],
);

sub _build_service { shift->container->service };

my %rel2label = (
    edit => 'editurl',
    self => 'selfurl',
);

for my $label (values %rel2label) {
    has $label => (
        isa => 'Str',
        is => 'ro',
        lazy_build => 1,
    );

    __PACKAGE__->meta->add_method(
        "_build_$label" => sub {
            my $self = shift;
            for my $link ($self->atom->link) {
                my $rel = $rel2label{$link->rel} or next;
                return $link->href if $rel eq $label;
            }
        }
    );
}

has atom => (
    isa => 'XML::Atom::Entry',
    is => 'rw',
    trigger => sub {
        my ($self, $arg) = @_;
        my $id = $self->atom->get($self->atom->ns, 'id');
        croak "can't set different id!" if $self->id && $self->id ne $id;
        $self->from_atom;
    },
    handles => ['elem', 'author'],
);

has id => (
    isa => 'Str',
    is => 'ro',
    lazy_build => 1,
);

sub _build_id {
    my $self = shift;
    $self->atom->get($self->atom->ns, 'id') || '';
}

has title => (
    isa => 'Str',
    is => 'rw',
    trigger => sub {$_[0]->update},
    lazy_build => 1,
);

sub _build_title {
    my $self = shift;
    $self->atom ? $self->atom->title : 'untitled';
}

has etag => (
    isa => 'Str',
    is => 'rw',
    lazy_build => 1,
);

sub _build_etag {
    my $self = shift;
    $self->atom or return '';
    $self->elem->getAttributeNS($self->ns('gd')->{uri}, 'etag');
}


sub from_atom {
    my ($self) = @_;
    for my $attr ($self->meta->get_all_attributes) {
        $attr->name eq 'service' and next;
        $attr->clear_value($self) if $attr->{lazy};
    }
}

sub to_atom {
    my ($self) = @_;
    my $entry = XML::Atom::Entry->new;
    $entry->title($self->title);
    return $entry;
}

sub sync {
    my ($self) = @_;
    my $entry = $self->service->get_entry($self->selfurl);
    $self->atom($entry);
}

sub update {
    my ($self) = @_;
    $self->etag or return;
    my $atom = $self->service->put(
        {
            self => $self,
            entry => $self->to_atom,
        }
    );
    $self->container->sync if $self->container;
    $self->atom($atom);
}

sub delete {
    my $self = shift;
    my $res = $self->service->delete({self => $self});
    $self->container->sync if $self->container;
    return $res->is_success;
}

no Any::Moose '::Role';

1;

__END__

=pod

=head1 NAME

Net::Google::DataAPI::Role::Entry - represents entry of Google Data API

=head1 SYNOPSIS

    package MyEntry;
    use Any::Moose;
    use Net::Google::DataAPI;
    with 'Net::Google::DataAPI::Role::Entry';

    entry_has some_data => (
        is => 'ro',
        isa => 'Str',
        tagname => 'somedata',
        ns => 'gd',
    );

    1;

=head1 DESCRIPTION

Net::Google::DataAPI::Role::Entry provides base functionalities for the entry of Google Data API.

=head1 AUTHOR

Nobuo Danjou E<lt>danjou@soffritto.orgE<gt>

=head1 SEE ALSO

L<Net::Google::DataAPI>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

