package SIL::FS;

use strict;

sub process_manifest
{
    my ($self, $str) = @_;
    my ($res, $s, $name, $type, @parts);
    
    foreach $s (split(/\n/, $str))
    { 
        chomp $s;
        my ($name, $type, @parts) = split(/(?:\s{2,}|\t)+/, $s);
        $name =~ s|\\|/|og;
        $res->{$name} = [$type, {@parts}];
    }
    return $res;
}

sub remove_list
{
    my ($self, $absname) = @_;
    my ($relname) = File::Spec->abs2rel($absname, $self->{'root'});
    $relname =~ s/^[A-Z]://o;
    $self->{'filelist'} = [grep ($_ ne $relname, @{$self->{'filelist'}})];
}


package SIL::FS::File;

use File::Find;
use File::Spec;
use File::Path;
use IO::File;
use Carp;

use vars qw(@ISA);
@ISA = qw(SIL::FS);

sub new
{
    my ($class, $root, %opts) = @_;
    my ($self) = {'root' => $root};
    
    bless $self, ref $class || $class;
    if ($opts{'-manfile'})
    { 
        my ($manifest, $manfh, $manf);
        
        $manf = File::Spec->rel2abs($opts{'-manfile'}, $root);
        $manfh = IO::File->new("< $manf") || warn "Can't open $opts{'-manfile'}";
        if ($manfh)
        {
            $manifest = join('', <$manfh>);
            $manfh->close;
            $self->{'manifest'} = $self->process_manifest($manifest); 
            $self->{'filelist'} = [sort keys %{$self->{'manifest'}}];
        }
    }
    elsif ($opts{'-manifest'})
    { 
        $self->{'manifest'} = $opts{'-manifest'};
        $self->{'filelist'} = [sort keys %{$opts{'-manifest'}}];
    }
    else
    { $self->{'filelist'} = [$self->get_filelist($root)]; }
    $self;
}

sub exists
{
    my ($self, $fname);
    my ($absname) = File::Spec->rel2abs($fname, $self->{'root'});
    
    return -e $absname;
}
    

sub get_filelist
{
    my ($self, $root) = @_;
    my (@list);
    
    find(sub {
        return unless (-f $_);
        my ($relname) = File::Spec->abs2rel($File::Find::name, $root);
        $relname =~ s/^[A-Z]://o;
        push (@list, $relname);
    }, $root);
    
    return sort @list;
}

sub get_lines
{
    my ($self, $fname) = @_;
    my ($absname, $fh, @lines);
    
    $absname = File::Spec->rel2abs($fname, $self->{'root'});
    $fh = IO::File->new("< $absname") || return ();
    @lines = <$fh>;
    $fh->close;
    chomp(@lines);
    return @lines;
}

sub get_str
{
    my ($self, $fname) = @_;
    my ($absname, $fh, @lines);
    
    $absname = File::Spec->rel2abs($fname, $self->{'root'});
    $fh = IO::File->new("< $absname") || return ();
    @lines = <$fh>;
    $fh->close;
    return join('', @lines);
}


sub put_lines
{
    my ($self, $fname, @lines) = @_;
    my ($absname, $fh);
    my ($vol, $dir, $file);

    $absname = File::Spec->rel2abs($fname, $self->{'root'});
    ($vol, $dir, $file) = File::Spec->splitpath($absname);
    unless (-d File::Spec->catpath($vol, $dir))
    { mkpath(File::Spec->catpath($vol, $dir)); }
    $fh = IO::File->new("> $absname") || confess "Can't open $absname for reading";
    $fh->print(join("\n", @lines));
}

sub put_str
{
    my ($self, $fname, $str) = @_;
    my ($absname, $fh);
    my ($vol, $dir, $file);

    $absname = File::Spec->rel2abs($fname, $self->{'root'});
    ($vol, $dir, $file) = File::Spec->splitpath($absname);
    unless (-d File::Spec->catpath($vol, $dir))
    { mkpath(File::Spec->catpath($vol, $dir)); }
    $fh = IO::File->new("> $absname") || confess "Can't open $absname for reading";
    $fh->print($str);
}

package SIL::FS::Zip;

use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use File::Temp qw(:POSIX);
use File::Copy;
use Carp;

use vars qw(@ISA);
@ISA = qw(SIL::FS);


sub new
{
    my ($class, $fname, %opts) = @_;
    my ($self) = {'fname' => $fname};

    bless $self, ref $class || $class;
    if ($fname)
    { $self->{'archive'} = Archive::Zip->new($fname) || confess "Can't open $fname as a zip file"; }
    else
    { $self->{'archive'} = Archive::Zip->new(); }
    
    if ($opts{'-manfile'})
    { 
        my ($manifest) = $self->{'archive'}->contents($opts{'-manfile'}) || warn "Can't find $opts{'-manfile'} in $fname";
        if ($manifest)
        {
            $self->{'manifest'} = $self->process_manifest($manifest); 
            $self->{'filelist'} = [sort keys %{$self->{'manifest'}}];
        }
    }
    elsif ($opts{'-manifest'})
    { 
        $self->{'manifest'} = $opts{'-manifest'};
        $self->{'filelist'} = [sort keys %{$opts{'-manifest'}}];
    }
    elsif ($opts{-io} !~ m/w/o)
    { $self->{'filelist'} = [$self->get_filelist($self->{'archive'})]; }
    $self;
}

sub exists
{
    my ($self, $fname) = @_;
    return $self->{'archive'}->memberNamed($fname);
}

sub get_filelist
{
    my ($self, $archive) = @_;
    my (@list);
    
    @list = $archive->memberNames();
    return sort @list;
}

sub get_lines
{
    my ($self, $fname) = @_;
    my ($contents) = $self->{'archive'}->contents($fname);
    my (@lines) = split(/\r\n|\r|\n/, $contents);
    return @lines;
}

sub put_lines
{
    my ($self, $fname, @lines) = @_;
    my ($member) = $self->{'archive'}->memberNamed($fname);
    
    if ($member)
    { $member->contents(join("\n", @lines)); }
    else
    { 
        $member = $self->{'archive'}->addString(join("\n", @lines), $fname); 
        $member->desiredCompressionMethod( COMPRESSION_DEFLATED );
    }
}

sub get_str
{
    my ($self, $fname) = @_;
    my ($contents) = $self->{'archive'}->contents($fname);
    return $contents;
}

sub put_str
{
    my ($self, $fname, $str) = @_;
    my ($member) = $self->{'archive'}->memberNamed($fname);
    
    if ($member)
    { $member->contents($str); }
    else
    { 
        $member = $self->{'archive'}->addString($str, $fname); 
        $member->desiredCompressionMethod( COMPRESSION_DEFLATED );
    }
}

sub writeTo
{
    my ($self, $fname) = @_;
    if ($fname eq $self->{'fname'})
    {
        $fname = tmpnam();
        $self->{'archive'}->writeToFileNamed($fname);
        copy($fname, $self->{'fname'});
    }
    else
    { $self->{'archive'}->writeToFileNamed($fname); }
}

package SIL::FS::Scalar;

=head1 TITLE

This is a copy of IO::scalar

=cut

sub new {
    my $self = bless {}, shift;
    $self->open(@_) if @_;
    $self;
}

sub DESTROY { 
    shift->close;
}


sub open {
    my ($self, $sref) = @_;

    # Sanity:
    defined($sref) or do {my $s = ''; $sref = \$s};
    (ref($sref) eq "SCALAR") or die "open() needs a ref to a scalar";

    # Setup:
    $self->{Pos} = 0;
    $self->{SR} = $sref;
    $self;
}

sub close {
    my $self = shift;
    %$self = ();
    1;
}

sub getc {
    my $self = shift;
    
    # Return undef right away if at EOF; else, move pos forward:
    return undef if $self->eof;  
    substr(${$self->{SR}}, $self->{Pos}++, 1);
}

sub getline {
    my $self = shift;

    # Return undef right away if at EOF:
    return undef if $self->eof;

    # Get next line:
    pos(${$self->{SR}}) = $self->{Pos}; # start matching at this point
    ${$self->{SR}} =~ m/(.*?)(\n|\Z)/g; # match up to newline or EOS
    my $line = $1.$2;                   # save it
    $self->{Pos} += length($line);      # everybody remember where we parked!
    return $line; 
}

sub getlines {
    my $self = shift;
    wantarray or croak("Can't call getlines in scalar context!");
    my ($line, @lines);
    push @lines, $line while (defined($line = $self->getline));
    @lines;
}

sub print {
    my $self = shift;
    my $eofpos = length(${$self->{SR}});
    my $str = join('', @_);

    if ($self->{'Pos'} == $eofpos)
    {
        ${$self->{SR}} .= $str;
        $self->{Pos} = length(${$self->{SR}});
    } else
    {
        substr(${$self->{SR}}, $self->{Pos}, length($str)) = $str;
        $self->{Pos} += length($str);
    }
    1;
}

sub read {
    my ($self, $buf, $n, $off) = @_;
    die "OFFSET not yet supported" if defined($off);
    my $read = substr(${$self->{SR}}, $self->{Pos}, $n);
    $self->{Pos} += length($read);
    $_[1] = $read;
    return length($read);
}

sub eof {
    my $self = shift;
    ($self->{Pos} >= length(${$self->{SR}}));
}

sub seek {
    my ($self, $pos, $whence) = @_;
    my $eofpos = length(${$self->{SR}});

    # Seek:
    if    ($whence == 0) { $self->{Pos} = $pos }             # SEEK_SET
    elsif ($whence == 1) { $self->{Pos} += $pos }            # SEEK_CUR
    elsif ($whence == 2) { $self->{Pos} = $eofpos + $pos}    # SEEK_END
    else                 { die "bad seek whence ($whence)" }

    # Fixup:
    if ($self->{Pos} < 0)       { $self->{Pos} = 0 }
    if ($self->{Pos} > $eofpos) { $self->{Pos} = $eofpos }
    1;
}

sub tell { shift->{Pos} }

        
1;
