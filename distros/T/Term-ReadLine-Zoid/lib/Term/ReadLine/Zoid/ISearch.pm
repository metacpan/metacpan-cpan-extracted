package Term::ReadLine::Zoid::ISearch;

use strict;
use base 'Term::ReadLine::Zoid';
no warnings; # undef == '' down here

our $VERSION = 0.06;

our %_keymap = (
	backspace  => 'backward_delete_char',
	ctrl_R     => 'isearch_again',
	_on_switch => 'is_switch',
	_default   => 'self_insert'
);

sub keymap { return \%_keymap }

sub is_switch {
	my $self = shift;
	$$self{is_lock} = undef;
	$$self{is_hist_p} = -1;
	$$self{is_save} = [[''], [0,0], undef];
}

sub is_switch_back {
	my ($self, $key) = @_;
	$$self{_hist_save} = $self->save();
	@$self{qw/lines pos hist_p/} = @{$$self{is_save}};
	$self->switch_mode();
	$self->do_key($key);
}

sub draw { # rendering this inc mode is kinda consuming
	my ($self, @args) = @_;
	my $save = $self->save();
	my $string = join "\n", @{$$self{lines}};
	$$self{prompt} = "i-search qr($string): ";
	goto DRAW unless length $string;

	my ($result, $match, $hist_p) = (undef, '', $$self{is_hist_p});
	$$self{last_search} = ['b', $string];
	my $reg = eval { qr/^(.*?$string)/ };
	goto DRAW if $@;

	while ($hist_p < $#{$$self{history}}) {
		$hist_p++;
		next unless $$self{history}[$hist_p] =~ $reg;
		($result, $match) = ($$self{history}[$hist_p], $1);
		last;
	}

	if (defined $result) {
		push @{$$self{last_search}}, $hist_p;
		$$self{is_lock} = undef;
		$$self{lines} = [ split /\n/, $result ];
		my @match = split /\n/, $match;
		$$self{pos} = [length($match[-1]), $#match];
	}
	else { $$self{is_lock} = 1 }

	DRAW: Term::ReadLine::Zoid::draw($self, @args);
	$$self{is_save} = [ $$self{lines}, $$self{pos}, $hist_p];
	$self->restore($save);
}

sub self_insert {
	if ($_[0]{is_lock}) { $_[0]->bell }
	elsif ($_[0]->key_binding($_[1], $_[0]{config}{default_mode})) {
		goto \&is_switch_back;
	}
	else { goto \&Term::ReadLine::Zoid::self_insert }
}

sub isearch_again { $_[0]{is_hist_p} = $_[0]{last_search}[-1] if $_[0]{last_search} }

1;

__END__

=head1 NAME

Term::ReadLine::Zoid::ISearch - a readline incremental search mode

=head1 SYNOPSIS

This class is used as a mode under L<Term::ReadLine::Zoid>,
see there for usage details.

=head1 DESCRIPTION

This mode is intended as a work alike for the incremental search
found in the gnu readline library.

In this mode the string you enter is regarded as a B<perl regex> which is used
to do an incremental histroy search.

Pressing '^R' repeatingly will give alternative results.

Special keys like movements or the C<return> drop you out of this mode
and set the edit line to the last search result.

=head1 AUTHOR

Jaap Karssenberg || Pardus [Larus] E<lt>pardus@cpan.orgE<gt>

Copyright (c) 2004 Jaap G Karssenberg. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

=cut

