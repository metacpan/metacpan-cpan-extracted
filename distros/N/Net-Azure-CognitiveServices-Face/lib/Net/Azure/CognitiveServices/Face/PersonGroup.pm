package Net::Azure::CognitiveServices::Face::PersonGroup;
use strict;
use warnings;
use base 'Net::Azure::CognitiveServices::Face::Base';

sub path {'/face/v1.0/persongroups'};

sub _create_request {
    my ($self, $person_group_id, %param) = @_;
    $self->build_request(PUT => [$person_group_id], undef, {%param});
}

sub create {
    my ($self, $person_group_id, %param) = @_;
    my $req = $self->_create_request($person_group_id, %param);
    $self->request($req);
}

sub _delete_request {
    my ($self, $person_group_id) = @_;
    $self->build_request(DELETE => [$person_group_id]);
}

sub delete {
    my ($self, $person_group_id) = @_;
    my $req = $self->_delete_request($person_group_id);
    $self->request($req); 
}

sub _get_request {
    my ($self, $person_group_id) = @_;
    $self->build_request(GET => [$person_group_id]);
}

sub get {
    my ($self, $person_group_id) = @_;
    my $req = $self->_get_request($person_group_id);
    $self->request($req);
}

sub _training_status_request {
    my ($self, $person_group_id) = @_;
    $self->build_request(GET => ["$person_group_id/training"]);
}

sub training_status {
    my ($self, $person_group_id) = @_;
    my $req = $self->_training_status_request($person_group_id);
    $self->request($req);
}

sub _list_request {
    my ($self, %param) = @_;
    $self->build_request(GET => [undef, %param]);
}

sub list {
    my ($self, %param) = @_;
    my $req = $self->_list_request(%param);
    $self->request($req);
}

sub _train_request {
    my ($self, $person_group_id) = @_;
    $self->build_request(POST => ["$person_group_id/train"], undef, {body => ''});
}

sub train {
    my ($self, $person_group_id) = @_;
    my $req = $self->_train_request($person_group_id);
    $self->request($req);
}

sub _update_request {
    my ($self, $person_group_id, %param) = @_;
    $self->build_request(PATCH => [$person_group_id], undef, {%param});
}

sub update {
    my ($self, $person_group_id, %param) = @_;
    my $req = $self->_update_request($person_group_id, %param);
    $self->request($req);
}

1;

__END__

=encoding utf-8

=head1 NAME

Net::Azure::CognitiveServices::Face::PersonGroup - Person Group API class of Cognitive Services API

=head1 DESCRIPTION

Person Group API wrapper.

=head1 METHODS

=head2 create

Send "Create a Person Group" request.

    $obj->create($person_group_id, 
        name     => 'Capitalists in America',
        userData => 'created_date:2016-08-01',
    );

Please see L<https://dev.projectoxford.ai/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395244> for detail.

=head2 delete

Send "Delete a Person Group" request.

    $obj->delete($person_group_id);

Please see L<https://dev.projectoxford.ai/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395245> for detail.

=head2 get

Send "Get a Person Group" request and fetch result as hashref.

    say $result->{name}; ## output name of Person Group
    my $result = $obj->get($person_group_id);

Please see L<https://dev.projectoxford.ai/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395246> for detail.

=head2 training_status

Send "Get Person Group Training Status" request and fetch result as hashref.

    my $result = $obj->training_status($person_group_id);
    say $result->{status}; ## output training status of Person Group

Please see L<https://dev.projectoxford.ai/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395247> for detail.

=head2 list

Send "List Person Groups" request and fetch result as arrayref.

    my $result = $obj->list(start => 5, top => 10);
    say join("%s\n", map {$_->{name}} @$result); ## output name list of Person Groups 

Please see L<https://dev.projectoxford.ai/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395248> for detail.

=head2 train

Send "Train Person Group" request.

    $obj->train($person_group_id);

Please see L<https://dev.projectoxford.ai/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395249> for detail.

=head2 update

Send "Update a Person Group" request.

    $obj->update($person_group_id, 
        name     => 'new Group Name',
        userData => 'update:2016-08-01', 
    );

Please see L<https://dev.projectoxford.ai/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039524a> for detail.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut