package Surveyor::Benchmark::HTMLEntities;
use strict;
use warnings;

use subs qw();
use vars qw($VERSION $HTML);

$VERSION = '1.02';

use HTML::Entities;
use HTML::Escape;

=encoding utf8

=head1 NAME

Surveyor::Benchmark::HTMLEntities - Benchmark HTML entity escaping

=head1 SYNOPSIS

Install L<Surveyor::App> to get the C<survey> program.

To test the defaults:

	% survey -p Surveyor::Benchmark::HTMLEntities URL

To compare pure Perl behavior:

	% env PERL_ONLY=1 survey -p Surveyor::Benchmark::HTMLEntities URL

=head1 DESCRIPTION

L<HTML::Escape> provides a limited functionality HTML entity escaper.
It only handles C<< ><&"' >>. As such, it can be quite a bit faster
because it does less.

Here are some numbers from my Mid-2012 MacBook Air:

XS versus pure Perl:

	Benchmark: timing 10000 iterations of html_entities, html_escape...
	html_entities: 14 wallclock secs (14.09 usr +  0.01 sys = 14.10 CPU) @ 709.22/s (n=10000)
	html_escape:  1 wallclock secs ( 0.68 usr +  0.00 sys =  0.68 CPU) @ 14705.88/s (n=10000)

fair fight:

	Benchmark: timing 10000 iterations of html_entities, html_escape...
	html_entities: 14 wallclock secs (13.79 usr +  0.01 sys = 13.80 CPU) @ 724.64/s (n=10000)
	html_escape:  7 wallclock secs ( 7.57 usr +  0.01 sys =  7.58 CPU) @ 1319.26/s (n=10000)

=over 4

=item set_up( URL )

Fetch the web page and store it for use in the benchmarks.

=cut

sub set_up {
	my( $self, @args ) = @_;
	require Mojo::UserAgent;

	print "Fetching $args[0]\n";
	my $tx = Mojo::UserAgent->new->get( $args[0] );

	my $code = $tx->res->code;
	die "Status $code: Could not fetch $args[0]\n"
		unless $code == 200;

	$HTML = $tx->res->body;
	print "HTML is " . length($HTML) . " bytes\n";

	my %counts;
	$counts{'>'} = $HTML =~ tr/>//;
	$counts{'<'} = $HTML =~ tr/<//;
	$counts{'&'} = $HTML =~ tr/&//;
	$counts{"'"} = $HTML =~ tr/'//;
	$counts{'"'} = $HTML =~ tr/"//;

	printf qq(> (%d)\n< (%d)\n& (%d)\n' (%d)\n" (%d)\n),
		@counts{ qw(> < & ' ") };
	}
	
=item tear_down

=cut

sub tear_down {
	1;
	}

=item bench_html_escape

Use HTML::Escape to encode. This is an XS module.

HTML::Escape only encodes the C<< ><&"' >>.

=cut

sub bench_html_escape {
	my $escaped = HTML::Escape::escape_html( $HTML );
	}

=item bench_html_entities

Use HTML::Entities to encode. This is an pure Perl module.

I tell C<encode_entities> to only encode C<< ><&"' >> so it
matches what HTML::Escape will do. Otherwise, C<encode_entities>
escapes wide characters too.

=cut

sub bench_html_entities {
	my $escaped = HTML::Entities::encode_entities( $HTML, q(<>&"') );
	}

=back

=head1 TO DO


=head1 SEE ALSO


=head1 SOURCE AVAILABILITY

This source is in Github:

	http://github.com/briandfoy/surveyor-benchmark-htmlentities

=head1 AUTHOR

brian d foy, C<< <bdfoy@gmail.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
