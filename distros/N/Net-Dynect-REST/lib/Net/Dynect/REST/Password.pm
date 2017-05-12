package Net::Dynect::REST::Password;
# $Id: Password.pm 149 2010-09-26 01:33:15Z james $
use strict;
use warnings;
use Carp;
use Net::Dynect::REST::RData;
our $VERSION = do { my @r = (q$Revision: 149 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

=head1 NAME 

Net::Dynect::REST::Password - Find all records matching a name

=head1 SYNOPSIS

  use Net::Dynect::REST:Password;
  my @records = Net::Dynect::REST:Password->set(connection => $dynect, 
                                           password=> $secret);

=head1 METHODS

=head2 Creating

=over 4

=item  Net::Dynect::REST:Password->set(connection => $dynect, password => $secret);

This will return an array of objects that match the Name and Zone.

=cut

sub set {
    my $proto = shift;
    my %args  = @_;
    if (
        not( defined( $args{connection} )
            && ref( $args{connection} ) eq "Net::Dynect::REST" )
      )
    {
        carp "Need a connection (Net::Dynect::REST)";
        return;
    }
    if ( not( defined $args{password} ) ) {
        carp "Need a new password";
        return;
    }

    my $request = Net::Dynect::REST::Request->new(
        operation => 'update',
        service   => sprintf( __PACKAGE__->_service_base_uri ),
        params => { password => $args{password}}
    );
    if ( not $request ) {
        carp "Request not valid: $request";
        return;
    }

    my $response = $args{connection}->execute($request);

    if ( not $response ) {
        carp "Response not valid: $response";
        return;
    }

    if ( $response->status !~ /^success$/i ) {
        carp $response->status;
        return;
    }
    return $response->data;
}


sub _service_base_uri {
  return "Password";
}

1;

=back

=head1 AUTHOR

James Bromberger, james@rcpt.to

=head1 SEE ALSO

L<Net::Dynect::REST>, L<Net::Dynect::REST::Request>, L<Net::Dynect::REST::Response>, L<NetLLDynect::REST::info>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by James Bromberger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
