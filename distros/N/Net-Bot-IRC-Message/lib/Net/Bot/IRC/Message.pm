package Net::Bot::IRC::Message;

use warnings;
use strict;

use Params::Validate;
use Carp;

=head1 NAME

Net::Bot::IRC::Message - An IRC protocol message class.

=head1 VERSION

Version 1.0.1

=cut

our $VERSION = '1.0.1';


=head1 SYNOPSIS

    use Net::Bot::IRC::Message;

    my $outgoing = Net::Bot::IRC::Message->new({
        prefix  => $prefix, #Optional
        command => $cmd,
        params  => $params,
    });
    my $raw_message = $outgoing->compile();

    my $incoming = Net::Bot::IRC::Message->new({
        unparsed => $raw_message,
    });
    my ($prefix, $command, $params)
        = $incoming->parse();


=head1 FUNCTIONS

=head2 new( prefix => $prefix, command => $cmd, params => $params )

=head2 new( unparsed => $raw_message )

=cut

sub new {
    my $class = shift;
    my $self  = validate(@_, {
        # For outgoing messages.
        prefix   => {
            optional => 1,
            depends  => [ 'command', 'params' ],
        },
        command  => {
            optional => 1,
            depends  => [ 'params' ],
        },
        params   => {
            optional => 1,
            depends  => [ 'command' ],
        },
        # For incoming messages
        unparsed => {
            optional => 1,
        },
    });

    bless $self, $class;
    return $self;
}

=head2 parse()

=cut

sub parse {
    my $self = shift;
    unless (exists $self->{unparsed}) {
        croak "No message to parse.";
    }

    my $message = $self->{unparsed};

    if ($message =~ /:(\S+) (\d\d\d) (.+)/) {
        $self->{prefix}  = $1;
        $self->{command} = $2;
        $self->{params}  = $3;
    }

    return ($self->{prefix},
            $self->{command},
            $self->{params});
}

=head2 compile()

=cut

sub compile {
    my $self = shift;

    unless (   exists $self->{prefix}
            && exists $self->{command}
            && exists $self->{params}) {
        croak "Prefix, command and params not specified.";
    }

    my $message = ":" . $self->{prefix}  . " "
                      . $self->{command} . " "
                      . $self->{params};

    $self->{unparsed} = $message;

    return $self->{unparsed};
}

=head1 AUTHOR

Mark Caudill, C<< <mcaudill at cpan.org> >>

=head1 SOURCE

The source for this module is maintained at C<< <git@github.com:markcaudill/Net-Bot-IRC-Message.git> >>.

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-bot-irc-message at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Bot-IRC-Message>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Bot::IRC::Message


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Bot-IRC-Message>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Bot-IRC-Message>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Bot-IRC-Message>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Bot-IRC-Message/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2023 Mark Caudill.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Net::Bot::IRC::Message
