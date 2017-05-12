package Padre::Plugin::SpellCheck::Checker;

use v5.10;
use warnings;
use strict;

use Encode;
use Padre::Logger;
use Padre::Locale                           ();
use Padre::Unload                           ();
use Padre::Plugin::SpellCheck::FBP::Checker ();

our $VERSION = '1.33';
use parent qw(
	Padre::Plugin::SpellCheck::FBP::Checker
	Padre::Plugin
);

use Class::Accessor 'antlers';
has _autoreplace => ( is => 'rw' ); # list of automatic replaces
has _engine      => ( is => 'rw' ); # pps:engine object
has _label       => ( is => 'rw' ); # label hosting the misspelled word
has _list        => ( is => 'rw' ); # listbox listing the suggestions
has _offset      => ( is => 'rw' ); # offset of _text within the editor
has _sizer       => ( is => 'rw' ); # window sizer
has _text        => ( is => 'rw' ); # text being spellchecked


#######
# Method new
#######
sub new {
	my $class = shift;
	my $main  = shift;

	# Create the dialog
	my $self = $class->SUPER::new($main);

	# define where to display main dialog
	$self->CenterOnParent;
	$self->SetTitle( sprintf( Wx::gettext('Spell-Checker v%s'), $VERSION ) );
	$self->_set_up;

	return $self;
}

#######
# Method _set_up
#######
sub _set_up {
	my $self    = shift;
	my $main    = $self->main;
	my $current = $main->current;

	my $text_spell = $self->config_read->{Engine};
	my $iso_name   = $self->config_read->{$text_spell};

	#Thanks alias
	my $status_info = "$text_spell => " . $self->padre_locale_label($iso_name);
	$self->{status_info}->GetStaticBox->SetLabel($status_info);


	# TODO: maybe grey out the menu option if
	# no file is opened?
	unless ( $current->document ) {
		$main->message( Wx::gettext('No document opened.'), 'Padre' );
		return;
	}

	my $mime_type = $current->document->mimetype;
	require Padre::Plugin::SpellCheck::Engine;
	my $engine = Padre::Plugin::SpellCheck::Engine->new( $mime_type, $iso_name, $text_spell );
	$self->_engine($engine);

	# fetch text to check
	my $selection = $current->text;
	my $wholetext = $current->document->text_get;

	my $text = $selection || $wholetext;
	$self->_text($text);

	my $offset = $selection ? $current->editor->GetSelectionStart : 0;
	$self->_offset($offset);

	# try to find a mistake
	my @error = $engine->check($text);
	my ( $word, $pos ) = @error;
	$self->{error} = \@error;

	# no mistake means bbb we're done
	if ( not defined $word ) {

		return;
	}

	$self->_autoreplace( {} );
	$self->_update;

	return;
}

#######
# Method _update;
# update the dialog box with current error. aa
#######
sub _update {
	my $self    = shift;
	my $main    = $self->main;
	my $current = $main->current;
	my $editor  = $current->editor;

	my $error = $self->{error};
	my ( $word, $pos ) = @{$error};

	# update selection in parent window
	my $offset = $self->_offset;
	my $from   = $offset + $pos + $self->_engine->_utf_chars;

	my $to = $from + length Encode::encode_utf8($word);
	$editor->goto_pos_centerize($from);
	$editor->SetSelection( $from, $to );

	# update label
	$self->labeltext->SetLabel('Not in dictionary:');
	$self->label->SetLabel($word);

	# update list
	my @suggestions = $self->_engine->get_suggestions($word);

	$self->list->DeleteAllItems;
	my $i = 0;
	foreach my $w ( reverse @suggestions ) {
		next unless defined $w;
		my $item = Wx::ListItem->new;
		$item->SetText($w);
		my $idx = $self->list->InsertItem($item);
		last if ++$i == 32; #TODO Fixme: should be a preference, why
	}

	# select first item
	my $item = $self->list->GetItem(0);
	$item->SetState(Wx::wxLIST_STATE_SELECTED);
	$self->list->SetItem($item);

	return;
}


#######
# dialog->_next;
#
# try to find next mistake, and update dialog to show this new error. if
# no error, display a message and exit.
#
# no params. no return value.
#######
sub _next {
	my ($self) = @_;
	my $autoreplace = $self->_autoreplace;

	# try to find next mistake
	my @error = $self->_engine->check( $self->_text );
	my ( $word, $pos ) = @error;
	$self->{error} = \@error;

	# no mistake means we're done
	if ( not defined $word ) {
		$self->list->DeleteAllItems;
		$self->label->SetLabel('Click Close');
		$self->labeltext->SetLabel('Spell check finished:...');
		$self->{replace}->Disable;
		$self->{replace_all}->Disable;
		$self->{ignore}->Disable;
		$self->{ignore_all}->Disable;
		return;
	}

	# check if we have hit a replace all word
	if ( exists $autoreplace->{$word} ) {
		$self->_replace( $autoreplace->{$word} );
		redo; # move on to next error
	}

	# update gui with new error
	$self->_update;
	return;
}

#######
# Method _replace( $word );
#
# fix current error by replacing faulty word with $word.
#
# no param. no return value.
#######
sub _replace {
	my ( $self, $new ) = @_;
	my $main   = $self->main;
	my $editor = $main->current->editor;

	# replace word in editor
	my $error = $self->{error};
	my ( $word, $pos ) = @{$error};
	my $offset = $self->_offset;
	my $from   = $offset + $pos + $self->_engine->_utf_chars;

	# say 'length '.length Encode::encode_utf8($word);
	my $to = $from + length Encode::encode_utf8($word);
	$editor->SetSelection( $from, $to );
	$editor->ReplaceSelection($new);

	# FIXME: as soon as STC issue is resolved:
	# Include UTF8 characters from newly added word
	# to overall count of UTF8 characters
	# so we can set proper selections
	$self->_engine->_count_utf_chars($new);

	# remove the beginning of the text, up to after replaced word
	my $posold = $pos + length $word;
	my $posnew = $pos + length $new;
	my $text   = substr $self->_text, $posold;
	$self->_text($text);
	$offset += $posnew;
	$self->_offset($offset);

	return;
}


########
# Event Handlers
########

#######
# Event Handler _on_ignore_all_clicked;
#######
sub _on_ignore_all_clicked {
	my $self = shift;

	my $error = $self->{error};
	my ( $word, $pos ) = @{$error};
	$self->_engine->set_ignore_word($word);
	$self->_on_ignore_clicked;

	return;
}

#######
# Event Handler$self->_on_ignore_clicked;
#######
sub _on_ignore_clicked {
	my $self = shift;

	# remove the beginning of the text, up to after current error
	my $error = $self->{error};
	my ( $word, $pos ) = @{$error};

	$pos += length $word;
	my $text = substr $self->_text, $pos;
	$self->_text($text);

	my $offset = $self->_offset + $pos;
	$self->_offset($offset);

	# FIXME: as soon as STC issue is resolved:
	# Include UTF8 characters from ignored word
	# to overall count of UTF8 characters
	# so we can set proper selections
	$self->_engine->_count_utf_chars($word);

	# try to find next error
	$self->_next;
	return;
}

#######
# Event Handler _on_replace_all_clicked;
#######
sub _on_replace_all_clicked {
	my $self  = shift;
	my $error = $self->{error};
	my ( $word, $pos ) = @{$error};

	# get replacing word
	my $index = $self->list->GetNextItem( -1, Wx::wxLIST_NEXT_ALL, Wx::wxLIST_STATE_SELECTED );
	return if $index == -1;
	my $selected_word = $self->list->GetItem($index)->GetText;

	# store automatic replacement
	$self->_autoreplace->{$word} = $selected_word;

	# do the replacement
	$self->_on_replace_clicked;
	return;
}

#######
# Event Handler _on_replace_clicked;
#######
sub _on_replace_clicked {
	my $self  = shift;
	my $event = shift;

	# get replacing word
	my $index = $self->list->GetNextItem( -1, Wx::wxLIST_NEXT_ALL, Wx::wxLIST_STATE_SELECTED );
	return if $index == -1;
	my $selected_word = $self->list->GetItem($index)->GetText;

	# actually replace word in editor
	$self->_replace($selected_word);

	# try to find next error
	$self->_next;
	return;
}

#######
# Composed Method padre_local_label
# aspell to padre local label
#######
sub padre_locale_label {
	my $self             = shift;
	my $local_dictionary = shift;

	my $lc_local_dictionary = lc( $local_dictionary ? $local_dictionary : 'en_GB' );
	$lc_local_dictionary =~ s/_/-/;
	require Padre::Locale;
	my $label = Padre::Locale::label($lc_local_dictionary);

	return $label;
}

1;

__END__

=pod

=head1 NAME

Padre::Plugin::SpellCheck::Checker - Check spelling in Padre, The Perl IDE.

=head1 VERSION

version: 1.33

=head1 DESCRIPTION

This module implements the Checker dialogue window that will be used to interact
with the user when spelling mistakes have been spotted.

=head1 METHODS

=over 2

=item * new

	$self->{dialog} = Padre::Plugin::SpellCheck::Checker->new( $self );

Create and return a new dialogue window.

=item * padre_locale_label

uses Padre::Local to convert language iso693_iso3166 to utf8text strings

=back

=head1 BUGS AND LIMITATIONS

Text::Hunspell hard coded for /usr/share/hunspell/

=head1 DEPENDENCIES

Padre, Padre::Locale, Class::XSAccessor, Padre::Plugin::SpellCheck::FBP::Checker,
 and either or ( Text::Hunspell or Text::Aspell )

=head1 SEE ALSO

For all related information (bug reporting, source code repository,
etc.), refer to L<Padre::Plugin::SpellCheck>.

=head1 AUTHOR

See L<Padre::Plugin::SpellCheck>

=head2 CONTRIBUTORS

See L<Padre::Plugin::SpellCheck>

=head1 COPYRIGHT

See L<Padre::Plugin::SpellCheck>

=head1 LICENSE

See L<Padre::Plugin::SpellCheck>

=cut
