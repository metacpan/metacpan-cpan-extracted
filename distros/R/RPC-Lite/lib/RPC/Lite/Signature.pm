package RPC::Lite::Signature;

use strict;

=pod

=head1 NAME

RPC::Lite::Signature - Object representation of method signatures.

=head1 SYNOPSIS

  # create a signature for the method 'MethodName' that returns
  # an int and takes an int, an array and a struct as arguments.
  my $signature = 
    RPC::Lite::Signature->new( 'MethodName=int:int,array,struct' );
  
  # prints "MethodName=int:int,array,struct
  print $signature->AsString();
  
  # change the signature
  $signature->FromString( 'OtherMethod=array:int,struct' );

  # returns false after the update call to FromString above
  my $result = $signature->Matches( 'MethodName=int:int,array,struct' );

=head1 DESCRIPTION

  RPC::Lite::Signature is an object representation for method signatures.
For the most part, it should be used internally by RPC::Lite.

=over 12

=cut

sub new
{
  my $class = shift;
  my $data = shift;

  my $self = bless {}, $class;

  $self->FromString( $data );

  return $self;
}

=pod

=item C<MethodName>

Returns the method name the signature concerns.

=item C<ReturnType>

Returns a string specifying the return type.

=item C<ArgumentTypeList>

Returns an array reference to the list of argument types.

=cut

sub MethodName       { $_[0]->{methodname} = $_[1] if @_ > 1; $_[0]->{methodname} }
sub ReturnType       { $_[0]->{returntype} = $_[1] if @_ > 1; $_[0]->{returntype} }
sub ArgumentTypeList { $_[0]->{argumenttypelist} = $_[1] if @_ > 1; $_[0]->{argumenttypelist} }

=pod

=item C<AsString>

Returns a string representation of the signature.

=cut

sub AsString
{
  my $self = shift;

  return $self->MethodName . "=" . $self->ReturnType . ":" . join(',', @{$self->ArgumentTypeList});
}

=pod

=item C<FromString>

Takes a string and sets the signatures properties from that string.

=cut

sub FromString
{
  my $self = shift;
  my $data = shift;

  my ( $methodName, $returnType, $argumentTypeList ) = $self->__ParseString( $data );

  $self->MethodName( $methodName );
  $self->ReturnType( $returnType );
  $self->ArgumentTypeList( $argumentTypeList );

}

=pod

=item C<Matches>

Returns true if this signature matches the signature passed as an argument.
The argument can either be a string (a method specification) or another
RPC::Lite::Signature object.

=cut

sub Matches
{
  my $self = shift;
  my $otherSignature = shift;
  
  # string
  if ( !ref( $otherSignature ) )
  {
	my ( $otherMethodName, $otherMethodReturnType, $otherMethodArgumentTypeList ) = $self->__ParseString( $otherSignature );
  
	return 0 if ( $self->MethodName ne $otherMethodName );
  
	return 0 if ( $self->ReturnType ne $otherMethodReturnType );
  
	# make sure they take the same number of args
	return 0 if ( @{ $self->ArgumentTypeList() } != @$otherMethodArgumentTypeList );
  
	my $argumentIndex = 0;
	foreach my $argumentType ( @{ $otherMethodArgumentTypeList } )
	{
      return 0 if ( $argumentType ne $self->ArgumentTypeList()->[ $argumentIndex ] );
      ++$argumentIndex;
    }
  }
  elsif ( ref( $otherSignature ) eq 'RPC::Lite::Signature' )
  {
    return 0 if ( $self->MethodName() ne $otherSignature->MethodName() );
    
    return 0 if ( $self->ReturnType() ne $otherSignature->ReturnType() );
    
    return 0 if ( @{ $self->ArgumentTypeList() } != @{ $otherSignature->ArgumentTypeList() } );
    
	my $argumentIndex = 0;
	foreach my $argumentType ( @{ $self->ArgumentTypeList() } )
	{
      return 0 if ( $argumentType ne $otherSignature->ArgumentTypeList()->[ $argumentIndex ] );
      ++$argumentIndex;
    }
    
  }

  return 1;
}

sub __ParseString
{
  my $self = shift;
  my $string = shift;
  
  $string =~ s/\s+//g; # remove whitespace

  my ( $methodName, $returnType, $argumentTypeListString ) = $string =~ /^(.*?)=(.*?):(.*)$/;

  $returnType = lc( $returnType );
  $argumentTypeListString = lc( $argumentTypeListString );

  my @argumentTypeList = split( /,/, $argumentTypeListString );

  return ( $methodName, $returnType, \@argumentTypeList );
}

1;
