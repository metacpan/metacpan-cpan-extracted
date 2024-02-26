package maint::inc::PreloadPodWeaver;

use Moose;
extends 'Dist::Zilla::Plugin';
use lib 'maint/inc';

sub register_component {
	require Pod::Elemental::Transformer::Cowl_GenDoc;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
