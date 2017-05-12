package Mozilla::Mork;

#use 5.008004;
#use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Mozilla::Mork ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


# Preloaded methods go here.
#TODO make private classes of mork munging routines

#package mork;

##declare variables

my ($verbose, $reference, $file);

my (%key_table, %val_table, %row_hash);

my ($total, $skipped) = (0, 0);

##initialise variables

#set to 0 if you dont want status reports

$verbose++;


sub new {
	my $class = shift;	# works on @_ by default
        my $file = shift;       # If an file has been given to start with
        my $MorkFileInfo = {};  #create a blank hash

        bless $MorkFileInfo, $class;

        #test that we got the file to parse
        unless ($file) { return 0; }
        #set the file name in the hash
        $MorkFileInfo->{'file'} = $file;
        #get a reference to an array of hash's

        $MorkFileInfo->{'results'} = mork_parse_file($file);



        return $MorkFileInfo;
}

##################
# ReturnReferenceStructure
# returns the reference to the array containing the hash's of the data
##################
sub ReturnReferenceStructure {
        #get the ojbect refernce to the instance thats calling us
        my ($obj) = shift;
        #return the details as requested above
        return $obj->{'results'};
}

################################
#address book specific test
# probably a better way of doing this is writing a package that inherits
# the Mork class and then does this, but for now..
#TODO AddressBookTestPrint probably doen't work - test and fix
#TODO implement AddressBookTestPrint as a inherited module from Morkto Mork::AddressBook
################################
sub AddressBookTestPrint {
	my ($obj) = shift;

        #get the first hash of results from the parse
        my %array = %{ $obj->{'results'}->[0] }
           || die "constructor not initialised in Mork.pm.  Did you call mork->new()?\n";
        #construct an array of just the keys of the hash

        my @field_names = sort(keys(%array));

        #print each of the field headers
        map { print "Field Names: $_\n"; } @field_names;

        #test print a couple of values
        print "Record Number 0's First Name is: $array{\"FirstName\"}\n";
        print "Record Number 0's Email is: $array{\"PrimaryEmail\"}\n";
}

##########################
# dumps the record headers
# returns  an array of the record headers
# assumes that the first record contains all the headers
# so far this assumption has proved true
##########################
sub ListHeaders
{
        my ($obj) = shift;
        #get the first hash of results from the parse
        #having problems with dereferncing, so..
        my $results =  $obj->{'results'}
                || die "constructor not initialised in Mork.pm.  Did you call mork->new()?\n";

        my @field_names = sort(keys( %{$results->[0]} ));
        return @field_names;
}

##########################
# Returns a reference to an array of hashes, the contents of the mork file.

# expects filename to process ($file)

##########################
sub mork_parse_file  

{

        #my ($obj) = shift;    #dont need to do this for internal (private class methods)
        #get the filename

        my ($file) = shift;

 	#stream the file (gulp all in one go, not iterate over each line)

  	local $/ = undef;

  	local *IN;



  ##########################################################################

  # Define the messy regexen up here

  ##########################################################################



  my $top_level_comment = qr@//.*\n@;



  my $key_table_re = qr/  < \s* <             # "< <"

                         \( a=c \) >          # "(a=c)>"

                         (?> ([^>]*) ) > \s*  # Grab anything that's not ">"

                     /sx;



  my $value_table_re = qr/ < ( .*?\) )> \s* /sx;



  my $table_re = qr/ \{ -?        # "{" or "{-"

                    [\da-f]+ :    # hex, ":"

                    (?> .*?\{ )   # Eat up to a {...

                   ((?> .*?\} )   # and then the closing }...

                    (?> .*?\} ))  # Finally, grab the table section

                 \s* /six;



  my $row_re = qr/ ( (?> \[ [^]]* \]  # "["..."]"

                         \s*)+ )      # Perhaps repeated many times

                 /sx;



  my $section_begin_re = qr/ \@\$\$\{    # "@$${"

                             ([\dA-F]+)  # hex

                             \{\@ \s*    # "{@"

                           /six;



  my $section_end_re = undef;

  my $section = "top level";



  ##########################################################################

  # Read in the file.

  ##########################################################################

  #open (IN, "<$file") || error ("$file: $!") || die "Cannot open $file: $!\n";

  open (IN, "<$file") || die "Cannot open $file: $!\n";
  print STDERR "$0: reading $file...\n" if ($verbose);



  my $body = <IN>;

  close IN;



  $body =~ s/\r\n/\n/gs;    # Windows Mozilla uses \r\n

  $body =~ s/\r/\n/gs;      # Presumably Mac Mozilla is similarly dumb



  $body =~ s/\\\\/\$5C/gs;  # Sometimes backslash is quoted with a

                            #  backslash; convert to hex.

  $body =~ s/\\\)/\$29/gs;  # close-paren is quoted with a backslash;

                            #  convert to hex.

  $body =~ s/\\\n//gs;      # backslash at end of line is continuation.



  ##########################################################################

  # Figure out what we're looking at, and parse it.

  ##########################################################################



  print STDERR "$0: $file: parsing...\n" if ($verbose);



  pos($body) = 0;

  my $length = length($body);



  	while( pos($body) < $length ) 

	{



    		# Key table

		if ( $body =~ m/\G$key_table_re/gc ) 

    		{

      			mork_parse_key_table($file, $section, $1);



	    	# Values

    		} elsif ( $body =~ m/\G$value_table_re/gco ) 

		{

      			mork_parse_value_table($file, $section, $1);



	    	# Table

    		} elsif ( $body =~ m/\G$table_re/gco ) 

		{

      			mork_parse_table($file, $section, $age, $since, $1);



	    	# Rows (-> table)

    		} elsif ( $body =~ m/\G$row_re/gco ) 

		{

      			mork_parse_table($file, $section, $age, $since, $1);



	    	# Section begin

    		} elsif ( $body =~ m/\G$section_begin_re/gco ) 

		{

      		$section = $1;

	      	$section_end_re = qr/\@\$\$\}$section\}\@\s*/s;



    		# Section end

    		} elsif ( $section_end_re && $body =~ m/\G$section_end_re/gc ) 

		{

      			$section_end_re = undef;

	      		$section = "top level";



    		# Comment

    		} elsif ( $body =~ m/\G$top_level_comment/gco ) 

		{

      		#no-op

    		} 

		else 

		{

			#$body =~ m/\G (.{0,300}) /gcsx; print "<$1>\n";

      			print("$file: $section: Cannot parse");

    		}

  	}#end of while loop



  	if($section_end_re) 

	{

    		print("$file: Unterminated section $section");

  	}





  	print STDERR "$0: $file: sorting...\n" if ($verbose);



	#	my @entries = sort { $b->{LastVisitDate} <=>

	#	               $a->{LastVisitDate} } values(%row_hash);



	my @entries = values(%row_hash);

 		       

  	print STDERR 

	"$0: $file: done!  ($total total, $skipped skipped)\n" 

	if ($verbose);



	#reset all variables in the left parenthesis	

	(%key_table, %val_table, %row_hash, $total, $skipped) = ();



	#send a reference to the @entries array back to the calling routine

	return \@entries;

} # end of mork_parse_file



##########################################################################

# parse a row and column table

##########################################################################

sub mork_parse_table {
        #my ($obj) = shift;

	#get the variables from the calling script

	my($file, $section, $age, $since, $table_part) = (@_);

	print STDERR "\n" if ($verbose);



  	# Assumption: no relevant spaces in values in this section

  	$table_part =~ s/\s+//g;



	#  print $table_part; #exit(0);



	  #Grab each complete [...] block

	while( $table_part =~ m/\G  [^[]*   \[  # find a "["

                            ( [^]]+ ) \]  # capture up to "]"

                        /gcx ) 

	{

		#set $_ to the result of the regex (each complete [...] block)

    		$_ = $1;

		my %hash;

		#break up the table - each line cosists of a $id and the rest are records

    		my ($id, @cells) = split (m/[()]+/s);



		#a long way of saying skip the line if there are no records 

		#in the @cells array

		next unless scalar(@cells);



    		# Trim junk

    		$id =~ s/^-//;

    		$id =~ s/:.*//;



		#check that the $id number we've been given corresponds 

		# to one we pulled out from the key_table index

    		if($row_hash{$id}) 

		{

			#set %hash to the contents of the anonymous 

			# hash that holds the hash  $id 

			# uniquely identifies within %row_hash

      			%hash = ( %{$row_hash{$id}} );

    		} #else 

		#{

			# the code below is for the history mdb hash, 

			# and not what we want to do here, so I've

			# shamefully just ommitted it.

			#	%hash = ( 'ID'            => $id,

			#'LastVisitDate' => 0   );

		#}

		#TODO write some code that inserts a default value if there isn't one already



		#having sorted out the right %hash according to the $id which was the

		#first record of the line, we now interate through all the others

		# on the line

		#another bit of Deep Magic which sorts out the cell,

		# includes some error checking

    		foreach (@cells) 

		{

			#if the record is empty, skip

      			next unless $_;

			# extract $keyi, $which, $vali from the result of the regexp

		      	my ($keyi, $which, $vali) =

        			m/^\^ ([-\dA-F]+)

              			([\^=])

              			(.*)     

          			$/xi;



	      		print ("$file: unparsable cell: $_\n") unless defined ($vali);

	

      			# If the key isn't in the key table, ignore it

      			#

	      		my $key = $key_table{$keyi};

      			next unless defined($key);



			#IIRC this is the precurser to map() in perl 5.

			# perl wizards feel free to correct me..

      			my $val  = ($which eq '='

	                  ? $vali

        	          : $val_table{$vali});



	  		#if ($key eq 'LastVisitDate' || $key eq 'FirstVisitDate') 

			#{

			#$val = int ($val / 1000000);  # we don't need milliseconds..

			#}



			#add a hash value of the $val we extracted from the table, 

			# relating to the key $key  

	      		$hash{$key} = $val;

			#print "$id: $key -> $val\n";

    		}





	#	if ($age && ($hash{LastVisitDate} || $since) < $since) 

#	    	{

#			print STDERR "$0: $file: skipping old: " .

#	#                 	"$hash{LastVisitDate} $hash{URL}\n"

#        		if ($verbose);

#      		

#		$skipped++;

#      		next;

#    		}

		

		#showing a blatant disregard for preserving the my of 

		#$total, we treat it as an our()

		#increment the $total counter so that mork_parse_file() 

		#can print its stats of how many

		# lines its processed

		$total++;

		#add a reference to the %hash table we just constructed 

		#of the values in this line  

    		$row_hash{$id} = \%hash;

  	}

}
       #end of mork_parse_tabl()


##########################################################################

# parse a values table

##########################################################################



sub mork_parse_value_table {
        #my ($obj) = shift;

  my($file, $section, $val_part) = (@_);



  return unless $val_part;



  my @pairs = split (m/\(([^\)]+)\)/, $val_part);

  $val_part = undef;



  print STDERR "\n" if ($verbose > 3);



  foreach (@pairs) {

    next unless (m/[^\s]/s);

    my ($key, $val) = m/([\dA-F]*)[\t\n ]*=[\t\n ]*(.*)/i;



    if (! defined ($val)) {

      print STDERR "$0: $file: $section: unparsable val: $_\n";

      next;

    }



    # Assume that records are never hexilated; so

    # don't bother unhexilating if we won't be using Name, etc.

    if($val =~ m/\$/) {

      # Approximate wchar_t -> ASCII and remove NULs

      $val =~ s/\$00//g;  # faster if we remove these first

      $val =~ s/\$([\dA-F]{2})/chr(hex($1))/ge;

    }



    $val_table{$key} = $val;

    print STDERR "$0: $file: $section: val $key = \"$val\"\n"

      if ($verbose > 3);

  }

} #end of mork_parse_value_table




##########################################################################

# parse a key table

##########################################################################



sub mork_parse_key_table {

        #my ($obj) = shift;
        my ($file, $section, $key_table) = (@_);



  print STDERR "\n" if ($verbose > 3);

  $key_table =~ s@\s+//.*$@@gm;



  my @pairs = split (m/\(([^\)]+)\)/s, $key_table);

  $key_table = undef;



  foreach (@pairs) {

    next unless (m/[^\s]/s);

    my ($key, $val) = m/([\dA-F]+)\s*=\s*(.*)/i;

    error ("$file: $section: unparsable key: $_") unless defined ($val);



    ## If we're only emitting URLs and dates, don't even bother

    ## saving the other fields that we aren't interested in.

    ##

    #next if (!$show_all_p &&

    #         $val ne 'URL' && $val ne 'LastVisitDate' &&

    #         $val ne 'VisitCount');



    $key_table{$key} = $val;

    print STDERR "$0: $file: $section: key $key = \"$val\"\n"

      if ($verbose > 3);

  }

}
  #end of mork_parse_key_table()


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mozilla::Mork - Perl extension for reading Mork hash database file such as are used in the Mozilla Address Book and History files.

=head1 SYNOPSIS

	use Mozilla::Mork;
	$file = $ARGV[0];
	unless ($file) { die "Useage: $0 <filename>\n"; }
	#get a reference to an array of hash's
	my $MorkDetails = Mozilla::Mork->new($file);
	my $results = $MorkDetails->ReturnReferenceStructure();
	#process those results
	# for each line in the database
	my %array = %{ $results->[0] };
	my @field_names = sort(keys(%array));
	#my @field_names = $MorkDetails->ListHeaders();
	map { print "Field Names: $_\n"; } @field_names;
	print "\ndone!\n";


=head1 DESCRIPTION

B<New>

Sets up the OO stuff.   Returns a pointer to a data structure, loads the mork database into a in-memory hash (array of hashes of hashes, actually.)

B<ReturnReferenceStructure>

Returns the reference to the array containing the hash's of the data.  
Each element in the array is a seperate record in the 'database'.  The record headers are usually the first record (see ListHeaders() below).

B<ListHeaders>

Dumps the record headers.
returns  an array of the record headers.  It assumes that the first record contains all the headers.  So far this assumption has proved true..



=head2 EXPORT

None by default.



=head1 SEE ALSO

I'll probably put up a web page here eventually: http://www.kript.net

For now, see;

http://www.jwz.org/hacks/mork.pl
http://www.mozilla.org/mailnews/arch/mork/primer.txt
http://jwz.livejournal.com/312657.html
http://www.jwz.org/doc/mailsum.html
http://bugzilla.mozilla.org/show_bug.cgi?id=241438

I would recommend reading the source of the perl script first in the list above.  This module was taken from work Jamie Zawinski did in that script, so a huge thanks - I admit I might not have tackled this without this as a starting point!
Jamie has quite a lot to say about the Mork file format, and its worth reading.  That I know of, this is only the second module to get involved with Mork, and we're both based on Jamie's code..

My employers website: http://www.ipaccess.com.  My thanks to them for allowing me to work on this and release it as open source.

=head1 AUTHOR

John Constable, E<lt>john@kript.netE<gt>

However, this could not be possible without Jamie Zawinski (and others) initial mozilla history perl parsing script (see above).   

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by John Constable

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
