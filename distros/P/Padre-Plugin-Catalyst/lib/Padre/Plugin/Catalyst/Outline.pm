package Padre::Plugin::Catalyst::Outline;

use strict;
use warnings;

use Padre::Wx   ();
use Padre::Util ('_T');
use Wx;

use base 'Wx::TreeCtrl';

our $VERSION = '0.09';


sub new {
	my $class  = shift;
	my $plugin = shift;
	my $main   = Padre::Current->main;

	my $self = $class->SUPER::new(
		$main->right,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTR_HIDE_ROOT | Wx::wxTR_SINGLE | Wx::wxTR_HAS_BUTTONS | Wx::wxTR_LINES_AT_ROOT
	);
	$self->SetIndent(10);
	$self->{force_next} = 0;

	Wx::Event::EVT_COMMAND_SET_FOCUS(
		$self, $self,
		sub {

			#			$self->on_tree_item_set_focus( $_[1] );
		},
	);

	# Double-click a function name
	Wx::Event::EVT_TREE_ITEM_ACTIVATED(
		$self, $self,
		sub {

			#			$self->on_tree_item_activated( $_[1] );
		}
	);

	$self->Hide;

	#    $self->Show;
	$main->right->show($self);
	$self->fill;

	return $self;
}

# fill() fills the TreeCtrl with information regarding the project
sub fill {
	my $self = shift;

	my $tree_ref = $self->update_tree;
	my $root = $self->AddRoot( 'Root', -1, -1, Wx::TreeItemData->new('Data') );
	$self->populate( $root, $tree_ref );
}

# update_tree() should return whatever it is we want it to fill the
# Catalyst side-panel (TreeCtrl) with, as a hash reference.
# TODO: I'm still wondering about this Outline. What would you like it
# to display?
sub update_tree {
	return {
		'Model' => {},
		'View'  => {
			'TT' => 1,
		},
		'Controller' => {
			'Root' => 1,
			'Foo'  => {
				'Bar' => 1,
			}
		},
		'Templates' => {
			'one.tt'   => 1,
			'two.tt'   => 1,
			'three.tt' => 1,
		},
	};
}

# receives a hash reference and populates tree (starting from $root node)
# with its sorted values, recursively
sub populate {
	my ( $self, $root, $tree_ref ) = (@_);

	foreach my $item ( sort keys %{$tree_ref} ) {
		my $node = $self->AppendItem( $root, $item, -1, -1, Wx::TreeItemData->new($item) );

		if ( ref $tree_ref->{$item} ) {
			$self->populate( $node, $tree_ref->{$item} );
		}
	}
}

sub gettext_label {
	_T('Catalyst');
}


1;

