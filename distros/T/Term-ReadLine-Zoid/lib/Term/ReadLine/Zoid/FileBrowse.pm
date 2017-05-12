package Term::ReadLine::Zoid::FileBrowse;

use strict;
use base 'Term::ReadLine::Zoid';

our $VERSION = 0.01;

our %_keymap = ( # maybe inherit from insert ? these could be remapped
	up	 => 'select_previous',
	down	 => 'select_next',
	right    => 'select_next_col',
	left     => 'select_previous_col',
	page_up  => 'page_up',
	page_down => 'page_down',
	return	 => 'accept_line',
	ctrl_C	 => 'return_empty_string',
	escape	 => 'switch_mode',
	'/'	 => 'fb_mini_buffer',
	' '	 => 'toggle_mark',
	'.'	 => 'toggle_hide_hidden',
	_default => 'self_insert',
	_on_switch => 'fb_switch',
);

sub keymap {
	my $self = shift;
	for (
		['hide_hidden_files', 1],
		['fb_prompt', "\e[1;37m -- \%s -- \e[0m"],
	) {
		$$self{config}{$$_[0]} = $$_[1]
			unless defined $$self{config}{$$_[0]}
	}
	return \%_keymap;
}

# fb_item   == item currently selected (pointed at)
# fb_marks  == marked _numbers_ in current dir
# fb_marked == marked _items_ in other dirs
# fb_items  == items in current dir
# fb_dir    == current dir

sub fb_switch {
	my $self = shift;
	@$self{qw/fb_item fb_marks fb_marked fb_items/} = (0, [], [], []);
	$self->fb_switch_dir('.');
}

sub fb_switch_dir { # FIXME FIXME "marked" admisnistrationis contains bugs
	my ($self, $dir) = @_;
	$dir ||= $$self{fb_dir};
	my $pwd;
	if ($dir eq '.') { $dir = $ENV{PWD}; $pwd++; }
	else {
		$dir =~ s#^\./#$ENV{PWD}#;
		$dir =~ s#/\.(/|$)|//+#/#g;
		$dir =~ s#(^|/)[^/]*/\.\.(/|$)##g;
		$dir =~ s#/?$#/#;
	}

	opendir DIR, $dir or return $self->bell;
	my (@marks, @marked);
	for ($self->marked()) {
		if (m#(.*/)(.*)#) {
			if ($1 eq $dir) { push @marks, $2 }
			else { push @marked, $_ }
		}
		elsif ($pwd) { push @marks, $_ }
		else { push @marked, $_ }
	}
	$$self{fb_items} = [ '../',
		map {-d "$dir/$_" ? $_.'/' : $_}
		$$self{config}{hide_hidden_files}
		? (sort grep {$_ !~ /^\./    } readdir DIR)
		: (sort grep {$_ !~ /^\.\.?$/} readdir DIR)
	];
	close DIR;
	$$self{fb_marked} = \@marked;
	$$self{fb_marks} = [];
	if (@marks) {
		my $i = 0;
		for my $item (@{$$self{fb_items}}) {
			push @{$$self{fb_marks}}, $i
				if grep {$_ eq $item} @marks;
			$i++;
		}
	}
	@$self{qw/fb_item fb_dir/} = (0, $dir);
}

sub draw { # Render Fu
	my $self = shift;
	
	my @pos = (1, 1);
	my @lines = map "   $_", @{$$self{fb_items}};
	for (@{$$self{fb_marks}}) { $lines[$_] =~ s/^ /*/ }
	$lines[ $$self{fb_item} ] =~ s/^(.) /$1>/;

	@lines = $self->col_format( @lines );
	$$self{fb_rows} = scalar @lines;
	$pos[1] += ($$self{fb_item} % $$self{fb_rows}); # assuming +1 offset due to fb_prompt

	unshift @lines, sprintf $$self{config}{fb_prompt}, $$self{fb_dir};

	$self->print(\@lines, \@pos);
}

sub toggle_hide_hidden {
	$_[0]{config}{hide_hidden_files}  =
		$_[0]{config}{hide_hidden_files} ? 0 : 1 ;
	$_[0]->fb_switch_dir();
}

sub self_insert {
	my ($self, $key) = @_;
	return $self->bell unless $key =~ /^\d+$/;
	#$$self{fb_item} .= $key;
}

sub accept_line {
	my $self = shift;
	my $dir = $$self{fb_dir}.'/'.$$self{fb_items}[ $$self{fb_item} ];
	return $self->fb_switch_dir($dir) if -d $dir;

	push @{$$self{fb_marks}}, $$self{fb_item};
	my @words = map {s/'/\\'/g; '\''.$_.'\''} $self->marked();
	$self->substring(join(' ', @words), $$self{pos});
	$self->switch_mode();
}

sub fb_mini_buffer {
	my $self = shift;
}

sub select_next { $_[0]{fb_item}++ if $_[0]{fb_item} < $#{$_[0]{fb_items}} }

sub page_up { 
	my $self = shift;
	my (undef, $higth) = $self->TermSize();
	my $vpos = $$self{fb_item} % $$self{fb_rows};
	if ($vpos > $higth) { $$self{fb_item} -= $higth }
	else { $$self{fb_item} -= $vpos }
}

sub page_down {
	my $self = shift;
	my (undef, $higth) = $self->TermSize();
	my $rvpos = $$self{fb_rows} - ($$self{fb_item} % $$self{fb_rows});
	if ($rvpos > $higth) { $$self{fb_item} += $higth }
	else { $$self{fb_item} += $rvpos }
	$$self{fb_item} = $#{$$self{fb_items}} if $$self{fb_item} > $#{$$self{fb_items}};
}

sub select_previous { $_[0]{fb_item}-- if $_[0]{fb_item} > 0 }

sub select_next_col {
	$_[0]{fb_item} += $_[0]{fb_rows}
		unless $_[0]{fb_rows} > $#{$_[0]{fb_items}} - $_[0]{fb_item};
}

sub select_previous_col {
	$_[0]{fb_item} -= $_[0]{fb_rows}
		unless $_[0]{fb_rows} > $_[0]{fb_item};
}

sub toggle_mark { # FIXME should be toggle
	my $self = shift;
	my $l = scalar @{$$self{fb_marks}};
	@{$$self{fb_marks}} = grep {$_ != $$self{fb_item}} @{$$self{fb_marks}};
	push @{$$self{fb_marks}}, $$self{fb_item} if $l == scalar @{$$self{fb_marks}};
	$self->select_next();
}

sub marked {
	my $self = shift;
	my $dir = $$self{fb_dir};
	$dir =~ s#^\Q$ENV{PWD}\E/?##;
	$dir =~ s#/?$#/# if length $dir;
	return @{$$self{fb_marked}},
		map $dir.$_, @{$$self{fb_items}}[ @{$$self{fb_marks}} ];
}

1;

__END__

=head1 NAME

Term::ReadLine::Zoid::FileBrowse - a readline file browser mode

=head1 SYNOPSIS

This class is used as a mode under L<Term::ReadLine::Zoid>,
see there for usage details.

=head1 DESCRIPTION

This module provides a "file browse" mode that lets you interactively select files
and navigate your file-system.

=head1 KEY MAPPING

=over 4

=item up  (I<select_previous>)

=item down  (I<select_next>)

=item right  (I<select_next_col>)

=item left  (I<select_previous_col>)

=item page_up  (I<page_up>)

=item page_down  (I<page_down>)

=item return  (I<accept_line>)

=item ^C  (I<return_empty_string>)

=item escape  (I<switch_mode>)

=item /  (I<fb_mini_buffer>)

=item space  (I<toggle_mark>)

=item .  (I<toggle_hide_hidden>)

=back

=head1 TODO

make fb_prompt config compatible with PS1 stuff
and keep $ENV{CLICOLOR} in mind

=head1 AUTHOR

Jaap Karssenberg (Pardus) E<lt>pardus@cpan.orgE<gt>

Copyright (c) 2004 Jaap G Karssenberg. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Term::ReadLine::Zoid>

=cut

