package Terse::Plugin;

use base 'Terse';

sub new {
	my ($pkg, @args) = @_;
	my $self = $pkg->SUPER::new(@args);
	my ($namespace) = $pkg =~ m/([^:]+)$/;
	$self->namespace = lc( $namespace );
	$self->build_plugin() if ($self->can('build_plugin'));
	return $self;
}

sub connect {
	return $_[0];
}

1;

=head1 NAME

Terse::Plugin - plugins made simple.

=head1 VERSION

Version 0.1234

=cut

=head1 SYNOPSIS

	package My::App::Plugin::ValidateParam;

	use base 'Terse::Plugin';

	sub az {
		my ($self, $param) = @_;
		return 0 if ref $param;
		return $param =~ m/^[a-z]+$/i; 
	}

	1;

	... If using Terse::App 

	package My::App;

	use base 'Terse::App';

	sub build_app {
		$_[0]->response_view = 'pretty'; # default all requests to use this view.
	}

	sub auth {
		shift;
		unless ($_[0]->plugin('validateparam')->az($_[0]->params->name)) {
			$_[0]->raiseError('param name contains more than just A-Z');
			return 0;
		}
		return $_[0]->controller('admin/auth')->authenticate(@_);
	}

	... else 

	package MyApp;

	use base 'Terse::Controller';
	
	use MyAppPlugin;

	sub build_controller {
		$_[0]->plugins->validate = MyAppPlugin->new();
	}

	sub overview :get {
		unless ($_[1]->plugin('validate')->az($_[1]->params->name)) {
			$_[1]->raiseError('param name contains more than just A-Z', 400);
			return 0;
		}
		$_[1]->response->data = $_[1]->model('data')->do_something();
	}


=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

L<Terse>.

=cut

