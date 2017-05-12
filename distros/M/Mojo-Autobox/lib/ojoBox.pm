package ojoBox;

require ojo;
require Mojo::Autobox;

sub import {
  Mojo::Autobox->import;
  goto &ojo::import;
}

1;

=head1 NAME

ojoBox - One-liners with the powers of ojo and Mojo::Autobox

=head1 SYNOPSIS

 $ perl -MojoBox -E 'g("http://mojolicio.us")->dom->find("a")->each(sub{$_->{href}->url->host->b->say})'

=head1 DESCRIPTION

Enables L<Mojo::Autobox> and L<ojo> for use in one-liners.

