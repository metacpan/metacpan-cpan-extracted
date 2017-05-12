package Mojolicious::Plugin::FillInFormLite;
use 5.008005;
use Mojo::Base 'Mojolicious::Plugin';

use HTML::FillInForm::Lite;

our $VERSION = "0.02";


sub register {
    my ($self, $app, $conf) = @_;

    $conf ||= {};

    $app->helper(render_fillinform => sub {
        my $c = shift;
        my $params = shift;

        my $html = $c->render(partial => 1, 'mojo.to_string' => 1, @_);
        my $fill = HTML::FillInForm::Lite->new(
            fill_password => 1,
            %$conf,
        );

        $c->render(
            text => $fill->fill(\$html, $params),
            format => 'html',
        );
    });
}


1;
__END__

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::FillInForm - Mojolicious plugin to fill in form.

=head1 SYNOPSIS

    # Mojolicious::Lite
    plugin('FillInFormLite');

    # Mojolicious
    $app->plugin('FillInFormLite');

    # Controller
    my %filled = (name => 'John');
    $c->render_fillinform(\%filled);

=head1 DESCRIPTION

Mojolicious::Plugin::FillInForm is Mojolicious plugin to fill in form.

=head1 LICENSE

Copyright (C) Uchiko.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Uchiko E<lt>memememomo@gmail.comE<gt>

=cut

