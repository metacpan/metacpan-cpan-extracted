package PDF::Tk;

use IO::All;
use IPC::Open2;
use File::Temp qw/tempdir tempfile/;
use Cwd;
use strict;
our $VERSION='0.02';

sub new {
    my ($proto,%options)=@_;
    my $class= ref $proto || $proto;
    my $self=\%options;
    bless $self,$class;
    die "Can't take both a file and document argument"
     if ($self->{file} && $self->{document});
    $self->{pdftk} ||= "/usr/bin/pdftk";
    $self->_get_document if $self->{file};
    die "Can't find executablable ".$self->{pdftk}
        unless -x $self->{pdftk};
    return $self;
}

sub _get_document {
   my $self=shift;
   my @targets;
   if (ref($self->{file}) eq "ARRAY") {
   	warn "Setting together an arrayref";
   	foreach my $file (@{$self->{file}}) {
	  if (ref($file) eq "SCALAR") {
	  	local $/;
		my ($fh,$filename)=tempfile();
		print $fh $$file; # put data in a file
		$file=$filename; # set the filename
		push @targets,$filename;
	  }
	}
      $self->call_pdftk($self->{file},\($self->{document}),"cat"); 
       die "Could not load ".$self->{file} unless $self->{document}; 
   } else {
       $self->{document} = io($self->{file})->binary->all;
       die "Could not load ".$self->{file} unless $self->{document}; 
   }
   delete $self->{file};
   unlink @targets;
}

sub call_pdftk {
    my ($self,$input,$output,@args)=@_;
    local $/;
    if (ref $input eq "SCALAR" &&  ref $output eq "SCALAR") {
      my ($rdfh,$wrfh);
      my $pid=open2($rdfh,$wrfh,$self->{pdftk},"-",@args,"output","-") 
         or die "pdftk - @args - failed: $?";
      print $wrfh $$input;
      close $wrfh;
      $$output=<$rdfh>;
      close  $rdfh;
      waitpid $pid,0;
    } elsif (ref $input eq "SCALAR") {
      my $fh;
      open($fh,"|-",$self->{pdftk},"-",@args,"output",$output)
         or die $self->{pdftk}." - @args output $output failed: $?";
      print $fh $$input;
      close $fh;
    } elsif (ref $output eq "SCALAR") {
      my $fh;
      open($fh,"-|",$self->{pdftk},(ref $input eq "ARRAY" ? @$input : $input),@args,"output","-")
       or die "pdftk $input @args - failed: $?";
      $$output=<$fh>;
      close $fh;
    } else {
      system($self->{pdftk},(ref $input eq "ARRAY" ? @$input : $input),@args,"output",$output) == 0 
       or die "pdftk $input @args $output failed: $?";
    }
}

sub document {
    my ($self,$doc)=@_;
    if ($doc) { $self->{document}=$doc; }
    else      { return $self->{document}; }
}

sub pages {
    my $self=shift;
    my $tmpdir=tempdir;
    my ($pdftk,@pages);
    chdir $tmpdir;
    $self->call_pdftk(\($self->{document}),'%d.pdf','burst');
    my $page=1;
    while (-f "./$page.pdf") {
        push @pages,io(cwd."/$page.pdf")->binary->all;
	unlink (cwd."/$page.pdf");
	$page++;
    }
    unlink ("doc_data.txt");
    chdir "/";
    rmdir $tmpdir;
    return (wantarray ? @pages :\@pages);
}

sub page {
    my ($self,$page)=@_;
    my $tmpdir=tempdir;
    chdir $tmpdir;
    $self->call_pdftk(\($self->{document}),'%d.pdf','burst');
    my $res=io(cwd."/$page.pdf")->binary->all;
    unlink <*.pdf>;
    unlink ("doc_data.txt");
    chdir "/";
    rmdir $tmpdir;
    return $res;

}

sub docinfo {
    my ($self,$arg)=@_;
    unless ($self->{documentinfo}) {
        my $documentinfo;
        $self->call_pdftk(\($self->{document}),\$documentinfo,"dump_data");
        my @lines=split "\n",$documentinfo;
        my %documentinfo;
        while (my $line=shift @lines) {
            my ($key,$val)=split m/\:\s*/,$line;
            if ($key eq "InfoKey") {
                $key=$val;
                $line=shift @lines;
                ($val)=$line=~m/InfoValue\:\s*(.+)/;
            }
            $documentinfo{lc($key)}=$val;
        }
        $self->{documentinfo}=\%documentinfo;
   }
   return $self->{documentinfo}->{$arg}if ($arg);
   return $self->{documentinfo};
}
            
 
1;

=head1 NAME

PDF::Tk - Perl integration for the pdf toolkit (pdftk)

=head1 SYNOPSIS

  use PDF::Tk;
  my $doc=PDF::Tk->new(file=>["/tmp/my1.pdf","/tmp/my2.pdf"]);
  my @parts=$doc->pages();

=head1 DESCRIPTION

This module is a interface for the command line pdftk command. 

=head1 METHODS

=over 4

=item new

The constructor for the pdftk module. Takes a hash of arguments

    document - a scalar containing a PDF document,
    file - either a PDF filename or a arrayref of filenames.
    pdftf - path to the pdftk binary, defaults to "/usr/bin/pdftk"

note that document and file are mutually exclusive!

=item call_pdftk

Calls up pdftk command, takes input, output and pdftk operation as arguments
input and output can either be files or scalar refs. input can also be an
array ref of files

=item pages

returns an array in list context, or arrayref, containing the content of all
pages in the document.

=item page

Takes a page as an argument, and returns the contents of that page.

=item docinfo

If you provide an argument, it will return that value (lower cased), or 
else it will return a hash of values;
Common values are B<creator> ,B<title>, B<producer>,B<author>, B<moddate>,
B<creationdate>, B<pdfid0>, B<pdfid1>, B<numberofpages>.

=item document

Accessor for the actual document.

=back

=head1 SEE ALSO

L<http://www.accesspdf.com/pdftk/>

=head1 AUTHOR

Marcus Ramberg, E<lt>marcus@mediaflex.noE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Mediaflex A/S.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
