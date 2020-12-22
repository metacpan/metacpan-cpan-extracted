package Net::NfDump;

use 5.000001;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;
use if $] <  5.014000, Socket  => qw(inet_aton AF_INET);
use if $] <  5.014000, Socket6 => qw(inet_ntop inet_pton AF_INET6);
use if $] >= 5.014000, Socket  => qw(inet_ntop inet_pton inet_aton AF_INET6 AF_INET);
use Net::NfDump::Fields;
use threads;

our @ISA = qw(Exporter);

our $VERSION = '1.29';

# XXX
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::NfDump ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	ip2txt txt2ip 
	mac2txt txt2mac
	family2txt txt2family
	mpls2txt txt2mpls
	flow2txt txt2flow 
	file_info 
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);


sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Net::NfDump::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Net::NfDump', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

# Below is stub documentation for your module. You'd better edit it!

# how to convert particular type to 
my %CVTTYPE = ( 
	'ip' => 'ip', 'srcip' => 'ip', 'dstip' => 'ip', 'nexthop' => 'ip', 'bgpnexthop' => 'ip', 'router' => 'ip',
	'net' => 'ip', 'srcnet' => 'ip', 'dstnet' => 'ip', 'routerip' => 'ip', 'nextip' => 'ip',
	'insrcmac' => 'mac', 'outsrcmac' => 'mac', 'indstmac' => 'mac', 'outdstmac' => 'mac',
	'mpls' => 'mpls',
	'xsrcip' => 'ip', 'xdstip' => 'ip', 'nsrcip' => 'ip', 'ndstip' => 'ip',
	'inetfamily' => 'family' );

=head1 NAME

Net::NfDump - Perl API for manipulating with nfdump files based on libnf.net library 

=head1 SYNOPSIS

  use Net::NfDump;

  #
  #
  # Example 1: reading nfdump file(s)
  # 
  
  $flow = new Net::NfDump(
              InputFiles => [ 'nfdump_file1', 'nfdump_file2' ], 
              Filter => 'icmp and src net 10.0.0.0/8',
              Fields => 'proto, bytes' ); 

  $flow->query();

  while (my ($proto, $bytes) = $flow->fetchrow_array() )  {
      $h{$proto} += $bytes;
  }
  $flow->finish();

  foreach ( keys %h ) {
      printf "%s %d\n", $_, $h{$_};
  }

  #
  #
  # Example 2: reading nfdump file(s) with aggregation and sorting
  # 
  
  $flow = new Net::NfDump(
              InputFiles => [ 'nfdump_file1', 'nfdump_file2' ], 
              Filter => 'icmp and src net 10.0.0.0/8',
              Fields => 'srcip/24/64, bytes', 
              Aggreg => 1, OrderBy => "bytes" ); 

  $flow->query();

  while (my ($ip, $bytes) = $flow->fetchrow_array() )  {
      printf "%s %d\n", $ip, $bytes;
      $h{$proto} += $bytes;
  }
  $flow->finish();


  #
  #
  # Example 3: creating and writing records to nfdump file
  #
  
  $flow = new Net::NfDump(
              OutputFile => 'output.nfcap',
              Fields => 'srcip,dstip' );

  $flow->storerow_arrayref( [ txt2ip('147.229.3.10'), txt2ip('1.2.3.4') ] );

  $flow->finish();


  #
  #
  # Example 4: reading/writing (merging two input files) and swap
  #            source and destination address if the destination port 
  #            is 80/http (I know it doesn't make much sense).
  #

  $flow1 = new Net::NfDump( 
               InputFiles => [ 'nfdump_file1', 'nfdump_file2' ], 
               Fields => 'srcip, dstip, dstport' ); 

  $flow2 = new Net::NfDump( 
               OutputFile => 'nfdump_file_out', 
               Fields => 'srcip, dstip, dstport' ); 

  $flow1->query();
  $flow2->create();

  while (my $ref = $flow->fetchrow_arrayref() )  {

      if ( $ref->[2] == 80 ) { 
          ($ref->[0], $ref->[1]) = ($ref->[1], $ref->[0]);
      }

     $flow2->clonerow($flow1);
     $flow2->storerow_arrayref($ref);

  }

  $flow1->finish();
  $flow2->finish();




=head1 DESCRIPTION

Nfdump L<http://nfdump.sourceforge.net/> is a very popular toolset 
for collecting, storing and processing NetFlow/SFlow/IPFIX data. 
One of the key tools is a command line utility bearing the same name
as the whole toolset (nfdump). Although this utility can process data 
very fast, it is cumbersome for some applications. 

This module implements basic operations and allows to 
read, create and write flow records on binary files produced
with nfdump tool. The module tries to keep the same naming conventions for 
methods as are used in DBI modules/API, so developers who 
got used to work with such interface should remain familiar with the new one. 

The module uses the original nfdump sources to implement necessary 
functions. This enables to keep the compatibility with the original 
nfdump quiet easily and to cope with future versions of the nfdump tool with a minimal effort. 

The architecture is following: 

      
          APPLICATION 
   +------------------------+
   |                        |  Implements all methods and functions 
   | Net::NfDump API (perl) |  described in this document.
   |                        |
   +------------------------+
   |                        |  The code converts internal nfdump 
   | libnf - glue code (C)  |  structures into perl and back to C.
   |                        |  See http://libnf.net for more information.
   +------------------------+
   |                        |  All original nfdump source files. There  
   |   nfdump sources (C)   |  are no changes in these files. All  
   |                        |  changes are placed into libnf code.
   +------------------------+  
         NFDUMP FILES


We always try to update Net::NfDump te lastest version of B<nfdump> available on L<https://github.com/phaag/nfdump>. Support for NSEL code is enabled. 

=head1 WARNING FOR VERSION >= 0.13

The files created by Net::NfDump version >= 0.13 can be read only with 
nfdump 1.6.12 and newer. For reading it supports all formats
starting with nfdump 1.6.

=cut 

# converts comma seperated string to array reference 
sub split_str($) {
	my ($arg) = @_;

	if (ref $arg eq 'ARRAY') {
		# already is an array
		return $arg;
	} else {
		my @arr = split(/,\s*/, $arg);
		chomp @arr;
		return \@arr;
	}

}


# merge $opts with class default opts and return the resilt. 

sub merge_opts {
	my ($self, %opts) = @_;

	my $ropts = {};
	while ( my ($key, $val) =  each %{$self->{opts}} ) {
		$ropts->{$key} = $val;

	}

	while ( my ($key, $val) =  each %opts ) {
		if ($key eq "InputFiles" || $key eq "Fields" ) {
			$val = split_str($val);
		}
		$ropts->{$key} = $val;
	}

	return $ropts; 
}

# Internal function to set output items/fields. At the input takes array that 
# represents string names of the files 
sub set_fields {
	my ($self, $fieldsref) = @_;

	$self->{fields_num} = [];
	$self->{fields_txt} = [];

	foreach (@{$fieldsref}) {

		my $fld = lc($_);

		# add all fields
		if ($fld eq '*') {
			push(@{$self->{fields_num}}, values %Net::NfDump::Fields::NFL_FIELDS_TXT );
			push(@{$self->{fields_txt}}, keys %Net::NfDump::Fields::NFL_FIELDS_TXT );
		# regular item 
		} else {

			if ( !defined($Net::NfDump::Fields::NFL_FIELDS_TXT{$fld}) ) {
				croak(sprintf("Unknown field \"%s\".", $_)); 
			}

			push(@{$self->{fields_num}}, $Net::NfDump::Fields::NFL_FIELDS_TXT{$fld});
			push(@{$self->{fields_txt}}, $fld);;
		}
	}

	$self->{NAME} = $self->{fields_txt};
	$self->{NUM_OF_FIELDS} = scalar @{$self->{fields_txt}};

	$self->{opts}->{Fields} = $self->{fields_txt};

	return Net::NfDump::libnf_set_fields($self->{handle}, $self->{fields_num});
}



=head1 METHODS, OPTIONS AND RELATED FUNCTIONS

=head2 Options

Options can be handled by various methods. The basic options can be handled 
by the constructor and then modified by methods such as $obj->query() or $obj->create(). 

The values after => indicate the default value for the item.


=over 

=item * B<InputFiles> => []

List of files to read (arrayref).  

=item * B<Filter> => 'any'

Filter that is applied on input records. It uses nfdump/tcpdump syntax. 

=item * B<Fields> => '*'

List of fields to read or to update. Any supported field can be used 
here. See the chapter "Supported Fields" for the full list.
Special field * can be used to define all fields. 

=item * B<Aggreg> => 0

Create aggregated result. When the method ->query() is called
the library loads data into memory structure and 
perform aggregation according the Fields attribute. 

=item * B<OrderBy> => '<none>'

Sort the final result according the field specified. It can by 
used only for aggregated results. 

=item * B<TimeWindowStart>, B<TimeWindowEnd> => 0

Filter flows that start or end in the specific time window. 
The options use unix timestamp values or 0 if the filter should
not be applied. 

=item *  B<OutputFile> => undef

Output file for storerow_* methods. Default: undef

=item * B<Compressed> => 1

Flag indicating whether the output files should be compressed or not. 

=item * B<Anonymized> => 0

Flag indicating that output file contains anonymized data.

=item * B<Ident> => '' 

String identificator of files. The value is stored in the file header. 

=item * B<CompatMode> => 0

Enable nfdump compatibility features. Some features are implemented differently 
comparing to original nfdump. Currently thi option enables only 
LNF_OPT_COMP_STATSCMP for aggregated statistics computation. 

=back 

=head2 Constructor, status information methods

=over 

=item * B<$obj = new Net::NfDump( %opts )>


  my $obj = new Net::NfDump( InputFiles => [ 'file1']  );


The constructor. It defines the way the parameter options can be specified. 


=cut

sub new {
	my ($self, %opts) = @_;

	my ($class) = {};
	bless($class);

	my $handle = Net::NfDump::libnf_init();

	if (!defined($handle) || $handle == 0) {
		return undef;
	} 

	$class->{opts} = { 
		InputFiles => [],
		Filter => 'any',
		Fields => [ '*' ],
		TimeWindowStart => 0,
		TimeWindowEnd => 0,
		OutputFile => undef,
		Compressed => 1,
		Anonymized => 0,
		Ident => ""
	};

	$class->{opts} = $class->merge_opts(%opts);
		
	$class->{handle} = $handle;	

	$class->{read_prepared} = 0;
	$class->{write_prepared} = 0;
	$class->{closed} = 0;
	$class->{last_hashref_items} = "";

	return $class;
}

=pod

=item * B<< $ref = $obj->info() >>


  my $i = $obj->info();
  print Dumper($i);


informs about the current state of processing input files. It 
returns information about already processed files, blocks and records. The
information may be useful for estimating the time of processing the whole 
dataset. Hashref returns following items:

  total_files           - total number of files to process
  elapsed_time          - elapsed time 
  remaining_time        - estimated remaining time to process all records
  percent               - estimated percentage of processed records
  
  processed_files       - total number of processed files
  processed_records     - total number of processed records
  processed_blocks      - total number of processed blocks
  processed_bytes       - total number of processed bytes 
                          number of bytes read from file 
                          system after uncompressing 
  
  current_filename      - the name of the file currently processed
  current_total_blocks  - the number of blocks in the currently 
                          processed file 
  current_processed_blocks -  the number of processed blocks in the 
                          currently processed file

=cut

sub info {
	my ($self) = @_;

	my $ref =  Net::NfDump::libnf_instance_info($self->{handle}); 

	if ($ref->{'total_files'} > 0 && $ref->{'current_total_blocks'} > 0) {
		my $totf = $ref->{'total_files'};
		my $cp = $ref->{'current_processed_blocks'} / $ref->{'current_total_blocks'} * 100;
		$ref->{'percent'} = ($ref->{'processed_files'}  - 1 )/ $totf * 100 + $cp / $totf;
	}

	if (defined($self->{read_started})) {
		my $etime = time() - $self->{read_started};
		$ref->{'elapsed_time'} = $etime;
		$ref->{'remaining_time'} = $etime / ($ref->{'percent'} / 100) - $etime;
	}

	return $ref;

}


=pod

=item * B<< $obj->finish() >>


  $obj->finish();


closes all open file handles. It is necessary to call the method especially 
when a new file is created. The method flushes the file records which remained in the memory 
buffer and updates file statistics in the header. Without calling this method the 
output file might be corrupted. 

=back

=cut

sub finish {
	my ($self) = @_;

	# handle, row reference
	Net::NfDump::libnf_finish($self->{handle});

	$self->{read_prepared} = 0;
	$self->{write_prepared} = 0;
	$self->{closed} = 1;
}

sub DESTROY {
	my ($self) = @_;

	# handle, row reference
	if (!$self->{closed}) {
		Net::NfDump::libnf_finish($self->{handle});
	}
}

=pod

=head2 Methods for reading data 

=over 

=item * B<< $obj->query( %opts ) >>


  $obj->query( Filter => 'src host 10.10.10.1' );


This method has to be applied before any of the C<fetchrow_*> methods is used. Any option described before can be used as a parameter of the method. 

After executing query command it possible to access $flow->{NUM_OF_FIELDS} and $flow->{NAME} variable to get returnd 
number of fields and field names. Here is an exmaple of code to acces field names: 

    foreach $colno (0..$flow->{NUM_OF_FIELDS}-1) {
        print $flow->{NAME}->[$colno]."\t";
    }

=cut 

# Query method can be used in two ways. If the string argument is the 
# flow query is handled. See section FLOW QUERY how to create flow 
# queries.

# =cut#

sub query {
	my ($self, %opts) = @_;


	my $o = $self->merge_opts(%opts);

	if (@{$o->{InputFiles}} == 0) {
		croak("No input files defined");
	} 

	my @resfields = ();
	foreach my $fld (@{$o->{Fields}}) {
		my $numbits = 0;
		my $numbits6 = 0;
		if (defined($CVTTYPE{$fld}) && $CVTTYPE{$fld} eq 'ip') {
			$numbits = 32;
			$numbits6 = 128;
		} 

		if ($fld =~ /\//) {
			($fld, $numbits, $numbits6) = split(/\//, $fld);
			$numbits6 = $numbits if (!defined($numbits6));
		}
		push(@resfields, $fld);


		if (defined($o->{Aggreg}) && $o->{Aggreg}) {
			if ($fld eq '*') {
				croak("Symbol '*' is not allowed for aggregated items");
			}
		
			if (!defined($Net::NfDump::Fields::NFL_FIELDS_TXT{$fld})) {
				croak("Unknown field $fld");
			}

			my $id = $Net::NfDump::Fields::NFL_FIELDS_TXT{$fld};
#			my $flags = $Net::NfDump::Fields::NFL_FIELDS_DEFAULT_AGGR{$id};
			my $flags = 0;

			if (defined($o->{OrderBy}) && $fld eq $o->{OrderBy}) {
				$flags |= $Net::NfDump::Fields::NFL_FIELDS_DEFAULT_SORT{$id};
			}

			Net::NfDump::libnf_aggr_add($self->{handle}, $id, $flags, 
				$numbits, $numbits6);
		} elsif (defined($o->{OrderBy}) && $fld eq $o->{OrderBy}) {
			# sorting in list mode 

			my $id = $Net::NfDump::Fields::NFL_FIELDS_TXT{$fld};
			my $flags = $Net::NfDump::Fields::NFL_FIELDS_DEFAULT_SORT{$id};
			Net::NfDump::libnf_aggr_add($self->{handle}, $id, $flags, 
				$numbits, $numbits6);

			Net::NfDump::libnf_listmode($self->{handle});
		}

	}

	$self->set_fields([ @resfields ]);

	if (defined($o->{CompatMode}) && $o->{CompatMode}) {
		Net::NfDump::libnf_compatmode($self->{handle});
	}


	# handle, filter, windows start, windows end, ref to filelist 
	Net::NfDump::libnf_read_files($self->{handle}, $o->{Filter}, 
				$o->{TimeWindowStart}, $o->{TimeWindowEnd}, 
				$o->{InputFiles});	

	$self->{read_prepared} = 1;
	$self->{read_started} = time();

}

=pod 

=item * B<< $ref = $obj->fetchrow_arrayref() >>


  while (my $ref = $obj->fetchrow_arrayref() ) {
      print Dumper($ref);
  }


This method has to be used after the query method. The method $obj->query() is called 
automatically if it has not been called before. 

It returns array reference with the record and skips to next record. It returns 
"true" if there are more records to read or "undef" if the end of a record set has been reached. 

=cut

sub fetchrow_arrayref {
	my ($self) = @_;

	if (!$self->{read_prepared}) {
		$self->query();
	}

	my $ret = Net::NfDump::libnf_read_row($self->{handle});

	#the end of the file/files we set back read prepared to 0
	if (!$ret) {
		$self->{read_prepared} = 0;
	}

	return $ret;
}

=pod 

=item * B<< @array = $obj->fetchrow_array() >>


  while ( @array = $obj->fetchrow_arrayref() ) { 
    print Dumper(\@array);
  }


It has the same function as fetchrow_arrayref; however, it returns items in array instead.

=cut 

sub fetchrow_array {
	my ($self) = @_;

	my $ref = $self->fetchrow_arrayref();

	return if (!defined($ref));

	return @{$ref};
}

=pod 

=item * B<< $ref = $obj->fetchrow_hashref() >>


  while ( $ref = $obj->fetchrow_hashref() ) {
     print Dumper($ref);
  }


The same case as fetchrow_arrayref; however, the items are returned in the hash reference as the 
key => vallue tuples. 

NOTE: This method can be very ineffective in some cases, please, see PERFORMANCE section.

=back 

=cut

sub fetchrow_hashref {
	my ($self) = @_;

	my %res;
	my $ref = $self->fetchrow_arrayref();

	return if (!defined($ref));
 
	my $numfields = scalar @{$self->{fields_txt}};	
	for (my $x = 0; $x <  $numfields; $x++) {
		$res{$self->{fields_txt}->[$x]} = $ref->[$x] if defined($ref->[$x]);
	}

	return \%res;
}

=pod

=head2 Methods for writing data 

=over 

=item * B<< $obj->create( %opts ) >>


  $obj->create( OutputFile => 'output.nfcapd' );


This method creates a new nfdump file and has to be applied before any of $obj->storerow_* 
method is called. 

=cut 

sub create {
	my ($self, %opts) = @_;

	my $o = $self->merge_opts(%opts);

	if (!defined($o->{OutputFile}) || $o->{OutputFile} eq "") {
		croak("No output file defined");
	} 

	$self->set_fields($o->{Fields});

	# handle, filename, compressed, anonyized, identifier 
	Net::NfDump::libnf_create_file($self->{handle}, 
		$o->{OutputFile}, 
		$o->{Compressed},
		$o->{Anonymized},
		$o->{Ident});

	$self->{write_prepared} = 1;
}

=pod 

=item * B<< $obj->storerow_arrayref( [ @array ] ) >>


  $obj->storerow_arrayref( [ $srcip, $dstip ] );


The method inserts data defined in arrayref to the file opened by the method $obj->create(). The number of 
fields and their order have to follow the order defined in the B<Fields> option 
handled during $obj->new() or $obj->create() method. 

=cut

sub storerow_arrayref {
	my ($self, $row) = @_;

	if (!$self->{write_prepared}) {
		$self->create();
	}

	return Net::NfDump::libnf_write_row($self->{handle}, $row);
}

=pod

=item * B<< $obj->storerow_array( @array ) >>


  $obj->storerow_array( $srcip, $dstip );


The same case as storerow_arrayref; however, the items are handled as a single array. 

=cut

sub storerow_array {
	my ($self, @row) = @_;

	return $self->storerow_arrayref(\@row);
}

=pod

=item * B<< $obj->storerow_hashref ( \%hash ) >>


  $obj->storerow_hashref( { 'srcip' =>  $srcip, 'dstip' => $dstip } );


It inserts the structure defined as hash reference into output file. 

NOTE: This method can be very ineffective in some cases, please, see PERFORMANCE section.

=cut

sub storerow_hashref {
	my ($self, $row) = @_;

	return undef if (!defined($row));

	if (join(',', keys %{$row}) ne $self->{last_hashref_items}) {
		$self->set_fields( [ keys %{$row} ] );
		$self->{last_hashref_items} = join(',', keys %{$row});
	}

	return $self->storerow_arrayref( [ values %{$row} ] );
	
}

=pod

=item * B<< $obj->clonerow( $obj2 ) >>


  $obj->clonerow( $obj2 );


This method copies the full content of the row from the source object (instance). This method 
is useful for writing effective scripts. See above the PERFORMANCE chapter. 

=back

=cut

sub clonerow {
	my ($self, $obj) = @_;

	return undef if ( !defined($obj) || !defined($obj->{handle}) );

	if (!$self->{write_prepared}) {
		$self->create();
	}

	return Net::NfDump::libnf_copy_row($self->{handle}, $obj->{handle});
}

=pod

=head2 Extra conversion and support functions

The module also provides extra convertion functions which allow to convert binnary format 
of IP address, MAC address and MPLS labels tag into text format and back. 

Those functions are not exported by default, therefore it has to be either called 
with full module name or imported when the module is loaded. To import
all support function C<:all> a synonym may be used. 
 
  use Net::NfDump qw ':all';

=over 

=item * B<< $txt = ip2txt( $bin ) >>

=item * B<< $bin = txt2ip( $txt ) >>


  $ip = txt2ip('10.10.10.1');
  print ip2txt($ip);


Converts both IPv4 and IPv6 addresses into text form and back. The standard 
inet_ntop/inet_pton functions can be used instead to provide the same results. 

Function txt2ip returns binnary format of IP address or "undef"
if the conversion is not possible. 

=cut 

sub ip2txt ($) {
	my ($addr) = @_;

	if (!defined($addr)) {
		return undef;
	}

	my $type;

	if (length($addr) == 4) {
		$type = AF_INET;
	} elsif (length($addr) == 16) {
		$type = AF_INET6;
	} else {
		carp("Invalid IP address length in binary representation");
		return undef;
	}

	return inet_ntop($type, $addr);
}


sub txt2ip ($) {
	my ($addr) = @_;
	my $type;

	if (!defined($addr)) {
		return undef;
	}

	if (index($addr, ':') != -1) {
    	return inet_pton(AF_INET6, $addr);
	} else {
		# ubuntu have buggy implementation of inet_pton for IPv4 
    	return inet_aton($addr);
	}

}

=pod

=item * B<< $txt = mac2txt( $bin ) >>

=item * B<< $bin = txt2mac( $txt ) >>


  $mac = txt2mac('aa:02:c2:2d:e0:12');
  print mac2txt($mac);


It converts MAC address to xx:yy:xx:yy:xx:yy format and back. The function mac2txt 
accepts an address of any following format: 

  aabbccddeeff
  aa:bb:cc:dd:ee:ff
  aa-bb-cc-dd-ee-ff
  aabb-ccdd-eeff

It returns the binnary format of an address or "undef" if the conversion is not possible. 

=cut 

sub mac2txt ($) {
	my ($addr) = @_;

	if (!defined($addr)) {
		return undef;
	}

	if (length($addr) != 6) {
		carp("Invalid MAC address length in binary representation");
		return undef;
	}

	return sprintf("%s%s:%s%s:%s%s:%s%s:%s%s:%s%s", split('',unpack("H12", $addr)));
}


sub txt2mac ($) {
	my ($addr) = @_;

	if (!defined($addr)) {
		return undef;
	}

	$addr =~ s/[\-|\:]//g;

	if (length($addr) != 12) {
		return undef;
	}

	return pack('H12', $addr);
}

=pod

=item * B<< $txt = family2txt( $bin ) >>

=item * B<< $bin = txt2family( $txt ) >>


  $fam = txt2family('ipv6');
  print family2txt($fam);


It converts internall address family (AF_INET, AF_INET6) to ipv4 or ipv6 string (or back). 

Function txt2family returns the binnary format of the family representation 
on the particular platform or "undef" if the conversion is not possible. 

=cut 

sub family2txt ($) {
	my ($fam) = @_;

	if (!defined($fam)) {
		return undef;
	}

	if ($fam == AF_INET) {
		return 'ipv4';
	} elsif ($fam == AF_INET6) {
		return 'ipv6';
	} else {
		return undef;
	}
}


sub txt2family ($) {
	my ($fam) = @_;

	if (!defined($fam)) {
		return undef;
	}

	if ($fam eq 'ipv4') {
		return AF_INET;
	} elsif ($fam eq 'ipv6') {
		return AF_INET6;
	} else {
		return undef;
	}
}

=pod

=item * B<< $txt = mpls2txt( $mpls ) >>

=item * B<< $mpls = txt2mpls( $txt ) >>


  $mpls = txt2mpls('1002-6-0 1003-6-0 1004-0-1');
  print mpls2txt($mpls);


It converts label information into format B<Lbl-Exp-S> and back. 

Where:
 
  Lbl - Value given to the MPLS label by the router. 
  Exp - Value of the experimental bit. 
  S   - Value of the end-of-stack bit: Set to 1 for the oldest 
        entry in the stack and to zero for all other entries. 

=cut 

sub mpls2txt ($) {
	my ($addr) = @_;

	if (!defined($addr)) {
		return undef;
	}
	my @res;

	foreach (unpack('I*', $addr)) {

		my $lbl = $_ >> 12;
		my $exp = ($_ >> 9 ) & 0x7;
		my $eos = ($_ >> 8 ) & 0x1;

		push(@res, sprintf "%d-%d-%d", $lbl, $exp, $eos) if ($_ != 0);
	}

	return  join(' ', @res);
}

sub txt2mpls ($) {
	my ($addr) = @_;

	if (!defined($addr)) {
		return undef;
	}

	my $res =  "";

	my @labels = split(/\s+/, $addr); 

	foreach (@labels) {
		my ($lbl, $exp, $eos) = split(/\-/);

		my $label = ($lbl << 12) | ( $exp << 9 ) | ($eos << 8 ); 
		
		$res .= pack("I", $label);	
	}


	$res .= pack("I", 0x0) x (10 - length($res) / 4);	# alogn to 10 items (4 * 10 Bytes) 
	return  $res;
}

=pod

=item * B<< $ref = flow2txt( \%row ) >>

=item * B<< $ref = txt2flow( \%row ) >>


The function flow2txt gets hash reference to the items returned by fetchrow_hashref and 
converts all items into text format readable for human. It applies functions 
ip2txt, mac2txt, mpl2txt to the items for which it makes sense. The function 
txt2flow does the exact opossite.

=cut 

	

sub flow2txt ($) {
	my ($row) = @_;
	my %res;
	
	while ( my ($key, $val) = each %{$row}) {

		if ( defined($CVTTYPE{$key}) ) { 
			my $cvt = $CVTTYPE{$key};
			if ($cvt eq 'ip') {
				$res{$key} = ip2txt($val);
			} elsif ($cvt eq 'mac') {
				$res{$key} = mac2txt($val);
			} elsif ($cvt eq 'family') {
				$res{$key} = family2txt($val);
			} elsif ($cvt eq 'mpls') {
				$res{$key} = mpls2txt($val);
			} else {
				croak("Invalid conversion type $cvt");
			}
		} else {
			$res{$key} = $val;
		}
	}

	return \%res;	
}


sub txt2flow ($) {
	my ($row) = @_;
	my %res;
	
	while ( my ($key, $val) = each %{$row}) {

		if ( defined($CVTTYPE{$key}) ) { 
			my $cvt = $CVTTYPE{$key};
			if ($cvt eq 'ip') {
				$res{$key} = txt2ip($val);
			} elsif ($cvt eq 'mac') {
				$res{$key} = txt2mac($val);
			} elsif ($cvt eq 'family') {
				$res{$key} = txt2family($val);
			} elsif ($cvt eq 'mpls') {
				$res{$key} = txt2mpls($val);
			} else {
				croak("Invalid conversion type $cvt");
			}
		} else {
			$res{$key} = $val;
		}
	}

	return \%res;	
}

=pod 

=item * B<< $ref = file_info( $file_name ) >>


  $ref = file_info('file.nfcap');
  print Dumper($ref);


It reads information from the nfdump file header and provides various attributes 
such as number of blocks, version, flags, statistics, etc.  As the result, the 
following items are returned: 

  version
  ident
  blocks
  catalog
  anonymized
  compressed
  sequence_failures

  first
  last

  flows, bytes, packets

  flows_tcp, flows_udp, flows_icmp, flows_other
  bytes_tcp, bytes_udp, bytes_icmp, bytes_other
  packets_tcp, packets_udp, packets_icmp, packets_other


=back 

=cut

sub file_info {
	my ($file) = @_;

	my $ref =  Net::NfDump::libnf_file_info($file); 

	return $ref;
}

=pod


=head1 SUPPORTED ITEMS 

Up to date list of supported items is available on L<Net::NfDump::Fields>

  Time items
  =====================
  first - Timestamp of the first packet seen (in miliseconds)
  last - Timestamp of the last packet seen (in miliseconds)
  received - Timestamp regarding when the packet was received by collector 

  Statistical items
  =====================
  bytes - The number of bytes 
  pkts - The number of packets 
  outbytes - The number of output bytes 
  outpkts - The number of output packets 
  flows - The number of flows (aggregated) 

  Layer 4 information
  =====================
  srcport - Source port 
  dstport - Destination port 
  tcpflags - TCP flags  

  Layer 3 information
  =====================
  srcip - Source IP address 
  dstip - Destination IP address 
  nexthop - IP next hop 
  srcmask - Source mask 
  dstmask - Destination mask 
  tos - Source type of service 
  dsttos - Destination type of service 
  srcas - Source AS number 
  dstas - Destination AS number 
  nextas - BGP Next AS 
  prevas - BGP Previous AS 
  bgpnexthop - BGP next hop 
  proto - IP protocol  

  Layer 2 information
  =====================
  srcvlan - Source vlan label 
  dstvlan - Destination vlan label 
  insrcmac - In source MAC address 
  outsrcmac - Out destination MAC address 
  indstmac - In destination MAC address 
  outdstmac - Out source MAC address 

  MPLS information
  =====================
  mpls - MPLS labels 

  Layer 1 information
  =====================
  inif - SNMP input interface number 
  outif - SNMP output interface number 
  dir - Flow directions ingress/egress 
  fwd - Forwarding status 

  Exporter information
  =====================
  router - Exporting router IP 
  systype - Type of exporter 
  sysid - Internal SysID of exporter 

  NSEL fields, see: http://www.cisco.com/en/US/docs/security/asa/asa81/netflow/netflow.html
  =====================
  eventtime - NSEL The time that the flow was created
  connid - NSEL An identifier of a unique flow for the device 
  icmpcode - NSEL ICMP code value 
  icmptype - NSEL ICMP type value 
  xevent - NSEL Extended event code
  xsrcip - NSEL Mapped source IPv4 address 
  xdstip - NSEL Mapped destination IPv4 address 
  xsrcport - NSEL Mapped source port 
  xdstport - NSEL Mapped destination port 
 NSEL The input ACL that permitted or denied the flow
  iacl - Hash value or ID of the ACL name
  iace - Hash value or ID of the ACL name 
  ixace - Hash value or ID of an extended ACE configuration 
 NSEL The output ACL that permitted or denied a flow  
  eacl - Hash value or ID of the ACL name
  eace - Hash value or ID of the ACL name
  exace - Hash value or ID of an extended ACE configuration
  username - NSEL username

  NEL (NetFlow Event Logging) fields
  =====================
  ingressvrfid - NEL NAT ingress vrf id 
  eventflag -  NAT event flag (always set to 1 by nfdump)
  egressvrfid -  NAT egress VRF ID

  NEL Port Block Allocation (added 2014-04-19)
  =====================
  blockstart -  NAT pool block start
  blockend -  NAT pool block end 
  blockstep -  NAT pool block step
  blocksize -  NAT pool block size

  Extra/special fields
  =====================
  cl - nprobe latency client_nw_delay_usec 
  sl - nprobe latency server_nw_delay_usec
  al - nprobe latency appl_latency_usec

=head1 PERFORMANCE

It is obvious that performance of the perl interface is lower in comparison to 
highly optimized nfdump utility. While nfdump is able to process up 
to 2 milion of records per second, the Net::NfDump is not able to process 
more than 1 milion. However, there are several rules to keep the code optimised:

=over 

=item * 

Use C<< $obj->fetchrow_arrayref() >> and C<< $obj->storerow_arrayref() >> instead of 
C<< *_array >> and C<< *_hashref >> equivalents. Arrayref handles only the reference 
to the structure with data. Avoid using C<< *_hashref >> functions, it can be 5-times 
slower.

=item * 

Handle to the perl API only items which are necessary to be used in the code. It is always 
more effective to define in C<< Fields => 'srcip,dstip,...' >> instead of in C<< Fields => '*' >>. 

=item * 

Preference to using C<< $obj->clonerow($obj2) >> method is highly recommended. This method copies data between 
two instances directly in the C code in the libnf layer. 

Following code: 

  $obj1->exec( Fields => '*' );
  $obj2->create( Fields => '*' );

  while ( my $ref = $obj1->fetchrow_arrayref() ) {
      # do something with srcip 
      $obj2->storerow_arrayref($ref);
  }

can be written in a more effective way (several times faster): 

  $obj1->exec( Fields => 'srcip' );
  $obj2->create( Fields => 'srcip' );

  while ( my $ref = $obj1->fetchrow_arrayref() ) {
      # do something with srcip 
      $obj2->clonerow($obj1);
      $obj2->storerow_arrayref($ref);
  }


=back 



=cut 

#=head1 FLOW QUERY - NOT IMPLEMENTED YET
#
#The flow query is a language very simmilar to SQL to query data on 
#nfdump files. However, the flow query has nothing to do with SQL. It uses
#only similar command syntax. Example of flow query 
#
#  SELECT * FROM data/nfdump1.nfcap, data2/nfdump2.nfcap
#  WHERE src host 147.229.3.10 
#  TIME WINDOW BETWEEN '2012-06-03' AND '202-06-04' 
#  ORDER BY bytes
#  LIMIT 100
#
#
#  INSERT INTO data/nout_nfdump.nfcap (srcip, dstip, srcport, dstport) 
#
#

=pod 

=head1 NOTE ABOUT 32BIT PLATFORMS

Nfdump primary uses 64 bit counters and other items to store single integer value. However, 
the native 64 bit support is not compiled in every perl. For those cases where 
only 32 integer values are supported, the C<Net::NfDump> uses C<Math::Int64> module. 

The build scripts detect the platform automatically and C<math::Int64> module is required
only on platforms where an available perl does not support 64bit integer values. 

=back


=head1 EXAMPLES OF USE 

There are several examples in the C<examples> and C<bin> directory. 


C<nfasnupd> - Is script for updating the information 
about AS numbers and country codes based on BGP and geolocation database. Every flow 
can be extended with src/dst AS number and alco can be 
extended with src/dst country code. 

The C<nfasnupd> periodically checks and downloads the BGP database 
which is available as part of libn.net project. After that it updates 
the AS (or country code) information in the nfdump file. It can be 
run as the extra command (-x option of nfcapd) to update 
information when the new file is available. 

The information about src/dst country works in a similar way. It uses maxmind database 
and C<Geo::IP> module. However, nfdump does not support any field to store such kind of 
information; the xsrcport and xdstport fields are used instead. The country code is 
converted into 16 bit information (8 bits for the first character of a country code and 
another 8 bits for the second one). 

=back


=head1 SEE ALSO

nfdump project - https://github.com/phaag/nfdump
libnf C interface http://libnf.net/

=head1 AUTHOR

Tomas Podermanski, E<lt>tpoder@vut.czE<gt>, Brno University of Technology
NetX Networks a.s., E<lt>info@netx.as<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2012 - 2019 by Brno University of Technology
Copyright (C) 2020 by NetX Networks a.s.

This library is free software; you can redistribute it and modify
it under the same terms as Perl itself.

If you are satisfied with using C<Net::NfDump>, please, send us a postcard, preferably with a picture of your location / city to: 

  Brno University of Technology 
  CVIS
  Tomas Podermanski 
  Antoninska 1
  601 90 
  Czech Republic 

=cut

1;

__END__
