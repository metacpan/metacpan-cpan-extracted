package Terse::Plugin::Glitch;
use 5.006; use strict; use warnings;
our $VERSION = '0.04';
use Glitch;
use YAML::XS;
use JSON;
use base 'Terse::Plugin';

sub build_plugin {
	my ($self) = @_;
	$self->build_glitch_config if $self->can('build_glitch_config');
    	if (!$self->glitch_config) {
                my $file = $0;
                ($self->glitch_config = $0) =~ s/(\.psgi)?$/.glitch/;
        }
	if ($self->{format} eq 'YAML') {
		$self->{glitch_config_parser} = sub { YAML::XS::Load($_[0]) };
	} elsif ($self->{format} eq 'JSON') {
		$self->{glitch_config_parser} = sub { JSON->new->encode($_[0]) };
	}
	Glitch::build_meta(
		map {($_, $self->{$_})} grep {$_ !~ m/^(namespace|format|app)$/} keys %{$self}
	);
}

sub call {
	my ($self, $name) = @_;
	eval { glitch($name) };
	return $@;
}

sub logError {
	my ($self, $t, $name, $status) = @_;
	my $glitch = $self->call($name);
	$self->extend($glitch) if $self->can('extend');
	$t->logError($glitch->hash, $status);
}

sub logInfo {
	my ($self, $t, $name, $status) = @_;
	my $glitch = $self->call($name);
	$self->extend($glitch) if $self->can('extend');
	$t->logInfo($glitch->hash);
}

1;

__END__

=head1 NAME

Terse::Plugin::Glitch - The great new Terse::Plugin::Glitch!

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	package MyApp;

	use base 'Terse';
	use Terse::Plugin::Glitch;

	sub build_terse {
		$_[0]->glitch = Terse::Plugin::Glitch->new(
			glitch_config => 't/lib/glitch.conf',
			format => 'YAML'
		);
	}

	sub auth {
		...
		$_[1]->response->raiseError($_[0]->glitch->call('unauthenticated')->hash);
	}

	...

	package MyApp::Plugin::Glitch;

	use base 'Terse::Plugin::Glitch';

	sub build_glitch_config {
		my ($self) = shift;
		$self->glitch_config = 'path/to/config.yml';
		$self->format = 'YAML';
	}

	package MyApp;

	use base 'Terse::App';

	sub auth {
		...
		$_[1]->plugin('glitch')->logError($_[1], 'unauthenticated');
	}

	1;

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-terse-plugin-glitch at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Terse-Plugin-Glitch>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Terse::Plugin::Glitch


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Terse-Plugin-Glitch>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Terse-Plugin-Glitch>

=item * Search CPAN

L<https://metacpan.org/release/Terse-Plugin-Glitch>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Terse::Plugin::Glitch
