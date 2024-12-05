=pod

  # .spvm file
  cat helper/DER_type_names.txt | perl helper/generate_DER.pl Net::SSLeay::DER spvm > .tmp/DER.spvm
  
  # .c file
  cat helper/DER_type_names.txt | perl helper/generate_DER.pl Net::SSLeay::DER c > .tmp/DER.c
  
  # .pm file
  cat helper/DER_type_names.txt | perl helper/generate_DER.pl Net::SSLeay::DER pm > .tmp/DER.pm

=cut

use strict;
use warnings;

my $class_name = shift;
my $type = shift;

while (my $line = <>) {
  
  next if $line =~ /^#/;
  
  chomp $line;
  
  my ($type_name, $has_bio) = split(/,/, $line);
  
  if ($type eq 'spvm') {
    my $output = <<"EOS";
  
  use Net::SSLeay::$type_name;
  
  native static method d2i_$type_name : Net::SSLeay::$type_name (\$a_ref : Net::SSLeay::${type_name}[], \$ppin_ref : string[], \$length : long);
  
  native static method i2d_$type_name : int (\$a : Net::SSLeay::$type_name, \$ppout_ref : string[]);
  
EOS
    
    if ($has_bio) {
      $output .= <<"EOS";
  native static method d2i_${type_name}_bio : Net::SSLeay::$type_name (\$bp : Net::SSLeay::BIO);
  
EOS
    }
    
    print $output;
  }
  elsif ($type eq 'c') {
    my $class_name_c = $class_name;
    $class_name_c =~ s/::/__/g;
    
    my $output = <<"EOS";
int32_t SPVM__${class_name_c}__d2i_$type_name(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_a_ref = stack[0].oval;
  
  void* obj_ppin_ref = stack[1].oval;
  
  int64_t length = stack[2].lval;
  
  if (obj_a_ref) {
    return env->die(env, stack, "\$a_ref must be undef. Currently reuse feature is not available.", __func__, FILE_NAME, __LINE__);
  }
  
  if (!obj_ppin_ref) {
    return env->die(env, stack, "\$ppin_ref must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t ppin_ref_length = env->length(env, stack, obj_ppin_ref);
  
  if (!(ppin_ref_length == 1)) {
    return env->die(env, stack, "The length of \$ppin_ref must be 1.", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_ppin = env->get_elem_string(env, stack, obj_ppin_ref, 0);
  
  if (!obj_ppin) {
    return env->die(env, stack, "\$ppin_ref at index 0 must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  char* ppin = (char*)env->get_chars(env, stack, obj_ppin);
  
  const unsigned char* ppin_ref_tmp[1] = {0};
  ppin_ref_tmp[0] = ppin;
  
  $type_name* ret = d2i_$type_name(NULL, ppin_ref_tmp, length);
  
  if (!ret) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]d2i_$type_name failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  void* obj_ret = env->new_pointer_object_by_name(env, stack, "Net::SSLeay::$type_name", ret, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_ret;
  
  return 0;
}

int32_t SPVM__${class_name_c}__i2d_$type_name(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_a = stack[0].oval;
  
  void* obj_ppout_ref = stack[1].oval;
  
  int64_t length = stack[2].lval;
  
  if (!obj_a) {
    return env->die(env, stack, "\$a must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  $type_name* a = env->get_pointer(env, stack, obj_a);
  
  if (!obj_ppout_ref) {
    return env->die(env, stack, "\$ppout_ref must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t ppout_ref_length = env->length(env, stack, obj_ppout_ref);
  
  if (!(ppout_ref_length == 1)) {
    return env->die(env, stack, "The length of \$ppout_ref must be 1.", __func__, FILE_NAME, __LINE__);
  }
  
  unsigned char* ppout_ref_tmp[1] = {0};
  int32_t status = i2d_$type_name(a, ppout_ref_tmp);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]i2d_$type_name failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  void* obj_ppout = env->new_string_nolen(env, stack, ppout_ref_tmp[0]);
  
  env->set_elem_object(env, stack, obj_ppout_ref, 0, obj_ppout);
  
  stack[0].ival = status;
  
  return 0;
}

EOS

    if ($has_bio) {
      $output .= <<"EOS";
int32_t SPVM__${class_name_c}__d2i_${type_name}_bio(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_bio = stack[0].oval;
  
  if (!obj_bio) {
    return env->die(env, stack, "The BIO object \$bio must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  BIO* bio = env->get_pointer(env, stack, obj_bio);
  
  $type_name* ret = d2i_${type_name}_bio(bio, NULL);
  
  if (!ret) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]d2i_${type_name}_bio failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  void* obj_ret = env->new_pointer_object_by_name(env, stack, "Net::SSLeay::$type_name", ret, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_ret;
  
  return 0;
}

EOS
    }
    
    print $output;
  }
  elsif ($type eq 'pm') {
    my $output = <<"EOS";
=head2 d2i_$type_name

C<static method d2i_$type_name : L<Net::SSLeay::$type_name|SPVM::Net::SSLeay::$type_name> (\$a_ref : L<Net::SSLeay::${type_name}|SPVM::Net::SSLeay::${type_name}>[], \$ppin_ref : string[], \$length : long);>

See L</"d2i_TYPE"> template method.

=head2 i2d_$type_name

C<static method i2d_$type_name : int (\$a : L<Net::SSLeay::$type_name|SPVM::Net::SSLeay::$type_name>, \$ppout_ref : string[]);>

See L</"i2d_TYPE"> template method.

EOS
    
    if ($has_bio) {
      $output .= <<"EOS";
=head2 d2i_${type_name}_bio

C<static method d2i_${type_name}_bio : L<Net::SSLeay::$type_name|SPVM::Net::SSLeay::$type_name> (\$bio : L<Net::SSLeay::BIO|SPVM::Net::SSLeay::BIO>);>

See L</"d2i_TYPE_bio"> template method.

EOS
    }
    print $output;
  }
  else {
    die;
  }
}
