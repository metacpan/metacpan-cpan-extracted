package Plugtools::Plugins::Samba::setPass;

use warnings;
use strict;
use Plugtools::Plugins::Samba;

=head1 NAME

Plugtools::Plugins::Samba::setPass - A Samba password setting plugin for Plugtools.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

This sets the required password attributes for use with Samba.

This is for use with userSetPass.

=head1 FUNCTIONS

=head2 plugin

The function that will be called by Plugtools.

    use Plugtools::Plugins::Samba::setPass;
    %returned=Plugtools::Plugins::Samba::setPass->plugin(\%opts, \%args);
    
    if($returned{error}){
        print "Error!\n";
    }

=cut

sub plugin{
	my %opts;
	if(defined($_[1])){
		%opts= %{$_[1]};
	};	my %args;
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
		warn('Plugtools-Plugins-Samba-setPass plugin:1: '.$returned{errorString});
		return %returned;
	}

	$pts->setPassEntry({
						entry=>$opts{entry},
						pass=>$args{pass},
						});
	if ($pts->{error}) {
		$returned{error}=1;
		$returned{errorString}='Plugtools::Plugins::Samba->setPassEntry errored. $pts->{error}="'.
		                       $pts->{error}.'" $pts->{errorString}="'.$pts->{errorString}.'"';
		warn('Plugtools-Plugins-Samba-setPass plugin:1: '.$returned{errorString});
		return %returned;
	}

	return %returned;
}

=head1 ERROR CODES

=head2 1

Unable to create new Plugtools::Plugins::Samba object.

=head2 2

setPassEntry errored

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-plugtools-plugins-samba at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Plugtools-Plugins-Samba>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Plugtools::Plugins::Samba::setPass


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

1; # End of Plugtools::Plugins::Samba::setPass
