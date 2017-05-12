package Script::Toolbox::Util::Opt;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Getopt::Long;
use IO::File;

require Exporter;

@ISA = qw(Exporter );
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
);
#$VERSION = '';


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

#------------------------------------------------------------------------------
# Create a new Opt object.
#------------------------------------------------------------------------------
sub new
{
	my $classname = shift;
	my $optDef	  = shift; # options definition
	my $caller	  = shift; # may be omited

	$optDef = {}	if( !defined $optDef );
	$optDef = {}	if( ref $optDef ne 'HASH' );
	$optDef = {}	if( scalar keys %{$optDef} == 0  );
	_addDefaultOptions( \$optDef );
	return	undef	if( _invalidOptDef( $optDef ));
	my $self = {};
	bless( $self, $classname );
	$self->_instCaller($caller);

	my $rc = $self->_init( $optDef, @_ );
	exit $rc if( $rc != 0 );

	return $self;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _invalidOptDef($)
{
	my ($optDef) = @_;

	foreach my $val ( values %{$optDef} )
	{
		return 1	if( ref $val ne 'HASH' );
		return 1	if( scalar keys %{$val} == 0 );
		foreach my $key ( keys %{$val} )
		{
			return 1 if( $key ne 'mod' 	&& $key ne 'desc'&&
						 $key ne 'mand'	&& $key ne 'default' );
		}
	}
	return 0;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _instCaller(@)
{
	my ($self, $call) = @_;

	my @caller = caller();
	$self->{'caller'} = defined $call ? $call : \@caller;
}

#------------------------------------------------------------------------------
# Get the options definition as input. Read the options from command line.
# Write usage message to STDERR if missing mandatory options.
#------------------------------------------------------------------------------
sub _init()
{
	my ( $self, $ops, $addUsage ) = @_;

	$self->{'opsDef'} 	= _normalize($ops);
	$self->{'addUsage'}	= defined $addUsage ? $addUsage :''; # additional usage text
	return $self->_processCmdLine();
}

#------------------------------------------------------------------------------
# Used for compatibility with old $ops format (array).
#------------------------------------------------------------------------------
sub _normalize($)
{
	my ($ops) = @_;

	return $ops		if( ref $ops eq 'HASH' );

	my %o;
	foreach my $old ( @{$ops} )
	{
		my $op = $old->{'op'};
		my $mod= $op;
		   $mod=~ s/^[^:=]+//;
		   $op =~ s/[:=].*$//;
		my %oo;
		$oo{'mod'}		= $mod				if( $mod ne '' );
		$oo{'desc'}		= $old->{'desc'}	if( defined $old->{'desc'});
		$oo{'mand'}		= $old->{'mand'}	if( defined $old->{'mand'});
		$oo{'default'}	= $old->{'default'}	if( defined $old->{'default'});

		$o{$op} = \%oo;
	}
	return \%o;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _addDefaultOptions
{
	my ($optDef) = @_;

	if( ! defined $$optDef->{'help'} )
	{
		$$optDef->{help} = {desc=>'Print online docu.'};
	}
}

#------------------------------------------------------------------------------
# Return the value of an option.
#------------------------------------------------------------------------------
sub get($)
{
	my ( $self, $key ) = @_;

	return $self->{$key};
}

#------------------------------------------------------------------------------
# Set the value of an option.
#------------------------------------------------------------------------------
sub set($)
{
	my ( $self, $key, $val ) = @_;

	my $old = $self->{$key};

	$self->{$key} = $val;

	return $old;
}

#------------------------------------------------------------------------------
# Read options from command line and start checking of the options.
# Exit with 1 if GetOptions found an internal error.
#------------------------------------------------------------------------------
sub _processCmdLine($)
{
	my ( $self ) = @_;
	my @opt = _mkOps( $self->{'opsDef'} );

	my $rc = GetOptions( $self, (@opt) );
	$self->usage(), exit 1  if( ! $rc );

    $rc = $self->_checkOps();
	return $rc;
}

#------------------------------------------------------------------------------
# Print usage message if missing any mandatory option and exit.
# Call perldoc of main programm if option -help is found.
# Exit with 2 if a mandatory option is missing.
#------------------------------------------------------------------------------
sub _checkOps($)
{
    my ( $self ) = @_;

	my $rc=0;
    my $errMsg;

	if( defined $self->{'help'} )
	{
		my $hasPerldoc = system("type perldoc >/dev/null 2>&1") / 256;
		my $hasNroff   = system("type nroff   >/dev/null 2>&1") / 256;
		if( $hasPerldoc == 0 && $hasNroff == 0 )
		{
			my $fh = new IO::File "perldoc $0 |";
			while( <$fh> ) { print STDERR $_; }
			$rc = 1;
		}else{
			$errMsg .= "Can't display online manual. Missing nroff and/or perldoc.\n";
		}
	}

    foreach ( keys %{$self->{'opsDef'}} )
    {
        $errMsg .= "Missing mandatory option '$_'.\n"
            if( ! $self->setDefaults( $_ ));
    }

    if( defined $errMsg )
    {
        print STDERR $errMsg;
        $self->usage();
        $rc = 2;
    }
	return $rc;
}

#------------------------------------------------------------------------------
# Set option to default value if option is missing and default value defined.
# Return 0 if option is mandatory, not set on comand line and no default value 
# available. Otherwise return 1;
#------------------------------------------------------------------------------
sub setDefaults($$)
{
	my ($self, $opt) = @_;

	# We are happy, found the option on command line
	return 1	if( defined $self->{$opt} );

	# Nothing to do, option not found on command line but not mandatory 
	return 1	if(! $self->{'opsDef'}{$opt}{'mand'} );

	# WOW!! We found an error!
	# Option not on comand line, mandatory and no default defined
	return 0	if(!defined $self->{'opsDef'}{$opt}{'default'} &&
							$self->{'opsDef'}{$opt}{'mand'}  );

	# Option not on comand line, mandatory and default defined
	# -> so we can use the default value
	$self->{$opt} = $self->{'opsDef'}{$opt}{'default'};
	return 1;


}

#------------------------------------------------------------------------------
# Print an usage message to STDERR.
#------------------------------------------------------------------------------
sub usage($$)
{
	my ( $self, $addMsg ) = @_;

	my $call = $self->{'caller'}->[1];
	   $call =~ s/^.*\///;

	my $cols = _getCols(); my $col2 = $cols/2-6;
	printf STDERR "\nUsage: %s <Options> %s\n%s %s %s\n",
					$call,
					$self->{'addUsage'},
					'-' x $col2, 'Options', '-' x $col2;

	my ($form, $max) = _calcForm( $self->{'opsDef'} );

	foreach my $key ( sort keys %{$self->{'opsDef'}} )
	{
		my $val = $self->{'opsDef'}{$key};
		printf STDERR "$form\n", _getOpDesc( $val, $max, $cols );
	}
	printf STDERR "%s\n%s\n", '-' x ($cols-3),
					defined $addMsg ? "$addMsg\n" : "\n";
}

#-----------------------------------------------------------------------------
# Compute the number of columns of then contoling terminal.
#-----------------------------------------------------------------------------
sub _getCols
{
	my $line = `stty -a 2>/dev/null`;
	   return 80	if( !defined $line );
	   $line =~ /(.*columns[^0-9]+)([0-9]+)/;
	   return defined $2 ? $2 : 80;
}

#------------------------------------------------------------------------------
# Calculate format template for usage message.
#------------------------------------------------------------------------------
sub _calcForm($)
{
	my ( $ops ) = @_;

	_prepUsage( $ops );
	my ($form, $max) = ( '', 0 );
	foreach my $op ( values %{$ops} )
	{
		my $ln = length $op->{'usage'};
		my $ad = _optionaly($op) ? 2 : 0;

		$max = $ln+$ad > $max ? $ln+$ad : $max;
	}

	$form = "%${max}s - %s";
	return ($form, $max+3);
}

#------------------------------------------------------------------------------
# Prepare usage message using [] for optional options and <> for input values.
#------------------------------------------------------------------------------
sub _prepUsage($)
{
	my ( $ops ) = @_;

	foreach my $op ( keys %{$ops} )
	{
		my $o = $ops->{$op}{'mod'};
		   $o = ''	if( !defined $o );
		   $o =~ s/=s.*/ <name>/;
		   $o =~ s/:s.*/ [<name>]/;
		   $o =~ s/=i.*/ <number>/;
		   $o =~ s/:i.*/ [<number>]/;
		   $o =~ s/=f.*/ <float>/;
		   $o =~ s/:f.*/ [<float>]/;

		$ops->{$op}{'usage'} = "-$op$o";
	}
}
#------------------------------------------------------------------------------
# Build the description of an option.
#------------------------------------------------------------------------------
sub _getOpDesc($)
{
	my ( $op, $max, $cols ) = @_;

	my $rc;
	if( _optionaly($op) )
	{
		$rc = '[' . $op->{'usage'} . ']';
	}else{
		$rc = $op->{'usage'};
	}
	my $desc = _insertNL( $op,  $max, $cols );
	return ( $rc, $desc );
}
#-----------------------------------------------------------------------------
#  Return false if the option is madatory and has no default value.
#  Return true otherwise.
#-----------------------------------------------------------------------------
sub _optionaly($)
{
    my ($op) = @_;

    if( defined $op->{'mand'})
    {
        return 1 if( ! $op->{'mand'} );
        return 0 if( ! defined $op->{'default'} );
    }
    return 1
}


#-----------------------------------------------------------------------------
# Fold line into two lines if line length exceeds number of columns .
#-----------------------------------------------------------------------------
sub _insertNL
{
	my ($op, $max, $cols) = @_;

	my $l='';
	my $line='';
	$op->{'desc'} = '--no description--'	if( !defined $op->{'desc'} );

	foreach my $x ( split /\s+/, $op->{'desc'} )
	{
		if( length($l) + length($x) + $max >= $cols )
		{
			$line .= sprintf "%s\n%s", $l, ' ' x $max;
			$l = '';
		}
		$l .= "$x ";
	}
	$line .= $l;
	$line .= sprintf "\n%s(default=%s)", ' ' x $max,$op->{'default'}
											if( defined $op->{'default'} );
	return $line;
}

#------------------------------------------------------------------------------
# Prepare the option hash for Getopt::Long::GetOptions().
#------------------------------------------------------------------------------
sub _mkOps()
{
	my ( $ops ) = @_;
	my @OPS;

	my $mod;
	foreach my $opt ( keys %{$ops} )
	{
		$mod = defined $ops->{$opt}{'mod'} ? $ops->{$opt}{'mod'} : '';
		push @OPS, $opt . $mod;
	}
	return @OPS;
}
##############################################################################
1;
__END__

=head1 NAME

Script::Toolbox::Util::Opt - see documentaion of Script::Toolbox

=cut
