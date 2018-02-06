=head1 NAME

Padre::Plugin::JSONUtilities - Adds buttons to beautify or compress json.

=cut

=head1 SYNOPSIS

Padre::Plugin::JSONUtilities is designed to compress or expand JSON. Enough said. Also to canonically sort, if you want.

=cut

package Padre::Plugin::JSONUtilities;

use 5.010;
use strict;
use warnings;
use utf8;
use Padre::Plugin();
use Padre::Role::Task;

our $VERSION = '0.10';
use base qw(Padre::Plugin);

sub padre_interfaces {
	return (
		'Padre::Plugin'   => 0.94,
		'Padre::Constant' => 0.94,
		'Padre::Unload'   => 0.94,
	);
}

use constant CHILDREN => qw{Padre::Plugin::JSONUtilities};

sub plugin_name { return Wx::gettext('JSON Utility Plugin'); } 

use Padre::Wx::Dialog::OpenResource;
use Padre::Wx    ();
use JSON;



sub plugin_enable {
	my ($self) = @_;
	$self->{canonicalize} = 1;
	return $self->SUPER::plugin_enable;
}

sub canonicalize { $_[0]->{canonicalize} = $_[1] if @_ > 1; return $_[0]->{canonicalize}; }

sub beautify {
	my ($self) = @_;
	my $document = Padre::Current->document;
	my $json = JSON->new->canonical($self->canonicalize)->utf8->pretty;
	my $data = eval { $json->decode($document->text_get) };
	if (my $exp = $@) {
		Padre::Current->main->error("Error parsing JSON: $exp.");
		return;
	}
	$document->text_set($json->encode($data));
	Padre::Current->editor->GotoPos(0);
}

sub compress {
	my ($self) = @_;
	my $document = Padre::Current->document;
	my $json = JSON->new->canonical($self->canonicalize)->utf8;
	my $data = eval { $json->decode($document->text_get) };
	if (my $exp = $@) {
		Padre::Current->main->error("Error parsing JSON: $exp.");
		return;
	}
	$document->text_set($json->encode($data));
	Padre::Current->editor->GotoPos(0);
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'About' => sub { $self->show_about },
		"JSON Beautify\tCtrl+Shift+D" => sub {
			$self->beautify;
		},
		"JSON Compress\tCtrl+Shift+S" => sub {
			$self->compress;
		}
	];
}

sub plugin_icon {
	require Padre::Wx::Icon;
	
	require File::ShareDir;
	my $sharedir =  File::ShareDir::dist_dir("Padre-Plugin-JSONUtilities");
	my $file = File::Spec->catfile(
		$sharedir,
		"logo"
	) . ".png";
	return Padre::Wx::Icon::find('logo') unless -f $file;
	my $image = Wx::Bitmap->new($file, Wx::BITMAP_TYPE_PNG );
	my $icon  = Wx::Icon->new;
	$icon->CopyFromBitmap($image);
	return $icon;
}

sub show_about {
	my $self = shift;
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName('JSON Utilities Plugin');
	$about->SetDescription( <<"END_MESSAGE" );

Plugin designed to make handling JSON easier.

END_MESSAGE
	Wx::AboutBox($about);

	return;
}

sub plugin_disable {
	my $self = shift;	
	for my $package (CHILDREN) {
		require Padre::Unload;
		Padre::Unload->unload($package);
	}
	$self->SUPER::plugin_disable(@_);
	return 1;
}

1;

=head1 AUTHOR

Adam Harrison <adamdharrison@gmail.com>

=cut