package String::Simrank;

    # Note to developers:
    # enable the VERSIONs (here and in the "use Inline C ..."
    # statement) to match each other when ready to install in sitelib or
    # when ready to distribute.  Otherwise, disable them
    # with commenting symbol for testing.

# use base 'Exporter';
# @EXPORT_OK = qw(add subtract);
use strict;
use File::Basename;
use IO::File;
use Fcntl;
use Data::Dumper;
use Storable;
use vars qw($VERSION $NAME);


$VERSION = '0.079';
$NAME = 'String::Simrank';

# Must specify a NAME and VERSION parameter. The NAME must match your module's package
# name. The VERSION parameter must match the module's $VERSION
# variable and they must both be of the form /^\d\.\d\d$/.
# DATA refers to the __DATA__ section near bottom of this file.
use Inline C => 'DATA';

=head1 NAME

String::Simrank - Rapid comparisons of many strings for k-mer similarity.
=cut

=head1 SYNOPSIS

  use String::Simrank;
  my $sr = new String::Simrank(
              { data => 'db.fasta'});
  $sr->formatdb();
  $sr->match_oligos({ query => 'query.fasta' });

  You may utilize  k-mers of various sizes, e.g.:
  $sr->formatdb( { wordlen => 6 } );
=cut

=head1 DESCRIPTION

The String::Simrank module allows rapid searches for similarity between query
strings and a database of strings.  This module is maintained by molecular
biologists who use it for searching for similarities among strings representing
contiguous DNA or RNA sequences.  This program does not
construct an alignment but rather finds the ratio
of nmers (A.K.A. ngrams) that are shared between a query and database
records.
The input file should be fasta formatted (either aligned or unaligned) multiple
sequence file.  
The memory consumption is moderate and grows linearly with the number of sequences
and depends on the nmer size defined by the user.  Using 7-mers, ~20,000 strings
each ~1,500 characters in length requires ~50 Mb.

The module can be used from the command line through the script
C<simrnak_nuc.pl> provided in the examples folder.

By default the output is written to STDOUT and
represents the similarity of each query string to the top hits in the 
the database.  The format is query_id, tab, best match database_id, colon, percent similarity, space
second best match database_id, colon, percent similarity.
query1  EscCol36:100.00 EscCol36:100.00 EscCol43:99.59  EscCol29:99.24  EscCol33:99.17  EscCol10:99.02 

=cut

=head1 METHODS

=cut

=head2 new( { data_path => $path })
  
  my $sr = new String::Simrank( { data => 'many_seqs.fasta' });

Instantiates a new String::Simrank object.
Each simrank database should live within its own String::Simrank object.
In other words, each unique combination of a fasta database and n-mer
length will have its own instance.
If the database has already been formated then the wordlength will be
read from the formatted database's .bin file. 
Parameters:

=over 4

=item data

Sets the path of where the data fasta file is (Database sequences, fasta format).
The same terminal directory is where the formated database will reside with the same
base name but the .fasta will be substituted with .bin.
Sequence names(identifiers) will be first 10 characters matched between the '>' and the first space character.
Be sure the sequences names are unique within this string.

=back

=cut

sub new {
    # Todd Z. DeSantis, March 2008
    
    my ($class, $cl_args) = @_;
       # Parameter hr is called $cl_args since in
       # many instances these will come directly from the command line.
    my $self = bless {}, $class;
    $self->_check_arguments_for_new($cl_args);
    # print STDERR "you are using String::Simrank version $VERSION \n";
    return $self;
}

=head2 _check_arguments_for_new

Internally used function.
Validates the 'data' argument needed so this instance knows what data
file will be linked. Method checks that fasta file exists and is readable 
and creates the name which corresponds to the .bin file.
If errors are found, program exits.
Returns a hash or hash ref
depending on the context of the method call.

=cut


sub _check_arguments_for_new {
    # Niels Larsen, May 2004.
    # Todd Z. DeSantis, March 2008.
 
    my ($self,
        $cl_args,    # Command Line ARGument hash
                      # not really required to come from the command line
         ) = @_;

    my ( @errors, $error);

    if ( $cl_args->{"data"} ) {
         # $cl_args->{"data"} = &Common::File::full_file_path( $cl_args->{"data"} );

        if ( -r $cl_args->{"data"}) {
            $cl_args->{"binary"} = $cl_args->{"data"};
            $cl_args->{"binary"} =~ s/\.[^\.]+$//;
            $cl_args->{"binary"} .= ".bin";
            
            $self->{param}{data} = $cl_args->{"data"};
            $self->{param}{binary} = $cl_args->{"binary"};
	    if (-e $cl_args->{"binary"} && -r $cl_args->{"binary"}) {
		print $cl_args->{"binary"} . " has been formatted\n";
		$self->{binary_ready} = 1;
	    } else {
		$self->{binary_ready} = 0;
	    }
            
        } else {
            push @errors, qq (Simrank.pm: Input fasta data file not found or not readable -> "$cl_args->{'data'}");
        }
        
    } else {
        push @errors, qq (Fasta sequence file must be specified with *data* argument);
    }
    
    # Print errors if any and exit,

    if ( @errors )
    {
        foreach $error ( @errors )
        {
            print STDERR "$error\n";
            # &Common::Messages::echo_red( "ERROR: ");
            # &Common::Messages::echo( "$error\n" );
        }
        
        exit;
    }
    else {
        
        wantarray ? return %{ $cl_args } : return $cl_args;
    }

}

=head2 formatdb({ wordlen => $int, minlen => $int, silent = $bool })

  $sr->formatdb({wordlen => 8, minlen => 500, silent => 0, valid_chars => 'ACGT'});

From an input collection of strings (data), generates a binary file
optimized for retrieval of k-mer similarities. The file will contain
a pre-computed map of which sequences - given by their index 
number in the input data file - contain a given k-mer. All the
valid k-mers of the given length are mapped. This means each
k-mer from a query string can be used to look up the database strings
it occurs in, very quickly. The memory consumption is moderate 
and grows linearly with the number of sequences; 20,000 takes 
50-55 mb. 
The first characters between the '>' character and the first space 
is recognized as the string (sequence) identifier and should be unique for each record.
The number of sequences found in the input collection
is returned and the file xyz.bin is written to disk.

Parameters:

=over 4

=item pre_subst

An integer that determines how to interpret some special characters in the strings.
The substitution is done before k-mers are extracted.
Use 1 to eliminate all periods(.), hypens(-), and space characters(\s, which includes
\s,\t,\n). This is the default behavior.
Use 2 to convert same characters as above into underscores(_).   

=item wordlen

An integer that specifies the k-mer length to index for each record in the input data file.
Default is 7.

=item minlen

Specifies the minimum string length for a database sequence to be worthy of indexing.
Default is 50.

=item valid_chars

Specifies the characters to allow for formatting.  Entire k-mer must be composed
of these characters otherwise it will be ignored. When not defined, all 
characters are valid.
Default is undef (indicating all characters are valid)

=item silent

Specifies if caller wants progress messages printed to STDERR while formatting.
Default is false, meaning not silent.

=back

=cut


sub formatdb {
    # Niels Larsen, November 2005.
    # Todd Z. DeSantis, July 2010

    my ( $self, $cl_args) = @_;
    $self->_check_arguments_for_formatdb($cl_args);

    # Returns an integer.

    my ( $data_fh, $bin_fh, $entry, @seq_oligos, $oligos, $oli2seqoffs, 
         $seqnum, $oligo, @sids, $sids, $bytstr, $begpos,
         $seqtot, $bytlen, $olibeg, 
         $oli_counts, $id, $seq, $count, $all_begpos, $all_bytlen, 
         $valid_chars, $lastnums, $lastnum, @seqoffs, $off, @seqnums,
	 $id_len);
    ## I think I can exlude $lastnums, never written to disk.

    my $cl_wordlen = $self->{param}{wordlen};
    my $cl_silent = $self->{param}{silent}; 
    my $cl_binary = $self->{param}{binary};
    my $cl_data = $self->{param}{data};
    print "cl_data: $cl_data\n"  unless ($cl_silent);
    print "cl_binary: $cl_binary\n" unless ($cl_silent);
    
    
    # Find the number of sequences and the longest length identifier,
    print "Counting new fasta records and measuring size of identifiers... " if not $cl_silent;   
    $seqtot = _count_records($cl_data); 
    print "found $seqtot\n" if not $cl_silent;
        
    $seqnum = 0;
    $oli_counts = "";
    $valid_chars = $self->{param}{valid_chars};
    $id_len = 0;  # init

    $data_fh = new IO::File $self->{param}{data}, "r";
	
    {
        local $/ = '>';
        print "Mapping sub-sequences ... \n" unless ($cl_silent);
        while ( <$data_fh> ) {
            next if ($_ eq '>'); # toss the first empty record 
            chomp $_;
                        
            my ($header, @seq_lines) = split /\n/, $_;
            my ($id) = split /\s/, $header;
	    my $sequence = '';
	    if ($self->{param}{pre_subst} == 1) {
		$sequence = join '', @seq_lines;
		$sequence =~ s/[\.\-\s]//g;
	    } elsif ($self->{param}{pre_subst} == 2) {
		$sequence = join '_', @seq_lines;
		$sequence =~ s/[\.\-\s]/_/g;
	    }
	    next unless ($id && $sequence);
            
	    push @sids, $id;
	       # format to a uniform character length AFTER longest is found
	    $id_len = length($id) if (length($id) > $id_len);

	    @seq_oligos = _create_oligos( $sequence, $cl_wordlen, $valid_chars);
	                    
            foreach $oligo ( @seq_oligos ) {
                if ( exists $oli2seqoffs->{ $oligo } ) {
                    $lastnum = $lastnums->{ $oligo };   ## I think I can exlude $lastnums, never written to disk.
                    $oli2seqoffs->{ $oligo } .= ",". ($seqnum - $lastnum);
		       # Keep track of the hops needed to find this oligo in the seqnums
                } else {
                    $oli2seqoffs->{ $oligo } = $seqnum;
                }

                $lastnums->{ $oligo } = $seqnum;
		  # keep track of the last $seqnum in which this $oligo was found.
		 ## I think I can exlude $lastnums, never written to disk.

	    }

            $oli_counts .= ",". ( scalar @seq_oligos );
	    # string-encoded ordered list of count of unique oligos in each seqnum

            $seqnum++;
            if ( !$cl_silent && $seqnum % 5000 == 0 ) {
                print "$seqnum done of $seqtot ," .  
		    scalar(keys %{ $oli2seqoffs }) . " unique kmers found ...\n";
		# this message is accurate since we just incremented 
		# $seqnum.  So if we just finshed index 4 (which is the 
		# fifth sequence, then $seqnum would have a value of 5"
            }
        }
    }
    
    $seqtot = $seqnum;
      # this is true since $seqnum was incremented after last sequence

    if ( not $cl_silent ) 
    {
        print "Total sequence count: $seqnum of $seqtot ," .
	   scalar(keys %{ $oli2seqoffs }) . " unique kmers found.\n";
    }        
    $data_fh->close;
  
    
    $self->{db_string_count} = $seqnum;
    $self->{unique_kmer_count} = scalar(keys %{ $oli2seqoffs });

    # Write binary file. We write binary representations using syswrite
    # and save the word length and number of sequences (the rest can be
    # calculated)

    eval { $bin_fh = IO::File->new( $cl_binary, 'w' ) };
    if ($@) {
	print STDERR $@;
        # such as: your vendor has not defined Fcntl macro O_LARGEFILE
        if ( not $bin_fh = new IO::File $cl_binary, "w") {
    
            print STDERR "Could not syswrite-open file $cl_binary\n";
	    exit;
        }
    }
    # print STDERR Dumper($bin_fh);
    unless (defined $bin_fh) {
	print STDERR "A filehandle to $cl_binary has not been defined\n";
	exit;
    }

    if ( not $cl_silent ) {
        print "Total number of unique oligos: " . scalar(keys %{ $oli2seqoffs } ) . "\n";
        print "Writing oligo map to file ...\n";
    }

    # Id length, word_length, and total number of sequences,

    $bytstr = pack "A10", $id_len;  # the max_length is encoded as text
    syswrite $bin_fh, $bytstr;

    $bytstr = pack "A10", $cl_wordlen;
    syswrite $bin_fh, $bytstr;

    $bytstr = pack "A10", $seqtot;
    syswrite $bin_fh, $bytstr;

    # Short ids as a string of fixed-length character words,
    $bytstr = pack "A$id_len" x $seqtot, @sids;
    syswrite $bin_fh, $bytstr;

    # Write byte strings of matching sequence numbers, while keeping
    # track of their byte position offsets,
    $begpos = sysseek $bin_fh, 0, 1;   # recommended "systell", perl book says
    $begpos = 0 if ($begpos =~ /^0/);  # sometimes $begpos gets set from sysseek as "0 but true"
                                       # I think this has something to do with not using the Fcntl
                                       # flags: O_WRONLY|O_CREAT|O_EXCL|O_LARGEFILE
                                       # since this behavoir emerged when I stopped using them.
                                       # BUT, I expect sysseek to return a positive int 
                                       # since many bytes have been already written to this filehandle.
                
    @seq_oligos = ();

    $all_begpos = "";
    $all_bytlen = "";

    $count = 0;
    
    foreach $oligo ( sort(keys %{ $oli2seqoffs }) ) # "sort" added by tzd  Apr-11-2008
    {
	
        @seqoffs = eval $oli2seqoffs->{ $oligo }; 
	# print STDERR '@seqoffs:' . join(',', @seqoffs) . "\n";

        @seqnums = shift @seqoffs;
	
	
        foreach $off ( @seqoffs )
        {
            push @seqnums, $seqnums[-1] + $off;
	    # -1 looks-up the value of the last element in the @seqnums
	    	    
        }
	# print STDERR '@seqnums:' . join(',', @seqnums) . "\n";
	
        $bytstr = pack "I*", @seqnums;  # unsigned integers
	                                # the rest of this module
	                                # assumes that integers will
	                                # be 4-byte which is a fairly
	                                # safe assumption
        syswrite $bin_fh, $bytstr;
        
        $bytlen = length $bytstr;

        $all_begpos .= ",$begpos";
        $all_bytlen .= ",$bytlen";
        
        $begpos += $bytlen;

        delete $oli2seqoffs->{ $oligo };

        push @seq_oligos, $oligo;

        $count += 1;
    }

    $oli2seqoffs = {};

    $olibeg = $begpos;

    # Write the oligos found, 

    $bytstr = pack "A$cl_wordlen" x ( scalar @seq_oligos ), @seq_oligos;
    syswrite $bin_fh, $bytstr; 

    # The begin positions of the corresponding run of sequence indices,
    # and their lengths,
    
    $all_begpos =~ s/^,//;  # get rid of initial comma
    $bytstr = pack "I*", eval $all_begpos;    
    syswrite $bin_fh, $bytstr; 

    $all_bytlen =~ s/^,//;
    $bytstr = pack "I*", eval $all_bytlen;
    syswrite $bin_fh, $bytstr; 

    # Store the number of unique oligos for every sequence,

    $oli_counts =~ s/^,//;
    $bytstr = pack "I*", eval $oli_counts;
    syswrite $bin_fh, $bytstr; 
    
    # Finally, we need to store the number of oligos encountered and the
    # byte position of where they were stored,

    $bytstr = pack "A10", scalar @seq_oligos;
    syswrite $bin_fh, $bytstr;
    
    $bytstr = pack "A10", $olibeg;
    syswrite $bin_fh, $bytstr;
    
    $bin_fh->close;

    
    print "format binary file complete\n" unless ($cl_silent);
    return $seqnum;
}

=head2 _check_arguments_for_formatdb

It checks that word length and minimum sequence length is reasonable.
Sets silent to true by default.
Sets pre_subst to 1 by default.
Defines binary file name.
If errors are found, program exits.
Returns a hash or hash ref
depending on the context of the method call.

=cut


sub _check_arguments_for_formatdb {
    # Niels Larsen, May 2004.
    # Todd Z. DeSantis, March 2008.
    my ( $self,
        $cl_args,    # Command Line ARGument hash
                      # not really reqired to come from the command line
         ) = @_;
    
    my ( @errors, $error);
    
    ## see if caller wants to constrain the alphabet
    if ( exists $cl_args->{valid_chars} ) {
	$self->{param}{valid_chars} = $cl_args->{valid_chars};
    } else {
	$self->{param}{valid_chars} = undef;
    }

    ## see if caller wants to make some pre-substitutions
    if ( exists $cl_args->{pre_subst} ) {
	$self->{param}{pre_subst} = $cl_args->{pre_subst};
    } else {
	$self->{param}{pre_subst} = 1;
    }

        # Ensure mininum sequence length is 1 or more and fill in 50 
    # if user didnt specify it
    if ( $cl_args->{"minlen"} )
    {
        if ( $cl_args->{"minlen"} < 1 ) {
            push @errors, qq (Minimum sequence length should be 1 or more);
        }
    }
    else {
        $cl_args->{"minlen"} = 50;
    }
    $self->{param}{minlen} = $cl_args->{"minlen"};

    # Ensure word length is over 0 and less than 
    # or equal to minlen and fill in 7 if the
    # user didnt specify it,
    if ( $cl_args->{"wordlen"} ) {
        if ( $cl_args->{"wordlen"} < 1 ) {
	    push @errors, qq (Word length should be at least 1);
	}
	if ( $cl_args->{"wordlen"} > $cl_args->{"minlen"} ) {
            push @errors, qq (Word length no greater than the minlen);
        }
    } else {
        $cl_args->{"wordlen"} = 7;
    }
    $self->{param}{wordlen} = $cl_args->{"wordlen"};

    if ( not defined $cl_args->{"silent"} ) {
        $cl_args->{"silent"} = 0
    }
    $self->{param}{silent} = $cl_args->{"silent"};
    
    # Print errors if any and exit,
    if ( @errors )
    {
        foreach $error ( @errors )
        {
            print STDERR "$error\n";
	}
        
        exit;
    }
    else {
        wantarray ? return %{ $cl_args } : return $cl_args;
    }

}

=head2 match_oligos({query => $path})

  $sr->match_oligos({query => 'query.fasta'});
  $sr->match_oligos({ query => 'query.fasta',
                      outlen => 10,
                      minpct => 95,
                      reverse => 1,
                      outfile => '/home/donny/sr_results.txt',
                    });
  
  my $matches = $sr->match_oligos({query => 'query.fasta'});
  print Dumper($matches);
  foreach my $k (keys %{$matches} ) {
    print "matches for $k :\n";
    foreach my $hit ( @{ $matches->{$k} } ) {
      print "hit id:" . $hit->[0] . " perc:" . $hit->[1] . "\n";
    }
  }  
    
This routine quickly estimates the overall similarity between
a given set of DNA or RNA sequence(s) and a background set  
of database sequences (usually homologues). 
It returns a sorted list of similarities as a 
table. The similarity between sequences A and B are the number
of unique k-words (short subsequence) that they share, divided
by the smallest total unique k-word count in either A or B. The result
are scores that do not depend on sequence lengths. When 
called in void context, the routine prints to the given output
file or STDOUT; otherwise a hash_ref is returned. 

Parameters:

=over 4

=item query

Sets the path where the query fasta file will be found.
Required.  In future versions, query could be a data structure instead. 
Need to build an abstract iterator for this feature to be enabled.

=item minpct

A real number indicating the  the minimum percent match that should 
be output/returned.
Default = 50.

=item outlen

An integer indicating  the maximum number of ranked db matches that
should be output/returned.
Default = 100.

=item valid_chars

Specifies the characters to allow for kmer-searching.  Entire n-mer must be composed
of these characters otherwise it will be ignored. When not defined, all 
characters are valid.
Default is undef (indicating all characters are valid)

=item reverse 

A boolean value. If true, reverses input sequence.
Default = false.

=item noids

A boolean value. If true, prints database index numbers instead of sequence ids.
Default = false.

=item outfile

Sets the path of the output file (instead of sending to STDOUT).
Default = false.  Meaning output is sent to STDOUT.

=item silent

Specifies if caller wants progress messages printed to STDERR while matching.
Default is false, meaning not silent.

=back

=cut


sub match_oligos {
    # Niels Larsen, May 2004.
    # Todd Z. DeSantis, March 2008.

    my ( $self,
        $cl_args,    # Arguments hash
         ) = @_;
    $self->_check_arguments_for_match_oligos($cl_args);
    # Returns a list of matches if not called in void context.

    my ( $q_seqs, $count, $silent, @sids, $wordlen, $seqnum, $bin_fh, 
         $query_fh, $bytstr, $olinum, $length, @oligos, $oligo, @scores,
         $oli2seqnums, $vector, @begpos, @endpos, $oli2pos, $i, @seqnums,
         $j, $seqtot, $score, @lengths, @temp, $valid_chars, $minscore,
         $olibeg, $olitot, $begpos, $endpos, $pack_bits, @scovec, $scovec, 
         $query_sid, $out_fh, $outdir, $outline, $matches, @oli_counts,
         $oli_count, $scovec_null, $index, $outlen, $pos, $id, $seq,
	 $id_len);

    my $void_context = 1; 
    # Recall 'wantarray' returns 
    # True if the context is looking for a list value,
    # False if the context is looking for a scalar,
    # Undef if the context is looking for no value (void context).
    $void_context = 0 if (defined wantarray);  # caller wants data back

    $silent = $self->{param}{silent};

    # >>>>>>>>>>>>>>>>>>>>>> FILE MAP SECTION <<<<<<<<<<<<<<<<<<<<<<<<

    # This section creates $oli2pos, where each key is a subsequence
    # and values are [ file byte position, byte length to read ]. This
    # map is used below to sum up similarities. 

    eval { $bin_fh = IO::File->new( $self->{param}{binary}, O_RDONLY|O_LARGEFILE ) };
    if ($@) {
        # such as: your vendor has not defined Fcntl macro O_LARGEFILE
        if ( not $bin_fh = new IO::File $self->{param}{binary}, "r") {
    
            print STDERR "Could not open file $self->{param}{binary} for reading\n";
	    exit;
        }
    }

    # Word length and total number of sequences,
    # reminder: sysread FILEHANDLE,SCALAR,LENGTH
    # Attempts to read LENGTH bytes of data into variable SCALAR
    # from the specified FILEHANDLE,
    sysread $bin_fh, $bytstr, 10;
    $id_len = $bytstr * 1;
    
    sysread $bin_fh, $bytstr, 10;
    $wordlen = $bytstr * 1;

    sysread $bin_fh, $bytstr, 10;
    $seqtot = $bytstr * 1;

    # String ids as a string of fixed-length character words,    
    sysread $bin_fh, $bytstr, $seqtot * $id_len;
    @sids = unpack "A$id_len" x $seqtot, $bytstr;  
    
    # Get the oligos and the begin and end positions of where the sequence
    # indices start and their lengths,

    sysseek $bin_fh, -10, 2;   # goto 10 bytes before EOF
    sysread $bin_fh, $bytstr, 10;
    $olibeg = $bytstr * 1;
    
    sysseek $bin_fh, -20, 2;   # goto 20 bytes before EOF
    sysread $bin_fh, $bytstr, 10;
    $olitot = $bytstr * 1;

    sysseek $bin_fh, $olibeg, 0;
    sysread $bin_fh, $bytstr, $olitot * $wordlen;
    @oligos = unpack "A$wordlen" x $olitot, $bytstr;
    
    sysread $bin_fh, $bytstr, 4 * $olitot;
    @begpos = unpack "I*", $bytstr;

    sysread $bin_fh, $bytstr, 4 * $olitot;
    @lengths = unpack "I*", $bytstr;

    sysread $bin_fh, $bytstr, 4 * $seqtot;
    @oli_counts = unpack "I*", $bytstr;

    # Create a hash that returns the file positions of where to get the 
    # matching sequence indices,

    for ( $i = 0; $i < scalar @oligos; $i++ ) {
        $oli2pos->{ $oligos[$i] } = [ $begpos[$i], $lengths[$i] ];
    }

    # >>>>>>>>>>>>>>>>>>>> PROCESS QUERY ENTRIES <<<<<<<<<<<<<<<<<<<<<<<

    if ( $void_context == 1 && $self->{param}{outfile} ) {
	# call was made in void context
        $out_fh = new IO::File $self->{param}{outfile}, "w";
	print "Outfile opened.\n" unless ($self->{param}{silent});
    }

    $query_fh = new IO::File $self->{param}{"query"}, "r";
    $scovec_null = pack "I*", (0) x $seqtot;
    
    $minscore = ( $self->{param}{"minpct"} || 0 ) / 100;

    {
        local $/ = '>';
        while ( <$query_fh>) {
            next if ($_ eq '>'); # toss the first empty record
            chomp $_;
            my ($header, @seq_lines) = split /\n/, $_;
            my ($query_sid) = split /\s/, $header;
	    my $sequence = '';
	    if ($self->{param}{pre_subst} == 1) {
		$sequence = join '', @seq_lines;
		$sequence =~ s/[\.\-\s]//g;
	    } elsif ($self->{param}{pre_subst} == 2) {
		$sequence = join '_', @seq_lines;
		$sequence =~ s/[\.\-\s]/_/g;
	    }	    
            
	    next unless ($query_sid && $sequence);
 
            if ( $self->{param}{"reverse"} ) {
                $sequence = reverse $sequence;
            }

            print "Processing $query_sid ... \n" unless  ( $silent );

            $scovec = $scovec_null;

            # >>>>>>>>>>>>>>>>>>>>>> COUNTING SECTION <<<<<<<<<<<<<<<<<<<<<<<<

            # Look up the sequences that contain each of the oligos found
            # in the sequence. The sort makes the disk jump around less, 
            # since the oligos were written in sorted order to the bin file
	
            @oligos = _create_oligos( $sequence, $wordlen, $self->{param}{valid_chars} );

            foreach $oligo ( sort @oligos ) {  # "sort" added by tzd  Apr-11-2008
                
                if ( defined ( $pos = $oli2pos->{ $oligo }->[0] ) ) {
                    sysseek $bin_fh, $pos, 0;
            
                    $length = $oli2pos->{ $oligo }->[1];
                    sysread $bin_fh, $bytstr, $length;

		    # $bytstr is a perl string. Every 4-byte block
		    # in this string encodes a 4 byte integer 
		    # so >4 billion integers are available. 
		    # but when passed to C
                    # it will be an integer array.

                    # This is a C function for speed, the code is at the end of this 
                    # file. The third argument is the maximum index of $bytstr array,
                    
		    ####### testing only
		    # print STDERR join (',', (unpack "I*", $scovec)) . "\n";
		    # print STDERR join (',', (unpack "I*", $bytstr)) . "\n";
		    #######

                    &update_scores_C( \$bytstr, \$scovec, ( $length - 1 ) / 4 );
		    
		    ####### testing only
		    # print STDERR '$query_sid:' . $query_sid .
		    #	' $oligo:' . $oligo . "\n" . 
		    #	Dumper(unpack "I*", $scovec) . "\n";
		    ####### 
                }
            }
        
            @scovec = unpack "I*", $scovec;

            # >>>>>>>>>>>>>>>>>>>>>> EXTRACT OUTPUT DATA <<<<<<<<<<<<<<<<<<<<<<

            # The score vector, @scovec, now contains integer scores in some 
            # slots, zeros in others. To get an ordered list of just the positive 
            # scores we could grep and sort, but that would be slow because the
            # list is long. Instead, keep a list of scores that is only as long
            # as the output length; insert values that are higher than the last
            # element and ignore the rest,

            $oli_count = scalar @oligos;
            $outlen = $self->{param}{"outlen"};

            @scores = ();   

            for ( $i = 0; $i < scalar @scovec; $i++ )
            {
                if ( $scovec[$i] ) {
		    
		    #### use for testing 
		    # print STDERR '$oli_count:' . $oli_count . '  $oli_counts[$i]:' . $oli_counts[$i] . '  $scovec[$i]:' . $scovec[$i] . "\n";
		    #####
		    
                    if ( $oli_count < $oli_counts[$i] ) {
                        $score = $scovec[$i] / $oli_count;
                    } else {
                        $score = $scovec[$i] / $oli_counts[$i];
                    }

                    if ( $score >= $minscore )
                    {
                        if ( scalar @scores < $outlen )
                        {
                            $index = _nearest_index( \@scores, $score );
                            splice @scores, $index, 0, [ $i, $score ];
                        }
                        elsif ( $score > $scores[0]->[1] )
                        {
                            $index = _nearest_index( \@scores, $score );
                            splice @scores, $index, 0, [ $i, $score ];
                            shift @scores;
                        }
                    }
                }
            }

            if ( $cl_args->{"noids"} ) {
               foreach $score ( @scores ) {
                   $score->[1] = sprintf "%.2f", 100 * $score->[1];
                }
            } else {
                foreach $score ( @scores ) {
                    $score->[0] = $sids[ $score->[0] ];
                    $score->[1] = sprintf "%.2f", 100 * $score->[1];
                    # Can we add a percision parameter here ?
                    # may be able to save disk space in the output file by getting
                    # just the 1/10 place for instance
                }
            }

            @scores = reverse @scores;

            # >>>>>>>>>>>>>>>>>>>>>> OUTPUT SECTION <<<<<<<<<<<<<<<<<<<<<<<<<

            # If called in non-void context, generate a data structure. If 
            # in void context, print tabular data to stdout or an output file
            # if specified,

            if ( $void_context == 0 ) {
		# means caller wants a scalar back
		# which will be a hash ref
                $matches->{ $query_sid } = &Storable::dclone( \@scores );
	    } else {
                $outline = "$query_sid\t" . join "\t", map { $_->[0] .":". $_->[1] } @scores;
    
                if ( defined $out_fh ) {
                    print $out_fh "$outline\n";
                } else {
                    print "$outline\n";
                }
            }

            unless ( $silent ) {
                print "$query_sid done\n";    
                # &Common::Messages::echo_green( qq (done\n) );
            }
        } # end while query_fh
    } # end local block
    $query_fh->close;
    $bin_fh->close;
    
    # Return data structure if non-void context, otherwise nothing,
    if ( $void_context == 0 ) {
	# means caller wants a scalar back
        return $matches;
    } else {
        return;
    }
}

=head2 _check_arguments_for_match_oligos

Internally used function.
Validates the arguments for outlen, minpct, reverse,
query, noids, silent, pre_subst and output.
If errors are found, program exits.
Returns a hash or hash ref
depending on the context of the method call.

=cut

sub _check_arguments_for_match_oligos {
    # Niels Larsen, May 2004.
    # Todd Z. DeSantis, March 2008.
    my ( $self,
        $cl_args,    # Command Line ARGument hash
                      # not really reqired to come from the command line
         ) = @_;
    
    my ( @errors, $error, $outdir );
    
    ## see if caller wants to constrain the alphabet
    if ( exists $cl_args->{valid_chars} ) {
	$self->{param}{valid_chars} = $cl_args->{valid_chars};
    } else {
	$self->{param}{valid_chars} = undef;
    }

    ## see if caller wants to make some pre-substitutions
    if ( exists $cl_args->{pre_subst} ) {
	$self->{param}{pre_subst} = $cl_args->{pre_subst};
    } else {
	$self->{param}{pre_subst} = 1;
    }

    # Ensure output list has at least one similarity in it and set
    # it to 100 if the user didnt specify it,
    
    if ( $cl_args->{"outlen"} )
    {
        if ( $cl_args->{"outlen"} < 1 ) {
            push @errors, qq (Output list length should be 1 or more);
        }
    }
    else {
        $cl_args->{"outlen"} = 100;
    }
    $self->{param}{outlen} = $cl_args->{"outlen"};
    
    if ($cl_args->{"minpct"} ) {
        $self->{param}{minpct} = $cl_args->{"minpct"};
    }  else {
        $self->{param}{minpct} = 0;
    }
    
    if ($cl_args->{reverse}) {
        $self->{param}{"reverse"} = $cl_args->{reverse};
    } else {
        $self->{param}{"reverse"} = 0;
    }
    # The mandatory query:
    # must be a file path
    # in the future, allow a hash ref of the structure
    # $hr->{$id} = $sequence_string
    
    # if file given, 
    # check that its readable. If not given, error,
    if ( $cl_args->{"query"} ) {
        # $cl_args->{"query"} = &Common::File::full_file_path( $cl_args->{"query"} );
        
        if ( not -r $cl_args->{"query"} ) {
            push @errors, qq (Query file not found or not readable -> "$cl_args->{'query'}");
        }
    }
    else {
        push @errors, qq (Query sequence file must be specified);
    }
    $self->{param}{query} = $cl_args->{"query"};
    
    # If output file given, check if it exists and if its directory
    # does not exist
    if ( $cl_args->{"outfile"} ) {
        
        if ( -e $cl_args->{"outfile"} )        {
            push @errors, qq (Output file exists -> "$cl_args->{'outfile'}");
        }

        $outdir = File::Basename::dirname( $cl_args->{"outfile"} );

        if ( not -d $outdir ) {
            push @errors, qq (Output directory does not exist -> "$outdir");
        } elsif ( not -w $outdir ) {
            push @errors, qq (Output directory is not writable -> "$outdir");
        }           
    } else {
        $cl_args->{"outfile"} = "";
    }
    $self->{param}{outfile} = $cl_args->{"outfile"};
    # print STDERR 'outfile:' . $self->{param}{outfile} . "\n"; 

    if ( defined $cl_args->{"silent"} ) {
        $self->{param}{silent} = $cl_args->{"silent"};
    }
    if ( not defined $self->{param}{silent}) {
        $self->{param}{silent}  = 1;
    }
    
    # Print errors if any and exit,

    if ( @errors )
    {
        foreach $error ( @errors )
        {
            print STDERR "$error\n";
            # &Common::Messages::echo_red( "ERROR: ");
            # &Common::Messages::echo( "$error\n" );
        }
        
        exit;
    }
    else {
        wantarray ? return %{ $cl_args } : return $cl_args;
    }

}

=head2 _create_oligos

Internal method.
Creates a list of unique words of a given length from a given sequence. 
Enforces k-mers composed of purely valid_char if requested.
Converts characters to upper case where possible.  This may become an option
in the future. 

=cut


sub _create_oligos {
    # Niels Larsen, November 2005.
    # Todd Z. DeSantis, March 2008

    my (  
         $str,        # Sequence string
         $word_len,    # Word length
	 $valid_chars
         ) = @_;
    
 
    my (@oligos, %oligos, $i, $len);
    $str = uc $str;

    my @good_spans = ();
    if ($valid_chars) {
	@good_spans = split (/[^$valid_chars]/, $str);  # pattern match done once
                                                        # instead of for every k-mer
    } else {
	# put whole string as first element
	$good_spans[0] = $str;
    }
    foreach my $good_span (@good_spans) {
	# print STDERR "good_span: $good_span\n";
	my $span_len = length($good_span);
	next if ($span_len < $word_len);
	my $i;
	for ( $i = 0; $i <= $span_len - $word_len; $i++ ) {
            $oligos{ substr $good_span, $i, $word_len } = undef;
	}
    }
        
    @oligos = keys %oligos;
    
    ## use for testing:
  
    #	foreach my $o (@oligos) {
    #	    if ($o =~ /[^ACGT]/) {
    # 		print STDERR $o . "\n";
    #	    }
    #	}
  


    wantarray ? return @oligos : \@oligos;
}

=head2 _nearest_index

Finds the index of a given sorted array where a given number
would fit in the sorted order. The returned index can then
be used to insert the number, for example. The array may 
contain integers and/or floats, same for the number.

=cut

sub _nearest_index
{
    # Niels Larsen, May 2004.
    my ( $array,       # Array of numbers
         $value,       # Lookup value 
         ) = @_;

    # Returns an integer. 

    my ( $low, $high ) = ( 0, scalar @{ $array } );
    my ( $cur );

    while ( $low < $high )
    {
        $cur = int ( ( $low + $high ) / 2 );

        if ( $array->[$cur]->[1] < $value ) {
            $low = $cur + 1;
        } else {
            $high = $cur;
        }
    }

    return $low;
}

=head2 _count_records

Counts the number of records in a fasta formated file.

=cut

sub _count_records
{
    # Todd Z. DeSantis, July 2010.
    my ( $fasta_file ) = @_;

    # Returns an integer. 
    my $c = 0;
    my $ffh = new IO::File $fasta_file, "r";
    while (<$ffh>) {
	$c++ if ($_ =~ /^\>/);
    }
    $ffh->close;
    return $c;
}


1;

=head2 _update_scores_C

Receives a list of indicies, score vector, and the final index
Updates the score vector by incrementing the oligo
  match count for the correct sequences.

=cut

__DATA__

=pod

=cut

__C__

/* Niels Larsen, May 2004. */

static void* get_ptr( SV* obj ) { return SvPVX( SvRV( obj ) ); }
  /* A sub which takes as input the ScalarVector pointer.
     Returns a C string.
     The SvPVX function is part of the Perl internal API 
      and converts SV* to a C string
    SvRV dereferences a SV when its a perl reference
  */

// define four macros for compiler to substitute where needed:
#define DEF_SCOPTR( str )  int* scoptr = get_ptr( str )
    // receives a SV, returns scoptr: a pointer to an integer
#define DEF_NDXPTR( str )  int* ndxptr = get_ptr( str )
    // receives a SV, returns ndxptr: a pointer to an integer
#define FETCH( idx )       ndxptr[ idx ]
    // receives an integer, looks up an array element in nxptr
#define INCR( idx )        scoptr[ idx ]++
    // receives an integer, increments the corresponding array element in scoptr

void update_scores_C( SV* ndxstr, SV* scovec, int maxndx )
{
    DEF_NDXPTR( ndxstr );
    DEF_SCOPTR( scovec );

    int i;

    for ( i = 0; i <= maxndx; i++ ) 
    {
        INCR( FETCH(i) ); 
    }
}

/* helps test the InlineC connection. */
int add(int x, int y) {
    return x + y;
}

int subtract(int x, int y) {
    return x - y;
}
__END__

