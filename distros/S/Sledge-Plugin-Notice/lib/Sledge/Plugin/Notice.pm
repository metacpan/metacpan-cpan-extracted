package Sledge::Plugin::Notice;

use strict;
use warnings;

our $VERSION = '0.03';

use Carp ();

sub import {
    my $class = shift;
    my $caller = caller;
    unless ($caller->isa('Sledge::Pages::Base')) {
        Carp::carp('use it from Sledge::Pages.');
        return;
    }
    my $sess_key = __PACKAGE__.'::notice';
    $caller->register_hook(
        AFTER_DISPATCH => sub {
            my $self = shift;
            my $notice = $self->notice;
            $self->tmpl->param(notice => $notice) if $notice;
        },
        AFTER_OUTPUT => sub {
            my $self = shift;
            $self->session->remove($sess_key);
        },
    );
    no strict 'refs';
    *{"$caller\::notice"} = sub {
        my $self = shift;
        if (@_ == 0) {
            return $self->session->param($sess_key);
        } elsif (@_ == 1) {
            $self->session->param($sess_key => $_[0]);
        }
    };
}

1;
__END__

=head1 NAME

Sledge::Plugin::Notice - show one-time message

=head1 SYNOPSIS

  # in your Sledge::Pages
  use Sledge::Plugin::Notice;
  sub post_dispatch_foo {
      my $self = shift;
      # do something..
      $self->notice('Item was successfully created.');
      $self->redirect('bar');
  }
  # in your template
  [% IF notice %]<h2>[% notice %]</h2>[% END %]

=head1 DESCRIPTION

Sledge::Plugin::Notice is a plugin for Sledge to show one-time message. 

=head1 SEE ALSO

L<Bundle::Sledge>

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
