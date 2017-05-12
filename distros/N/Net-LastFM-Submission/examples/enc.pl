#!/usr/bin/perl
use strict;

BEGIN { $ENV{'SUBMISSION_DEBUG'}++ };
use lib qw(../lib ..);
use Net::LastFM::Submission 0.61;
use Data::Dumper;

my $a = 'Привет';
# Encode::_utf8_on($a);
warn Encode::is_utf8($a);
warn $a = Net::LastFM::Submission::encode_data($a, 'cp1251');
warn Encode::is_utf8($a);
warn $a;

my $conf = require '.lastfmrc';

my $submit = Net::LastFM::Submission->new(map { $_ => $conf->{$_} } 'user', 'password');

warn Dumper $submit->handshake;

warn Dumper $submit->submit(
	'artist' => 'Артист',
	'title'  => 'Песня',
	'time'   => time - 10*60,
);

warn Dumper $submit->now_playing(
	'artist' => 'Артист',
	'title'  => 'Песня2',
);

__END__
=head1 NAME

examples/enc.pl - the example of usage Net::LastFM::Submission with encode_data

=head1 SYNOPSIS

	cd examples; ./enc.pl

=head1 DESCRIPTION

See source code :)

=head1 AUTHOR

Anatoly Sharifulin, E<lt>sharifulin at gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Anatoly Sharifulin.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
