=pod
  
  # .spvm file
  cat helper/constants.txt | perl helper/constants.pl Compress::Raw::Zlib::Constant spvm > .tmp/Constant.spvm

  # .c file
  cat helper/constants.txt | perl helper/constants.pl Compress::Raw::Zlib::Constant c > .tmp/Constant.c

  # .pm file
  cat helper/constants.txt | perl helper/constants.pl Compress::Raw::Zlib::Constant pm > .tmp/Constant.pm

=cut

use strict;
use warnings;

my $class_name = shift;
my $type = shift;

while (my $line = <>) {
  chomp $line;
  
  my $constant_name = $line;
  
  if ($type eq 'spvm') {
    my $output = "  native static method $constant_name : int ();\n\n";
    
    print $output;
  }
  elsif ($type eq 'c') {
    my $class_name_c = $class_name;
    $class_name_c =~ s/::/__/g;
    
    my $output = <<"EOS";
int32_t SPVM__${class_name_c}__$constant_name(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef $constant_name
  stack[0].ival = $constant_name;
  return 0;
#else
  env->die(env, stack, "$constant_name is not defined on the system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

EOS

    print $output;
  }
  elsif ($type eq 'pm') {
    my $output = <<"EOS";
=head2 $constant_name

C<static method $constant_name : int ();>

Returns the value of C<$constant_name>. If this constant is not defined on the system, an exception is thrown with the error id set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

EOS
    
    print $output;
  }
  else {
    die;
  }
}