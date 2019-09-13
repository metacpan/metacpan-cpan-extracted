package Rapi::Blog::Controller::Remote::PreauthAction;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

__PACKAGE__->config( namespace => 'remote/preauth_action' );

use strict;
use warnings;

use RapidApp::Util ':all';
use Rapi::Blog::Util;

sub index :Path :Args(1) {
  my ($self, $c, $key) = @_;
  
  my $Actor = $c
    ->model('DB::PreauthAction')
    ->request_Actor($c,$key);
    
  $Actor->call_execute;
  
  if (my $url = $Actor->redirect_url) {
    $url =~ s/^\///;
    return $c->res->redirect( join('/', $c->mount_url, $url), 307 );
  }
  
  my $tpl = $Actor->render_template or die "Error - Actor has neither redirect or render instructions, this is a bug";
  
  return $c->detach( '/rapidapp/template/view', [$tpl] );
}



__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Rapi::Blog::Controller::Remote::PreauthAction - Pre-Authorized Actions Controller

=head1 DESCRIPTION

This controller handles valid Pre-Authorized Actions, such as password_reset, and other
specific, single-use actions which can be triggered by any remote user who knows the
secret C<auth_key> for the action

=head1 SEE ALSO

=over

=item * 

L<Rapi::Blog>

=item * 

L<Catalyst::Controller>

=back


=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

