package Script::Toolbox::Util::Formatter;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
#use Script::Toolbox::Util qw(Log);

require Exporter;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
#$VERSION = '0.03';


# Preloaded methods go here.

#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
sub new
{
	my $classname = shift;
	my $self      = {};
	bless( $self, $classname );
	$self->_init( @_ );
	return $self;
}

#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
sub _init
{
	my ($self, $container) = @_;

	$self->{'title'}= defined $container->{'title'} ?
	                          $container->{'title'} :
						     'Title';

	if( ref $container->{'data'} eq 'ARRAY' ) {
		$self->_initHashArray ( $container ) if( ref $container->{'data'}[0] eq 'HASH' );
		$self->_initArray     ( $container ) if( ref $container->{'data'}[0] eq 'ARRAY');
	}

	if( ref $container->{'data'} eq 'HASH' ) {
		$self->_initHashHash  ( $container ) if( ref $container->{'data'}    eq 'HASH' );
	}

	$self->{'head'} = defined $container->{'head'} ?
	                          $container->{'head'} :
						      _getDefaultHeader($container);


}

#------------------------------------------------------------------------------
# Extract column keys from first data row.
# 'data'  => {
#              key1 => {F1=>'aaa', F2=>'bb   ', F3=>3}
#              key2 => {F1=>11111, F2=>2222222, F3=>3}
#            }
#------------------------------------------------------------------------------
sub _getHeadsFromFirstRow($)
{
	my ($data) = @_;
	my @H;
	push( @H, "KEY" );
	foreach my $d ( values %{$data} )
	{
		map{ push( @H, $_ ) } sort keys %{$d};
		last;
	}
	#return \@H;
	return @H;
}

#------------------------------------------------------------------------------
# 'title'  => 'Test1',
# 'head'  => ['RowKey', Field1', 'Field2', 'Field3'],
# 'data'  => {
#              key1 => {F1=>'aaa', F2=>'bb   ', F3=>3}
#              key2 => {F1=>11111, F2=>2222222, F3=>3}
#            }
#------------------------------------------------------------------------------
sub _initHashHash($$)
{
	my ($self,$container) = @_;

	if( ref $container->{'data'} eq 'HASH' )
	{
		@{$self->{'head'}} = _getHeadsFromFirstRow( $container->{'data'} );
		my @D;
		foreach my $lk ( sort keys %{$container->{'data'}} )
		{
			my $l = $container->{'data'}{$lk};
			my @L;
			foreach my $k ( @{$self->{'head'}} )
			{
				# auto generated meta column
				if( $k eq 'KEY' ) { push @L,$lk; next }

				$self->_logit( $k, $l )	if( !defined $l->{$k} );
				push @L, $l->{$k};
			}
			push @D, \@L;
		}
		$self->{data} = \@D;
	}
}

#------------------------------------------------------------------------------
# 'title'  => 'Test1',
# 'head'  => ['Feld1', 'Feld2', 'Feld3'],
# 'data'  => [
#             [ 'aaa', 'bb          ', 'cc  ' ],
#             [ 11111, 2222222, 3 ]
#            ]
# OR data part
# 'data'  => [
#              {F1=>'aaa', F2=>'bb   ', F3=>3}
#              {F1=>11111, F2=>2222222, F3=>3}
#            ]
#------------------------------------------------------------------------------
sub _initHashArray($$)
{
	my ($self,$container) = @_;
	$self->{'data'}  = $self->_getData($container);
}

#------------------------------------------------------------------------------
#  [
#   'title',
#   ['COL-HEAD','COL-HEAD2','COL-HEAD3'],
#   [1,      2,     3],
#   [4,      5,     6],
#  ]
# OR:
#  [
#   [1,      2,     3],
#   [4,      5,     6],
#  ]
# OR:
# 'data'  => [
#              {F1=>'aaa', F2=>'bb   ', F3=>3}
#              {F1=>11111, F2=>2222222, F3=>3}
#            ]
#------------------------------------------------------------------------------
sub _initArray($$)
{
	my ($self,$container) = @_;

	$self->{'data'}  = $container->{'data'};
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _getData($$)
{
	my ($self, $container) = @_;

	return  []	if( !defined $container->{'data'}[0] );
	return $container	if( ref($container->{'data'}[0]) eq 'ARRAY' );
	if( ref($container->{'data'}[0]) eq 'HASH' )
	{
		@{$self->{'head'}} = sort keys %{$container->{'data'}[0]};
		my @D;
		foreach my $l ( @{$container->{'data'}} )
		{
			my @L;
			foreach my $k ( @{$self->{'head'}} )
			{
				$self->_logit( $k, $l )	if( !defined $l->{$k} );
				push @L, $l->{$k};
			}
			push @D, \@L;
		}
		return \@D;
	}
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _logit($$)
{
	my ($self,$k,$line) = @_;

	print STDERR 
	"Warning: inconsistent data hash, missing key $k in line: " . 
		 join ";", each %{$line};
}
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _getDefaultHeader($)
{
	my ($cont) = @_;
	my @hd;

	if( ref $cont->{'data'} eq 'ARRAY' ) {
		 if( ref $cont->{'data'}[0] eq 'HASH' ) {
			 foreach my $h ( sort keys %{$cont->{'data'}[0]} ) { push @hd, $h; }
		 }
		 if( ref $cont->{'data'}[0] eq 'ARRAY') {
			 for( my $i=0; $i <= $#{$cont->{'data'}[0]}; $i++ ) { push @hd, "Col-$i"; }
		 }
	}

	# 'data'  => {
	# 'line1' => { 'F1' => 'aaaa', 'F2' => 'bbb   ', 'F3' => 'c' },
	# 'line2' => { 'F1' => 'dddd', 'F2' => 'eee   ', 'F3' => 'f' }
	# }
	if( ref $cont->{'data'} eq 'HASH' ) {
		foreach my $line ( values %{$cont->{'data'}} )
		{
			push @hd, "KEY";
			foreach my $fldName ( sort keys %{$line} )
			{
				push @hd, $fldName;
			}
			last;
		}
	}

	return \@hd;
}

#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
sub matrix
{
	my ($self) = @_;
	return  []	if( !defined $self->{'data'} );
	return  []	if( scalar @{$self->{'data'}} == 0 );

	my @result;
	$self->_matrix( \@result );
	return \@result ;
}

#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
sub _matrix
{
	my ($self, $result) = @_;

	my @maxColW = $self->_maxColWidth();
	my $format  = $self->_getFormat( \@maxColW );
	my $formatHd= $format;
	   $formatHd=~ s/([.]\d*)?[df]/s/g;

	push @{$result}, sprintf "== %s ==", $self->{'title'};
	push @{$result}, sprintf $formatHd, @{$self->{'head'}};
	push @{$result}, _underline( @maxColW );

	map { push @{$result},
				sprintf $format, _getLineArray($_); } @{$self->{'data'}};
}

#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
sub _underline
{
	my (@maxColWidth) = @_;

	my $x;
	map { $_ =~s/([.]\d+)?[fds]$//;
		  $_ =~s/-//;
		  $x .= sprintf "%s ", '-' x $_ }	@maxColWidth;

	$x =~ s/\s$//;
	return $x;
}
#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
sub _getLineArray
{
	my ($line) = @_;

	return @{$line}		if( ref $line eq 'ARRAY' );

	if( ref $line eq 'HASH' )
	{
		my @R;
		foreach my $key ( sort keys %{$line} ) {
			push @R, ${$line}{$key};
		}
		return @R;
	}
}

#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
sub _getFormat
{
	my ($self, $maxColWidth ) = @_;

	my $form='';
	_mkFloatLen( $maxColWidth );
	foreach my $f ( @{$maxColWidth} )
	{
		$f = '-' . $f			if( $f =~ /s$/ );
		$form .= sprintf "%%%s ", $f;
	}
	$form =~ s/\s$//;
	return $form;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _mkFloatLen($)
{
	my ($maxColRef) = @_;

	for( my $i=@{$maxColRef}-1; $i >= 0; $i-- )
	{
		if( ${$maxColRef}[$i] =~ /(\d+)[.](\d+)f$/ )
		{
			my $len = $1;
			my $dig = $2;
			${$maxColRef}[$i] = $len+$dig+1 .'.'. $dig .'f';
		}
	}
}

#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
sub _maxColWidth
{
	my ($self) = @_;
	my @maxColWidth;

	my @X;
	push @X, $self->{'head'};
	map { push @X, $_ }	@{$self->{'data'}};
	my $i=0;
	foreach my $line ( @X )
	{
		next	if( $i++ == 0 );
		_maxColHashLine( $line, \@maxColWidth ) if( ref $line eq 'HASH' );
		_maxColArrayLine($line, \@maxColWidth ) if( ref $line eq 'ARRAY');
	}
	_checkMaxHeader( $X[0],  \@maxColWidth );
	return @maxColWidth;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _checkMaxHeader($$)
{
	my ($line, $maxColWidth) = @_;

	for( my $i=0; $i<= $#{$line}; $i++ )
	{
		_trimBlanks( \${$line}[$i] );
		${$maxColWidth}[$i] = _getMaxColWidthHead(${$maxColWidth}[$i],
												  ${$line}[$i] );
	}
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _getMaxColWidthHead($$)
{
	my ($old,$new) = @_;

	my $nl= length( $new );
	$old =~ /(\d+)[.]?(\d*)([fds])/; my ($ol,$od, $ot) = ($1,$2,$3);

	return stringType($nl,$ol)			if($ot eq 's' );
	return floatType($nl,0,$ol,$od)		if($ot eq 'f');
	return intType($nl,$ol)				if($ot eq 'd' );

	printf STDERR "ERROR format\n";
	return 0;
}


#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
sub _maxColArrayLine
{
	my ($line, $maxColWidth) = @_;
	for( my $i=0; $i<= $#{$line}; $i++ )
	{
		_trimBlanks( \${$line}[$i] );
		my $type= _getTypeLen( ${$line}[$i] );
		${$maxColWidth}[$i] = _getMaxColWidth(${$maxColWidth}[$i], $type);
	}
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _getMaxColWidth($$)
{
	my ($old,$new) = @_;

	$new =~ /(\d+)[.]?(\d*)([fds])/; my ($nl,$nd, $nt) = ($1,$2,$3);
	$old = $new	if( !defined $old );
	$old =~ /(\d+)[.]?(\d*)([fds])/; my ($ol,$od, $ot) = ($1,$2,$3);

	return stringType($nl,$ol)			if($nt eq 's' || $ot eq 's' );
	return floatType($nl,$nd,$ol,$od)	if($nt eq 'f' || $ot eq 'f');
	return intType($nl,$ol)				if($nt eq 'd' && $ot eq 'd' );

	printf STDERR "ERROR format\n";
	return 0;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub intType($$)
{
	my ($nl,$ol) = @_;
	my $len = $nl > $ol ? $nl : $ol;
	return $len . 'd';
}
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub floatType($$$$$$)
{
	my ($nl,$nd,$ol,$od) = @_;
	$nl = $nl eq '' ? 0 : $nl;
	$nd = $nd eq '' ? 0 : $nd;
	$od = $od eq '' ? 0 : $od;
	$ol = $ol eq '' ? 0 : $ol;
	my $len = $nl > $ol ? $nl : $ol;
	my $dig = $nd > $od ? $nd : $od;

	return	$len	.'.'.	$dig	.'f';
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub stringType($$)
{
	my ($nl,$ol) = @_;
	my $len = $nl > $ol ? $nl : $ol;

	return	$len .'s';
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _getTypeLen($)
{
	my ($field) = @_;

	my $type;
	$type = _isFloat($field); return $type	if( defined $type );
	$type = _isInt($field);	  return $type	if( defined $type );

	return	length($field) .'s';
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _isInt($)
{
	my ($field) = @_;
	return  undef   if( $field !~ /^[-]?\d+$/ );
	return	length($field) .'d';
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _isFloat($)
{
	my ($field) = @_;
	return	undef	if( $field !~ /^[-]?(\d+)[.](\d*)$/ );

	my $int = $1; my $li = length($int);
	my $frac= $2; my $lf = length($frac);

	my $form= $li+$lf+1 .'.'. $lf .'f';

	return $form;
}
#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
sub _maxColHashLine
{
	my ($line, $maxColWidth) = @_;
	my $i=0;
	foreach my $key ( sort keys %{$line} )
	{
		_trimBlanks( \${$line}{$key} );
		my $type= _getTypeLen( ${$line}{$key} );
		${$maxColWidth}[$i] = _getMaxColWidth(${$maxColWidth}[$i], $type);
		$i++;
	}
}
#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
sub _trimBlanks
{
	my ($field) = @_;

	$$field =~ s/^\s+//;
	$$field =~ s/\s+$//;

	return length( $$field  );
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub sumBy()
{
    my ($self, $raw, $colIdxRef, $notGroupBy) = @_;
	my $colIdx = $colIdxRef->[0];	#FIXME may be more than one colum in future

    my @LEN = _getColLen(    $raw->[2] );
	my $fmt = _getSumFormat( $raw->[3],$colIdx,@LEN );
	my $pattern = _getSplitPattern(@LEN);
    my $sum = 0;
	my $gSum= _getSumField( $raw->[3],$pattern, $colIdx );

    my $old = $raw->[3];
	my @NEW = @{$raw}[0..3];

    for( my $i=4; $i <= $#{$raw}; $i++ )
    {
		push @NEW, _endGroup(\$gSum,$fmt,\$sum)
					if( _isGroupEnd($raw,$i,$colIdx,$pattern,$notGroupBy));
		$gSum +=  _getSumField( $raw->[$i],$pattern, $colIdx );
		push @NEW, $raw->[$i];
    }
	push @NEW, sprintf $fmt, $gSum;
	push @NEW, sprintf $fmt, $sum;
    return \@NEW;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _endGroup($$)
{
	my ($sumRef, $fmt, $totSumRef) = @_;
	
	my $line = sprintf $fmt, $$sumRef;
	$$totSumRef += $$sumRef;
	$$sumRef = 0;

	return $line;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _isGroupEnd($$$$)
{
	my ($raw,$currIdx,$colIdx,$pattern,$notGroupBy) = @_;

	my @PREV = _getSplitedLine($raw->[$currIdx-1],$pattern);
	my @CURR = _getSplitedLine($raw->[$currIdx],  $pattern);
	for( my $i=0; $i <= $#CURR; $i++ )
	{
		next	if( _noGroupCol($i,$colIdx,$notGroupBy) );
		return 1	if( $PREV[$i] ne $CURR[$i] );
	}
	return 0;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _noGroupCol($$$)
{
	my ($idx,$sumIdx,$notGroupBy) = @_;

	return 1	if( $idx == $sumIdx );
	return 0	if( !defined $notGroupBy );

	foreach my $col ( @{$notGroupBy} ) { return 1 if( $col == $idx ); }
	return 0;
}
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _getSumField($$$)
{
	my ($line,$pattern,$idx) = @_;

	my @L = _getSplitedLine($line,$pattern);
	return $L[$idx];
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _getSumFormat($$@)
{
	my ($line, $colIdx, @LEN) = @_;

	my $form='';
	for( my $i=0; $i <= $#LEN; $i++ )
	{
		if( $i == $colIdx ) { $form .= _getSumColForm($line, $colIdx, @LEN); }
		else				{ $form .= sprintf "%s ", ' ' x $LEN[$i]; 	  }
	}
	return $form;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _getSumColForm($$@)
{
	my ($line, $colIdx, @LEN) = @_;

	my $pattern = _getSplitPattern(@LEN);
	my @splited = _getSplitedLine($line,$pattern);
	my $sumField= $splited[$colIdx];
	my @I 		= $sumField =~ /(\d+)([.]?)(\d*)/;
	my $decimal	= $I[2];

	return '%'. $LEN[$colIdx] .
		   '.'. length($decimal) .'f' 	if( $I[1] eq '.' );

	return '%'. $LEN[$colIdx] .'d';
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _getSplitedLine($$)
{
	my ($line,$pattern) = @_;
	return	$line =~ m/$pattern/;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _getSplitPattern(@)
{
	my (@LEN) = @_;

	return	join ' ', map { '(.{'. $_ .'})' } @LEN;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _getColLen
{
	my ($cols) = @_;

	my @len;
	foreach my $col ( split /\s+/, $cols )
	{
		push @len, length $col;
	}
	return @len;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub newGroup($$$)
{
    my ($O, $L, $idx) = @_;

    foreach my $i ( @{$idx} )
    {
        return 1    if( $O->[$i] ne $L->[$i] );
    }
    return 0;
}

1;
__END__

=head1 NAME

Script::Toolbox::Util::Formatter - see documentaion of Script::Toolbox

=cut

