package Ogma;

use 5.006; use strict; use warnings; use Rope;our $VERSION = '0.03';
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

	@export = qw/option title abstract/ unless @export;

	$PRO{keyword}($caller, $_, \&{$_}) for @export;

	my $extend = 'Ogma';
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

sub run {
	my ($pkg, @params) = @_;

	my $self = Rope->new({ name => $pkg, use => [qw/Rope::Autoload/], properties => $OPTIONS{$pkg}{options} });
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

	if (scalar @params == 1 && $params[0] =~ m/^(h|help)$/) {
		print $OPTIONS{$pkg}{title} . "\n\n";
		print $OPTIONS{$pkg}{abstract} . "\n\n";
		print "Options" . "\n\n";
		for my $o (sort keys %{$options}) {
			print sprintf(
				"%s  %s\n",
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

1;

__END__;


=head1 NAME

Ogma - Command Line Applications via Rope

=head1 VERSION

Version 0.03

=cut

=head1 SYNOPSIS


	package Time::Tracker;

	use Coerce::Types::Standard qw/Int Bool JSON/;

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
	}


	1;

....

	Time::Tracker->run('help');

	Time::Tracker->run('t=1715069487', 'e=1', 'history=[{"one":"two", ...}]');

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ogma at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ogma>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ogma


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Ogma>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Ogma>

=item * Search CPAN

L<https://metacpan.org/release/Ogma>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Ogma
