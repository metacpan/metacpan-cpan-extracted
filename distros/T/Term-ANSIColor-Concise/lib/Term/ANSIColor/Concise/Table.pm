package Term::ANSIColor::Concise::Table;

our $VERSION = "2.0201";

use v5.14;
use utf8;

use Exporter 'import';
our @EXPORT      = qw();
our @EXPORT_OK   = qw(
    colortable colortable6 colortable12 colortable24
    );
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);

use Carp;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use Term::ANSIColor::Concise qw(ansi_color map_to_256);
use List::Util qw(min);

sub colortable6 {
    colortableN(
	step   => 6,
	string => "    ",
	line   => 2,
	x => 1, y => 1, z => 1,
	@_
	);
}

sub colortable12 {
    colortableN(
	step   => 12,
	string => "  ",
	x => 1, y => 1, z => 2,
	@_
	);
}

# use charnames ':full';

sub colortable24 {
    colortableN(
	step   => 24,
	string => "\N{U+2580}", # "\N{UPPER HALF BLOCK}",
	shift  => 1,
	x => 1, y => 2, z => 4,
	@_
	);
}

sub colortableN {
    my %arg = (
	shift => 0,
	line  => 1,
	row   => 3,
	@_);
    my @combi = do {
	my @default = qw( XYZ YZX ZXY  YXZ XZY ZYX );
	if (my @s = $arg{row} =~ /[xyz]{3}/ig) {
	    @s;
	} else {
	    @default[0 .. $arg{row} - 1];
	}
    };
    my @order = map {
	my @ord = map { { X=>0, Y=>1, Z=>2 }->{$_} } /[XYZ]/g;
	sub { @_[@ord] }
    } map { uc } @combi;
    binmode STDOUT, ":utf8";
    for my $order (@order) {
	my $rgb = sub {
	    sprintf "#%02x%02x%02x",
		map { map_to_256($arg{step}, $_) } $order->(@_);
	};
	for (my $y = 0; $y < $arg{step}; $y += $arg{y}) {
	    my @out;
	    for (my $z = 0; $z < $arg{step}; $z += $arg{z}) {
		for (my $x = 0; $x < $arg{step}; $x += $arg{x}) {
		    my $fg = $rgb->($x, $y, $z);
		    my $bg = $rgb->($x, $y + $arg{shift}, $z);
		    push @out, ansi_color "$fg/$bg", $arg{string};
		}
	    }
	    print((@out, "\n") x $arg{line});
	}
    }
}

sub colortable {
    my $width = shift || 144;
    my $column = min 6, $width / (4 * 6);
    for my $c (0..5) {
	for my $b (0..5) {
	    my @format =
		("%d$b$c", "$c%d$b", "$b$c%d", "$b%d$c", "$c$b%d", "%d$c$b")
		[0 .. $column - 1];
	    for my $format (@format) {
		for my $a (0..5) {
		    my $rgb = sprintf $format, $a;
		    print ansi_color "$rgb/$rgb", " $rgb";
		}
	    }
	    print "\n";
	}
    }
    for my $g (0..5) {
	my $grey = $g x 3;
	print ansi_color "$grey/$grey", sprintf(" %-19s", $grey);
    }
    print "\n";
    for ('L00' .. 'L25') {
	print ansi_color "$_/$_", " $_";
    }
    print "\n";
    for my $rgb ("RGBCMYKW", "rgbcmykw") {
	for my $c (split //, $rgb) {
	    print ansi_color "$c/$c", "  $c ";
	}
	print "\n";
    }
    for my $rgb (qw(500 050 005 055 505 550 000 555)) {
	print ansi_color "$rgb/$rgb", " $rgb";
    }
    print "\n";
}

1;

__END__

=head1 NAME

Term::ANSIColor::Concise::Table - Print color table

=head1 SYNOPSIS

  $ perl -MTerm::ANSIColor::Concise::Table=:all -e colortable

=head1 DESCRIPTION

Print color matrix tables.

Use like this:

    perl -MTerm::ANSIColor::Concise::Table=:all -e colortable

=head1 FUNCTION

=over 4

=item B<colortable>([I<width>])

Print visual 256 color matrix table on the screen.  Default I<width>
is 144.

=begin html

<p><img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/Term-ANSIColor-Concise/main/images/colortable-s.png">

=end html

=begin html

<p><img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/Term-ANSIColor-Concise/main/images/colortable-rev-s.png">

=end html

=item B<colortable6>

Print 6x6 24bit color martix tables.

=begin html

<p><img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/Term-ANSIColor-Concise/main/images/colortable6-s.png">

=end html

=item B<colortable12>

Print 12x12 24bit color martix tables.

=begin html

<p><img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/Term-ANSIColor-Concise/main/images/colortable12-s.png">

=end html

=item B<colortable24>

Print 24x24 24bit color martix tables.

=begin html

<p><img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/Term-ANSIColor-Concise/main/images/colortable24-s.png">

=end html

=back

=head1 AUTHOR

Kazumasa Utashiro

=head1 COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2015-2022 Kazumasa Utashiro

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
