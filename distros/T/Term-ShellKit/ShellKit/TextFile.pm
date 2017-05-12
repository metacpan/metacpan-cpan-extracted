package Term::ShellKit::TextFile;

require Term::ShellKit;

######################################################################

sub file_slurp {
  my $file = shift;
  # warn "Reading file: $file\n";
  local *FILE;
  open FILE, "$file" or die "Can't open $file: $!";
  local $/ = undef;
  return <FILE>;
}

sub file_splurt {
  my $file = shift;
  # warn "Writing file: $file \n";
  local *FILE;
  open FILE, ">$file" or die "Can't write to $file: $!";
  print FILE shift();
}

######################################################################

sub show_file {
  my $file = shift;
  my %opts = @_;
  
  if ( exists $opts{number} ) {
    $opts{number} = ( $opts{number} and $opts{number} !~ /^n/ ) ? 1 : 0
  }
  
  if ( $opts{line} ) {
    $opts{line} =~ s/\D//g;
    $opts{window} ||= 2;
  } else {
    warn "No windows without lines" if $opts{window};
  }
  
  my $text = file_slurp( $file );
  my @lines = split /\n/, $text;

  if ( $opts{number} ) { 
    my $i = 1;
    foreach ( @lines ) { $_ = ($i ++) . ": " . $_ }
  }
  if ( $opts{line} ) {
    @lines = @lines[ $opts{line} - $opts{window} .. $opts{line} + $opts{window} ];
  } 
  @lines;
}

######################################################################

sub file_grep { 
  my $str = shift; 
  $shell->shell_auto_command( qw( execute find ), @_, qw( -type f -exec egrep ),  $str, '{}', '/dev/null', "\\;" );
}

######################################################################

use Cwd; 
use File::Find;

sub find_text {
  my $term = shift(@ARGV);
  $term = "\Q$term" if $q;
  
  my $dirs = join(' ', @ARGV)
    || join(' ', map "/opt/bdev/$_", qw( lib htdocs Manager includes bin conf ))
    || '.';
  
  my @skips = qw( CVS .dir5_0.wmd .#* *.jpg *.jpeg *.gif *.bmp );
  
  my $command = "find $dirs \\( " . join(' -o ', map "-name '$_'", @skips ) . " \\) -prune -o -type f -exec egrep '$term' {} /dev/null \\;";
  
  print "$0: $command\n\n" if ( $v );
  
  exec( $command );
}

sub replace_text {
  my $term = shift(@_);
  
  $term = "(\Q$term\E)" unless ( $p );
  
  $term = "(?i)$term" if ( $i );
  $term = "(?e)$term" if ( $e );
  
  my $rplc = shift(@_);
  
  my $cwd = cwd();
  my @targets = scalar(@_) ? map ( "$cwd/$_", @_ ) : $cwd;
  
  print "$0: {$term} => {$rplc} in ". join(', ', @targets) . "\n";
  
  my $tempfile = File::Name->new( '/tmp/tmp_replace_text_buffer' );
  
  finddepth( sub { 
    my $filename = $File::Find::name;
    if ( $filename =~ m{/CVS/} ) {
      next;
    }
    if ( $filename =~ m{/\.} ) {
      next;
    }
    if ( -d $filename ) {
      next;
    }
    unless ( -R $filename ) {
      warn "Skipping $filename, not readable...\n" if ( $v );
      next;
    }
    warn "Scanning $filename...\n" if ( $v );
    
    my $contents = file_slurp($filename);
    next unless $contents =~ /$term/;
    
    unless ( $f ) {
      while ( 1 ) {
	print "$0: Change $filename? (Yes/no/view/all/quit) ";
	my $in = <STDIN>;
	if ( ! $in or $in =~ /^y/i ) {
	  last;
	} elsif ( $in =~ /^n/i ) {
	  return;
	} elsif ( $in =~ /^a/i ) {
	  ++ $f;
	  last;
	} elsif ( $in =~ /^q/i ) {
	  exit;
	} elsif ( $in =~ /^v/i ) {
	  my $temp = $contents;
	  $temp =~ s{$term}{$rplc}g;
	  $tempfile->set_text_contents($temp);
	  system("diff -C1 $filename $$tempfile | more");
	}
      }
    }
    
    $contents =~ s{$term}{$rplc}g;
    warn "Changing $filename...\n" if ( $v );
    splurt_file($filename, $contents);
  
    1; 
  }, @targets );
}

1;

######################################################################

=head1 COMMANDS

The following commands are available.


=head2 show_file (alias at)

Show the contents of a file.

=over 4

=item *

show_file I<filename>: Display file contents.

=item *

show_file I<filename> line I<lineno> (window I<lines>): show a window of I<lines>, or by default 3, around the specific I<lineno>.

=item *

show_file I<filename> number yes: show line numbers

=back


=head2 file_grep

Recursive grep through directories.

=over 4

=item *

file_grep I<expr> I<files_or_directories...>

=back
