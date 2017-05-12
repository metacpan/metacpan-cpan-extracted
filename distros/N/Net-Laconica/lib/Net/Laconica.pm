package Net::Laconica;

use warnings;
use strict;
use HTML::Parser;
use LWP::UserAgent;
use Data::Validate qw(is_alphanumeric);
use Data::Validate::URI qw(is_http_uri);
use Carp;

our $VERSION = '0.08';

my $ua = LWP::UserAgent->new;
$ua->agent('Mozilla');
$ua->cookie_jar({ file => 'cookies.txt' });


sub new {
    my $class = shift;
    my $self  = { login => 1, @_ };

    unless( exists $self->{uri} && exists $self->{username} && exists $self->{password}
        or exists $self->{uri} && exists $self->{username} ) {
        croak 'Invalid arguments';
    }

    # Sanitise arguments and check for validity
    is_http_uri($self->{uri}) || croak 'Invalid URI';
    is_alphanumeric($self->{username}) || croak 'Invalid username';

    # Append a slash at the end of uri if it does not end with one
    if( substr($self->{uri}, (length $self->{uri}) - 1, 1) ne '/' ) {
        $self->{uri} .= '/';
    }

    # Convert the username to lowercase and return the blessed reference
    $self->{username} = lc $self->{username};
    bless $self, $class;
}


sub fetch {
    my $self = shift;
    undef $self->{contents};
    my $number;

    # Get/set the number of messages to be fetched
    if( @_ == 1 ) {
        $number = shift;
        if($number > 20) {
            $number = 20;
        }
    } elsif( @_ == 0 ) {
        $number = 10;
    } else {
        croak 'Invalid arguments';
    }

    # Start fetching messages
    my $p = HTML::Parser->new(api_version => 3);
    $p->handler(start => sub { $self->_start_handler(@_) }, 'self,tagname,attr');
    $p->handler(end   => sub {
        return unless defined $self->{value};
        return if $self->{value} eq 'content' && shift eq 'a';
        $self->{value} = undef;
    }, 'tagname');
    $p->utf8_mode(1);

    my $response = $ua->get($self->{uri} . $self->{username} . '/all');
    $p->parse($response->content);

    unless( $self->{login} ) {
        croak 'Incorrect username';
    }

    # Ignore the first array element which is undef, and return the rest of the elements
    splice @{$self->{contents}}, 1, $number;
}


sub send {
    my $self = shift;
    my $message;

    unless( exists $self->{password} ) {
        return $self->{login} = 0;
    }

    if( @_ == 1 ) {
        # Strip the message to 140 characters if the message is longer
        $message = shift;
        if(length $message > 140) {
            $message = substr $message, 0, 140;
        }
    } else {
        croak 'Invalid arguments';
    }

    # Start sending messages
    my $p = HTML::Parser->new(api_version => 3);
    $p->handler(start => sub { $self->_start_handler(@_) }, 'self,tagname,attr');
    $p->handler(end   => sub {
        return unless defined $self->{value};
        return if $self->{value} eq 'content' && shift eq 'a';
        $self->{value} = undef;
    }, 'tagname');
    $p->utf8_mode(1);

    my $response = $ua->post($self->{uri} . 'main/login', [nickname => $self->{username}, password => $self->{password}]);
    $p->parse($response->content);

    # Return 0 if not logged in
    return 0 unless $self->{login};
    $response = $ua->post($self->{uri} . 'notice/new', [status_textarea => $message, returnto => 'all']);
}


sub _start_handler {
    my $class = shift;
    my $self  = shift;

    return unless exists $_[1]->{class};

    if( $_[1]->{class} eq 'nickname' ) {
        $class->{value} = 'nickname';
        $class->{counter}++;
    } elsif( $_[1]->{class} eq 'content' ) {
        $class->{value} = 'content';
    } elsif( $_[1]->{class} eq 'error' ) {
        $class->{value} = 'error';
    }

    $self->handler(text => sub {
        return unless defined $class->{value};
        if( $class->{value} eq 'content' ) {
            $class->{contents}[$class->{counter}] .= shift;
        } elsif( $class->{value} eq 'nickname' ) {
            $class->{contents}[$class->{counter}] .= shift(@_) . ': ';
        } elsif( $class->{value} eq 'error' ) {
            my $error = shift;
            if( $error eq 'Incorrect username or password.' || $error eq 'No such user.' ) {
                $class->{login} = 0;
            }
        }
    }, 'dtext');
}

1;

__END__

=head1 NAME

Net::Laconica - Perl extension for fetching from, and sending notices/messages to Laconica instances

=head1 VERSION

Version 0.08

=cut

=head1 SYNOPSIS

    use Net::Laconica;

    my $identi = Net::Laconica->new(
        uri      => 'http://identi.ca/',
        username => 'alanhaggai',
        password => 'topsecret'
    );

    print map { $_, "\n" } $identi->fetch;

=head1 DESCRIPTION

This module is designed to support C<fetch>ing and C<send>ing messages to Laconica instances.

=head1 METHODS

The implemented methods are:

=over 4

=item C<new>

Returns a blessed hash reference object. This method accepts a hash reference with C<uri>, C<username> and C<password> as keys. C<uri> and C<username> are required, whereas C<password> is optional.

=over 4

=item C<uri>

Holds the URI to the particular Laconica instance to which the object is to be bound.

Example:

    uri => 'http://identi.ca'  # Presence or absence of a trailing slash in the URI does not matter

=item C<username>

Username for the Laconica instance.

Example:

    username => 'alanhaggai'

=item C<password>

Password for the Laconica instance.

Password is required only if you wish to C<send> messages.

Example:

    my $identi = Net::Laconica->new(
        uri      => 'http://identi.ca/',
        username => 'alanhaggai',
        password => 'topsecret'
    );

Or:

    my $identi = Net::Laconica->new(
        uri      => 'http://identi.ca/',
        username => 'alanhaggai',
        password => 'topsecret'
    );

=back

=cut

=item C<fetch>

Returns an array of recent messages.

Default number of recent messages returned is 10. The value can be changed by passing the value as an argument to the method. Maximum limit for the value is 20.

Example:

    my @messages = $laconica->fetch;  # Fetches the top 10 messages
                                      # (If there exists less than 10 messages,
                                      # they are all returned)

Or:

    my @messages = $laconica->fetch(3);  # Fetches the top 3 messages

=cut

=item C<send>

Sends a message.

Returns C<0> if an error occurs.

Example:

    if( $laconica->send('Hello world') ) {
        print 'Message sent successfully.';
    }

=back

=cut

=head1 TODO

These are some features which will be implemented soon:

=over 4

=item * Migrate to the API once it is made a standard

=item * Delete notices

=item * Subscriptions

=item * Profile

=item * Favourites

=item * Replies

=item * Inbox

=item * Outbox

=item * Avatars

=back

=head1 AUTHOR

Alan Haggai Alavi, C<< <alanhaggai at alanhaggai.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-laconica at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Laconica>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Laconica

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Laconica>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Laconica>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Laconica>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Laconica>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Alan Haggai Alavi, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Net::Laconica
