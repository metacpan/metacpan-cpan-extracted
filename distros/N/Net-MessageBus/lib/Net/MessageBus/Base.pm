package Net::MessageBus::Base;

use 5.006;
use strict;
use warnings;

=head1 NAME

Net::MessageBus::Base - Base class for Net::MessageBus modules

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SUBROUTINES/METHODS

=head2 logger

Getter / Setter for the logging object

=cut
sub logger {
    my $self = shift;
    if ($_[0]) {
        $self->{logger} = $_[0];
    }
    return $self->{logger};
}


=head2 create_default_logger

Creates the default logger that will be used
    
=cut
sub create_default_logger {
    my $logger;
    eval {
        use Log::Log4perl qw(:easy);
        Log::Log4perl->easy_init($ERROR);
        $logger = Log::Log4perl->get_logger;
    };
    if ($@) {
        die "Error creating default logger for ". __PACKAGE__ .
            ", please specify one or install Log::Log4perl! $@";
    }
    
    return $logger;
}


=head1 AUTHOR

Horea Gligan, C<< <gliganh at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-MessageBus at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-MessageBus>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::MessageBus


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-MessageBus>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-MessageBus>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-MessageBus>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-MessageBus/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Horea Gligan.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Net::MessageBus::Base