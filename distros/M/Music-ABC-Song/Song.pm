package Music::ABC::Song;

use 5.008;
use strict;
use warnings;
use Carp ;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = () ;
our @EXPORT_OK = ();

our $VERSION = '0.01';


my %new_attributes = (archivename=>1, number => 1, meter=>1, type=>1, key=>1, filepos=>1) ;

my %header_full = (
A=>"AREA", 
B=>"BOOK", 
C=>"COMPOSER", 
D=>"DISCOGRAPHY", 
E=>"ELEMSKIP", 
F=>"FILENAME", 
G=>"GROUP", 
H=>"HISTORY", 
I=>"INFORMATION", 
K=>"KEY", 
L=>"NOTELENGTH", 
M=>"METER", 
N=>"NOTES", 
O=>"ORIGIN", 
P=>"PARTS", 
Q=>"TEMPO", 
R=>"RHYTHM", 
S=>"SOURCE", 
T=>"TITLES", 
X=>"NUMBER", 
Z=>"TRANSCRIPTION") ;

my %header_is_multiline = (DISCOGRAPHY=>1,HISTORY=>1,INFORMATION=>1,NOTES=>1,TITLES=>1,TRANSCRIPTION=>1) ;

my @header_print_order = qw(TITLES RHYTHM KEY METER NOTES HISTORY DISCOGRAPHY INFORMATION TRANSCRIPTION) ;

sub new
{
    my ($caller, %args) = @_ ;
    my $self = bless {}, ref($caller) || $caller ;

    $self->{ARCHIVENAME} = "" ;
    $self->{DISPLAY_NAME} = "" ;
    $self->{NUMBER} = 0 ;
    $self->{FILEPOS} = 0 ;
    $self->{TEXT} = [] ;

    $self->{AREA} = "" ;
    $self->{BOOK} = "" ;
    $self->{COMPOSER} = "" ;
    $self->{DISCOGRAPHY} = [] ;
    $self->{ELEMSKIP} = "" ;
    $self->{GROUP} = "" ;
    $self->{HISTORY} = [] ;
    $self->{INFORMATION} = [] ;
    $self->{KEY} = "" ;
    $self->{NOTELENGTH} = "" ;
    $self->{METER} = "" ;
    $self->{NOTES} = [] ;
    $self->{ORIGIN} = "" ;
    $self->{PARTS} = "" ;
    $self->{TEMPO} = "" ;
    $self->{RHYTHM} = "" ;
    $self->{SOURCE} = "" ;
    $self->{TITLES} = [] ;
    $self->{TRANSCRIPTION} = [] ;


    while (my ($arg, $value) = each %args) {
	croak "Invalid intializer for Music::ABC::Song object" unless $new_attributes{$arg} ;
	no strict 'refs' ;
	$self->$arg($value) ;
    }

    return $self ;
}

sub quote_html
{
    my $text = shift ;

    $text =~ s/&/&amp;/g ;
    $text =~ s/</&lt;/g ;
    $text =~ s/>/&gt;/g ;
    $text =~ s/"/&qout;/g ;

    return $text ;
}

sub output_scalar_desc
{
    my $header_str = shift ;
    my $text = shift ;
    my $html_tag = shift || 0 ;
    my $use_tags = shift || 0 ;
    my @data = () ;
    my $tmp ;

    $tmp .= "<$html_tag>" if ($use_tags) ;
    $tmp .= "$header_str" if $header_str ;
    $tmp .= "<dd><pre>" if ($use_tags) ;
    $text = quote_html($text) if($use_tags) ;
    $tmp .= " $text" ;
    $tmp .= "</pre></dd>" if ($use_tags) ;
    $tmp .= "</$html_tag>" if($use_tags) ;
    push (@data, $tmp) ;
    return @data ;
}

sub output_array_desc
{
    my $header_str = shift ;
    my $text_aref = shift ;
    my $html_tag = shift || 0 ;
    my $use_tags = shift || 0 ;
    my @data ;
    my $indent = " " x 8 ;

    push (@data, "<$html_tag>") if($use_tags) ;
    my $tmp .= "$header_str " if $header_str ;
    push (@data, $tmp) ;

    foreach(@$text_aref) {
	$tmp = $use_tags ? "<dd><pre>" : "" ;
	$tmp .= $use_tags ? quote_html($_) : $_ ;
	$tmp .= $use_tags ? "</pre></dd>" : "" ;
	push (@data, $indent . $tmp) ;
    }
    push (@data, "</$html_tag>") if($use_tags) ;
    return @data ;
}

sub get_song_summary
{
    my $self = shift ;
    my $use_html_tags = shift || 0 ;
    my @data ;
    my $indent = " " x 8 ;

    my $tmp = "<h3><center>" if $use_html_tags ;
    $tmp .= "Song Number $self->{NUMBER} in " . $self->{ARCHIVENAME} ;
    $tmp .= "</h3>" if $use_html_tags ;

    push(@data, $tmp) ;

    foreach(@header_print_order) {
	my $multiline = $header_is_multiline{$_} ;
	if($multiline) {
	    push(@data, output_array_desc($_, \@{$self->{$_}}, "dl", $use_html_tags)) ;
	} else {
	    push(@data, output_scalar_desc($_, $self->{$_}, "dl", $use_html_tags)) ;
	}
    }

    return @data ;
}

sub archivename
{
    my $self = shift ;
    $self->{ARCHIVENAME} = shift if @_ ;
    return $self->{ARCHIVENAME} ;
}

sub filepos
{
    my $self = shift ;
    $self->{FILEPOS} = shift if @_ ;
    return $self->{FILEPOS} ;
}

sub number
{
    my $self = shift ;
    $self->{NUMBER} = shift if @_ ;
    return $self->{NUMBER} ;
}

sub type
{
    my $self = shift ;
    $self->{TYPE} = shift if @_ ;
    return $self->{TYPE} ;
}

sub key
{
    my $self = shift ;
    $self->{KEY} = shift if @_ ;
    return $self->{KEY} ;
}

sub meter
{
    my $self = shift ;
    $self->{METER} = shift if @_ ;
    return $self->{METER} ;
}

sub display_name
{
    my $self = shift ;
    $self->{DISPLAY_NAME} = shift if @_ ;
    return $self->{DISPLAY_NAME} ;
}

sub titles {
    my $self = shift ;

    if(@_) {
	if (ref $_[0] eq 'ARRAY') {
	    @{ $self->{TITLES} } = @{ $_[0] } ;
	} else {
	    @{ $self->{TITLES} } = @_ ;
	}
    }

    return $self->{TITLES} ;
}

sub add_title {
    my $self = shift ;
    push (@{ $self->{TITLES} }, shift) if @_ ;
    return $self->{TITLES}
}

sub notes {
    my $self = shift ;

    if(@_) {
	if (ref $_[0] eq 'ARRAY') {
	    @{ $self->{NOTES} } = @{ $_[0] } ;
	} else {
	    @{ $self->{NOTES} } = @_ ;
	}
    }

    return $self->{NOTES} ;
}

sub add_note {
    my $self = shift ;
    push (@{ $self->{NOTES} }, shift) if @_ ;
    return $self->{NOTES} ;
}

sub text {
    my $self = shift ;
    push (@{ $self->{TEXT} }, shift) if @_ ;
    return $self->{TEXT} ;
}

sub header {
    my $self = shift ;
    my $header_code = shift ;
    my $header_text = shift ;
    my $header_name = $header_full{$header_code} ;

    if($header_name) {
	my $multiline = $header_is_multiline{$header_name} || 0 ;
	if($multiline) {
	    if($header_text) {
		push (@{ $self->{$header_name} }, $header_text) if $header_text ;
	    }
	    return \@{ $self->{$header_name} } ;
	} else {
	    if($header_text) {
		$self->{$header_name} = $header_text ;
	    }
	    return $self->{$header_name} ;
	}
    }
}

1;
__END__

=head1 NAME

Music::ABC::Song -  Handle songs in ABC music archives

=head1 VERSION

0.01

=head1 SYNOPSIS

 $abcfile = "Some_ABC_file.abc" ;
 $songnum = 6 ;

 $abc_obj = Music::ABC::Song->new(archivename=>$abcfile, number=>$songnum) ;

 some other text here...

=head1 DESCRIPTION

ABC music archives (http://www.gre.ac.uk/~walshaw/abc/index.html) contain songs in the ABC format.
They are a very quick way for entering music in a text format, and there are numerous publishable quality
renderers for ABC music.  This module encapsulates an individual song from an ABC archive, so they may
more easily be managed by perl front-ends.

=head1 ABSTRACT

ABC music archives (http://www.gre.ac.uk/~walshaw/abc/index.html) contain songs in the ABC format.
They are a very quick way for entering music in a text format, and there are numerous publishable quality
renderers for ABC music.  This module encapsulates an individual song from an ABC archive, so they may
more easily be managed by perl front-ends.

=head1 CONSTRUCTOR

=over 3

=item new()

optional arguments: archivename=>$, number=>$, filepos=>$, key=>$, meter=>$ 

 archivename is the name of the ABC archive
 number is the song number in the archive
 filepos is the file position pointer (as in tell) of the start of the song in the archive
 key is the musical key of the song
 type is the song type, i.e. reel, jig, waltz, ...
 meter is the song meter, i.e. 4/4, 3/8, C, etc.

=back

=head1 METHODS

=over 4 

=item archivename([I<s>])

Specify the name of the archive file, if I<s> is given.
Returns the current archive file name.

=item displayname([I<s>])

Specify a name for display to the user of the song, if I<s> is given.
Returns the current displayname.

=item filepos([I<s>])

Specify the position of the song in the archive (as in ftell), if I<s> is given.
Returns the current position.

=item number([I<s>])

Specify the song number in the archive, if I<s> is given.
Returns the current song number.

=item key([I<s>])

Specify the musical key of the song, if I<s> is given.
Returns the current key.

=item meter([I<s>])

Specify the meter of the song, if I<s> is given.
Returns the current meter.

=item type([I<s>])

Specify the type (jig, waltz, ...) of the song, if I<s> is given.
Returns the current type.

=item titles([I<s>])

Specify titles for the song (via an array reference), if I<s> is given.
Returns the array reference of current titles.

=item add_title([I<s>])

Add a single title for the song, if I<s> is given.
Returns the list of current titles.

=item notes([I<s>])

Specify notes for the song (via an array reference), if I<s> is given.
Returns the array reference of current notes.

=item add_note([I<s>])

Add a single note for the song, if I<s> is given.
Returns the list of current notes.

=item text([I<s>])

Add a single line of text for the song, if I<s> is given.
Returns the list of current text lines.

=item header(I<h>,[I<text>])

Returns the scalar value of the header I<h>, or an array reference if a multiline header.  If I<text> is given
add a single header with type I<h> for the song. 

=item get_song_summary(<s>,[<f>])

return an array reference with text summarizing the song.
Optionally use html markup, if I<f> is given and set to a value Perl condsiders to be TRUE.

=back

=head1 AUTHOR

Jeff Welty (jeff@redhawk.org)

=head1 BUGS

None known, but you'll be sure to tell me if you find one, won't you?

=head1 SEE ALSO

Music::ABS::Archive.pm

=head1 COPYRIGHT

This program is free software.  You may copy or
redistribute it under the same terms as Perl itself.

=cut
