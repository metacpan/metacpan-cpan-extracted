package SPVM::Net::SSLeay::SSL_CTX;



1;

=head1 Name

SPVM::Net::SSLeay::SSL_CTX - SSL_CTX data structure in OpenSSL

=head1 Description

Net::SSLeay::SSL_CTX class in L<SPVM> represents L<SSL_CTX|https://docs.openssl.org/master/man3/SSL_CTX_new/> data structure in OpenSSL.

=head1 Usage

  use Net::SSLeay::SSL_CTX;

=head1 Fields

=head2 pkeys_list

C<has pkeys_list : L<List|SPVM::List> of L<Net::SSLeay::EVP_PKEY|SPVM::Net::SSLeay::EVP_PKEY>;>

A list of private keys.

=head1 Class Methods

=head2 new

C<static method new : L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX> ($method : L<Net::SSLeay::SSL_METHOD|SPVM::Net::SSLeay::SSL_METHOD>);>

Calls native L<SSL_CTX_new|https://docs.openssl.org/master/man3/SSL_CTX_new/> function given the pointer value of $method, creates a new L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX> object, sets the pointer value of the new object to the return value of the native function, and returns the new object.

C<SSL_MODE_AUTO_RETRY> mode is enabled.

Exceptions:

If SSL_CTX_new failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head1 Instance Methods

=head2 set_mode

C<method set_mode : long ($mode : long);>

Calls native L<SSL_CTX_set_mode|https://docs.openssl.org/1.0.2/man3/SSL_CTX_set_mode> function given the pointer value of the instance, $mode, and returns the updated mode.

=head2 set_verify

C<method set_verify : void ($mode : int);>

Calls native L<SSL_CTX_set_verify|https://docs.openssl.org/master/man3/SSL_CTX_set_verify/> function given the pointer value of the instance, $mode.

=head2 get0_param

C<method get0_param : L<Net::SSLeay::X509_VERIFY_PARAM|SPVM::Net::SSLeay::X509_VERIFY_PARAM> ();>

Calls native L<SSL_CTX_get0_param|https://docs.openssl.org/master/man3/SSL_CTX_get0_param/> function, creates a L<Net::SSLeay::X509_VERIFY_PARAM|SPVM::Net::SSLeay::X509_VERIFY_PARAM> object, sets the pointer value of the new object to the return value of the native function, and returns the new object.

=head2 load_verify_locations

C<method load_verify_locations : int ($path : string);>

Calls native L<SSL_CTX_load_verify_locations|https://docs.openssl.org/master/man3/SSL_CTX_load_verify_locations/> function given the pointer value of the instance, $path, and returns its return value.

Exceptions:

If SSL_CTX_load_verify_locations failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 set_default_verify_paths

C<method set_default_verify_paths : int ();>

Calls native L<set_default_verify_paths|https://docs.openssl.org/master/man3/SSL_CTX_load_verify_locations/> function, and returns its return value.

Exceptions:

If SSL_CTX_set_default_verify_paths failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 use_certificate_file

C<method use_certificate_file : int ($file : string, $type : int);>

Calls native L<use_certificate_file|https://docs.openssl.org/master/man3/SSL_CTX_use_certificate/> function given the pointer value of the instance, $file, $type, and returns its return value.

Exceptions:

The file $file must be defined. Otherwise an exception is thrown.

If SSL_CTX_use_certificate_file failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 use_certificate_chain_file

C<method use_certificate_chain_file : int ($file : string);>

Calls native L<use_certificate_chain_file|https://docs.openssl.org/1.1.1/man3/SSL_CTX_use_certificate/> function given the pointer value of the instance, $file, and returns its return value.
 
Exceptions:

If SSL_CTX_use_certificate_chain_file failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 use_PrivateKey_file

C<method use_PrivateKey_file : int ($file : string, $type : int);>

Calls native L<use_PrivateKey_file|https://docs.openssl.org/3.1/man3/SSL_CTX_use_certificate> function given the pointer value of the instance, $file, $type, and returns its return value.

Exceptions:

The file $file must be defined. Otherwise an exception is thrown.

If SSL_CTX_use_PrivateKey_file failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 set_cipher_list

C<method set_cipher_list : int ($str : string);>

Calls native L<set_cipher_list|https://docs.openssl.org/master/man3/SSL_CTX_set_cipher_list/> function given the pointer value of the instance, $str, and returns its return value.

Exceptions:

The cipher list $str must be defined. Otherwise an exception is thrown.

If SSL_CTX_set_cipher_list failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 set_ciphersuites

C<method set_ciphersuites : int ($str : string);>

Calls native L<set_ciphersuites|https://docs.openssl.org/master/man3/SSL_CTX_set_cipher_list/> function given the pointer value of the instance, $str, and returns its return value.

Exceptions:

The ciphersuites $str must be defined. Otherwise an exception is thrown.

If SSL_CTX_set_ciphersuites failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 get_cert_store

C<method get_cert_store : L<Net::SSLeay::X509_STORE|SPVM::Net::SSLeay::X509_STORE> ();>

Calls native L<SSL_CTX_set_cert_store|https://docs.openssl.org/master/man3/SSL_CTX_set_cert_store/> function, creates a new L<Net::SSLeay::X509_STORE|SPVM::Net::SSLeay::X509_STORE>, sets the pointer value of the new object to the return value of the native function, and returns the new object.

=head2 set_options

C<method set_options : long ($options : long);>

Calls native L<set_options|https://docs.openssl.org/1.0.2/man3/SSL_CTX_set_options> function given the pointer value of the instance, $options, and returns its return value.

=head2 get_options

C<method get_options : long ();>

Calls native L<SSL_CTX_get_options|https://docs.openssl.org/3.1/man3/SSL_CTX_set_options/> function, and returns its return value.

=head2 clear_options

C<method clear_options : long ($options : long);>

Calls native L<SSL_CTX_clear_options|https://docs.openssl.org/3.1/man3/SSL_CTX_set_options/> function given the pointer value of the instance, $options, and returns its return value.

=head2 set_alpn_protos

C<method set_alpn_protos : int ($protos : string, $protos_len : int = -1);>

Calls native L<SSL_CTX_set_alpn_protos|https://docs.openssl.org/1.1.1/man3/SSL_CTX_set_alpn_select_cb> function given the protocals $ptotos and the length $protos_len, and returns its return value.

If $protos_len is less than 0, it is set to the length of $protos.

Exceptions:

The protocols $protos must be defined. Otherwise an exception is thrown.

If SSL_CTX_set_alpn_protos failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 set_tmp_ecdh

C<method set_tmp_ecdh : long ($ecdh : L<Net::SSLeay::EC_KEY|SPVM::Net::SSLeay::EC_KEY>);>

Calls native L<SSL_CTX_set_tmp_ecdh|https://docs.openssl.org/master/man3/SSL_CTX_set_tmp_ecdh> function given the ECDH parameters $ecdh, and returns its return value.

Exceptions:

The ECDH parameters $ecdh must be defined. Otherwise an exception is thrown.

If SSL_CTX_set_tmp_ecdh failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 set1_groups_list

C<method set1_groups_list : int ($list : string);>

Calls native L<SSL_CTX_set1_groups_list|https://docs.openssl.org/3.1/man3/SSL_CTX_set1_curves> function given the group list $list, and returns its return value.

Exceptions:

The group list $list must be defined. Otherwise an exception is thrown.

If set1_groups_list failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

Requirements:

OpenSSL 3.0

=head2 set1_curves_list

C<method set1_curves_list : int ($list : string);>

Calls native L<SSL_CTX_set1_curves_list|https://docs.openssl.org/3.1/man3/SSL_CTX_set1_curves> function given the group list $list, and returns its return value.

Exceptions:

The group list $list must be defined. Otherwise an exception is thrown.

If set1_curves_list failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 set_session_cache_mode

C<method set_session_cache_mode : long ($mode : long);>

Calls native L<SSL_CTX_set_session_cache_mode|https://docs.openssl.org/1.0.2/man3/SSL_CTX_set_session_cache_mode/> function given the pointer value of the instance, $mode, and returns its return value.

=head2 set_ecdh_auto

C<method set_ecdh_auto : long ($state : int);>

Calls native L<SSL_CTX_set_ecdh_auto|https://docs.openssl.org/3.1/man3/SSL_CTX_set_tmp_ecdh/> function given the pointer value of the instance, $state, and returns its return value.

Exceptions:

If set_ecdh_auto failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 set_tmp_dh

C<method set_tmp_dh : long ($dh : L<Net::SSLeay::DH|SPVM::Net::SSLeay::DH>);>

Calls native L<SSL_CTX_set_tmp_dh|https://docs.openssl.org/master/man3/SSL_CTX_set_tmp_dh_callback> function given the pointer value of $dh, and returns its return value.

Exceptions:

If set_tmp_dh failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 set_post_handshake_auth

C<method set_post_handshake_auth : void ($val : int);>

Calls native L<SSL_CTX_set_post_handshake_auth|https://docs.openssl.org/1.1.1/man3/SSL_CTX_set_verify> function given the pointer value of the instance, $val.

=head2 use_PrivateKey

C<method use_PrivateKey : int ($pkey : L<Net::SSLeay::EVP_PKEY|SPVM::Net::SSLeay::EVP_PKEY>);>

Calls native L<SSL_CTX_use_PrivateKey|https://docs.openssl.org/master/man3/SSL_CTX_use_certificate> function given the pointer value of the instance, $pkey, pushes $pkey to the end of L</"pkeys_list"> field, and returns the return value of the native function.

=head2 set_session_id_context

C<method set_session_id_context : int ($sid_ctx : string, $sid_ctx_len : int = -1);>

Calls native L<SSL_CTX_set_session_id_context|https://docs.openssl.org/1.1.1/man3/SSL_CTX_set_alpn_select_cb> function given the pointer value of the instance, $sid_ctx, $sid_ctx_len, and returns its return value.

If $sid_ctx_len is less than 0, it is set to the length of $sid_ctx.

Exceptions:

The context $sid_ctx must be defined. Otherwise an exception is thrown.

If SSL_CTX_set_session_id_context failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 set_min_proto_version

C<method set_min_proto_version : int ($version : int);>

Calls native L<SSL_CTX_set_min_proto_version|https://docs.openssl.org/master/man3/SSL_CTX_set_min_proto_version> function given the pointer value of the instance, $version, and returns its return value.

Exceptions:

If SSL_CTX_set_min_proto_version failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 set_client_CA_list

C<method set_client_CA_list : void ($list : L<X509_NAME|SPVM::X509_NAME>[]);>

Calls native L<SSL_CTX_set_client_CA_list|https://docs.openssl.org/1.0.2/man3/SSL_CTX_set_client_CA_list> function given the pointer value of the instance, $list.

Exceptions:

The list $list must be defined. Otherwise an exception is thrown.

=head2 add_client_CA

C<method add_client_CA : int ($cacert : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>);>

Calls native L<SSL_CTX_add_client_CA|https://docs.openssl.org/master/man3/SSL_CTX_set0_CA_list> function given the pointer value of the instance, $cacert, and returns its return value.

Exceptions:

The X509 object $cacert must be defined. Otherwise an exception is thrown.

If add_client_CA failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 add_extra_chain_cert

C<method add_extra_chain_cert : long ($x509 : L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>);>

Calls native L<SSL_CTX_add_extra_chain_cert|https://docs.openssl.org/1.1.1/man3/SSL_CTX_add_extra_chain_cert/> function given the pointer value of the instance, $x509, sets the C<no_free> flag of $x509 is set to 1, and returns its return value.

Exceptions:

The X509 object $x509 must be defined. Otherwise an exception is thrown.

If SSL_CTX_add_extra_chain_cert failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 set_tlsext_servername_callback

C<method set_tlsext_servername_callback : long ($cb : L<Net::SSLeay::Callback::TlsextServername|SPVM::Net::SSLeay::Callback::TlsextServername>, $arg : object = undef);>

Calls native L<SSL_CTX_set_tlsext_servername_callback|https://docs.openssl.org/1.1.1/man3/SSL_CTX_set_tlsext_servername_callback> function given $cb, and returns its return value.

$arg is expected to be passed to native L<SSL_CTX_set_tlsext_servername_arg|https://docs.openssl.org/1.1.1/man3/SSL_CTX_set_tlsext_servername_callback> function.

=head2 set_tlsext_status_cb

C<method set_tlsext_status_cb : long ($cb : L<Net::SSLeay::Callback::TlsextStatus|SPVM::Net::SSLeay::Callback::TlsextStatus>, $arg : object = undef);>

Calls native L<SSL_CTX_set_tlsext_status_cb|https://docs.openssl.org/1.1.1/man3/SSL_CTX_set_tlsext_status_cb> function given $cb, and returns its return value.

$arg is expected to be passed to native L<SSL_CTX_set_tlsext_status_arg|https://docs.openssl.org/1.1.1/man3/SSL_CTX_set_tlsext_status_cb> function.

Exceptions:

If SSL_CTX_set_tlsext_status_cb failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 set_default_passwd_cb

C<method set_default_passwd_cb : void ($cb : L<Net::SSLeay::Callback::PemPasswd|SPVM::Net::SSLeay::Callback::PemPasswd>, $arg : object = undef);>

Calls native L<SSL_CTX_set_default_passwd_cb|https://docs.openssl.org/1.0.2/man3/SSL_CTX_set_default_passwd_cb> function given $cb, and returns its return value.

$arg is expected to be passed to native L<SSL_CTX_set_default_passwd_cb_userdata|https://docs.openssl.org/1.0.2/man3/SSL_CTX_set_default_passwd_cb> function.

=head2 set_psk_client_callback

C<method set_psk_client_callback : void ($cb : L<Net::SSLeay::Callback::PskClient|SPVM::Net::SSLeay::Callback::PskClient>);>

Calls native L<SSL_CTX_set_psk_client_callback|https://docs.openssl.org/1.0.2/man3/SSL_CTX_set_psk_client_callback> function given $cb.

=head2 DESTROY

C<method DESTROY : void ();>

Calls native L<SSL_CTX_free|https://docs.openssl.org/3.1/man3/SSL_CTX_free/> function given the pointer value of the instance if C<no_free> flag of the instance is not a true value.

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

