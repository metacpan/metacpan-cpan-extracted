
package Slackware::Slackget::GPG;

use warnings;
use strict;
use Slackware::Slackget::GPG::Signature ;
use constant {
	SIG_GOOD => 'GOOD',
	SIG_BAD => 'BAD',
	SIG_UNKNOW => 'UNKNOW',
};

=head1 NOM

Slackware::Slackget::GPG - A simple wrapper class to the gpg binary

=head1 VERSION

Version 0.4

=cut

our $VERSION = '0.4';

=head1 SYNOPSIS

A simple class to verify files signatures with gpg.

    use Slackware::Slackget::GPG;

    my $slackware_slackget_gpg_object = Slackware::Slackget::GPG->new();

=cut

=head1 CONSTRUCTOR

new() : The constructor take the followings arguments :

	- gpg_binary : where we can find a valid gpg binary (default: /usr/bin/gpg)



=cut

sub new
{
	my ($class,%args) = @_ ;
	my $self={};
	$self->{DATA}->{gpg_binary} = '/usr/bin/gpg' ;
	$self->{DATA}->{gpg_binary} = $args{gpg_binary} if(exists($args{gpg_binary}) && defined($args{gpg_binary}));
	bless($self,$class);
	return $self;
}

=head1 METHODS

=head2 verify_file

take a file and a signature as parameter and verify the signature of the file. Return a Slackware::Slackget::GPG::Signature object. If the status is UNKNOW, the warnings() accessor may return some interesting data.

	my $sig = $gpg->verify("/usr/local/slack-get-1.0.0-alpha1/update/signature-cache/gcc-g++-3.3.4-i486-1.tgz","/usr/local/slack-get-1.0.0-alpha1/update/package-cache/gcc-g++-3.3.4-i486-1.tgz.asc");
	die "Signature doesn't match.\n" if(!$sig->is_good) ;

=cut

sub verify_file
{
	my ($self,$file,$sig1) = @_;
	my @out = `2>&1 LC_ALL=C $self->{DATA}->{gpg_binary} --verify $sig1 $file`;
	
# 	gpg: CRC error; 040b69 - 24a901
# 	gpg: packet(3) with unknown version 3
# 
# 	gpg: Signature made Mon 14 Jun 2004 09:23:24 AM CEST using DSA key ID 40102233
# 	gpg: Good signature from "Slackware Linux Project <security@slackware.com>"
# 	gpg: WARNING: This key is not certified with a trusted signature!
# 	gpg:          There is no indication that the signature belongs to the owner.
	
# 	gpg: Signature made Mon 16 Feb 2004 07:53:35 AM CET using DSA key ID 40102233
# 	gpg: BAD signature from "Slackware Linux Project <security@slackware.com>"
	
	my $sig = new Slackware::Slackget::GPG::Signature;
	foreach (@out)
	{
# 		print "[DEBUG::GPG] $_\n";
		chomp;
		if($_ =~ /gpg: Signature made (.*) using DSA key ID (.*)/)
		{
			$sig->date($1);
			$sig->key_id($2);
		}
		if($_ =~ /gpg: CRC error;.*/)
		{
			$sig->status('BAD');
		}
		if($_ =~ /gpg: Good signature from "([^"]*)"/)
		{
			$sig->status('GOOD');
			$sig->emitter($1);
		}
		if($_ =~ /gpg: BAD signature/)
		{
			$sig->status('BAD');
		}
		if($_ =~ /gpg: BAD signature from "([^"]*)"/)
		{
			$sig->status('BAD');
			$sig->emitter($1);
		}
		if($_=~ /gpg: WARNING: (.*)/)
		{
			$sig->warnings([@{$sig->warnings()},$1]);
		}
		if($_=~ /Primary key fingerprint: ([0-9A-F\s]*)/)
		{
			$sig->fingerprint($1);
		}
		if($_=~ /gpg: verify signatures failed: (.*)/)
		{
			$sig->status('UNKNOW');
			$sig->warnings([@{$sig->warnings()},$1]);
		}
		if($_=~ /gpg: can't hash datafile: (.*)/)
		{
			$sig->status('UNKNOW');
			$sig->warnings([@{$sig->warnings()},"can't hash datafile",$1]);
		}
		
	}
	$sig->status('UNKNOW') unless($sig->status);
	return $sig;
}

=head2 import_key

Import a key file passed in parameter.

	$gpg->import_key('update/GPG-KEY') or die "unable to import official Slackware GnuPG key.\n";

Return a Slackware::Slackget::Signature object. 

The returned object is set with the status (which represent in this case, the status of the import).

On successfull import, it also set teh key_id and the emitter.

=cut

sub import_key
{
	my ($self,$key) = @_ ;
	my @out = `2>&1 LC_ALL=C $self->{DATA}->{gpg_binary} --import $key`;
	my $sig = new Slackware::Slackget::GPG::Signature;
	$sig->status('BAD');
	foreach (@out){
	# key 40102233: public key "Slackware Linux Project <security@slackware.com>" imported
		if(/gpg: key ([^:]+): public key "([^"]+)" imported/){
			$sig->status('GOOD');
			$sig->key_id($1);
			$sig->emitter($2);
		}
	}
	
	return $sig;
}

=head2 in_keyring

Return the number of keys in the keyring that match the given string.

    $gpg->in_keyring('Slackware Linux Project') or die "The GPG signature of the Slackware Linux project cannot be found in your keyring.\n";

=cut

sub in_keyring {
	my ($self, $string) = @_ ;
	my @r = ();
	foreach my $key ( $self->list_keys ){
		foreach (@{$key->{uid}}){
			push @r, $key if(/$string/);
		}
	}
	return scalar(@r);
}

=head2 list_keys

Return the list of keys in the current user's keyring.

=cut

# Put the next line in the pod when the *info methods are coded.
# To retrieve all information for a given key, use the key_info() method.

sub list_keys {
	my $self = shift;
	my @list = ();
	my @out = `2>&1 LC_ALL=C $self->{DATA}->{gpg_binary} --list-keys`;
	#pub   1024D/61BD09B3 2005-07-02
	foreach (@out){
		chomp;
		if(/^pub\s+[^\/]+\/([^\s]+)\s+.*$/){
			push @list, {key => $1, uid => []};
		}
		elsif(/^uid\s+(.+)$/){
			push @{ $list[$#list]->{uid} },$1;
		}
	}
	return @list;
}

=head2 list_sigs

Return the list of signatures in the current user's keyring.

=cut

# Put the next line in the pod when the *info methods are coded.
# To retrieve all information for a given key, use the sig_info() method.

sub list_sigs {
	my $self = shift;
	my @list = ();
	my @out = `2>&1 LC_ALL=C $self->{DATA}->{gpg_binary} --list-sigs`;
	foreach (@out){
		chomp;
		if(/^pub\s+[^\/]+\/([^\s]+)\s+.*$/){
			push @list, $1;
		}
		elsif(/^uid\s+(.+)$/){
			push @{ $list[$#list]->{uid} },$1;
		}
	}
	return @list;
}

# =head2 sig_info
# 
# Retrieve info on one of the user's keyring signature.
# 
# This method takes a uid (or a significant part of it) as parameter. 
# 
# If the uid is not unique enough to select one signature, this method return undef.
# 
# =cut
# # TODO: it sucks => list_* should return a list of key id and *_info return the rest of info !!
# sub sig_info {
# 	my ($self,$uid) = @_;
# 	my @out = `2>&1 LC_ALL=C $self->{DATA}->{gpg_binary} --list-sigs`;
# 	my $data = {};
# 	foreach (@out){
# 		chomp;
# 		if(/^uid\s+$uid/){
# 			$data->{uid} = $uid;
# 		}elsif(defined($data->{uid}) && $data->{uid} eq $uid ){ # you are never to cautious with test...
# 			if(//)
# 		}
# 	}
# }



=head1 ACCESSORS

=head2 gpg_binary

Get/set the path to the gpg binary.

	die "Cannot find gpg : $!\n" unless( -e $gpg->gpg_binary());

=cut

sub gpg_binary
{
	return $_[1] ? $_[0]->{DATA}->{gpg_binary}=$_[1] : $_[0]->{DATA}->{gpg_binary};
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

=head1 SEE ALSO

=head1 COPYRIGHT & LICENSE

Copyright 2005 DUPUIS Arnaud, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # Fin de Slackware::Slackget::GPG

