use strict;
use warnings;
use Benchmark qw(cmpthese);

my $RENDER_COUNT = 1;
my %data         = ( name => 'Alice & Bob', age => 45.1 );

for my $i (1, 10, 100) {
	$RENDER_COUNT = $i;
	print "\$RENDER_COUNT = $RENDER_COUNT\n";
	cmpthese(-1, {
		TT        => \&template_toolkit,
		TC        => \&template_compiled,
		TC_NoSig  => \&template_compiled_nosig,
	});
	print "\n";
}

#######################################################################

use Types::Standard -types;
use Template::Compiled;
use Template;

# Standard Template::Compiled example.
#
sub template_compiled {
	my $template = Template::Compiled->new(
	  signature  => [
		 name => Str,
		 age  => Int->plus_coercions(Num, q{ int $_ }),
	  ],
	  template   => '<p>Hi <?= $name ?>. You are <?= $age ?> years old.</p>',
	  escape     => 'html',
	);
	my $sub = $template->sub;
	
	return $sub->(\%data)
		if $RENDER_COUNT == 1;
	
	$sub->(\%data)
		for 1 .. $RENDER_COUNT;
}

# Optimized Template::Compiled without signature.
#
sub template_compiled_nosig {
	my $template = Template::Compiled->new(
	  template   => '<p>Hi <?= $_{name} ?>. You are <?= int($_{age}) ?> years old.</p>',
	  escape     => 'html',
	);
	my $sub = $template->sub;
	
	return $sub->(\%data)
		if $RENDER_COUNT == 1;
	
	$sub->(\%data)
		for 1 .. $RENDER_COUNT;
}

# Template::Toolkit example.
#
sub template_toolkit {
	my $tt = Template->new;
	my $template = q{[% USE Math %]<p>Hi [% name|html %]. You are [% Math.int(age)|html %] years old.</p>};
	
	my $out = '';
	return $tt->process(\$template, \%data, \$out) && $out
		if $RENDER_COUNT == 1;
	
	$out = '' || $tt->process(\$template, \%data, \$out)
		for 1 .. $RENDER_COUNT;
}

#######################################################################

__END__
$RENDER_COUNT = 1
           Rate       TC       TT TC_NoSig
TC        509/s       --     -46%     -76%
TT        948/s      86%       --     -55%
TC_NoSig 2093/s     311%     121%       --

$RENDER_COUNT = 10
           Rate       TT       TC TC_NoSig
TT        112/s       --     -76%     -92%
TC        465/s     315%       --     -69%
TC_NoSig 1480/s    1220%     218%       --

$RENDER_COUNT = 100
           Rate       TT       TC TC_NoSig
TT       9.43/s       --     -96%     -98%
TC        250/s    2555%       --     -53%
TC_NoSig  527/s    5490%     111%       --
