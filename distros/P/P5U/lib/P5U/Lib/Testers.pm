package P5U::Lib::Testers;

use 5.010;
use utf8;

BEGIN {
	$P5U::Lib::Testers::AUTHORITY = 'cpan:TOBYINK';
	$P5U::Lib::Testers::VERSION   = '0.100';
};

use Moo;
use File::Spec       0 qw< >;
use JSON             0 qw< from_json >;
use LWP::Simple      0 qw< mirror is_success >;
use List::Util       0 qw< maxstr >;
use match::simple    0 qw< M >;
use Object::AUTHORITY  qw< AUTHORITY >;
use Path::Tiny       0 qw< path >;
use Type::Utils      0 qw< class_type >;
use Types::Standard  0 qw< ArrayRef HashRef Bool Str >;
use namespace::clean;

has distro => (
	is         => 'ro',
	isa        => Str,
	required   => 1,
);

has version => (
	is         => 'lazy',
	isa        => Str,
);

has os_data => (
	is         => 'ro',
	isa        => Bool,
	default    => sub { 0 },
);

has stable => (
	is         => 'ro',
	isa        => Bool,
	default    => sub { 0 },
);

has cache_dir => (
	is         => 'lazy',
	isa        => class_type { class => 'Path::Tiny' },
);

has results => (
	is         => 'lazy',
	isa        => ArrayRef[HashRef],
);

sub version_data
{
	my ($self) = @_;
	my %data;
	foreach (@{$self->results})
	{
		next unless $_->{version} eq $self->version;
		my ($pv) = ($_->{perl} =~ /^5\.(\d+)/) or next;
		next if $pv |M| [9, 11, 13, 15, 17];
		my $key = $self->os_data
			? sprintf("Perl 5.%03d, %s", $pv, $_->{ostext})
			: sprintf("Perl 5.%03d", $pv);
		my $num  = { PASS => 0, FAIL => 1 }->{$_->{status}} // 2;
		$data{$key}[$num]++;
	}
	return \%data;
}

sub summary_data
{
	my ($self) = @_;
	my %data;
	foreach (@{$self->results})
	{
		my $key  = $_->{version};
		my $num  = { PASS => 0, FAIL => 1 }->{$_->{status}} // 2;
		$data{$key}[$num]++;
	}
	return \%data;
}

sub format_report
{
	my ($self, $title, $data) = @_;
	no warnings;
	join "\n" => (
		$title,
		q(),
		sprintf("%-32s%6s%6s%6s", q(), qw(PASS FAIL ETC)),
		(
			map { sprintf "%-32s% 6d% 6d% 6d", $_, @{$data->{$_}} }
			sort keys %$data
		),
		q(),
	);
}

sub version_report
{
	my ($self) = @_;
	
	$self->format_report(
		sprintf("CPAN Testers results for %s version %s", $self->distro, $self->version),
		$self->version_data,
	);
}

sub summary_report
{
	my ($self, $os_data) = @_;
	
	$self->format_report(
		sprintf("CPAN Testers results for %s", $self->distro),
		$self->summary_data,
	);
}

sub _build_version
{
	maxstr
		map { $_->{version} }
		@{ shift->results }
}

sub _build_results
{
	my $self = shift;
	
	my $results_uri = sprintf(
		'http://www.cpantesters.org/distro/%s/%s.json',
		substr($self->distro, 0, 1),
		$self->distro,
	);
	my $results_file = path(
		$self->cache_dir,
		sprintf('%s.json', $self->distro),
	);
	
	is_success mirror($results_uri => $results_file)
		or do {
			unlink $results_file;
			die "Failed to retrieve URI $results_uri\n";
		};
		
	my $results = from_json scalar $results_file->slurp;
	die "Unexpected non-ARRAY content from $results_uri\n"
		unless ref $results eq 'ARRAY';
	
	$self->stable
		? [ grep { $_->{version} !~ /_/ } @$results ]
		: $results;
}

sub _build_cache_dir
{
	"Path::Tiny"->tempdir;
}

1;

__END__

=pod

=encoding utf-8

=for stopwords HoA

=head1 NAME

P5U::Lib::Testers - support library implementing p5u's testers command

=head1 SYNOPSIS

 use P5U::Lib::DebianRelease;
 use Path::Tiny qw(path);
 
 my $dr = P5U::Lib::DebianRelease->new(
   cache_file => path("/tmp/debian.data"),
 );
 
 my $author_data = $dr->author_data('tobyink');
 foreach my $dist (@$author_data)
 {
   print "Dist:   $dist->[0]\n";
   print "CPAN:   $dist->[1]\n";
   print "Debian: $dist->[2]\n\n";
 }

=head1 DESCRIPTION

This is a support library for the testers command.

It's a L<Moo>-based class.

=head2 Constructor

=over

=item C<< new(%attributes) >>

Creates a new instance of the class.

=back

=head2 Attributes

=over

=item C<distro>

Distribution name; read-only; string; required.

=item C<version>

Version number; read-only; string.

If omitted, the latest version for which CPAN Testers results are available
is assumed.

=item C<os_data>

Indicates that reports should be split by operating system. Read-only;
boolean; default false.

=item C<stable>

Indicates that reports should ignore development releases. Read-only;
boolean; default false.

=item C<cache_dir>

A directory for caching JSON files into. Read-only; string. If omitted,
something sensible will be used.

=item C<results>

The CPAN testers results, as an array of hashes. You generally do not
want to set this yourself, but rely on this module to build it for you!

=back

=head2 Methods

=over

=item C<version_data>

Returns a hashref. Keys are Perl versions such as "Perl 5.008", or if
C<os_data> is true "Perl 5.008, Linux". Values are arrayrefs of three
numbers indicating counts of passes, fails and other results respectively.

=item C<summary_data>

Returns a similar hash of arrays (HoA) structure to C<version_data>,
except keys are versions of the distribution, not versions of Perl.

=item C<format_report>

Given an HoA structure as above, formats it into a single string for printing
to a terminal or other output device using a fixed-width font.

=item C<< version_report >>

C<version_data> and C<format_report> in a single method call.

=item C<< summary_report >>

C<summary_data> and C<format_report> in a single method call.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=P5U>.

=head1 SEE ALSO

L<p5u>.

L<http://www.perlmonks.org/?node_id=978606>.

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

