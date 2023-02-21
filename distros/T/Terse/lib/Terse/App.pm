package Terse::App;
use strict;
use warnings;
use attributes ();
use base 'Terse::Controller';
use B 'svref_2object';
use Cwd qw(abs_path cwd);
use Module::Runtime qw/require_module/;

sub start {
	my ($pkg, %args) = @_;
	my $path = $pkg->_path($pkg, $args{lib});
	my $self = $pkg->new(
		app => 1,
		models => $pkg->_build_models($pkg, $path, $args{lib}),
		views => $pkg->_build_views($pkg, $path, $args{lib}),
		controllers => $pkg->_build_controllers($pkg, $path, $args{lib}),
		plugins => $pkg->_build_plugins($pkg, $path, $args{lib}),
		%args
	);
	$self->build_app() if ($self->can('build_app'));
	return $self;
}

sub preprocess_req {
        my ($self, $req, $t) = @_;
	if (!$req) {
		(my $path = $t->request->uri->path) =~ s/\/$//;
		if ($self->controllers->{_alias}) {
			for my $candidate (keys %{$self->controllers->{_alias}}) {
                        	my @captured = $path =~ m/$candidate/;
                        	if (scalar @captured) {
                                	$t->captured = \@captured;
                                	$t->params->req = $req = $self->controllers->{_alias}->{$candidate}->{req};
                        	}
                	}
		}
		$req = $self->SUPER::preprocess_req($req, $t) if ! $req;
        	($req) = $path =~ m/([^\/]+)$/ if ! $req;
	}
        return $req;
}

sub _build_models {
	my ($self, $pkg, $path, $lib) =@_; 
	return $self->_load_modules(
		path => $path,
		pkg => $pkg,
		type => 'Model',
		lib => $lib
	);
}

sub _build_views {
	my ($self, $pkg, $path, $lib) =@_; 
	return $self->_load_modules(
		path => $path,
		pkg => $pkg,
		type => 'View',
		lib => $lib
	);
}

sub _build_controllers {
	my ($self, $pkg, $path, $lib) =@_; 
	return $self->_load_modules(
		path => $path,
		pkg => $pkg,
		type => 'Controller',
		lib => $lib
	);
}

sub _build_plugins {
	my ($self, $pkg, $path, $lib) =@_; 
	return $self->_load_modules(
		path => $path,
		pkg => $pkg,
		type => 'Plugin',
		lib => $lib
	);
}

sub _load_modules {
	my ($self, %args) = @_;
	my $type = $args{type};
	my @modules = map {
		(my $l = $_) =~ s/^(\/)|(\.pm)$//ig;
		(my $m = $l) =~ s/\//::/g;
		[
			"$args{path}/${type}/${l}.pm",
			"$args{pkg}::${type}::${m}"
		]
	} $self->_recurse_directory("$args{path}/$type");
	my %mods = ();
	for my $module (@modules) {
		require_module($module->[1]);
	}
	for my $module (@modules) {
		$module = $module->[1]->new(app => 1);
		die $@ && next if $@;
		$mods{_alias} = { %{$mods{_alias} || {}}, %{$Terse::Controller::dispatcher{ref $module}{_alias} || {}} }; 
		$mods{_alias}{$module->capture} = { namespace => $module->namespace } if $module->{capture};
		my $in;
		$in = sub {
			my @ISA = eval "\@$_[0]::ISA";
			for (@ISA) {
				$in->($_);
				my $dispatch = $Terse::Controller::dispatcher{$_};
				$mods{_alias} = {%{$dispatch->{_alias} || {}}, %{$mods{_alias} || {}}}; 
			}
		};
		$in->(ref $module);




		$mods{$module->namespace} = $module;
	}
	return \%mods;
}

sub _path {
	my $pkg_file = join('/', split("\:\:", ($_[1])));
	my $path = $0;
	$path =~ s/[^\/]+$//g;
 	$path .= $_[2] . '/' if (defined $_[2]);
	$path .= $pkg_file;
	return $path;
}

sub _recurse_directory {
	my ($self, $dir, $path, @files) = @_;
	return () unless -d $dir;
	opendir my $d, $dir or die "Cannot read controller directory: $!";
	for (readdir $d) {
		next if $_ =~ m/^\./;
	 	if (-d "$dir/$_") {
			push @files, $self->_recurse_directory("$dir/$_", ($path || "") . "/$_");
		} elsif ($_ =~ m/\.pm/) {
			push @files, $path ? "$path/$_" : $_;
		}
	}
	closedir $d;
	return @files;
}

sub dispatch {
	my ($self, $req, $t, @params) = @_;
	my $root_path = $t->_root_path || "";
	(my $path = $t->request->uri->path) =~ s/^$root_path\///g;
	if (!$path && !$req) {
		$req = lc(ref $self);
	}
	my $controller = $t->controller($path);
	if ($path && ! $controller) {
		$t->logError('Path not found - ' . $path, 500);
		return;
	}
	if ($req eq $t->{_auth} || $t->is_login || $t->is_logout) {
		my @response = ($self->SUPER::dispatch($req, $t, @params));
		@response = ($controller->dispatch($req, $t, @response))
			if $path && $controller->can($req);
		return @response;
	} elsif ($path) {
		if ($controller->required_captured && scalar @{$t->captured ||= []} != $controller->required_captured) {
			$t->logError('Missing captured arguments', 500);
			return;
		}
		if ($controller->default_req && !$t->params->req) {
			$req = $controller->default_req;
		}
		return $controller->dispatch($req, $t, @params);
	}
	return $self->SUPER::dispatch($req, $t, @params);
}

1;

__END__;


=head1 NAME

Terse::App - Lightweight MVC applications.

=head1 VERSION

Version 0.123456789

=cut

=head1 SYNOPSIS

	.. My/App.pm

	package My::App;

	use base 'Terse::App';

	sub login :any {
		return 1;
	}

	sub auth_prevent :any(auth) {
		return 0;
	}

	sub auth :get :post {
		return 1;
	}

	... My/App/Controller/Hello.pm

	package My::App::Controller::Hello;

	use base 'Terse::Controller';

	sub hello :get {
		... #1
	}
	
	sub world :get {
		... #2
	}

	... My/App/Controller/Hello/World.pm

	package My::App::Controller::Hello::World;

	use base 'Terse::Controller';

	sub build_controller {
		$_[0]->required_captured = 2;
		$_[0]->capture = 'hello/(.*)/world/(.*)';
		$_[0];
	}

	sub world :get {
		$_[1]->respone->captured = $_[1]->captured;
		... #3
	}

	.... MyApp.psgi ...

	use Terse;
	use My::App;
	our $app = My::App->start();

	sub {
		my ($env) = (shift);
		Terse->run(
			plack_env => $env,
			application => $app,
		);
	};

	....

	plackup MyApp.psgi

	GET http://localhost:5000/hello?id=here&other=params #1
	GET http://localhost:5000/hello?req=world #2
	GET http://localhost:5000/hello/abc/world/123 #3

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

L<Terse>.

=cut
