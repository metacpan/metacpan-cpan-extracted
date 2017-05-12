package Music::ABC::Archive;

use 5.008;
use strict;
use warnings;
use Carp ;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(new parse openabc filename list_by_title get_song print_song_summary get_song_titles) ] );

our @EXPORT_OK = qw(new parse openabc filename list_by_title get_song print_song_summary) ;
our @EXPORT = ( );

our $VERSION = '0.02';

use Music::ABC::Song ;

my (@header_lines, %Song_objs, %Song_data, %Unique_display_name) ;

sub new
{
    my $class = shift ;
    my $self = {} ;
    my $filename = shift ;
    $self->{FILENAME} = "" ;

    if(defined($filename)) {
	$self->{FILENAME} = $filename ;
    }

    bless ($self, $class) ;
    $self->{Is_parsed} = 0 ;
    $self->{File_is_open} = 0 ;
    return $self ;
}

sub abc_reset
{
    my $self = shift ;
    $self->{Is_parsed} = 0 ;
    %Song_data = () ;
    %Song_objs = () ;
    %Unique_display_name = () ;
    #close($self->{fh}) if $self->{File_is_open} ;
    #$self->{File_is_open} = 0 ;
}

sub filename
{
    my $self = shift ;
    my $newfilename = shift ;

    if($newfilename) {
	if($newfilename ne $self->{FILENAME}) {
	    $self->{FILENAME} = $newfilename ;
	    $self->abc_reset() ;
	}
    }

    return $self->{FILENAME} ;
}

sub openabc
{
    my $self = shift ;
    my $filename = shift ;
    my $fh ;

    if(defined($filename)) {
	$self->{FILENAME} = $filename ;
    }

    close($self->{fh}) if $self->{File_is_open} ;
    $self->{File_is_open} = 0 ;

    open($fh, "<$self->{FILENAME}") || return 0 ;
    $self->{fh} = $fh ;
    $self->{File_is_open} = 1 ;

    return 1 ;
}

sub parse
{
    my $self = shift ;
    return if $self->{Is_parsed} ;

    $self->openabc() if !$self->{File_is_open} ;

    my $display_name ;
    my $currpos = tell(${$self->{fh}}) ;
    my $songnumber ;
    my $type = "" ;
    my $key = "" ;
    my $meter = "" ;
    my $currobj ;
    my $songnum ;
    my $fname = $self->{FILENAME} ;
    my $in_song = 0 ;
    my $in_songs = 0 ;
    my $found_meter = 0 ;
    my $found_type = 0 ;
    my $fh = $self->{fh} ;


    while (<$fh>) {
	#print ;
	chomp ;
	s/\r// ;
	s/\n// ;
	my $text = $_ ;
	#print "$t[0] $t[1]\n" ;

	## 4 header types we need to explicity detect X,T,M and R
	if (/^X\:/) {
	    my @t = split(':') ;
	    $t[1] = "" if(!defined($t[1])) ;
	    $t[1] =~ s/^\s+//; # trim leading whitespace
	    $t[1] =~ s/\s+$//; # trim trailing whitespace
	    $songnum = $t[1] + 0 ;
	    $Song_objs{$songnum} = Music::ABC::Song->new(archivename=>$fname, number=>$songnum) ;
	    $Song_objs{$songnum}->filepos($currpos) ;
	    $in_song = 0 ;
	} elsif (/^T\:/) {
	    my @t = split(':') ;
	    $t[1] = "" if(!defined($t[1])) ;
	    $t[1] =~ s/^\s+//; # trim leading whitespace
	    $t[1] =~ s/\s+$//; # trim trailing whitespace
	    my $append = "" ;
	    my $name = $t[1] ;


	    my $display_name = $name . $append ;

	    while (defined($Unique_display_name{$display_name})) {
		if($append eq "") {
		    $append = 2 ;
		} else {
		    $append++ ;
		}
		$display_name = $name . " (" . $append . ")" ;
	    }

	    $Song_objs{$songnum}->display_name($display_name) ;

	    # set the display_name in the unique hash so we can avoid
	    # future name collisions
	    $Unique_display_name{$display_name} = 1 ;

	} elsif (/^R\:/) {
	    my @t = split(':') ;
	    $t[1] = "" if(!defined($t[1])) ;
	    $type = $t[1] ;
	} elsif (/^M\:/) {
	    my @t = split(':') ;
	    $t[1] = "" if(!defined($t[1])) ;
	    $meter = $t[1] ;
	} 


	if(/^%/) {
	    # this line silently passes through, but
	    # isn't necessarily the start of the song
	    if(!$in_songs) {
		push @header_lines, $_ ;

	    }
	}
	
	if($songnum) {
	    if (/^(.):/) {
		my ($code, @v) = split(':') ;
		my $text = join ":", @v ;
		if($in_song || !($1 =~/[MR]/)) {
		    $Song_objs{$songnum}->header($1, $text) if($1 ne "|") ;
		}
	    } else {
		if(!$in_song) {
		    # type (R) and meter (M) headers are inherited from 
		    # any previous occurences, or the ones we found in this song
		    # so we set them, and output them here just before the song text ;
		    $Song_objs{$songnum}->header("R", $type) ;
		    $Song_objs{$songnum}->header("M", $meter) ;
		    $Song_objs{$songnum}->type($type) ;
		    $Song_objs{$songnum}->meter($meter) ;
		}
		$in_song = 1 ;
		$in_songs = 1 ;
	    }

	    $Song_objs{$songnum}->text($_) ;
	}

	$currpos = tell($self->{fh}) ;
    }

    $self->{Is_parsed} = 1 ;
}

sub get_song
{
    my $self = shift ;
    my $songnum = shift ;
    my $no_headers = @_ || 0 ;
    my @data ;

    eval {
	$self->parse() if(!$self->{Is_parsed}) ;

	foreach(@{$Song_objs{$songnum}->text()}) {
	    next if /^[A-Z]:/ && $no_headers ;
	    next if /^[a-z]:/ && $no_headers ;
	    push (@data, $_) ;
	}
    } ;

    croak "get_song failed" if ($@) ;

    return @data ;
}

sub get_archive_header_lines
{
    my $self = shift ;
    eval {
	$self->parse() if(!$self->{Is_parsed}) ;
    } ;

    croak "get_archive_header_lines failed" if ($@) ;

    #print "Returning Header Lines:\n@header_lines\n" ;

    return @header_lines ;
}

sub print_song_summary
{
    my $self = shift ;
    my $songnum = shift ;
    my $use_html_tags = shift || 0 ;
    my @data ;

    $self->parse() if(!$self->{Is_parsed}) ;

    my $sr = $Song_objs{$songnum} ;

    return $sr->get_song_summary($use_html_tags) ;
}

sub by_name
{
    my $hrefa = $Song_objs{$a} ;
    my $hrefb = $Song_objs{$b} ;

    return $hrefa->display_name() cmp $hrefb->display_name() ;
}


sub list_by_title
{
    my $self = shift ;
    my @data ;

    $self->parse() if(!$self->{Is_parsed}) ;

    foreach my $songnum (sort by_name keys %Song_objs) {
	push (@data, [$Song_objs{$songnum}->display_name(),
		      $songnum,
		      $Song_objs{$songnum}->type(),
		      $Song_objs{$songnum}->meter(),
		      $Song_objs{$songnum}->key(),
		      $Song_objs{$songnum}->titles(),
		      ]) ;
    }

    return @data ;
}

sub get_song_titles
{
    my $self = shift ;
    my $songnum = shift || return undef ;

    $self->parse() if(!$self->{Is_parsed}) ;

    return @{$Song_objs{$songnum}->titles()} ;
}

sub DESTROY
{
    my $self = shift ;
    close($self->{fh}) if $self->{File_is_open} ;
}

1;
__END__

=head1 NAME

Music::ABC::Archive - Parse ABC music archives

=head1 VERSION

0.01

=head1 SYNOPSIS

 use Music::ABC::Archive ;

 $abcfile = "Some_ABC_file.abc" ;
 $songnum = 6 ;

 $abc_obj = Music::ABC::Archive->new($abcfile) ;

 $abc_obj->openabc($abcfile) || die("failed to open $abcfile") ;

 print "-----------------------------\n" ;
 my @lines = $abc_obj->print_song_summary($songnum) ;
 
 foreach (@lines) {
     print "$_\n" ;
 }
 
 my @files = $abc_archive->list_by_title() ;
 
 foreach (@files) {
     my ($display_name, $sn, $type, $meter, $key, $titles_aref) = @{$_} ;
     my $name = "$display_name - $type - Key of $key" ;
     print "<option value=\"$sn\">$name</option>\n" ;
 }

=head1 DESCRIPTION

ABC music archives (http://www.gre.ac.uk/~walshaw/abc/index.html) contain songs in the ABC format.
They are a very quick way for entering music in a text format, and there are numerous publishable quality
renderers for ABC music.  This module encapsulates the ABC archive, and individual songs so they may
more easily be managed by perl front-ends.

=head1 ABSTRACT

    ABC music archives (http://www.gre.ac.uk/~walshaw/abc/index.html) contain songs in the ABC format.
    They are a very quick way for entering music in a text format, and there are numerous publishable quality
    renderers for ABC music.  This module encapsulates the ABC archive, and individual songs so they may
    more easily be managed by perl front-ends.

=head1 CONSTRUCTOR

=over 3

=item new([I<s>])

Creates the Music::ABC::Archive object.
If I<s> is given, specifies the name of the archive file.

=back

=head1 METHODS

=over 4 

=item openabc([I<s>])

Opens the abc archive file.  Optional argument is the name of the archive file.
Returns false on failure.

=item filename([I<s>])

Specify the name of the archive file.  Returns the current archive file name

=item list_by_title()

@song_numbers = list_by_title() ;

Returns list of array references for songs in the archive, sorted by title,
which contain (in this order):

display_name - a song title for display to the user

song number - an integer

song type - Reel, Jig, Waltz, etc

key - Key of the song

titles - a reference to an array holding all titles for the song


=item get_song(I<n>)

Returns all of the ABC text for song number I<n>. There is no trailing "\n" ;

@lines = get_song($songnum) ;

=item print_song_summary(I<n>,[I<f>])

Returns a list of lines, giving a description of the song as found in the headers
of the song text for song number I<n>.  if the second argument is false, or missing, then no html markup
is included, otherwise the lines include basic html markup for displaying the song
on a WWW browser.  There is no trailing "\n" ;

@lines = print_song_summary($song_number) ;
@lines = print_song_summary($song_number, $use_html_tags) ;


=item get_archive_header_lines()

Returns all of the ABC header text(any line starting with %, before any songs are found)

@header_lines = get_archive_header_lines() ;

=item parse()

Force immediate parsing of the ABC archive file.  This will be done automatically
on any other calls.

=back

=head1 AUTHOR

Jeff Welty (jeff@redhawk.org)

=head1 BUGS

None known, but you'll be sure to tell me if you find one, won't you?

=head1 SEE ALSO

Music::ABC::SONG.pm

=head1 COPYRIGHT

This program is free software.  You may copy or
redistribute it under the same terms as Perl itself.

=pod ABC Field names
Field name            header tune elsewhere Used by Examples and notes
----------            ------ ---- --------- ------- ------------------
A:area                yes                           A:Donegal, A:Bampton
B:book                yes         yes       archive B:O'Neills
C:composer            yes                           C:Trad.
D:discography         yes                   archive D:Chieftans IV
E:elemskip            yes    yes                    see Line Breaking
F:file name                         yes               see index.tex
G:group               yes         yes       archive G:flute
H:history             yes         yes       archive H:This tune said to ...
I:information         yes         yes       playabc
K:key                 last   yes                    K:G, K:Dm, K:AMix
L:default note length yes    yes                    L:1/4, L:1/8
M:meter               yes    yes  yes               M:3/4, M:4/4
N:notes               yes                           N:see also O'Neills - 234
O:origin              yes         yes       index   O:I, O:Irish, O:English
P:parts               yes    yes                    P:ABAC, P:A, P:B
Q:tempo               yes    yes                    Q:200, Q:C2=200
R:rhythm              yes         yes       index   R:R, R:reel
S:source              yes                           S:collected in Brittany
T:title               second yes                    T:Paddy O'Rafferty
W:words                      yes                    W:Hey, the dusty miller
X:reference number    first                         X:1, X:2
Z:transcription note  yes                           Z:from photocopy
=cut
