package SMS::Send::Fr::OVH;

use strict;
use warnings;
use LWP::Simple qw(get);
use JSON        qw(from_json);
use Carp;

our $VERSION = '0.01';
use base 'SMS::Send::Driver';

use constant URL => 'https://www.ovh.com/cgi-bin/sms/http2sms.cgi?&account=%s&login=%s&password=%s&from=%s&to=%s&message="%s"&contentType=application/json';

=head1 NAME

SMS::Send::Fr::OVH - Perl driver for SMS::Send library.

=head1 SYNOPSIS

  use SMS::Send::Fr::OVH;

  # Create a sender
  my $sender = SMS::Send->new('Fr::OVH',
      _account => 'sms-ab1234-1',
      _login => 'sms_user_name',
      _password => 'pass',
      _from => 'ovh_sender_name'
      _transform_number => [
           { match_re => '^+33', replace_re => '0033' },
      ]
  );

  # Send a message
  my $sent = $sender->send_sms(
      text => 'This is a test message',
      to   => '003361*****20'
  );

=head1 DESCRIPTION

SMS::Send::Fr::OVH - SMS::Send driver to send messages via OVH SMS API.

=head1 METHODS

=over 4

=item new

Constructor.

=cut

sub new {
    my ($class, %args) = @_;

    my $self = bless { %args }, $class;

    return $self;
}

=item send_sms

Send the message - see SMS::Send for details.

=cut

sub send_sms {
    my ($self, %args) = @_;

    $self->{text} = "$args{text}";
    $self->{to} = $self->transform_number($args{to});

    my @arguments;
    foreach my $arg (qw(_account _login _password _from to text)) {
        push @arguments, $self->{ $arg };
    }

    #my $url = sprintf(URL, @arguments);
    #my $response = from_json(get($url));

    #unless ($response->{status} == 100) {
    #    Carp::croak($response->{message});
    #    return 0;
    #}

    return 1;
}

=item transform_number

Transform a phone number according to the regular expressions
provided to the constructor.

=cut

sub transform_number {
    my ($self, $number) = @_;

    foreach my $rule (@{ $self->{_transform_number} }) {
        my $match = $rule->{match_re};
        my $replace = $rule->{replace_re};
        if ($number =~ /$match/) {
            $number =~ s/$match/\Q$replace/g;
            return $number;
        }
    }

    return $number;
}

=back

=head1 AUTHOR

Alex Arnaud, E<lt>gg.alexarnaud@gmail.comE<gt>
