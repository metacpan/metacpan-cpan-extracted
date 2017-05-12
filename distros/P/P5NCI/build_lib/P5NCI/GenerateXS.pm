package P5NCI::Sig;

sub new
{
	my ($class, %args) = @_;
	bless \%args, $class;
}

for my $accessor (qw( c_type type ))
{
	no strict 'refs';
	*{ $accessor } = sub { $_[0]->{$accessor} };
}

package P5NCI::GenerateXS;

use strict;
use warnings;

sub generate_xs
{
	my $out_file = shift;
	die "Usage: $0 <output_file.xs>\n" unless @_;

	open( my $out, '>', $out_file ) or die "Can't write $out_file: $!\n";

	write_header( $out );
	write_thunks( $out );
}

sub type_args
{
	return
	{
		d => P5NCI::Sig->new( type => 'd', c_type => 'double' ),
		i => P5NCI::Sig->new( type => 'i', c_type => 'int'    ),
		f => P5NCI::Sig->new( type => 'f', c_type => 'float'  ),
		p => P5NCI::Sig->new( type => 'p', c_type => 'void *' ),
		s => P5NCI::Sig->new( type => 's', c_type => 'short'  ),
		t => P5NCI::Sig->new( type => 't', c_type => 'char *' ),
		v => P5NCI::Sig->new( type => 'v', c_type => 'void'   ),
	};
};

sub write_thunks
{
	my $out = shift;

	my $args        = type_args();
	my $combination = generate_combinations( keys %$args );

	while (my $combo = $combination->())
	{
		# void makes no sense as anything other than return value or all args
		next if index( $combo, 'v', 2 ) > 0;

		my ($return, @args) = map { $args->{ $_ } } split('', $combo);
		my $func            = generate_function( "nci_$combo", $return, @args );
		print $out "\n", $func;
	}
}

sub generate_combinations
{
	my @possibilities = @_;

	return generate_iterator( 2, 4, \@possibilities );
}

sub generate_iterator
{
	my ($from, $to, $items) = @_;
	my @prefix              = (0) x $from;

	return sub
	{
		return if @prefix > $to;
		my $ret = join( '', map { $items->[ $_ ] } @prefix );

		# increment counter rightward
		my $i = 0;
		while ( ++$prefix[$i] > $#{ $items } )
		{
			$prefix[$i] = 0;
			$i++;
			if ( $i == @prefix )
			{
				@prefix = ( ( 0 ) x ( @prefix + 1 ) );
				last;
			}
		}

		return $ret;
	};
}

sub generate_function
{
	my ($signature, $return, @types) = @_;
	my $function = <<END_HERE;
%s
%s( c_func%s )
	SV* c_func
%sPREINIT:
	%s(*func)(%s);
CODE:
	func   = INT2PTR(%s(*)(%s), SvIV(c_func) );
END_HERE

	if ($return->type() eq 'v')
	{
		$function .= "\t(*func)(%s);\n";
	}
	else
	{
		$function .= <<END_HERE;
	RETVAL = (*func)(%s);
OUTPUT:
	RETVAL
END_HERE
	}

	my ($siglist, $insiglist, $arglist, $typelist) = get_type_lists( @types );
	return sprintf( $function, $return->c_type, $signature, $insiglist,
		$arglist, $return->c_type(), $typelist, $return->c_type(), $typelist,
		$siglist );
}

sub get_type_lists
{
	my (@siglist, @arglist, @typelist);

	if ($_[0]->type() eq 'v')
	{
		return ( '' ) x 3, ' ';
	}

	for my $type (@_)
	{
		my $var_name = $type->type() . @siglist;
		push @siglist, $var_name;
		push @typelist, $type->c_type();
		last if $type->type() eq 'v';
		push @arglist, "\t" . $type->c_type() . ' ' . $var_name;
	}

	my $siglist   = join( ', ', @siglist  );
	my $insiglist = ", $siglist";
	my $arglist   = join( "\n", @arglist, ''  );
	my $typelist  = join( ', ', @typelist );

	return ( $siglist, $insiglist, $arglist, $typelist );
}

sub write_header
{
	my $out = shift;

	print $out <<END_HERE;
#include "EXTERN.h"
#include "XSUB.h"
#include "perl.h"
#ifdef PERL_UNUSED_DECL
    #undef PERL_UNUSED_DECL
#endif
#include "ppport.h"

#ifdef newXS
	#undef newXS
	#define newXS ;
#endif

MODULE = P5NCI  PACKAGE = P5NCI
END_HERE
}

1;
