package SMS::Matrix;

# ABSTRACT: Module for the SMS::Matrix API

use warnings;
use strict;

use LWP::UserAgent;
use HTTP::Request::Common;
use JSON();
## use Data::Dumper;

our $VERSION = '1.01';

####################################################

my @attrs = qw(username password);

for my $attr ( @attrs )
{
 no strict 'refs';
 *{ __PACKAGE__ . '::' . $attr } = sub
   {
    my ($self, $value) = @_;
        
    my $key = '__' . $attr . '__';
    $self->{$key} = $value if @_ == 2;
    return $self->{$key};
   };
}

####################################################

sub new
{
 my ($class, %param) = @_;
    
 my $self = bless {}, $class;
 for my $attr ( @attrs )
  {
   if (exists $param{$attr}) {  $self->$attr( $param{$attr} ); }
  }
 return $self;
}

####################################################

sub send
{
 my ($self, $rqp) = @_;

 if ($rqp->{txt} eq '')
  {
   $self->errstr ('Message text is blank');
   $self->status (1001);
   return;
  }

 my $json_txt = JSON::to_json ($rqp);
 if ($json_txt eq '')
  {
   $self->errstr ('JSON::to_json() returned NULL');
   $self->status (1000);
   return;
  }

 my $ua = LWP::UserAgent->new();
 my $res = $ua->request
  (
   POST $rqp->{url},
   Content_Type  => 'application/json',
   Content       => $json_txt
  );

 ## print Dumper($rqp) . "\n\n";
 ## print Dumper($res) . "\n\n";

 if ($res->is_error)
  {
   $self->errstr ($res->{_msg});
   $self->status ($res->{_rc});
   return;
  }
 my $resp = undef;
 eval { $resp = JSON::from_json ($res->content); };

 $self->errstr ($resp->{STATUSTXT});
 $self->status ($resp->{STATUSCODE});

 return $resp;
}

####################################################

sub send_sms
{
 my ($self, %param) = @_;

 my $rqp =
  {
   'username' => $self->{__username__},
   'password' => $self->{__password__},
   'url'      => 'https://www.smsmatrix.com/matrix.json',
  };
 while (my ($key, $value) = each (%param))  { $rqp->{$key} = $value; }
 return $self->send ($rqp);
}

####################################################

sub send_tts
{
 my ($self, %param) = @_;

 my $rqp =
  {
   'username' => $self->{__username__},
   'password' => $self->{__password__},
   'url'      => 'https://www.smsmatrix.com/matrix_tts.json',
  };
 while (my ($key, $value) = each (%param))  { $rqp->{$key} = $value; }
 return $self->send ($rqp);
}

####################################################

sub get_balance
{
 my ($self, %param) = @_;

 my $rqp =
  {
   'username' => $self->{__username__},
   'password' => $self->{__password__},
   'url'      => 'https://www.smsmatrix.com/balance.json',
   'txt'      => 'x',
  };
 while (my ($key, $value) = each (%param))  { $rqp->{$key} = $value; }
 return $self->send ($rqp);
}

####################################################

sub is_success
{
 my ($self) = @_;
    
 my $s = $self->{__status__};
 return (($s >= 0) and ($s < 399));
}

####################################################

sub is_error
{
 my ($self) = @_;
    
 return ! $self->is_success();
}

####################################################

sub errstr
{
 my ($self,$message) = @_;
    
 $self->{__errstr__} = $message if @_ == 2;
 return $self->{__errstr__};
}

####################################################

sub status
{
 my ($self, $status) = @_;
    
 $self->{__status__} = $status if @_ == 2;
 return $self->{__status__};
}

####################################################


1; # End of Matrix::SMS

__END__
=pod

=head1 NAME

SMS::Matrix - Module for the SMSMatrix API!

=head1 VERSION

version 1.00

=head1 SYNOPSIS

This module simplifies sending SMS through the SMSMatrix API.

    use SMS::Matrix;
    use Data::Dumper;

    my $x = SMS::Matrix->new
    (
     username => 'myaccount@qqqqq.com',
     password => 'mypassword',
    );

    my $resp = $x->send_sms
    (
     txt     => 'This is a test',
     phone   => '13475524523',
    );

    print $x->status() . "\n" .    ## Numbers from 200-399 mean success; numbers from 400 up mean error
          $x->errstr() . "\n" .    ## If ok, set to 'OK'
          "Response" . Dumper ($resp) . "\n\n";

    ## resp hash looks like this:
    ##    {
    ##      'ID' => '03ade5c5ede29451edd75147aa9586d0',
    ##      'STATUSTXT' => 'OK',
    ##      'STATUSCODE' => 200,
    ##      'TIMESTAMP' => 1409596234    ## UTC
    ##    };
    ## resp may be undefined, if API didn't even hit the SMS Gateway server

=head1 VERSION

Version 1.00

=head1 METHODS

=head2 new

create a new object

    my $x = SMS::Matrix->new
    (
     username => 'myaccount@qqqqq.com',
     password => 'mypassword',
    );

Username and password are not validated at this point.

=head2 send_sms

Send new sms message, returns  response object or C<undef>.

    my $resp = $x->send_sms
    (
     txt     => 'This is a test',
     phone   => '13475524523',     ## Always use country prefix (e.g 1 for US/Canada)
    );
    print Data::Dumper ($resp);

=head2 is_success

returns 1 if message was sent OK

    print $x->is_success();

=head2 is_error

returns 1 if message was NOT sent OK

    print $x->is_error();

=head2 status

gets/set status of the message

    print $x->status();

=head2 username

gets value of the username property

    print $x->username();

=head2 password

gets value of the password property

    print $x->password();

=head2 errstr

returns the "last" error as string.

    print $x->errstr();

=head2 get_balance

Retrieves your current balance - number of credits available for your account

    my $resp = $x->get_balance();
    print Data::Dumper ($resp);

=head2 send

Internal function, do not use it.
Its interface may change in the future.

=head2 send_tts

Send new tts (text to speech) message, returns response object or C<undef>.

    my $resp = $x->send_tts
    (
     txt      => 'This is a test of a machine trying to talk English',
     phone    => '13475524523',
     gender   => 'male',
     language => 'en',
     response => 0,
    );
    print Data::Dumper ($resp);

Check for list of available languages at L<http://www.smsmatrix.com/?sms-gateway-json>

=head2 send_voice

Not implemented yet...

=head2 get_history

Not implemented yet...

=head2 get_status

Not implemented yet...

=head2 get_pricing

Not implemented yet...

=head1 AUTHOR

Daniel Rokosz, C<< <daniel at smsmatrix.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sms-matrix at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SMS-Matrix>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SMS::Matrix

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SMS-Matrix>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SMS-Matrix>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SMS-Matrix>

=item * Search CPAN

L<http://search.cpan.org/dist/SMS-Matrix/>

=item * SMSMatrix website

L<http://www.smsmatrix.com>

=back

=head1 AUTHOR

Daniel Rokosz <daniel@smsmatrix.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Daniel Rokosz.
This is free software, licensed under:
  The Artistic License 2.0 (GPL Compatible)

=cut

