
package Slackware::Slackget::GPG::Signature;

use warnings;
use strict;

=head1 NAME

Slackware::Slackget::GPG::Signature - A simple class to represent an output of gpg signature verification.

=head1 VERSION

Version 0.5

=cut

our $VERSION = '0.5';

=head1 SYNOPSIS

A simple class to represent an output of gpg signature verification. This class parse the output of the 'gpg' command line tool.

    use Slackware::Slackget::GPG::Signature;

    my $slackget_gpg_signature_object = Slackware::Slackget::GPG::Signature->new();

=cut

=head1 CONSTRUCTOR

new() : The constructor take the followings arguments :

	- key_id : the id of the key which have been use to sign the file

	- warnings : an array reference which contains all 

	- status : GOOD, BAD or UNKNOW the status of the verification

	- date : date the signature was made

	- emitter : the signature emitter.

	- fingerprint : the primary key fingerprint.



=cut

sub new
{
	my ($class,%args) = @_ ;
	my $self={};
	$self->{DATA}->{key_id} = undef ;
	$self->{DATA}->{key_id} = $args{key_id} if(exists($args{key_id}) && defined($args{key_id})); 
	$self->{DATA}->{'warnings'} = [] ;
	$self->{DATA}->{'warnings'} = $args{warnings} if(exists($args{warnings}) && defined($args{warnings}));
	$self->{DATA}->{status} = undef ;
	$self->{DATA}->{status} = $args{status} if(exists($args{status}) && defined($args{status}));
	$self->{DATA}->{date} = undef ;
	$self->{DATA}->{date} = $args{date} if(exists($args{date}) && defined($args{date}));
	$self->{DATA}->{emitter} = undef ;
	$self->{DATA}->{emitter} = $args{emitter} if(exists($args{emitter}) && defined($args{emitter}));
	$self->{DATA}->{fingerprint} = undef ;
	$self->{DATA}->{fingerprint} = $args{fingerprint} if(exists($args{fingerprint}) && defined($args{fingerprint}));
	bless($self,$class);
	return $self;
}

=head1 METHODS

=head2 is_good

True if the signature is good, false otherwise.

=cut

sub is_good
{
	my ($self) = @_;
	return ($self->{DATA}->{status} eq 'GOOD') ? 1 : 0 ;
}



=head1 ACCESSORS


=head2 key_id

Accessor for the key_id constructor's parameter. Return a scalar.

=cut

sub key_id
{
	return $_[1] ? $_[0]->{DATA}->{key_id}=$_[1] : $_[0]->{DATA}->{key_id};
}

=head2 warnings

Accessor for the warnings constructor's parameter. Return a hashref.

=cut

sub warnings
{
	return $_[1] ? $_[0]->{DATA}->{'warnings'}=$_[1] : $_[0]->{DATA}->{'warnings'};
}

=head2 status

Accessor for the status constructor's parameter. Return a scalar.

=cut

sub status
{
	return $_[1] ? $_[0]->{DATA}->{status}=$_[1] : $_[0]->{DATA}->{status};
}

=head2 date

Accessor for the date constructor's parameter. Return a scalar.

=cut

sub date
{
	return $_[1] ? $_[0]->{DATA}->{date}=$_[1] : $_[0]->{DATA}->{date};
}

=head2 emitter

Accessor for the emitter constructor's parameter. Return a scalar.

=cut

sub emitter
{
	return $_[1] ? $_[0]->{DATA}->{emitter}=$_[1] : $_[0]->{DATA}->{emitter};
}

=head2 fingerprint

Accessor for the fingerprint constructor's parameter. Return a scalar.

=cut

sub fingerprint
{
	return $_[1] ? $_[0]->{DATA}->{fingerprint}=$_[1] : $_[0]->{DATA}->{fingerprint};
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

    perldoc Slackware::Slackget::GPG::Signature


You can also look for information at:

=over 4

=item * Infinity Perl website

L<http://www.infinityperl.org>

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

=head1 SEE ALSO

=head1 COPYRIGHT & LICENSE

Copyright 2005 DUPUIS Arnaud, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # Fin de Slackware::Slackget::GPG::Signature

