package Parley::Controller::Help;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;
use base 'Catalyst::Controller';

use Parley::App::I18N qw( :locale );

sub index : Private {
    my ( $self, $c ) = @_;
    $c->stash->{template} =
          q{help/}
        . first_valid_locale($c, [qw/base help/])
        . q{/contents}
}

sub default :Private {
    my ($self, $c) = @_;
    my $help_template;

    # the section / page to show is derived from the URI
    $help_template = $c->request->arguments->[1];

    # set the template to use based on the URI
    $c->stash->{template} =
          q{help/}
        . first_valid_locale($c, [qw/base help/])
        . q{/}
        . $help_template;
    # send to the view
    $c->forward('Parley::View::TT');

    # deal with errors (i.e. missing templates)
    if ($c->error and $c->error->[0]) {
        # only show the "unknown help section" page if we couldn't find the
        # page to show
        my $template_name = $c->stash->{template};
        if ($c->error->[0] =~ m{file error - $template_name: not found}ms) {
            $c->clear_errors;
            $c->stash->{template_name} = $template_name;
            $c->forward( 'unknown' );
        }
    }
}

sub unknown :Local {
    my ($self, $c) = @_;
    $c->stash->{template} = 'help/unknown';
}

=head1 NAME

Parley::Controller::Help - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 index 

=head1 AUTHOR

Chisel Wright C<< <chiselwright@users.berlios.de> >>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
