=head1 NAME

Bio::Polloc - Perl library for Polymorphic Loci Analyses

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Bio::Polloc::Polloc::Root;

use strict;
use Bio::Polloc::Polloc::Version;
use Bio::Polloc::Polloc::IO;
use Bio::Polloc::Polloc::Error;
use Error qw(:try);

=head1 GLOBALS

Global variables controling the behavior of the package

=cut

our($VERBOSITY, $DOER, $DEBUGLOG, $TIMESTAMP);

=head2 VERSION

The package's version

=cut

our $VERSION = 1.0503; # [a-version] from Bio::Polloc::Polloc::Version


=head2 VERBOSITY

Verbosity level

=cut

$VERBOSITY = 0;
sub VERBOSITY { shift; $VERBOSITY = 0 + shift }

=head2 TIMESTAMP

Should I report the current Unix time on each debug line?

=cut

$TIMESTAMP = 0;
sub TIMESTAMP { shift; $TIMESTAMP = shift }

=head2 DOER

Should I save my work?  Provided for testing purposes

=cut

$DOER = 1;
sub DOER { shift ; $DOER = shift }

=head2 DEBUGLOG

Sets the file at which debug information should be saved
if VERBOSITY is greater or equal to 2, and returns a
L<Bio::Polloc::Polloc::IO> object to write on it.

=cut

sub DEBUGLOG {
   my $self = shift;
   $DEBUGLOG = Bio::Polloc::Polloc::IO->new(@_) if $#_ >= 0;
   return $DEBUGLOG;
}

=head1 PUBLIC METHODS

Methods provided by the package
 
=head2 new

Generic instantiation function

=cut
sub new {
   my $class = shift;
   my $self = {};
   bless $self, ref($class) || $class;
   if( @_ > 1 ){
      shift if @_ % 2;
      my %param = @_;
      $self->verbosity($param{'-VERBOSE'} || $param{'-verbose'});
   }
   return $self;
}


=head2 verbosity

Gets/sets the verbosity level

=head3 Arguments

=over

=item An integer

 -1 : No warnings
  0 : Display warnings
  1 : Display warnings with stacktrace
  2 : + debug information
  3 : + throw on warning

=back

=head3 Returns

An integer (as the arguments)

=cut

sub verbosity {
   my($self,$value) = @_;
   return $VERBOSITY unless ref $self;
   $self->{'_verbosity'} = ($value+0) if defined $value;
   $self->{'_verbosity'} = $VERBOSITY unless defined $self->{'_verbosity'};
   return $self->{'_verbosity'};
}


=head2 throw

Throws an Exception

=head3 Arguments

=over

=item -text

The message of the error

=item -value

The element causing the error

=item -class

The exception class (L<Bio::Polloc::Polloc::Error> by default)

=back

=head3 Returns

Nothing

=cut

sub throw {
   my ($self, @args) = @_;
   my ($text, $value, $class) =
   	$self->_rearrange([qw(TEXT VALUE CLASS)], @args);
   $class ||= "Bio::Polloc::Polloc::Error";
   $class->throw( -text=>$text, -value=>$value, -object=>$self );
}


=head2 debug

Appends debug information to the L<$Bio::Polloc::Polloc::DEBUGLOG> or STDERR
if verbosity is greater than 1

=cut

sub debug {
   my($self,@txt) = @_;
   if($self->verbosity >= 2){
      my $msg = "" . ($TIMESTAMP ? "[".time()."] " : '') . ref($self) . " | " . join(' ', @txt) . "\n";
      if(defined $self->DEBUGLOG){ $self->DEBUGLOG->_print($msg) }
      else{ print STDERR $msg }
   }
}


=head2 warn

Launches a warning message.  If verbosity is greater than two, the
message becomes a C<throw>.

=cut

sub warn {
   my ($self, $txt, $value) = @_;
   my $verb = $self->verbosity;
   return if $verb==-1;
   $self->throw($txt,$value,'Bio::Polloc::Polloc::LoudWarningException') if $verb >=3;
   my $out = "\n" . ("-"x10) . " WARNING " . ("-"x10) . "\n" .
   	"MSG: " . $txt . "\n" ;
   $out.= "VALUE: $value - ".ref($value)."\n" if defined $value;
   if($verb>=1){
      $out.= $self->stack_trace_dump;
   }
   $out.= ("-"x29) . "\n";
   print STDERR $out;
   return;
}


=head2 stack_trace_dump

=cut

sub stack_trace_dump {
   my $self = shift;
   my @stack = $self->stack_trace;

   shift @stack; # stack_trace
   shift @stack; # stack_trace_dump
   shift @stack; # error_msg

   my $out = "";
   for my $stack ( @stack ){
      my ($module, $file, $position, $function) = @{$stack};
      $out.= "STACK $function $file:$position\n";
   }
   return $out;
}

=head2 strack_trace

=cut

sub stack_trace {
   my $self = shift;
   my $i = 0;
   my @out = ();
   my $prev = [];
   while( my @call = caller($i++)){
      $prev->[3] = $call[3];
      push @out, $prev;
      $prev = \@call;
   }
   $prev->[3] = 'toplevel';
   push @out, $prev;
   return @out;
}


=head2 vardump

Attempts to display all the content of a given object

=head3 Arguments

Some object (any type)

=head3 Returns

Nothing, the result is sent to STDOUT

=cut

sub vardump {
	my ($self,$value) = @_;
	if(!defined $value){
		print "\nundef.\n";
	}elsif(ref($value) =~ /hash/i){
		print "{\n";
		for my $k ( keys %$value ){
			print "$k=>";
			$self->vardump($value->{$k});
			print "\n";
		}
		print "\n}\n";
	}elsif(ref($value) =~ /array/i){
		print "[\n";
		for (@$value){
			$self->vardump($_);
			print "\n";
		}
		print "\n]\n";
	}else{
		print $value;
	}
}

=head2 rrmdir

Recursively removes a directory.

=cut

sub rrmdir {
   my ($self, $dir) = @_;
   return unless -d $dir;
   while(my $file = <$dir/*>){
      next if $file =~ /^\.\.?$/;
      $file = Bio::Polloc::Polloc::IO->catfile($dir, $file);
      if(-d $file){ $self->rrmdir($file) }
      else { unlink $file }
   }
   rmdir $dir;
}

=head1 INTERNAL METHODS

Methods intended to be used only witin the scope of Bio::Polloc::*

=head2 _rearrange

=cut

sub _rearrange {
   my $self = shift;
   my $order = shift;
   return unless $#_>=0 && defined $_[0];
   return @_ unless $_[0] =~ m/^-/;
   push @_, undef unless $#_%2;
   my %param;
   while(@_){
      (my $key = shift) =~ tr/a-z\055/A-Z/d; #deletes all dashes!
      $param{$key} = shift;
   }
   map { $_ = uc($_) } @$order;
   return @param{@$order};
}

=head2 _load_module

=cut

sub _load_module {
   my($self, $name) = @_;
   my($module, $load);
   $module = "_<$name.pm";
   return 1 if $main::{$module};

   $self->throw("Illegal perl package name", $name) unless $name =~ m/^([\w:]+)$/;
   $load = "$name.pm";
   my $io = Bio::Polloc::Polloc::IO->new();
   $load = $io->catfile((split /::/, $load));
   eval {
      require $load;
   };
   $self->throw("Failed to load module. ".$@, $name) if $@;
   return 1;
}

=head2 _register_cleanup_method

=cut

sub _register_cleanup_method {
   my($self, $method) = @_;
   return unless $method;
   $self->{'_cleanup_methods'} ||= [];
   push @{$self->{'_cleanup_methods'}}, $method;
}

=head2 _unregister_cleanup_method

=cut

sub _unregister_cleanup_method {
   my($self, $method) = @_;
   my @keep = grep {$_ ne $method} $self->_cleanup_methods;
   $self->{'_cleanup_methods'} = \@keep;
}

=head2 _cleanup_methods

=cut

sub _cleanup_methods {
   my $self = shift;
   return unless ref $self && $self->isa('HASH');
   my $methods = $self->{'_cleanup_methods'} or return;
   @$methods;
}

=head2 DESTROY

=cut

sub DESTROY {
   my $self = shift;
   my @cleanup_methods = $self->_cleanup_methods or return;
   for my $method (@cleanup_methods){
      $method->($self);
   }
}

1;
