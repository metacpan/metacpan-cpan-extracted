package Net::SPAMerLookup;
#
# Masatoshi Mizuno E<lt>lusheE(<64>)cpan.orgE<gt>
#
# $Id: SPAMerLookup.pm 376 2009-01-26 02:13:00Z lushe $
#
use strict;
use warnings;
use Net::DNS;
use Net::Domain::TldMozilla;

our $VERSION = '0.10';

our @RBL_IP= qw/
 niku.2ch.net
 all.rbl.jp
 list.dsbl.org
 /;
our @RBL_URI= qw/
 url.rbl.jp
 notop.rbl.jp
 all.rbl.jp
 /;

our $TLDregex= do {
	my $tld= Net::Domain::TldMozilla->get_tld;
	join '|', map{quotemeta($_)}@$tld;
  };

sub import {
	my $class= shift; $_[0] || return $class;
	if (ref $_[0]) {
		if (ref($_[0]) eq 'HASH') {
			@RBL_URI= @{$_[0]->{URI}} if $_[0]->{URI};
			@RBL_IP = @{$_[0]->{IP}}  if $_[0]->{IP};
		} elsif (ref($_[0]) eq 'ARRAY') {
			@RBL_URI= @{$_[0]};
		} else {
			die __PACKAGE__.' - Argument of unsupported.';
		}
	} else {
		@RBL_URI= @_;
	}
	$class;
}
sub new {
	bless []; ## no critic.
}
sub check_rbl {
	my $self= shift;
	my $args= shift || die q{I want 'host name' or 'IP address' or 'URL'.};
	my $attr= shift || {};
	my $timeout= $attr->{timeout} || $self->[0] || 10;
	$args=~s/\s+//;
	if ($args=~m{^(?:ftps?|https?|gopher|news|nntp|telnet|wais)\://([^/\:]+)}) {
		$args= $1;
		$args=~s/^[^\@]+\@//;
		$args=~s/^[^\:]+\://;
		$args=~m{^([^/\:]+)} || die q{Invalid argument.};
		$args= $1;
	} elsif ($args=~m{^(?:mailto)\:(.+)}) {
		$args= $1;
		if ($args=~m{\@([^\@]+)$}) { $args= $1 }
	} elsif ($args=~m{\@([^\@]+)$}) {
		$args= $1;
	}
	my $dns= Net::DNS::Resolver->new;
	my $is_ip;
	my $check= $args=~m{^\d{1.3}\.\d{1.3}\.\d{1.3}\.\d{1.3}$} ? sub {
		$is_ip= 1;
		my $q= $dns->search("$args.$_[0]", 'PTR') || return 0;
		{
		  address=> $args,
		  result => [ map{$_->ptrdname}grep($_->type eq 'PTR', $q->answer) ],
		  };
	  }: do {
		$is_ip= 0;
		my $domain;
		sub {
			my $q= $dns->search("$args.$_[0]", 'A') || do {
				$domain
				||= do { $args=~m{([^\.]+\.(?:$TLDregex))$} ? $1 : 'unmatch' };
				return 0 if ($args eq $domain or $domain eq 'unmatch');
				my $result= $dns->search("$domain.$_[0]", 'A') || return 0;
				$args= $domain;
				$result;
			  };
			{
			  name  => $args,
			  result=> [ map{$_->address}grep($_->type eq 'A', $q->answer) ],
			  };
		  };
	  };
	eval {
		local $SIG{ALRM}= sub { die 'Timeout' };
		alarm $timeout;
		for ($is_ip ? @RBL_IP: @RBL_URI) {
			my $hit= $check->($_) || next;
			alarm 0;
			return { %$hit, RBL=> $_ };
		}
		alarm 0;
	  };
	if (my $error= $@) { $self->is_error($error) }
	0;
}
sub is_error {
	my $self= shift;
	return $self->[1] unless @_;
	$self->[1]= shift;
	0;
}
sub is_spamer {
	my $self= shift;
	for (@_) { if (my $target= $self->check_rbl($_)) { return $target } }
	0;
}

1;

__END__

=head1 NAME

Net::SPAMerLookup - Perl module to judge SPAMer.

=head1 SYNOPSIS

  use Net::SPAMerLookup {
    IP => [qw/ niku.2ch.net all.rbl.jp list.dsbl.org /],
    URI=> [qw/ url.rbl.jp notop.rbl.jp all.rbl.jp /],
    };
  
  my $spam= Net::SPAMerLookup->new;
  if ($spam->check_rbl($TARGET)) {
  	print "It is SPAMer.";
  } else {
  	print "There is no problem.";
  }
  
  # Whether SPAMer is contained in two or more objects is judged.
  if (my $spamer= $spam->is_spamer(@TARGET)) {
  	print "It is SPAMer.";
  } else {
  	print "There is no problem.";
  }

=head1 DESCRIPTION

SPAMer is judged by using RBL.

Please set HTTP_PROXY of the environment variable if you use Proxy.

see L<Net::Domain::TldMozilla>.

=head1 SETTING RBL USED

When passing it to the start option.

  use Net::SPAMerLookup qw/ all.rbl.jp .....  /;

When doing by the import method.

  require Net::SPAMerLookup;
  Net::SPAMerLookup->import(qw/ all.rbl.jp ..... /);

=head1 METHODS

=head2 new

Constructor.

  my $spam= Net::SPAMerLookup;

=head2 check_rbl ([ FQDN or IP_ADDR or URL ])

'Host domain name', 'IP address', 'Mail address', and 'URL' can be passed to the argument.

HASH including information is returned when closing in passed value RBL.

0 is returned when not closing.

Following information enters for HASH that was able to be received.

=over 4

=item * RBL

RBL that returns the result enters.

=item * name or address

The value enters 'Address' at 'Name' and "IP address" when the object is "Host domain name" form.

=item * result

Information returned from RBL enters by the ARRAY reference.

=back 

  if (my $result= $spam->check_rbl('samp-host-desuka.com')) {
    print <<END_INFO;
    It is SPAMer.
  
  RBL-Server: $result->{RBL}
  
  @{[ $result->{name} ? qq{Name: $result->{name}}: qq{Address: $result->{address}} ]}
  
  @{[ join "\n", @{$result->{result}} ]}
  
  END_INFO
  } else {
    print "There is no problem.";
    ......
    ...

=head2 is_error

error.

=head2 is_spamer ([TARGET_LIST])

'check_rbl' is continuously done to two or more objects.

And, HASH that 'check_rbl' returned is returned as it is if included.

  if (my $result= $spam->is_spamer(@TAGER_LIST)) {
    .........
    ....

=head1 SEE ALSO

L<Net::DNS>,
L<Net::Domain::TldMozilla>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lushe(E<64>)cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Bee Flag, Corp. E<lt>http://egg.bomcity.com/E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

