package Net::UCP::Common;

use 5.008007;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(STX ETX UCP_DELIMITER DEF_SMSC_PORT ACK NACK DEBUG) ] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT      = qw();

our $VERSION = '0.05';

use constant STX           => chr(2);
use constant ETX           => chr(3);
use constant UCP_DELIMITER => '/';
use constant DEF_SMSC_PORT => 3024;
use constant ACK           => 'A';
use constant NACK          => 'N';

use constant DEBUG         => 0;

sub new {
    my $self = {};
    bless($self, shift())->_init(@_);
}

# Calculate packet checksum
sub checksum {
    shift;
    
    my $checksum;
    
    defined($_[0]) || return(0);
    map {$checksum += ord} (split //,pop @_);
    sprintf("%02X", $checksum%256);
    
}

# Calculate data length
sub data_len {
    shift;

    defined($_[0]) || return(0);
    my $len = length(pop @_) + 17;
    for(1..(5-length($len))) {
        $len = '0' . $len;
    }
    
    $len;
}

sub decode_7bit {
    shift;

    my ($oadc) = shift;
    my ($msg,$bits);
    my $cnt = 0;
    my $ud  = $oadc || "";
    my $len = length($ud);
    $msg    = "";

    my $byte = unpack('b8', pack('H2', substr($ud, 0, 2)));

    while (($cnt < length($ud)) && (length($msg) < $len)) {
        $msg .= pack('b7', $byte);
        $byte = substr($byte,7,length($byte)-7);
        if ( (length( $byte ) < 7) ) {
            $cnt+=2;
            $byte = $byte.unpack('b8', pack('H2', substr($ud, $cnt, 2)));
        }
    }

    return $msg;
}

#use Encode is the best solution
sub encode_7bit {
    my($self, $msg) = @_;
   
    my($bit_string, $user_data) = ('','');
    my($octet, $rest);
    
    defined($msg) && length($msg) || return('00');   # Zero length user data.

    for(split(//,$msg)) {
        $bit_string.=unpack('b7',$_);
    }

    while(defined($bit_string) && (length($bit_string))) {
        $rest = $octet = substr($bit_string,0,8);
        $user_data .= unpack("H2",pack("b8",substr($octet.'0'x7,0,8)));
        $bit_string = (length($bit_string) > 8) ? substr($bit_string,8) : '';
    }
    
    sprintf("%02X", length($rest) < 5 ? length($user_data)-1 : length($user_data)).uc($user_data);
}

sub convert_sms_to_ascii {
    my $self = shift;
    my $msg = shift;

    $msg =~ tr{\x00\x02\x05\x04\x06\x07\x08\x11\x5f\x7f}
    {\x40\x24\xe8\xe9\xf9\xec\xf2\x5f\xa7\xe0} if defined $msg;
 
    return $msg;
}


sub convert_ascii_to_sms {
    my $self = shift;
    my $msg = shift;
    
    $msg =~ tr{\x40\x24\xe8\xe9\xf9\xec\xf2\x5f\xa7\xe0}
    {\x00\x02\x05\x04\x06\x07\x08\x11\x5f\x7f} if defined $msg;
    
    return $msg;
}


sub ia5_decode {
    my ($self, $msg) = @_;

    my $tmp = "";
    my $out = "";

    while (length($msg)) {
        ($tmp,$msg) = ($msg =~ /(..)(.*)/);
        $out .= sprintf("%s", chr(hex($tmp)));
    }
    
    return $out;
}

sub ia5_encode { shift; join('',map {sprintf "%02X", ord} split(//,pop(@_))); }

sub error_by_code {
    my $self = shift;
    
    my $ec = shift || '';
    return $self->{EC}->{$ec};
}

sub _init { 
    my $self = shift;

    my %ec_string = (
		     ''   => 'Unknown error code',
		     '01' => 'Checksum error',
		     '02' => 'Syntax error',
		     '04' => 'Operation not allowed (at this point in time)',
		     '05' => 'Call barring active',
		     '06' => 'AdC invalid',
		     '07' => 'Authentication failure',
		     '08' => 'Legitimisation code for all calls, failure',
		     '24' => 'Message too long',
		     '26' => 'Message type not valid for the pager type',
		     );
    
    $self->{EC} = %ec_string;
    $self;
}


1;
__END__

=head1 NAME

Net::UCP::Common - Common Stuff for Net::UCP Module

=head1 SYNOPSIS

  use Net::UCP::Common;
  
  see Net::UCP documentation for more details

=head1 DESCRIPTION

=head2 EXPORT

None by default.

=head1 SEE ALSO

Net::UCP

=head1 AUTHOR

Marco Romano, E<lt>nemux@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Marco Romano

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
