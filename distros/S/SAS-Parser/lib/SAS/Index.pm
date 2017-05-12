package SAS::Index;

#use SAS::Parser;
use SAS::Header; # qw(get_title get_version date);
@ISA = qw(SAS::Header);

=head1 NAME

SAS::Index - Extract indexing information from SAS files

=head1 SYNOPSIS

 use SAS::Index;

 $filelist = new SAS::Index;
 $filelist->makeindex(@ARGV);

 foreach $f (@{$filelist->{files}}) {
    my $index = ${$filelist->{entries}{$f}};
    print "Indexed $f:\n$index\n";
 }
 
=head1 DESCRIPTION

I<SAS::Index> provides simple tools for extractng and storing information
from a collection of SAS files suitable for a program index.  It is
meant as a start, suitable for extending.

=head2 Methods

The following methods are defined in the SAS:Index class.

=over 4

=item $p -> makeindex(@files)

Reads and parses a list of SAS files.

=back 4


=cut

sub new
{
    my $class = shift;
    my $self = bless { 
         files       => [],    # array of files processed
			entries     => {},    # hash of index entries
           }, $class;
    $self;
}

sub get_index{
	my $self = shift;
	my $index;
	
	my $file = $self->{file};
	my $date = SAS::Header::date((stat $file)[9]);
	my $title   = $self->SAS::Header::get_title();
	my $version = $self->SAS::Header::get_version();
#	my $doc     = $self->get_doc();
		
	$title =~ s/\s*$//s;
	$index = "$file: $title";
	$index .= " $date";
	$index .= " [$version]" if $version;
	return $index;	
}

sub makeindex {
	my $self = shift;
	my @files = @_;
	my %options = (
		silent => 1,
		store  => 'NONE',
		);
	foreach $file (@files) {
		#print "Indexing $file\n";
		push (@{$self->{files}}, $file);
		$p = new SAS::Parser;
		$p->SUPER::parse_file($file, \%options);
		my $index = $p->SAS::Index::get_index();
		${$self->{entries}{$file}} = $index;
		#print $index, "\n";
	}
}

## Override the parse_comment method to extract information from an
## existing header: Title, Created, Version, Doc.

#  Call eof() as soon as seen first PROC or DATA step

#package SAS::Header;
sub parse_ccomment {		# $self->parse_ccomment($statement);
   my($self, $stmt) = @_;
	
	unless ($step eq '') {
		$self->eof(1);
		print "Done, at $self->{file} ($lineno)\n";
		return;
	}

	$stmt = SAS::Header::unbox($stmt);
	my @lines = split(/\n/, $stmt);
	foreach (@lines) {
		if (/(author|title|created|version|doc)\s*:\s*/i) {
			my $info = lc($1);
			my $rest = $';
			$rest =~ s/\s*$//;
			$rest =~ s/\s+/ /g;
			#print "$info :: $rest\n";
			$self->{$info} = $rest;
		};
	}
}

