package Net::Azure::CognitiveServices::Face::Face;
use strict;
use warnings;
use base 'Net::Azure::CognitiveServices::Face::Base';

sub path {'/face/v1.0'};

sub _detect_request {
    my ($self, $image_url, %param) = @_;
    my %query = (
        returnFaceId         => defined $param{returnFaceId}         ? $param{returnFaceId} : 'true',
        returnFaceLandmarks  => defined $param{returnFaceLandmarks}  ? $param{returnFaceLandmarks} : 'false',
        returnFaceAttributes => defined $param{returnFaceAttributes} ? join(',', @{$param{returnFaceAttributes}}) : '',
    );
    $self->build_request(POST => ['detect', %query], undef, {url => $image_url});
}

sub detect {
    my ($self, $image_url, %param) = @_;
    my $req = $self->_detect_request($image_url, %param);
    $self->request($req);
}

sub _find_similar_request {
    my ($self, %param) = @_;
    $self->build_request(POST => ['findsimilars'], undef, {%param});
}

sub find_similar {
    my ($self, %param) = @_;
    my $req = $self->_find_similar_request(%param);
    $self->request($req);
}

sub _group_request {
    my ($self, %param) = @_;
    $self->build_request(POST => ['group'], undef, {%param});
}

sub group {
    my ($self, %param) = @_;
    my $req = $self->_group_request(%param);
    $self->request($req);
}

sub _identify_request {
    my ($self, %param) = @_;
    $self->build_request(POST => ['identify'], undef, {%param});
}

sub identify {
    my ($self, %param) = @_;
    my $req = $self->_identify_request(%param);
    $self->request($req);
}

sub _verify_request {
    my ($self, %param) = @_;
    $self->build_request(POST => ['verify'], undef, {%param});
}

sub verify {
    my ($self, %param) = @_;
    my $req = $self->_verify_request(%param);
    $self->request($req);
}

1;

__END__

=encoding utf-8

=head1 NAME

Net::Azure::CognitiveServices::Face::Face - Face API class of Cognitive Services API

=head1 DESCRIPTION

Face API wrapper.

=head1 METHODS

=head2 detect

Send "Detect" request and fetch result as arrayref.

    my $result = $obj->detect($image_url, 
        returnFaceAttributes => ['age', 'gender'],
        returnFaceLandmarks  => 'true',
    );
    say join "\n", map { $_->{faceId} } @$result; ## output faceId list

Please see L<https://dev.projectoxford.ai/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236> for detail.

=head2 find_similar

Send "Find Similar" request and fetch result as arrayref.

    my $result = $obj->find_similar(
        faceId                     => "c5c24a82-6845-4031-9d5d-978df9175426",
        faceListId                 => "sample_list",  
        maxNumOfCandidatesReturned => 10,
        mode                       => "matchPerson"
    );
    say join "\n", map {$_->{persistedFaceId}} @$result; ## output persistedFaceId list

Please see L<https://dev.projectoxford.ai/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395237> for detail.

=head2 group

Send "Group" request and fetch result as hashref.

    my $result = $obj->find_similar(
        faceIds => [
            "c5c24a82-6845-4031-9d5d-978df9175426",
            "015839fb-fbd9-4f79-ace9-7675fc2f1dd9",
            "65d083d4-9447-47d1-af30-b626144bf0fb",
            "fce92aed-d578-4d2e-8114-068f8af4492e",
            "30ea1073-cc9e-4652-b1e3-d08fb7b95315",
            "be386ab3-af91-4104-9e6d-4dae4c9fddb7",
            "fbd2a038-dbff-452c-8e79-2ee81b1aa84e",
            "b64d5e15-8257-4af2-b20a-5a750f8940e7",
        ],
    );

Please see L<https://dev.projectoxford.ai/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395238> for detail.

=head2 identify

Send "Identify" request and fetch result as hashref.

    my $result = $obj->identify(
        faceIds => [
            "c5c24a82-6845-4031-9d5d-978df9175426",
            "65d083d4-9447-47d1-af30-b626144bf0fb"
        ],
        personGroupId              => sample_group",
        maxNumOfCandidatesReturned => 1,
        confidenceThreshold        => 0.5
    );

Please see L<https://dev.projectoxford.ai/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395239> for detail.

=head2 verify

Send "Verify" request and fetch result as hashref.

    my $result = $obj->verify(
        faceId        => "c5c24a82-6845-4031-9d5d-978df9175426",
        peronId       => "815df99c-598f-4926-930a-a734b3fd651c",
        personGroupId => "sample_group"
    );

Please see L<https://dev.projectoxford.ai/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f3039523a> for detail.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut