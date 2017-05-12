package Net::Azure::CognitiveServices::Face::FaceList;
use strict;
use warnings;
use base 'Net::Azure::CognitiveServices::Face::Base';

sub path {'/face/v1.0/facelists'};

sub _create_request {
    my ($self, $face_list_id, %param) = @_;
    my $body = {
        name     => $param{name}     || "$face_list_id", 
        userData => $param{userData} || "$face_list_id",
    };
    $self->build_request(PUT => [$face_list_id], undef, $body);
}

sub create {
    my ($self, $face_list_id, %param) = @_;
    my $req = $self->_create_request($face_list_id, %param);
    $self->request($req);
}

sub _add_request {
    my ($self, $face_list_id, $image_url, %param) = @_;
    $self->build_request(POST => ["$face_list_id/persistedFaces", %param], undef, {url => $image_url}); 
}

sub add {
    my ($self, $face_list_id, $image_url, %param) = @_;
    my $req = $self->_add_request($face_list_id, $image_url, %param);
    $self->request($req);
}

sub _delete_request {
    my ($self, $face_list_id, $remove_face_id) = @_;
    $self->build_request(DELETE => ["$face_list_id/persistedFaces/$remove_face_id"]);
}

sub delete {
    my ($self, $face_list_id, $remove_face_id) = @_;
    my $req = $self->_delete_request($face_list_id, $remove_face_id);
    $self->request($req);
}

sub _flush_request {
    my ($self, $face_list_id) = @_;
    $self->build_request(DELETE => ["$face_list_id"]);
}

sub flush {
    my ($self, $face_list_id) = @_;
    my $req = $self->_flush_request($face_list_id);
    $self->request($req);
}

sub _get_request {
    my ($self, $face_list_id) = @_;
    $self->build_request(GET => ["$face_list_id"]);
}

sub get {
    my ($self, $face_list_id) = @_;
    my $req = $self->_get_request($face_list_id);
    $self->request($req);
}

sub _list_request {
    my ($self) = @_;
    $self->build_request('GET');
}

sub list {
    my ($self) = @_;
    my $req = $self->_list_request;
    $self->request($req); 
}

sub _update_request {
    my ($self, $face_list_id, %param) = @_;
    $self->build_request(PATCH => ["$face_list_id"], undef, {%param});
}

sub update {
    my ($self, $face_list_id, %param) = @_;
    my $req = $self->_update_request($face_list_id);
    $self->request($req);
}

1;

__END__

=encoding utf-8

=head1 NAME

Net::Azure::CognitiveServices::Face::FaceList - Face List API class of Cognitive Services API

=head1 DESCRIPTION

Face List API wrapper.

=head1 METHODS

=head2 create

Send "Create a Face List" request.

    $obj->create($face_list_id, 
        name     => 'my_face_list',
        userData => 'created_date:2016-08-01',
    );

Please see L<https://dev.projectoxford.ai/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039524b> for detail.

=head2 add

Send "Add a Face to Face List" request and fetch result as hashref.

    my $result = $obj->add($face_list_id, $image_url,
        userData   => 'added_date:2016-08-01',
        targetFace => '10,10,100,100',
    );
    say $result->{persistedFaceId}; ## output persistedFaceId

Please see L<https://dev.projectoxford.ai/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395250> for detail.

=head2 delete

Send "Delete a Face from Face List" request.

    $obj->delete($face_list_id, $remove_face_id);

Please see L<https://dev.projectoxford.ai/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395251> for detail.

=head2 flush

Send "Delete a Face List" request.

    my $result = $obj->flush($face_list_id);

Please see L<https://dev.projectoxford.ai/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039524f> for detail.

=head2 get

Send "Get a Face List" request and fetch result as hashref.

    my $result = $obj->get($face_list_id);
    say $result->{name}; ## output Face List name

Please see L<https://dev.projectoxford.ai/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039524c> for detail.

=head2 list

Send "List Face Lists" request and fetch result as arrayref.

    my $result = $obj->list;
    say join("%s\n", map {$_->{faceListId}} @$result); ## output list of faceListId

Please see L<https://dev.projectoxford.ai/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039524d> for detail.

=head2 update 

Send "Update a Face List" request.

    $obj->update($face_list_id,
        name     => 'new Face List Name',
        userData => 'update:2016-08-01',  
    );

Please see L<https://dev.projectoxford.ai/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039524e> for detail.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut