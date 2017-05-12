package Catalyst::Controller::FormValidator;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use version; our $VERSION = qv(0.0.1)->numify;

use base 'Catalyst::Controller';

use Carp;
use Data::Dump qw(pp);
use Data::FormValidator '4.50';
use Data::FormValidator::Constraints qw(:closures);

sub form_check :Private {
    my ($self, $c, $dfv_profile, $param_type) = @_;
    my $parameters;

    # Which parameters? GET / POST or "all"?
    # - POST [default]
    if (
        not defined $param_type
            or
        q{POST} eq $param_type
    ) {
        $parameters = $c->request->body_parameters;
    }
    # - GET
    elsif (q{GET} eq $param_type) {
        $parameters = $c->request->query_parameters;
    }
    # - "all"
    elsif (q{all} eq $param_type) {
        $parameters = $c->request->parameters;
    }

    my $results = Data::FormValidator->check(
        $parameters,
        $dfv_profile
    );

    # if we have any failures ...
    #if ($results->has_invalid or $results->has_missing) {
        $c->stash->{validation} = $results;
        #}

    return;
}

sub add_form_invalid :Private {
    my ($self, $c, $invalid_key, $invalid_value) = @_;

    # if we haven't checked hte form yet, we can't add to the results
    if (not defined $c->stash->{validation}) {
        carp('form must be validated first');
        return;
    }

    # the invalids are a keyed list of constraint names
    push
        @{ $c->stash->{validation}{invalid}{$invalid_key} },
        $invalid_value
    ;

    return;
}

sub validation_errors_to_html :Private {
    my ($self, $c) = @_;
}

1;

__END__

=pod

=head1 NAME

Catalyst::Controller::FormValidator - check form data

=head1 SUMMARY

Form-validation using a Catalyst controller and Data::FormValidator

=head1 SYNOPSIS

    use base 'Catalyst::Controller::FormValidator';
    use Data::FormValidator::Constraints qw(:closures);

    # define a DFV profile
    my $dfv_profile = {
        required => [qw<
            email_address
            phone_home
            phone_mobile
        >],

        constraint_methods => {
            email_address   => email(),
            phone_home      => american_phone(),
            phone_mobile    => american_phone(),
        },
    };

    # check the form for errors
    $c->forward('form_check', [$dfv_profile]);

    # perform custom/complex checking and
    # add to form validation failures
    if (not is_complex_test_ok()) {
        $c->forward(
            'add_form_invalid',
            [ $error_key, $error_constraint_name ]
        );
    }

=head1 AUTHOR

Chisel Wright

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
