package Net::Google::Calendar::Server::Auth::Dummy;

use strict;
use base qw(Net::Google::Calendar::Server::Auth);
use Digest::MD5 qw(md5_hex);

=head1 NAME

Net::Google::Calendar::Server::Auth::Dummy - the most basic authentication module for Net::Google::Calendar::Server

=cut

=head1 METHODS

=head2 validate <email> <pass>

Return a validation token.

=cut

sub validate {
    my $self  = shift;
    my $email = shift;
    my $pass  = shift;

    return md5_hex("$email:$pass"); 
}


=head2 auth <key>

Return 1 if the authetication key is correct.

=cut

sub auth {
    my $self = shift;
    my $key  = shift;

    return 1;

}

=head2 magic_cookie_auth <email> <cookie>

Return 1 if the email and magic cookie auth are correct. 

=cut

sub magic_cookie_auth {
	my $self   = shift;
	my $email  = shift;
	my $cookie = shift;
	
	return 1;
}

1;
