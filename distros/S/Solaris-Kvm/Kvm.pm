package Solaris::Kvm;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Solaris::Kvm ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	STB_GLOBAL	
	STB_WEAK
	STB_NUM

	STT_NOTYPE	
	STT_OBJECT
	STT_FUNC
	STT_SECTION	
	STT_FILE
	STT_COMMON	
	STT_TLS		
	STT_NUM	

	STV_DEFAULT
	STV_INTERNAL
	STV_HIDDEN
	STV_PROTECTED
);
our $VERSION = '0.02';

bootstrap Solaris::Kvm $VERSION;

# Preloaded methods go here.

sub AUTOLOAD {
   my $self = shift;
   my $prop;
   my $val;

   ($prop = $Solaris::Kvm::AUTOLOAD) =~ s/.*:://g;
   if (ref $self eq "Solaris::Kvm" ) {
      if (exists($self->{$prop})) {
         return $self->{$prop};
      } else {
         $self->rAUTOLOAD($prop, @_);
      }
   } else {
      $val = constant($prop, 0);
      croak "Your vendor has not defined Elf macro $val" if $!;
      no strict 'refs';
      *$Solaris::Kvm::AUTOLOAD = sub { $val };
      goto &$Solaris::Kvm::AUTOLOAD;
   }
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Solaris::Kvm - Perl interface to Solaris Kernel Virtual Memory Access
	       Library (libkvm)

=head1 SYNOPSIS

  use Solaris::Kvm;
  
  $handle = new Solaris::Kvm();
  printf "value of maxusers %d\n", $handle->maxusers;
  printf "size of maxusers variable %d\n", $handle->size('maxusers');

=head1 DESCRIPTION

Solaris::Kvm allows read access to Solaris kernel variables through the tied hash interface. 
By default, the module reads the /dev/ksyms namelist, but it is also possible to use an
alternative namelist by passing its name to the module constructor:

   $handle = new Solaris::Kvm("/my_namelist");

The value of a particular kernel variable can by looked up by simply retrieving the element from the hash
using the name of the variable as a key:

   printf "maxusers: %d\n", $handle->{maxusers};

Note, the value is automatically refreshed for every lookup - i.e. internally, the FETCH routine
calls kvm_kread().
Variable value can also be retrieved using the subroutine/method syntax:

   printf "maxusers: %d\n", $handle->maxusers;

although, it is slightly less efficient since such call is dispatched through the AUTOLOAD function.
In addition to reading the values of kernel variables, the module is capable of providing the size
of a variable (in bytes), its type (object, function, etc) as well as its bind (local, global, etc) and
visibility (internal, protected, etc):

   printf "maxusers size: %d\n", $handle->size('maxusers');
   printf "maxusers type: %d\n", $handle->type('maxusers');
   printf "maxusers bind: %d\n", $handle->bind('maxusers');
   printf "maxusers visibility: %d\n", $handle->visibility('maxusers');

All these functions return standard ELF constants (STT_OBJECT, STT_HIDDEN, etc), defined in elf.h.
The "write" function is disabled - those who wish to modify the values of kernel variables should
really use /etc/system...;-).

=head2 EXPORT

	STB_GLOBAL	
	STB_WEAK
	STB_NUM
	STT_NOTYPE	
	STT_OBJECT
	STT_FUNC
	STT_SECTION	
	STT_FILE
	STT_COMMON	
	STT_TLS		
	STT_NUM	
	STV_DEFAULT
	STV_INTERNAL
	STV_HIDDEN
	STV_PROTECTED

=head1 AUTHOR

Alexander Golomshtok<lt>golomshtok_alexander@jpmorgan.com<gt>

=head1 SEE ALSO

L<libkvm(3LIB)>, L<perl>.

=cut
