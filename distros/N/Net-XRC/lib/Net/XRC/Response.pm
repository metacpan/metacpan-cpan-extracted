package Net::XRC::Response;

use strict;
use vars qw($AUTOLOAD);

my %exception = (
    1 => 'PROTOCOL',
    2 => 'UNKNOWN_COMMAND',
    4 => 'IO',
    5 => 'AUTHENTICATION_FAILURE',
    6 => 'SYSTEM_FAILURE',
    7 => 'PERMISSION_DENIED',
    8 => 'ARGUMENT_TYPE_MISMATCH',
   10 => 'UNKNOWN_TYPE',
   11 => 'SYNTAX',
   13 => 'SERIALIZE',
  200 => 'INVALID_ARGUMENT',
  201 => 'EMAIL_SERVICE_ALREADY_SETUP',
  202 => 'WEBMAIL_HOSTNAME_NOT_READY',
  203 => 'EMAIL_DOMAIN_NAME_NOT_READY',
  204 => 'WEBMAIL_HOSTNAME_TAKEN',
  205 => 'EMAIL_DOMAIN_NAME_TAKEN',
  206 => 'ACCOUNT_NAME_TAKEN',
  207 => 'CLIENT_DOES_NOT_EXIST',
  208 => 'INVALID_PASSWORD',
  209 => 'INVALID_ADDRESS',
  210  => 'EMAIL_SERVICE_NOT_READY',
  211 => 'INVALID_WEBMAIL_HOSTNAME',
  212 => 'INVALID_EMAIL_DOMAIN',
  213 => 'USER_DOES_NOT_EXIST',
  214 => 'INVALID_ACCOUNT_NAME',
  215 => 'OFFER_NOT_AVAILABLE',
  216 => 'ALIAS_DOES_NOT_EXIST',
  217 => 'USER_NO_MAILBOX',
  218 => 'EMAIL_SERVICE_NOT_FOUND',
  219 => 'ACCOUNT_NOT_SUSPENDED',
);

my %exception_long = (
    1 => 'EOF while reading metadata, '.
         'a metadata line exceeded 8192 bytes, '.
         'missing a required metadata key-value pair, '.
         'metadata value malformed, or '.
         'missing method name and/or method arguments.',
    2 => 'The method name does not match a known method.',
    4 => 'IO error or premature EOF while parsing method arguments',
    5 => 'Credentials offered in metadata are not valid.',
    6 => 'An internal error in the XRC server. Everyone.net is automatically notified.',
    7 => 'The caller does not have necessary rights.',
    8 => 'One or more of the method arguments was not of the correct type, or the number of arguments to the method was incorrect.',
   10 => 'The name of a complex type is not known.',
   11 => 'An error in the format of the XRC request.',
   13 => 'A value of a complex type was of the wrong type or failed to meet the requirements of the type specification.',
  200 => 'An argument to a method did not meet the requirements of the specification.',
  201 => 'An attempt was made to setup an email service for a client that already has an email service.',
  202 => 'The webmail hostname is not properly configured. See DNS Requirements.',
  203 => 'The email domain is not properly configured. See DNS Requirements.',
  204 => 'The webmail hostname is in use by another client.',
  205 => 'The email domain is in use by another client.',
  206 => 'The username or alias name is in use.',
  207 => 'An operation was attempted on a client that cannot be found.',
  208 => 'The password is not valid. See Name Restrictions.',
  209 => 'An email address was not of legal form.',
  210 => 'The MX records of the email service have not been validated.',
  211 => 'The webmail hostname is not valid. See Name Restrictions.',
  212 => 'The email domain is not valid. See Name Restrictions.',
  213 => 'An operation was attempted on a user that cannot be found.',
  214 => 'The username or alias name is not valid. See Name Restrictions.',
  215 => 'The distributor attempted to apply an offer to a user or client that does not exist, applies to the wrong beneficiary, or does not belong to the distributor.',
  216 => 'An operation was attempted on an alias that cannot be found.',
  217 => 'The user does not have a mailbox.',
  218 => 'The client does not have an email service.',
  219 => 'The user mailbox cannot be purged because the user account is not in suspended mode.',
);

=head1 NAME

Net::XRC::Response - XRC response object

=head1 SYNOPSIS

  my $response = $xrc->some_method( $and, $args );

  #response meta-data
  my $server = $response->server;
  my $timestamp = $response->server;

  if ( $response->is_success ) {

    my $content = $response->content;
    #...

  } else {

    my $status = $response->status; #error code
    my $error = $response->error; #error message
    #...
  }

=head1 DESCRIPTION

The "Net::XRC::Response" class represents XRC responses.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  bless($self, $class);

  my $data = shift;

  while ( $data =~ s/^(\w+):\s*(.*)$//m ) { #metadata
    warn "response metadata: $1 => $2\n"
      if $Net::XRC::DEBUG;
    $self->{$1} = $2;
  }

  $self->{'content'} = $self->decode(\$data)
    if $self->is_success;

  $self;
}

sub is_success { 
  my $self = shift;
  ! $self->{'status'};
}

sub error {
  my $self = shift;
  $exception{ $self->{'status'} }. ': '. $exception_long{ $self->{'status'} }.
  ' - '. $self->{'errorDescription'};
}

sub AUTOLOAD {
  my $self = shift;
  $AUTOLOAD =~ s/.*://;
  $self->{$AUTOLOAD};
}
#sub content { $self->{'content'}; }
#sub status { $self->{'status'}; }
#sub errorDescription { $self->{'errorDescription'}; }
#sub server { $self->{'server'}; }
#sub timestamp { $self->{'timestamp'}; }

sub decode {
  my( $self, $s ) = @_;

  warn "starting to parse response: ". $$s
    if $Net::XRC::DEBUG > 1;

  $$s =~ s/^[\s\n]+//g; #trim leading newlines and whitespace

  if ( $$s =~ /^[\-\d]/ ) { #int
    $$s =~ s/^(\-?\d+)// and $1
      or die "can't parse (int) response: ". $$s. "\n";
  } elsif ( $$s =~ /^"/ ) { #string
    $$s =~  s/^"(([^"\\]|\\"|\\\\)+)"//
      or die "can't parse (string) response: ". $$s. "\n";
    my $str = $1;
    $str =~ s(\\")(")g;
    $str =~ s(\\\\)(\\)g;
    $str;
  } elsif ( $$s =~ /^\/[TF]/ ) { #boolean
    $$s =~ s/^\/([TF])//
      or die "can't parse (bool) response: ". $$s. "\n";
    $1 eq 'T' ? 1 : 0;
  } elsif ( $$s =~ s/^\/NULL// ) { #NULL
    undef;
  } elsif ( $$s =~ /^\{/ ) { #bytes
    $$s =~ s/^\{(\d+)\}//
      or die "can't parse (bytes) response: ". $$s. "\n";
    substr($$s, 0, $1, '');
  } elsif ( $$s =~ /^\(/ ) { #list
    $$s =~ s/^\([\s\n]*//
      or die "can't parse (list) reponse: ". $$s. "\n";
    my @list = ();
    until ( $$s =~ s/^[\s\n]*\)// ) {
      push @list, $self->decode($s);
      die "unterminated list\n" if $s =~ /^[\s\n]*$/;
    }
    \@list;
  } elsif ( $$s =~ /^:/ ) { #complex
    $$s =~ s/^:(\w+)[\s\n]*//
      or die "can't parse (complex) response: ". $$s. "\n";
    my %hash = ( '_type' => $1 );
    until ( $$s =~ s/^[\s\n]*\)// ) {
      $$s =~ s/^[\s\n]*(\w+)//
        or die "can't parse ($hash{_type}) response: ". $$s. "\n";
      $hash{$1} = $self->decode($s);
      die "unterminated $hash{_type}\n" if $s =~ /^[\s\n]*$/;
    }
    \%hash;
  } else {
    die "can't parse response: ". $$s. "\n";
  }

}

=head1 BUGS

Needs better documentation.

=head1 SEE ALSO

L<Net::XRC>,
Everyone.net XRC Remote API documentation (XRC-1.0.5.html or later)

=head1 AUTHOR

Ivan Kohler E<lt>ivan-xrc@420.amE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 Ivan Kohler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
