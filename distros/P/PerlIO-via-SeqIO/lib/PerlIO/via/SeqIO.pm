#$Id: SeqIO.pm 529 2009-10-29 18:48:14Z maj $
# PerlIO layer for sequence format with BioPerl guts
# Enjoy!
package PerlIO::via::SeqIO;
use strict;
use warnings;
use Bio::Seq;
use Carp;
use Exporter;
use File::Temp qw(tempfile);
use IO::Seekable;
use IO::String;
use PerlIO::Util;
use Scalar::Util qw(weaken);
use Symbol;

our $VERSION = '0.0322';
our @ISA = qw(Exporter);
our @EXPORT = qw(O T);
our @EXPORT_OK = qw(open);
our %OBJS;
our %ITERS;
our $INSTANCE = 128; # big "fileno"
our $__seqio_DUP;

BEGIN {
    # crazy setup machinations...
    use Bio::SeqIO;
    our @SUPPORTED_FORMATS = qw(embl fasta genbank gcg pir);
    foreach (@SUPPORTED_FORMATS) {
	no strict qw(refs);
	my $pkg = "PerlIO::via::SeqIO::$_";
	my $io_class = "Bio::SeqIO::$_";
	Bio::SeqIO->_load_format_module($_);
	$ITERS{$io_class} = \&{$io_class."::next_seq"};
	my $code =<<END;
package ${pkg};
use strict;
use warnings;
use base qw(PerlIO::via::SeqIO);
1;
END
        eval $code;
	croak($@) if $@;
	{ # hook
	    no warnings qw(redefine);
	    *{$io_class."::next_seq"} = sub {
		my $seq = $PerlIO::via::SeqIO::ITERS{$io_class}->(@_);
		return unless $seq;
		$PerlIO::via::SeqIO::OBJS{sprintf("%s\n",$seq)} = $seq;
		return $seq;
	    };
	}
	# add a 'role' to our handles...
	push @IO::Handle::ISA, 'IO::Handle::_viaSeqIO';
    }
    return;
}

our %MODE_SYM = (
    'r' => '<',
    'w' => '>',
    'a' => '>>',
    'r+' => '+<',
    'w+' => '+>',
    'a+' => '+>>'
    );

# init the layer:

sub PUSHED {
#    no strict qw(refs);
    my $self = { 
	'instance' => $INSTANCE,	
	'mode' => $_[1],
	'perl_mode' => $MODE_SYM{$_[1]},
	'format' => (split(m{::}, $_[0]))[-1],
	'eot'    => 0,
	'fh'     => undef,
	'fileno' => undef,
	'source' => undef,
	'engine' => undef,
	'inited' => 0
    };
    $self->{self} = $self; weaken $self->{self};
    $self->{format} = '' if $self->{format} eq 'SeqIO';
    bless ( $self, $_[0] );
}

# the problem: if OPEN is specified in a via module, 
# you never see the filehandle in subsequent via method
# calls (FILL, WRITE, etc.); yet we need to have access
# to the handle returned by open...however, if we do not
# define OPEN, all via method calls recieve the filehandle
# provided by the lower-level open.
# the hack: fileno() is called at the end of the lower-level
# open call; so the via FILENO provides a hook that receives
# the lower-level filehandle. We pre-empt FILENO one time to
# do our setup machinations on the real filehandle.

# grab the opened filehandle using FILENO (called at the 
# end of open() !)
sub FILENO {
    no strict qw(refs);
    my ($self,$fh) = @_;
    if (!$self->{inited}) {
	# if the secret dup is here, use it
	$fh = $PerlIO::via::SeqIO::__seqio_DUP || $fh;
	$self->{fileno} = fileno($fh); # nec to kick fileno hooks
	$self->{eot} = 0;
	for ($self->{mode}) {
	    m/r/ && do {
		$self->{source} =
		    Bio::SeqIO->new( -fh=>$fh, -format=>$self->{format} );
		$self->{format} ||= (split m/::/,ref($self->{source}))[-1];
		last;
	    };
	    m/w|a/ && do {
		$self->set_write_format($self->{format});
		last;
	    };
	    do { #huh?
		croak "failed(INIT): Don't understand mode '".$self->{mode}."'";
	    };
	}
	# connect the via object to the filehandle
	$fh->via_o($self); 
	$INSTANCE++;
	$self->{inited} = 1;
    }
    return $self->{fileno} || -1;
}

sub set_write_format {
    my ($self, $format) = @_;
    unless (grep( /^$format$/, @PerlIO::via::SeqIO::SUPPORTED_FORMATS)) {
	carp("The format '$format' isn't supported; current format unchanged");
	return;
    }
    unless ($self->{mode}  =~ /\+|w/) {
	carp("Can't set format; handle not open for writing");
	return;
    }
    $self->{format} = $format;
    $self->{io_string} = IO::String->new();
    $self->{engine} = Bio::SeqIO->new(-fh=>$self->{io_string},
				  -format=>$self->{format});
    $self->{engine}->_flush_on_write(1);
    return 1;
}

# the FILL/_readline crosstalk allows true "line-by-line" parsing with
# angle brackets. It's a hack, but the lower-level doesn't respect
# $/, as has been advertised (as far as I can tell)

sub FILL {
    my ($self, $fh) = @_;
    my $line;
    my $sep = $/;
    if ($self->{eot} == 0) {
	$self->{eot} = 1;
	$line = $self->_readline;
	$line && $sep && $line =~ s/$sep$//;
	return $line;
    }
    else { # EOT
	$self->{eot} = 0; # clear flag
#	$DB::single=1;
	if ($/) {
	    return "$/"; # kick out of FILL loop
	    # TODO: figure out why this doesn't work in ActiveState, when
	    # reading via gzip.
	}
	else {
	    return $self->_readline($fh);
	}
    }
}

sub _readline {
    my ($self, $fh) = @_;
    if ($self->{source}) { # prepared for seq reads
	my $seq = $self->{source}->next_seq;
	return undef unless $seq;
	my $sep = $/ || "\n";
	if (!wantarray) {
	    return sprintf("%s$sep",$seq);
	} 
	else {
	    local $_;
	    my @ret = ($seq);
	    while ( $_ = $self->{source}->next_seq ) {
		push @ret, $_;
	    }
	    return map { sprintf("%s$sep", $_) } @ret;
	}
    }
    else { # passthru
	return (wantarray ? $fh->getlines : $fh->getline);
    }
    # on EOF, return undef.
}

sub WRITE {
    my ($self, $buf, $fh) = @_;
    my $ios = $self->{io_string};
    my $ret = 0;
    # following may not work, if a Bio...=HASH... is broken up 
    # by buffering...
    my @input = split( /(Bio::.*?=HASH\(0x[0-9a-f]+\)\s)/, $buf ); 
    foreach my $item (@input) {
	if ($item =~ /HASH/) { # string rep of object
	    $item = $OBJS{$item};
	    $self->{engine}->write_seq($item);
	    $ios->pos(0); # seek to top
	    my $line = join('', <$ios>);
	    $ios->pos(0); ${$ios->string_ref}=''; 
	    $ret += $fh->write($line, length $line);
	    undef $OBJS{$item}; # clean up
	}
	else { # write the raw buffer
	    $fh->write($item, length($item)) if $item;
	}
    }
    $ret;
}

sub FLUSH {
    my ($self, $fh) = @_;
#    $DB::single=1;
    return $fh ? $fh->flush : 0;
#    return $fh->flush if !defined $self->{mode} or $self->{mode} =~ /w|a|\+/;
    return -1;
}

sub CLOSE {
    my ($self, $fh) = @_;
    return $fh->close;
}

# This open() is an optional (exported on explicit demand) replacement
# for the core, that provides for the redirection of STDIN/STDOUT/DATA
# through the via(SeqIO) layer. When this open is active, ordinary uses
# of open should be passed through unharmed (tests are in 001_passthru.t)

# to emulate redirection, which PerlIO::via doesn't do yet, the 
# special filehandle is tied to an internal tied class.
# This is truly spaghettified, because the tied handle needs access to 
# the via object's goodies, but it seems to work (002_seqio.t)

sub open  {
    no strict qw(refs);
    my ($fh, $mode, $file) = @_;
    if ($file or $mode !~ /:via\(SeqIO(?:::[a-zA-Z_]+)?\)/) {
	#passthru
	# if !defined $file, parse $mode according to presence of &...
	if ($fh) {
	    if ( $fh =~ /^[A-Z]+$/ ) {
		$fh = *{(caller)[0]."::$fh"};
	    }
	}
	if ($file) {
	    if ( $file =~ /^[A-Z]+$/) {
		$file = *{(caller)[0]."::$file"};
	    }
	    return CORE::open($fh || $_[0],$_[1],$file);
	}
	else {
	    $_[0] ? 
		($_[0] = PerlIO::Util->open($_[1])) : 
		CORE::open($fh || $_[0],$_[1]);

	}
    }
    # deal with special filehandles with 2-argument opens
    if ($fh and $fh =~ /(DATA|STD(?:IN|OUT))/) {
	no strict qw(refs);
	my $dup = gensym;
	my $bareword = $1;
	my $redirect = ($bareword =~ /OUT/ ? ">&" : "<&");
	# get a pristine copy of DATA/STDIN/STDOUT
	$fh = *{(caller)[0]."::$bareword"};
	CORE::open($dup, $redirect, $fh) or croak($!);
	if ($bareword =~ /OUT/) {
	    $| && $dup->autoflush(1);
	}
	# now, need to make everything output to the duplicated
	# handle; may need to use ties after all (to make real
	# writes to the subordinate handle only...)
	
	# provide dummy file to CORE::open
	my ($dumh, $file) = tempfile("dumXXXX", UNLINK=>1);
	close($dumh);
	# secretly pass the dup
	$PerlIO::via::SeqIO::__seqio_DUP = $dup;
	# kick PUSHED
	CORE::open( $dumh, $mode, $file) or croak( $! );
	undef $PerlIO::via::SeqIO::__seqio_DUP;

	tie $fh, '_viaSeqIO_FH';
	(tied $fh)->sub_fh($dup);
	# private pointer for tied object...
	(tied $fh)->via_o( $dumh->via_o );
	return 1;
	
    }
    else { # passthru
	$DB::single=1;
	($mode, $file) = $mode =~ /(\+?(?:<|>)?>?&?)(.*)/;
	$file =~ /^[A-Z]+$/ and $file = *{(caller)[0]."::$file"};
	$_[0] = PerlIO::Util->open($mode,$file);
    }
    1;
}

# seq object converter

sub T {
    my @objs = @_;
    my @ret;
    foreach my $s (@objs) {
	unless (defined $s and ref($s) and
		($s->isa('Bio::SeqI') || $s->isa('Bio::Seq') || 
		 $s->isa('Bio::PrimarySeq'))) {
	    carp "Item undefined or not a sequence object; returning an undef";
	    push @ret, undef;
	    next;
	}
	$s->isa('Bio::PrimarySeq') and $s = _pseq_to_seq($s);
	push @ret, sprintf("%s\n", $s);
	$OBJS{$ret[-1]} = $s;
    }
    return wantarray ? @ret : $ret[0];
}

# object getter ...

sub O {
    no strict qw(refs);
    my $sym = shift;
    $sym ||= $_; 
    for ($sym) {
	m/Bio/ && do {
	    return $OBJS{$sym}; last;
	};
	m/via/ && do {
	    return (tied $sym)->via_o; last;
	};
	m/^[A-Z]+$/ && do {
	    $sym = (caller)[0]."::$sym";
	    return (tied *$sym)->via_o if (tied *$sym);
	    return;
	    last;
	};
    }
    croak("Don't understand the arg");
}

# wrap Bio::PrimarySeqs (incl. Bio::LocatableSeqs) in a Bio::Seq
# for Bio::SeqIO use

sub _pseq_to_seq {
    my @pseqs = @_;
    my @ret;
    foreach (@pseqs) {
	unless (defined $_ && ref($_) && $_->isa('Bio::PrimarySeq')) {
	    push @ret, undef;
	    next;
	}
	my $seq = Bio::Seq->new();
	$seq->id( $_->display_id || $_->id );
	$seq->primary_seq( $_ );
	push @ret, $seq;
    }
    return wantarray ? @ret : $ret[0];
}

1;

# tied handle class for special filehandle 2-argument opens
# see comments to open()

package _viaSeqIO_FH;
use strict;
use warnings;
use Config;
our %__SUB_FH;
our $AUTOLOAD;

sub TIEHANDLE { bless ( { sub_fh => undef, via_o => undef }, $_[0] ) }

sub PRINT {
    my ($self, @args) = @_;
    # use the via object's write method on the sub-handle:
    foreach (@args) {
	$self->via_o->WRITE( $_, $self->sub_fh);
    }
    return 1;
}

sub sub_fh {
    my ($self, $fh) = @_;
    if ($fh) {
	#kludge for ActivePerl:
	if ($Config{cf_email} =~ /ActiveState/) { 
	    push @IO::Handle::ISA, 'IO::Seekable';
	}
	return $__SUB_FH{$fh->fileno} = $fh;
    }
    return unless defined $self->fileno;
    return $__SUB_FH{$self->fileno};
}

sub via_o {
    my ($self, $o) = @_;
    if ($o) {
	$self->{via_o} = $o;
	Scalar::Util::weaken($self->{via_o});
    }
    return $self->{via_o};
}

# use AUTOLOAD to perform handle operations on the 
# subhandle, but delegate the work back to the 
# via class (is this Laziness, or laziness?)

sub AUTOLOAD {
    my ($self,@args) = @_;
    my $func = lc ((split m/::/, $AUTOLOAD)[-1]);
    # specials
    $func = uc $func if $func =~ /destroy/;

    for ($func) {
	# delegate these back to the via object:
	m/readline/ && do {
	    return wantarray ? 
		($self->via_o->_readline($self->sub_fh)) :
		$self->via_o->_readline($self->sub_fh);
	};
	m/fileno/ && do {
	    return unless $self->via_o;
	    return $self->via_o->FILENO();
	};
	m/flush/ && do {
	    return $self->via_o->FLUSH($self->sub_fh);
	};
	m/close/ && do {
	    return $self->via_o->CLOSE($self->sub_fh);
	};
        # otherwise, use the native methods of the sub-handle:
	do { 
	    return unless $self->sub_fh;
	    return $self->sub_fh->$func(@args);
	};
    }
}

# pollute IO::Handle slightly differently ( to avoid unauthorized
# release error)
package IO::Handle::_viaSeqIO;
use strict;
use warnings;
use Scalar::Util qw(weaken);

our %__VIA_O;

sub via_o {
    my ($self, $o) = @_;
    my $key = $self->fileno;
    if ($o) {
	$__VIA_O{$key} = $o;
	weaken($__VIA_O{$key});
    }
    return $__VIA_O{$key};
}

# want to call this off the filehandle to keep the 
# interface simple...

sub set_write_format {
    my ($self, $format) = @_;
    return unless $self->via_o;
    # delegate
    return $self->via_o->set_write_format($format);
}


1;
__END__

=pod

=head1 NAME

PerlIO::via::SeqIO - PerlIO layer for biological sequence formats

=head1 SYNOPSIS
 
 use PerlIO::via::SeqIO;

 # open a FASTA file for reading:
 open( my $f, "<:via(SeqIO)", 'my.fas');

 # open an EMBL file for writing
 open( my $e, ">:via(SeqIO::embl)", 'my.embl');

 # convert
 print $e $_ while (<$f>);

 # add comments (this really works)
 while (<$f>) {
   # get the real sequence object
   my $seq = O($_);
   if ($seq->desc =~ /Pongo/) {
     print $e "# this one is almost human...";
   }
   print $e $_; 
 }

 # a one-liner, sort of
 $ alias scvt="perl -Ilib \"-MPerlIO::via::SeqIO qw(open)\" -e \"open(STDIN, '<:via(SeqIO)'); open(STDOUT, '>:via(SeqIO::'.shift().')'); while (<STDIN>) { print }\""
 $ cat my.fas | scvt gcg > my.gcg

=head1 DESCRIPTION

C<PerlIO::via::SeqIO> attempts to provide an easy option for
harnessing the magic sequence format I/O of the BioPerl
(L<http://bioperl.org>) toolkit. Opening a biological sequence file
under C<via(SeqIO)> yields a filehandle that can be used to read and
write L<Bio::Seq> objects sequentially with an absolute minimum of
setup code.

C<via(SeqIO)> also allows the user to mix plain text and sequence formats
on a single filehandle transparently. Different sequence formats
can be written to a single file by a simple filehandle tweak.

=head1 DETAILS

=over

=item Basics

Here's the basic idea, in code converting FASTA to EMBL format:

 open($in, '<:via(SeqIO)', 'my.fas');
 open($out, '>:via(SeqIO::embl)', 'my.embl');
 while (<$in>) {
   print $out $_;
 }

=item Specifying sequence formats (or not)

On reading, you can rely on L<Bio::SeqIO>'s format guesser by invoking
an unqualifed

 open($in, '<:via(SeqIO)', 'mystery.txt');

or you can specify the format, like so:

 open($in, '<:via(SeqIO::embl)', 'mystery.txt');

On writing, a qualified invocation is required;

 open($out, '>:via(SeqIO)', 'my.fas');        # throws
 open($out, '>:via(SeqIO::fasta)', 'my.fas'); # that's better

=item Retrieving the sequence object itself

This does what you mean:

 open($in, '<:via(SeqIO)', 'my.fas');
 open($out, '>:via(SeqIO::embl)', 'my.embl');
 while (<$in>) {
   print $out $_;
 }

However, C<$_> here is not the sequence object itself. To get that use 
the all-purpose object getter L<O()|/UTILITIES>:

 while (<$in>) {
   print join("\t", O($_)->id, O($_)->desc), "\n";
 }

If you

 use subs qw(O);

then this DWYM:

 while (<$in>) {
   print O->id;
 }

=item Writing a I<de novo> sequence object

Use the L<T()|/UTILITIES> mapper to convert a Bio::Seq object into a thing that can be formatted by C<via(SeqIO)>:

 open($seqfh, ">:via(SeqIO::embl)", "my.embl");
 my $result = Bio::SearchIO->new( -file=>'my.blast' )->next_result;
 while(my $hit = $result->next_hit()){
   while(my $hsp = $hit->next_hsp()){
     my $aln = $hsp->get_aln;
       print $seqfh T($_) for ($aln->each_seq);
     }
   }

=item Writing plain text

Interspersing plain text among your sequences is easy; just print the
desired text to the handle. See the L</SYNOPSIS>.

Even the following works:

 open($in, "<:via(SeqIO)", 'my.fas')
 open($out, ">:via(SeqIO::embl)", 'annotated.txt');

 $seq = <$in>;
 print $out "In EMBL format, the sequence would be rendered:", $s;

=item Pipe through a gzip layer

You can use the Perlio layer L<PerlIO::via::gzip> to decompress and
compress via(SeqIO) input and output.

Compressed output:

 open(my $tfh,"<:via(SeqIO)", "test.fas");
 open(my $zfh,'>:via(SeqIO::embl):via(gzip)', 'test.embl.gz');
 while (<$tfh>) {
     print $zfh $_;
 }
 close($zfh);

B<GOTCHA>: the C<close> is I<required>.

Decompressed input:

 open($tfh,"<:via(gzip):via(SeqIO::fasta)", "test.fas.gz");
 open(my $zfh,'>:via(SeqIO::embl)', 'test.embl');
 while (<$tfh>) {
     print $zfh $_;
 }

When reading via gzip, the sequence format must be explicitly
specified in the C<via(SeqIO)> mode spec.

Conversion, gzip to gzip:

 open(my $tfh, "<:via(gzip):via(SeqIO::fasta)", "test.fas.gz");
 open(my $zfh, ">:via(gzip):via(SeqIO::embl)", "test.embl.gz");
 local $/;
 print $zfh <$tfh>;
 close($zfh);

=item Redirecting STDIN/STDOUT/DATA through C<via(SeqIO)>

Import the C<open()> function provided by the module, like so

 use PerlIO::via::SeqIO qw(open);

This will provide the following kind of two-argument C<open> functionality

 open(STDIN, '<:via(SeqIO)');
 open(STDOUT, '>:via(SeqIO::gcg)');
 while (<STDIN>) {
   print;
 }

which will allow

 cat my.gcg | perl your.pl > out

C<your.pl> can read STDIN and acquire the sequence objects by
using the object getter L<O()|/UTILITIES>:

 use PerlIO::via::SeqIO qw(open O);
 open (STDIN, '<:via(SeqIO)');
 while (<STDIN>) {
  $seqobj = O($_);
  ...
 }

The format of the input in this case will be guessed by the C<Bio::SeqIO>
machinery.

The imported C<open()> should pass through other uses of C<open>
unharmed.  This is tested in C<001_passthru.t>. Please ping the
L</AUTHOR> if there are issues.


=item Switching write formats

You can also easily switch write formats. (Why? Because...who knows?)
Use L<set_write_format|/UTILITIES> right off the handle:

 open($in, "<:via(SeqIO)", 'my.fas')
 open($out, ">:via(SeqIO::embl)", 'multi.txt');

 $seq1 = <$in>;
 print "This is sequence 1 in embl format:\n";
 print $out $seq1;
 $out->set_write_format('gcg');
 print $out "while this is sequence 1 in GCG format:\n"
 print $out $seq1;

=item Supported Formats

The supported formats are contained in
C<@PerlIO::via::SeqIO::SUPPORTED_FORMATS>. Currently they are

 fasta, embl, gcg, genbank, pir

=back

=head1 UTILITIES

The C<O()> and C<T()> methods are exported by default.

The C<open> hook needs to be available for the 2-argument C<open> redirections
(see L</DETAILS>) to work. Do

 use PerlIO::via::SeqIO qw(open);


=head2 O()

 Title   : O
 Usage   : $o = O($sym) # not an object method
 Function: get the object "represented" by the argument
 Returns : the right object
 Args    : PerlIO::via::SeqIO GLOB, or 
           *PerlIO::via::SeqIO::TFH (tied fh) or
           scalar string (sprintf-rendered Bio::SeqI object)
 Example : $seqobj = O($s = <$seqfh>);

=head2 T()

 Title   : T
 Usage   : T($seqobj) # not an object method
 Function: Transform a real Bio::Seq object to a
           via(SeqIO)-writeable thing
 Returns : A thing writeable as a formatted sequence
           by a via(SeqIO) filehandle
 Args    : a[n array of] Bio::Seq or related object[s]
 Example : print $seqfh T($seqobj);

=head2 set_write_format()

 Title   : set_write_format
 Usage   : $fh->set_write_format($format)
 Function: Set a write handle to write a specified 
           sequence format
 Returns : true on success
 Args    : scalar string; a supported format 
           (see @PerlIO::via::SeqIO::SUPPORTED_FORMATS)
 Note    : call off filehandle directly

=head1 SEE ALSO

L<PerlIO|perlio>, L<PerlIO::via>, L<Bio::SeqIO>, L<Bio::Seq>, 
L<http://bioperl.org>

=head1 AUTHOR - Mark A. Jensen

 Email maj -at- fortinbras -dot- us
 http://fortinbras.us
 http://bioperl.org/wiki/Mark_Jensen

=cut
