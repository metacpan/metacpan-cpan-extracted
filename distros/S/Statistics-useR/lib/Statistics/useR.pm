=head1 NAME

Statistics::useR - Embed R to let Perl speak statistics. 

=head1 SYNOPSIS

	use Statistics::useR;

=head1 DESCRIPTION

The Statistics::useR is intended to integrate statistical power of R and comprehensive power of Perl. It defines a set of methods that make it possible to communicate easily between Perl and R. Furthermore, it offers a parallel environment for users to do multiple tasks at same time.

Please keep in mind that Statistics::useR is currently just a layer of glue. User is assumed to know basic ideas of R.

Statistics::useR can start an embedded R and evaluate R commands. It also offers an object-based interface to R data. The R data can be output into Perl (integer vector, real number vector and string vector, also lists containing such vectors) as a hash structure which is called RData. The hash contains array refs to data. Keys in hash are names of list in R. For vector data, though, hash with only value will be put back into Perl. It can also introduce a hash into R list data. In one word, useR exchanges data with R through Perl-hash/R-list. Please see details below.

Please open the "readme" file before installation.

=head2 EXPORT

Statistics::useR exports five methods to run embedded R.

=cut

package Statistics::useR;

use 5.010001;
use strict;
use warnings;
use XSLoader;
use forks;
use threads::shared;
use Storable qw(store retrieve);
use File::Temp qw(:POSIX);

=head1 USAGE

When this module is used, an R interpreter will be started automatically. It will also close by itself when the program ends. Following codes show how to evaluate R commands and how the RData looks like. It is important to understand the structure of RData. It is strongly suggested that you run the following two example codes.

The first example could demonstrate how RData looks like.

	use Statistics::useR;
	use Data::Dumper;

	my $cmd = 'l<-list(a=1:3,b=2:6,c=list(d=c(2,3.4,5.6),e=c(23.3,43.445),f=c(98.8,42.1,"df")));l';
	my $list = eval_R($cmd);
	print $list->getType(), "\n"; #get data type of cmd result
	print $list->getLen(), "\n"; #get number of members of cmd result
	print join "\t", @{$list->getNames()}; print "\n"; #get names(like 'names' in R)
	print Dumper($list->getValue()), "\n"; #Dumped value will help understand how value is returned to Perl.

	my $data = {'val',[1,4,3],'attr',['hello', 'world','universe']};
	my $rvar = Statistics::RData->new('data'=>$data, 'name'=>'test'); #Set a new R data named 'test' in R.
	$cmd='test2<-test;test2$val <- test2$val+5;pdf("pic.pdf");plot(test2$val);dev.off();test2';
	my $res=eval_R($cmd);
	print Dumper($res->getValue()), "\n";

The second example shows how to share data and to run analysis in parallel way.

	use Statistics::useR;

The following assignment creates a shared data.
	
	my $res = eval_R('a<-rnorm(5600*5600);dim(a)<-c(5600,5600);b<-t(a);colnames(a)<-1:5600;as.data.frame(a)');

Following codes create four tasks to calculate the matrix product of 'b' and 'a'.

	my $th1 = openTask('as.data.frame(b %*% a[,1:1400])');
	my $th2 = openTask('as.data.frame(b %*% a[,1401:2800])');
	my $th3 = openTask('as.data.frame(b %*% a[,2801:4200])');
	my $th4 = openTask('as.data.frame(b %*% a[,4201:5600])');

Then close all the tasks. Please note that the tasks are opened together before get closed. Since B<closeTask> may block the main program, closing a task right after opening it may actually equal to doing tasks sequentially.

	my $o1 = closeTask($th1); #closeTask returns a hash ref.
	my $o2 = closeTask($th2);
	my $o3 = closeTask($th3);
	my $o4 = closeTask($th4);
	my %res = (%{$o1},%{$o2},%{$o3},%{$o4}); #collect all returned RData.

=cut

BEGIN {
  our $VERSION = '0.1';
  XSLoader::load('Statistics::useR', $VERSION);
  init_R();
}
END {
  end_R();
}

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw() ],
		     'runR' => [qw(eval_R readTable writeTable openTask closeTask)]
    );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = ( @{ $EXPORT_TAGS{'runR'} } );

sub readTable {
    my %data;
    my @colnames;
    open my $fh, '<', $_[0];
    chomp(my $header = <$fh>);
    @colnames = split /$_[1]/, $header;
    for (@colnames) {
      $data{$_} = [];
    }
    while(<$fh>) {
      chomp;
      my @eles = split /$_[1]/, $_;
      for my $idx (0..$#eles) {
	push @{$data{$colnames[$idx]}}, $eles[$idx];
      }
    }
    close $fh;
    return \%data;
}

sub writeTable {
    my ($data, $file, $delim) = @_;
    my @headers = sort keys %$data;

    open FH, '>', $file;
    print FH join $delim, @headers;
    print FH "\n";
    for my $idx (0..$#{$data->{$headers[0]}}) {
	print FH join $delim, map {$data->{$_}->[$idx]} @headers;
	print FH "\n";
    }
    close FH;
}

sub openTask {
  my $cmd = $_[0];
  my $dataRepo = tmpnam();
  my $t = threads->new(sub{
			 my $out;
			 if(eval {$out = eval_R($cmd)}) {
			   store $out->getValue(), $dataRepo;
			   return $dataRepo;
			 }
			 else {
			   warn $@;
			   return undef;
			 }
		       });
 return $t;
}

sub closeTask {
  my $dataRepo = $_[0]->join;
  if(defined $dataRepo) {
    my $dataRef = retrieve($dataRepo);
    unlink $dataRepo;
    return $dataRef;
  }
  else {return undef;}
}

package Statistics::RData;

use strict;
use warnings;

sub new {
    shift;
    my $input = {};
    %{$input} = @_;
    my %type = ('int',[],'real',[],'str',[]);;
    my $keyCount = keys(%{$input->{'data'}});

    while(my ($key, $val) = each %{$input->{'data'}}) {
	my $t1;
	for (1..3) {
	    my $i = int(rand($#{$val}));
	    my $t2 = &getDataType($val->[$i]);
	    if(!defined $t1 || $t1 lt $t2) {
		$t1 = $t2;
	    }
	}
	push @{$type{$t1}}, $key;
    }

    my $rData = setValue($input->{'data'}, \%type, $keyCount);
    insVar($rData, $input->{'name'});

    return $rData;
}

sub getDataType {
    if(!defined $_[0]) {
	return 'str';
	}
    elsif($_[0] =~ /^\-?(?:[1-9]\d*\.\d+|0\.\d+)$/) {
	return 'real';
    }
    elsif($_[0] =~ /^-?[1-9]\d*$/) {
	return 'int';
    }
    else {
	return 'str';
    }
}

1;

__END__

=head1 METHODS

=over

=item B<eval_R>

Evaluate R expression and return an object of RData. It is one way to share data between different tasks to evaluate an R command before creating any task by openTask. 

 eval_R('a <- 1:100;');
 my $task1 = openTask(...);
 my $task2 = openTask(...);
 #task1 and task2 both know data a.

=item B<openTask>

Turn on a process to evaluate R commands. Given a scalar containing command string, a process object will be returned.

 my $cmd = 'm <- rnomr(3*3); dim(m) <- c(3,3); crossprod(m)';
 my $process = openTask($cmd);

=item B<closeTask>

Turn off a process. Since it will block the main program, it is good to close tasks only after opening all needed tasks. Return a hash ref pointing to the value of returned RData of the last evaluated expression in the R command.

 my $res = closeTask($process);

=item B<readTable>

Read in a text file containing a table-style data. The data is assumed to have column names, yet without row names.

 my $delim = "\t";
 my $newdata = readTable 'filename.txt', $delim;

=item B<writeTable>

Put a RData into a text file in table format.
 
 writeTable $RData, $filename, $delim;

=back

I<Following is Object-oriented methods for RData.>

=over

=item B<new>

Create a new R list - 'data' with 'name'. Return an object of RData. 'data' is a hash ref, which points to hash containing array refs. Created R list takes hash keys as names, and takes every array content as component data. Refer to usage. And this is another way to share data between multiple tasks.

=item B<getType>

Get R data type.

=item B<getLen>

Get number of members in R data.

=item B<getNames>

Just like 'names' in R.

=item B<getValue>

Return a hash ref which contains array refs and takes names of R list components as hash keys. The arrays map to components of R list.

=back

=head1 SEE ALSO

R project website: http://www.r-project.org

=head1 AUTHOR

Xin Zheng, E<lt>xinzheng@cpan.orgE<gt>
Any feedback will be greatly appreciated.
It may help if you go to http://david.abcc.ncifcrf.gov/manuscripts/R .

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by LIB/SAIC-Frederick @ NCI-Frederick

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
