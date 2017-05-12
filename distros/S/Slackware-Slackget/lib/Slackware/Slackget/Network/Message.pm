package Slackware::Slackget::Network::Message ;

use warnings;
use strict;

=head1 NAME

Slackware::Slackget::Network::Message - The response object for Slackware::Slackget::Network class

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '0.9.1';

=head1 SYNOPSIS

This class is the message object used by the Slackware::Slackget::Network class to return informations from the network connection.

This module is the evolution of the old Slackware::Slackget::Network::Response.

=cut

=head2 new

the constructor require no argument. But store every given argument in the object (which is a hashref).

	my $msg = new Slackware::Slackget::Network::Message ;

=cut

sub new
{
	my $class = shift;
	my $self = {@_};
	bless($self,$class);
	return $self;
}

=head2 new_from_data

This is an alternative constructor to create a Slackware::Slackget::Network::Message with the whole slack-get protocol compatible data structure.

You must provide the following arguments :

	* an action id (integer)
	* a action (string)
	* some data

Here is a little example :

	my $msg = Slackware::Slackget::Network::Message->new(
		123456789,
		'search',
		@keywords,
	);

=cut

sub new_from_data {
	my $class = shift;
	my $action_id = shift;
	my $action = shift;
	my @data = @_;
	my $self = {};
# 	my $self = {
# 		raw_data => {
# 				Enveloppe => {
# 					Action => {
# 						id => $action_id ,
# 						content => $action,
# 					},
# 					Data => {
# 						content => join('',@_),
# 					},
# 				}
# 			}
# 	};
	bless($self,$class);
	$self->create_enveloppe();
	$self->{raw_data}->{Enveloppe}->{Action}->{id} = $action_id;
	$self->{raw_data}->{Enveloppe}->{Action}->{content} = $action;
	$self->{raw_data}->{Enveloppe}->{Data}->{content} = join('',@data);
	return $self;
}

=head2 create_enveloppe

Create a base enveloppe for the SlackGetProtocol in the raw_data section. This method access directly to the object's data structure.

Be carefull not to use it on an already initialized object. Else all "raw_data" will be lost.

	$self = {
		action => 0,
		action_id => 0,
		raw_data => {
				Enveloppe => {
					Action => {
						id => 0 ,
						content => 0,
					},
					Data => {},
				}
			}
	};

=cut

sub create_enveloppe {
	my $self = shift;
	$self->action(0);
	$self->action_id(0);
	$self->{raw_data} =  {
		Enveloppe => {
			Action => {
				id => 0 ,
				content => 0,
			},
			Data => {},
		}
	};
}

=head2 is_success

true if the operation is a success

=cut

sub is_success {
	my $self = shift;
	my $data = shift;
	return $data ? $self->{is_success}=$data : $self->{is_success};
}

=head2 is_error

true if the operation is an error

=cut

sub is_error {
	my $self = shift;
	return !$self->{is_success} ;
}

=head2 error_msg

return a string containing an error message. Works only if $response->is_error() is true.

=cut

sub error_msg {
	my $self = shift;
	my $data = shift;
	return $data ? $self->{error_msg}=$data : $self->{error_msg};
}

=head2 have_choice

true if the daemon return a choice

=cut

sub have_choice {
	my $self = shift;
	my $data = shift;
	return $data ? $self->{have_choice}=$data : $self->{have_choice};
}

=head2 data

return all raw data returned by the remote daemon

=cut

sub data {
	my $self = shift;
	my $data = shift;
	return $data ? $self->{raw_data}=$data : $self->{raw_data};
}

=head2 action

return (or set) the action of the message (all network messages must have an action).

=cut

sub action{
	my $self = shift;
	my $data = shift;
	if($data){
		$self->{raw_data}->{Enveloppe}->{Action}->{content} = $data if(exists($self->{raw_data}->{Enveloppe}->{Action}) && ref($self->{raw_data}->{Enveloppe}->{Action}) eq 'HASH' );
		 $self->{action}=$data
	}else{
		return $self->{action};
	}
}

=head2 action_id

return (or set) the action ID of the message (all network messages must have an action id).

=cut

sub action_id{
	my $self = shift;
	my $data = shift;
	if($data){
		$self->{raw_data}->{Enveloppe}->{Action}->{id} = $data if(exists($self->{raw_data}->{Enveloppe}->{Action}) && ref($self->{raw_data}->{Enveloppe}->{Action}) eq 'HASH' );
		 $self->{action_id}=$data
	}else{
		return $self->{action_id};
	}
}


=head1 AUTHOR

DUPUIS Arnaud, C<< <a.dupuis@infinityperl.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-Slackware-Slackget@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Slackware-Slackget>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Slackware::Slackget


You can also look for information at:

=over 4

=item * Infinity Perl website

L<http://www.infinityperl.org/category/slack-get>

=item * slack-get specific website

L<http://slackget.infinityperl.org>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Slackware-Slackget>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Slackware-Slackget>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Slackware-Slackget>

=item * Search CPAN

L<http://search.cpan.org/dist/Slackware-Slackget>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Bertrand Dupuis (yes my brother) for his contribution to the documentation.

=head1 COPYRIGHT & LICENSE

Copyright 2005 DUPUIS Arnaud, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Slackware::Slackget::Network::Message