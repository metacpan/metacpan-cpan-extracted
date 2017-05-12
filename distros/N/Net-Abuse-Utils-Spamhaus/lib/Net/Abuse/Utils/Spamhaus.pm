package Net::Abuse::Utils::Spamhaus;

use 5.008008;
use strict;
use warnings;

our $VERSION = '0.09';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

=head1 NAME

Net::Abuse::Utils::Spamhaus - Perl extension for checking data against the spamhaus blacklists

=head1 SYNOPSIS

  use Net::Abuse::Utils::Spamhaus qw(check_fqdn check_ip);
  my $addr = '222.186.44.110';
  my $ret = check_ip($addr);

  $addr = 'test';
  $ret = check_fqdn($addr);

  foreach (@$ret){
    warn $_->{'assessment'}.': '.$_->{'description'}.' -- '.$_->{'id'};
  }

=head1 DESCRIPTION

=head2 EXPORT

check_ip, check_fqdn
=cut

require Exporter;
our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::Abuse::Utils::Spamhaus ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
    check_ip check_fqdn	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    check_ip check_fqdn	
);

# Preloaded methods go here.
# http://www.spamhaus.org/zen/
my $ip_codes = {
    '127.0.0.2' => {
        assessment  => 'spam',
        description => 'Direct UBE sources, spam operations & spam services',
    },
    '127.0.0.3' => {
        assessment  => 'spam',
        description => 'Direct snowshoe spam sources detected via automation',
    },
    '127.0.0.4' => {
        assessment  => 'exploit',
        description => 'CBL + customised NJABL. 3rd party exploits (proxies, trojans, etc.)',
    },
    '127.0.0.5' => {
        assessment  => 'exploit',
        description => 'CBL + customised NJABL. 3rd party exploits (proxies, trojans, etc.)',
    },
    '127.0.0.6' => {
        assessment  => 'exploit',
        description => 'CBL + customised NJABL. 3rd party exploits (proxies, trojans, etc.)',
    },
    '127.0.0.7' => {
        assessment  => 'exploit',
        description => 'CBL + customised NJABL. 3rd party exploits (proxies, trojans, etc.)',
    },
    '127.0.0.9' => {
        assessment  => 'suspicious',
        description => 'hijacked prefix',
    },
    '127.0.0.10' => {
        assessment  => 'spam',
        description => 'End-user Non-MTA IP addresses set by ISP outbound mail policy',
    },
    '127.0.0.11' => {
        assessment  => 'spam',
        description => 'End-user Non-MTA IP addresses set by ISP outbound mail policy',
    },
};

# http://www.spamhaus.org/faq/section/Spamhaus%20DBL
my $fqdn_codes = {
    '127.0.1.2' => {
        assessment  => 'suspicious',
        description => 'spammed domain',
    },
    '127.0.1.3' => {
        assessment  => 'suspicious',
        description => 'spammed redirector / url shortener',
    },
    '127.0.1.4' => {
        assessment  => 'phishing',
        description => 'phishing domain',
    },
    '127.0.1.5' => {
        assessment  => 'malware',
        description => 'malware domain',
    },
    '127.0.1.6' => {
        assessment  => 'botnet',
        description => 'Botnet C&C domain',
    },
    '127.0.1.102' => {
        assessment  => 'suspicious',
        description => 'abused legit spam',
    },
    '127.0.1.103' => {
        assessment  => 'suspicious',
        description => 'abused legit spammed redirector',
    },
    '127.0.1.104' => {
        assessment  => 'phishing',
        description => 'abused legit phish',
    },
    '127.0.1.105' => {
        assessment  => 'malware',
        description => 'abused legit malware',
    },
    '127.0.1.106' => {
        assessment  => 'botnet',
        description => 'abused legit botnet',
    },
    '127.0.1.255'   => {
        description => 'BANNED',
    },
};

sub _return_rr {
    my $lookup  = shift;
    my $type    = shift || 'A';
    my $timeout = shift;
    
    # little more thread friendly
    require Net::DNS::Resolver;
    my $r = Net::DNS::Resolver->new(recursive => 0);
    
    if($timeout){
        $r->udp_timeout($timeout);
        $r->tcp_timeout($timeout);
    }
    

    my $pkt = $r->send($lookup);
    return unless($pkt);
    my @rdata = $pkt->answer();
    return unless(@rdata);
    return (\@rdata);
}
=head2 FUNCTIONS

=over
       
=item check_fqdn(<FQDN>)

  accepts: a fully qualified domain name (ex: example.com)
  returns: an ARRAYREF of HASHREF's based on the spamhaus dbl

=cut

sub check_fqdn {
    my $addr = shift;
    my $timeout = shift || 10;

    my $lookup = $addr.'.dbl.spamhaus.org';
    my $rdata = _return_rr($lookup,undef,$timeout);
    return unless($rdata);
    
    my @array;
    foreach (@$rdata){
        next unless($_->address());
        next unless($_->type() eq 'A');
        my $code = $fqdn_codes->{$_->address()};
        unless($code){
            warn 'unknown return code: '.$_->address().' library ('.$VERSION.') needs updating, contact module author ('.$lookup.')';
            $code->{'description'} = 'unknown' unless($code->{'description'});
            $code->{'assessment'} = 'unknown' unless($code->{'assessment'});
        }

        if($code->{'description'} =~ /BANNED/){
            warn 'BANNED received from spamhaus, you should contact them and work it out';
            return;
        }
        push(@array,{
            id          => 'http://www.spamhaus.org/query/dbl?domain='.$addr,
            assessment  => $code->{'assessment'},
            description => $code->{'description'},
        });
    }
    return(\@array);
}

=item check_ip(<ipv4-addr>)

  accepts: a properly formatted ipv4 address (ex: 1.1.1.1)
  returns: an ARRAY REF of HASHREF's based on feedback from the spamhaus zen list

=cut

sub check_ip {
    my $addr = shift;
    my $timeout = shift;
   
    my @bits = split(/\./,$addr);
    my $lookup = join('.',reverse(@bits));
    $lookup .= '.zen.spamhaus.org';

    my $rdata = _return_rr($lookup,undef,$timeout);
    return unless($rdata);
    
    my $array;
    foreach (@$rdata){
        next unless($_->type() eq 'A');
        my $code = $ip_codes->{$_->address()};
        
        unless($code){
            warn 'unknown return code: '.$_->address().' library ('.$VERSION.') needs updating, contact module author ('.$lookup.')';
            $code->{'description'} = 'unknown' unless($code->{'description'});
            $code->{'assessment'} = 'unknown' unless($code->{'assessment'});
        }

        # these aren't really malicious assessments, skip them
        # see http://www.spamhaus.org/faq/answers.lasso?section=Spamhaus%20PBL#183
        next if($_->address() =~ /\.(10|11)$/);
        push(@$array,{
            assessment  => $code->{'assessment'},
            description => $code->{'description'},
            id          => 'http://www.spamhaus.org/query/bl?ip='.$addr,
        });
    }
    return($array);
} 
    
1;
__END__
=back

=head1 SEE ALSO

  http://www.spamhaus.org/zen/
  http://www.spamhaus.org/dbl/

=head1 AUTHOR

Wes Young, E<lt>wes@barely3am.comE<gt>

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2012 by Wes Young (wesyoung.me)

  This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself, either Perl version 5.10.1 or,
  at your option, any later version of Perl 5 you may have available.

=cut
