package Oracle::ZFSSA::Client;

use 5.008;

use strict;
use warnings;

use LWP::UserAgent;
use JSON;

our $VERSION = '0.01';

# HTTP Return Codes
use HTTP::Status qw(:constants);

sub new {

   my $class = shift;

   my %param = @_;

   my $self->{user}  = delete $param{user};
   $self->{password} = delete $param{password};
   $self->{host}     = delete $param{host};
   $self->{port}     = delete $param{port}      || 215;
   $self->{debug}    = delete $param{debug}     || 0;

   if (!defined($param{ssl}) || $param{ssl} != 0) {
      $self->{ssl} = 1;
   } else {
      $self->{ssl} = 0;
   }

   if (!defined($param{verify_hostname}) || $param{verify_hostname} != 0) {
      $self->{verify_hostname} = 1;
   } else {
      $self->{verify_hostname} = 0;
   }

   die "A user must be defined" if (!defined($self->{user}));
   die "A password must be defined" if (!defined($self->{password}));
   die "A host must be defined" if (!defined($self->{host}));

   my $url = $self->{host} . ":" . $self->{port};

   if ($self->{ssl}) {
      $url = "https://" . $url;
   } else {
      $url = "http://" . $url;
   }

   $self->{url} = $url;

   # Generate the first request and get a valid Session
   #
   $url = $url . '/api/access/v1';

   my $header = ['X-Auth-User'   => $self->{user},
                 'X-Auth-Key'    => $self->{password},
                 'Content-Type'  => 'application/json; charset=utf-8'];
   my $r = HTTP::Request->new('POST', $url, $header);
   my $ua = LWP::UserAgent->new();

   if ($self->{debug} == 1) {
      $ua->add_handler("request_send",  sub { shift->dump; return });
      $ua->add_handler("response_done", sub { shift->dump; return });
   }

   if ($self->{verify_hostname} == 0) {
      # Self signed Cert
      $ua->ssl_opts( verify_hostname => 0,
                     SSL_verify_mode => 'SSL_VERIFY_NONE' );
   }

   # We'll reuse this User Agent
   $self->{ua} = $ua;

   my $res = $ua->request($r);

   my $session = "";
   if ($res->code == HTTP_CREATED) {
      # All proceeding request should had this header set
      $session = $res->header('X-Auth-Session');
   } else {
      # You did not get a valid session
      die $res->status_line . ": Unable to get valid X-Auth-Session";
   }
   #
   # End Session Building

   $self->{session} = $session;

   bless $self, $class;
   return $self;
}

sub call {

   my ($self,$method,$uri,$json) = @_;

   $json = JSON->new->utf8->encode($json) if (defined($json));

   my $url = $self->{url} . $uri;
   my $header = ['X-Auth-Session'   => $self->{session},
                 'Content-Type'     => 'application/json; charset=utf-8'];
   my $r = HTTP::Request->new($method, $url, $header, $json);

   my $ua = $self->{ua};

   my $res = $ua->request($r);

   if ($res->is_success) {
      return JSON->new->utf8->decode($res->decoded_content);
   }
   return;
}

1;

=pod

=head1 NAME

Oracle::ZFSSA::Client - Oracle ZFS Storage RESTful API Connector

=head1 SYNOPSIS

   use Oracle::ZFSSA::Client;

   $zfssa = new Oracle::ZFSSA::Client(
      user => $user,
      password => $password,
      host => "your.appliance.org"
   );

   $json_param = {
      your => 'params',
      but  => 'not required',
   };

   $json_result = $zfssa->call('POST','/api/storage/v1/method',$json_param)

   # See ex/example.pl for more examples:
   #     https://github.com/whindsx/Oracle-ZFSSA-Client/blob/master/ex/example.pl 

=head1 DESCRIPTION

This Perl module provides a simplified means of connecting to and
executing commands against an Oracle ZFSSA RESTful Application
Programming Interface. Responses are Perl C<JSON> data structures.

=head1 CONSTRUCTOR

$zfssa = Oracle::ZFSSA::Client->new( %options )

This method creates a new C<Oracle::ZFSSA::Client> and returns it.

   Key                 Default
   -----------         -----------
   user                undef (Required)
   password            undef (Required)
   host                undef (Required)
   port                215
   ssl                 1
   verify_hostname     1
   debug               0

ssl - Connect to the API over HTTPS.

verify_hostname - Disable SSL certificate verification.

debug - Turns on raw HTTP request/response output from LWP::UserAgent.

=head1 METHODS

There is only one c<Oracle::ZFSSA::Client> method:

=head2 call

   $zfssa->call('GET','/api/storage/v1/pools');

The first parameter is the HTTP method, this is required.
The second parameter is the ZFSSA API method, this is also required.
The third and optional parameter is a hash of API parameters that will 
become C<JSON> encoded.
                                                                                                                          
For more information see:
https://docs.oracle.com/cd/E51475_01/html/E52433/index.html  

=head1 AUTHOR

Wesley Hinds wesley.hinds@gmail.com

=head1 AVAILABILITY

The latest branch is avaiable from Github.

https://github.com/whindsx/Oracle-ZFSSA-Client

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Wesley Hinds.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut
