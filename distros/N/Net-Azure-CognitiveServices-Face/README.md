[![Build Status](https://travis-ci.org/ytnobody/p5-Net-Azure-CognitiveServices-Face.svg?branch=master)](https://travis-ci.org/ytnobody/p5-Net-Azure-CognitiveServices-Face)
# NAME

Net::Azure::CognitiveServices::Face - A wrapper class for Face API of Azure Cognitive Services

# SYNOPSIS

    use Net::Azure::CognitiveServices::Face;
    Net::Azure::CognitiveServices::Face->endpoint('https://westus.api.cognitive.microsoft.com/face/v1.0');
    Net::Azure::CognitiveServices::Face->access_key('YOUR_ACCESS_KEY');

    ### Face - Detect
    my $face_api = Net::Azure::CognitiveServices::Face->Face;
    my $result = $face_api->detect(
        "http://example.com/photo.jpg", 
        returnFaceAttributes => ['age', 'gender'],
    );
    printf "age: %d, gender: %d\n", $result->[0]{faceAttributes}{age}, $result->[0]{faceAttributes}{gender};
    
    ### Person - List Persons in a PersonGroup
    my $person_api = Net::Azure::CognitiveServices::Face->Person;
    $result = $person_api->list('my_person_group');
    for my $person (@$result) {
        printf "name: %s, personId: %s\n", $person->{name}, $person->{personId};
    }

# DESCRIPTION

Net::Azure::CognitiveServices::Face provides following subclasses.

- Net::Azure::CognitiveServices::Face::Face
- Net::Azure::CognitiveServices::Face::FaceList
- Net::Azure::CognitiveServices::Face::Person
- Net::Azure::CognitiveServices::Face::PersonGroup

Please see [https://westus.dev.cognitive.microsoft.com/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236](https://westus.dev.cognitive.microsoft.com/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236) for more information. 

# METHODS

## endpoint

Set the endpoint url for accessing to Azure Cognitive Services APIs

## access\_key

Set the access key for accessing to Azure Cognitive Services APIs

## Face

Returns an instance of Net::Azure::CognitiveServices::Face::Face

## FaceList

Returns an instance of Net::Azure::CognitiveServices::Face::FaceList

## Person

Returns an instance of Net::Azure::CognitiveServices::Face::Person

## PersonGroup

Returns an instance of Net::Azure::CognitiveServices::Face::PersonGroup

# LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ytnobody <ytnobody@gmail.com>
