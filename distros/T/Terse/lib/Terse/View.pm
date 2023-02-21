package Terse::View;

use base 'Terse';

sub new {
	my ($pkg, @args) = @_;
	my $self = $pkg->SUPER::new(@args);
	my ($namespace) = $pkg =~ m/([^:]+)$/;
	$self->namespace = lc( $namespace );
	$self->build_view() if ($self->can('build_view'));
	return $self;
}

sub render {
	my ($self, $t, $data) = @_;
	return ('application/json', $data->pretty(1)->serialize())
}

1;

=head1 NAME

Terse::View - views made simple.

=head1 VERSION

Version 0.123456789

=cut

=head1 SYNOPSIS

	package My::App::View::Pretty;

	use base 'Terse::View';

	1;

	... If using Terse::App 

	package My::App;

	use base 'Terse::App';

	sub build_app {
		$_[0]->response_view = 'pretty'; # default all requests to use this view.
	}

	sub auth {
		shift;
		$_[0]->controller('admin/auth')->authenticate(@_);
	}

	... else 

	package MyApp;

	use base 'Terse::Controller';
	
	use MyAppView;

	sub build_controller {
		$_[0]->views->pretty = MyAppView->new();
		$_[0]->response_view = 'pretty';
	}

	sub overview :get {
		$_[1]->response->data = $_[1]->model('data')->do_something();
	}


=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

L<Terse>.

=cut

