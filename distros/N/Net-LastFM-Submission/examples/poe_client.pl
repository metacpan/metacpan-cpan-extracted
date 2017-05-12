#!/usr/bin/perl
use strict;
use utf8;

use lib qw(../lib ..);
BEGIN { $ENV{'SUBMISSION_DEBUG'}++ };

use POE qw(Component::Client::HTTP);
use POE::Component::Net::LastFM::Submission 0.24; # support an existing client
use Data::Dumper;

my $conf = require '.lastfmrc';

POE::Component::Client::HTTP->spawn(
	Alias   => 'HTTP_CLIENT',
	Agent   => 'My http client/1.0',
	Timeout => 1,
	# ...
);

POE::Component::Net::LastFM::Submission->spawn(
	Alias   => 'LASTFM_SUBMIT',
	Client  => 'HTTP_CLIENT', # use my own client
	LastFM  => {map { $_ => $conf->{$_} } 'user', 'password'},
);

POE::Session->create(
	options       => { trace => 1 },
	inline_states => {
		_start => sub {
			$_[KERNEL]->post('LASTFM_SUBMIT' => 'handshake' => 'np');
			$_[KERNEL]->yield('_delay');
		},
		_delay => sub { $_[KERNEL]->delay($_[STATE] => 5) },
		
		np => sub {
			warn Dumper @_[ARG0, ARG1, ARG2];
			$_[HEAP]->{__i}++ == 10
				?
					$_[KERNEL]->post(
						'LASTFM_SUBMIT' => 'submit' => 'sb',
						{'artist' => 'ArtistName', 'title'  => 'TrackName', time => time - 10*60}
					)
				: 
					$_[KERNEL]->post(
						'LASTFM_SUBMIT' => 'now_playing' => 'np',
						{'artist' => 'Артист11', 'title'  => 'Песня21'},
						$_[HEAP]->{__i}
					)
			;
		},
		
		sb => sub {
			warn Dumper $_[ARG0];
			$_[KERNEL]->stop;
		},
	}
);

POE::Kernel->run;

__END__
=head1 NAME

examples/poe_client.pl - the example of usage POE::Component::Net::LastFM::Submission

=head1 SYNOPSIS

	cd examples; ./poe_client.pl

=head1 DESCRIPTION

See source code :)

=head1 AUTHOR

Anatoly Sharifulin, E<lt>sharifulin at gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Anatoly Sharifulin.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
