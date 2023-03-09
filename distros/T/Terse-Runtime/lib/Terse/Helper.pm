package Terse::Helper;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.02';
use Cwd qw/cwd/;
use Module::Generate;
use base 'Terse';
use MIME::Base64 qw/decode_base64/;
our ($FAVICON, $HTML, $CSS, $JS);

sub new {
	my ($self, %args) = @_;
	return $self->SUPER::new(%args);
}

sub run {
	my ($self, %args) = @_;
	if ( not keys %args || $args{'--help'} ) {
		print q|Help:
terse --name Test::App # Generates an application skeleton
terse --name Test::App --model Sun # Generate an application model
terse --name Test::App --view Moon # Generate an application view
terse --name Test::App --controller Stars # Generate an application controller
terse --name Test::App --plugin Satellites # Generate an application plugin
|;
		return;
	}
	$args{base} ||= cwd;
	if (! $args{'--name'}) {
		die 'No application "--name" passed to Terse::Helper';
	}
	($args{camel} = $args{'--name'}) =~ s/:://g;
	($args{application_base} = 'lib/' . $args{'--name'}) =~ s/::/\//g;
	if ($args{'--controller'}) {
		return $self->create_controller(%args);
	} elsif ($args{'--plugin'}) {
		return $self->create_plugin(%args);
	} elsif ($args{'--model'}) {
		return $self->create_model(%args);
	} elsif ($args{'--view'}) {
		return $self->create_view(%args);
	} else {
		$self->create_base_application(%args);
	}
}

sub create_controller {
	my ($self, %args) = @_;
	chdir 'lib';
	my $controller = "$args{'--name'}::Controller::$args{'--controller'}"; 
	my @parts = split "\:\:", $args{'--controller'}; 
	my $sub = lc($parts[-1]);
	my $endpoint = lc(join "/", @parts);
	my $applicaiton = Module::Generate->start
		->class($controller)
			->no_warnings('reserved')
			->synopsis("plackup $args{camel}.psgi")
			->abstract("$args{'--controller'} application class")
			->base($args{'--base'} || 'Terse::Controller')
			->sub($sub)
				->code(q|sub :any { 
					my ($self, $t) = @_;
				}|)
               	        	->pod("Base ANY endpoint for the $controller")
                        	->example("localhost/$endpoint")
			->generate();
}

sub create_plugin {
	my ($self, %args) = @_;
	chdir 'lib';
	my $plugin = "$args{'--name'}::Plugin::$args{'--plugin'}"; 
	my @parts = split "\:\:", $args{'--plugin'}; 
	my $sub = lc($parts[-1]);
	my $endpoint = lc(join "/", @parts);
	my $applicaiton = Module::Generate->start
		->class($plugin)
			->no_warnings('reserved')
			->synopsis("\$t->plugin('$sub')->\$method(...)")
			->abstract("$args{'--plugin'} application plugin")
			->base($args{'--base'} || 'Terse::Plugin')
			->generate();
}

sub create_model {
	my ($self, %args) = @_;
	chdir 'lib';
	my $model = "$args{'--name'}::Model::$args{'--model'}"; 
	my @parts = split "\:\:", $args{'--model'}; 
	my $sub = lc($parts[-1]);
	my $endpoint = lc(join "/", @parts);
	my $applicaiton = Module::Generate->start
		->class($model)
			->no_warnings('reserved')
			->synopsis("\$t->model('$sub')->\$method(...)")
			->abstract("$args{'--model'} application model")
			->base($args{'--base'} || 'Terse::Plugin')
			->generate();
}

sub create_view {
	my ($self, %args) = @_;
	chdir 'lib';
	my $view = "$args{'--name'}::View::$args{'--view'}"; 
	my @parts = split "\:\:", $args{'--view'}; 
	my $sub = lc($parts[-1]);
	my $endpoint = lc(join "/", @parts);
	my $applicaiton = Module::Generate->start
		->class($view)
			->no_warnings('reserved')
			->synopsis("\$t->view('$sub')->\$method(...)")
			->abstract("$args{'--view'} application view")
			->base($args{'--base'} || 'Terse::View')
			->generate();
}

sub create_base_application {
	my ($self, %args) = @_;
	return 0 if -d $args{application_base};
	$args{controller_base} = $args{application_base} . '/Controller/';
	$args{plugin_base} = $args{application_base} . '/Plugin/';
	$args{view_base} = $args{application_base} . '/View/';
	Module::Generate::_make_path($args{$_}) for qw/application_base controller_base plugin_base view_base/;
	$self->create_psgi(%args);
	$self->create_conf(%args);
	$self->create_root(%args);
	$self->create_demo_files();
	chdir 'lib';
	my $applicaiton = Module::Generate->start
		->class($args{'--name'})
			->no_warnings('reserved')
			->synopsis("plackup $args{camel}.psgi")
			->abstract('Base application class')
			->base('Terse::App')
			->sub('auth')
				->code(q|sub :any { 
					my ($self, $t) = @_;
					if ($t->req) { # second run through of the auth sub routine
						$t->plugin('headers')->set($t);
					}
					return 1;
				}|)
               	        	->pod('Base auth endpoint.')
                        	->example('localhost/auth')
			->sub('login')
				->code('sub :any :path(/login) { return 1; }')
				->pod('Base login endpoint.')
				->example('localhost/login')
			->sub('logout')
				->code('sub :any :path(/logout) { return 1; }')
				->pod('Base logout endpoint.')
				->example('localhost/logout')
			->sub('index')
				->code('sub :get(index) :path(/) :view(static) :content_type(text/html) {}')
				->pod('Base GET index endpoint that renders HTML.')
				->example('localhost/')
			->generate();
	$self->create_config(%args);
	$self->create_ua(%args);
	$self->create_headers(%args);
	$self->create_static(%args);
	$self->create_home_controller(%args);
}

sub create_file {
	my ($self, $file, $content) = @_;
	open(my $fh, '>', $file) or die "Cannot open file $file to write $!";
	print $fh $content;
	close $fh;
}

sub create_psgi {
	my ($self, %args) = @_;
	my $content = qq|#!user/bin/perl
use lib 'lib';
use Terse;
use $args{'--name'};
our \$app = $args{'--name'}->start(lib => 'lib');
no warnings 'reserved'; 
sub {
        my (\$env) = (shift);
        Terse->run(
                plack_env => \$env,
                application => \$app,
        );
};|;
	$self->create_file($args{camel} . ".psgi", $content);
	return 1;
}

sub create_conf {
	my ($self, %args) = @_;
	$self->create_file($args{camel} . ".yml", qq|title: Welcome to Terse
content: You have created a new application named $args{'--name'}|
);
}

sub create_root {
	my ($self, %args) = @_;
	Module::Generate::_make_path('root/static');
	Module::Generate::_make_path('root/static/js');
	Module::Generate::_make_path('root/static/html');
	Module::Generate::_make_path('root/static/css');
}

sub create_config {
	my ($self, %args) = @_;
	my $class = $args{'--name'} . '::Plugin::Config';
	my $headers = Module::Generate->start
		->class($class)
			->abstract('YAML config plugin.')
			->synopsis(q|YAML config plugin.
	$self->plugin('config')->post(%post);|)
			->base('Terse::Plugin::Config::YAML')
		->generate();
	return 1;
}

sub create_ua {
	my ($self, %args) = @_;
	my $class = $args{'--name'} . '::Plugin::UA';
	my $headers = Module::Generate->start
		->class($class)
			->abstract('LWP::UserAgent plugin.')
			->synopsis(q|LWP::UserAgent plugin.
	$self->plugin('ua')->post(%post);|)
			->base('Terse::Plugin::UA')
		->generate();
	return 1;
}

sub create_headers {
	my ($self, %args) = @_;
	my $class = $args{'--name'} . '::Plugin::Headers';
	my $headers = Module::Generate->start
		->class($class)
			->abstract('Set default response headers')
			->synopsis(q|Set default response headers
	$self->plugin('headers')->set($context, %headers);|)
			->base('Terse::Plugin::Headers')
		->generate();
	return 1;
}

sub create_static {
	my ($self, %args) = @_;
	my $class = $args{'--name'} . '::View::Static';
	my $view = Module::Generate->start
		->class($class)
			->abstract('Serve static files')
			->synopsis(q|Serve static files
	$self->view('static')->render($t, %view);|)
			->base('Terse::View::Static')
		->generate();
	$class = $args{'--name'} . '::Controller::Static';
	# TODO synopsis
	my $controller = Module::Generate->start
		->class($class)
			->abstract('Serve static files')
			->synopsis(qq|Serve static files
	plackup $args{camel}.psgi|)
			->base('Terse::Controller::Static')
		->generate();
	return 1;
}

sub create_home_controller {
	my ($self, %args) = @_; 
	my $applicaiton = Module::Generate->start
		->class("$args{'--name'}::Controller::Home")
			->no_warnings('reserved')
			->synopsis("plackup $args{camel}.psgi")
			->abstract('Base application class')
			->base('Terse::Controller')
			->sub('home')
				->code(q|sub :post { 
					my ($self, $t) = @_;
					$t->response->title = $t->plugin('config')->find('title');
					$t->response->content = $t->plugin('config')->find('content'); 		
				}|)
               	        	->pod('Base POST endpoint that retrieves the data for the Index page.')
                        	->example('localhost/home')
			->generate();
}

sub create_demo_files {
	my ($self, $t) = @_;
	$self->create_file("favicon.ico", $FAVICON);
	$self->create_file("root/static/html/index.html", $HTML);
	$self->create_file("root/static/js/demo.js", $JS);
	$self->create_file("root/static/css/demo.css", $CSS);
}

BEGIN {
	$FAVICON = decode_base64(q|iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAALEwAACxMBAJqcGAAABCJpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADx4OnhtcG1ldGEgeG1s
bnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDUuNC4wIj4KICAgPHJkZjpS
REYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMj
Ij4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6
dGlmZj0iaHR0cDovL25zLmFkb2JlLmNvbS90aWZmLzEuMC8iCiAgICAgICAgICAgIHhtbG5zOmV4
aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIgogICAgICAgICAgICB4bWxuczpkYz0i
aHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iCiAgICAgICAgICAgIHhtbG5zOnhtcD0i
aHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyI+CiAgICAgICAgIDx0aWZmOlJlc29sdXRpb25V
bml0PjI8L3RpZmY6UmVzb2x1dGlvblVuaXQ+CiAgICAgICAgIDx0aWZmOkNvbXByZXNzaW9uPjA8
L3RpZmY6Q29tcHJlc3Npb24+CiAgICAgICAgIDx0aWZmOlhSZXNvbHV0aW9uPjcyPC90aWZmOlhS
ZXNvbHV0aW9uPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9u
PgogICAgICAgICA8dGlmZjpZUmVzb2x1dGlvbj43MjwvdGlmZjpZUmVzb2x1dGlvbj4KICAgICAg
ICAgPGV4aWY6UGl4ZWxYRGltZW5zaW9uPjMyPC9leGlmOlBpeGVsWERpbWVuc2lvbj4KICAgICAg
ICAgPGV4aWY6Q29sb3JTcGFjZT4xPC9leGlmOkNvbG9yU3BhY2U+CiAgICAgICAgIDxleGlmOlBp
eGVsWURpbWVuc2lvbj4zMjwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiAgICAgICAgIDxkYzpzdWJq
ZWN0PgogICAgICAgICAgICA8cmRmOkJhZy8+CiAgICAgICAgIDwvZGM6c3ViamVjdD4KICAgICAg
ICAgPHhtcDpNb2RpZnlEYXRlPjIwMTk6MDY6MDIgMTg6MDY6NTI8L3htcDpNb2RpZnlEYXRlPgog
ICAgICAgICA8eG1wOkNyZWF0b3JUb29sPlBpeGVsbWF0b3IgMy44PC94bXA6Q3JlYXRvclRvb2w+
CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgrNXcFJ
AAADe0lEQVRYCeVXS0gbYRCePMhLsRaJoKiXFK0PJBKt8ZIexJKDYKlNVVSUYPBS0KaHUopIC4J6
8nEpVEWkh4iEXCz1UD3kZrGmptUo9uLFx6XFEqlGkunMSnKoabKp6ULpB5P99/93Zr6dnZn/D8D/
DsUVA6Aj/YckVpIAyQmJdJDL5c97e3txcHAQNRrNHHmWSeFdTk5sJM6MjIyPu7u7eH5+jsXFxZ9p
Tp0qAWWqCvS8vbm5+VV5eTmMjY1BOByGUCgECoUCaU2SCLxeXl5Ghs1mw4mJCSQCWFpa+okIaP7g
hVJWudfS0hJhAn6/H41GI25vb2NlZaVkBJRqtfrdysoKc0Cn04mdnZ1oMpkkI8Ahu02gyIfw6OgI
y8rKUKfTSUoAqARfz8/PC1GYmpriBOQqUDE7qVBWVVX1LRgM4unpKVosliA5NkvlPOrnLVcBY3Fx
EakU39DCVbtr1Pal6x2aeUFyi+QuyRMSX1FRER4cHCD1A6T+EKG5+yRph6WmpuZkcnIS8/PzT+rr
68NDQ0NYWFiIDQ0NQiVwFHw+H2ZnZ/vJ+7V0M3g2MjLCPrC1tRU9Ho8wbmxsxKWlJayrq8ONjQ1h
bmBgAClBOTqiILYVc+MRDFIPgNHRUXC5XLC+vg7j4+NweHgIbW1tQEnJ1cHyOBKJuEnhSzIWYgnE
7HDfp9CDw+GAnp4eoI0IlEolkENhvLOzw8T0m5ubHAVHTPGKg6fDw8NCiNvb27GgoAC3traE+3g/
+/v7WF1d/YN8csImhOgI8BsyVCoV1NbWgt1uh9zcXOE+utbX1wfUDyAvLw/6+/s1HR0dD0jlvaD4
mx/RBGSyi52WQ97V1QVmsxmsVivQxgR0FgDOEYPBEHNTUlIClC+Gs7Oz2Fy8gWgCvO8z2CB1PtDr
9ZCTkwNNTU3Azn4FE+aETAbRBGZnZ+H4+BhWV1eBGg94vV4h8SgfkvlIuC6aQEVFBWRmZsLCwgLs
7e0BZTlMT08DHcsSOkjXYqwK4mV9vLm1tTXUarWeZASSf6QLCzJOvr8BsQTCnOWpgJ+PlmciPbEE
fPzNUwGdE7likrZisTa1lIBet9sd73NfmqMk5TPidzJuTOYglXP8jaysLFd3d7eJux39ExKaT9QB
1z2HnPeCmZmZr4FA4BGtzUXX03W9ToZeknBCXBIiwXMfSG6S/Bv4CVh16+2sXAUTAAAAAElFTkSu
QmCC|);
	$HTML = decode_base64(q|PGh0bWw+Cgk8aGVhZD4KCQk8bGluayBocmVmPSIvc3RhdGljL2Nzcy9kZW1vLmNzcyIgdHlwZT0i
dGV4dC9jc3MiIHJlbD0ic3R5bGVzaGVldCI+PC9saW5rPgoJPC9oZWFkPgoJPGJvZHk+CgkJPGRp
diBpZD0icGFnZSI+PC9kaXY+CgkJPHNjcmlwdCBzcmM9Ii9zdGF0aWMvanMvZGVtby5qcyI+PC9z
Y3JpcHQ+Cgk8L2JvZHk+CjwvaHRtbD4K|);
	$JS = decode_base64(q|KGZ1bmN0aW9uICgpIHsKCWxldCBTUEEgPSBmdW5jdGlvbiAoKSB7CgkJdGhpcy5pbml0KCk7CgkJ
cmV0dXJuIHRoaXM7Cgl9OwoJCglTUEEucHJvdG90eXBlID0gewoJCXBhZ2U6IGRvY3VtZW50LnF1
ZXJ5U2VsZWN0b3IoJyNwYWdlJyksCgkJaW5pdDogZnVuY3Rpb24gKCkgewoJCQlsZXQgc2VsZiA9
IHRoaXM7CgkJCXRoaXMucmVxdWVzdCgnaG9tZScsIHt9LCAncmVuZGVyJyk7CgkJfSwKCQlyZXF1
ZXN0OiBmdW5jdGlvbiAocGF0aCwgcGFyYW1zLCBjYikgewoJCQlsZXQgc2VsZiA9IHRoaXM7CgkJ
CWZldGNoKHBhdGgsIHsKCQkJCW1ldGhvZDogIlBPU1QiLCAKCQkJCWhlYWRlcnM6IHsKCQkJCQkn
Q29udGVudC1UeXBlJzogJ2FwcGxpY2F0aW9uL2pzb24nCgkJCQl9LAoJCQkJYm9keTogSlNPTi5z
dHJpbmdpZnkocGFyYW1zKSAKCQkJfSkudGhlbiggKGpzb24pID0+IGpzb24uanNvbigpICkudGhl
biggKGRhdGEpID0+IHNlbGZbY2JdKGRhdGEpICk7CgkJfSwKCQlyZW5kZXI6IGZ1bmN0aW9uIChk
YXRhKSB7CgkJCWxldCBzZWxmID0gdGhpczsKCQkJc2VsZi5jcmVhdGVOb2RlKHsgdGFnOiAiaDEi
LCB0ZXh0OiBkYXRhLnRpdGxlIH0sIHNlbGYucGFnZSk7CgkJCXNlbGYuY3JlYXRlTm9kZSh7IHRh
ZzogInAiLCB0ZXh0OiBkYXRhLmNvbnRlbnQgfSwgc2VsZi5wYWdlKTsKCQl9LAoJCWNyZWF0ZU5v
ZGU6IGZ1bmN0aW9uIChvcHRpb25zLCB3cmFwcGVyLCBuZXN0ZWQpIHsKCQkJbGV0IG5vZGUgPSBk
b2N1bWVudC5jcmVhdGVFbGVtZW50KG9wdGlvbnMudGFnKTsKCQkJbGV0IHJldDsKCQkJaWYgKG9w
dGlvbnMuY2xhc3MpIHRoaXMuYWRkQ2xhc3Mobm9kZSwgb3B0aW9ucy5jbGFzcyk7CgkJCWlmIChv
cHRpb25zLmlkKSBub2RlLmlkID0gb3B0aW9ucy5pZDsKCQkJaWYgKG9wdGlvbnMudGV4dCkgbm9k
ZS5pbm5lclRleHQgPSBvcHRpb25zLnRleHQ7CgkJCWlmIChvcHRpb25zLnN0eWxlKSB0aGlzLmFk
ZENTUyhub2RlLCBvcHRpb25zLnN0eWxlKTsKCQkJaWYgKG9wdGlvbnMudmFsdWUpIG5vZGUudmFs
dWUgPSBvcHRpb25zLnZhbHVlOwoJCQlpZiAob3B0aW9ucy5hdHRyaWJ1dGVzKSB7CgkJCQlmb3Ig
KGxldCBhdHRyIGluIG9wdGlvbnMuYXR0cmlidXRlcykgewoJCQkJCWlmIChhdHRyID09ICdkaXNh
YmxlZCcpIG5vZGUuZGlzYWJsZWQgPSBvcHRpb25zLmF0dHJpYnV0ZXNbYXR0cl07CgkJCQkJZWxz
ZSBpZiAoYXR0ciA9PSAnY2hlY2tlZCcpIG5vZGUuY2hlY2tlZCA9IG9wdGlvbnMuYXR0cmlidXRl
c1thdHRyXTsKCQkJCQllbHNlIGlmIChhdHRyID09ICdzZWxlY3RlZCcpIG5vZGUuc2VsZWN0ZWQg
PSAgb3B0aW9ucy5hdHRyaWJ1dGVzW2F0dHJdOwoJCQkJCWVsc2Ugbm9kZS5zZXRBdHRyaWJ1dGUo
YXR0ciwgb3B0aW9ucy5hdHRyaWJ1dGVzW2F0dHJdKTsKCQkJCX0KCQkJfQoJCQlpZiAob3B0aW9u
cy5jaGlsZHJlbikgewoJCQkJb3B0aW9ucy5jaGlsZHJlbi5mb3JFYWNoKGZ1bmN0aW9uIChjaGls
ZCkgewoJCQkJCWxldCBbY2hpbGRfbm9kZSwgcmV0c10gPSB0aGlzLmNyZWF0ZU5vZGUoY2hpbGQs
IG5vZGUsIDEpOwoJCQkJCWlmIChjaGlsZC5yZXR1cm4gfHwgcmV0cykgcmV0ID0gY2hpbGRfbm9k
ZTsKCQkJCX0uYmluZCh0aGlzKSk7CgkJCX0KCQkJaWYgKG9wdGlvbnMuZXZlbnQpIHsKCQkJCWZv
ciAobGV0IGV2ZW50IGluIG9wdGlvbnMuZXZlbnQpIHsKCQkJCQlub2RlLmFkZEV2ZW50TGlzdGVu
ZXIoZXZlbnQsIG9wdGlvbnMuZXZlbnRbZXZlbnRdKTsKCQkJCX0KCQkJfQoJCQlpZiAod3JhcHBl
cikgd3JhcHBlci5hcHBlbmRDaGlsZChub2RlKTsKCQkJcmV0dXJuIG5lc3RlZCA/IHJldCA/IFsg
cmV0LCAxIF0gOiBbIG5vZGUsIDAgXSA6IHJldCA/IHJldCA6IG5vZGU7CgkJfSwKCQlhZGRDU1M6
IGZ1bmN0aW9uIChub2RlLCBzdHlsZXMpIHsKCQkJZm9yIChsZXQga2V5IGluIHN0eWxlcykgewoJ
CQkJbm9kZS5zdHlsZVtrZXldID0gc3R5bGVzW2tleV07CgkJCX0KCQkJcmV0dXJuIHRoaXM7CgkJ
fSwKCQlyZW1vdmVDU1M6IGZ1bmN0aW9uIChub2RlLCBzdHlsZXMpIHsKCQkJaWYgKHN0eWxlcyBp
bnN0YW5jZW9mIEFycmF5KSBzdHlsZXMuZm9yRWFjaChmdW5jdGlvbiAoYykgewoJCQkJbm9kZS5z
dHlsZVtjXSA9ICcnOwoJCQl9KTsKCQkJZWxzZSBub2RlLnN0eWxlW3N0eWxlc10gPSAnJzsKCQkJ
cmV0dXJuIHRoaXM7CgkJfSwKCQlhZGRDbGFzczogZnVuY3Rpb24gKG5vZGUsIGNsYXNzZXMpIHsK
CQkJKChjbGFzc2VzIGluc3RhbmNlb2YgQXJyYXkpID8gY2xhc3Nlcy5mb3JFYWNoKGZ1bmN0aW9u
IChjKSB7CgkJCQlpZiAoYykgbm9kZS5jbGFzc0xpc3QuYWRkKGMpOwoJCQl9KSA6IG5vZGUuY2xh
c3NMaXN0LmFkZChjbGFzc2VzKSk7CgkJCXJldHVybiB0aGlzOwoJCX0sCgkJcmVtb3ZlQ2xhc3M6
IGZ1bmN0aW9uIChub2RlLCBjbGFzc2VzKSB7CgkJCSgoY2xhc3NlcyBpbnN0YW5jZW9mIEFycmF5
KSA/IGNsYXNzZXMuZm9yRWFjaChmdW5jdGlvbiAoYykgewoJCQkJbm9kZS5jbGFzc0xpc3QucmVt
b3ZlKGMpOwoJCQl9KSA6IG5vZGUuY2xhc3NMaXN0LnJlbW92ZShjbGFzc2VzKSk7CgkJCXJldHVy
biB0aGlzOwoJCX0KCX07CgoJbmV3IFNQQTsKfSkoKTsK|);
	$CSS = decode_base64(q|Ym9keSB7CglwYWRkaW5nOiAxZW07CgltYXJnaW46IDA7CgliYWNrZ3JvdW5kOiBibGFjazsKCWNv
bG9yOiBncmVlbjsKfQo=|);
}

1;

__END__

=head1 NAME

Terse::Helper - Utility for generating Terse skeleton code.

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    	use Terse::Helper;

	Terse::Helper->new()->run('--name' => 'Test::App');

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-terse-runtime at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Terse-Helper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Terse::Helper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Terse-Helper>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Terse-Helper>

=item * Search CPAN

L<https://metacpan.org/release/Terse-Helper>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Terse::Helper
