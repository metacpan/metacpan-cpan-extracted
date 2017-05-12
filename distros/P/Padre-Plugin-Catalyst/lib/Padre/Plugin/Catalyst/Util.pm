package Padre::Plugin::Catalyst::Util;
use strict;
use warnings;

# some code used all around the Plugin
use Cwd         ();
use File::Spec  ();
use Padre::Util ('_T');

our $VERSION = '0.09';

# get the Catalyst project name, so we can
# figure out the development server's name
# TODO: make this code suck less
sub get_catalyst_project_name {
	my $project_dir = shift;
	return unless $project_dir;

	require File::Spec;
	my @dirs         = File::Spec->splitdir($project_dir);
	my $project_name = lc( $dirs[-1] );
	$project_name =~ tr{-}{_};

	return $project_name;
}

sub find_file_from_output {
	my $filename    = shift;
	my $output_text = shift;

	$filename .= '.pm';

	if ( $output_text =~ m{created "(.+$filename(?:\.new)?)"} ) {
		return $1;
	} else {
		return; # sorry, not found
	}
}

sub get_document_base_dir {
	my $main = Padre->ide->wx->main;
	my $doc  = $main->current->document;

	unless ($doc) {
		Wx::MessageBox(
			_T('Could not open current document. Please make sure you have at least one document open.'),
			_T('Catalyst project dir not found'), Wx::wxOK, $main
		);
		return;
	}

	my $filename = $doc->filename;
	return Padre::Util::get_project_dir($filename);
}

# returns true if given filename (looks like) is inside a
# Catalyst project
sub in_catalyst_project {
	require File::Spec;
	my $filename = shift or return;

	my $project_dir = Padre::Util::get_project_dir($filename);

	foreach my $dir (qw(lib root script t)) {
		return unless -d File::Spec->catdir( $project_dir, $dir );
	}
	return 1;
}

#TODO: maybe this function (or some mutation of it)
# is useful to other plugin authors. In this case, we
# should move it to Padre::Plugin or similar
sub get_plugin_menu_item_by_label {
	my $menu_item = shift;
	my $main      = Padre::ide->wx->main;

	# find plugin menu
	my $menu = $main->menu->{'plugins'}->{'plugin_menus'};
	my $plugin_menu;
	foreach ( @{$menu} ) {
		if ( $_->GetLabel eq 'Catalyst' ) {
			$plugin_menu = $_;
			last;
		}
	}
	return unless $plugin_menu;

	# find requested menu element
	my $submenu = $plugin_menu->GetSubMenu;
	foreach my $item ( $submenu->GetMenuItems ) {
		return $item if $item->GetLabel eq $menu_item;
	}
	return;
}

sub toggle_server_menu {
	my $toggle = shift;

	my $menu_start = get_plugin_menu_item_by_label( _T('Start Web Server') );
	my $menu_stop  = get_plugin_menu_item_by_label( _T('Stop Web Server') );
	if ( $menu_start and $menu_stop ) {
		$menu_start->Enable($toggle);
		$menu_stop->Enable( !$toggle );
	}
}

sub toggle_menu_items {
	my ( $toggle, $is_server_on ) = (@_);

	#TODO: caching this on startup would probably make things marginally faster
	my $menu_helpers = get_plugin_menu_item_by_label( _T('Create new...') );
	my $menu_start   = get_plugin_menu_item_by_label( _T('Start Web Server') );
	my $menu_stop    = get_plugin_menu_item_by_label( _T('Stop Web Server') );
	my $menu_update  = get_plugin_menu_item_by_label( _T('Update Application Scripts') );

	$menu_helpers->Enable($toggle) if $menu_helpers;
	$menu_update->Enable($toggle)  if $menu_update;

	if ( $toggle == 0 ) {
		$menu_start->Enable($toggle) if $menu_start;
		$menu_stop->Enable($toggle)  if $menu_stop;
	} else {
		$menu_start->Enable( !$is_server_on ) if $menu_start;
		$menu_stop->Enable($is_server_on) if $menu_stop;
	}
}

42;
