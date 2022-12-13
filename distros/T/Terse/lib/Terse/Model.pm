package Terse::Model;

use base 'Terse';

sub new {
	my ($pkg, @args) = @_;
	my $self = $pkg->SUPER::new(@args);
	my ($namespace) = $pkg =~ m/([^:]+)$/;
	$self->namespace = lc( $namespace );
	$self->build_model() if ($self->can('build_model'));
	return $self;
}

sub connect {
	my ($self, $t) = @_;
	return $self;
}

1;

=head1 NAME

Terse::Controller - models made simple.

=head1 VERSION

Version 0.120

=cut

=head1 SYNOPSIS

	package My::App::Model::Data;

	use base 'Terse::Model';

	sub do_something {
		...
	}

	1;

	... If using Terse::App 

	package My::App::Controller::Overview;

	use base 'Terse::Controller';

	sub overview :get {
		$_[1]->response->data = $_[1]->model('data')->do_something();
	}

	... else 

	package MyApp;

	use base 'Terse::Controller';
	
	use MyAppModel;

	sub build_controller {
		$_[0]->models->data = MyAppModel->new();
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

