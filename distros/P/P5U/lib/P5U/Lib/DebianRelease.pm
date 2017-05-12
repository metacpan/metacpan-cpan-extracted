package P5U::Lib::DebianRelease;

# This is largely based on a script by SHARYANTO

use 5.010;
use utf8;

BEGIN {
	$P5U::Lib::DebianRelease::AUTHORITY = 'cpan:TOBYINK';
	$P5U::Lib::DebianRelease::VERSION   = '0.100';
};

use Moo;
use IO::Uncompress::Gunzip qw< gunzip $GunzipError >;
use JSON             2.00  qw< from_json >;
use LWP::Simple      0     qw< get >;
use match::smart     0     qw< M >;
use Object::AUTHORITY qw/AUTHORITY/;
use Type::Utils      0     qw< class_type >;
use Types::Standard  0.004 qw< HashRef >;

my $json   = JSON::->new->allow_nonref;

sub dist2deb
{
	my ($dist) = @_;
	"lib".lc($dist)."-perl";
}

use namespace::clean;

has debian => (
	is         => 'lazy',
	isa        => HashRef,
);

has cache_file => (
	is         => 'ro',
	required   => 1,
	isa        => class_type { class => 'Path::Tiny' },
);

sub _build_debian
{
	my $self = shift;
	my %pkgs;
	unless ((-f $self->cache_file) && (-M _) < 7)
	{
		my $res = get "http://packages.debian.org/unstable/allpackages?format=txt.gz"
			or die "get failed\n";
		($res =~ /^All Debian Package/is)
			? $self->cache_file->spew([$res])
			: gunzip(\$res => $self->cache_file->stringify)
			or die "gunzip failed: $GunzipError\n";
	}
	for ($self->cache_file->lines_utf8)
	{
		next unless /^(lib\S+?-perl) \(([^\s\)]+).*\)/;
		$pkgs{$1} = $2;
	}
	\%pkgs
}

sub author_report
{
	my $self = shift;
	$self->format_report(
		$self->author_data(@_)
	)
}

sub distribution_report
{
	my $self = shift;
	$self->format_report(
		$self->distribution_data(@_)
	)
}

sub format_report
{
	my ($self, $data) = @_;
	join q(),
		sprintf(
			"%-40s%15s%15s  %s\n",
			qw(PACKAGE CPAN DEBIAN WARNING)
		),
		map {
			my ($dist, $cpan, $deb) = @$_;
			(my $debx = $deb) =~ s/[-].+//;
			sprintf(
				"%-40s%15s%15s  %s\n",
				$dist,
				$cpan,
				$deb,
				($debx eq $cpan ? q[  ] : q[!!]),
			);
		}
		@$data;
}

sub author_data
{
	my ($self, $author) = @_;

	my $res = get "http://api.metacpan.org/v0/release/_search?q=author:".
		uc($author)."%20AND%20status:latest&fields=name&size=1000";
	$res = $json->decode($res);
	die "MetaCPAN timed out" if $res->{timed_out};

	my $pkgs = $self->debian;

	my %dists;
	for my $hit (@{ $res->{hits}{hits} })
	{
		my $dist = $hit->{fields}{name};
		$dist =~ s/-(\d.+)//;
		$dists{$dist} = $1;
	}

#	use Data::Dumper;
#	$Data::Dumper::Sortkeys = 1;
#	print Dumper $pkgs;

	my @data;
	for my $dist (sort keys %dists)
	{
		my $pkg = dist2deb($dist);
		next unless $pkg |M| $pkgs;
		
		push @data => [
			$dist,
			$dists{$dist},
			$pkgs->{$pkg},
		];
	}
	\@data;
}

sub distribution_data
{
	my $self = shift;
	my $dist = from_json get sprintf('http://api.metacpan.org/v0/release/%s', @_);
	my $pkg  = dist2deb $dist->{distribution};
	
	[[
		$dist->{distribution},
		$dist->{version},
		($self->debian->{$pkg} // '(none)'),
	]]
}

1;

__END__

=pod

=encoding utf-8

=for stopwords AoA libfoo-bar-perl debian-release

=head1 NAME

P5U::Lib::DebianRelease - support library implementing p5u's debian-release command

=head1 SYNOPSIS

 use P5U::Lib::DebianRelease;
 use Path::Tiny qw(path);
 
 my $dr = P5U::Lib::DebianRelease->new(
   cache_file  => path("/tmp/debian.data"),
 );
 
 my $author_data = $dr->author_data('tobyink');
 foreach my $dist (@$author_data)
 {
   print "Dist:   $dist->[0]\n";
   print "CPAN:   $dist->[1]\n";
   print "Debian: $dist->[2]\n\n";
 }

=head1 DESCRIPTION

This is a support library for the debian-release command.

It's a L<Moo>-based class.

=head2 Constructor

=over

=item C<< new(%attributes) >>

Creates a new instance of the class.

=back

=head2 Attributes

=over

=item C<< cache_file >>

A Path::Tiny object representing the location we should download Debian
release data to (and cache it). This is required, so provided it to the
constructor.

=item C<< debian >>

A hashref mapping Debian packages to versions. You presumably don't want
to provide this data in the constructor. Let the module handle building
it for you!

=back

=head2 Methods

=over

=item C<< author_data($cpanid) >>

Get a list of the author's distributions which are included in Debian.
This is an AoA (array of arrays) structure. The "outer" array is the list.
Each "inner" array is three elements long; the first element being the
distribution name; the second, the version number of the latest non-dev 
release on CPAN; and the third, the version number in Debian.

=item C<< distribution_data($dist) >>

Returns a similar AoA to C<author_data>, but selected by distribution name
rather than author. The "outer" array will only ever contain one "inner"
array, so is redundant, but included for consistency.

Unlike C<author_data>, the third element will be the string "(none)" when
the distribution does not appear in Debian.

=item C<< format_report >>

Given an AoA structure as above, formats it into a single string for printing
to a terminal or other output device using a fixed-width font.

=item C<< author_report($cpanid) >>

C<author_data> and C<format_report> in a single method call.

=item C<< distribution_report($dist) >>

C<distribution_data> and C<format_report> in a single method call.

=back

=head2 Function

=over

=item C<< P5U::Lib::DebianRelease::dist2deb($dist) >>

Returns the expected Debian package name for a distribution. For example,
given "Foo-Bar" will return "libfoo-bar-perl".

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=P5U>.

=head1 SEE ALSO

L<p5u>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

This module is largely based on a script by Steven Haryanto, so any credit
belongs to him. Any blame is almost certainly down to the changes I've made.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

