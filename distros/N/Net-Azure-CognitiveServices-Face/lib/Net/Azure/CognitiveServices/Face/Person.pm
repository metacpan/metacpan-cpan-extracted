package Net::Azure::CognitiveServices::Face::Person;
use strict;
use warnings;
use base 'Net::Azure::CognitiveServices::Face::Base';

sub path {'/face/v1.0/persongroups'};

sub _add_face_request {
    my ($self, $person_group_id, $person_id, $image_url, %param) = @_;
    $self->build_request(POST => ["$person_group_id/persons/$person_id/persistedFaces", %param], 
        undef, {url => $image_url}
    );
}

sub add_face {
    my ($self, $person_group_id, $person_id, $image_url, %param) = @_;
    my $req = $self->_add_face_request($person_group_id, $person_id, $image_url, %param);
    $self->request($req);
}

sub _create_request {
    my ($self, $person_group_id, %param) = @_;
    $self->build_request(POST => ["$person_group_id/persons"], undef, {%param});
}

sub create {
    my ($self, $person_group_id, %param) = @_;
    my $req = $self->_create_request($person_group_id, %param);
    $self->request($req);
}

sub _delete_request {
    my ($self, $person_group_id, $person_id) = @_;
    $self->build_request(DELETE => ["$person_group_id/persons/$person_id"]);
}

sub delete {
    my ($self, $person_group_id, $person_id) = @_;
    my $req = $self->_delete_request($person_group_id, $person_id);
    $self->request($req);
}

sub _delete_face_request {
    my ($self, $person_group_id, $person_id, $persisted_face_id) = @_;
    $self->build_request(DELETE => ["$person_group_id/persons/$person_id/persistedFaces/$persisted_face_id"]);
}

sub delete_face {
    my ($self, $person_group_id, $person_id, $persisted_face_id) = @_;
    my $req = $self->build_request($person_group_id, $person_id, $persisted_face_id);
    $self->request($req);
}

sub _get_request {
    my ($self, $person_group_id, $person_id) = @_;
    $self->build_request(GET => ["$person_group_id/persons/$person_id"]);
}

sub get {
    my ($self, $person_group_id, $person_id) = @_;
    my $req = $self->_get_request($person_group_id, $person_id);
    $self->request($req);
}

sub _get_face_request {
    my ($self, $person_group_id, $person_id, $persisted_face_id) = @_;
    $self->build_request(GET => ["$person_group_id/persons/$person_id/persistedFaces/$persisted_face_id"]);
}

sub get_face {
    my ($self, $person_group_id, $person_id, $persisted_face_id) = @_;
    my $req = $self->_get_face_request($person_group_id, $person_id, $persisted_face_id);
    $self->request($req);
}

sub _list_request {
    my ($self, $person_group_id) = @_;
    $self->build_request(GET => ["$person_group_id/persons"]);
}

sub list {
    my ($self, $person_group_id) = @_;
    my $req = $self->_list_request($person_group_id);
    $self->request($req);
}

sub _update_request {
    my ($self, $person_group_id, $person_id, %param) = @_;
    $self->build_request(PATCH => ["$person_group_id/persons/$person_id"], undef, {%param});
}

sub update {
    my ($self, $person_group_id, $person_id, %param) = @_;
    my $req = $self->_update_request($person_group_id, $person_id, %param);
    $self->request($req);
}

sub _update_face_request {
    my ($self, $person_group_id, $person_id, $persisted_face_id, %param) = @_;
    $self->build_request(PATCH => ["$person_group_id/persons/$person_id/persistedFaces/$persisted_face_id"],
        undef,
        {%param},
    );
}

sub update_face {
    my ($self, $person_group_id, $person_id, $persisted_face_id, %param) = @_;
    my $req = $self->_update_face_request($person_group_id, $person_id, $persisted_face_id, %param);
    $self->request($req);
}

1;

__END__

=encoding utf-8

=head1 NAME

Net::Azure::CognitiveServices::Face::Person - Person API class of Cognitive Services API

=head1 DESCRIPTION

Person API wrapper.

=head1 METHODS

=head2 add_face

Send "Add a Person Face" request.

    $obj->add_face($person_group_id, $person_id, $image_url, 
        userData   => 'created_date:2016-08-01',
        targetFace => '10,10,100,100', 
    );

Please see L<https://dev.projectoxford.ai/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039523b> for detail.

=head2 create

Send "Creaet a Person" request and fetch result as arrayref.

    my $result = $obj->create($person_group_id,
        name     => "Donard Trump",
        userData => "created_date:2016-08-01",
    );
    say $result->{personId} ## output personId

Please see L<https://dev.projectoxford.ai/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039523c> for detail.

=head2 delete

Send "Delete a Person" request.

    $obj->delete($person_group_id, $person_id);

Please see L<https://dev.projectoxford.ai/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039523d> for detail.

=head2 delete_face

Send "Delete a Person Face" request.

    $obj->delete_face($person_group_id, $person_id, $persisted_face_id);

Please see L<https://dev.projectoxford.ai/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039523e> for detail.

=head2 get

Send "Get a Person" request and fetch result as hashref.

    my $result = $obj->get($person_group_id, $person_id);
    say $result->{personId}; ## output personId

Please see L<https://dev.projectoxford.ai/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039523f> for detail.

=head2 get_face

Send "Get a Person Face" request and fetch result as hashref.

    my $result = $obj->get_face($person_group_id, $person_id, $persisted_face_id);
    say $result->{persistedFaceId}; ## output persistedFaceId

Please see L<https://dev.projectoxford.ai/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395240> for detail.

=head2 list

Send "List Persons in a Person Group" request and fetch result as arrayref.

    my $result = $obj->list($person_group_id);
    say join("%s\n", map {$_->{personId}} @$result); ## output list of personId

Please see L<https://dev.projectoxford.ai/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395241> for detail.

=head2 update

Send "Update a Person" request.

    $obj->update($person_group_id, $person_id,
        name     => "Hillary Clinton",
        userData => "update:2016-08-01",
    );

Please see L<https://dev.projectoxford.ai/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395242> for detail.

=head2 update_face

Send "Update a Person Face" request.

    $obj->update_face($person_group_id, $person_id, $persisted_face_id,
        userData => "update:2016-08-01",
    );

Please see L<https://dev.projectoxford.ai/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395243> for detail.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut