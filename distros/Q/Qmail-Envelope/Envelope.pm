package Qmail::Envelope;
use strict;

use vars qw/$VERSION/;
$VERSION = '0.53';


## constructor
sub new {
    my $class = shift;
    my $self = {
        data   => '',
        recips => '',
        sender => '',
        @_
    };

    bless($self, $class);

    $self->{'sender'} = '';
    $self->{'recips'} = [];
    $self->{'rcpt_hosts'} = {};
    $self->{'recips_map'} = {};

    if ($self->{'data'}) {
        $self->init_envelope_data;
    }

    return $self;

}

## if the constructor is called with the 'data' attribute defined ...
sub init_envelope_data {
    my $self = shift;

    ## elegant rewrite by Peter Pentchev -- thanks!
    return 0 unless $self->{'data'} =~ /^F([^\0]+)\0T(.*?)\0\0/;
    my ($sender, @recips) = ($1, split(/\0T/, $2));

    $self->{'sender'} = $sender;
    $self->{'recips'} = [ @recips ];

    $self->map_recips;

}

sub add_recip {
    my $self = shift;
    push (@{$self->{'recips'}}, shift());
    $self->map_recips;
}

sub remove_recip {
    my $self = shift;
    my $recip = shift;

    my $new_recips = [];
    foreach my $r (@{$self->{'recips'}}) {
        next if ($r eq $recip);
        push (@$new_recips, $r);
    }

    $self->{'recips'} = $new_recips;
    $self->map_recips;

}

sub remove_recips_for_host {
    my $self = shift;
    my $rcpt_host = shift;

    my $new_recips = [];
    foreach my $r (@{$self->{'recips'}}) {
        $r =~ /^.*@(\S+)$/io;
        next if ($1 eq $rcpt_host);

        push (@$new_recips, $r);

    }

    $self->{'recips'} = $new_recips;

    $self->map_recips;

}

sub remove_all_recips {
    my $self = shift;
    $self->{'recips_map'} = {};
    $self->{'recips'} = [];
    $self->{'rcpt_hosts'} = {};
}


sub map_recips {
    my $self = shift;

    ## maps instances of a recipient within the 'recips' array
    $self->{'recips_map'} = {};

    ## maps instances of a host in the 'recips' array
    $self->{'rcpt_hosts'} = {};

    my $index = 0;

    foreach my $r (@{$self->{'recips'}}) {

        if (exists($self->{'recips_map'}->{$r})) {
            push(@{$self->{'recips_map'}->{$r}}, $index);
        }

        else {
            $self->{'recips_map'}->{$r}->[0] = $index;
        }

        ## pull off the host
        $r =~ /^.*@(\S+)$/io;

        unless ($self->{'rcpt_hosts'}->{$1}) {
            $self->{'rcpt_hosts'}->{$1} = [];
        }

        push(@{$self->{'rcpt_hosts'}->{$1}}, $index);

        $index++;
    }
}

sub gen {

    my $self = shift;
    my $e = 'F' . $self->{'sender'} . "\0";

    foreach my $r (@{$self->{'recips'}}) {
        $e .= 'T' . $r . "\0";
    }

    $e .= "\0";

    return $e;

}

sub as_string {

    my $self = shift;
    my $e = 'F' . $self->{'sender'};

    foreach my $r (@{$self->{'recips'}}) {
        $e .= 'T' . $r;
    }

    return $e;

}

sub rcpt_hosts {
    return [ keys %{ shift()->{'rcpt_hosts'} }];
}


sub sender {
    my $self = shift;
    my $sender = shift || '';

    return $self->{'sender'} unless ($sender);

    $self->{'sender'} = $sender;
}

sub total_recips {
    return scalar(@{ shift()->{'recips'} });
}

sub total_recips_for_host {
    my $self = shift;
    return scalar(@{ $self->{'rcpt_hosts'}->{shift()} });
}

sub remove_duplicate_recips {
    my $self = shift;

    my $recip_hash = {};

    foreach my $r (@{$self->{'recips'}}) {
        $recip_hash->{$r} = 1;
    }

    $self->{'recips'} = keys %$recip_hash;

    $self->map_recips;
}


1;
__END__

=head1 NAME

Qmail::Envelope - Perl module modifying qmail envelope strings.

=head1 SYNOPSIS

  use Qmail::Envelope;

  ## When you have received the envelope from qmail-smtpd
  my $E = Qmail::Envelope->new (data => $Envelope);

  ## or if you want to create one on the fly ...
  my $E = Qmail::Envelope->new();

  ## add a recipient
  $E->add_recip('foo@bar.com');

  ## remove a recipient
  $E->remove_recip('foo@ack.com');

  ## remove all recipients for a specific domain
  $E->remove_recips_for_host('quux.com');

  ## clear the entire recipient list
  $E->remove_all_recips;

  ## get ref to an array containing the list of hosts in the envelope
  my $host_list = $E->rcpt_hosts;

  ## get envelope sender
  my $sender = $E->sender;
  
  ## set envelope sender 
  $E->sender('blarch@chunk.com');

  ## get the total number of recipients in the envelope.
  ## duplicates are counted.
  my $number_of_recips = $E->total_recips;

  ## get the total numbers of recips for a specific host
  my $number_of_recips = $E->total_recips_for_host('frobnicate.com');

  ## remove duplicate recipient entries in the envelope
  $E->remove_duplicate_recips;

  ## pretty print the envelope
  print $E->as_string;

  ## complete formatted envelope, with terminating null bytes and all.
  my $envelope = $E->gen;

=head1 DESCRIPTION

This module takes a qmail envelope, and allows you perform
operations on it. You can also create qmail envelopes from
scratch.  A quick background: qmail-smtpd hands all mail messages
it receives to the mail queuer program, qmail-queue.  qmail-queue
gets the message (headers and body) from qmail-smtpd on file
descriptor 1, and the envelope on file descriptor 2.  Yeah, I
thought it was weird at first too.

Anyway, the envelope is a string which contains the sender and all of
the recipients of a mail message.  This envelope may or may not
match the headers of the mail message (think cc and bcc).  The envelope
tells qmail-queue where the message is from, and where it is going
to.  

This module my help you if you have decided to insert a perl script
in between qmail-smtpd and qmail-queue.  There is an interesting open
source program called qmail-scanner which (in its documentation) explains
how to accomplish this this neat trick.

I hope this module helps someone out there.  I've been using it in a
production environment for some time now, and it seems stable.


=head2 EXPORT

None by default.


=head1 SEE ALSO

Useful to me was qmail-scanner program, located at:
http://qmail-scanner.sourceforge.net/

Also helpful were the man pages for qmail-smtpd, qmail-queue,
and envelopes.  They all come with the qmail mail server source.

You can see the other (few) things I've written at 
http://www.avitable.org/software


=head1 AUTHOR

root, E<lt>mja-perl@escapement.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Matt J. Avitable

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

