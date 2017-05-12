package Plugtools::Plugins::Dump;

use warnings;
use strict;
use Data::Dumper;

=head1 NAME

Plugtools::Plugins::Dump - A Plugtools plugin that calls Data::Dumper->Dumper on %opts and %args that are passed to the plugin.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';

=head1 SYNOPSIS

This is a Plugtools plugin that calls Data::Dumper->Dumper on %opts and %args
that are passed to the plugin.

=cut

=head1 Functions

=head2 plugin

The function that will be called by Plugtools.

    use Plugtools::Plugins::Dump;
    %returned=Plugtools::Plugins::Dump->plugin(\%opts, \%args);
    
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

	print '%opts=...'."\n".Dumper(\%opts)."\n\n".'%args=...'."\n".Dumper(\%args);

	my %returned;
	$returned{error}=undef;

	return %returned;
}

=head1 ERROR CODES

At this time this plugin does not return any error codes. As long as Data::Dumper is
installed, it will work.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-plugtools at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Plugtools>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Plugtools


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Plugtools>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Plugtools>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Plugtools>

=item * Search CPAN

L<http://search.cpan.org/dist/Plugtools/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Plugtools
