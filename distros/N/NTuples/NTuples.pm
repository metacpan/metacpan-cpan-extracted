# NTuples
# Specialized intra-memory RDBMS 
# Copyright (c) 2005, 2006, 2007 Charles Morris
# All rights reserved.
# 
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
# 
# This module is the core association engine for a few projects
# based on fast access to network configuration information.
# 
# There are generic wrappers available to you for use in your
# own projects. See the NTuples::wrap::* packages.
# 
# For more information on my projects, check for news at:
# http://www.cs.odu.edu/~cmorris/
# 
# Who says project creep should be avoided?


package NTuples;

our @DATA;
our @FMT;
our %colname_to_colnum;
our %addr_to_loc;

BEGIN {
  $VERSION = '0.11';
}

sub debug_display
{
  my $rownum = 0;
  foreach my $row ( @DATA )
  {   
    my $colnum = 0;
    foreach my $val ( @{$row} )
    {
      print "$val:[$rownum][$colnum] ";
      $colnum++;
    }
  $rownum++;
  print "\n";
  }
}

#---------- Constructor ----------#
#static method
sub new {
  my ($pkg) = shift;

  my $instance = bless( {}, $pkg );

return $instance;
}

##########################
#--- object functions ---#

# new_format()
# static method
# register format for any current or added data tuples.
sub new_format
{
  my ($instance) = shift;
  warn "expecting a ". __PACKAGE__ ."\n" unless $instance->isa(__PACKAGE__);

  @FMT = @_;

  my $i = 0;
  my $x;
  map{
    $x = $_;
    if($x){$colname_to_colnum{$x} = $i;}
    $i++;
  } @FMT;

return $instance;
}


# new_data()
# static method
# register data (overwriting old data)
sub new_data
{
  my ($instance) = shift;
  warn "expecting a ". __PACKAGE__ ."\n" unless $instance->isa(__PACKAGE__);

  @DATA = @_;

# probeably be made alot more efficient.
# any patches are welcome :)

#use Time::HiRes;
#my $start = Time::HiRes::time();
#$last = $start;

  my $rownum = 0;
  foreach my $row (@DATA)
  {
    my $colnum = 0;
    foreach my $field (@{$row})
    {
      my $i = 0;

      foreach my $colname (@FMT)
      {
	#debugged, $field needs to be encapsulated with ''s.
        $fieldrep = $field;
        $fieldrep =~ s/'/\\\'/g;
#        $code = '$lh_'. $FMT[$colnum] .'{\''. $fieldrep .'\'}{'. $colname .'} = '.
#          '\$DATA[$rownum][$colname_to_colnum{$colname}];';

         $lh{ $FMT[$colnum] }{ $fieldrep }{ $colname } =
	   \$DATA[$rownum][$colname_to_colnum{$colname}];

#        eval "$code"; warn "$code: $@" if $@;
      }

    $addr_to_loc{\$DATA[$rownum][$colnum]} = [ $rownum, $colnum ];

    $colnum++;
    }
  $rownum++;
  }

#$finish = Time::HiRes::time();
#print $finish - $start ."\n";

return $instance;
}


# insert_data()
# static method
# register an array of data (pushes to the end of current data)
# INSERT INTO NTuples VALUES @data
sub insert_data
{
  my ($instance) = shift;
  warn "expecting a ". __PACKAGE__ ."\n" unless $instance->isa(__PACKAGE__);

  push(@DATA, @_);

  # we REALLLY dont need to remap the entire LoL........
  # but thats how its happening right now until I have time to sit down and figure it out

  my $rownum = 0;
  foreach my $row (@DATA)
  {
    my $colnum = 0;
    foreach my $field (@{$row})
    {
      my $i = 0;
      foreach my $colname (@FMT)
      {
#        $code = '$lh_'. $FMT[$colnum] .'{'. $field .'}{'. $colname .'} = '.
#          '\$DATA[$rownum][$colname_to_colnum{$colname}];';

         $lh{ $FMT[$colnum] }{ $field }{ $colname } =
           \$DATA[$rownum][$colname_to_colnum{$colname}];

#        eval "$code"; warn "$code: $@" if $@;
      }

    $addr_to_loc{\$DATA[$rownum][$colnum]} = [ $rownum, $colnum ];

    $colnum++;
    }
  $rownum++;
  }

return $instance;
}


# select_row()
# SELECT * FROM NTuples WHERE $keyname = $key
sub select_row
{
  my ($instance, $keyname, $key) = @_;
  warn "expecting a ". __PACKAGE__ ."\n" unless $instance->isa(__PACKAGE__);


# This is faster (just an educated guess) but it returns crazy ordered results
# (ordered by the value of the hashed key.. I think)
#  my %result;
#  my $code = '%result = %{$lh_'. $keyname .'{'. $key .'}};';
#  eval "$code"; warn $@ if $@;
#  my @ret;
#  map { push(@ret, ${$_}) } values %result;

# So we do this instead.

  my @ret;
  map { push(@ret, NTuples::select_value($instance, $keyname, $key, $_)) } @FMT;  
  
return @ret;
}


# update_row()
# static method
# updates row resolved by $keyname{$key}
# UPDATE NTuples SET * = @row WHERE $keyname = $key
sub update_row
{
  my ($instance, $keyname, $key, @row) = @_;
  warn "expecting a ". __PACKAGE__ ."\n" unless $instance->isa(__PACKAGE__);

  my $i = 0;
  map { NTuples::update_value($instance, $keyname, $key, @FMT[$i], $_); $i++ } @row;

return $instance;
}


# select_value()
# static method
# resolves value $valname from row resolved by $keyname{$key}
# SELECT $valname FROM NTuples WHERE $keyname = $key
sub select_value
{
  my ($instance, $keyname, $key, $valname) = @_;
  warn "expecting a ". __PACKAGE__ ."\n" unless $instance->isa(__PACKAGE__);

  my $result;
#  my $code = '$result = $lh_'. $keyname .'{'. $key .'}{'. $valname .'};';
#  eval "$code"; warn "$code: $@" if $@;

  $result = $lh{ $keyname }{ $key }{ $valname };

return ${$result};
}


# update_value()
# static method
# updates value of $valname in row resolved by $keyname{$key} to $val
# UPDATE NTuples SET $valname = $val WHERE $keyname = $key
sub update_value
{
  my ($instance, $keyname, $key, $valname, $val) = @_;
  warn "expecting a ". __PACKAGE__ ."\n" unless $instance->isa(__PACKAGE__);

  #Step 1) Buffer old value
  #Step 2) Alter actual value
  #Step 3) Copy association based on $valname from $oldval to $val
  #Step 4) Remove old association based on $oldval

  #ok, so now its at least only doing one scalar assignment and one eval{}
#  my $code = '
#    $oldvalue = ${$lh_'. $keyname .'{'. $key .'}{'. $valname .'}};
#    ${$lh_'. $keyname .'{'. $key .'}{'. $valname .'}} = $val;
#    $lh_'. $valname .'{'. $val .'} = $lh_'. $valname .'{$oldvalue};
#    delete $lh_'. $valname .'{$oldvalue};
#  ';
  #codes and evaluates (using test.pl)
#   $oldvalue = ${$lh_username{sys}{uid}};
#   ${$lh_username{sys}{uid}} = $val;
#   $lh_uid{17} = $lh_uid{$oldvalue};
#   delete $lh_uid{$oldvalue};

#  print "eval: $code\n";
#  eval "$code"; warn "$code: $@" if $@;
  
  $oldvalue = ${ $lh{ $keyname }{ $key }{ $valname } };
  #print "$oldvalue = \${ \$lh{ $keyname }{ $key }{ $valname } }\n";
  
  ${ $lh{ $keyname }{ $key }{ $valname } } = $val;
  #print "\${ \$lh{ $keyname }{ $key }{ $valname } } = $val\n";
  
  $lh{ $valname }{ $val } = $lh{ $valname }{ $oldvalue };
  #print "\$lh{ $valname }{ $val } = \$lh{ $valname }{ $oldvalue }\n";
  
  delete $lh{ $valname }{ $oldvalue };

return $instance;
}


# delete_row()
# static method
# deletes row resolved by $keyname{$key}
# DELETE FROM NTuples WHERE $keyname = $key
sub delete_row
{
  my ($instance, $keyname, $key) = @_;
  warn "expecting a ". __PACKAGE__ ."\n" unless $instance->isa(__PACKAGE__);

  my $result;
#  my $code = '$result = $lh_'. $keyname .'{'. $key .'}{'. $keyname .'};';
#  print "eval: $code\n";
#  eval "$code"; warn "$code: $@" if $@;

  $result = $lh{ $keyname }{ $key }{ $keyname };

  if( $result )
  {
    splice( @DATA, @{$addr_to_loc{$result}}[0], 1 );
    
    my $i = 0;
    my @row = NTuples::select_row($instance, $keyname, $key);
    
    foreach my $colname (@FMT)
    {
    #  $code = 'delete $lh_'. $colname .'{'. $row[$i] .'};'; #if exists will not work with delete()
    #eval "$code"; warn "$code: $@" if $@;

    delete $lh{$colname}{$row[$i]};

    $i++;
    }
  }

return (defined($result)? '1' : '0');
}

1;

__END__

=head1 NAME

    NTuples - intra-memory RDBMS / db-operations on NxN arrays

=head1 SYNOPSIS

      use NTuples;

      $myassoc = new NTuples( );
	
      $myassoc->new_format( ['username', 'id', 'uid'] );

      $myassoc->new_data(
                          (
                            ["cmorris", "T0001", "100"],
                            ["ibl", "T2841", "101"],
                            ["olson", "T4812", "102"],
                            ["bader", "T3124", "103"]
                          )
                        );

      $myassoc->insert_data( ["robin_c", "T1492", "104"] );

	#returns [ 'ibl', 'T2841', '101' ]
      @row = $myassoc->select_row( 'username', 'ibl' );

	#returns 'robin_c'
      $val = $myassoc->select_value( 'uid', '104', 'username' );


=head1 DESCRIPTION

    NTuples - intra-memory RDBMS / database operations on NxN arrays

	NTuples should be used to run fast db-operations
	in NxN tables. NTuples is designed to be run inside of
	programs with daemon-like behavior, you regain the time
	lost during load-time from the high associativity
        with the excellent query performance.


=head1 USAGE

    new()
      Constructor.
      Returns new instance of NTuples.
    
    
    new_format()
      parameters:
        @format, array of column names
      
      Alters key format for any current or added data lines.
      
      There should be one argument for each element in the list
      with the name of the type of data in that field.
      
      For a non-unique data field in the format, or one that
      is not to be mapped, simply use null.
    
    
    new_data()
      parameters:
        @data, lines of data
      
      Registers and runs map on an array of data (overwriting old data)
    
    
    select_row()
      parameters:
        $keyname, name of column (specified in format)
        $key, value in column 
      
      Returns record specified by $key in $keyname column (array)
      SQL equivalent: "SELECT * FROM MyTuples WHERE $keyname=$key"
    
    
    select_value()
      parameters:
        $keyname, name of column (specified in format)
        $key, value in column 
        $valname, name of associated column to retreive
      
      Returns single value specified by $key in $keyname column (scalar)
      SQL equivalent: "SELECT $valname FROM MyTuples WHERE $keyname=$key"
    
    
    update_row()
      parameters:
        $keyname, name of column (specified in format)
        $key, value in column 
        @row, values to update (must be full record, otherwise use update_value)
      
      Updates row specified by $key in $keyname column.
      SQL equivalent: "UPDATE MyTuples SET c1=$row[0], ..., cn=$row[n] WHERE $keyname=$key"
    
    
    update_value()
      parameters:
        $keyname, name of column (specified in format)
        $key, value in column 
        $valname, value to update
        $val, new value
      
      Updates $valname to $val in row specified by $key in $keyname column.
      SQL equivalent: "UPDATE MyTuples SET $valname=$val WHERE $keyname=$key"


    delete_row()
      parameters:
        $keyname, name of column (specified in format)
        $key, value in column 
      
      Deletes row specified by $key in $keyname column.
      SQL equivalent: "DELETE FROM MyTuples WHERE $keyname=$key"
    
    
=head1 INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make install

=head1 DEPENDENCIES

  none

=head1 BUGS

  Not sure at this time. Everything -seems- stable,
  but if any are sighted please email me.

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2006, 2007 Charles A Morris.  All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
