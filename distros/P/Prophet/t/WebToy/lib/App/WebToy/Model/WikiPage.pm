package App::WebToy::Model::WikiPage;
use Any::Moose;
extends 'Prophet::Record';
has type => ( default => 'wikipage' );

sub declared_props {qw(title content tags mood)}

sub default_prop_content {
    'This page has no content yet';
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

