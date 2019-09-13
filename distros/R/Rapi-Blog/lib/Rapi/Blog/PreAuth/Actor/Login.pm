package Rapi::Blog::PreAuth::Actor::Login;
use strict;
use warnings;

use Moo;
extends 'Rapi::Blog::PreAuth::Actor';

use Types::Standard qw(:all);

use RapidApp::Util ':all';
use Rapi::Blog::Util;



sub execute {
  my $self = shift;
  my $c = RapidApp->active_request_context or die "Unable to get Catlyst context - you're only calling this during a request, right?";
  
  #$c->delete_expired_sessions;
  try{$c->logout};
  
  my $BlogUser = $self->PreauthAction->user or die "Failed to get user row.";
  my $user = $BlogUser->username;
  
  my $uObj = $c->find_user({ username => $user }) or die "Failed to get Catalyst Auth user object";
  
  $c->set_authenticated( $uObj ) or die "->set_authenticated(): unknown error occured";

  # -----
  # This comes directly from Auth::do_login
  $c->session->{RapidApp_username} = $user;
    
  # New: set the X-RapidApp-Authenticated header now so the response
  # itself will reflect the successful login (since in either case, the
  # immediate response is a simple redirect). This is for client info/debug only
  $c->res->header('X-RapidApp-Authenticated' => $c->user->username);

  $c->log->info("Successfully authenticated user '$user'") if ($c->debug);
  $c->user->update({ 
    last_login_ts => DateTime->now( time_zone => 'local' ) 
  });
  
  # Something is broken!
  $c->_save_session_expires;
  # -----
  
}



1;


__END__

=head1 NAME

Rapi::Blog::PreAuth::Actor::Login - Single-use user login


=head1 DESCRIPTION

This is an internal class and is not intended to be used directly. 

=head1 SEE ALSO

=over

=item * 

L<Rapi::Blog>

=back

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
