package Net::Server::Mail::ESMTP::HELP;

use warnings;
use strict;

use base qw(Net::Server::Mail::ESMTP::Extension);

=head1 NAME

Net::Server::Mail::ESMTP::HELP - Simple implementation of HELP for Net::Server::Mail::ESMTP

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Simple implementation of HELP for Net::Server::Mail::ESMTP.

    use Net::Server::Mail::ESMTP;
    my $server = new IO::Socket::INET Listen => 1, LocalPort => 25;

    my $conn;
    while($conn = $server->accept)
    {
      my $esmtp = new Net::Server::Mail::ESMTP socket => $conn;

      # activate HELP extension
      $esmtp->register('Net::Server::Mail::ESMTP::HELP');

      # adding (optional) HELP handler
      $esmtp->set_callback(HELP => \&show_help);
      $esmtp->process;
    }

    # if you don't set a custom HELP handler, the default one will be used which just lists all known verbs
    sub show_help {
        my ($session, $command) = @_;
    
        $session->reply(214, ($command ? "2.0.0 Heck yeah, '$command' rules!\n":'') . "2.0.0 Available Commands: " . join(', ', keys %{$session->{verb}}) . "\nEnd of HELP info");
    
        return 1;
    }



=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=cut

=head2 verb

=cut

sub verb {
    return [ 'HELP' => 'help' ];
}

=head2 keyword

=cut

sub keyword {
    return 'HELP';
}

=head2 reply

=cut

sub reply {
    return ( [ 'HELP', ] );
}

=head2 help

=cut

sub help {
    my $self = shift;
    my ($args) = @_;

    my $ref = $self->{callback}->{HELP};
    if ( ref $ref eq 'ARRAY' && ref $ref->[0] eq 'CODE' ) {
        my $code = $ref->[0];

        my $ok = &$code($self, $args);
    } else {
        $self->reply(214, "2.0.0 Available Commands: " . join(', ', keys %{$self->{verb}}) . "\nEnd of HELP info");
    }

    return ();
}

*Net::Server::Mail::ESMTP::help = \&help;


=head1 AUTHOR

Dan Moore, C<< <dan at moore.cx> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-server-mail-esmtp-help at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Server-Mail-ESMTP-HELP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Server::Mail::ESMTP::HELP


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Server-Mail-ESMTP-HELP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Server-Mail-ESMTP-HELP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Server-Mail-ESMTP-HELP>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Server-Mail-ESMTP-HELP/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Dan Moore.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Net::Server::Mail::ESMTP::HELP
