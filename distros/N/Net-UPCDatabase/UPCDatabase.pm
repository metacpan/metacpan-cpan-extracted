package Net::UPCDatabase;

use 5.008;
use Frontier::Client;

our $VERSION = '0.07';

our $DEFAULTURL = 'http://www.upcdatabase.com/rpc';

=head1 NAME

Net::UPCDatabase - Simple OO interface to UPCDatabase.com

=head1 SYNOPSIS

  use Net::UPCDatabase;
  my $upcdb = Net::UPCDatabase->new;

  print "\n[lookup]\n";
  my $upc = '035000764119';
  my $item = $upcdb->lookup($upc);
  print "UPC: $item->{upc}\n";
  if ($item->{error}) {
    print "Error: $item->{error}\n";
  }
  else {
    print "Product: $item->{description}\n";
    print "Size: $item->{size}\n";
  }

  print "\n[convertUpcE]\n";
  my $upcE = '01212901';
  my $upcA = $upcdb->convertUpcE($upcE);
  print "UPCE: $upcA->{upcE}\n";
  if ($upcA->{error}) {
    print "Error: $upcA->{error}\n";
  }
  else {
    print "UPCA: $upcA->{upc}\n";
  }

  print "\n[calculateCheckDigit]\n";
  my $upcC = '01200000129C';
  my $upcA = $upcdb->calculateCheckDigit($upcE);
  print "UPCC: $upcA->{upcC}\n";
  if ($upcA->{error}) {
    print "Error: $upcA->{error}\n";
  }
  else {
    print "UPCA: $upcA->{upc}\n";
  }

=head1 DESCRIPTION

Connects to UPCDatabase.com to get information about a given UPC.

=head1 FUNCTIONS

=head2 new

  $upcObject = Net::UPCDatabase->new;

  # .. or ..

  $upcObject = Net::UPCDatabase->new( url => $aDifferentUrlThanDefault );

Accepts an B<OPTIONAL> argument, a URL to use instead of the default.  Unless you're really sure what you're doing, don't give it a URL.  It defaults to 'http://www.upcdatabase.com/rpc', which is probably the right thing.

Returns the object.

=cut

sub new {
  my $class = shift;
  my $self = bless({}, $class);
  my %arg = @_;
  $self->{_debug} = $arg{debug} || 0;
  $self->{_url} = $arg{url} || $DEFAULTURL;
  $self->{_coder} = Frontier::RPC2->new;
  $self->{_server} = Frontier::Client->new('url' => $self->{_url}, debug => $self->{_debug});
  return $self;
}

=head2 lookup

  $itemInfo = $upcObject->lookup($upc);

  # example usage
  my $ean = '0012000000133'; # pepsi 12oz can
  print "EAN: $ean\n";
  my $item = $upcdb->lookup($ean);
  die "LOOKUP-ERROR: $item->{error}\n" if $item->{error};
  print Dumper($item);

Accepts a B<REQUIRED> argument, the UPC to lookup.
The UPC can be UPC-E (8 digits), UPC-A (12 digits), or EAN (13 digits).

Returns the data about the given UPC in a hash reference.

On error, it returns the given error reason as C<< $itemInfo->{error} >>.

=cut

sub lookup
{
  my $self = shift;
  my $upc = uc(shift);
  my $response = {};
  $upc =~ s|X|C|g;
  $upc =~ s|[^0-9C]||g;
  if ($upc =~ m|^\d{8}$|)
  {
    my $upcA = $self->convertUpcE($upc);
    if ($upcA->{error})
    {
      $response = $upcA;
    }
    else
    {
      $upc = $upcA->{upc};
    }
  }
  if (!$response->{error} && $upc =~ m|C|)
  {
    my $upcC = $self->calculateCheckDigit($upc);
    if ($upcC->{error})
    {
      $response = $upcC;
    }
    else
    {
      $upc = $upcC->{upc};
    }
  }
  $upc = substr(('0' x 13).$upc, -13, 13); # if it ain't a 13-digit EAN, make it one.
  if (!$response->{error})
  {
    my $data = $self->{_server}->call('lookupEAN', $self->{_coder}->string($upc));
    if (ref($data) eq "HASH")
    {
      $response = $data;
    }
    else
    {
      $response->{upc} = $upc;
      $response->{error} = $data;
    }
  }
  return $response;
}

=head2 convertUpcE

  $ean = $upcObject->convertUpcE($upcE);
  die "ERROR: $ean->{error}\n" if $ean->{error};
  print "EAN: $ean->{ean}\n";

  # example usage
  my $upce = '01201701'; # pepsi 24 pack
  print "UPCE: $upce\n";
  $ean = $upcdb->convertUpcE($upce);
  die "EAN-ERROR: $ean->{error}\n" if $ean->{error};
  print "EAN: $ean->{ean}\n";
  $item = $upcdb->lookup($ean->{ean});
  die "LOOKUP-ERROR: $item->{error}\n" if $item->{error};
  print Dumper($item);

Accepts a B<REQUIRED> argument, the UPC-E to convert.

Returns the EAN (exactly 13 digits).

On error, it returns the given error reason as C<< $itemInfo->{error} >>.

=cut

sub convertUpcE
{
  my $self = shift;
  my $upc = shift;
  my $data = $self->{_server}->call('convertUPCE', $self->{_coder}->string($upc));
  my $response = {};
  $response->{upcE} = $upc;
  if ($data =~ m|^\d{13}$|)
  {
    $response->{ean} = $data;
  }
  else
  {
    $response->{error} = $data;
  }
  return $response;
}

=head2 calculateCheckDigit

  $ean = '001200000C2X1';  # bad (more than one digit being calculated)
  $ean = '001200000C29C';  # bad (more than one digit being calculated)
  $ean = '001200000129C';  # good (only one digit)
  $ean = '00120000012C1';  # good (only one digit)
  $ean = $upcObject->calculateCheckDigit($ean);
  die "ERROR: $ean->{error}\n" if $ean->{error};
  print "EAN: $ean->{ean}\n";

Accepts a B<REQUIRED> argument, the UPC-A or EAN with checkdigit placeholder (C or X) to calculate.
This function will calculate the missing digit for any position, not just the last position.
This only works if only one digit being calculated.
This doesn't work with UPC-E.
There is no difference between using "X" or "C" as the placeholder.

Returns the EAN with the checkdigit properly calculated.

On error, it returns the given error reason as C<< $itemInfo->{error} >>.

NOTE:  This uses an internal function, not the function on UPCDatabase.com because it appears that it is currently not
implemented on the UPCDatabase.com side of things.
If it is implemented to the same extent on UPCDatabase.com, it is a simple change to use it instead.

=cut

sub calculateCheckDigit
{
  my $self = shift;
  my $upc = uc(shift);
  return $self->_calculateCheckDigit($upc); ## ???: If UPCDatabase.com supports this function (no longer "Unimplemented"), maybe remove this line?
  #$upc =~ s|X|C|g;
  #my $data = $self->{_rpcClient}->send_request('calculateCheckDigit', $upc)->value;
  #my $response = {};
  #$response->{upcC} = $upc;
  #if ($data =~ m|^\d{12}$|)
  #{
  #  $response->{upc} = $data;
  #}
  #else
  #{
  #  $response->{error} = $data;
  #  if ($response->{error} eq "Unimplemented")
  #  {
  #    return $self->_calculateCheckDigit($upc);
  #  }
  #}
  #return $response;
}

=head2 _calculateCheckDigit

The internal function that calculates the check digit.
You won't want to use this yourself.

=cut

sub _calculateCheckDigit
{
  my $self = shift;
  my $upc = uc(shift);
  $upc = substr(('0' x 13).$upc, -13, 13); # if it ain't a 13-digit EAN, make it one.
  $upc =~ s|X|C|g;
  my $response = {};
  $response->{eanC} = $upc;
  if ($upc =~ m|^([C\d]{12})([C\d])$| && $upc !~ m|C.*?C|)
  {
    my $code = $1;
    my $check = $2;
    my @odd = ();
    my @even = ();
    my $i = 0;
    my $oddTotal = 0;
    my $oddMissing = 0;
    my $evenTotal = 0;
    my $evenMissing = 0;
    foreach my $digit (split(//, $code))
    {
      if ($i++ % 2)
      {
        if ($digit eq "C")
        {
          $oddMissing++;
        }
        else
        {
          $oddTotal += $digit * 3;
        }
      }
      else
      {
        if ($digit eq "C")
        {
          $evenMissing++;
        }
        else
        {
          $evenTotal += $digit;
        }
      }
    }
    if ($check eq "C")
    {
      my $theTotal = $evenTotal + $oddTotal;
      $theTotal -= int($theTotal / 10) * 10;
      $theTotal ||= 10;
      $check = 10 - $theTotal;
    }
    elsif ($oddMissing)  # ???: Is there a better way to do this than a wasteful brute force method?
    {
      my $isDigit = 0;
      foreach $digit (0 .. 9)
      {
        my $theTotal = $evenTotal + $oddTotal + ($digit * 3);
        $theTotal -= int($theTotal / 10) * 10;
        $theTotal ||= 10;
        my $tCheck = 10 - $theTotal;
        if ($check == $tCheck)
        {
          $isDigit = $digit;
        }
      }
      $code =~ s|C|$isDigit|;
    }
    elsif ($evenMissing)
    {
      my $theTotal = $evenTotal + $oddTotal + $check;
      $theTotal -= int($theTotal / 10) * 10;
      $theTotal ||= 10;
      my $diff = 10 - $theTotal;
      $code =~ s|C|$diff|;
    }
    $response->{ean} = $code.$check;
  }
  else
  {
    $response->{error} = 'Unimplemented';
  }
  return $response;
}

=head1 DEPENDENCIES

L<Frontier::Client>
L<Frontier::RPC2>

=head1 TODO

=over

=item UPC checksum checking/creation

Clean up calculation of odd-position checkdigit calculation.
It currently uses an inefficient brute-force method of calculation for that position.
Even-position and checksum position calculation is pretty efficient.
OEOEOEOEOEOX (O=odd, E=even, X=checksum)
It's not *really* that wasteful, just not as efficient as it could be.

=back

=head1 BUGS

Report bugs on the CPAN bug tracker.
Please, do complain if something is broken.

=head1 SEE ALSO

L<http://www.upcdatabase.com/>

=head1 COPYRIGHT AND LICENSE

Copyright 2005-2009 by Dusty Wilson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
