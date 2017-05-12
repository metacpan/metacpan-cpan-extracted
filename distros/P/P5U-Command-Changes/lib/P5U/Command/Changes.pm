package P5U::Command::Changes;

use 5.010;
use strict;
use utf8;
use P5U-command;

use match::simple;

BEGIN {
	$P5U::Command::Changes::AUTHORITY = 'cpan:TOBYINK';
	$P5U::Command::Changes::VERSION   = '0.002';
}

use constant {
	abstract    => q[view change logs],
	usage_desc  => q[%c changes DIST_OR_MODULE VERSIONS?],
};

sub command_names {qw{ changes change changelog ch }}

sub opt_spec
{
	(
		[verbatim => 'show the Changes file verbatim'],
	);
}

sub _metacpan
{
	require JSON;
	require LWP::UserAgent;
	my ($self, @path) = @_;
	state $ua = LWP::UserAgent->new(
		agent => sprintf('%s/%s ', ref $self, $self->VERSION),
	);
	
	my $path = join '/', @path;
	my $r = $ua->get("http://api.metacpan.org/$path");
	$r->is_success or die("HTTP request failed");
	if ($r->content_type =~ /json/i)
	{
		return JSON::from_json( $r->decoded_content );
	}
	else
	{
		return $r->decoded_content;
	}
}

my $DATE = qr/^\d{4}-\d{2}-\d{2}/;
sub execute
{
	require CPAN::Changes;
	
	my ($self, $opt, $args) = @_;
	
	my ($dist, $versions) = @$args
		or $self->usage_error("must provide a distribution name");
	
	my ($release, $author, $latest);
	if ($dist =~ m{::})
	{
		$dist =~ s/^:://;
		$dist =~ s/::$//;
		my $data = $self->_metacpan('v0', module => $dist);
		($release, $author, $latest) = ($data->{release}, $data->{author}, $data->{version});
	}
	else
	{
		my $data = $self->_metacpan('v0', release => $dist);
		($release, $author, $latest) = ($data->{name}, $data->{author}, $data->{version});
	}

	my $changes = $self->_metacpan(source => ($author, $release, 'Changes'));
	if ($opt->{verbatim})
	{
		print $changes;
		exit;
	}

	my ($start, $end);
	if (defined $versions and $versions =~ /\.{2}/)
		{ ($start, $end) = split /\.{2}/, $versions }
	elsif (defined $versions and $versions |M| $DATE)
		{ ($start, $end) = ($versions, $latest) }
	elsif (defined $versions and length $versions)
		{ ($start, $end) = ($versions) x 2 }
	$start ||= 0;
	$end   ||= $latest;
	
	my ($start_is_date, $end_is_date);
	for ($start, $end)
	{
		next unless /^C/i;
		require Module::Info;
		my $mod = Module::Info->new_from_module($dist)
			or die "Unable to find local module info for '$dist'";
		$_ = $mod->version;
	}

	my ($start_is_date, $end_is_date) = map { $_ |M| $DATE } ($start, $end);

	for my $R (CPAN::Changes->load_string($changes)->releases)
	{
		next if (
				($R->version  < $start and not $start_is_date)
			or ($R->version  > $end   and not $end_is_date)
			or ($R->date    lt $start and     $start_is_date)
			or ($R->date    gt $end   and     $end_is_date)
		);
		print $R->serialize;
	}
}

1;

__END__

=head1 NAME

P5U::Command::Changes - p5u extension to view change logs

=head1 SYNOPSIS

Show changes to Test-Fatal distribution

	$ p5u changes Test-Fatal

Show changes to whatever distribution provides the Test::Fatal module

	$ p5u changes Test::Fatal

Show changes for Test-Fatal 0.002

	$ p5u changes Test-Fatal 0.002

Show changes between Test-Fatal 0.002 and 0.004 (inclusive)

	$ p5u changes Test-Fatal 0.002..0.004

Show changes between Test-Fatal 0.002 and currently installed version
(only works for modules, not distributions).

	$ p5u changes Test::Fatal 0.002..c

Show changes during the year 2011

	$ p5u changes Test-Fatal 2011-01-01..2011-12-31

Show the "Changes" file from Test-Fatal with no further processing

	$ p5u changes --verbatim Test-Fatal

=head1 DESCRIPTION

Except when the C<< --verbatim >> flag is used, this command relies on
change logs conforming to the L<CPAN::Changes::Spec>. Changes files that
deviate from the specification may misbehave.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=P5U-Command-Changes>.

=head1 SEE ALSO

L<P5U>,
L<CPAN::Changes::Spec>.

L<http://changes.cpanhq.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

