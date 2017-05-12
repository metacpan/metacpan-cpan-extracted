package Net::Google::DocumentsList::Role::EntryWithoutEtag;
use Any::Moose '::Role';
with 'Net::Google::DataAPI::Role::Entry' => {-excludes => ['update']};

sub update {
    my ($self) = @_;
    $self->atom or return;
    # put without etag!
    my $atom = $self->service->request(
        {
            method => 'PUT',
            uri => $self->editurl,
            content => $self->to_atom->as_xml,
            content_type => 'application/atom+xml',
            response_object => 'XML::Atom::Entry',
        }
    );
    $self->container->sync;
    $self->atom($atom);
}

1;
