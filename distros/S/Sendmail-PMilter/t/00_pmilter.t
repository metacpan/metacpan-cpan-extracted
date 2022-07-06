#   Copyright (c) 2002-2004 Todd Vierling <tv@duh.org> <tv@pobox.com>
#   Copyright (c) 2004 Robert Casey <rob.casey@bluebottle.com>
#   Copyright (c) 2016-2018 GWHAYWOOD <comments via cpan please>
#   This file is covered by the terms in the file COPYRIGHT supplied with this
#   software distribution.


BEGIN {

    use Test::More 'tests' => 123;

    use_ok('Sendmail::PMilter');
}


#   Perform some basic tests of the module constructor and available methods

can_ok(
        'Sendmail::PMilter',
                'auto_getconn',
                'auto_setconn',
                'get_max_interpreters',
                'get_max_requests',
                'get_sendmail_cf',
                'get_sendmail_option',
                'get_sendmail_class',
		'ithread_dispatcher',
		'prefork_dispatcher',
		'postfork_dispatcher',
		'sequential_dispatcher',
		'main',
                'new',
                'register',
                'setconn',
                'set_dispatcher',
                'set_listen',
                'set_sendmail_cf',
                'set_socket'
);

ok( my $milter = Sendmail::PMilter->new );
isa_ok( $milter, 'Sendmail::PMilter' );


#   Perform some tests on namespace symbols which should be defined within the 
#   Sendmail::PMilter namespace.  Not tested yet is the export of these symbols 
#   into the caller's namespace - TODO.

my %CONSTANTS = (

	# Reply codes for return by milter callbacks to the MTA.
	'SMFIS_CONTINUE'	=>  100,
	'SMFIS_REJECT'		=>  101,
	'SMFIS_DISCARD'		=>  102,
	'SMFIS_ACCEPT'		=>  103,
	'SMFIS_TEMPFAIL'	=>  104,

	# Protocol flags, which permit a milter to make certain requests to the MTA at the negotiation stage (which
	# takes place at the beginning of processing every message, before the 'connect' callback is called by the MTA).
	'SMFIP_NOCONNECT'	=> 0x00000001,		# MTA should not send connect info
	'SMFIP_NOHELO'		=> 0x00000002,		# MTA should not send HELO info
	'SMFIP_NOMAIL'		=> 0x00000004,		# MTA should not send MAIL info
	'SMFIP_NORCPT'		=> 0x00000008,		# MTA should not send RCPT info
	'SMFIP_NOBODY'		=> 0x00000010,		# MTA should not send body
	'SMFIP_NOHDRS'		=> 0x00000020,		# MTA should not send headers
	'SMFIP_NOEOH'		=> 0x00000040,		# MTA should not send EOH
	'SMFIP_NR_HDR'		=> 0x00000080,		# No reply for headers
	'SMFIP_NOHREPL'		=> 0x00000080,		# No reply for headers (backward compatibility)
	'SMFIP_NOUNKNOWN'	=> 0x00000100,		# MTA should not send unknown commands
	'SMFIP_NODATA'		=> 0x00000200,		# MTA should not send DATA
	'SMFIP_SKIP'		=> 0x00000400,		# MTA understands the 'skip any remaining message body chunks' request (called from EOM callback).
	'SMFIP_RCPT_REJ'	=> 0x00000800,		# MTA should also send recipients rejected e.g. if they are unknown (but not on error conditions).
	'SMFIP_NR_CONN'		=> 0x00001000,		# No reply for CONNECT
	'SMFIP_NR_HELO'		=> 0x00002000,		# No reply for HELO
	'SMFIP_NR_MAIL'		=> 0x00004000,		# No reply for MAIL
	'SMFIP_NR_RCPT'		=> 0x00008000,		# No reply for RCPT
	'SMFIP_NR_DATA'		=> 0x00010000,		# No reply for DATA
	'SMFIP_NR_UNKN'		=> 0x00020000,		# No reply for UNKN
	'SMFIP_NR_EOH'		=> 0x00040000,		# No reply for EOH
	'SMFIP_NR_BODY'		=> 0x00080000,		# No reply for BODY CHUNK
	'SMFIP_HDR_LEADSPC'	=> 0x00100000,		# Header value leading space will be managed by the milter
	'SMFIP_MDS_256K'	=> 0x10000000,		# MILTER_MAX_DATA_SIZE=256K
	'SMFIP_MDS_1M'		=> 0x20000000,		# MILTER_MAX_DATA_SIZE=1M

	# Convenience bit sets of the protocol flags associated with the SMFIP_* flags above, grouped by Milter Protocol Version.
	# 'SMFI_V1_PROT'	=>  0x0000003F,		# Protocol flags for Milter Protocol Version 1.  Milter Protocol Version 1 is obsolete, so we won't bother with it.
	'SMFI_V2_PROT'		=>  0x0000007F,		# Protocol flags for Milter Protocol Version 2.  Milter Protocol Version 2 will soon be obsolete.
	'SMFI_V6_PROT'		=>  0x001FFFFF,		# Protocol flags for Milter Protocol Version 6.

	# Capability flags for negotiation between a milter and an MTA, now largely unused.
	# Since the arrival of Milter Protocol Version 6 with Sendmail 8.14.0 in January 2010,
	# SMFIF_CHGFROM is now the only SMFIF_* flag which must be set in order to enable one
	# of the associated milter requests.
	'SMFIF_NONE'		=>  0x00000000,		# Not normally used.
	'SMFIF_ADDHDRS'		=>  0x00000001,		# Milter may add/insert headers
	'SMFIF_CHGBODY'		=>  0x00000002,		# Milter may replace message body; SMFIF_CHGBODY was introduced with Milter Protocol V2, to eventually replace SMFIF_MODBODY.
	'SMFIF_MODBODY'		=>  0x00000002,		# Milter may replace message body; SMFIF_CHGBODY replaces SMFIF_MODBODY, which will eventually be removed.
	'SMFIF_ADDRCPT'		=>  0x00000004,		# Milter may add recipients
	'SMFIF_DELRCPT'		=>  0x00000008,		# Milter may delete recipients
	'SMFIF_CHGHDRS'		=>  0x00000010,		# Milter may change/delete headers
	'SMFIF_QUARANTINE'	=>  0x00000020,		# Milter may quarantine message
	'SMFIF_CHGFROM'		=>  0x00000040,		# Milter may change "from" (envelope sender)
	'SMFIF_ADDRCPT_PAR'	=>  0x00000080,		# Milter may add recipients (like SMFIF_ADDRCPT, but include extra arguments in the call)
	'SMFIF_SETSYMLIST'	=>  0x00000100,		# Milter may send set of symbols (macros) that it wants

	# Convenience bit sets of the 'actions' associated with the SMFIF_* flags above, grouped by Milter Protocol Version.
	'SMFI_V1_ACTS'		=>  0x0000000F,		# SMFIF_ADDHDRS|SMFIF_CHGBODY|SMFIF_ADDRCPT|SMFIF_DELRCPT
	'SMFI_V2_ACTS'		=>  0x0000003F,		# SMFI_V1_ACTS|SMFIF_CHGHDRS|SMFIF_QUARANTINE
	'SMFI_V6_ACTS'		=>  0x000001FF,		# SMFI_V2_ACTS|SMFIF_CHGFROM|SMFIF_ADDRCPT_PAR|SMFIF_SETSYMLIST
	'SMFI_CURR_ACTS'	=>  0x000001FF,		# SMFI_V6_ACTS (as of July 2019; see mfapi.h and mfdef.h in the Sendmail source)

	'MAXREPLYLEN'		=> 980,			# Maximum length of lines in a reply from the MTA to the client.
	'MAXREPLIES'		=> 32,			# Maximum number of lines in a multi-line reply from the MTA to the client.

);

foreach my $constant (keys %CONSTANTS) {

    no strict 'refs';
    my $symbol = "Sendmail::PMilter::$constant"->();
    ok( defined $symbol, "Sendmail::PMilter::$constant" );
    SKIP: {

        skip("- Sendmail::PMilter::$constant not defined", 1) unless defined $symbol;
        is( $symbol, $CONSTANTS{$constant} );
    }
}


#   Of the module methods, the get_sendmail_cf function is tested first given 
#   the number of other methods dependent upon this method.  By default, this 
#   method should return the Sendmail configuration file as '/etc/mail/sendmail.cf'.

ok( my $cf = $milter->get_sendmail_cf );
ok( defined $cf );
is( $cf, '/etc/mail/sendmail.cf' );


#   Test the corresponding set_sendmail_cf function by setting a new value for 
#   this parameter and then testing the return value from get_sendmail_cf

ok( $milter->set_sendmail_cf('t/files/sendmail.cf') );
is( $milter->get_sendmail_cf, 't/files/sendmail.cf' );
ok( $milter->set_sendmail_cf() );
is( $milter->get_sendmail_cf, '/etc/mail/sendmail.cf' );


#   Test the auto_getconn function using our own set of test sendmail 
#   configuration files - The first test should fail as a result of the name 
#   parameter not having been defined.

eval { $milter->auto_getconn() };
ok( defined $@ );

my @sockets = (
        'local:/var/run/milter.sock',
        'unix:/var/run/milter.sock',
        'inet:3333@localhost',
        'inet6:3333@localhost'
);
foreach my $index (0 .. 4) {

    my $cf = sprintf('t/files/sendmail%d.cf', $index);
    SKIP: {

        skip("- Missing file $cf", 3) unless -e $cf;
        ok( $milter->set_sendmail_cf($cf), $cf );
        my $socket = shift @sockets;
        ok( 
                ( ! defined $socket ) or 
                ( my $milter_socket = $milter->auto_getconn('test-milter') ) 
        );
        is( $milter_socket, $socket, defined $socket ? $socket : '(undef)' );


        #   Test the creation of the milter connection socket with the setconn function 
        #   for each of the test sendmail configuration files parsed.

    }
}


1;


__END__
