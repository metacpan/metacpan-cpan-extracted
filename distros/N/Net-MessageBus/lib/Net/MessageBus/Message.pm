package Net::MessageBus::Message;

use 5.006;
use strict;
use warnings;

=head1 NAME

Net::MessageBus::Message - Pure Perl generic message queue

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

use base qw(Class::Accessor);

__PACKAGE__->mk_ro_accessors(qw(type group sender payload));


=head1 SYNOPSIS

This module implements a pure perl message bus message object

Example :

    use Net::MessageBus::Message;

    my $foo = Net::MessageBus::Message->new(
                            type => 'event',
                            payload => { some => 'complex strcture' },
                            sender => 'script1',
                            group => 'backend',
            );
    ...


=head1 SUBROUTINES/METHODS

=head2 new

Creates a new Net::MessageBus::Message object

B<Arguments>

=over

=item * type = A type assigned to the message

=item * payload = A complex perl structure / scalar but it cannot contain any objects

=item * sender = the name of the Net::MessageBus client that is sending the message

=item * group = the group to which this message belongs

=back

B<Example> :
    
    my $foo = Net::MessageBus::Message->new(
                            type => 'event',
                            payload => { some => 'complex strcture' },
                            sender => 'script1',
                            group => 'backend',
            );

=cut

sub new {
    my $class = shift;
    my %params = %{shift()};
    
    my $self = __PACKAGE__->SUPER::new({%params});
    
    return $self;
}

=head2 type

Returns the type of the message

B<Example> :
    
    my $type = $Message->type();
        
=head2 sender

Returns the sender of the message

B<Example> :

    my $type = $Message->sender();
        
=head2 group

Returns the group of the message

B<Example> :

    my $type = $Message->group();
        
=head2 payload

Returns the payload of the message 

B<Example> :

    my $type = $Message->payload();        


=head1 Private methods

=head2 serialize

Serializes the message for transport

=cut

sub serialize {
    my $self = shift;
    
    return {
            sender => $self->sender(),
            group  => $self->group(),
            type   => $self->type(),
            payload => $self->payload()
           };
}

=head1 AUTHOR

Horea Gligan, C<< <gliganh at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-MessageBus at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-MessageBus>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::MessageBus::Message


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

1; # End of Net::MessageBus::Message
