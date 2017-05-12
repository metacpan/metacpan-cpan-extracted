package Padre::Plugin::SpellCheck::Preferences;

use v5.10;
use warnings;
use strict;

use Try::Tiny;
use Padre::Logger;
use Padre::Util                                 ();
use Padre::Locale                               ();
use Padre::Unload                               ();
use Padre::Plugin::SpellCheck::FBP::Preferences ();

our $VERSION = '1.33';
use parent qw(
	Padre::Plugin::SpellCheck::FBP::Preferences
	Padre::Plugin
);

#######
# Method new
#######
sub new {
	my $class = shift;
	my $main  = shift;

	# Create the dialogue
	my $self = $class->SUPER::new($main);

	# define where to display main dialogue
	$self->CenterOnParent;
	$self->SetTitle( sprintf Wx::gettext('Spell-Checker-Preferences v%s'), $VERSION );
	$self->_set_up;

	return $self;
}

#######
# Method _set_up
#######
sub _set_up {
	my $self = shift;

	# set preferred dictionary from config
	try {
		$self->{dictionary} = $self->config_read->{Engine};
	}
	catch {
		$self->{dictionary} = 'Aspell';
	};

	if ( $self->{dictionary} eq 'Aspell' ) {

		# use Aspell as default, as the aspell engine works
		$self->chosen_dictionary->SetSelection(0);
		$self->_local_aspell_dictionaries;
	} else {
		$self->chosen_dictionary->SetSelection(1);
		$self->_local_hunspell_dictionaries;
	}

	# update dialogue with locally install dictionaries;
	$self->_display_dictionaries;

	return;
}

#######
# Method _local_aspell_dictionaries
#######
sub _local_aspell_dictionaries {
	my $self = shift;

	my @local_dictionaries_names = ();

	try {
		require Text::Aspell;
		my $speller = Text::Aspell->new;

		my @local_dictionaries = grep { $_ =~ /^\w+$/ } map { $_->{name} } $speller->dictionary_info;
		$self->{local_dictionaries} = \@local_dictionaries;
		TRACE("Aspell locally installed dictionaries found = @local_dictionaries") if DEBUG;
		TRACE("Aspell iso to dictionary names = $self->{dictionary_names}")        if DEBUG;

		for (@local_dictionaries) {
			push @local_dictionaries_names, $self->padre_locale_label($_);
			$self->{dictionary_names}{$_} = $self->padre_locale_label($_);
		}

		@local_dictionaries_names = sort @local_dictionaries_names;
		$self->{local_dictionaries_names} = \@local_dictionaries_names;

		TRACE("Aspell local dictionaries names = $self->{local_dictionaries_names}") if DEBUG;
	}
	catch {
		$self->{local_dictionaries_names} = \@local_dictionaries_names;
		$self->main->info( Wx::gettext('Text::Aspell is not installed') );
	};
	return;
}


#######
# Method _local_aspell_dictionaries
#######
sub _local_hunspell_dictionaries {
	my $self = shift;

	my @local_dictionaries_names;
	my @local_dictionaries;

	# if ( require Text::Hunspell ) {
	try {
		require Text::Hunspell;
		require Padre::Util;

		my $speller = Padre::Util::run_in_directory_two( cmd => 'hunspell -D </dev/null', option => '0' );
		TRACE("hunspell speller = $speller") if DEBUG;

		#TODO this is yuck must do better
		my @speller_raw = grep { $_ =~ /\w{2}_\w{2}$/m } split /\n/, $speller->{error};
		my %temp_speller;
		foreach (@speller_raw) {
			if ( $_ !~ m/hyph/ ) {
				m/(\w{2}_\w{2})$/;
				my $tmp = $1;
				$temp_speller{$tmp}++;
			}
		}

		while ( my ( $key, $value ) = each %temp_speller ) {
			push @local_dictionaries, $key;
		}

		$self->{local_dictionaries} = \@local_dictionaries;
		TRACE("Hunspell locally installed dictionaries found = $self->{local_dictionaries}") if DEBUG;
		TRACE("Hunspell iso to dictionary names = $self->{dictionary_names}")                if DEBUG;

		for (@local_dictionaries) {
			push( @local_dictionaries_names, $self->padre_locale_label($_) );
			$self->{dictionary_names}{$_} = $self->padre_locale_label($_);
		}

		@local_dictionaries_names = sort @local_dictionaries_names;
		$self->{local_dictionaries_names} = \@local_dictionaries_names;
		TRACE("Hunspell local dictionaries names = $self->{local_dictionaries_names}") if DEBUG;
		return;

	}
	catch {
		$self->{local_dictionaries_names} = \@local_dictionaries_names;
		$self->main->info( Wx::gettext('Text::Hunspell is not installed') );
		return;
	};
	return;
}

#######
# Method _display_dictionaries
#######
sub _display_dictionaries {
	my $self = shift;

	# my $main = $self->main;

	my $prefered_dictionary;
	try {
		$prefered_dictionary = $self->config_read->{ $self->{dictionary} };
	}
	catch {
		$prefered_dictionary = 'Aspell';
	};

	TRACE("iso prefered_dictionary = $prefered_dictionary ") if DEBUG;

	# set local_dictionaries_index to zero in case prefered_dictionary not found
	my $local_dictionaries_index = 0;
	require Padre::Locale;
	for ( 0 .. $#{ $self->{local_dictionaries_names} } ) {
		if ( $self->{local_dictionaries_names}->[$_] eq $self->padre_locale_label($prefered_dictionary) ) {
			$local_dictionaries_index = $_;
		}
	}

	TRACE("local_dictionaries_index = $local_dictionaries_index ") if DEBUG;

	$self->language->Clear;

	# load local_dictionaries_names
	$self->language->Append( $self->{local_dictionaries_names} );

	# highlight prefered_dictionary
	$self->language->SetSelection($local_dictionaries_index);

	return;
}

#######
# event handler _on_button_ok_clicked
#######
sub _on_button_save_clicked {
	my $self = shift;

	my $select_dictionary_name = $self->{local_dictionaries_names}->[ $self->language->GetSelection() ];
	TRACE("selected dictionary name = $select_dictionary_name ") if DEBUG;

	my $select_dictionary_iso = 0;

	# require Padre::Locale;
	for my $iso ( keys %{ $self->{dictionary_names} } ) {
		if ( $self->padre_locale_label($iso) eq $select_dictionary_name ) {
			$select_dictionary_iso = $iso;
		}
	}
	TRACE("selected dictionary iso = $select_dictionary_iso ") if DEBUG;

	# save config info
	my $config = $self->config_read;
	$config->{ $self->{dictionary} } = $select_dictionary_iso;
	$config->{Engine} = $self->{dictionary};
	$self->config_write($config);

	$self->Hide;
	return;
}

#######
# event handler on_dictionary_chosen
#######
sub on_dictionary_chosen {
	my $self = shift;

	if ( $self->chosen_dictionary->GetSelection() == 0 ) {
		$self->{dictionary} = 'Aspell';
		TRACE("Aspell chosen") if DEBUG;
		$self->_local_aspell_dictionaries;
	} else {
		$self->{dictionary} = 'Hunspell';
		TRACE("Hunspell chosen") if DEBUG;
		$self->_local_hunspell_dictionaries;
	}
	$self->_display_dictionaries;

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

Padre::Plugin::SpellCheck::Preferences - Check spelling in Padre, The Perl IDE.

=head1 VERSION

version: 1.33

=head1 DESCRIPTION

This module handles the Preferences dialogue window that is used to set your
 chosen dictionary and preferred language.


=head1 METHODS

=over 2

=item * new

	$self->{dialog} = Padre::Plugin::SpellCheck::Preferences->new( $self );

Create and return a new dialogue window.

=item * on_dictionary_chosen
event handler

=item * padre_locale_label

uses Padre::Local to convert language iso693_iso3166 to utf8text strings

=back

=head1 BUGS AND LIMITATIONS

Throws an info on the status bar if you try to select a language if dictionary not installed

=head1 DEPENDENCIES

Padre, Padre::Plugin::SpellCheck::FBP::Preferences, and either or ( Text::Hunspell or Text::Aspell )

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
