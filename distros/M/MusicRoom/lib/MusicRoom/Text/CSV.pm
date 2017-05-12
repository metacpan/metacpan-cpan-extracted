# This module deals with handling comma serperated value files
# (CSV files).
#
# This is intended to provide a simple way to cope with standard format
# files so that data can be read and written.  It is OK for well formed
# files but not sufficiently robust to deal with everything.
#
=head1 NAME

MusicRoom::Text::CSV - Comma seperated files

=head1 DESCRIPTION

Read and write text files in a particular format

=head2 FORMAT

For the purposes of this module a CSV file looks like this:

    artist,name,year
    "Elvis Costello","Alison","1977"
    "Riuichi Sakamoto","23rd Psalm","1983"
    "Duane Eddy","Forty Miles of Bad Road","1959"

In particular the first line has the names of the attribites then each
following line has a data entry. Multi-line entries can be dealt with provided
they are quoted

=cut

package MusicRoom::Text::CSV;

use strict;
use warnings;
use Carp;

=head2 scan($fh,%flags)

A routine that reads in CSV data from an IO filehandle.  The standard way to use this 
function is like:

    use MusicRoom::Text::CSV;

    my $fh = IO::File->new("source.csv");
    MusicRoom::Text::CSV::scan($fh,action => \&process_entry);

    sub process_entry
      {
        my(%attribs) = @_;

        my $this_artist = $attribs{artist};
        my $this_name = $attribs{name};

        print "Next entry is $this_artist \"$this_name\"\n";
      }

The valid flags are:

    action: A routine to call for each line
    carp_msg: A routine to call to report problems
    allowed: List of attributes that are allowed
    required: List of attributes required
    required_quiet: List of attributes required

The allowed and required flags need either an array of hash reference, 
for example:

    MusicRoom::Text::CSV::scan($fh,action => \&process_entry,
                        required => ["name"]);

The required_quiet flag tells the routine that we require a group of 
columns to be present before proceeding, but that if they are missing 
we just want to fail silently.  This is a good option if you want to 
process a bunch of CSV files some of which have the data you need 
but you don't know in advance which ones, a call like:

    MusicRoom::Text::CSV::scan($fh,action => \&process_entry,
                        required_quiet => ["id","format"]);

will silently skip over the CSV file if it does not have both a 
"format" and "id" column.

=cut

sub scan
  {
    my($fh,%flags) = @_;

    my @ret;
    my %allowed;
    my %required;
    my $required_quiet = "";

    my %attrib2column;
    my @column2attrib;

    my $msg = "CSV file";
    $msg = $flags{"carp_msg"}
             if(defined $flags{"carp_msg"});
    my $return_data = 1;
    $return_data = "" if(defined $flags{"discard_data"});

    # We have been told which attributes are allowed
    foreach my $typ ("allowed","required","required_quiet")
      {
        if(defined $flags{$typ})
          {
            my @list;
            if(ref($flags{$typ}) eq "ARRAY")
              {
                @list = @{$flags{$typ}};
              }
            elsif(ref($flags{$typ}) eq "HASH")
              {
                @list = keys %{$flags{$typ}};
              }
            else
              {
                @list = split(/\s*,\s*/,$flags{$typ});
              }
            foreach my $flag (@list)
              {
                if($typ eq "allowed")
                  {
                    $allowed{$flag} = 1;
                  }
                elsif($typ eq "required")
                  {
                    $required{$flag} = 1;
                  }
                elsif($typ eq "required_quiet")
                  {
                    $required{$flag} = 1;
                    $required_quiet = 1;
                  }
                else
                  {
                    carp("Unknown list type $typ");
                  }
              }
          }
      }

    # First line tells us the attribute names in order
    my $attrib_str = <$fh>;
    my @attribs = split(/,/,$attrib_str);
    my $column_num = 0;
    for(my $i=0;$i<=$#attribs;$i++)
      {
        # Tidy up the attribute
        $attribs[$i] =~ s/^[\n\r\s]+//s;
        $attribs[$i] =~ s/[\n\r\s]+$//s;
        $attribs[$i] =~ s/[\n\r\s]+/_/sg;
        if($attribs[$i] =~ /\"([^\"]+)\"/)
          {
            # Should do some checks here
            $attribs[$i] = $1;
          }
        if($attribs[$i] =~ /\W/)
          {
            carp("Attribute name invalid ($attribs[$i]) in $msg");
            $attribs[$i] =~ s/\W//g;
          }
        carp("Attribute names must be lower case ($attribs[$i]) in $msg")
                           if($attribs[$i] ne lc($attribs[$i]));

        $attribs[$i] = lc($attribs[$i]);

        carp("Attribute $attribs[$i] is not allowed in $msg") 
                if(%allowed && !defined $allowed{$attribs[$i]});

        $attrib2column{$attribs[$i]} = $column_num++;
      }

    foreach my $attrib (keys %required)
      {
        if(!defined $attrib2column{$attrib})
          {
            # If we set a "required_quiet" flag then the caller wants to 
            # drop out without complaining
            carp("Required attribute $attrib is missing in $msg") if(!$required_quiet);
            return;
          }
      }

    my @this_record = ();
    my $record_num;

    my @data = <$fh>;
    while(@data)
      {
        # Read one record at a time
        @this_record = ();
        my $line = shift @data;

        if($line =~ s/\cZ+//)
          {
            next if($line =~ /^\s*$/s);
          }
        foreach my $attrib (@attribs)
          {
            $line =~ s/^[\s\n\r\cZ]+//s;
            next if($line eq "");

            my $val = "";
            # This could be delimited by quotes
            if(substr($line,0,1) eq "\"" || substr($line,0,1) eq "\'" || 
                                                 substr($line,0,1) eq "\`")
              {
                while(!($line =~ /^\"([^\"]*)\"/ || $line =~ /\'([^\']*)\'/ ||
                                                        $line =~ /\`([^\']*)\'/))
                  {
                    if(!@data)
                      {
                        carp("Cannot find close quote on |".substr($line,0,60)."| in $msg");
                        last;
                      }
                    $line .= shift @data;
                  }
                # Quoted attrib, could be multiline
                if($line =~ s/^\"([^\"]*)\"//s || $line =~ s/^\'([^\']*)\'//s ||
                                                     $line =~ s/^\`([^\']*)\'//s)
                  {
                    $val = $1;
                  }
              }
            elsif($line =~ s/^([^,]*),/,/s)
              {
                $val = $1;
                $val =~ s/\s+$//;
              }
            elsif($line =~ s/^([^\n\r]*)([\n\r])/$2/s)
              {
                $val = $1;
                $val =~ s/\s+$//;
              }
            else
              {
                carp("Cannot pick out value from \"".
                            substr($line,0,20)."...\" in $msg [".join('|',@this_record)."]");
                # Move data on
                $line =~ s/^([^\n\r]+)[\n\r]+//s;
                @this_record = ();
                last;
              }

            push @this_record,$val;

            # Do we have a valid delimiter?
            if($#this_record < $#attribs)
              {
                # Should be a comma
                if($line =~ s/^\s*,//)
                  {
                  }
                else
                  {
                    carp("Missing comma \"".
                            substr($line,0,20)."...\" in $msg [".join('|',@this_record)."]");
                  }
              }
            else
              {
                # Should be a newline
                if($line =~ s/^(\n\r|\r\n)//)
                  {
                  }
                elsif($line =~ s/^(\n|\r)//)
                  {
                  }
                else
                  {
                    carp("Missing newline \"".
                            substr($line,0,20)."...\" in $msg [".join('|',@this_record)."]");
                  }
              }
          }
        # Now we should have a complete record
        next if(!@this_record);

        my %vals;
        for(my $i=0;$i<=$#this_record;$i++)
          {
            $vals{$attribs[$i]} = $this_record[$i];
          }

        if(defined $flags{action})
          {
            &{$flags{action}}(%vals,%flags);
          }
        push @ret,\%vals if($return_data);
        $record_num++;
      }

    return () if(!$return_data);
    return @ret;
  }

=head2 scan($fh,$cols_ref,$flags_ref,%data)

Output data to a CSV file.  Here is an example:

    my @to_columns = ("year","name");

    my @order;
    foreach my $id (sort by_year keys %local_data)
      {
        push @order,$id;
      }
    my $fh = IO::File->new(">$target_file");
    MusicRoom::Text::CSV::write($fh,\@to_columns,
                     {order => \@order, replace => 's/\~\|/, /g'},
                     %local_data);

The flags are:

    sort_fun: A function to call to sort entries
    order: Array of keys selecting the entries
    replace: A rexeg pattern to apply before outputting

=cut

sub write
  {
    my($fh,$cols_ref,$flags_ref,%data) = @_;
        
    # Write data in CSV format.  We will write in a restrictive fashion
    print $fh join(',',@{$cols_ref})."\n";

    my @keys;
    if(defined $flags_ref->{sort_fun})
      {
        # @keys = sort \&{$flags_ref->{sort_fun}} keys(%data);
        carp("sort_fun not yet implemented");
      }
    elsif(defined $flags_ref->{order} && ref($flags_ref->{order}) eq "ARRAY")
      {
        @keys = @{$flags_ref->{order}};
      }
    elsif(defined $flags_ref->{order})
      {
        @keys = split(/\s*[\|\,]\s*/,$flags_ref->{order});
      }
    else
      {
        @keys = sort lexically keys(%data);
      }
    foreach my $key (@keys)
      {
        my %attribs = %{$data{$key}};
        foreach my $col (@{$cols_ref})
          {
            print $fh ","
                        if($col ne ${$cols_ref}[0]);
            my $val = $attribs{$col};
            $val = "" if(!defined $val);

            if(defined $flags_ref && ref($flags_ref) eq "HASH" &&
                          defined $flags_ref->{replace})
              {
                eval("\$val =~ ".$flags_ref->{replace});
              }
            print $fh "\"$val\"";
          }
        print $fh "\n";
      }
  }

sub lexically
  {
    # This routine gives us a sort order that more closely matches what 
    # a naive use would expect (ie "9-z" comes before "10-a")
    my($a_,$b_) = @_;

    # If we are called by sort the old @_ gets left around
    # we want to detect this and grab values from $a and $b
    if(!defined($a_) || !defined($b_) ||
         ref($a_) || ref($b_) || $#_ != 1)
      {
        $a_ = $a;
        $b_ = $b;
      }
    return 0
        if($a_ eq "" && $b_ eq "");
    return -1
        if($a_ eq "");
    return 1
        if($b_ eq "");

    my($a_1,$a_t,$a_2,$b_1,$b_t,$b_2);

    if($a_ =~ /^(\d+)/)
      {
        $a_t = 0; $a_1 = $1; $a_2 = $';
      }
    elsif($a_ =~ /^(\D+)/)
      {
        $a_t = 1; $a_1 = $1; $a_2 = $';
      }
    if($b_ =~ /^(\d+)/)
      {
        $b_t = 0; $b_1 = $1; $b_2 = $';
      }
    elsif($b_ =~ /^(\D+)/)
      {
        $b_t = 1; $b_1 = $1; $b_2 = $';
      }

    if($a_t == 0 && $b_t == 0)
      {
        return lexically($a_2,$b_2)
                       if($a_1 == $b_1);
        return $a_1 <=> $b_1;
      }
    if($a_t == 1 && $b_t == 1)
      {
        my $r = lc($a_1) cmp lc($b_1);
        return lexically($a_2,$b_2)
                       if($r == 0);
        return $r;
      }
    return -1
        if($a_t == 0);
    return 1;
  }

1;

