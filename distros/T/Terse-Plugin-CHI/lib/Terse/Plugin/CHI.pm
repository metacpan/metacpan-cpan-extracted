package Terse::Plugin::CHI;
use 5.006; use strict; use warnings;
our $VERSION = '0.02';
use base 'Terse::Plugin';
use CHI; use JSON;

sub build_plugin {
	my ($self) = @_;
	$self->cache = CHI->new(
		driver => 'Memory',
		global => 1,
		($self->chi ? %{ $self->chi } : ())
	);
}

sub set {
	my ($self, $content, $timeout, $unique) = @_;
	$unique ||= [caller(1)]->[3];
	$self->cache->set( $unique, $content->response->serialize(), (defined $timeout ? $timeout : ()) );
	return $content;
}

sub get {
	my ($self, $t, $unique) = @_;
	$unique ||= [caller(1)]->[3];
	my $c = $self->cache->get($unique);
	$t->graft('response', $c);
	return $t;
}

1;

__END__

=head1 NAME

Terse::Plugin::CHI - Terse response cache

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	package World::Plugin::Cache;

	use base 'Terse::Plugin::CHI';

   	1;

	...
	
	package World::Controller::Owner;

	use base 'Terse::Controller';

	sub my_land {
		my ($self, $t) = @_;
		$t->plugin('cache')->get($t) && return;
		... 
		$t->response = $response;
		$t->plugin('cache')->set($t) && return;
	}

	1;

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-terse-plugin-chi at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Terse-Plugin-CHI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Terse::Plugin::CHI

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Terse-Plugin-CHI>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Terse-Plugin-CHI>

=item * Search CPAN

L<https://metacpan.org/release/Terse-Plugin-CHI>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Terse::Plugin::CHI
