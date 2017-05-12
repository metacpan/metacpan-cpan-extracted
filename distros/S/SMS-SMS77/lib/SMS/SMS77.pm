package SMS::SMS77;

use strict;
use warnings;

use LWP::UserAgent;
use Carp;
use Data::Dumper;

our $VERSION = 0.01;

=head1 NAME
  
SMS::SMS77 - inferface for sms77.de SMS Service
    
=head1 VERSION
      
Version 0.01

=cut

sub new {
    my $invocant = shift();
    my $class    = ref($invocant) || $invocant;
    my $self     = {
        '_lwp'   => LWP::UserAgent->new(),
				'url' => 'https://gateway.sms77.de/',
				'user' => undef,
				'password' => undef,
				'debug' => 0,
				'default_type' => 'standard',
				'timeout' => 30,
				'proxy' => undef,
        @_
    };

		$self->{'_lwp'}->agent('SMS::SMS77-perlmodule/'.$VERSION." with libwww-perl");
		$self->{'_lwp'}->timeout($self->{'timeout'});
		if(defined($self->{'proxy'})) {
			$self->{'_lwp'}->proxy(@{$self->{'proxy'}});
		}

    bless( $self, $class );

    return ($self);
}

sub timeout {
	my $self = shift();

	$self->{'timeout'} = shift;
	return($self->{'_lwp'}->timeout($self->{'timeout'}));
}

sub proxy {
	my $self = shift();

	$self->{'proxy'} = [ @_ ];
	return($self->{'_lwp'}->proxy(@{$self->{'proxy'}}));
}

sub send {
	my $self = shift;
	my $msg = shift;
	my %form;
	my $uri = URI->new($self->{'url'});
	my $ret;
	my $i;

	$form{'u'} = $self->{'user'};
	$form{'p'} = $self->{'password'};

	if(defined($msg->{'type'})) {
		$form{'type'} = $msg->{'type'};
	} else {
		$form{'type'} = $self->{'default_type'};
	}

	foreach $i ('from', 'text', 'status') {
		if(defined($msg->{$i})) {
			$form{$i} = $msg->{$i};
		}
	}

	if($self->{'debug'}) {
		$form{'debug'} = 1;
	}
	if(defined($msg->{'delay'})) {
		$form{'delay'} = $msg->{'delay'}->epoch();
	}
	$form{'to'} = join("\n", @{$msg->{'to'}});

	$uri->query_form(\%form);
	$ret = $self->{'_lwp'}->get($uri);

	if($self->{'debug'}) {
		print Dumper($ret);
	}
	return($ret->content);
}

=head1 see also

SMS::SMS77::Message

=head1 AUTHOR

Markus Benning, C<< <me at w3r3wolf.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Markus Benning, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of SMS::SMS77

# vim:ts=2:syntax=perl:
# vim600:foldmethod=marker:

