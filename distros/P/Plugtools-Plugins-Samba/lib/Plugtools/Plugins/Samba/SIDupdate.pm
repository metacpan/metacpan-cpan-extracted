package Plugtools::Plugins::Samba::SIDupdate;

use warnings;
use strict;
use Plugtools::Plugins::Samba;

=head1 NAME

Plugtools::Plugins::Samba::SIDupdate - Updates a the SIDs for a entry based on the current GID/UID.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

This should be called after updating the UID/GID of a POSIX account.

This is for use with userGIDchange and userUIDchange.

=head1 FUNCTIONS

=head2 plugin

The function that will be called by Plugtools.

    use Plugtools::Plugins::Samba::SIDupdate;
    %returned=Plugtools::Plugins::Samba::SIDupdate->plugin(\%opts, \%args);
    
    if($returned{error}){
        print "Error!\n";
    }

=cut

sub plugin{
	my %opts;
	if(defined($_[1])){
		%opts= %{$_[1]};
	};
	my %args;
	if(defined($_[2])){
		%args= %{$_[2]};
	};
	
	my %returned;
	$returned{error}=undef;

    my $pts = Plugtools::Plugins::Samba->new({
                                              pt=>$opts{self},
                                              ldap=>$opts{ldap}
											  });
	if ($pts->{error}) {
		$returned{error}=1;
		$returned{errorString}='Unable to create new Plugtools::Plugins::Samba object. $pts->{error}="'.
		                       $pts->{error}.'" $pts->{errorString}="'.$pts->{errorString}.'"';
		warn('Plugtools-Plugins-Samba-SIDupdate plugin:1: '.$returned{errorString});
		return %returned;
	}

	$pts->sidUpdateEntry({
						entry=>$opts{entry},
						});
	if ($pts->{error}) {
		$returned{error}=1;
		$returned{errorString}='Plugtools::Plugins::Samba->sidUpdateEntry errored. $pts->{error}="'.
		                       $pts->{error}.'" $pts->{errorString}="'.$pts->{errorString}.'"';
		warn('Plugtools-Plugins-Samba-SIDupdate plugin:1: '.$returned{errorString});
		return %returned;
	}

	return %returned;
}

=head1 ERROR CODES

=head2 1

Unable to create new Plugtools::Plugins::Samba object.

=head2 2

sidUpdate errored

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-plugtools-plugins-samba at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Plugtools-Plugins-Samba>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Plugtools::Plugins::Samba::SIDupdate


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Plugtools-Plugins-Samba>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Plugtools-Plugins-Samba>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Plugtools-Plugins-Samba>

=item * Search CPAN

L<http://search.cpan.org/dist/Plugtools-Plugins-Samba/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Plugtools::Plugins::Samba::SIDupdate
