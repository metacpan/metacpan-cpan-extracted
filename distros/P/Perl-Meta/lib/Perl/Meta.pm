package Perl::Meta;

use 5.005;
#use warnings;
use strict;

=head1 NAME

Perl::Meta - Extract metadata from perl/pod text.

=head1 VERSION

Version 0.04

=cut

use vars '$VERSION';
$VERSION = '0.04';


=head1 SYNOPSIS

    use Perl::Meta;

    my $pv = Perl::Meta::extract_perl_version(' use 5.10.1;');
    ...

=head1 SUBROUTINES/METHODS

=head2 extract_license

Returns license code for META.yml/json from perl/pod text by matching several patterns.

=head2 extract_perl_version

Returns perl version required in perl text.

=head2 extract_bugtracker

Searches for bug tracker pod links in text. rt.cpan.org, github.com,
code.google.com are supported.

=cut

sub extract_license {
	my $pod = shift;
	my $matched;
	return _extract_license(
		($matched) = $pod =~ m/
			(=head \d \s+ L(?i:ICEN[CS]E|ICENSING)\b.*?)
			(=head \d.*|=cut.*|)\z
		/xms
	) || _extract_license(
		($matched) = $pod =~ m/
			(=head \d \s+ (?:C(?i:OPYRIGHTS?)|L(?i:EGAL))\b.*?)
			(=head \d.*|=cut.*|)\z
		/xms
	);
}

sub _extract_license {
	my $license_text = shift or return;
	my @phrases      = (
		'(?:under )?the same (?:terms|license) as (?:perl|the perl (?:\d )?programming language)' => 'perl', 1,
		'(?:under )?the terms of (?:perl|the perl programming language) itself' => 'perl', 1,
		'under the terms of either the GNU General Public License or the Artistic License' => 'perl', 1,
		'Artistic and GPL'                   => 'perl',         1,
		'GNU general public license'         => 'gpl',          1,
		'GNU public license'                 => 'gpl',          1,
		'GNU lesser general public license'  => 'lgpl',         1,
		'GNU lesser public license'          => 'lgpl',         1,
		'GNU library general public license' => 'lgpl',         1,
		'GNU library public license'         => 'lgpl',         1,
		'GNU Free Documentation license'     => 'unrestricted', 1,
		'GNU Affero General Public License'  => 'open_source',  1,
		'(?:Free)?BSD license'               => 'bsd',          1,
		'Artistic license 2\.0'              => 'artistic_2',   1,
		'Artistic license'                   => 'artistic',     1,
		'Apache (?:Software )?license'       => 'apache',       1,
		'GPL'                                => 'gpl',          1,
		'LGPL'                               => 'lgpl',         1,
		'BSD'                                => 'bsd',          1,
		'Artistic'                           => 'artistic',     1,
		'MIT'                                => 'mit',          1,
		'Mozilla Public License'             => 'mozilla',      1,
		'Q Public License'                   => 'open_source',  1,
		'OpenSSL License'                    => 'unrestricted', 1,
		'SSLeay License'                     => 'unrestricted', 1,
		'The beer-?ware license'             => 'unrestricted', 1,
		'zlib License'                       => 'open_source',  1,
		'proprietary'                        => 'proprietary',  0,
	);
	while ( my ($pattern, $license, $osi) = splice(@phrases, 0, 3) ) {
		$pattern =~ s#\s+#\\s+#gs;
		if ( $license_text =~ /\b$pattern\b/i ) {
			return $license;
		}
	}
	return '';
}


sub extract_perl_version {
	if (
		$_[0] =~ m/
		^\s*
		(?:use|require) \s*
		v?
		([\d_\.]+)
		\s* ;
		/ixms
	) {
		my $perl_version = $1;
		$perl_version =~ s{_}{}g;
		return $perl_version;
	} else {
		return;
	}
}


sub extract_bugtracker {
	my @links   = $_[0] =~ m#L<(
	 https?\Q://rt.cpan.org/\E[^>]+|
	 https?\Q://github.com/\E[\w_]+/[\w_]+/issues|
	 https?\Q://code.google.com/p/\E[\w_\-]+/issues/list
	 )>#gx;
	my %links;
	@links{@links}=();
	@links=keys %links;
	return @links;
}

=head1 AUTHOR

Alexandr Ciornii, C<< <alexchorny at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-perl-meta at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Meta>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Perl::Meta


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Perl-Meta>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Perl-Meta>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Perl-Meta>

=item * Search CPAN

L<http://search.cpan.org/dist/Perl-Meta/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 - 2021 Alexandr Ciornii.
Copyright 2002 - 2011 Brian Ingerson, Audrey Tang and Adam Kennedy.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Perl::Meta
