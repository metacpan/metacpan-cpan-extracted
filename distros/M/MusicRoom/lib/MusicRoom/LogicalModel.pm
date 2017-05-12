# This should map from a logical model to a physical one,
# for the moment just use it to list physical tables
package MusicRoom::LogicalModel;

use strict;
use warnings;
use Carp;
use IO::File;

use MusicRoom;
use MusicRoom::Date;
use MusicRoom::File;

use MusicRoom::Artist;
use MusicRoom::Song;
use MusicRoom::Album;
use MusicRoom::Track;
use MusicRoom::Zone;

# Globally available enum definitions
my %enums =
  (
    format =>  [MusicRoom::File::formats()],
  );

my @databases = 
  (
    core => 
      [
        MusicRoom::Artist::table_spec(),
        MusicRoom::Song::table_spec(),
        MusicRoom::Album::table_spec(),
        MusicRoom::Zone::table_spec(),
        MusicRoom::Track::table_spec(),
      ],
  );

# Convert the ordered list (which we need to know what
# order to create things in) into a set of nested
# hashes (which will be easier to use for most tasks)

my(%databases,%db_idxes);

for(my $db_idx=0;$db_idx<=$#databases;$db_idx += 2)
  {
    my $db_name = $databases[$db_idx];

    croak("Two databases called $db_name")
                                 if(defined $databases{$db_name});
    croak("Cannot use empty name as db_name")
                                 if($db_name eq "");

    my %db_tables = ();
    for(my $tab_idx=0;$tab_idx<=$#{$databases[$db_idx+1]};$tab_idx += 2)
      {
        my $tab_name = $databases[$db_idx+1]->[$tab_idx];

        croak("Two tables called $tab_name in $db_name")
                                                 if(defined $db_tables{$tab_name});
        croak("Cannot use empty name as table name in $db_name")
                                 if($tab_name eq "");
        my %tab_attribs = ();
        for(my $atr_idx=0;$atr_idx<=$#{$databases[$db_idx+1]->[$tab_idx+1]};$atr_idx += 2)
          {
            my $attrib = $databases[$db_idx+1]->[$tab_idx+1]->[$atr_idx];

            croak("Two attributes called $attrib in $db_name:$tab_name")
                                                 if(defined $tab_attribs{$attrib});
            croak("Cannot use empty name as attribute name in $db_name:$tab_name")
                                 if($tab_name eq "");
            $tab_attribs{$attrib} =
                          $tab_attribs{$databases[$db_idx+1]->[$tab_idx+1]->[$atr_idx+1]};
          }
        $tab_attribs{""} = $tab_idx;
        $db_tables{$tab_name} = \%tab_attribs;
      }

    $db_tables{""} = $db_idx;
    $databases{$db_name} = \%db_tables;
  }

sub list_dbs
  {
    my @dbs = ();
    for(my $db_idx=0;$db_idx<=$#databases;$db_idx += 2)
      {
        push @dbs,$databases[$db_idx];
      }
    return @dbs;
  }

sub list_physical_tables
  {
    # Provide a list of the physical tables that are held in 
    # a named database
    my($db_name) = @_;

    croak("$db_name: is not a listed database")
                 if(!defined $databases{$db_name});

    my $db_idx = $databases{$db_name}->{""};
    my @tables = ();
    for(my $tab_idx=0;$tab_idx<=$#{$databases[$db_idx+1]};$tab_idx += 2)
      {
        push @tables,$databases[$db_idx+1]->[$tab_idx];
      }
    return @tables;
  }

sub get_physical_columns
  {
    my($db_name,$tab_name) = @_;
    croak("$db_name: is not a listed database")
                 if(!defined $databases{$db_name});

    my $db_idx = $databases{$db_name}->{""};

    croak("$db_name:$tab_name is not a listed table")
                 if(!defined $databases{$db_name}->{$tab_name});

    my $tab_idx = $databases{$db_name}->{$tab_name}->{""};
    my @attribs = ();
    for(my $atr_idx=0;$atr_idx<=$#{$databases[$db_idx+1]->[$tab_idx+1]};$atr_idx += 2)
      {
        push @attribs,$databases[$db_idx+1]->[$tab_idx+1]->[$atr_idx];
      }
    return @attribs;
  }

sub get_column_spec
  {
    my($db_name,$tab_name,$attrib) = @_;

    croak("$db_name: is not a listed database")
                 if(!defined $databases{$db_name});

    my $db_idx = $databases{$db_name}->{""};

    croak("$db_name:$tab_name is not a listed table")
                 if(!defined $databases{$db_name}->{$tab_name});

    my $tab_idx = $databases{$db_name}->{$tab_name}->{""};
    for(my $atr_idx=0;$atr_idx<=$#{$databases[$db_idx+1]->[$tab_idx+1]};$atr_idx += 2)
      {
        return $databases[$db_idx+1]->[$tab_idx+1]->[$atr_idx+1]
                           if($databases[$db_idx+1]->[$tab_idx+1]->[$atr_idx] eq $attrib);
      }
    croak("$db_name:$tab_name.$attrib is not a listed attribute");
    return undef;
  }

sub get_physical_column
  {
    my($db_name,$tab_name,$attrib,$quiet) = @_;
    my $spec = get_column_spec($db_name,$tab_name,$attrib);

    return "CHAR(8)"
                 if($spec eq "STN");
    return "CHAR($1)"
                 if($spec =~ /^text\:(\d+)$/i);
    return "INTEGER"
                 if($spec =~ /^integer$/i);

    # For the moment all bools are ints
    return "INTEGER"
                 if($spec =~ /^boolean$/i);

    if(ref($spec) eq "ARRAY")
      {
        # This is a list of values that this slot can have, for the 
        # moment lets just create a text entry that is long enough for
        # all of them
        my $max_len = 0;
        foreach my $val (@{$spec})
          {
            $max_len = length($val) if(length($val) > $max_len);
          }
        croak("Empty enum in ${db_name}:${tab_name}.${attrib}?") 
                                                   if($max_len == 0);
        $max_len += 2;
        return "CHAR($max_len)";
      }
    elsif($spec =~ /^enum\.(\S+)$/i)
      {
        # For the moment we'll store enumerations in strings just long 
        # enough to hold the maximum
        my $enum = $1;
        croak("There is no $enum enum defined for ${db_name}:$tab_name.$attrib")
                            if(!defined $enums{$enum});
        my $max_len = 0;
        foreach my $val (@{$enums{$enum}})
          {
            $max_len = length($val) if(length($val) > $max_len);
          }
        croak("Empty enum $enum?") if($max_len == 0);
        $max_len += 2;
        return "CHAR($max_len)";
      }
    if($spec =~ /^(\w+)\:(\w+)\.(\w+)$/)
      {
        # This duplicates an entry from another table
        my $far_spec = get_physical_column($1,$2,$3,1);
        return $far_spec if(defined $far_spec);
      }
    elsif($spec =~ /^(\w+)\.(\w+)$/)
      {
        # This duplicates an entry from another table
        my $far_spec = get_physical_column($db_name,$1,$2,1);
        return $far_spec if(defined $far_spec);
      }
    croak("Cannot convert \"$spec\" into physical form") if(!$quiet);
  }

1;
