###########################################
package OS390::IEBUtils::IEBUPDTE;
###########################################

use strict;
use warnings;
#use diagnostics;
use Carp;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(iebupdte);
our @EXPORT_OK = qw();
our $VERSION = '0.01';

sub new {
	my $class = shift;
	my $self = { };
	bless ($self, $class);
	$self->_init(@_);			# initialize self with any remaining args
	return $self;
}

sub _init {
	my $self = shift;
	my $first_parm = shift;
	if (ref($first_parm) !~ /^GLOB$/) {
		croak "Sorry, I need a filehandle, but I got a " . ref($first_parm) . "...";
		return undef;
	}
	$self->{fh} = $first_parm;
	$self->{current_membername} = '';
	$self->{debug} = 0;
}

sub isValidFile {
	my $self = shift;
	my $fh = $self->{fh};
	my $rtn;
	
	# save cursor position
	my $saved_position = tell($fh);
	# go to beginning
	seek($fh, 0, 0);
	# 
	local $/ = \32768;
	$_ = <$fh>;
	if (/^1.*\n\ MEMBER\ NAME/) {
		$rtn= 1;
	}else{
		$rtn= 0;
	}
	#put the cursor back to where we found it...
	seek($fh, $saved_position, 0);
	return $rtn;
}

sub getNextMember {
	my $self = shift;
	my $fh = $self->{fh};
	my $data = '';
	my $readname = '';
	my $returnName = '';

	# local $/ = "\r\n";

	# we're already at the end, be graceful and return nothing...
	if ( eof($fh) ) {
		print STDERR "Already at end, return undef.\n" if $self->{debug};
		return undef;
	}
	
	while(<$fh>){
	
		s/\x0d//g;  # strip all x0D bytes (from DOS CC)
		
		# CC line, do nothing
		if (/^1/){
			print "\t$. CC\n" if $self->{debug};
			next;
		}

		# 'MEMBER NAME'
		elsif (/MEMBER NAME\ \ (.*)/) {

			$readname = $1;
			chomp $readname;

			# first found name
			if ($self->{current_membername} eq ''){
				print "\t$. Found first membername ($readname).\n" if $self->{debug};
				$self->{current_membername} = $readname;
			}
			# repeated name
			elsif ($readname eq $self->{current_membername}) {
				print "\t$. Repeat memberName ($readname).\n" if $self->{debug};
				next;
			}
			# new name
			elsif ($readname ne $self->{current_membername}) {
				print "\t$. Found new member ($readname), stoping.\n" if $self->{debug};
				print "\t$. Setting \$returnName to " . $self->{current_membername} . "\n" if $self->{debug};
				$returnName = $self->{current_membername};
				$self->{current_membername} = $readname;
				last;
			}
			else {die;}
					
		}
		# EOF
		elsif ( eof($fh) ){
			print "\t$. EOF\n" if $self->{debug};
			$returnName = $self->{current_membername};
			last;
		}
		# data line
		else{
			$data .= substr($_,1);  # trim leading space from FBA CC
		}
	}
	print "\t$. \$current_membername = " . $self->{current_membername} . "\n" if $self->{debug};
	print "\t$. \$readname = $readname\n" if $self->{debug};
	print "\t$. \$returnName = $returnName\n" if $self->{debug};
	print "\t$. Returning " . $returnName. ".\n" if $self->{debug};

	return $returnName , \$data;
};


sub getMemberNames{

	my $self = shift;
	my @membername_list;
	my %unique_members;
	my $fh = $self->{fh};


	# save cursor position
	my $saved_position = tell($fh);

	# go to beginning
	seek($fh, 0, 0);

	# look for the member names	
	while (<$fh>) {
		if (/MEMBER NAME\ \ (.*)/) {
			push (@membername_list, $1) unless $unique_members{$1}++;
		}
	}
	
	#put the cursor back to where we found it...
	seek($fh, $saved_position, 0);


	if (wantarray()){
		print "\tReturning ref to an array.\n" if $self->{debug};
		return \@membername_list;
	}else{
		print "\tReturning a scalar.\n" if $self->{debug};
		return scalar(@membername_list);
	}

	

}
	
sub getNamedMember{
	# stub for later use
};


###########################################
package OS390::IEBUtils::IEBPTPCH;
###########################################

use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(iebptpch);
our @EXPORT_OK = qw();
our $VERSION = '0.01';

sub new {
	my $class = shift;
	my $self = { };
	bless ($self, $class);
	$self->_init(@_);			# initialize self with any remaining args
	return $self;
}

sub _init {
	my $self = shift;
	my $first_parm = shift;
	$self->{debug} = 0;


	if (ref($first_parm) !~ /^GLOB$/) {
		carp "Sorry, I need a file handle....";
		return undef;
	}

}

sub addFile {
	my $self = shift;
	my $filename = shift;

	unless (_validMemberName($filename)){
		carp "Sorry, '$filename' is not a valid PDS member name.";
		return undef;
	}


	
}

sub _validMemberName {

	my $self = shift;
	my $filename = uc(shift);
	print "\tTesting '$filename'\n" if $self->{debug};
	if ($filename =~ /^[A-Z\$][A-Z0-9\$]{0,7}$/) {
		return 1;
	}else {return 0;}

}

	
=head1 NAME

OS390::IEBUtils - IEBPTPCH and IEBUPDTE work-alikes.

=head1 SYNOPSIS

  use OS390::IEBUtils;

  my $obj = OS390::IEBUtils::IEBUPDTE;
  my ($name, $dataRef) = $obj->getNextMember();
  my $arrayRef = $obj->getMemberNames();

  my $obj = OS390::IEBUtils::IEBPTPCH;
  $obj->addFile(/$contents);
   

=head1 DESCRIPTION

Stub documentation for OS390::IEBUtils, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.

=head1 OS390 INFO

On the mainframe, you can use the following step to dump PDS members
to a sequential file.  This should produce the input that 
OS390::IEBUtils::IEBUPDTE will expect to see on the PC side.

  //IEBPTPCH EXEC  PGM=IEBPTPCH                        
  //SYSPRINT DD SYSOUT=*                               
  //SYSIN    DD 
   PRINT TYPORG=PO,MAXFLDS=1,MAXNAME=999     
   RECORD FIELD=(80)                         
  //SYSUT1   DD DSN=HLQ.INPUT.PDS,DISP=SHR             
  //SYSUT2   DD DSN=HLQ.OUTPUT.SEQUENTIAL,                    
  //         DISP=(NEW,CATLG,DELETE),                  
  //         SPACE=(TRK,(9,9),RLSE),UNIT=SYSDA,        
  //         DCB=(RECFM=FB,LRECL=81,BLKSIZE=0)         


=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 SPONSOR

This code has been developed under sponsorship of InterTech Training and
Consulting.  They can help you with a variety of OS390, OS/390, z/OS tasks, 
especially those relating to report distribution products.

http://www.intertechconsulting.net

=head1 AUTHOR

Paul Boin, E<lt>paul@boin.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Paul Boin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut



1;


