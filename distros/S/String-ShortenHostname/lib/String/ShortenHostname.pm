package String::ShortenHostname;
# ABSTRACT: tries to shorten hostnames while keeping them meaningful

use Moose;

our $VERSION = '0.006'; # VERSION


has 'length' => ( is => 'rw', isa => 'Int', required => 1 );
has 'keep_digits_per_domain' => ( is => 'rw', isa => 'Int', default => 5 );
has 'domain_edge' => ( is => 'rw', isa => 'Maybe[Str]', default => '~' );
has 'cut_middle' => ( is => 'rw', isa => 'Bool', default => 1 );

has 'force' => ( is => 'rw', isa => 'Bool', default => 1 );
has 'force_edge' => ( is => 'rw', isa => 'Maybe[Str]', default => '~>');

sub shorten {
	my ( $self, $hostname ) = @_;
	my $cur_len = length($hostname);
	my ( $host, @domain ) = split('\.', $hostname);

	if( $cur_len <= $self->length ) {
		return($hostname); # already short
	}

	for( my $i = scalar(@domain) - 1 ; $i >= 0 ; $i--) {
		my $cut_len = $self->keep_digits_per_domain;
		my $orig = $domain[$i];
		if( length($domain[$i]) <= $self->keep_digits_per_domain ) {
			next;
		}
		if( defined $self->domain_edge ) {
			$cut_len -= length($self->domain_edge);
		}
		if( $self->cut_middle ) {
			$cut_len--;
		}
		if( $cut_len < 1 ) {
			die('remaining length per domain too small, adjust keep_digits_per_domain, domain_edge, cut_middle');
		}
		$domain[$i] = substr($orig, 0, $cut_len);
		if( defined $self->domain_edge ) {
			$domain[$i] .= $self->domain_edge;
		}
		if( $self->cut_middle ) {
			$domain[$i] .= substr($orig, -1, 1);
		}
		$cur_len = length(join('.', $host, @domain));
		
		if( $cur_len <= $self->length ) {
			return( join('.', $host, @domain) );
		}
	}

	$hostname = join('.', $host, @domain);

	if( $self->force ) {
		$hostname = substr($hostname, 0, $self->length);
		if( defined $self->force_edge ) {
			$hostname = substr($hostname, 0, $self->length - length($self->force_edge));
			$hostname .= $self->force_edge;
		}
	}

	return($hostname);
}

1;


__END__
=pod

=head1 NAME

String::ShortenHostname - tries to shorten hostnames while keeping them meaningful

=head1 VERSION

version 0.006

=head1 SYNOPSIS

  use String::ShortenHostname;

  my $sh = String::ShortenHostname->new( length => 20 );
  $sh->shorten('zumsel.haushaltswarenabteilung.einzelhandel.de');
  # zumsel.hau~g.ein~l~>

  $sh->cut_middle(0);
  $sh->shorten('zumsel.haushaltswarenabteilung.einzelhandel.de');
  # zumsel.haus~.einz~~>

  $sh->force(0);
  $sh->shorten('zumsel.haushaltswarenabteilung.einzelhandel.de');
  # zumsel.haus~.einz~.de

  $sh->domain_edge(undef);
  $sh->shorten('zumsel.haushaltswarenabteilung.einzelhandel.de');
  # zumsel.haush.einze.de

=head1 DESCRIPTION

String::ShortenHostname will try to shorten the hostname string to the length specified.
It will cut each domain part to a given length from right to left till the string is
short enough or the end of the domain has been reached.

Options:

=over

=item length (required)

The desired maximum length of the hostname string.

=item keep_digits_per_domain (default: 5)

Cut each domain part at this length.

=item domain_edge (default: '~')

If defined this string will be used to replace the end of each domain truncated to
indicate that it was truncated.

=item cut_middle (default: 1)

Will do the cut one character before the last.

=item force (default: 1)

If specified the module will force the length by cutting the result string.

=item force_edge (default: '~>')

If defined this string will be used to replace the end of the string to
indicate that it was truncated.

=back

=head1 AUTHOR

Markus Benning <me@w3r3wolf.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Markus Benning.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

