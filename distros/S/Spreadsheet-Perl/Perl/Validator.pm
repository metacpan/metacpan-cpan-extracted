
package Spreadsheet::Perl ;

use 5.006 ;

use Carp ;
use strict ;
use warnings ;

require Exporter ;

our @ISA = qw(Exporter) ;

our %EXPORT_TAGS = 
	(
	#~ 'all' => [ qw(Validator AddValidator GenerateValidatorSub) ]
	'all' => []
	) ;

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;

our @EXPORT ;
push @EXPORT, qw( Validator AddValidator ) ;

our $VERSION = '0.01' ;

#-------------------------------------------------------------------------------

sub Validator
{
# Arguments must be: a name, a sub, an optional list of arguments
return bless [$_[0], GenerateValidatorSub(@_)], "Spreadsheet::Perl::Validator::Set" ;
}

#-------------------------------------------------------------------------------

sub AddValidator
{
# Arguments must be: a name, a sub, an optional list of arguments
return bless [$_[0], GenerateValidatorSub(@_)], "Spreadsheet::Perl::Validator::Add" ;
}

#-------------------------------------------------------------------------------

sub GenerateValidatorSub
{
my $name = shift ;
my $sub  = shift ;
my @args = @_ ;

if(defined($name) && ('' eq ref $name) && ($name ne ''))
	{
	}
else
	{
	confess "Validator error: No name given to this validator.\n" ;
	}
	
confess "Validator error: No validator sub.\n" unless(defined $sub && 'CODE' eq ref $sub) ;

return
	(
	sub
		{
		my $self = shift ;
		
		if($self->{DEBUG}{VALIDATOR})
			{
			my $dh = $self->{DEBUG}{ERROR_HANDLE} ;
			print $dh "Calling Validator '$name': " ;
			}
			
		my $value_is_valid = $sub->($self, @_, @args) ;
		
		if($self->{DEBUG}{VALIDATOR})
			{
			my $dh = $self->{DEBUG}{ERROR_HANDLE} ;
			
			if($value_is_valid)
				{
				print $dh "Valid.\n" ;
				}
			else
				{
				print $dh "Not valid\n" ;
				}
			}
		
		return($value_is_valid) ;
		}
	) ;
}

#-------------------------------------------------------------------------------

1 ;

__END__
=head1 NAME

Spreadsheet::Perl::Validator - Cell Validators

=head1 SYNOPSIS

  
=head1 DESCRIPTION

Part of Spreadsheet::Perl.

=head1 AUTHOR

Khemir Nadim ibn Hamouda. <nadim@khemir.net>

  Copyright (c) 2004 Nadim Ibn Hamouda el Khemir. All rights
  reserved.  This program is free software; you can redis-
  tribute it and/or modify it under the same terms as Perl
  itself.
  
If you find any value in this module, mail me!  All hints, tips, flames and wishes
are welcome at <nadim@khemir.net>.

=cut
