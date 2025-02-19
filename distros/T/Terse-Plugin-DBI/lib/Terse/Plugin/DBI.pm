package Terse::Plugin::DBI;
use 5.006; use strict; use warnings;
our $VERSION = '0.04'; 
use base 'Terse::Plugin';

use DBI;

sub connect {
	my ($self, $t) = @_;
	my ($dsn, $user, $password) = $self->connect_info($t);
	if (!$dsn) {
		$t->logError('No dsn found for DBI conntection', 400);
		return;
	}
	my $dbi = DBI->connect($dsn, $user, $password);
	return $dbi;
}

sub connect_info {
	my ($self, $t) = @_;
	my $conf = $t->plugin('config')->find('coredb');
	return ($conf->{dsn}, $conf->{user}, $conf->{password});
}

1;

__END__

=head1 NAME

Terse::Plugin::DBI - DBI in Terse

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	package MyApp::Plugin::DBI;

	use base 'Terse::Plugin::DBI';

	sub connect_info {
		...
		return ($dsn, $user, $password);
	}


	1;

	...
	
	package MyApp::Model::List;

	use base 'Terse::Model';

	sub get {
		my ($self, $t, $name) = @_;

		my $sh = $t->plugin('dbi')->prepare(q|select * from lists where name = ?|);

		$sh->execute($name) or $t->logError($sh->errstr, 404) && return;
	
		return $sh->fetchrow_array();
	}

	1;

	...

	package MyApp::Controller::List

	use base 'Terse::Controller';

	sub mockery {
		my ($self, $t) = @_;

		$t->model('list')->get('my-list');
	}
	
	1;

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-terse-plugin-dbi at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Terse-Plugin-DBI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Terse::Plugin::DBI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Terse-Plugin-DBI>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Terse-Plugin-DBI>

=item * Search CPAN

L<https://metacpan.org/release/Terse-Plugin-DBI>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Terse::Plugin::DBI
