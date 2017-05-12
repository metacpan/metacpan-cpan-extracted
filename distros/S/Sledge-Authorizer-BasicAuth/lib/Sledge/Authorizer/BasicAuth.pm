package Sledge::Authorizer::BasicAuth;
use strict;
use warnings;
use base qw(Sledge::Authorizer Class::Data::Inheritable);
use 5.008001;

our $VERSION = '0.07';

use MIME::Base64 qw//;

__PACKAGE__->mk_classdata('error_template');
__PACKAGE__->mk_classdata(realm => 'Authorization Required');

sub basic_auth {
    my $self  = shift;
    my $page  = shift;

    my $auth_header = $page->r->header_in('Authorization') || '';
    if ($auth_header =~ /^Basic (.+)$/) {
        my ($user, $pass) = split q{:}, MIME::Base64::decode_base64($1);
        if (defined $user and defined $pass) {
            return ($user, $pass);
        }
    }
    return $self->show_error_page($page);
}

sub show_error_page {
    my $self = shift;
    my $page = shift;

    $page->load_template($self->error_template);

    my $realm = $self->realm;
    $page->r->header_out('WWW-Authenticate' => qq{Basic realm="$realm"});
    $page->r->status(401);

    $page->output_content;
}

1;
__END__

=head1 NAME

Sledge::Authorizer::BasicAuth - Basic Authentication module for Sledge

=head1 SYNOPSIS

  package Your::Authorizer;
  use base qw(Sledge::Authorizer::BasicAuth);
  use Your::Data::User;

  __PACKAGE__->error_template('/401.html');
  __PACKAGE__->realm('SECRET PAGE');

  sub authorize {
      my $self = shift;
      my $page = shift;
     
      return if $page->session->param('user');
     
      my ($login_id, $passwd) = $self->basic_auth($page) or return;
     
      my $user = Your::Data::User->search(login_id => $login_id, passwd => $passwd)->first;
      if ($user) {
          $page->session->param(user => $user);
      } else {
          $self->show_error_page($page);
      }
  }

=head1 DESCRIPTION

Sledge::Authorizer::BasicAuth is Basic Authentication module for Sledge.

=head1 AUTHOR

MATSUNO Tokuhiro E<lt>tokuhirom@gmail.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 THANKS TO

Tatsuhiko Miyagawa.

=head1 SEE ALSO

L<Bundle::Sledge>

=cut
