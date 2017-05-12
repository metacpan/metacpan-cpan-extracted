package Net::SMTP::Server::AnyEvent;

use 5.006;
use strict;
use warnings FATAL => 'all';
use AnyEvent::Socket;
use AnyEvent::Handle;


=head1 NAME

Net::SMTP::Server::AnyEvent - Expiremental SMTP server using AnyEvent!

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

An attempt at an SMTP server using AnyEvent. This server so far is NOT yet capable of relay and supports only the basic functions. At this point this module is EXPIREMENTAL, so use at your own risk. Functionality can change at any time.

    use Net::SMTP::Server::AnyEvent;

    my $smtp = Net::SMTP::Server::AnyEvent->new(
        Host=>'127.0.0.1',
        Port=>25,
        Debug=>1,
        Commands=>{
            EHLO=>sub{
                my ($self,$conn,$data)=@_;
                print "HELLO!\n";
            },
        }
    );

    

=head1 SUBROUTINES/METHODS

=head2 new

Host - Host of server
Port - Port of server
Debug - Enable debug output (Default: 0) [Optional]
Commands - Overload commands sent to the server [Optional]

EHLO, MAIL, RCPT, DATA, DATASEND, DATAEND, QUIT

=cut


sub new {
    my $class=shift;
    my $self={};
    my %new;
    

    
    bless($self, $class||'Net::SMTP::Server::AnyEvent');

    
    if ($#_ % 2 == 0) {
        $new{Host}=shift;
    }
    %new=@_;
    $self->{debug}  = (($new{Debug}||0) >= 1) ? $new{Debug}:0;
    $self->{debug_path} = $new{DebugPath}||'debug_[HOST]_[PORT].txt';
    $self->{new}=\%new;
    

    return $self;
}

sub start {
    my $self=shift;

    if (exists($self->{new}{Hosts})) {
       $self->_HOSTS($self->{new}{Hosts});
    } else {
       $self->_HOSTS([$self->{new}]);
    }
    
    AnyEvent->condvar->recv;
    
}

=head2 start

Starts the smtp server

$smtp->start();

=cut

sub _HOSTS {
    my $self=shift;
    my $hosts=shift;
    
    foreach my $host (@{$hosts}) {
        
        my $h=$host->{Host}||'127.0.0.1';
        my $p=$host->{Port}||25;
        
        $self->{host}{ $h }{ $p }=$h;
        $self->{port}{ $h }{ $p }=$p;
        $self->{commands}{ $h }{ $p }=$host->{Commands}||{};
        
        
        if ($self->{debug} == 2) {
            my $path=''.$self->{debug_path};
            $path=~s/\[HOST\]/$h/gs;
            $path=~s/\[PORT\]/$p/gs;
            open( $self->{debug_fh}{ $h.':'.$p } , '>>'.$path );
            binmode( $self->{debug_fh}{ $h.':'.$p } , ':utf8' );
        }
        
        $self->_CONNECT( $h, $p );
        
    }
    
}

sub _CONNECT {
    my $self=shift;
    my $h=shift;
    my $p=shift;

    $self->_DEBUG([$h,$p],"Listening on $self->{host}{ $h }{ $p } on port $self->{port}{ $h }{ $p }") if $self->{debug} >= 1;
    
    tcp_server $self->{host}{ $h }{ $p }, $self->{port}{ $h }{ $p }, sub {
        my ($fh, $host, $port) = @_;
        my $handle;
        $handle = AnyEvent::Handle->new(
            fh => $fh,
            poll => 'r',
            on_read => sub {
                my ($self_read) = @_;
                $self->{handle}{ $h }{ $p }{ $handle }->push_read (line => sub {
                    my ($hdl, $buf) = @_;
                    $self->_DEBUG([$h,$p,$hdl],$buf) if $self->{debug} >= 1;
                    $self->_PROCESS([$h,$p,$hdl],$buf);
                });    
            },
            on_eof => sub {
                my ($hdl) = @_;
                $hdl->destroy();
            },
        );
    
    $self->{handle}{ $h }{ $p }{ $handle }=$handle;
    $self->{data_mode}{ $h }{ $p }{ $handle }='none';
    $self->_WRITE([$h,$p,$handle],"220 $self->{host}{ $h }{ $p } ESMTP Postfix");
   
    
   };

    
    
}

sub _PROCESS {
    my $self=shift;
    my $k=shift;
    my $buf=shift;
    
    if ($buf=~m/^EHLO (.*?)$/is) {
        $self->_COMMAND($k,'EHLO',$1);
        $self->_WRITE($k,"250-${$k}[0]\015\012250-SIZE 31457280\015\012250 OK");
    } elsif ($buf=~m/^QUIT$/is) {
        $self->_COMMAND($k,'QUIT');
        $self->_WRITE($k,'221 Service closing transmission channel');
        ${ $k }[2]->destroy();
    } elsif ($buf=~m/^DATA$/is) {
        $self->_COMMAND($k,'DATA');
        $self->{data_mode}{ $k->[0] }{ $k->[1] }{ $k->[2] }='data';
        $self->{store}{data}{ $k->[0] }{ $k->[1] }{ $k->[2] }='';
        $self->_WRITE($k,'354 End data with <CR><LF>.<CR><LF>');
    } elsif ($self->{data_mode}{ $k->[0] }{ $k->[1] }{ $k->[2] } eq 'data' and $buf eq '.') {
        $self->_COMMAND($k,'DATAEND',$self->{store}{data}{ $k->[0] }{ $k->[1] }{ $k->[2] });
        $self->{data_mode}{ $k->[0] }{ $k->[1] }{ $k->[2] }='none';
        delete($self->{store}{data}{ $k->[0] }{ $k->[1] }{ $k->[2] });
        $self->_WRITE($k,'250 OK, Message Received');
    } elsif ( $self->{data_mode}{ $k->[0] }{ $k->[1] }{ $k->[2] } eq 'data' ) {
        $self->_COMMAND($k,'DATASEND',$buf);
        $self->{store}{data}{ $k->[0] }{ $k->[1] }{ $k->[2] }.=$buf;
    } else {
        
        if ($buf=~m/^MAIL FROM:(?: |)(.*?)$/is) {
            $self->_COMMAND($k,'MAIL',$1);        
        } elsif ($buf=~m/^RCPT TO:(?: |)(.*?)$/is) {
            $self->_COMMAND($k,'RCPT',$1);        
        } else {
            $self->_COMMAND($k,'DEFAULT',$buf);
        }
        $self->_WRITE($k,'250 OK');
    }
}

sub _COMMAND {
    my $self=shift;
    my $k=shift;
    my $cmd=shift;
    my $data=shift;
    
    no strict;
    &{ $self->{commands}{ $k->[0] }{ $k->[1] }{ $cmd } }($self,$k,$data) if exists($self->{commands}{ $k->[0] }{ $k->[1] }{ $cmd });
    
}

sub _WRITE {
    my $self=shift;
    my $k=shift;
    my $cont=shift;
    
    $self->_DEBUG($k,'> '.$cont) if $self->{debug} >= 1;
    ${$k}[2]->push_write($cont."\015\012")

}

sub _DEBUG {
    my $self=shift;
    my $k=shift;
    my $str=shift||'';
    if ($self->{debug} == 1) {
        print '['.$k->[0].':'.$k->[1].'] '.$str."\r\n";
    } else {
        syswrite $self->{debug_fh}{ $k->[0].':'.$k->[1] }, '['.$k->[0].':'.$k->[1].'] '.$str."\r\n";
        
    }
}


=head1 AUTHOR

KnowZero

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-smtp-server-anyevent at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-SMTP-Server-AnyEvent>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::SMTP::Server::AnyEvent


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-SMTP-Server-AnyEvent>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-SMTP-Server-AnyEvent>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-SMTP-Server-AnyEvent>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-SMTP-Server-AnyEvent/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 KnowZero.

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

1; # End of Net::SMTP::Server::AnyEvent
