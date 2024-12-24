package SPVM::Net::SSLeay::SSL_CTX;



1;

=head1 Name

SPVM::Net::SSLeay::SSL_CTX - SSL_CTX data structure in OpenSSL

=head1 Description

Net::SSLeay::SSL_CTX class in L<SPVM> represents C<SSL_CTX> data structure in OpenSSL.

=head1 Usage

  use Net::SSLeay::SSL_CTX;

=head1 Detais

=head2 Callback Hack

C<SSL_CTX> uses a number of callback functions.

These callbacks cannot receive a L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX> object.

See L<Callback Hack|SPVM::Net::SSLeay/"Callback Hack"> about the way resolving this problem.

In this case, a native C<SSL> object in the documentis replaced with a native C<SSL_CTX> object, and L<Net::SSLeay|SPVM::Net::SSLeay> object in the document is replaced with L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX> object.

=head1 Fields

=head2 verify_callback

C<has verify_callback : ro L<Net::SSLeay::Callback::Verify|SPVM::Net::SSLeay::Callback::Verify>;>

A callback set by L</"set_verify"> method.

=head2 default_passwd_cb

C<has default_passwd_cb : ro L<Net::SSLeay::Callback::PemPassword|SPVM::Net::SSLeay::Callback::PemPassword>;>

A callback set by L</"set_default_passwd_cb"> method.

=head2 alpn_select_cb

C<has alpn_select_cb : ro L<Net::SSLeay::Callback::AlpnSelect|SPVM::Net::SSLeay::Callback::AlpnSelect>;>

A callback set by L</"set_alpn_select_cb"> method.

=head2 alpn_select_cb_output

C<has alpn_select_cb_output : string;>

An output string returned by calling the callback in L</"alpn_select_cb"> field.

=head2 tlsext_servername_callback

C<has tlsext_servername_callback : ro L<Net::SSLeay::Callback::TlsextServername|SPVM::Net::SSLeay::Callback::TlsextServername>;>

A callback set by L</"set_tlsext_servername_callback"> method.

=head1 Class Methods

=head2 new

C<static method new : L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX> ($method : L<Net::SSLeay::SSL_METHOD|SPVM::Net::SSLeay::SSL_METHOD>);>

Calls native L<SSL_CTX_new|https://docs.openssl.org/master/man3/SSL_CTX_new> function given the pointer value of $method, enables C<SSL_MODE_AUTO_RETRY> mode, creates a new L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX> object, sets the pointer value of the new object to the return value of the native function.

And calls L</"init"> method.

And returns the new object.

Exceptions:

If SSL_CTX_new failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head1 Instance Methods

=head2 init

C<protected method init : void ($options : object[] = undef);>

Initializes the instance given the options $options.

Performes L<Initialization process described in Callback Hack|/"Callback Hack">.

=head2 get_mode

C<method get_mode : long ();>

Calls native L<SSL_CTX_get_mode|https://docs.openssl.org/master/man3/SSL_CTX_get_mode> function given the pointer value of the instance, and returns its return value.

=head2 set_mode

C<method set_mode : long ($mode : long);>

Calls native L<SSL_CTX_set_mode|https://docs.openssl.org/master/man3/SSL_CTX_set_mode> function given the pointer value of the instance, $mode, and returns its return value.

=head2 get0_param

C<method get0_param : L<Net::SSLeay::X509_VERIFY_PARAM|SPVM::Net::SSLeay::X509_VERIFY_PARAM> ();>

Calls native L<SSL_CTX_get0_param|https://docs.openssl.org/master/man3/SSL_CTX_get0_param> function, creates a L<Net::SSLeay::X509_VERIFY_PARAM|SPVM::Net::SSLeay::X509_VERIFY_PARAM> object, sets the pointer value of the new object to the return value of the native function, sets C<no_free> flag of the new object to 1, creates a reference from the new object to the instance, and returns the new object.

=head2 load_verify_locations

C<method load_verify_locations : int ($CAfile : string, $CApath : string);>

Calls native L<SSL_CTX_load_verify_locations|https://docs.openssl.org/master/man3/SSL_CTX_load_verify_locations> function given the pointer value of the instance, $CAfile, $CApath, and returns its return value.

Exceptions:

If SSL_CTX_load_verify_locations failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 set_default_verify_paths

C<method set_default_verify_paths : int ();>

Calls native L<SSL_CTX_set_default_verify_paths|https://docs.openssl.org/master/man3/SSL_CTX_set_default_verify_paths> function, and returns its return value.

Exceptions:

If SSL_CTX_set_default_verify_paths failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 set_default_verify_paths_windows

C<method set_default_verify_paths_windows : void ();>

It behaves as if L</"set_default_verify_paths"> is performed in Windows using the way described below.

L<https://stackoverflow.com/questions/9507184/can-openssl-on-windows-use-the-system-certificate-store>

Requirement:

Windows

Exceptions:

If CertOpenSystemStore failed, an exception is thrown.

d2i_X509 failed, an exception is thrown.

X509_STORE_add_cert failed, an exception is thrown.
      
=head2 use_certificate_file

C<method use_certificate_file : int ($file : string, $type : int = -1);>

Calls native L<SSL_CTX_use_certificate_file|https://docs.openssl.org/master/man3/SSL_CTX_use_certificate_file> function given the pointer value of the instance, $file, $type, and returns its return value.

If $type is a negative integer, $type is set to C<SSL_FILETYPE_PEM>.

Exceptions:

The file $file must be defined. Otherwise an exception is thrown.

If SSL_CTX_use_certificate_file failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 use_certificate_chain_file

C<method use_certificate_chain_file : int ($file : string);>

Calls native L<SSL_CTX_use_certificate_chain_file|https://docs.openssl.org/master/man3/SSL_CTX_use_certificate_chain_file> function given the pointer value of the instance, $file, and returns its return value.
 
Exceptions:

If SSL_CTX_use_certificate_chain_file failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 use_PrivateKey_file

C<method use_PrivateKey_file : int ($file : string, $type : int = -1);>

Calls native L<SSL_CTX_use_PrivateKey_file|https://docs.openssl.org/master/man3/SSL_CTX_use_PrivateKey_file> function given the pointer value of the instance, $file, $type, and returns its return value.

If $type is a negative integer, $type is set to C<SSL_FILETYPE_PEM>.

Exceptions:

The file $file must be defined. Otherwise an exception is thrown.

If SSL_CTX_use_PrivateKey_file failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 use_PrivateKey

C<method use_PrivateKey : int ($pkey : L<Net::SSLeay::EVP_PKEY|SPVM::Net::SSLeay::EVP_PKEY>);>

Calls native L<SSL_CTX_use_PrivateKey|https://docs.openssl.org/master/man3/SSL_CTX_use_PrivateKey> function given the pointer value of the instance, the pointer value of $pkey, and returns its return value.

Exceptions:

The EVP_PKEY object $pkey must be defined. Otherwise an exception is thrown.

If SSL_CTX_use_PrivateKey failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 set_cipher_list

C<method set_cipher_list : int ($str : string);>

Calls native L<SSL_CTX_set_cipher_list|https://docs.openssl.org/master/man3/SSL_CTX_set_cipher_list> function given the pointer value of the instance, $str, and returns its return value.

Exceptions:

The cipher list $str must be defined. Otherwise an exception is thrown.

If SSL_CTX_set_cipher_list failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 set_ciphersuites

C<method set_ciphersuites : int ($str : string);>

Calls native L<SSL_CTX_set_ciphersuites|https://docs.openssl.org/master/man3/SSL_CTX_set_ciphersuites> function given the pointer value of the instance, $str, and returns its return value.

Exceptions:

The ciphersuites $str must be defined. Otherwise an exception is thrown.

If SSL_CTX_set_ciphersuites failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 get_cert_store

C<method get_cert_store : L<Net::SSLeay::X509_STORE|SPVM::Net::SSLeay::X509_STORE> ();>

Calls native L<SSL_CTX_set_cert_store|https://docs.openssl.org/master/man3/SSL_CTX_set_cert_store> function, creates a new L<Net::SSLeay::X509_STORE|SPVM::Net::SSLeay::X509_STORE>, sets the pointer value of the new object to the return value of the native function, calls L<X509_STORE_up_ref|https://docs.openssl.org/master/man3/X509_STORE_up_ref> function on the return value of the native function, and returns the new object.

=head2 set_options

C<method set_options : long ($options : long);>

Calls native L<SSL_CTX_set_options|https://docs.openssl.org/master/man3/SSL_CTX_set_options> function given the pointer value of the instance, $options, and returns its return value.

=head2 get_options

C<method get_options : long ();>

Calls native L<SSL_CTX_get_options|https://docs.openssl.org/master/man3/SSL_CTX_get_options> function given the pointer value of the instance, and returns its return value.

=head2 clear_options

C<method clear_options : long ($options : long);>

Calls native L<SSL_CTX_clear_options|https://docs.openssl.org/master/man3/SSL_CTX_clear_options> function given the pointer value of the instance, $options, and returns its return value.

=head2 set_alpn_protos

C<method set_alpn_protos : int ($protos : string, $protos_len : int = -1);>

Calls native L<SSL_CTX_set_alpn_protos|https://docs.openssl.org/master/man3/SSL_CTX_set_alpn_protos> function given $ptotos, $protos_len, and returns its return value.

If $protos_len is less than 0, it is set to the length of $protos.

Exceptions:

The protocols $protos must be defined. Otherwise an exception is thrown.

If SSL_CTX_set_alpn_protos failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 set_alpn_protos_with_protocols

C<method set_alpn_protos_with_protocols : int ($protocols : string[]);>

Calls L<Net::SSLeay::Util#convert_to_wire_format|SPVM::Net::SSLeay::Util/"convert_to_wire_format"> method given $protocols, calls L</"set_alpn_protos"> method given the return value of C<convert_to_wire_format> method, and returns its return value.

=head2 set1_groups_list

C<method set1_groups_list : int ($list : string);>

Calls native L<SSL_CTX_set1_groups_list|https://docs.openssl.org/master/man3/SSL_CTX_set1_groups_list> function given the group list $list, and returns its return value.

Exceptions:

The group list $list must be defined. Otherwise an exception is thrown.

If set1_groups_list failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 set_post_handshake_auth

C<method set_post_handshake_auth : void ($val : int);>

Calls native L<SSL_CTX_set_post_handshake_auth|https://docs.openssl.org/master/man3/SSL_CTX_set_post_handshake_auth> function given the pointer value of the instance, $val.

=head2 set_min_proto_version

C<method set_min_proto_version : int ($version : int);>

Calls native L<SSL_CTX_set_min_proto_version|https://docs.openssl.org/master/man3/SSL_CTX_set_min_proto_version> function given the pointer value of the instance, $version, and returns its return value.

Exceptions:

If SSL_CTX_set_min_proto_version failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 set_client_CA_list

C<method set_client_CA_list : void ($list : L<X509_NAME|SPVM::X509_NAME>[]);>

Creates a new native C<STACK_OF(X509_NAME)> object(named C<x509_names_stack>).

And performs the following loop:copies the element at index $i using native L<X509_NAME_dup|https://docs.openssl.org/master/man3/X509_NAME_dup>, pushes the copied value to C<x509_names_stack>.

And calls native L<SSL_CTX_set_client_CA_list|https://docs.openssl.org/master/man3/SSL_CTX_set_client_CA_list> function given the pointer value of the instance, C<x509_names_stack>.

Exceptions:

The list $list must be defined. Otherwise an exception is thrown.

=head2 add_client_CA

C<method add_client_CA : int ($cacert : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>);>

Calls native L<SSL_CTX_add_client_CA|https://docs.openssl.org/master/man3/SSL_CTX_add_client_CA> function given the pointer value of the instance, the pointer value of $cacert, and returns its return value.

Exceptions:

The X509 object $cacert must be defined. Otherwise an exception is thrown.

If add_client_CA failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 use_certificate

C<method use_certificate : int ($x : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>);>

Calls native L<SSL_CTX_use_certificate|https://docs.openssl.org/master/man3/SSL_CTX_use_certificate> function given the pointer value of the instance, the pointer value of $x, and returns its return value.

Exceptions:

The X509 object $x must be defined. Otherwise an exception is thrown.

If SSL_CTX_use_certificate failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 add_extra_chain_cert

C<method add_extra_chain_cert : long ($x509 : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>);>

Calls native L<SSL_CTX_add_extra_chain_cert|https://docs.openssl.org/master/man3/SSL_CTX_add_extra_chain_cert> function given the pointer value of the instance, the pointer value of $x509, calls native L<X509_up_ref|https://docs.openssl.org/master/man3/X509_up_ref> function on the pointer value of $x509, and returns its return value.

Exceptions:

The X509 object $x509 must be defined. Otherwise an exception is thrown.

If SSL_CTX_add_extra_chain_cert failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 set_verify

C<method set_verify : void ($mode : int, $verify_callback : L<Net::SSLeay::Callback::Verify|SPVM::Net::SSLeay::Callback::Verify> = undef);>

If the callback $verify_callback is defined, A native variable C<native_cb> is set to a function pointer of the native callback funcion described below, otherwise C<native_cb> is set to NULL.

And calls native L<SSL_CTX_set_verify|https://docs.openssl.org/master/man3/SSL_CTX_set_verify> function given the pointer value of the instance, C<native_cb>.

And sets L</"verify_callback"> field to $verify_callback.

Native Callback Function:

The native callback function is defined by the following native code:

  static int SPVM__Net__SSLeay__SSL_CTX__my__verify_callback(int preverify_ok, X509_STORE_CTX* x509_store_ctx) {
    
    int32_t error_id = 0;
    
    int32_t ret_status = 0;
    
    SPVM_ENV* env = thread_env;
    
    SPVM_VALUE* stack = env->new_stack(env);
    
    int32_t scope_id = env->enter_scope(env, stack);
    
    SSL* ssl = (SSL*)X509_STORE_CTX_get_ex_data(x509_store_ctx, SSL_get_ex_data_X509_STORE_CTX_idx());
    
    if (!ssl) {
      env->die(env, stack, "X509_STORE_CTX_get_ex_data(x509_store_ctx, SSL_get_ex_data_X509_STORE_CTX_idx()) failed.", __func__, FILE_NAME, __LINE__);
      
      env->print_exception_to_stderr(env, stack);
      
      goto END_OF_FUNC;
    }
    
    SSL_CTX* self = SSL_get_SSL_CTX(ssl);
    
    if (!self) {
      env->die(env, stack, "SSL_get_SSL_CTX(ssl) failed.", __func__, FILE_NAME, __LINE__);
      
      env->print_exception_to_stderr(env, stack);
      
      goto END_OF_FUNC;
    }
    
    char* tmp_buffer = env->get_stack_tmp_buffer(env, stack);
    snprintf(tmp_buffer, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE, "%p", self);
    stack[0].oval = env->new_string(env, stack, tmp_buffer, strlen(tmp_buffer));
    env->call_class_method_by_name(env, stack, "Net::SSLeay::SSL_CTX", "GET_INSTANCE", 1, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) {
      env->print_exception_to_stderr(env, stack);
      
      goto END_OF_FUNC;
    }
    void* obj_self = stack[0].oval;
    
    void* obj_cb = env->get_field_object_by_name(env, stack, obj_self, "verify_callback", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) {
      env->print_exception_to_stderr(env, stack);
      goto END_OF_FUNC;
    }
    
    if (!obj_cb) {
      env->die(env, stack, "verify_callback field must be defined.", __func__, FILE_NAME, __LINE__);
      
      env->print_exception_to_stderr(env, stack);
      goto END_OF_FUNC;
    }
    
    void* obj_address_x509_store_ctx = env->new_pointer_object_by_name(env, stack, "Address", x509_store_ctx, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) {
      env->print_exception_to_stderr(env, stack);
      goto END_OF_FUNC;
    }
    stack[0].oval = obj_address_x509_store_ctx;
    env->call_class_method_by_name(env, stack, "Net::SSLeay::X509_STORE_CTX", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) {
      env->print_exception_to_stderr(env, stack);
      goto END_OF_FUNC;
    }
    void* obj_x509_store_ctx = stack[0].oval;
    env->set_no_free(env, stack, obj_x509_store_ctx, 1);
    
    stack[0].oval = obj_cb;
    stack[1].ival = preverify_ok;
    stack[2].oval = obj_x509_store_ctx;
    
    env->call_instance_method_by_name(env, stack, "", 3, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) {
      env->print_exception_to_stderr(env, stack);
      
      goto END_OF_FUNC;
    }
    ret_status = stack[0].ival;
    
    END_OF_FUNC:
    
    env->leave_scope(env, stack, scope_id);
    
    env->free_stack(env, stack);
    
    return ret_status;
  }

=head2 set_alpn_select_cb

C<method set_alpn_select_cb : void ($cb : Net::SSLeay::Callback::AlpnSelect);>

If the callback $cb is defined, A native variable C<native_cb> is set to a function pointer of the native callback funcion described below, otherwise C<native_cb> is set to NULL.

And calls native L<SSL_CTX_set_alpn_select_cb|https://docs.openssl.org/master/man3/SSL_CTX_set_alpn_select_cb> function given the pointer value of the instance, C<native_cb>, NULL.

And sets L</"alpn_select_cb"> field to $cb.

Native Callback Function:

The native callback function is defined by the following native code:

  static int SPVM__Net__SSLeay__SSL_CTX__my__alpn_select_cb(SSL* ssl, const unsigned char** out_ref, unsigned char* outlen_ref, const unsigned char* in, unsigned int inlen, void* native_arg) {
    
    int32_t error_id = 0;
    
    int32_t ret_status = SSL_TLSEXT_ERR_NOACK;
    
    void** native_args = (void**)native_arg;
    
    SPVM_ENV* env = thread_env;
    
    SPVM_VALUE* stack = env->new_stack(env);
    
    int32_t scope_id = env->enter_scope(env, stack);
    
    SSL_CTX* self = SSL_get_SSL_CTX(ssl);
    
    char* tmp_buffer = env->get_stack_tmp_buffer(env, stack);
    snprintf(tmp_buffer, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE, "%p", self);
    stack[0].oval = env->new_string(env, stack, tmp_buffer, strlen(tmp_buffer));
    env->call_class_method_by_name(env, stack, "Net::SSLeay::SSL_CTX", "GET_INSTANCE", 1, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) {
      env->print_exception_to_stderr(env, stack);
      
      goto END_OF_FUNC;
    }
    void* obj_self = stack[0].oval;
    
    void* obj_cb = env->get_field_object_by_name(env, stack, obj_self, "alpn_select_cb", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) {
      env->print_exception_to_stderr(env, stack);
      goto END_OF_FUNC;
    }
    
    if (!obj_cb) {
      env->die(env, stack, "alpn_select_cb field must be defined.", __func__, FILE_NAME, __LINE__);
      
      env->print_exception_to_stderr(env, stack);
      goto END_OF_FUNC;
    }
    
    void* obj_address_ssl = env->new_pointer_object_by_name(env, stack, "Address", ssl, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) {
      env->print_exception_to_stderr(env, stack);
      goto END_OF_FUNC;
    }
    snprintf(tmp_buffer, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE, "%p", ssl);
    stack[0].oval = env->new_string(env, stack, tmp_buffer, strlen(tmp_buffer));
    env->call_class_method_by_name(env, stack, "Net::SSLeay", "GET_INSTANCE", 1, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) {
      env->print_exception_to_stderr(env, stack);
      
      goto END_OF_FUNC;
    }
    void* obj_ssl = stack[0].oval;
    
    void* obj_out_ref = env->new_string_array(env, stack, 1);
    
    void* obj_in = env->new_string(env, stack, in, inlen);
    
    stack[0].oval = obj_cb;
    stack[1].oval = obj_ssl;
    stack[2].oval = obj_out_ref;
    stack[3].bref = outlen_ref;
    stack[4].oval = obj_in;
    stack[5].ival = inlen;
    
    env->call_instance_method_by_name(env, stack, "", 6, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) {
      env->print_exception_to_stderr(env, stack);
      goto END_OF_FUNC;
    }
    ret_status = stack[0].ival;
    
    void* obj_out = env->get_elem_object(env, stack, obj_out_ref, 0);
    
    if (!obj_out) {
      env->die(env, stack, "An output string for set_alpn_select_cb is not set.", __func__, FILE_NAME, __LINE__);
      
      env->print_exception_to_stderr(env, stack);
      goto END_OF_FUNC;
    }
    
    const char* out = env->get_chars(env, stack, obj_out);
    *out_ref = out;
    
    env->set_field_string_by_name(env, stack, obj_self, "alpn_select_cb_output", obj_out, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) {
      env->print_exception_to_stderr(env, stack);
      goto END_OF_FUNC;
    }
    
    END_OF_FUNC:
    
    env->leave_scope(env, stack, scope_id);
    
    env->free_stack(env, stack);
    
    return ret_status;
  }

=head2 set_alpn_select_cb_with_protocols

C<method set_alpn_select_cb_with_protocols : void ($protocols : string[]);>

Calls L</"set_alpn_select_cb"> method given the following anon method.

  my $cb = [$protocols : string[]] method : int ($ssl : Net::SSLeay, $out_ref : string[], $outlen_ref : byte*, $in : string, $inlen : int) {
    
    my $wire_format = Net::SSLeay::Util->convert_to_wire_format($protocols);
    
    my $status_select_next_proto = Net::SSLeay->select_next_proto($out_ref, $outlen_ref, $in, $inlen, $wire_format, length $wire_format);
    
    my $status = SSL->SSL_TLSEXT_ERR_NOACK;
    if ($status_select_next_proto == SSL->OPENSSL_NPN_NEGOTIATED) {
      $status = SSL->SSL_TLSEXT_ERR_OK;
    }
    
    return $status;
  };

=head2 set_default_passwd_cb

C<method set_default_passwd_cb : void ($cb : L<Net::SSLeay::Callback::PemPassword|SPVM::Net::SSLeay::Callback::PemPassword>);>

If the callback $cb is defined, A native variable C<native_cb> is set to a function pointer of the native callback funcion described below, otherwise C<native_cb> is set to NULL.

And calls native L<SSL_CTX_set_default_passwd_cb|https://docs.openssl.org/master/man3/SSL_CTX_set_default_passwd_cb> function given the pointer value of the instance, C<native_cb>, the pointer of the instance, and calls L<SSL_CTX_set_default_passwd_cb_userdata|https://docs.openssl.org/master/man3/SSL_CTX_set_default_passwd_cb_userdata> given the pointer of the instance.

And sets L</"default_passwd_cb"> field to $cb.

Native Callback Function:

The native callback function is defined by the following native code:

  static int SPVM__Net__SSLeay__SSL_CTX__my__default_passwd_cb(char* buf, int size, int rwflag, void* native_arg) {
    
    int32_t error_id = 0;
    
    int32_t ret_buf_length = 0;
    
    SPVM_ENV* env = thread_env;
    
    SPVM_VALUE* stack = env->new_stack(env);
    
    int32_t scope_id = env->enter_scope(env, stack);
    
    SSL_CTX* self = (SSL_CTX*)native_arg;
    
    char* tmp_buffer = env->get_stack_tmp_buffer(env, stack);
    snprintf(tmp_buffer, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE, "%p", self);
    stack[0].oval = env->new_string(env, stack, tmp_buffer, strlen(tmp_buffer));
    env->call_class_method_by_name(env, stack, "Net::SSLeay::SSL_CTX", "GET_INSTANCE", 1, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) {
      env->print_exception_to_stderr(env, stack);
      
      goto END_OF_FUNC;
    }
    void* obj_self = stack[0].oval;
    
    assert(obj_self);
    
    void* obj_cb = env->get_field_object_by_name(env, stack, obj_self, "default_passwd_cb", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) {
      env->print_exception_to_stderr(env, stack);
      goto END_OF_FUNC;
    }
    
    if (!obj_cb) {
      env->die(env, stack, "default_passwd_cb field must be defined.", __func__, FILE_NAME, __LINE__);
      
      env->print_exception_to_stderr(env, stack);
      goto END_OF_FUNC;
    }
    
    void* obj_buf = env->new_string(env, stack, buf, size);
    
    stack[0].oval = obj_cb;
    stack[1].oval = obj_buf;
    stack[2].ival = size;
    stack[3].ival = rwflag;
    
    env->call_instance_method_by_name(env, stack, "", 4, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) {
      env->print_exception_to_stderr(env, stack);
      
      goto END_OF_FUNC;
    }
    ret_buf_length = stack[0].ival;
    
    memcpy(buf, env->get_chars(env, stack, obj_buf), size);
    
    END_OF_FUNC:
    
    env->leave_scope(env, stack, scope_id);
    
    env->free_stack(env, stack);
    
    return ret_buf_length;
  }

=head2 set_tlsext_servername_callback

C<method set_tlsext_servername_callback : long ($callback : L<Net::SSLeay::Callback::TlsextServername|SPVM::Net::SSLeay::Callback::TlsextServername>);>

Calls native L<SSL_CTX_set_tlsext_servername_callback|https://docs.openssl.org/master/man3/SSL_CTX_set_tlsext_servername_callback> function given $cb, NULL, and returns its return value.

If the callback $callback is defined, A native variable C<native_cb> is set to a function pointer of the native callback funcion described below, otherwise C<native_cb> is set to NULL.

And calls native L<SSL_CTX_set_tlsext_servername_callback|https://docs.openssl.org/master/man3/SSL_CTX_set_tlsext_servername_callback> function given the pointer value of the instance, C<native_cb>.

And sets L</"alpn_select_cb"> field to $callback.

And retunrs the return value of native L<SSL_CTX_set_tlsext_servername_callback|https://docs.openssl.org/master/man3/SSL_CTX_set_tlsext_servername_callback> function.

Native Callback Function:

The native callback function is defined by the following native code:

  static int SPVM__Net__SSLeay__SSL_CTX__my__tlsext_servername_callback(SSL* ssl, int* al, void* native_arg) {
    
    int32_t error_id = 0;
    
    int32_t ret_status = SSL_TLSEXT_ERR_NOACK;
    
    SPVM_ENV* env = thread_env;
    
    SPVM_VALUE* stack = env->new_stack(env);
    
    int32_t scope_id = env->enter_scope(env, stack);
    
    SSL_CTX* self = SSL_get_SSL_CTX(ssl);
    
    char* tmp_buffer = env->get_stack_tmp_buffer(env, stack);
    snprintf(tmp_buffer, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE, "%p", self);
    stack[0].oval = env->new_string(env, stack, tmp_buffer, strlen(tmp_buffer));
    env->call_class_method_by_name(env, stack, "Net::SSLeay::SSL_CTX", "GET_INSTANCE", 1, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) {
      env->print_exception_to_stderr(env, stack);
      
      goto END_OF_FUNC;
    }
    void* obj_self = stack[0].oval;
    
    void* obj_cb = env->get_field_object_by_name(env, stack, obj_self, "tlsext_servername_callback", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) {
      env->print_exception_to_stderr(env, stack);
      goto END_OF_FUNC;
    }
    
    if (!obj_cb) {
      env->die(env, stack, "tlsext_servername_callback field must be defined.", __func__, FILE_NAME, __LINE__);
      
      env->print_exception_to_stderr(env, stack);
      goto END_OF_FUNC;
    }
    
    snprintf(tmp_buffer, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE, "%p", ssl);
    stack[0].oval = env->new_string(env, stack, tmp_buffer, strlen(tmp_buffer));
    env->call_class_method_by_name(env, stack, "Net::SSLeay", "GET_INSTANCE", 1, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) {
      env->print_exception_to_stderr(env, stack);
      
      goto END_OF_FUNC;
    }
    void* obj_ssl = stack[0].oval;
    
    assert(obj_ssl);
    
    stack[0].oval = obj_cb;
    stack[1].oval = obj_ssl;
    int32_t al_tmp = 0;
    stack[2].iref = &al_tmp;
    
    env->call_instance_method_by_name(env, stack, "", 3, &error_id, __func__, FILE_NAME, __LINE__);
    ret_status = stack[0].ival;
    
    *al = al_tmp;
    
    if (error_id) {
      env->print_exception_to_stderr(env, stack);
      
      goto END_OF_FUNC;
    }
    
    END_OF_FUNC:
    
    env->leave_scope(env, stack, scope_id);
    
    env->free_stack(env, stack);
    
    return ret_status;
  }

=head2 DESTROY

C<method DESTROY : void ();>

Performes L<Cleanup process described in Callback Hack|/"Callback Hack">.

And calls native L<SSL_CTX_free|https://docs.openssl.org/master/man3/SSL_CTX_free> function given the pointer value of the instance unless C<no_free> flag of the instance is a true value.

=head1 See Also

=over 2

=item * L<Net::SSLeay::SSL_METHOD|SPVM::Net::SSLeay::SSL_METHOD>

=item * L<Net::SSLeay::X509_VERIFY_PARAM|SPVM::Net::SSLeay::X509_VERIFY_PARAM>

=item * L<Net::SSLeay::X509_STORE|SPVM::Net::SSLeay::X509_STORE>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

