package Term::ReadLine::Zoid::Emacs;

use strict;
use base 'Term::ReadLine::Zoid';

our $VERSION = 0.01;

=head1 NAME

Term::ReadLine::Zoid::Emacs - a readline emacs mode

=head1 SYNOPSIS

This class is used as a mode under L<Term::ReadLine::Zoid>,
see there for usage details.

=head1 DESCRIPTION

This mode provides some emacs key-bindings, taking the L<bash>(1)
implementation as a reference.

This module also provides a 'emac_multiline' key map.

=head1 KEY MAPPING

These bindings are additional to those in L<Term::ReadLine::Zoid> which
already contains some emacs key bindings.

=over 4

=cut

our %_keymap = (
	ctrl_Q	=> 'quoted_insert',
	escape	=> 'prefix_meta',
	meta_f	=> 'forward_word',
	meta_b	=> 'backward_word',
	ctrl_X  => 'prefix_key',
	ctrl_X_ctrl_V => 'switch_mode_command',
	_isa	=> 'insert',
);

our %_m_keymap;

sub keymap {
	return \%_keymap unless $_[1] =~ /multiline/;
	unless (%_m_keymap) {
		%_m_keymap = %_keymap;
		$_m_keymap{_isa} = 'multiline';
	}
	return \%_m_keymap;
}

=item escape, ^[  (I<prefix_meta>)

=cut

sub prefix_meta { $_[0]->prefix_key('meta') }

sub prefix_key {
	my ($self, $pre) = @_;
	my ($key, $cnt);
	until ($key) {
		my $k = $self->read_key();
		if ($k =~ /^[\-\d]+$/) { $cnt .= $k }
		else { $key = $self->key_name( $k ) }
	}
	$self->do_key($pre.'_'.$key, $cnt);
}

=item meta-f  (I<forward_word>)

=item meta-b  (I<backward_word>)

=cut

sub forward_word { # simple version of vi_E
	my ($self, undef, $cnt) = @_;
	$cnt ||= 1;
	my $l = $$self{lines}[ $$self{pos}[1] ];
	for (1 .. $cnt) {
		if ($l =~ /^.{$$self{pos}[0]}(\w?.*?\w+)/) { $$self{pos}[0] += length($1) }
		else {
			$self->end_of_line();
			last;
		}
	}
	return 1;
}

sub backward_word { # simple version of vi_B
	my ($self, undef, $cnt) = @_;
	$cnt ||= 1;
	my $l = $$self{lines}[ $$self{pos}[1] ];
	for (1 .. $cnt) {
		$l = substr($l, 0, $$self{pos}[0]);
		if ($l =~ /(\w+[^\w]*)$/) { $$self{pos}[0] -= length $1 }
		else {
			$self->beginning_of_line;
			last;
		}
	}
	return 1;
}

1;

__END__

=item ^X^V  (I<switch_mode_command>)

Enter (vi) command mode. Taken from L<zsh>(1).

=item ^V, ^Q  (I<quoted_insert>)

Insert next key literally, ignoring any key-bindings.

WARNING: control or escape chars in the editline can cause unexpected results

=back

=head1 TODO

Get count args right (see bash reference)

A lot more bindings

A emacs multiline mode

=head1 AUTHOR

Jaap Karssenberg (Pardus) E<lt>pardus@cpan.orgE<gt>

Copyright (c) 2004 Jaap G Karssenberg. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Term::ReadLine::Zoid>

=cut

