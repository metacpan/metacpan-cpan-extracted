#!/usr/bin/perl
use utf8; # encoding="utf-8"
use strict;

use lib qw(../lib ..);
BEGIN { $ENV{'SUBMISSION_DEBUG'}++ };
use Net::LastFM::Submission;
use Data::Dumper;

warn $Net::LastFM::Submission::VERSION;

my $conf = require '.lastfmrc';

my $submit = Net::LastFM::Submission->new(map { $_ => $conf->{$_} } 'user', 'password');

$submit->handshake;

warn Dumper $submit->submit(
	'artist' => 'Артист1',
	'title'  => 'Песня1',
	'time'   => time - 10*60,
);

# no module encoding
warn Dumper $submit->now_playing(
	'artist' => 'Артист2',
	'title'  => 'Песня2',
);

__END__
=head1 NAME

examples/submit.pl - the example of usage Net::LastFM::Submission

=head1 SYNOPSIS

	cd examples; ./submit.pl

=head1 DESCRIPTION

See source code :)

=head1 AUTHOR

Anatoly Sharifulin, E<lt>sharifulin at gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Anatoly Sharifulin.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
