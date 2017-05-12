package P5U::Lib::Whois;

BEGIN {
	$P5U::Lib::Whois::AUTHORITY = 'cpan:TOBYINK';
	$P5U::Lib::Whois::VERSION   = '0.100';
};

use Moo; no warnings;
use Types::Standard qw< ArrayRef HashRef Maybe Num Str >;
use JSON qw(from_json);
use LWP::Simple qw(get);
use Object::AUTHORITY;

use constant {
	template_website           => 'https://metacpan.org/author/%s',
	template_email             => '%s@cpan.org',
	template_metacpan_data     => 'http://api.metacpan.org/v0/author/%s',
	template_metacpan_releases => 'http://api.metacpan.org/v0/release/_search?q=author:%s+AND+status:latest&fields=name,date,abstract,status&size=5000',
	template_metacpan_popular  => 'http://api.metacpan.org/v0/favorite/_search?q=author:%s&fields=distribution&size=5000',
};

has cpanid => (
	is         => 'ro',
	isa        => Str,
);

has metacpan_data => (
	is         => 'lazy',
	isa        => HashRef,
);

sub _build_metacpan_data
{
	from_json get sprintf __PACKAGE__->template_metacpan_data, uc shift->cpanid
}

has [qw(metacpan_releases metacpan_popular)] => (
	is         => 'lazy',
	isa        => ArrayRef,
);

sub _build_metacpan_releases
{
	[
		map $_->{fields}, @{
			(from_json get sprintf __PACKAGE__->template_metacpan_releases, uc shift->cpanid)
				->{hits}{hits}
		}
	]
}

sub _build_metacpan_popular
{
	my @plusplus = map $_->{fields}{distribution}, @{
		(from_json get sprintf __PACKAGE__->template_metacpan_popular, uc shift->cpanid)
			->{hits}{hits}
	};
	my %dist; $dist{$_}++ for @plusplus;
	[ sort { $b->[1] <=> $a->[1] or $a->[0] cmp $b->[0] } map [ $_ => $dist{$_} ], keys %dist ];
}


has $_ => (
	is         => 'lazy',
	isa        => Maybe[Str],
) for qw(name city region country);

sub _build_name     { $_[0]->metacpan_data->{name} }
sub _build_city     { $_[0]->metacpan_data->{city} }
sub _build_region   { $_[0]->metacpan_data->{region} }
sub _build_country  { $_[0]->metacpan_data->{country} }

has $_ => (
	is         => 'lazy',
	isa        => Maybe[Num],
) for qw(latitude longitude);

sub _build_longitude { $_[0]->metacpan_data->{location}[0] }
sub _build_latitude  { $_[0]->metacpan_data->{location}[1] }

has $_ => (
	is         => 'lazy',
	isa        => ArrayRef,
) for qw(website email);

sub _build_website
{
	my @r = @{ $_[0]->metacpan_data->{website} || [] };
	@r = sprintf __PACKAGE__->template_website, uc shift->cpanid unless @r;
	\@r
}

sub _build_email
{
	my @r = @{ $_[0]->metacpan_data->{email} || [] };
	@r = sprintf __PACKAGE__->template_email, lc shift->cpanid unless @r;
	\@r
}

sub location
{
	my $self = shift;
	
	my $addr = join q[, ], grep defined, map { $self->$_ } qw(city region country);
	
	if (defined $self->longitude and defined $self->latitude)
	{
		$addr .= sprintf(
			" (%s, %s)",
			$self->latitude,
			$self->longitude,
		)
	}
	
	return $addr;
}

sub releases
{
	my $self = shift;
	my @r =
		sort
		map  { $_->{name} }
		@{ $self->metacpan_releases || [] };
	wantarray ? @r : \@r
}

sub namespaces
{
	my $self = shift;
	my %counts;
	for ($self->releases)
	{
		next unless /^(.+?)-/;
		$counts{$1}++;
	}
	my @r =
		sort { $counts{$b} <=> $counts{$a} or $a cmp $b }
		keys %counts;
	wantarray ? @r : \@r
}

sub report
{
	my ($self, $detailed) = @_;
	my $report = sprintf("%s (%s)\n", $self->name, uc $self->cpanid);
	
	my $location = $self->location;
	$report .= "$location\n" if $location =~ /\w/;
	
	my $web = join q( ), map { "<$_>" } @{ $self->website };
	$report .= "$web\n" if $web =~ /\w/;
	
	my $email = join q( ), map { "<mailto:$_>" } @{ $self->email };
	$report .= "$email\n" if $email =~ /\w/;
	
	if ($detailed)
	{
		my @namespaces = $self->namespaces;
		$report .= sprintf "\nNamespaces: %s\n" => join q(, ), @namespaces[0..9]
			if @namespaces;
		
		my @recent =
			map {
				sprintf
					'%s: %s - %s',
					substr($_->{date}, 0, 10),
					$_->{name},
					$_->{abstract},
			}
			sort { $b->{date} cmp $a->{date} }
			@{ $self->metacpan_releases || [] };
		$report .= join "\n", q(), q(Recent:), @recent[0..9], q()
			if @recent;

		my @popular = map sprintf('%s - %d votes', @$_), @{ $self->metacpan_popular || [] };
		$report .= join "\n", q(), q(Popular:), @popular[0..9], q()
			if @recent;

		if (@{ $self->metacpan_data->{profile} || [] })
		{
			$report .= "\n";
			for (sort { $a->{name} cmp $b->{name} } @{ $self->metacpan_data->{profile} })
			{
				$report .= sprintf(qq{%-16s%s\n}, @{$_}{qw{name id}})
			}
		}
	}
	
	return $report;
}

1;



__END__

=pod

=encoding utf-8

=for stopwords MetaCPAN whois co-ordinates websites

=head1 NAME

P5U::Lib::Whois - support library implementing p5u's whois command

=head1 SYNOPSIS

 use P5U::Lib::Whois;
 print P5U::Lib::Whois
    -> new(cpanid => 'TOBYINK')
    -> report;

=head1 DESCRIPTION

This is a support library for the testers command.

It's a L<Moo>-based class.

=head2 Constructor

=over

=item C<< new(%attributes) >>

Creates a new instance of the class.

Generally speaking the only attribute you want to set here is C<cpanid>.

=back

=head2 Attributes

=over

=item C<cpanid>

CPAN ID; read-only; string.

=item C<name>

Person's name; read-only; string or undef.

=item C<city>

City where person lives; read-only; string or undef.

=item C<region>

Region where person lives; read-only; string or undef.

=item C<country>

Country where person lives as an ISO 3166 code; read-only; string or undef.

=item C<longitude>

Longitude for where the person lives; read-only; number or undef.

=item C<latitude>

Latitude for where the person lives; read-only; number or undef.

=item C<website>

Person's websites; read-only, array ref of strings.

=item C<email>

Person's e-mail addresses; read-only, array ref of strings.

=item C<metacpan_data>

Data from MetaCPAN; read-only, hash ref.

=item C<metacpan_releases>

Release data from MetaCPAN; read-only, array ref.

=back

=head2 Methods

=over

=item C<location>

Returns a string combining location data (city, region, country, co-ordinates).

=item C<releases>

Arrayref of strings of all latest releases. Strings are e.g. "Foo-Bar-0.001".

=item C<namespaces>

Top-level namespaces this person has released distributions in, sorted in order
of most releases first.

=item C<< report($detailed) >>

Returns a whois report on the person as a long string. The parameter is a
boolean indicating whether the report should include additional details.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=P5U>.

=head1 SEE ALSO

L<p5u>.

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

