use strict ;
use warnings ;
use Test::More ;

my @modules = qw(
	Term::ANSIColor::Gradients
	Term::ANSIColor::Gradients::Utils
	Term::ANSIColor::Gradients::Classic
	Term::ANSIColor::Gradients::Extended
	Term::ANSIColor::Gradients::Accessibility
	Term::ANSIColor::Gradients::Artistic
	Term::ANSIColor::Gradients::Diverging
	Term::ANSIColor::Gradients::Scientific
	Term::ANSIColor::Gradients::Sequential
) ;

use_ok($_) for @modules ;

my @data_modules = qw(
	Term::ANSIColor::Gradients::Classic
	Term::ANSIColor::Gradients::Extended
	Term::ANSIColor::Gradients::Accessibility
	Term::ANSIColor::Gradients::Artistic
	Term::ANSIColor::Gradients::Diverging
	Term::ANSIColor::Gradients::Scientific
	Term::ANSIColor::Gradients::Sequential
) ;

for my $mod (@data_modules)
	{
	no strict 'refs' ;

	my %g = %{"${mod}::GRADIENTS"} ;
	my %c = %{"${mod}::CONTRAST"} ;

	ok(scalar keys %g > 0, "$mod has at least one gradient") ;

	is_deeply([sort keys %c], [sort keys %g], "$mod CONTRAST keys match GRADIENTS keys") ;

	for my $name (sort keys %g)
		{
		my $arr = $g{$name} ;
		my $con = $c{$name} ;

		ok(ref $arr eq 'ARRAY', "$mod $name gradient is an array-ref") ;
		ok(scalar @$arr > 0,   "$mod $name gradient is non-empty") ;

		my @bad_g = grep { !defined $_ || $_ !~ /^\d+$/ || $_ < 0 || $_ > 255 } @$arr ;
		is(scalar @bad_g, 0, "$mod $name gradient contains only valid ANSI indices (0-255)") ;

		ok(ref $con eq 'ARRAY', "$mod $name contrast is an array-ref") ;
		is(scalar @$con, scalar @$arr, "$mod $name contrast length matches gradient length") ;

		my @bad_c = grep { !defined $_ || $_ !~ /^\d+$/ || $_ < 0 || $_ > 255 } @$con ;
		is(scalar @bad_c, 0, "$mod $name contrast contains only valid ANSI indices (0-255)") ;
		}
	}

use Term::ANSIColor::Gradients qw(list_groups) ;
my @groups = list_groups() ;
ok(scalar @groups > 0, 'list_groups returns at least one group') ;
ok((grep { $_ eq 'Classic' } @groups), 'Classic is in list_groups') ;

use Term::ANSIColor::Gradients::Utils qw(build_contrast intensity_shift) ;

my $c = build_contrast(21) ;
ok(defined $c && $c >= 0 && $c <= 255, 'build_contrast returns valid index for blue (21)') ;

my $lighter = intensity_shift(21, 4) ;
ok(defined $lighter && $lighter >= 0 && $lighter <= 255, 'intensity_shift returns valid index') ;

my $same_h = intensity_shift(21, 0) ;
ok(defined $same_h && $same_h >= 0 && $same_h <= 255, 'intensity_shift with delta 0 returns valid index') ;

done_testing() ;
