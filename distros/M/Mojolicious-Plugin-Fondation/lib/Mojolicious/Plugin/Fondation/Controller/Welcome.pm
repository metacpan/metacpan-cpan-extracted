package Mojolicious::Plugin::Fondation::Controller::Welcome;
$Mojolicious::Plugin::Fondation::Controller::Welcome::VERSION = '0.03';
# ABSTRACT: Welcome page controller with language-aware template selection

use Mojo::Base 'Mojolicious::Plugin::Fondation::Controller::Base', -signatures;

sub index ($self) {
    $self->render_later;
    my $c    = $self;
    my $lang = $c->stash('i18n_lang');
    unless ($lang) {
        ($lang) = ($c->req->headers->accept_language // '') =~ /^([a-z]{2})/i;
        $lang //= 'en';
    }

    # Only 'en' and 'fr' exist; fall back to 'en' for anything else
    $lang = 'en' unless $lang eq 'fr';

    $c->render(template => "welcome_$lang");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Controller::Welcome - Welcome page controller with language-aware template selection

=head1 VERSION

version 0.03

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
