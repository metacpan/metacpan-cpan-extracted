package Nephia::Plugin::FillInForm;
use 5.008005;
use strict;
use warnings;
use parent 'Nephia::Plugin';
use HTML::FillInForm;

our $VERSION = "0.20";

sub new {
    my ($class, %opts) = @_;
    my $self = $class->SUPER::new(%opts);
    $self->app->action_chain->append(FillInForm => $class->can('_fillin'));
    return $self;
}

sub exports { qw/ fillin_form / };

sub fillin_form {
    my ($self, $context) = @_;
    sub {
        my $params = shift;
        $context->set(fillin => $params);
    };
}

sub _fillin {
    my ($app, $context) = @_;
    my $params = $context->get('fillin');
    if ($params) {
        my $res = $context->get('res');
        if (ref($res->body) eq 'ARRAY') {
            my $body = $res->body->[0];
            $res->body->[0] = HTML::FillInForm->fill(\$body, $params);
        }
        else {
            my $body = $res->body;
            $res->body(HTML::FillInForm->fill(\$body, $params));
        }
    }
    return $context;
}

1;
__END__

=encoding utf-8

=head1 NAME

Nephia::Plugin::FillInForm - A plugin for Nephia that provides fill-in-form feature

=head1 SYNOPSIS

    use Nephia plugins => [
        'FillInForm',
        'View::MicroTemplate' => { ... },
    ];
    path '/' => sub {
        my $params = param;
        fillin_form( $params ); # fill params in form
        render('template.html');
    };

=head1 DESCRIPTION

Nephia::Plugin::FillInForm provides fill-in-form feature.

=head1 DSL

=head2 fillin_form

    fillin_form( $hashref );

Fill spedified value in form.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

