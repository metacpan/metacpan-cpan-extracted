package Terse::Plugin::Es;
use 5.006; use strict; use warnings;
our $VERSION = '0.03'; 
use base 'Terse::Plugin';
use Search::Elasticsearch;

sub connect {
	my ($self, $t) = @_;
	my ($host, $user, $password) = $self->connect_info($t);
	if (!$host) {
		$t->logError('No elasticsearch uri found for connection', 400);
		return;
	}
	my $uri = $user ? sprintf("https://%s:%s@%s", $user, $password, $host) : sprintf("https://%s", $host);
	my $es = Search::Elasticsearch->new(
		nodes => $uri
	);
	return $es;
}

sub connect_info {
	my ($self, $t) = @_;
	my $conf = $t->plugin('config')->find('es');
	return ($conf->{host}, $conf->{user}, $conf->{password});
}

1;

__END__

=head1 NAME

Terse::Plugin::Es - Terse Elasticsearch Plugin 

=head1 VERSION

Version 0.03

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	package MyApp::Plugin::Es;

	use base 'Terse::Plugin::Es';

	sub connect_info {
		...
		return ($host, $user, $password);
	}

	1;

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-terse-plugin-es at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Terse-Plugin-Es>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Terse::Plugin::Es


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Terse-Plugin-Es>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Terse-Plugin-Es>

=item * Search CPAN

L<https://metacpan.org/release/Terse-Plugin-Es>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Terse::Plugin::Es
