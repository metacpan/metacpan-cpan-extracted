package Padre::Plugin::Moose::Util;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.21';

sub add_moose_keywords_highlighting {
	my $type     = shift or return;
	my $document = shift or return;
	my $editor   = shift or return;

	my $keywords = Padre::Wx::Scintilla->keywords($document);
	if ( Params::Util::_ARRAY($keywords) ) {
		foreach my $i ( 0 .. $#$keywords ) {
			my $keyword_list = $keywords->[$i];
			if ( $i == 0 ) {
				$keyword_list
					.= ' has with extends before around after'
					. ' override super augment inner type subtype'
					. ' enum class_type as where coerce via from'
					. ' requires excludes';
				if ( $type eq 'MooseX::Declare' ) {
					$keyword_list .= ' class role method dirty clean mutable';
				}
			}
			$editor->Wx::Scintilla::TextCtrl::SetKeyWords( $i, $keyword_list );
		}
	}

	return;
}
