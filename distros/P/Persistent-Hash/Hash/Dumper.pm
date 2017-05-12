#!/usr/bin/perl
package Persistent::Hash::Dumper;

use strict;
use Carp;

use base qw(Data::Dumper);


sub _dump 
{
	my $s = shift;
	my ($val,$name) = @_;

  my($sname);
  my($out, $realpack, $realtype, $type, $ipad, $id, $blesspad);

  $type = ref $val;
  $out = "";


	if ($type) 
	{
    # prep it, if it looks like an object\
	 #XXX Modified here.
		if ($type !~ /^[A-Z]*$/) 
		{
      	my $freezer = $s->{freezer};
     		if ($freezer && UNIVERSAL::can($val, $freezer))
      	{
         	my $ret = $val->$freezer();
        		return $ret;
      	}
    	}
	}

	return $s->SUPER::_dump(@_);
}

666;
