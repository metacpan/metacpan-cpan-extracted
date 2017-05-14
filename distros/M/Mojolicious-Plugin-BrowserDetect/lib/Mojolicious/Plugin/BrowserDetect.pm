package Mojolicious::Plugin::BrowserDetect;

# ABSTRACT: HTTP::BrowserDetect integration for Mojolicious

use Mojo::Base 'Mojolicious::Plugin';

use HTTP::BrowserDetect;


my $key = 'HTTP::BrowserDetect';


sub register {
    my ($self, $app, $conf) = @_;

    $app->helper(
        browser => sub {
            my ($c) = @_;
            unless ($c->stash($key)) {
                $c->stash(
                    $key => HTTP::BrowserDetect->new(
                        $c->req->headers->user_agent,
                    ),
                );
            };
            return $c->stash($key);
        },
    ); 
}

1;



__END__
=pod

=head1 NAME

Mojolicious::Plugin::BrowserDetect - HTTP::BrowserDetect integration for Mojolicious

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  # in your App module
  $self->plugin('browser_detect');

  # in your Mojolicious controller
  $self->browser->...

  # e. g. in your root/index action
  if ($self->browser->mobile) {
      return $self->redirect_to('/mobile');
  }

=head1 DESCRIPTION

This Mojolicious plugin integrates L<HTTP::BrowserDetect>.

=head1 SEE ALSO

L<HTTP::BrowserDetect>

=head1 AUTHOR

Uwe Voelker <uwe@uwevoelker.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Uwe Voelker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

