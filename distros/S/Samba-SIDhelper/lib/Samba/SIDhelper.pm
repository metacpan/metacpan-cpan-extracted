package Samba::SIDhelper;

use warnings;
use strict;

=head1 NAME

Samba::SIDhelper - Create SIDs based on G/UIDs.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use Samba::SIDhelper;

    my $sidhelper = Samba::SIDhelper->new({sid=>'S-1-5-21-1234-56789-10111213'});

    my $sid=$sidhelper->uid2sid('1002');
    if ($sidhelper){
        print "Error!\n";
    }

    $sid=$sidhelper->gid2sid('1002');
    if ($sidhelper){
        print "Error!\n";
    }

=head1 METHODS

=head2 new

=head3 args hash

=head4 sid

If this is specified, this base SID will be used instead of trying
to automatically figure out what to use.

=head4 domain

If this is set to 1, it will try to use get the domain SID instead
of the local SID.

    my $sidhelper->new({sid=>'S-1-5-21-1234-56789-10111213'});
    if($sidhelper->{error}){
        print "Error!\n";
    }

=cut

sub new {
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	my $self = {error=>undef, errorString=>""};
	bless $self;

	if (defined($args{sid})) {
		$self->{sid}=$args{sid};
	}

	if (!defined($self->{sid})) {
		my $sid;
		if ($args{domain}) {
			$sid=`net getdomainsid`;
			if ($? ne '0') {
				$self->{error}=1;
				$self->{errorString}='"net getdomainsid" exited with a non-zero';
				warn('Samba-SIDhelper new:1: '.$self->{errorString});
				return $self;
			}
		}else {
			$sid=`net getlocalsid`;
			if ($? ne '0') {
				$self->{error}=2;
				$self->{errorString}='"net getdomainsid" exited with a non-zero';
				warn('Samba-SIDhelper new:2: '.$self->{errorString});
				return $self;
			}
		}

		chomp($sid);

		my @sidA=split(/\:/, $sid);
		
		$sid=$sidA[1];

		$sid=~s/ //g;

		$self->{sid}=$sid;
	}

	return $self;
}

=head2 uid2sid

Convert a UID to SID.

   my $sid=$sidhelper->uid2sid('1002');
   if ($sidhelper){
       print "Error!\n";
   }

=cut

sub uid2sid{
	my $self=$_[0];
	my $uid=$_[1];

	$self->errorblank;

	if (!defined($uid)) {
		$self->{error}=3;
		$self->{errorString}='No UID specified';
		warn('Samba-SIDhelper uid2sid:3: '.$self->{errorString});
		return undef;
	}

	if ($uid !~ /^[0123456789]*$/) {
		$self->{error}=5;
		$self->{errorString}='UID is not numeric';
		warn('Samba-SIDhelper uid2sid:5: '.$self->{errorString});
		return undef;
	}

	$uid=$uid*2;
	$uid=$uid+1000;

	return $self->{sid}.'-'.$uid;
}

=head2 gid2sid

Convert a GID to SID.

   my $sid=$sidhelper->gid2sid('1002');
   if ($sidhelper){
       print "Error!\n";
   }

=cut

sub gid2sid{
	my $self=$_[0];
	my $gid=$_[1];

	$self->errorblank;

	if (!defined($gid)) {
		$self->{error}=4;
		$self->{errorString}='No GID specified';
		warn('Samba-SIDhelper gid2sid:4: '.$self->{errorString});
		return undef;
	}

	if ($gid !~ /^[0123456789]*$/) {
		$self->{error}=5;
		$self->{errorString}='GID is not numeric';
		warn('Samba-SIDhelper gid2sid:5: '.$self->{errorString});
		return undef;
	}

	$gid=$gid*2;
	$gid=$gid+1001;

	return $self->{sid}.'-'.$gid;
}

=head2 errorblank

This is a internal function and should not be called.

=cut

#blanks the error flags
sub errorblank{
	my $self=$_[0];

	$self->{error}=undef;
	$self->{errorString}="";

	return 1;
};

=head1 ERROR CODES

=head2 1

"net getdomainsid" exited with a non-zero.

=head2 2

"net getlocalsid" exited with a non-zero.

=head2 3

No UID specified.

=head2 4

No UID specified.

=head2 5

Non-numeric value for UID or GID.

=head1 SID DISCOVERY

This requires Samba to be installed. The command net is used, which requires this
being ran as root.

=head1 CONVERSION METHOD

This uses the method from smbldap-tools.

    $sid=$uid*2+1000
    $sid=$gid*2+1001

This method means both both user and group info is can be stored in the same space. Groups are always
odd, while users are always even.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-samba-sidhelper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Samba-SIDhelper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Samba::SIDhelper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Samba-SIDhelper>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Samba-SIDhelper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Samba-SIDhelper>

=item * Search CPAN

L<http://search.cpan.org/dist/Samba-SIDhelper/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Samba::SIDhelper
