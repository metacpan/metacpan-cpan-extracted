package Terse::Es;
use 5.006; use strict; use warnings;
our $VERSION = '0.02'; 
1;

__END__

=head1 NAME

Terse::Es - Terse Elasticsearch.

=head1 VERSION

Version 0.02

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

	...

	package MyApp::Model::Shiva;

	use base 'Terse::Model::Es';

	sub index { return 'shiva'; }

	sub columns { 
		$_[0]->{_columns} ||= {
			id => {
				display => 'ID',
				table => {
					response => 8,
					sort => 1
				}
			},
			name => {
				alias => 'name.keyword',
				display => 'Name',
				table => {
					response => 1,
					sort => 1,
				}
			},
			type => { ... },
			body => { ... }
		};
	}

	sub jokes {
		my ($self, $t) = ($_[0]->clone(), $_[1]);
		$self->size = 10;
		$self->type = 'joke';
		return $self->search($t);
	}

	1;

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-terse-es at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Terse-Es>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Terse::Es

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Terse-Es>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Terse-Es>

=item * Search CPAN

L<https://metacpan.org/release/Terse-Es>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Terse::Es
