package SMS::Send::TMC;

# ABSTRACT: SMS::Send driver to send messages via TMC (http://www.tmcsms.com/)

use strict;
use warnings;
use Carp;
use LWP::UserAgent;
use URI::Escape;

use base 'SMS::Send::Driver';

our $VERSION = '0.01'; # VERSION
our $AUTHORITY = 'cpan:NIGELM'; # AUTHORITY



sub new {
    my ( $class, %args ) = @_;

    # check we have an email and password
    die "_login and _password required" unless ( $args{_login} and $args{_password} );

    # build the object
    my $self = bless {
        _endpoint  => 'https://www.tmcsms.co.uk/api/SendService.aspx',
        _timeout   => 20,
        _debug     => 0,
        _reference => 'Message',
        _source    => 'InboundNumber',
        _confirm   => 0,
        _unicode   => 'true',
        %args
    }, $class;

    # get an LWP user agent ready
    $self->{ua} = LWP::UserAgent->new( agent => join( '/', $class, $VERSION ), timeout => $self->{_timeout} );

    # get the password hash
    $self->{_pwhash} = $self->_hash_password();

    return $self;
}

sub _send_method {
    my ( $self, $method, @args ) = @_;

    unshift( @args, method => $method );
    my @params;
    while (@args) {
        my $key = shift @args;
        my $val = shift @args;
        push( @params, join( '=', uri_escape($key), uri_escape($val) ) );
        print STDERR ">>>     Arg $key = $val\n" if ( $self->{_debug} );
    }
    my $url = join( '?', $self->{_endpoint}, join( '&', @params ) );
    print STDERR ">>> GET $url\n" if ( $self->{_debug} );

    my $res = $self->{ua}->get($url);

    printf STDERR "<<< Status:  %s\n<<< Content: %s\n", $res->code, $res->content if ( $self->{_debug} );
    die $res->status_line unless ( $res->is_success );

    return $res;
}

sub _hash_password {
    my $self = shift;

    my $res = $self->_send_method( 'HashPassword', pwd => $self->{_password} );
    return $res->content;
}


sub send_sms {

    my ( $self, %args ) = @_;

    my $merged_args = { %{$self}, %args };
    my @send_options;
    foreach my $opt (qw[reference source confirm unicode]) {
        push @send_options, $opt => $merged_args->{ '_' . $opt };
    }

    $self->_send_method(
        'SendMessage',
        email      => $self->{_login},
        Pwd        => $self->{_pwhash},
        recipients => $args{to},
        body       => $args{text},
        @send_options
    );
}

1;

__END__

=pod

=for stopwords ACKNOWLEDGEMENTS CPAN Centre Unicode homepage

=head1 NAME

SMS::Send::TMC - SMS::Send driver to send messages via TMC (http://www.tmcsms.com/)

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use SMS::Send;

  # Create a sender
  my $sender = SMS::Send->new(
      'AQL',
      _login    => 'tmc_username',
      _password => 'tmc_password',
  );

  # Send a message
  my $sent = $sender->send_sms(
      text => 'This is a test message',
      to   => '+61 (4) 1234 5678',
  );

  if ($sent) {
      print "Message sent ok\n";
  }
  else {
      print "Failed to send message\n";
  }

=head1 DESCRIPTION

A driver for SMS::Send to send SMS text messages via TMC (Text Messaging
Centre) - L<http://www.tmcsms.com/>

This is not intended to be used directly, but instead called by SMS::Send (see
synopsis above for a basic illustration, and see SMS::Send's documentation for
further information).

The driver uses the TMC HTTP GET API mechanism.  This is documented at
L<http://www.tmcsms.com/developers/>

=head1 METHODS

=head2 new

Constructor, takes argument pairs passed by SMS::Send, returns an
SMS::Send::TMC object.  See usage synopsis for example, and see SMS::Send
documentation for further info on using SMS::Send drivers.

Additional arguments that may be passed include:-

=over 4

=item _endpoint

The HTTP API endpoint.  Defaults to
C<https://www.tmcsms.co.uk/api/SendService.aspx>

=item _timeout

The timeout in seconds for HTTP operations.  Defaults to 20 seconds.

=item _debug

Whether debugging information is output.

=item _reference

The reference used on sent messages - this will show up in the web interface.
For details of this see the C<reference> parameter in the API documentation.
Defaults to C<Message>.

=item _source

The source identifier or number attached to the message.  This has a number of
possible values - C<Mobile>, C<CompanyName>, C<NickName>, C<Signature> or
C<InboundNumber>. For details of this see the C<source> parameter in the API
documentation.  The default is C<InboundNumber>

=item _confirm

What form of confirmation should be sent.  Binary or of the values 2 (for
Mobile confirmation) and 4 (for Email confirmation). For details of this see
the C<confirm> parameter in the API documentation. Defaults to 0.

=item _unicode

Whether the message is in Unicode (a C<true> value) or ASCII (a C<false>
value).  For details of this see the C<unicode> parameter in the API
documentation. Defaults to C<true>.

=back

=head2 send_sms

Send the message - see SMS::Send for details.  Additionally the following
options can be given - these have the same meaning as they do in the C<new>
method:-

=over 4

=item *

_reference

=item *

_source

=item *

_confirm

=item *

_unicode

=back

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org/Public/Dist/Display.html?Name=SMS-Send-TMC>.

=head1 AVAILABILITY

The project homepage is L<https://metacpan.org/release/SMS-Send-TMC>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/SMS::Send::TMC/>.

=head1 AUTHOR

Nigel Metheringham <nigelm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Nigel Metheringham.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
