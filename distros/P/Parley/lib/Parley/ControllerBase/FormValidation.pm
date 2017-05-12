package Parley::ControllerBase::FormValidation;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;

use base 'Catalyst::Controller';

sub check_unique_username :Private {
    my ($self, $c, $username_field) = @_;
    my ($count);

    # if we haven't checked the form yet, we can't add to the results
    if (not defined $c->stash->{validation}) {
        carp('form must be validated first');
        return;
    }

    # see how many matches we have for the value in the (supplied) username
    # field
    $count = $c->model('Authentication')->count(
        { username => $c->stash->{validation}->valid($username_field) }
    );

    # set a validation error if we've already got one
    if ($count > 0) {
        $c->forward(
            'add_form_invalid',
            [ $username_field, q{username-not-unique} ]
        );
    }

    return;
}

sub check_unique_forumname :Private {
    my ($self, $c, $forumname_field) = @_;
    my ($count);

    $c->log->debug( $forumname_field );
    $c->log->debug( $c->stash->{validation}->valid($forumname_field) );

    # if we haven't checked the form yet, we can't add to the results
    if (not defined $c->stash->{validation}) {
        carp('form must be validated first');
        return;
    }

    # see how many matches we have for the value in the (supplied) forumname
    # field
    $count = $c->model('Person')->count(
        { forum_name => $c->stash->{validation}->valid($forumname_field) }
    );

    # set a validation error if we've already got one
    if ($count > 0) {
        $c->forward(
            'add_form_invalid',
            [ $forumname_field, q{forumname-not-unique} ]
        );
    }

    return;
}

1;

__END__
