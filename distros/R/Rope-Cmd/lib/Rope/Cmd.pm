package Rope::Cmd;

use 5.006;
use strict;
use warnings;
use Term::ANSI::Sprintf qw/sprintf/;
use 5.006; use strict; use warnings; use Rope;our $VERSION = '0.05';
our (%PRO, %OPTIONS);

BEGIN {
	%PRO = (
		keyword => sub {
			no strict;
			my ($caller, $meth, $cb) = @_;
			*{"${caller}::${meth}"} = sub { $cb->($caller, @_) };
		}
	);
}

sub import {
	my ($pkg, @export) = @_;

	my $caller = caller();

	@export = qw/option title abstract colors/ unless @export;

	$PRO{keyword}($caller, $_, \&{$_}) for @export;

	my $extend = 'Rope::Cmd';
	my $isa = '@' . $caller . '::ISA';
	eval "push $isa, '$extend'";
}

sub option {
	my ($pkg, $name, %options) = @_;
	! exists $options{$_} && do { $options{$_} = 1 } for qw/enumerable configurable/;
	$OPTIONS{$pkg}{options}{$name} = \%options;
}

sub options {
	my ($pkg) = @_;
	return $OPTIONS{$pkg}{options};
}

sub title {
	my ($pkg, $str) = @_;
	$OPTIONS{$pkg}{title} = $str;
}

sub abstract {
	my ($pkg, $str) = @_;
	$OPTIONS{$pkg}{abstract} = $str;
}

sub colors {
	my ($pkg, %colors) = @_;
	$OPTIONS{$pkg}{colors} = \%colors;
}

sub run {
	my ($pkg, @params) = @_;
	my $self = Rope->new({ name => $pkg, use => [qw/Rope::Autoload/], properties => {
		%{ $OPTIONS{$pkg}{options} },
		print_color => {
			writeable => 1,
			value => sub {
				my ($self, $color, $text) = @_;
				print sprintf('%' . $color, $text);
			}
		}
	}});
	my %map;
	my ($options, $max) = ($OPTIONS{$pkg}{options}, 0);
	for my $o (sort keys %{$options}) {
		my $cur = length $o;
		$map{$o} = $o;
		if ($options->{$o}{option_alias}) {
			$map{$options->{$o}{option_alias}} = $o;
			$cur += length($options->{$o}{option_alias}) + 1;
		}
		$max = $cur if ($cur > $max);
	}

	my $colors = $self->_default_colors($OPTIONS{$pkg}{colors});

	if (scalar @params == 1 && $params[0] =~ m/^(h|help)$/) {
		print sprintf('%' . $colors->{title}, $OPTIONS{$pkg}{title} . "\n\n");
		print sprintf('%' . $colors->{abstract}, $OPTIONS{$pkg}{abstract} . "\n\n");
		print sprintf('%' . $colors->{options_title}, "Options" . "\n\n");
		for my $o (sort keys %{$options}) {
			print sprintf(
				"%$colors->{options}  %$colors->{options_description}\n",
				pack("A${max}", ($options->{$o}{option_alias} ? sprintf("%s|", $options->{$o}{option_alias}) : "") . $o),
				$options->{$o}{description}
			);
		}
		return;
	}

	for my $param (@params) {
		my ($key, $value) = split("\=", $param, 2);
		$self->{$map{$key}} = $value;
	}

	$self->callback();

	return $self;
}

sub _default_colors {
	my ($self, $colors) = @_;
	for (qw/title abstract options_title options options_description/) {
		$colors->{$_} = 's' unless $colors->{$_};
	}
	return $colors;
}

1;

__END__;

=head1 NAME

Rope::Cmd - Command Line Applications via Rope

=head1 VERSION

Version 0.05

=cut

=head1 SYNOPSIS

	package Time::Tracker;

	use Rope::Cmd;
	use Coerce::Types::Standard qw/Int Bool JSON/;

	colors (
	        title => 'bright_green',
		abstract => 'bright_red',
		options_title => 'bright_magenta',
		options => 'bright_cyan',
		options_description => 'bright_yellow'
	);

	title '...';

	abstract '...'

	option time => (
		type => Int,
		option_alias => 'o',
		description => '...'
	);

	option enabled => (
		type => Bool,
		option_alias => 'e',
		description => '...'
	);

	option history => (
		type => JSON->by('decode'),
		type_coerce => 1,
		description => '...'
	);
	
	sub callback {
		my ($self) = @_;
		...
		$self->print_color("red", "Hello World");
	}


	1;

....

	Time::Tracker->run('help');

	Time::Tracker->run('t=1715069487', 'e=1', 'history=[{"one":"two", ...}]');

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rope-cmd at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Rope-Cmd>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Rope::Cmd

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Rope-Cmd>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Rope-Cmd>

=item * Search CPAN

L<https://metacpan.org/release/Rope-Cmd>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Rope::Cmd
