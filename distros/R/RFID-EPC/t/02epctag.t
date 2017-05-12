#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use RFID::EPC::Tag;

use Data::Dumper;

my @testtags = (
		{ 
		    epc_type => 'GID-96',
		    epc_manager => '7777777',
		    epc_class => '666666',
		    epc_serial => '999999999',
		},
		{ 
		    epc_type => 'SGTIN-64',
		    epc_filter => '7',
		    epc_company => '3fff',
		    epc_item => 'aaaaa',
		    epc_serial => '1abcdef'
		},
		{ 
		    epc_type => 'SGTIN-96',
		    epc_filter => '7',
		    epc_partition => '0',
		    epc_company => 'AAAAAAAAAA',
		    epc_item => '1',
		    epc_serial => '3FFFFFFFFF'
		},		
		{
		    epc_type => 'SGTIN-96',
		    epc_filter => '7',
		    epc_partition => '1',
		    epc_company => '1fffffffff',
		    epc_item => '01',
		    epc_serial => '3FFFFFFFFF'
		},	
		{
		    epc_type => 'SGTIN-96',
		    epc_filter => '7',
		    epc_partition => '2',
		    epc_company => '3ffffffff',
		    epc_item => '001',
		    epc_serial => '3FFFFFFFFF'
		},	
		{
		    epc_type => 'SGTIN-96',
		    epc_filter => '7',
		    epc_partition => '3',
		    epc_company => '3fffffff',
		    epc_item => '0001',
		    epc_serial => '3FFFFFFFFF'
		},	
		{
		    epc_type => 'SGTIN-96',
		    epc_filter => '7',
		    epc_partition => '4',
		    epc_company => '7ffffff',
		    epc_item => '00001',
		    epc_serial => '3FFFFFFFFF'
		},	
		{
		    epc_type => 'SGTIN-96',
		    epc_filter => '7',
		    epc_partition => '5',
		    epc_company => 'ffffff',
		    epc_item => '00001',
		    epc_serial => '3FFFFFFFFF'
		},	
		{
		    epc_type => 'SGTIN-96',
		    epc_filter => '7',
		    epc_partition => '6',
		    epc_company => 'fffff',
		    epc_item => '000001',
		    epc_serial => '3FFFFFFFFF'
		},	
		{
		    epc_type => 'SSCC-64',
		    epc_filter => '7',
		    epc_company => '3fff',
		    epc_serial => '7000000000',
		},
		{ 
		    epc_type => 'SSCC-96',
		    epc_filter => '7',
		    epc_partition => '0',
		    epc_company => 'FFFFFFFFFF',
		    epc_serial => '00001',
		},		
		{
		    epc_type => 'SSCC-96',
		    epc_filter => '7',
		    epc_partition => '6',
		    epc_company => 'fffff',
		    epc_serial => '0000000001',
		},	
		{ 
		    epc_type => 'GRAI-64',
		    epc_filter => '7',
		    epc_company => '3fff',
		    epc_asset_type => 'aaaaa',
		    epc_serial => '00001'
		},
		{ 
		    epc_type => 'GRAI-96',
		    epc_filter => '7',
		    epc_partition => '0',
		    epc_company => 'AAAAAAAAAA',
		    epc_asset_type => '1',
		    epc_serial => '3FFFFFFFFF'
		},		
		{
		    epc_type => 'GRAI-96',
		    epc_filter => '7',
		    epc_partition => '6',
		    epc_company => 'fffff',
		    epc_asset_type => '000001',
		    epc_serial => '3FFFFFFFFF'
		},	
 		{
		    epc_type => 'SGLN-64',
		    epc_filter => '7',
		    epc_company => '3fff',
		    epc_location => '00000',
		    epc_serial => '7ffff'
		},	
		{ 
		    epc_type => 'SGLN-96',
		    epc_filter => '7',
		    epc_partition => '0',
		    epc_company => 'ffffffffff',
		    epc_location => '1',
		    epc_serial => '123456789ab'
		},		
		{
		    epc_type => 'SGLN-96',
		    epc_filter => '7',
		    epc_partition => '6',
		    epc_company => 'fffff',
		    epc_location => '000001',
		    epc_serial => '123456789AB'
		},	
 		{
		    epc_type => 'GIAI-64',
		    epc_filter => '7',
		    epc_company => '3fff',
		    epc_asset => '0000000001',
		},	
		{ 
		    epc_type => 'GIAI-96',
		    epc_filter => '7',
		    epc_partition => '0',
		    epc_company => 'ffffffffff',
		    epc_asset => '00000000001',
		},		
		{
		    epc_type => 'GIAI-96',
		    epc_filter => '7',
		    epc_partition => '6',
		    epc_company => 'fffff',
		    epc_asset => '0000000000000001',
		},	
		{
		    epc_type => 'GIAI-96',
		    epc_filter => '7',
		    epc_partition => '6',
		    epc_company => 'fffff',
		    epc_asset => '0000000000000001',
		},	
		{
		    epc_type => 'UNKNOWN1-64',
		    epc_unknown => '3012345678abcdef',
		},
		{
		    epc_type => 'UNKNOWN2-64',
		    epc_unknown => '3012345678abcdef',
		},
		{
		    epc_type => 'UNKNOWN3-64',
		    epc_unknown => '12345678abcdef',
		},
		{
		    epc_type => 'UNKNOWN-96',
		    epc_unknown => '8888888888888888888888',
		},
		{
		    epc_type => 'UNKNOWN',
		    epc_unknown => 'deadbeef',
		},
		{
		    epc_type => 'UNKNOWN',
		    epc_unknown => '0123456789abcdef0123456789abcdef',
		},
		{
		    epc_type => 'UNKNOWN',
		    epc_unknown => '',
		},
		
		);

plan tests => keys(%RFID::EPC::Tag::TAGTYPES) +
              4*@testtags;

my %seenval;
while (my($name,$spec) = each(%RFID::EPC::Tag::TAGTYPES))
{
    eval {
	# Make sure the type_val is unique
	$seenval{"$spec->{type_val}/$spec->{type_bits}"} 
	    and die "Already saw this type_val\n";
	$seenval{"$spec->{type_val}/$spec->{type_bits}"} = 1;

	my $counted_bits = 0;
	my %unknown_fields;
	my @fields = @{$spec->{fields}};
	while (@fields)
	{
	    my $field = shift @fields;
	    my $fieldsize = shift @fields;
	    if ($fieldsize eq '?')
	    {
		$unknown_fields{$field} = 1;
	    }
	    elsif ($fieldsize eq '*')
	    {
		if ( defined($spec->{bits}) and
		     ($counted_bits - $spec->{bits}) >= 0)
		{
		    $counted_bits = $spec->{bits};
		}
	    }
	    elsif ($fieldsize =~ /^\d+$/)
	    {
		$counted_bits += $fieldsize;
	    }
	    else
	    {
		die "Invalid fieldsize for $name/$field\n";
	    }
	}
	
	if (keys %unknown_fields)
	{
	    foreach my $pf (@{$spec->{partition_fields}})
	    {
		$unknown_fields{$pf}
		    or die "partition_fields wants to define $pf, but it's now undefined!";
		delete $unknown_fields{$pf};
	    }
	    if (keys %unknown_fields)
	    {
		die "Some fields weren't defined: ",keys %unknown_fields;
	    }
	    if ($spec->{partitions})
	    {
		my $leftover_bits = $spec->{bits} - $counted_bits;
		foreach my $i (0..$#{$spec->{partitions}})
		{
		    my $partitions = $spec->{partitions}[$i];
		    my $sum = 0;
		    if (@$partitions != @{$spec->{partition_fields}})
		    {
			die "Partition $i has too many or too few field sizes\n"; 
		    }
		    foreach my $ps (@$partitions)
		    {
			$sum += $ps;
		    }
		    if ($sum != $leftover_bits)
		    {
			die "Expected $spec->{bits} bits, but found ",$counted_bits+$sum," instead, in partition $i\n";
		    }
		}
	    }
	}
	else
	{
	    if ($spec->{bits} and $counted_bits != $spec->{bits})
	    {
		die "Expected $spec->{bits} bits, but found $counted_bits in spec!\n";
	    }
	}
    };
    $@ and warn "Bad tagtype $name: $@";
    ok(!$@);
}

foreach my $tp (@testtags)
{
    my $e = RFID::EPC::Tag->new(%$tp);
    ok($e);
    warn "Tag ID: ",$e->id,"\n"
	if ($ENV{DEBUG});
    
    my $e2 = RFID::EPC::Tag->new(id => $e->id);
    ok($e2);

    my $parsed = { $e2->get(keys %$tp) };
    ok($parsed);

    warn Dumper($parsed)
	if ($ENV{DEBUG});

    # Make sure all keys match
    ok(scalar(grep 
	      { (defined($parsed->{$_}) and defined($tp->{$_})
		 and uc $parsed->{$_} eq uc $tp->{$_})
		    or warn("Field '$_' doesn't match!! ('$parsed->{$_}' != '$tp->{$_}')\n"),0 
		} keys %$tp)
       == scalar(keys %$tp)); 
}



