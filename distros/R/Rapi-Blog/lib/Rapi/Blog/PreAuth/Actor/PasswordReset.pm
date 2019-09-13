package Rapi::Blog::PreAuth::Actor::PasswordReset;
use strict;
use warnings;

use Moo;
extends 'Rapi::Blog::PreAuth::Actor';

use Types::Standard qw(:all);

use RapidApp::Util ':all';
use Rapi::Blog::Util;



sub execute {
  my $self = shift;
  
  my $params = $self->req_params;
  
  my $pw = $params->{new_password} or die "new_password not supplied.";
  
  my $User = $self->PreauthAction->user or die "Failed to get user row.";
  
  $User->update({ set_pw => $pw })

}





1;


__END__

=head1 NAME

Rapi::Blog::PreAuth::Actor::PasswordReset - Handles password_reset


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

This software is copyright (c) 2018 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
