package Terse::View::TT;

use 5.006;
use strict;
use warnings;
our $VERSION = 0.02;

use base qw/Terse::View/;

use Template;

sub build_view {
	my ($self, $config) = @_;
	$config = $self->app_config = {
		EVAL_PERL          => 0,
		INCLUDE_PATH	   => 'root/src',
		TEMPLATE_EXTENSION => 'tt',
		CLASS              => 'Template',
		%{ $config }
	};
	$self->{template} = $config->{CLASS}->new($config);
	return $self;
}

sub render {
	my ($self, $t, $data) = @_;
	my $template = $data->{template};
	if (!$template) {
		$template = $t->response_namespace;
		my $handler = $t->response_handler;
		if ($template !~ m/$handler$/) {
			$template .= '/' . $handler;
		}
		$template .= '.' . $self->app_config->TEMPLATE_EXTENSION;
	}
	unless ($template) {
		return $self->can('handle_error') ? $self->handle_error('Error - Cannot find template') : ('text/html', '<p>Error - Cannot find template</p>');
	}
	$self->template->{SERVICE}->{WRAPPER} = ($data->{NO_WRAPPER} || (!$data->WRAPPER && ! $self->app_config->WRAPPER))
		? []
		: [($data->WRAPPER || $self->app_config->WRAPPER) . '.' . $self->app_config->TEMPLATE_EXTENSION];
	my $output = eval { $self->render_template($template, $data) };
	if ($@) {
		return $self->can('handle_error') ? $self->handle_error($@) : ('text/html', $@);
	}
	return ('text/html', $output);
}

sub render_template {
	my ($self, $template, $data) = @_;
	my $output;
	unless ($self->template->process( $template, {%{$data}}, \$output )) {
		die $self->template->error;
	}
	return $output;
}

1;

__END__

=head1 NAME

Terse::View::TT - Terse Template Toolkit View

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

lib/Karaoke/View/TT.pm

	package Karaoke::View::TT;

	use base qw/Terse::View::TT/;

	1;

lib/Karaoke/Controller/Songs.pm

	package Karaoke::Controller::Songs;

	use base qw/Terse::Controller/;

	sub songs : any : view(tt) {
		my ($self, $t) = @_;
		$t->response->popular_songs = $t->model('Songs')->popular_songs(5);
		...
	}

	sub add : get : path(songs/add) : view(tt) { ... }

	sub add : post : path(songs/add) { ... }

	...

	1;

root/src/wrapper.tt

	<html>
		<head>
			...
		</head>
		<body>
			...
			[% content %]
			...
		</body>
	</html>

root/src/songs.tt
	
	<div>
		...
		<h1>Top 5 Songs</h1>
		[% FOREACH song in popular_songs %]
		<div>
			...
		</div>
		[% END %]
		...
	</div>

Karaoke.psgi

	use lib 'lib';
	use Terse;
	use Karaoke;
	our $app = Karaoke->start(
		lib => 'lib',
		views => {
			TT => {
				WRAPPER => 'wrapper'
			}
		}
	);

	sub {
     		my ($env) = (shift);
        	Terse->run(
               		plack_env => $env,
                	application => $app,
        	);
	};

...

	plackup -s Starman Karaoke.psgi

...

	GET http://localhost:5000/songs

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-terse-view-tt at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Terse-View-TT>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Terse::View::TT

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Terse-View-TT>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Terse-View-TT>

=item * Search CPAN

L<https://metacpan.org/release/Terse-View-TT>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Terse::View::TT
