use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $define = '-DUSE_SMTPAUTH'; # disable if you do not need/have auth-client.h
my $libs   = `libesmtp-config --libs`;
chomp($libs);
my $otherldflags = " " . $libs;
$otherldflags =~ s/ \-[lLR]\S+//g;
$otherldflags =~ s/ \/\S+//g;
$otherldflags =~ s/  / /g;
$otherldflags =~ s/ +$//g;
$otherldflags =~ s/^ +//g;
my $incs   = `libesmtp-config --cflags`;
chomp($incs);
my $USE_OPENSSL = 1; # set to 0 if you do not have openssl installed

if ($USE_OPENSSL && $libs !~ /\-lssl/) {
    warn "libESMTP compiled without openssl support, disabling it in Net::ESMTP";
    $USE_OPENSSL = 0;
}

# Although $libs has -lssl it has no -L/usr/local/openssl/lib etc.
# (the same for $incs)

if ($USE_OPENSSL) {
    # searching for openssl - borrowed from Net-SSLeay
    # It seems at least Redhat installs OpenSSL in /usr ...
    my $openssl_path;
    $openssl_path = '/usr' if -x '/usr/bin/openssl' || -x '/usr/sbin/openssl';
    $openssl_path = '/opt/ssl' if -x '/opt/ssl/bin/openssl'
        || -x '/opt/ssl/sbin/openssl';
    $openssl_path = '/usr/local/ssl' if -x '/usr/local/ssl/bin/openssl';
    $openssl_path = '/apps/openssl/std' if -x '/apps/openssl/std/bin/openssl';
    $openssl_path = shift if @ARGV && $ARGV[0] ne '--';

    if (!-f "$openssl_path/include/openssl/ssl.h") {
	warn "Could not find <openssl/ssl.h>, disabling SSL support\n";
	$USE_OPENSSL = 0;
    } else {
        $incs .= " -I$openssl_path/include";
        $libs = "-L$openssl_path/lib $libs";

	# -DPERL5 is for conflicting definition of crypt in openssl/des.h
        $define .= ' -DPERL5 -DUSE_OPENSSL';
    }
}


WriteMakefile(
    'NAME'		=> 'Net::ESMTP',
    'VERSION_FROM'	=> 'ESMTP.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'ESMTP.pod', # retrieve abstract from module
       AUTHOR     => 'Piotr Klaban <post@klaban.torun.pl>') : ()),
    'LIBS'		=> [$libs], # e.g., '-lm'
    'dynamic_lib' => { 'OTHERLDFLAGS' => $otherldflags },
    # 'OPTIMIZE'          => '-O',
    # 'CCFLAGS'           => '-g -ggdb -Wall',
    'DEFINE'		=> $define,
	# Insert -I. if you add *.h files later:
    'INC'		=> $incs, # e.g., '-I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(
  SMTP_CB_HEADERS SMTP_CB_READING SMTP_CB_WRITING
  SMTP_ERR_DROPPED_CONNECTION SMTP_ERR_EAI_ADDRFAMILY SMTP_ERR_EAI_AGAIN SMTP_ERR_EAI_BADFLAGS
  SMTP_ERR_EAI_FAIL SMTP_ERR_EAI_FAMILY SMTP_ERR_EAI_MEMORY SMTP_ERR_EAI_NODATA
  SMTP_ERR_EAI_NONAME SMTP_ERR_EAI_SERVICE SMTP_ERR_EAI_SOCKTYPE SMTP_ERR_EXTENSION_NOT_AVAILABLE
  SMTP_ERR_HOST_NOT_FOUND SMTP_ERR_INVAL SMTP_ERR_INVALID_RESPONSE_STATUS SMTP_ERR_INVALID_RESPONSE_SYNTAX
  SMTP_ERR_NOTHING_TO_DO SMTP_ERR_NO_ADDRESS SMTP_ERR_NO_RECOVERY SMTP_ERR_STATUS_MISMATCH
  SMTP_ERR_TRY_AGAIN SMTP_ERR_UNTERMINATED_RESPONSE
  Timeout_OVERRIDE_RFC2822_MINIMUM
	 ));
  push @names,
    {name=>$_, type=>"IV",
     macro=>["#if defined(_auth_client_h)\n",
             "#endif\n"]}
     foreach qw(AUTH_USER AUTH_REALM AUTH_PASS AUTH_CLEARTEXT
                AUTH_PLUGIN_ANONYMOUS AUTH_PLUGIN_PLAIN AUTH_PLUGIN_EXTERNAL
     );
  push @names,
    {name=>$_, type=>"IV",
     macro=>1}
     foreach qw(
  By_NOTSET By_NOTIFY By_RETURN
  E8bitmime_NOTSET E8bitmime_7BIT E8bitmime_8BITMIME E8bitmime_BINARYMIME
  Hdr_OVERRIDE Hdr_PROHIBIT
  Notify_NOTSET Notify_NEVER Notify_SUCCESS Notify_FAILURE Notify_DELAY
  Ret_NOTSET Ret_FULL Ret_HDRS
  SMTP_EV_CONNECT SMTP_EV_MAILSTATUS SMTP_EV_RCPTSTATUS SMTP_EV_MESSAGEDATA
  SMTP_EV_MESSAGESENT SMTP_EV_DISCONNECT SMTP_EV_ETRNSTATUS SMTP_EV_EXTNA_DSN
  SMTP_EV_EXTNA_8BITMIME SMTP_EV_EXTNA_STARTTLS SMTP_EV_EXTNA_ETRN SMTP_EV_EXTNA_CHUNKING
  SMTP_EV_EXTNA_BINARYMIME SMTP_EV_DELIVERBY_EXPIRED SMTP_EV_WEAK_CIPHER SMTP_EV_STARTTLS_OK
  SMTP_EV_INVALID_PEER_CERTIFICATE SMTP_EV_NO_PEER_CERTIFICATE SMTP_EV_WRONG_PEER_CERTIFICATE
  SMTP_EV_NO_CLIENT_CERTIFICATE SMTP_EV_UNUSABLE_CLIENT_CERTIFICATE SMTP_EV_UNUSABLE_CA_LIST
  Starttls_DISABLED Starttls_ENABLED Starttls_REQUIRED
  Timeout_GREETING Timeout_ENVELOPE Timeout_DATA Timeout_TRANSFER Timeout_DATA2
     );

  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Net::ESMTP',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
