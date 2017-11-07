package POE::Filter::SSL;

use strict;
use Net::SSLeay;
use POE qw (Filter::HTTPD Filter::Stackable Wheel::ReadWrite);
use Scalar::Util qw(blessed);
use Carp qw(carp confess);
use POE;

use vars qw($VERSION @ISA);
$VERSION = '0.37';
sub DOSENDBACK () { 1 }

our $globalinfos;

my $PATCH         = 18;
my $HANDSHAKE     = 19;
my $EVENT_FLUSHED = 20;
my $EVENT_INPUT   = 21;

BEGIN {
   eval {
      require Net::SSLeay;
      Net::SSLeay->import( 1.30 );
   };
   Net::SSLeay::load_error_strings();
   Net::SSLeay::SSLeay_add_ssl_algorithms();
   Net::SSLeay::randomize();

   no warnings 'redefine';
   my $old_new = \&POE::Wheel::ReadWrite::new;
   my $old_set_filter = \&POE::Wheel::ReadWrite::set_filter;
   my $old_set_input_filter = \&POE::Wheel::ReadWrite::set_input_filter;
   my $old_set_output_filter = \&POE::Wheel::ReadWrite::set_output_filter;
   my $old_rw_put = \&POE::Wheel::ReadWrite::put;
   *POE::Wheel::ReadWrite::put = sub {
      my $self = shift;
      my $unique_id = $self->[POE::Wheel::ReadWrite::UNIQUE_ID()];
      if (defined($self->[$EVENT_FLUSHED])) {
         $self->[POE::Wheel::ReadWrite::EVENT_FLUSHED] = $self->[$EVENT_FLUSHED];
         $self->[$EVENT_FLUSHED] = undef;
      }
      $old_rw_put->($self, @_);
   };
   *POE::Wheel::ReadWrite::new = sub {
      my $class = shift;
      my %arg = @_;
      my $self = $old_new->($class,%arg);
      my $unique_id = $self->[POE::Wheel::ReadWrite::UNIQUE_ID];
      $self->[$EVENT_INPUT] = $self->[POE::Wheel::ReadWrite::EVENT_INPUT];
      $self->[POE::Wheel::ReadWrite::EVENT_INPUT] = ref($self) . "($unique_id) -> ssl handshake";
      my $flushed_event = \$self->[POE::Wheel::ReadWrite::EVENT_FLUSHED];
      my $temp_flushed_event = \$self->[$EVENT_FLUSHED];
      my $temp_event_input = \$self->[$EVENT_INPUT];
      my $filter_output = \$self->[POE::Wheel::ReadWrite::FILTER_OUTPUT];
      my $driver = \$self->[POE::Wheel::ReadWrite::DRIVER_BOTH];
      my $handle_output = \$self->[POE::Wheel::ReadWrite::HANDLE_OUTPUT];
      $poe_kernel->state(
         $self->[$HANDSHAKE] = ref($self) . "($unique_id) -> ssl handshake",
         sub {
            if (checkForDoSendback($_[ARG0])) {
               unless (defined($$temp_flushed_event)) {
                  $$temp_flushed_event = $$flushed_event;
                  $$flushed_event = undef;
               }
               $$driver->put($$filter_output->put([$_[ARG0]]));
               $poe_kernel->select_resume_write($$handle_output);
            } else {
               $poe_kernel->call($_[SESSION], $$temp_event_input, $_[ARG0], $_[ARG1]);
            }
         }
      );
      $poe_kernel->state(
         $self->[$PATCH] = ref($self) . "($unique_id) -> ssl patch",
         sub {
            my $type = $_[ARG0];
            my $self = $_[ARG1];
            if ($_[HEAP]->{self}->{PreFilter}) {
               $_[HEAP]->{self}->{"PreFilter".ref($self).$self->[POE::Wheel::ReadWrite::UNIQUE_ID()]} = $_[HEAP]->{self}->{PreFilter}->clone()
                  unless ($_[HEAP]->{self}->{"PreFilter".ref($self).$self->[POE::Wheel::ReadWrite::UNIQUE_ID()]});
               if ($type eq "input") {
                  $old_set_input_filter->($self, POE::Filter::Stackable->new(
                     Filters => [
                        $_[HEAP]->{self}->{"PreFilter".ref($self).$self->[POE::Wheel::ReadWrite::UNIQUE_ID()]},
                        $self->get_input_filter()
                     ]
                  ));
               } else {
                  $old_set_output_filter->($self, POE::Filter::Stackable->new(
                     Filters => [
                        $_[HEAP]->{self}->{"PreFilter".ref($self).$self->[POE::Wheel::ReadWrite::UNIQUE_ID()]},
                        $self->get_output_filter()
                     ]
                  ));
               }
            }
         }
      );
      $poe_kernel->yield(ref($self) . "($unique_id) -> ssl patch" => "input" => $self);
      $poe_kernel->yield(ref($self) . "($unique_id) -> ssl patch" => "output" => $self);
      return $self;
   };
   my $old_destroy = \&POE::Wheel::ReadWrite::DESTROY;
   *POE::Wheel::ReadWrite::DESTROY = sub {
      my $self = shift;
      if ($self->[$PATCH]) {
         $poe_kernel->state($self->[$PATCH]);
         $self->[$PATCH] = undef;
      }
      if ($self->[$HANDSHAKE]) {
         $poe_kernel->state($self->[$HANDSHAKE]);
         $self->[$HANDSHAKE] = undef;
      }
      return $old_destroy->($self, @_);
   };
   *POE::Wheel::ReadWrite::set_filter = sub {
      my $self = shift;
      my $new_filter = shift;
      my $unique_id = $self->[POE::Wheel::ReadWrite::UNIQUE_ID()];
      my $ret = $old_set_filter->($self, $new_filter, @_);
      $poe_kernel->yield(ref($self) . "($unique_id) -> ssl patch" => "input" => $self);
      $poe_kernel->yield(ref($self) . "($unique_id) -> ssl patch" => "output" => $self);
      return $ret;
   };
   *POE::Wheel::ReadWrite::set_input_filter = sub {
      my $self = shift;
      my $new_filter = shift;
      my $unique_id = $self->[POE::Wheel::ReadWrite::UNIQUE_ID()];
      my $ret = $old_set_input_filter->($self, $new_filter, @_);
      $poe_kernel->yield(ref($self) . "($unique_id) -> ssl patch" => "input" => $self);
      return $ret;
   };
   *POE::Wheel::ReadWrite::set_output_filter = sub {
      my $self = shift;
      my $new_filter = shift;
      my $unique_id = $self->[POE::Wheel::ReadWrite::UNIQUE_ID()];
      my $ret = $old_set_output_filter->($self, $new_filter, @_);
      $poe_kernel->yield(ref($self) . "($unique_id) -> ssl patch" => "output" => $self);
      return $ret;
   };
   #my $old_get_one  = \&POE::Filter::Stackable::get_one;
   *POE::Filter::Stackable::get_one = sub {
      my ($self) = @_;
      my $return = [ ];
      while (!@$return) {
         my $exchanged = 0;
         foreach my $filter (@{$self->[POE::Filter::Stackable::FILTERS]}) {
            # If we have something to input to the next filter, do that.
            if (@$return) {
               $filter->get_one_start($return);
               $exchanged++;
            }
            # Get what we can from the current filter.
            $return = $filter->get_one();
            # This is the only inserted line:
            return $return if (checkForDoSendback($return) && ($return->[0] eq $filter));
         }
         last unless $exchanged;
      }
      return $return;
   };
   my $old_get_one_start = \&POE::Filter::Stackable::get_one_start;
   *POE::Filter::Stackable::get_one_start = sub {
      my $self = shift;
      (exists($self->[POE::Filter::Stackable::FILTERS]->[0])) ? $old_get_one_start->($self, @_) : []
   };
   my $old_put = \&POE::Filter::Stackable::put;
   *POE::Filter::Stackable::put = sub {
      my $self = shift;
      my $data = shift;
      my $found = 0;
      if (checkForDoSendback($data)) {
         foreach my $filter (@{$self->[POE::Filter::Stackable::FILTERS]}) {
            if ($data->[0] eq $filter) {
               $found++;
               last;
            }
         }
      }
      if ($found) {
         my $ok = 0;
         foreach my $filter (reverse @{$self->[POE::Filter::Stackable::FILTERS]}) {
            next unless ($ok || (($filter eq $data->[0]) && checkForDoSendback($data)));
            $ok++;
            $data = $filter->put($data);
            last unless @$data;
         }
         $data;
      } else {
         $old_put->($self, $data, @_);
      }
   };
   *POE::Filter::HTTPD::get_pending = sub {
      return undef;
   }
}

require XSLoader;
XSLoader::load('POE::Filter::SSL', $VERSION);

sub checkForDoSendback {
   my $chunks = shift;
   $chunks = $chunks->[0] if ((ref($chunks) eq "ARRAY") && 
                          (scalar(@$chunks)));
   return 1 if (blessed($chunks) &&
                       ($chunks->can("DOSENDBACK")) &&
                       ($chunks->DOSENDBACK()));
   return 0;
}

sub PEMdataToX509 {
   my $x509 = shift;
   my $bio = dataToBio($x509);
   my $x509result = undef;
   die "Error using x509: ".Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error())
      unless ($x509result = Net::SSLeay::PEM_read_bio_X509($bio));
   Net::SSLeay::BIO_free($bio);
   return $x509result;
}

sub PEMdataToEVP_PKEY {
   my $ssl = shift;
   my $crt = shift;
   my $bio = dataToBio($crt);
   my $evp_pkey = undef;
   die "Error using cacrt: ".Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error())
      unless ($evp_pkey = Net::SSLeay::PEM_read_bio_PrivateKey($bio));
   Net::SSLeay::BIO_free($bio);
   return $evp_pkey;
}

sub CTX_add_client_CA {
   my $ctx = shift;
   my $x509 = shift;
   my $ssl = shift;
   my $err = Net::SSLeay::X509_STORE_add_cert(Net::SSLeay::CTX_get_cert_store($ctx), PEMdataToX509($x509));
   die "Error using cacrt: ".Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error())
      if ($err && ($err != 1));
   $err = Net::SSLeay::CTX_add_client_CA($ctx, PEMdataToX509($x509));
   die "Error using cacrt: ".Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error())
      if ($err && ($err != 1));
}

sub dataToBio {
   my $data = shift;
   my $self = $globalinfos->[3] || {};
   my $bio = Net::SSLeay::BIO_new(Net::SSLeay::BIO_s_mem());
   my $sent = Net::SSLeay::BIO_write($bio, $data);
   print "Wrote ".$sent." of ".length($data)." bytes.\n"
      if $self->{debug};
   die "Cannot write to bio!"
      if (($sent) != length($data));
   return $bio;
}

sub new {
   my $type = shift;

   my $params = {@_};
   my $self = bless({}, $type);

   $globalinfos = [0, 0, [], $self];

   $self->{buffer} = '';
   $self->{debug} = $params->{debug} || 0;
   $self->{cacrl} = $params->{cacrl}
      if $self->{cacrl};
   $self->{client} = $params->{client} || 0;
   $self->{errorhandler} = $params->{errorhandler};
   $self->{params} = $params;

   $self->{context} =
      ($params->{tls} || $params->{tls1_2}) ?
                        ($params->{tls1_2}  ?
         Net::SSLeay::CTX_tlsv1_2_new() :
         Net::SSLeay::CTX_tlsv1_new()) :
         Net::SSLeay::CTX_new();

   Net::SSLeay::CTX_set_options($self->{context}, 0x00400000) # SSL_OP_CIPHER_SERVER_PREFERENCE # Beim Apache: SSLHonorCipherOrder
      if ((!$self->{client}) && (!$params->{"nohonor"}));

   my $err = undef;
   if ($params->{chain}) {
      $err = Net::SSLeay::CTX_use_certificate_chain_file($self->{context}, $params->{chain});
      die "Error using chain: ".Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error())
         if ($err && ($err != 1));
   } else {
      if ($params->{keymem} || $params->{key}) {
         if ($params->{keymem}) {
            $err = Net::SSLeay::CTX_use_PrivateKey($self->{context}, PEMdataToEVP_PKEY($self->{ssl}, $params->{keymem}));
            print "Loaded keymem(".length($params->{keymem})." Bytes) with result ".$err."\n"
               if $self->{debug};
         } else {
            $err = Net::SSLeay::CTX_use_PrivateKey_file($self->{context}, $params->{key}, &Net::SSLeay::FILETYPE_PEM);
            print "Loaded key from file ".$params->{key}." with result ".$err."\n"
               if $self->{debug};
         }
         die "Error using keymem: ".Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error())
            if ($err && ($err != 1));
      }
      if ($params->{crtmem} || $params->{crt}) {
         if ($params->{crtmem}) {
            my $crt = PEMdataToX509($params->{crtmem});
            $err = Net::SSLeay::CTX_use_certificate($self->{context}, $crt);
            print "Loaded crtmem(".length($params->{crtmem})." Bytes/".$crt.") with result ".$err."\n"
               if $self->{debug};
         } else {
            # TODO:XXX:FIXME: Errorchecking!
            $err = Net::SSLeay::CTX_use_certificate_file($self->{context}, $params->{crt}, &Net::SSLeay::FILETYPE_PEM);
            print "Loaded crt from file ".$params->{crt}." with result ".$err."\n"
               if $self->{debug};
         }
         die "Error using crtmem: ".Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error())
            if ($err && ($err != 1));
      }
   }

   $err = undef;
   if ($params->{cacrt}||
       $params->{cacrtmem}) {
      if ($params->{cacrtmem}) {
         if (ref($params->{cacrtmem}) eq "ARRAY") {
            foreach my $curcert (@{$params->{cacrtmem}}) {
               $err = CTX_add_client_CA($self->{context}, $curcert, $self->{ssl});
               last
                  unless $err;
            }
         } else {
            $err = CTX_add_client_CA($self->{context}, $params->{cacrtmem}, $self->{ssl});
            print "Loaded cacrtmem(".length($params->{cacrtmem})." Bytes) with result ".$err."\n"
               if $self->{debug};
         }
      } else {
         $err = Net::SSLeay::CTX_load_verify_locations($self->{context}, $params->{cacrt}, '');
         print "Loaded cacrt from file ".$params->{cacrt}." with result ".$err."\n"
            if $self->{debug};
         $err = Net::SSLeay::CTX_set_client_CA_list($self->{context}, Net::SSLeay::load_client_CA_file($params->{cacrt}))
            unless ($err && ($err == 1));
         print "Set client cacrt from file ".$params->{cacrt}." with result ".$err."\n"
            if $self->{debug};
      }
      $err = Net::SSLeay::CTX_set_verify_depth($self->{context}, $params->{caverifydepth} || 5)
         unless ($err && ($err == 1));
   }
   die "Error using cacrt: ".Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error())
      if ($err && ($err != 1));

   $err = undef;
   $err = Net::SSLeay::CTX_set_cipher_list($self->{context}, $params->{cipher})
      if ($params->{cipher});
   die "Error setting cipher: ".Net::SSLeay::ERR_error_string(ERR_get_error())
      if ($err && ($err != 1));

   $err = undef;
   $self->{rbio} = Net::SSLeay::BIO_new(Net::SSLeay::BIO_s_mem())
      or die("Error creating r BIO: ".Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error()));
   $self->{wbio} = Net::SSLeay::BIO_new(Net::SSLeay::BIO_s_mem())
      or die("Error creating w BIO: ".Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error()));
   $self->{ssl} = Net::SSLeay::new($self->{context});
   $err = Net::SSLeay::set_bio($self->{ssl}, $self->{rbio}, $self->{wbio});
   die "Error setting r/w BIOs: ".Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error())
      if ($err && ($err != 1));

   if ($params->{dhcert} ||
       $params->{dhcertmem}) {
      my $dhbio = undef;
      if ($params->{dhcertmem}) {
         $dhbio = dataToBio($params->{dhcertmem});
      } else {
         die "Cannot open dhcert file!"
            unless ((-s $params->{dhcert}) && ($dhbio = Net::SSLeay::BIO_new_file($params->{dhcert}, "r")));
      }
      # TODO:XXX:FIXME: Errorchecking!
      my $dhret = Net::SSLeay::PEM_read_bio_DHparams($dhbio);
      print "Loaded dhcert with result ".$err."\n"
         if $self->{debug};
      Net::SSLeay::BIO_free($dhbio);
      die "Couldn't set DH parameters!"
         if (SSL_set_tmp_dh($self->{ssl}, $dhret) < 0);
      print "Set dhcert params with result ".$err."\n"
         if $self->{debug};
      #die "Couldn't set CTX DH parameters!"
      #   if (SSL_CTX_set_tmp_dh($self->{context}, $dhret) < 0);
      # TODO:XXX:FIXME: Errorchecking!
      my $rsa = Net::SSLeay::RSA_generate_key(2048, 73);
      #die "Couldn't set RSA key!"
      #   if (!Net::SSLeay::set_tmp_rsa($self->{ssl}, $rsa));
      die "Couldn't set RSA key!"
         if (!SSL_CTX_set_tmp_rsa($self->{context}, $rsa));
      print "Set dhrsa with result ".$err."\n"
         if $self->{debug};
      Net::SSLeay::RSA_free($rsa);
   }
   my $orfilter = &Net::SSLeay::VERIFY_PEER;
   $orfilter |=   &Net::SSLeay::VERIFY_CLIENT_ONCE
      if $params->{clientcert};
   $orfilter |=   &Net::SSLeay::VERIFY_FAIL_IF_NO_PEER_CERT
      if $params->{blockbadclientcert};
   # TODO:XXX:FIXME: Errorchecking!
   #Net::SSLeay::CTX_set_verify($self->{context}, $orfilter, \&VERIFY);
   Net::SSLeay::set_verify($self->{ssl}, $orfilter, \&VERIFY);
   print "Set verify ".($params->{blockbadclientcert} ? "FORCE" : "")." ".$orfilter."\n"
      if $self->{debug};
   if ($params->{sni}) {
      my $err = Net::SSLeay::set_tlsext_host_name($self->{ssl}, $params->{sni});
      print "Set sni with result ".$err."\n"
         if $self->{debug};
      die "Error setting sni:".Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error())
         if ($err && ($err != 1));
   }
   $self->{ignoreVerifyErrors} = $params->{ignoreVerifyErrors}
      if ($params->{ignoreVerifyErrors} &&
     (ref($params->{ignoreVerifyErrors}) eq "ARRAY"));

   $self
}

sub VERIFY {
   my ($ok, $x509_store_ctx) = @_;
   my $self = $globalinfos->[3] || {};
   print "VERIFY ".$ok
      if $self->{debug};
   my $errcode = Net::SSLeay::X509_STORE_CTX_get_error($x509_store_ctx);
   if ($self->{ignoreVerifyErrors} &&
  (ref($self->{ignoreVerifyErrors}) eq "ARRAY") && (scalar(grep { $errcode == $_ }
     @{$self->{ignoreVerifyErrors}}))) {
      $ok = 1;
      print " -> ".$ok." (Ignoring error ".$errcode.")"
         if $self->{debug};
   }
   print "\n"
      if $self->{debug};
   $globalinfos->[0] = $ok ? 1 : 2
      if ($globalinfos->[0] != 2);
   $globalinfos->[1]++;
   # TODO:XXX:FIXME: Chainlength check
   #X509_STORE_CTX_set_error($x509_store_ctx, X509_V_ERR_CERT_CHAIN_TOO_LONG)
   #   if (X509_STORE_CTX_get_error_depth(ctx) > uuu);
   # TODO:XXX:FIXME: No globalconfig
   #    ssl = X509_STORE_CTX_get_ex_data(ctx, SSL_get_ex_data_X509_STORE_CTX_idx());
   #    mydata = SSL_get_ex_data(ssl, mydata_index);
   if (my $x = Net::SSLeay::X509_STORE_CTX_get_current_cert($x509_store_ctx)) {
      push(@{$globalinfos->[2]},[Net::SSLeay::X509_NAME_oneline(Net::SSLeay::X509_get_subject_name($x)),
                                 Net::SSLeay::X509_NAME_oneline(Net::SSLeay::X509_get_issuer_name($x)),
                                 X509_get_serialNumber($x),
                                 $errcode]);
   }
   Net::SSLeay::X509_STORE_CTX_set_error($x509_store_ctx, 0);
   return 1; # $ok; # 1=accept cert, 0=reject
}

sub clone {
   my $self = shift;
   return POE::Filter::SSL->new(%{$self->{params}});
}

sub get_one_start {
   my ($self, $data) = @_;
   print "GETONESTART: NETWORK -> SSL -> POE: ".$self->hexdump(join("", @$data))."\n"
      if $self->{debug};
   $self->writeToSSLBIO(join("", @$data), $self->{accepted} ? 0 : 1);
   []
}

sub get_one {
   my $self = shift;
   print "GETONE: BEGIN\n"
      if $self->{debug};
   my @return = ();
   push(@return, $self) if ($self->doSSL() || $self->{buffer});
   my $data = Net::SSLeay::read($self->{ssl});
   push(@return, $data)
      if $data;
   print "GETONE: END: ".scalar(@return)."\n"
      if $self->{debug};
   [@return]
}

sub get {
   my ($self, $chunks) = @_;
   print "GET: BEGIN\n"
      if $self->{debug};
   my @return = ();
   #print "GET:\n"
   #   if $self->{debug};
   push(@return, $self) if ($self->doSSL() || $self->{buffer});
   foreach my $data (@$chunks) {
      print "GET: NETWORK -> SSL -> POE: ".join("", @$data)."\n"
         if $self->{debug};
      $self->writeToSSLBIO(join("", @$data));
      my $data = Net::SSLeay::read($self->{ssl});
      print "GET: Read ".length($data)." bytes.\n"
         if $self->{debug};
      push(@return, $data);
   }
   [@return]
}

sub put {
   my ($self, $chunks) = @_;
   print "PUT: BEGIN\n"
      if $self->{debug};
   my @return = ();
   $self->doSSL();
   if ($self->{accepted}) {
      if (defined($self->{sendbuf})) {
         foreach my $cdata (@{$self->{sendbuf}}) {
            $self->writeToSSL($cdata);
         }
         delete($self->{sendbuf});
      }
   }
   foreach my $data (@$chunks) {
      next if (ref($data) eq "POE::Filter::SSL");
      print "PUT: POE -> SSL -> NETWORK: ".$self->hexdump($data)."\r\n"
         if $self->{debug};
      if ($self->{accepted}) {
         $self->writeToSSL($data);
      } else {
         push(@{$self->{sendbuf}}, $data)
            if ($data);
      }
   }
   push(@return, $self->{buffer})
      if $self->{buffer};
   $self->{buffer} = '';
   [@return]
}

sub writeToSSL {
   my $self = shift;
   my $data = shift;
   if ((my $sent = Net::SSLeay::write($self->{ssl}, $data)) != length($data)) {
      my $err2 = Net::SSLeay::get_error($self->{ssl}, $sent);
      #die("PUT: Not all data given to SSL(".$err2."): ".$sent." != ".length($data)) if ($sent);
   }
   $self->doSSL();
}

sub writeToSSLBIO {
   my $self = shift;
   my $data = shift;
   my $nodoSSL = shift;
   if ((my $sent = Net::SSLeay::BIO_write($self->{rbio}, $data)) != length($data)) {
      my $err2 = Net::SSLeay::get_error($self->{ssl}, $sent);
      #die("GET: Not all data given to BIO SSL(".$err2."): ".$sent." != ".length($data)) if ($sent);
   }
   $self->doSSL() unless $nodoSSL;
}

sub get_pending {
  return undef;
}

sub doSSL {
   my $self = shift;
   my $ret = 0;
   print "SSLing..."
      if $self->{debug};
   unless ($self->{accepted}) {
      my $err = $self->{client} ?
         Net::SSLeay::connect($self->{ssl}) :
         Net::SSLeay::accept($self->{ssl});
      if ($err == 1) {
         $self->{infos} = [((@$globalinfos)[0..2])];
         $globalinfos = [0, 0, []];
         $self->{accepted}++;
         $ret++;
      } else {
         my $errtext = $!;
         my $err2 = Net::SSLeay::get_error($self->{ssl}, $err);
         unless ($err2 == Net::SSLeay::ERROR_WANT_READ()) {
            my $tmp = "POE::Filter::SSL: ".($self->{client} ? "connect" : "accept").": ";
            my $err3 = undef;
            if ($err3 = Net::SSLeay::ERR_get_error()) {
               $tmp .= Net::SSLeay::ERR_error_string($err3)."(".$err3.", ".$err2.")";
            } else {
               $tmp .= "No error (return=".$err2.")";
            }
            if (defined($self->{errorhandler})) {
               if (ref($self->{errorhandler}) eq "CODE") {
                  $self->{errorhandler}($self, {
                     ssl       => $self->{ssl},
                     msg       => $tmp,
                     ret       => $err,
                     get_error => $err2,
                     error     => $err3,
                  });
               } elsif(lc($self->{errorhandler}) eq "ignore") {
               } elsif(lc($self->{errorhandler}) eq "carp") {
                  carp($tmp);
               } elsif(lc($self->{errorhandler}) eq "confess") {
                  confess($tmp);
               } elsif(lc($self->{errorhandler}) eq "carponetime") {
                  carp($tmp)
                     unless $self->{errorstat}->{$err||"-"}->{$err2||"-"}->{$err3||"-"}++;
               }
            } else {
               carp($tmp);
            }
            $ret++
               unless $self->{accepted}++;
         }
      }
   }
   while (my $data = Net::SSLeay::BIO_read($self->{wbio})) {
      $self->{buffer} .= $data;
   }
   print $ret."\n"
      if $self->{debug};
   return $ret;
}

sub getCipher {
   my $self = shift;
   return Net::SSLeay::get_cipher($self->{ssl});
}

sub clientCertExists {
   my $self = shift;
   return ((ref($self->{infos}) eq "ARRAY") && ($self->{infos}->[1]));
}

sub clientCertValid {
   my $self = shift;
   my $valid = 1;
   if (defined($self->{cacrl})) {
      $valid = $self->clientCertNotOnCRL($self->{cacrl}) ? 1 : 0;
   }
   return $self->clientCertExists() ? (($self->{infos}->[0] ne "2") && scalar(@{$self->{infos}->[2]}) && $valid) : undef;
}

sub clientCertIds {
   my $self = shift;
   return $self->clientCertExists ? @{$self->{infos}->[2]} : undef;
}

sub clientCertNotOnCRL {
   my $self = shift;
   my $crlfilename = shift;
   my @certids = $self->clientCertIds();
   if (scalar(@certids)) {
      my $found = 0;
      my $badcrls = 0;
      my $jump = 0;
      print("----- SSL Infos BEGIN ---------------"."\n")
         if $self->{debug};
      foreach (@{$self->{infos}->[2]}) {
         my $crlstatus = verify_serial_against_crl_file($crlfilename, $_->[2]);
         $badcrls++ if $crlstatus;
         $crlstatus = $crlstatus ? "INVALID (".($crlstatus !~ m,^CRL:, ? $self->hexdump($crlstatus) : $crlstatus).")" : "VALID";
         my $t = ("  " x $jump++);
         if (ref($_) eq "ARRAY") {
            if ($self->{debug}){
               print(" ".$t."  |---[ Subcertificate ]---\n") if $t;
               print(" ".$t."  | Subject Name: ".$_->[0]."\n");
               print(" ".$t."  | Issuer Name : ".$_->[1]."\n");
               print(" ".$t."  | Serial      : ".$self->hexdump($_->[2])."\n");
               print(" ".$t."  | CRL Status  : ".$crlstatus."\n");
            }
         } else {
            print(" NOCERTINFOS!"."\n") if $self->{debug};
            return 0;
         }
      }
      print("----- SSL Infos END -----------------"."\n") if $self->{debug};
      return 1 unless $badcrls;
   }
   return 0;
}

sub handshakeDone {
   my $self = shift;
   my $params = {@_};
   return ($self->{accepted} && (($params->{ignorebuf}) || ((!$self->{sendbuf}) && (!$self->{buffer})))) || 0;
}

sub DESTROY {
   my $self = shift;
   Net::SSLeay::free($self->{ssl})
      if $self->{ssl};
   Net::SSLeay::CTX_free($self->{context})
      if $self->{context};
   #Net::SSLeay::BIO_free($self->{bio}) # CTX_free automatically frees BIO!!!
   #   if $self->{bio};
}

sub hexdump { my $self = shift; join ':', map { sprintf "%02X", $_ } unpack "C*", $_[0]; }

1;

__END__

=head1 NAME

POE::Filter::SSL - The easiest and flexiblest way to SSL in POE!

=head1 VERSION

Version 0.37

=head1 DESCRIPTION

This module allows one to secure connections of I<POE::Wheel::ReadWrite> with OpenSSL by a
I<POE::Filter> object, and behaves (beside of SSLing) as I<POE::Filter::Stream>.

I<POE::Filter::SSL> can be added, switched and removed during runtime, for example if you
want to initiate SSL (see the I<SSL on an established connection> example in I<SYNOPSIS>) on an already established connection. You are able to combine
I<POE::Filter::SSL> with other filters, for example have a HTTPS server together
with I<POE::Filter::HTTPD> (see the I<HTTPS-Server> example in I<SYNOPSIS>).

I<POE::Filter::SSL> is based on I<Net::SSLeay>, but got two XS functions which I<Net::SSLeay> is missing.

=over 4

=item B<Features>

=over 2

Full non-blocking processing

No use of sockets at all

Server and client mode

Optional client certificate verification

Allows one to accept connections with invalid or missing client certificate and return custom error data

CRL check of client certificates

Retrieve client certificate details (subject name, issuer name, certificate serial)

=back

=back

=over 4

=item B<Upcoming Features>

=over 2

Direct cipher encryption without SSL or TLS protocol, for example with static AES encryption

=back

=back

=head1 SYNOPSIS

By default I<POE::Filter::SSL> acts as a SSL server. To use it in client mode you just have to set the I<client> option of I<new()>.

=over 2

=item TCP-Client

  #!perl

  use warnings;
  use strict;

  use POE qw(Component::Client::TCP Filter::SSL);

  POE::Component::Client::TCP->new(
    RemoteAddress => "yahoo.com",
    RemotePort    => 443,
    Filter        => [ "POE::Filter::SSL", client => 1 ],
    Connected     => sub {
      $_[HEAP]{server}->put("HEAD /\r\n\r\n");
    },
    ServerInput   => sub {
      print "from server: ".$_[ARG0]."\n";
    },
  );

  POE::Kernel->run();
  exit;

=item TCP-Server

  #!perl

  use warnings;
  use strict;

  use POE qw(Component::Server::TCP);

  POE::Component::Server::TCP->new(
    Port => 443,
    ClientFilter => [ "POE::Filter::SSL", crt => 'server.crt', key => 'server.key' ],
    ClientConnected => sub {
      print "got a connection from $_[HEAP]{remote_ip}\n";
      $_[HEAP]{client}->put("Smile from the server!\r\n");
    },
    Alias => "tcp",
    ClientInput => sub {
      my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
      $_[HEAP]{client}->put("You sent:\r\n".$_[ARG0]);
      $_[KERNEL]->yield("shutdown");
    },
  );

  POE::Kernel->run;
  exit;

=item HTTPS-Server

  use POE::Filter::SSL;
  use POE::Component::Server::HTTP;
  use HTTP::Status;
  my $aliases = POE::Component::Server::HTTP->new(
    Port => 443,
    ContentHandler => {
      '/' => \&handler,
      '/dir/' => sub { return; },
      '/file' => sub { return; }
    },
    Headers => { Server => 'My Server' },
    PreFilter => POE::Filter::SSL->new(
      crt    => 'server.crt',
      key    => 'server.key',
      cacrt  => 'ca.crt'
    )
  );

  sub handler {
    my ($request, $response) = @_;
    $response->code(RC_OK);
    $response->content("Hi, you fetched ". $request->uri);
    return RC_OK;
  }

  POE::Kernel->run();
  POE::Kernel->call($aliases->{httpd}, "shutdown");
  # next line isn't really needed
  POE::Kernel->call($aliases->{tcp}, "shutdown");

=back

=head2 SSL on an established connection

=over 2

=item Advanced Example

This example is an IMAP-Relay which forwards the connections to a IMAP server
by username. It allows one the uncrypted transfer on port 143, with the option
of SSL on the established connection (STARTTLS). On port 993 it allows one to do
direct SSL.

Tested with Thunderbird version 3.0.5.

  #!perl

  use warnings;
  use strict;

  use POE qw(Component::Server::TCP Component::Client::TCP Filter::SSL Filter::Stream);

  my $defaultImapServer = "not.existing.de";
  my $usernameToImapServer = {
    user1 => 'mailserver1.domain.de',
    user2 => 'mailserver2.domain.de',
    # ...
  };

  POE::Component::Server::TCP->new(
    Port => 143,
    ClientFilter => "POE::Filter::Stream",
    ClientDisconnected => \&disconnect,
    ClientConnected => \&connected,
    ClientInput => \&handleInput,
    InlineStates => {
      send_stuff => \&send_stuff,
      _child => \&child
    }
  );

  POE::Component::Server::TCP->new(
    Port => 993,
    ClientFilter => [ "POE::Filter::SSL", crt => 'server.crt', key => 'server.key' ],
    ClientConnected => \&connected,
    ClientDisconnected => \&disconnect,
    ClientInput => \&handleInput,
    InlineStates => {
      send_stuff => \&send_stuff,
      _child => \&child
    }
  );

  sub disconnect {
    my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
    logevent('server got disconnect', $session);
    $kernel->post($heap->{client_id} => "shutdown");
  }

  sub connected {
    my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
    logevent("got a connection from ".$heap->{remote_ip}, $session);
    $heap->{client}->put("* OK [CAPABILITY IMAP4rev1 UIDPLUS CHILDREN NAMESPACE THREAD=ORDEREDSUBJECT THREAD=REFERENCES SORT QUOTA IDLE ACL ACL2=UNION STARTTLS] IMAP Relay v0.1 ready.\r\n");
  }

  sub send_stuff {
    my ($heap, $stuff, $session) = @_[HEAP, ARG0, SESSION];
    logevent("-> ".length($stuff)." Bytes", $session);
    (defined($heap->{client})) && (ref($heap->{client}) eq "POE::Wheel::ReadWrite") &&
    $heap->{client}->put($stuff);
  }

  sub child {
    my ($heap, $child_op, $child) = @_[HEAP, ARG0, ARG1];
    if ($child_op eq "create") {
      $heap->{client_id} = $child->ID;
    }
  }

  sub handleInput {
    my ($kernel, $session, $heap, $input) = @_[KERNEL, SESSION, HEAP, ARG0];
    if($heap->{forwarding}) {
      return $kernel->yield("shutdown") unless (defined($heap->{client_id}));
      $kernel->post($heap->{client_id} => send_stuff => $input);
    } elsif ($input =~ /^(\d+)\s+STARTTLS[\r\n]+/i) {
      $_[HEAP]{client}->put($1." OK Begin SSL/TLS negotiation now.\r\n");
      logevent("SSLing now...", $session);
      $_[HEAP]{client}->set_filter(POE::Filter::SSL->new(crt => 'server.crt', key => 'server.key'));
    } elsif ($input =~ /^(\d+)\s+CAPABILITY[\r\n]+/i) {
      $_[HEAP]{client}->put("* CAPABILITY IMAP4rev1 UIDPLUS CHILDREN NAMESPACE THREAD=ORDEREDSUBJECT THREAD=REFERENCES SORT QUOTA IDLE ACL ACL2=UNION STARTTLS\r\n");
      $_[HEAP]{client}->put($1." OK CAPABILITY completed\r\n");
    } elsif ($input =~ /^(\d+)\s+login\s+\"(\S+)\"\s+\"(\S+)\"[\r\n]+/i) {
      my $username = $2;
      my $pass = $3;
      logevent("login of user ".$username, $session);
      spawn_client_side($username, $input);
      $heap->{forwarding}++;
    } else {
      logevent("unknown command before login, disconnecting.", $session);
      return $kernel->yield("shutdown");
    }
  }

  sub spawn_client_side {
    my $username = shift;
    POE::Component::Client::TCP->new(
      RemoteAddress => $usernameToImapServer->{$username} || $defaultImapServer,
      RemotePort    => 143,
      Filter => "POE::Filter::Stream",
      Started       => sub {
        $_[HEAP]->{server_id} = $_[SENDER]->ID;
        $_[HEAP]->{buf} = $_[ARG0];
        $_[HEAP]->{skip} = 0;
      },
      Connected => sub {
        my ($heap, $session) = @_[HEAP, SESSION];
        logevent('client connected', $session);
        $heap->{server}->put($heap->{buf});
        delete $heap->{buf};
      },
      ServerInput => sub {
        my ($kernel, $heap, $session, $input) = @_[KERNEL, HEAP, SESSION, ARG0];
        #logevent('client got input', $session, $input);
        $kernel->post($heap->{server_id} => send_stuff => $input) if ($heap->{skip}++);
      },
      Disconnected => sub {
        my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];
        logevent('client disconnected', $session);
        $kernel->post($heap->{server_id} => 'shutdown');
      },
      InlineStates => {
        send_stuff => sub {
          my ($heap, $stuff, $session) = @_[HEAP, ARG0, SESSION];
          logevent("<- ".length($stuff)." Bytes", $session);
          (defined($heap->{server})) && (ref($heap->{server}) eq "POE::Wheel::ReadWrite") && 
          $heap->{server}->put($stuff);
        },
      },
      Args => [ shift ]
    );
  }

  sub logevent {
    my ($state, $session, $arg) = @_;
    my $id = $session->ID();
    print "session $id $state ";
    print ": $arg" if (defined $arg);
    print "\n";
  }

  POE::Kernel->run;

=back

=head2 Client certificate verification

=over 2

=item Advanced Example

The following example implements a HTTPS server with client certificate verification, which shows details about the verified client certificate.

  #!perl

  use strict;
  use warnings;
  use Socket;
  use POE qw(
    Wheel::SocketFactory
    Wheel::ReadWrite
    Driver::SysRW
    Filter::SSL
    Filter::Stackable
    Filter::HTTPD
  );

  POE::Session->create(
    inline_states => {
      _start       => sub {
        my $heap = $_[HEAP];
        $heap->{listener} = POE::Wheel::SocketFactory->new(
          BindAddress  => '0.0.0.0',
          BindPort     => 443,
          Reuse        => 'yes',
          SuccessEvent => 'socket_birth',
          FailureEvent => '_stop',
        );
      },
      _stop => sub {
        delete $_[HEAP]->{listener};
      },
      socket_birth => sub {
        my ($socket) = $_[ARG0];
        POE::Session->create(
          inline_states => {
            _start       => sub {
              my ($heap, $kernel, $connected_socket, $address, $port) = @_[HEAP, KERNEL, ARG0, ARG1, ARG2];
              $heap->{sslfilter} = POE::Filter::SSL->new(
                 crt    => 'server.crt',
                 key    => 'server.key',
                 cacrt  => 'ca.crt',
                 cipher => 'DHE-RSA-AES256-GCM-SHA384:AES256-SHA',
                 #cacrl  => 'ca.crl', # Uncomment this, if you have a CRL file.
                 debug  => 1,
                 clientcert => 1
              );
              $heap->{socket_wheel} = POE::Wheel::ReadWrite->new(
                Handle     => $connected_socket,
                Driver     => POE::Driver::SysRW->new(),
                Filter     => POE::Filter::Stackable->new(Filters => [
                  $heap->{sslfilter},
                  POE::Filter::HTTPD->new()
                ]),
                InputEvent => 'socket_input',
                ErrorEvent => '_stop',
              );
            },
            socket_input => sub {
              my ($kernel, $heap, $buf) = @_[KERNEL, HEAP, ARG0];
              my (@certid) = ($heap->{sslfilter}->clientCertIds());
              my $content = '';
              if ($heap->{sslfilter}->clientCertValid()) {
                $content .= "Hello <font color=green>valid</font> client Certifcate:";
              } else {
                $content .= "None or <font color=red>invalid</font> client certificate:";
              }
              $content .= "<hr>";
              foreach my $certid (@certid) {
                $certid = $certid ? $certid->[0]."<br>".$certid->[1]."<br>SERIAL=".$heap->{sslfilter}->hexdump($certid->[2]) : 'No client certificate';
                $content .= $certid."<hr>";
              }
              $content .= "Your URL was: ".$buf->uri."<hr>"
                if (ref($buf) eq "HTTP::Request");
              $content .= localtime(time());
              my $response = HTTP::Response->new(200);
              $response->push_header('Content-type', 'text/html');
              $response->content($content);
              $heap->{socket_wheel}->put($response);
              $kernel->delay(_stop => 1);
            },
            _stop => sub {
              delete $_[HEAP]->{socket_wheel};
            }
          },
          args => [$socket],
        );
      }
    }
  );

  $poe_kernel->run();

=back

=head1 FUNCTIONS

=over 4

=item B<new(option => value, option => value, option...)>

Returns a new I<POE::Filter::SSL> object. It accepts the following options:

=over 2

=item client

By default I<POE::Filter::SSL> acts as a SSL server. To use it in client mode, you have to set this option.

=item crt{mem}

The certificate file (.crt) for the server, a client certificate in client mode.

You are able to pass the already inmemory crt file as scalar via I<crtmem>.

=item key{mem}

The key file (.key) of the certificate (see I<crt> above).

You are able to pass the already inmemory key file as scalar via I<keymem>.

=item cacrt{mem}

The ca certificate file (ca.crt), which is used to verificate the client certificates against a CA. You can store multiple ca in one file, all of them gets imported.

You are able to pass the already inmemory cacrt file as scalar via I<cacrtmem> or as an array ref of scalars, if you have multiple ca.

=item caverifydepth

By default the ca verify depth is 5, you can override this via this option.

=item chain

Chain certificate, you need it for example for startssl.org which needs a intermedia certificates. Here you can configure it. You can generate this the following way:

cat client.crt intermediate.crt ca.crt > chain.pem

In this case, you normalyly have no I<key> and I<crt> option. Currently it is not possible to pass this inmemory, only by file.

=item cacrl

Configures a CRL (ca.crl) against the client certificate is verified by I<clientCertValid()>.

=item dhcert{mem}

If you want to enable perfect forward secrecy, here you can enable Diffie-Hellman. You just have to create a dhparam file and there here the path to the path/to/FILENAME.pem where your Diffie-Hellman (pem format) stays.

openssl dhparam -check -text -5 2048 -out path/to/FILENAME.pem

You are able to pass the already inmemory dhparam file as scalar(string) via I<dhcertmem>.

=item clientcert

Only in server mode: Request during ssl handshake from the client a client certificat.

B<WARNING:> If the client provides an untrusted or no client certificate, the connection is B<not> failing. You have to ask I<clientCertValid()> if the certificate is valid!

=item sni

Allows to set the SNI hostname indication in first packet of handshake. See https://de.wikipedia.org/wiki/Server_Name_Indication

=item tls

Force in the handshake the use of tls, disables support for the obsolete SSL handshake.

=item tls1_2

Force in the handshake the use of tls in version 1.2, disables support for the obsolete SSL handshake.

=item nohonor

By default, as server, I<POE::Filter:SSL> sets the option I<SSL_OP_CIPHER_SERVER_PREFERENCE>. For more information you may google the pendant of apache I<SSLHonorCipherOrder>.

To flip back to the old behaviour, not setting this option, you can set nohonor.

=item cipher

Specify which ciphers are allowed for the synchronous encrypted transfer of the data over the ssl connection.

Example:

  cipher => 'DHE-RSA-AES256-GCM-SHA384:AES256-SHA'

=item blockbadclientcert

Let OpenSSL deny the connection if there is no client certificate.

B<WARNING:> If the client is listed in the CRL file or an invalid client certifiate has been sent, the connection will be established! You have to ask I<clientCertValid()> if you have the I<crl> option set on I<new()>, otherwise to ask I<clientCertNotOnCRL()> if the certificate is listed on your CRL file!

=item ignoreVerifyErrors

B<WARNING:> Before using this option, you should be realy sure that you know what you are doing!

Specify to ignore specific errors on verifying the certificate chain: This is for example useful to be able to fetch the time from via secure and trusted TLS connection. In this case, your time is wrong, so must ignore time errors, which are 9: X509_V_ERR_CERT_NOT_YET_VALID (certificate is not yet valid) and 10: X509_V_ERR_CERT_HAS_EXPIRED (certificate has expired).

The list of errors you can ignore can be found on the documentation:

L<https://wiki.openssl.org/index.php/Manual:Verify(1)>

Example:

  ignoreVerifyErrors => [ 9, 10, ]

=back

=item handshakeDone(options)

Returns I<true> if the handshake is done and all data for handshake has been written out. It accepts the following options:

=over 2

=item ignorebuf

Returns I<true> if OpenSSL has established the connection, regardless if all data has been written out. This is needed if you want to exchange the Filter of I<POE::Wheel::ReadWrite> before the first data comes in. This option have been only used by I<doHandshake()> to be able to add new filters before first cleartext data to be processed gets in.

=back

=item clientCertNotOnCRL($file)

Verifies if the serial of the client certificate is not contained in the CRL $file. No file caching is done, each call opens the file again.

B<WARNING:> If your CRL file is missing, can not be opened is empty or has no blocked certificate at all in it, then every call will get blocked!

=item clientCertIds()

Returns an array of every certificate found by OpenSSL. Each element
is again a array. The first element is the value of I<X509_get_subject_name>,
second is the value of I<X509_get_issuer_name> and third element is the
serial of the certificate in binary form. You have to use I<split()> and
I<ord()>, or the I<hexdump()> function, to convert it to a readable form.

Example:

  my ($certid) = ($heap->{sslfilter}->clientCertIds());
  $certid = $certid ? $certid->[0]."<br>".$certid->[1]."<br>SERIAL=".$heap->{sslfilter}->hexdump($certid->[2]) : 'No client certificate';

=item getCipher()

Returns the used cryptographic algorithm and length.

Example:

  $sslfilter->getCipher()

=item clientCertValid()

Returns I<true> if there is a client certificate that is valid. It
also tests against the CRL, if you have the I<cacrl> option set on I<new()>.

=item doHandshake($readWrite, $filter, $filter, ...) !!!REMOVED!!!

B<WARNING:> POE::Filter:SSL now is able to do the ssh handshake now without any helpers. Because of this, this function has been removed!

Allows one to add filters after the ssl handshake. It has to be called in the input handler, and needs the passing of the I<POE::Wheel::ReadWhile> object. If it returns false, you have to return from the input handler.

See the I<HTTPS-Server>, I<SSL on an established connection> and I<Client certificate verification> examples in I<SYNOPSIS>

=item clientCertExists()

Returns I<true> if there is a client certificate, that might be untrusted.

B<WARNING:> If the client provides an untrusted client certificate a client certificate that is listed in CRL, this function returns I<true>. You have to ask I<clientCertValid()> if the certificate is valid!

=item errorhandler

By default, every ssl error is escalated via carp. You may change this behaviour via this option to:

=over 2

=item "ignore"

Do not report any error.

=item I<CODE>

Setting errorhandler to a reference of a function allows one to be called it callback function with the following options:

ARG1: POE:SSL::Filter instance

ARG2: Ref on a Hash with the following keys:

  ret        The return code of Net::SSLeay::connect (client) or Net::SSLeay::accept (server)
  ssl        The SSL context (SSL_CTX)
  msg        The error message as text, as normally reported via carp
  get_error  The error code of get_error the ssl context
  error      The error code of get_error without context

=item "carp" (or undef)

Do Carp/carp on error.

=item "confess"

Do Carp/confess (stacktrace) on error.

=item "carponetime"

Report carp for one occurrence only one time - over all!

=back

=item debug

Shows debug messages of I<clientCertNotOnCRL()>.

=item hexdump($string)

Returns string data in hex format.

Example:

  perl -e 'use POE::Filter::SSL; print POE::Filter::SSL->hexdump("test")."\n";'
  74:65:73:74

=back

=head2 Internal functions and POE::Filter handler

=over 2

=item VERIFY()

=item X509_get_serialNumber()

=item SSL_CTX_set_tmp_dh()

=item SSL_CTX_set_tmp_rsa()

=item SSL_set_tmp_dh()

=item clone()

=item doSSL()

=item get()

=item get_one()

=item get_one_start()

=item get_pending()

=item writeToSSLBIO()

=item writeToSSL()

=item put()

=item verify_serial_against_crl_file()

=item DOSENDBACK()

=item checkForDoSendback()

=item CTX_add_client_CA()

=item PEMdataToEVP_PKEY

=item PEMdataToX509

=item dataToBio

=back

=head1 AUTHOR

Markus Schraeder, C<< <privi at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-poe-filter-ssl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Filter-SSL>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Filter::SSL

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Filter-SSL>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Filter-SSL>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Filter-SSL>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Filter-SSL>

=back

=head1 Commercial support

Commercial support can be gained at <sslsupport at cryptomagic.eu>.

Used in our products, you can find on L<https://www.cryptomagic.eu/>

=head1 COPYRIGHT & LICENSE

Copyright 2010-2017 Markus Schraeder, CryptoMagic GmbH, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of POE::Filter::SSL
