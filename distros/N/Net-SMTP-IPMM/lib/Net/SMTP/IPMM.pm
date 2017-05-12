package Net::SMTP::IPMM;

use strict;
use warnings;

use base 'Net::SMTP';

# import CMD_* constants
use Net::Cmd;

our $VERSION = '0.03';

sub ackrcpt {
    my ( $self, $command ) = @_;

    # object is a globref
    ${ *$self }{ipmm_ackrcpt} = $command ? 1 : 0;

    $self->_ACKRCPT( $command ? 'on' : 'off' );
}

sub xmrg {
    my ( $self, $address ) = @_;
    my $sender = $self->_addr( $address );

    $self->_XMRG( $sender );
}

sub xdfn {
    my $self = shift;
    my %args = @_;

    my $command = '*PARTS="' . delete( $args{ 'PARTS' } ) . '"';
    while ( my ( $key, $value ) = each %args ) {
	$command .= " $key=\"$value\"";
    }

    $self->_XDFN( $command );
}

sub xprt {
    my ( $self, @parts ) = @_;

    my $count = @parts;
    my $i = 1;

    foreach my $part( @parts ) { 
	my $command = $i;
	$command .= ' LAST' if $i == $count;

	$self->_XPRT( $command )   or return;
	$self->datasend( $part )   or return;

	$i++;
    }

    $self->dataend;
}

# _addr isn't in our contract, so we define it since it may change 
# between releases.  For example, see the difference between Net::SMTP 
# 2.24 and 2.26.  
sub _addr {
    my $self = shift;
    my $addr = shift;
    $addr = "" unless defined $addr;
    
    if ( ${ *$self }{net_smtp_exact_addr} ) {
	return $1 if $addr =~ /^\s*(<.*>)\s*$/s;
    }
    else {
	return $1 if $addr =~ /(<[^>]*>)/;
	$addr =~ s/^\s+|\s+$//sg;
    }
    
    "<$addr>";
}

sub _ACKRCPT { shift->command( "XLSMTP-ACKRCPT", @_ )->response == CMD_OK   }
sub _XMRG    { shift->command( "XMRG FROM:"    , @_ )->response == CMD_OK   }
sub _XDFN    { shift->command( "XDFN",           @_ )->response == CMD_OK   }

# XPRT returns OK on the first part and MORE on subsequent parts
# for no reason that I can figure out.
sub _XPRT    { 
    my $r = shift->command( "XPRT", @_ )->response;  
    return 1 if ( $r == CMD_OK ) or ( $r == CMD_MORE );
    return;
}


sub _RCPT { 
    my $self = shift;
    
    if( ${ *$self }{ipmm_ackrcpt} ) { 
	return $self->command( "RCPT", @_ )->response == CMD_OK;
    } else { 
	return $self->command( "RCPT", @_ );
    }
    
    return undef;
}


1;

__END__


=head1 NAME

Net::SMTP::IPMM - IronPort Mail-Merge interface

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Net::SMTP::IPMM;
    my $ipmm = Net::SMTP::IPMM->new( 'ipmmhost' );

    # define parts
    my $part1 = "From: me\@mydomain.org\n" .
                "To: &*TO;\n" .
                "Subject: This is a message\n\n" .
                "Dear &FNAME;,\n";
         
    my $part2 = "Your last name is &LNAME;.\n"; 

    # from addresss
    $self->xmrg( 'me@mydomain.com' );

    # first person, both parts
    $self->xdfn( parts => "1,2", 
                 fname => "Some",
                 lname => "Guy", );
    $self->to( 'someguy@example.com' );

    # second person, first part only
    $self->xdfn( parts => "1", 
                 fname => "Another",
                 lname => "Guy", );
    $self->to( 'anotherguy@somewhereelse.com' );

    # send the parts.
    $self->xprt( $part1, $part2 );

=head1 DESCRIPTION

IronPort Mail Merge (IPMM) is a proprietary extension to SMTP used on IronPort's
email
server appliances. This module is a subclass of L<Net::SMTP> which impliments
the IPMM extensions. All the Net::SMTP methods are inherrited by this module.
See the documentation for L<Net::SMTP> for general usage examples. For more
on IPMM, see the documentation that came with your IronPort appliance.

=head1 METHODS

=over 2

=item new 

Constructor. Pass the hostname of the IronPort as the first parameter:

    my $ipmm = Net::SMTP::IPMM->new( 'ironport.foo.com' );

For additional configuration options see the docs for L<Net::SMTP>.

=item ackrcpt( BOOL )

Turn RCPT acknowledgements on or off.  Off means less traffic and 
higher performance (which is probably why you bought an IronPort).
Pass any true value to turn RCPT acknowledgements on, false for off.

=item xmrg( ADDRESS )
 
This sends an XMRG FROM command (replacing MAIL FROM from regular SMTP.)
You must use this method to tell the IronPort that mail-merge data is coming.

    $ipmm->xmrg( 'me@mydomain.com' );

=item xdfn( PARTS => PART_NUMBERS,
            key   => value,
            key   => value,
            ...  )

This sends an XDFN command. XDFN is used to send each recipient's data to 
the IronPort. PART_NUMBERS is a string containing a comma-separated list
of "parts" for the recipient. The key/value pairs will be substituted
into the message by the IronPort. Note that message parts are not 
zero-indexed (the first one is "1".)

    $ipmm->xdfn( PARTS => "1,2,5",
                 fname => 'Mike',
                 lname => 'Friedman',
                 zip   => '11106' );
    $ipmm->to( 'mfriedman@plusthree.com' );

=item xprt( MESSAGE_PARTS )

This sends all the message parts to the IronPort and begins the mailing.
MESSAGE_PARTS is a list of strings containing the message parts with
the appropriate variables in them.

    my $part1 = "From: sender\@mydomain.org$CRLF" .
                "To: &*TO;$CRLF" .
                "Subject: message$CRLF$CRLF" .
                "Dear &FNAME;,$CRLF";

    my $part2 = "Your last name is &LNAME;.$CRLF";

    $ipmm->xprt( $part1, $part2 );


=back

=head1 THANKS

Thanks to Douglas Hunter for doing most of the work. :) 

=head1 AUTHORS

Mike Friedman C<< <mfriedman@plusthree.com> >>

Douglas Hunter, C<< <dug@plusthree.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-smtp-ipmm@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-SMTP-IPMM>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 PlusThree LP, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


