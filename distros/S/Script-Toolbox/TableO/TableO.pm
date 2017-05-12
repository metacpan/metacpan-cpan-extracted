package Script::Toolbox::TableO;
# vim: ts=4 sw=4 ai

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

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
	my ($self, $param, $separator) = @_;

	return undef	if( _noData( $param ) );
	my $para  = _normParam($param, $separator);

	my $form  = Script::Toolbox::Util::Formatter->new( $para );
	my $result= $form->matrix();
	if( ref $param eq 'ARRAY' || !defined $param->{'sumCols'} ){
        $self->{'result'} = $result;
    }else{
	    $self->{'result'} = $form->sumBy($result, $param->{'sumCols'},
                                                  $param->{'notGroupBy'});
    }
}

#------------------------------------------------------------------------------
# $param must be a hash reference. This Hash must have a key "data".
# This key may point to:
# 		arrayref 
# 		hashref
#------------------------------------------------------------------------------
sub _noData($)
{
	my ($param) = @_;

	return 0 if( ref $param ne 'HASH' );
	return 0 if( ref $param->{'data'} eq 'HASH' );
	return 0 if( ref $param->{'data'} eq 'ARRAY');

	if( !defined $param->{'data'}[0] )
	{
	    Log( "WARNING: no input data for Table()." );
	    return 1;
	}
	return 0;
}

#------------------------------------------------------------------------------
# Valid Calls:
#	[ "csvString", "csvString",...], 				 undef
#	[ "csvString", "csvString",...], 				 separatorString
#	[ "TitelString", [headArray], [dataArray],...],  undef
#	[ [dataArray],...],  							 undef
#	{title=>"", head=>[], data=>[[],[],...] },		 undef
#	{title=>"", head=>[], data=>[{},{},...] },		 undef
#	{title=>"", head=>[], data=>{r1=>{c1=>,c2=>,},r2=>{c1=>,c2=>,},}, undef
#------------------------------------------------------------------------------
sub _normParam($$)
{
	my ($param, $separator) = @_;

	if( ref $param eq 'HASH' )
	{
	    # keine Ahnung wozu: return _sepHash($param, $separator)	if( _isCSV($param->{'data'}) );
	    return $param;
	}
	return _sepTitleHead($param)		if( _isTitleHead($param) );
	return _sepCSV($param, $separator) 	if( _isCSV($param, $separator) );
	return { 'data' => $param };
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _sepHash($$)
{
	my ($param,$separator) = @_;

	my $d = _sepCSV($param->{'data'}, $separator);
	$param->{'data'} = $d->{'data'};
	return $param;
}

# ------------------------------------------------------------------------------
# Check if we found the special data array format.
# ["TitleString", [headString,headString,...],[data,...],...]
#------------------------------------------------------------------------------
sub _isTitleHead($)
{
	my ($param) = @_;

	return 1	if( ref \$param->[0] eq 'SCALAR' && ref $param->[1] eq 'ARRAY' );
	return 0;
}

#------------------------------------------------------------------------------
# Transform the special data array
# ["TitleString", [headString,headString,...],[data,...],...]
# into hash format. 
#------------------------------------------------------------------------------
sub _sepTitleHead($)
{
	my ($param) = @_;

	my $title= splice @{$param}, 0,1;
	my $head = splice @{$param}, 0,1;

	return	{
		'title'	=> $title,
		'head'	=> $head,
		'data'	=> $param
		};
}


#------------------------------------------------------------------------------
#	[[],[],...]
#	[{},{},...]
#	{r1=>{c1=>,c2=>,},r2=>{c1=>,c2=>,},}
#------------------------------------------------------------------------------
sub _isCSV($$)
{
	my ($param, $separator) = @_;

	return 0	if( ref  $param      ne 'ARRAY' );

	$separator = ';'	unless defined $separator; #FIXME default sep
	return 1    if( $param->[0] =~ /$separator/ ); #assume it's a CSV record
	return 0;
}

#------------------------------------------------------------------------------
# Convert an array of CSV strings into an array of arrays.
#
# [ "a;b","c,d"] becomes
# [[a,b], [c,d]]
#------------------------------------------------------------------------------
sub _sepCSV($$)
{
	my ($param, $separator) = @_;

	$separator = ';'	if( !defined $separator);
	my @R;
	foreach my $l ( @{$param} )
	{
	    my @r = split /$separator/, $l;
	    push @R, \@r;
	}

	return { 'data' => \@R };
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub asArray($){
    my ($self) = @_;

    return @{$self->{'result'}};
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub asString($$){
    my ($self,$sep) = @_;

    $sep = defined $sep ? $sep : "\n";
    return sprintf "%s", join $sep, @{$self->{'result'}};
}

1;
__END__

=head1 NAME

Script::Toolbox::TableO - see documentaion of Script::Toolbox

=cut
