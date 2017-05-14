package Template::Flute::I18N;

use strict;
use warnings;

=head1 NAME

Template::Flute::I18N - Localization class for Template::Flute

=head1 SYNOPSIS

    %german_map = (Cart=> 'Warenkorb', Price => 'Preis');

    sub translate {
        my $text = shift;

        return $german_map{$text};
    };

    $i18n = Template::Flute::I18N->new(\&translate);

    $flute = Template::Flute(specification => ...,
                             template => ...,
                             i18n => $i18n);

=head1 CONSTRUCTOR

=head2 new [CODEREF]

Create a new Template::Flute::I18N object. CODEREF is used by
localize method for the text translation.

=cut

sub new {
	my ($proto, @args) = @_;
	my ($class, $self);

	$class = ref($proto) || $proto;
	$self = {};
	
	if (ref($args[0]) eq 'CODE') {
		# use first parameter as localization function
		$self->{func} = shift(@args);
	}
	else {
		# noop translation
		$self->{func} = sub {return;}
	}

	bless ($self, $class);
}

=head1 METHODS

=head2 localize STRING

Calls localize function with provided STRING. The result is
returned if it contains non blank characters. Otherwise the
original STRING is returned.

=cut

sub localize {
	my ($self, $text) = @_;
	my ($trans);
	
	$trans = $self->{func}->($text);

	if (defined $trans && $trans =~ /\S/) {
		return $trans;
	}

	return $text;
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
