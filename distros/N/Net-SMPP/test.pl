# Test script for Net::SMPP
# 8.1.2002, Sampo Kellomaki <sampo@symlabs.com>
# $Id: test.pl,v 1.3 2002/05/27 04:14:43 sampo Exp $
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use Data::Dumper;

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..93\n"; }
END {print "not ok 1\n" unless $loaded;}
use Net::SMPP;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

sub fail_pdu {
    my ($n, $pdu) = @_;
    print "fail $n\n"
	. Dumper($pdu)
	    . Net::SMPP::hexdump($pdu->{data}, "\t");
    $fail++;
}

# Test packet encoding and decoding by sending a packet over a localhost
# socket and seeing that all parameters come through unmodified.

alarm 30;  # No test should last longer than this

$listen = Net::SMPP->new_listen('localhost',
                              port => 2251,
                              smpp_version => 0x34,
			      async=>1,
                              );
if ($listen) {
    print  "ok 2\n";

    $cli = Net::SMPP->new_connect('localhost',
				  port => 2251,
				  smpp_version => 0x34,
				  async=>1,
				  );
    if ($cli) {
	print "ok 3\n";

	$serv = $listen->accept;
	if ($serv) {
	    print "ok 4\n";
	    
	    ### Check sending every type of PDU. Note that this is
	    ### not necessarily a meaningful dialog - it only
	    ### tries to test packet assembly and disassembly.
	    ### In general, constants are specified explicitly as
	    ### numbers to ensure that errors in the constant
	    ### definitions themselves are caught.
	    ###
	    ### Every PDU is first tested in its default form with
	    ### only mandatory arguments supplied and letting everything
	    ### else take default values. Next PDU is tested with
	    ### all normal arguments and finally with all optional arguments.
	    
	    $seq = $cli->bind_transceiver() or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 9)
		&& ($pdu->{status} == 0)
		&& ($pdu->{system_id} eq '')
		&& ($pdu->{password} eq '')
		&& ($pdu->{system_type} eq '')
		&& ($pdu->{interface_version} == 0x34)
		&& ($pdu->{addr_ton} == 0)
		&& ($pdu->{addr_npi} == 0)
		&& ($pdu->{address_range} eq '')
		) {
		print "ok 5  (seq=$seq)\n";
	    } else {
		fail_pdu(5, $pdu);
	    }
	    
	    $seq = $serv->bind_transceiver_resp(seq=>$seq) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80000009)
		&& ($pdu->{status} == 0)
		&& ($pdu->{system_id} eq '')
		) {
		print "ok 6  (seq=$seq)\n";
	    } else {
		fail_pdu(6, $pdu);
	    }

	    $seq = $cli->bind_transceiver(system_id => 'testi',
					  password  => 'salainen',
					  system_type => 'penkki',
					  interface_version => 0x11,
					  addr_ton => 0x22,
					  addr_npi => 0x33,
					  address_range => '^\+1'
					  ) or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 9)
		&& ($pdu->{status} == 0)
		&& ($pdu->{system_id} eq 'testi')
		&& ($pdu->{password} eq 'salainen')
		&& ($pdu->{system_type} eq 'penkki')
		&& ($pdu->{interface_version} == 0x11)
		&& ($pdu->{addr_ton} == 0x22)
		&& ($pdu->{addr_npi} == 0x33)
		&& ($pdu->{address_range} eq '^\+1')
		) {
		print "ok 7  (seq=$seq)\n";
	    } else {
		fail_pdu(7, $pdu);
	    }
	    
	    $seq = $serv->bind_transceiver_resp(seq=>$seq,
						status=>0x44,
						system_id=>'tuoli') or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80000009)
		&& ($pdu->{status} == 0x44)
		&& ($pdu->{system_id} eq 'tuoli')
		) {
		print "ok 8  (seq=$seq)\n";
	    } else {
		fail_pdu(8, $pdu);
	    }
	    
	    $seq = $serv->bind_transceiver_resp(seq=>$seq,
						sc_interface_version=>'\x55\x66',
						system_id=>'tuoli') or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80000009)
		&& ($pdu->{status} == 0)
		&& ($pdu->{system_id} eq 'tuoli')
		&& ($pdu->{sc_interface_version} eq '\x55\x66')
		&& ($pdu->{0x210} eq '\x55\x66')
		) {
		print "ok 9  (seq=$seq)\n";
	    } else {
		fail_pdu(9, $pdu);
	    }
	    
	    ### N.B. bind_transmitter() and bind_receiver() encoders and decoders
	    ###      are the same and thus are not tested here	    	    

	    ### Outbind

	    $seq = $serv->outbind() or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0xb)
		&& ($pdu->{status} == 0)
		&& ($pdu->{system_id} eq '')
		&& ($pdu->{password} eq '')
		) {
		print "ok 10  (seq=$seq)\n";
	    } else {
		fail_pdu(10, $pdu);
	    }
	    
	    $seq = $serv->outbind(system_id => 'pensas',
				  password => 'sala') or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0xb)
		&& ($pdu->{status} == 0)
		&& ($pdu->{system_id} eq 'pensas')
		&& ($pdu->{password} eq 'sala')
		) {
		print "ok 11  (seq=$seq)\n";
	    } else {
		fail_pdu(11, $pdu);
	    }

	    ### Unbind

	    $seq = $cli->unbind() or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 6)
		&& ($pdu->{status} == 0)
		) {
		print "ok 12  (seq=$seq)\n";
	    } else {
		fail_pdu(12, $pdu);
	    }

	    $seq = $serv->unbind_resp(seq=>$seq) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80000006)
		&& ($pdu->{status} == 0)
		) {
		print "ok 13  (seq=$seq)\n";
	    } else {
		fail_pdu(13, $pdu);
	    }
	    
	    ### Generic NACK

	    $seq = $cli->generic_nack(seq=>$seq) or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80000000)
		&& ($pdu->{status} == 0)
		) {
		print "ok 14  (seq=$seq)\n";
	    } else {
		fail_pdu(14, $pdu);
	    }
	    
	    ### Submit SM
	    
	    $seq = $cli->submit_sm(destination_addr => '19258887777') or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 4)
		&& ($pdu->{status} == 0)
		&& ($pdu->{service_type} eq '')
		&& ($pdu->{source_addr_ton} == 0)
		&& ($pdu->{source_addr_npi} == 0)
		&& ($pdu->{source_addr} eq '')
		&& ($pdu->{dest_addr_ton} == 0)
		&& ($pdu->{dest_addr_npi} == 0)
		&& ($pdu->{destination_addr} eq '19258887777')
		&& ($pdu->{esm_class} == 0)
		&& ($pdu->{protocol_id} == 0)
		&& ($pdu->{priority_flag} == 0)
		&& ($pdu->{schedule_delivery_time} eq '')
		&& ($pdu->{validity_period} eq '')
		&& ($pdu->{registered_delivery} == 0)
		&& ($pdu->{replace_if_present_flag} == 0)
		&& ($pdu->{data_coding} == 0)
		&& ($pdu->{sm_default_msg_id} == 0)
		&& ($pdu->{short_message} eq '')
		) {
		print "ok 15  (seq=$seq)\n";
	    } else {
		fail_pdu(15, $pdu);
	    }
	    
	    $seq = $serv->submit_sm_resp(seq=>$seq,
						message_id=>'') or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80000004)
		&& ($pdu->{status} == 0)
		&& ($pdu->{message_id} eq '')
		) {
		print "ok 16  (seq=$seq)\n";
	    } else {
		fail_pdu(16, $pdu);
	    }
	    
	    $seq = $cli->submit_sm(service_type => 'foosv',
				   source_addr_ton => 0x11,
				   source_addr_npi => 0x22,
				   source_addr => '8199998888',
				   dest_addr_ton => 0x33,
				   dest_addr_npi => 0x44,
				   destination_addr => '19258887777',
				   esm_class => 0x55,
				   protocol_id => 0x66,
				   priority_flag => 0x77,
				   schedule_delivery_time => '0123456789abcdef',
				   validity_period => 'FEDCBA9876543210',
				   registered_delivery => 0x88,
				   replace_if_present_flag => 0x99,
				   data_coding => 0xaa,
				   sm_default_msg_id => 0xbb,
				   short_message => 'foobar',
				   ) or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 4)
		&& ($pdu->{status} == 0)
		&& ($pdu->{service_type} eq 'foosv')
		&& ($pdu->{source_addr_ton} == 0x11)
		&& ($pdu->{source_addr_npi} == 0x22)
		&& ($pdu->{source_addr} eq '8199998888')
		&& ($pdu->{dest_addr_ton} == 0x33)
		&& ($pdu->{dest_addr_npi} == 0x44)
		&& ($pdu->{destination_addr} eq '19258887777')
		&& ($pdu->{esm_class} == 0x55)
		&& ($pdu->{protocol_id} == 0x66)
		&& ($pdu->{priority_flag} == 0x77)
		&& ($pdu->{schedule_delivery_time} eq '0123456789abcdef')
		&& ($pdu->{validity_period} eq 'FEDCBA9876543210')
		&& ($pdu->{registered_delivery} == 0x88)
		&& ($pdu->{replace_if_present_flag} == 0x99)
		&& ($pdu->{data_coding} == 0xaa)
		&& ($pdu->{sm_default_msg_id} == 0xbb)
		&& ($pdu->{short_message} eq 'foobar')
		) {
		print "ok 17  (seq=$seq)\n";
	    } else {
		fail_pdu(17, $pdu);
	    }
	    
	    $seq = $serv->submit_sm_resp(seq=>$seq,
					 message_id=>'1234567') or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80000004)
		&& ($pdu->{status} == 0)
		&& ($pdu->{message_id} eq '1234567')
		) {
		print "ok 18  (seq=$seq)\n";
	    } else {
		fail_pdu(18, $pdu);
	    }

	    $seq = $cli->submit_sm(service_type => 'foosv',
				   source_addr_ton => 0x11,
				   source_addr_npi => 0x22,
				   source_addr => '8199998888',
				   dest_addr_ton => 0x33,
				   dest_addr_npi => 0x44,
				   destination_addr => '19258887777',
				   esm_class => 0x55,
				   protocol_id => 0x66,
				   priority_flag => 0x77,
				   schedule_delivery_time => '0123456789abcdef',
				   validity_period => 'FEDCBA9876543210',
				   registered_delivery => 0x88,
				   replace_if_present_flag => 0x99,
				   data_coding => 0xaa,
				   sm_default_msg_id => 0xbb,
				   user_message_reference => 'user msg ref',
				   source_port => '9999',
				   source_addr_subunit => "\xee",
				   destination_port => '8888',
				   dest_addr_subunit => "\xdd",
				   sar_msg_ref_num => "\xaa\xbb",
				   sar_total_segments => "\x01",
				   sar_segment_seqnum => "\x01",     # 1 out of 1
				   more_messages_to_send => "\x01",  # Yes
				   payload_type => "\x01",  # WCMP
				   message_payload => ('A' x 1024),
				   privacy_indicator => "\x03",  # secret
				   callback_num => "\x01\x05\x061234",  # ascii, TON=alphanum, NPI=Land mobile
				   callback_num_pres_ind => "\x05",
				   callback_num_atag => "\x03Greg",  # Latin1 Greg
				   source_subaddress => "\xa01234567890123456789012",
				   dest_subaddress => "\xa02101234567890123456789",
				   user_response_code => "\xaa",
				   display_time => "\x02", # Invoke
				   sms_signal => "\x11\x22",
				   ms_validity => "\x03",  # For your eyes only
				   ms_msg_wait_facilities => "\x82",  # email waiting icon
				   number_of_messages => "\x63",
				   alert_on_message_delivery => "",  # Value has to be empty
				   language_indicator => "\x05", # Portuguese
				   its_reply_type => "\x03",     # Password
				   its_session_info => "\x33\x01", # Session 0x33, dialogue unit 0, end of session
				   ussd_service_op => "\x02",    # USSR request
				   ) or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 4)
		&& ($pdu->{status} == 0)
		&& ($pdu->{service_type} eq 'foosv')
		&& ($pdu->{source_addr_ton} == 0x11)
		&& ($pdu->{source_addr_npi} == 0x22)
		&& ($pdu->{source_addr} eq '8199998888')
		&& ($pdu->{dest_addr_ton} == 0x33)
		&& ($pdu->{dest_addr_npi} == 0x44)
		&& ($pdu->{destination_addr} eq '19258887777')
		&& ($pdu->{esm_class} == 0x55)
		&& ($pdu->{protocol_id} == 0x66)
		&& ($pdu->{priority_flag} == 0x77)
		&& ($pdu->{schedule_delivery_time} eq '0123456789abcdef')
		&& ($pdu->{validity_period} eq 'FEDCBA9876543210')
		&& ($pdu->{registered_delivery} == 0x88)
		&& ($pdu->{replace_if_present_flag} == 0x99)
		&& ($pdu->{data_coding} == 0xaa)
		&& ($pdu->{sm_default_msg_id} == 0xbb)
		&& ($pdu->{short_message} eq '')
		&& ($pdu->{user_message_reference} eq 'user msg ref')
		&& ($pdu->{source_port} eq '9999')
		&& ($pdu->{source_addr_subunit} eq "\xee")
		&& ($pdu->{destination_port} eq '8888')
		&& ($pdu->{dest_addr_subunit} eq "\xdd")
		&& ($pdu->{sar_msg_ref_num} eq "\xaa\xbb")
		&& ($pdu->{sar_total_segments} eq "\x01")
		&& ($pdu->{sar_segment_seqnum} eq "\x01")     # 1 out of 1
		&& ($pdu->{more_messages_to_send} eq "\x01")  # Yes
		&& ($pdu->{payload_type} eq "\x01")  # WCMP
		&& ($pdu->{message_payload} eq ('A' x 1024))
		&& ($pdu->{privacy_indicator} eq "\x03")  # secret
		&& ($pdu->{callback_num} eq "\x01\x05\x061234")  # ascii, TON=alphanum, NPI=Land mobile
		&& ($pdu->{callback_num_pres_ind} eq "\x05")
		&& ($pdu->{callback_num_atag} eq "\x03Greg")  # Latin1 Greg
		&& ($pdu->{source_subaddress} eq "\xa01234567890123456789012")
		&& ($pdu->{dest_subaddress} eq "\xa02101234567890123456789")
		&& ($pdu->{user_response_code} eq "\xaa")
		&& ($pdu->{display_time} eq "\x02") # Invoke
		&& ($pdu->{sms_signal} eq "\x11\x22")
		&& ($pdu->{ms_validity} eq "\x03")  # For your eyes only
		&& ($pdu->{ms_msg_wait_facilities} eq "\x82")  # email waiting icon
		&& ($pdu->{number_of_messages} eq "\x63")
		&& ($pdu->{alert_on_message_delivery} eq "")  # Value has to be empty
		&& ($pdu->{language_indicator} eq "\x05") # Portuguese
		&& ($pdu->{its_reply_type} eq "\x03")     # Password
		&& ($pdu->{its_session_info} eq "\x33\x01") # Session 0x33, dialogue unit 0, end of session
		&& ($pdu->{ussd_service_op} eq "\x02")    # USSR request
		) {
		print "ok 19  (seq=$seq)\n";
	    } else {
		fail_pdu(19, $pdu);
	    }
	    
	    $seq = $serv->submit_sm_resp(seq=>$seq,
					 message_id=>'1234567') or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80000004)
		&& ($pdu->{status} == 0)
		&& ($pdu->{message_id} eq '1234567')
		) {
		print "ok 20  (seq=$seq)\n";
	    } else {
		fail_pdu(20, $pdu);
	    }

	    ### Deliver SM
	    
	    $seq = $serv->deliver_sm(destination_addr => '19258887777') or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 5)
		&& ($pdu->{status} == 0)
		&& ($pdu->{service_type} eq '')
		&& ($pdu->{source_addr_ton} == 0)
		&& ($pdu->{source_addr_npi} == 0)
		&& ($pdu->{source_addr} eq '')
		&& ($pdu->{dest_addr_ton} == 0)
		&& ($pdu->{dest_addr_npi} == 0)
		&& ($pdu->{destination_addr} eq '19258887777')
		&& ($pdu->{esm_class} == 0)
		&& ($pdu->{protocol_id} == 0)
		&& ($pdu->{priority_flag} == 0)
		&& ($pdu->{schedule_delivery_time} eq '')
		&& ($pdu->{validity_period} eq '')
		&& ($pdu->{registered_delivery} == 0)
		&& ($pdu->{replace_if_present_flag} == 0)
		&& ($pdu->{data_coding} == 0)
		&& ($pdu->{sm_default_msg_id} == 0)
		&& ($pdu->{short_message} eq '')
		) {
		print "ok 21  (seq=$seq)\n";
	    } else {
		fail_pdu(21, $pdu);
	    }
	    
	    $seq = $cli->deliver_sm_resp(seq=>$seq,
					 message_id=>'') or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80000005)
		&& ($pdu->{status} == 0)
		&& ($pdu->{message_id} eq '')
		) {
		print "ok 22  (seq=$seq)\n";
	    } else {
		fail_pdu(22, $pdu);
	    }
	    
	    $seq = $serv->deliver_sm(service_type => 'foosv',
				   source_addr_ton => 0x11,
				   source_addr_npi => 0x22,
				   source_addr => '8199998888',
				   dest_addr_ton => 0x33,
				   dest_addr_npi => 0x44,
				   destination_addr => '19258887777',
				   esm_class => 0x55,
				   protocol_id => 0x66,
				   priority_flag => 0x77,
				   schedule_delivery_time => '0123456789abcdef',
				   validity_period => 'FEDCBA9876543210',
				   registered_delivery => 0x88,
				   replace_if_present_flag => 0x99,
				   data_coding => 0xaa,
				   sm_default_msg_id => 0xbb,
				   short_message => 'foobar',
				   ) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 5)
		&& ($pdu->{status} == 0)
		&& ($pdu->{service_type} eq 'foosv')
		&& ($pdu->{source_addr_ton} == 0x11)
		&& ($pdu->{source_addr_npi} == 0x22)
		&& ($pdu->{source_addr} eq '8199998888')
		&& ($pdu->{dest_addr_ton} == 0x33)
		&& ($pdu->{dest_addr_npi} == 0x44)
		&& ($pdu->{destination_addr} eq '19258887777')
		&& ($pdu->{esm_class} == 0x55)
		&& ($pdu->{protocol_id} == 0x66)
		&& ($pdu->{priority_flag} == 0x77)
		&& ($pdu->{schedule_delivery_time} eq '0123456789abcdef')
		&& ($pdu->{validity_period} eq 'FEDCBA9876543210')
		&& ($pdu->{registered_delivery} == 0x88)
		&& ($pdu->{replace_if_present_flag} == 0x99)
		&& ($pdu->{data_coding} == 0xaa)
		&& ($pdu->{sm_default_msg_id} == 0xbb)
		&& ($pdu->{short_message} eq 'foobar')
		) {
		print "ok 23  (seq=$seq)\n";
	    } else {
		fail_pdu(23, $pdu);
	    }
	    
	    $seq = $cli->deliver_sm_resp(seq=>$seq,
					 message_id=>'1234567') or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80000005)
		&& ($pdu->{status} == 0)
		&& ($pdu->{message_id} eq '1234567')
		) {
		print "ok 24  (seq=$seq)\n";
	    } else {
		fail_pdu(24, $pdu);
	    }

	    $seq = $serv->deliver_sm(service_type => 'foosv',
				   source_addr_ton => 0x11,
				   source_addr_npi => 0x22,
				   source_addr => '8199998888',
				   dest_addr_ton => 0x33,
				   dest_addr_npi => 0x44,
				   destination_addr => '19258887777',
				   esm_class => 0x55,
				   protocol_id => 0x66,
				   priority_flag => 0x77,
				   schedule_delivery_time => '0123456789abcdef',
				   validity_period => 'FEDCBA9876543210',
				   registered_delivery => 0x88,
				   replace_if_present_flag => 0x99,
				   data_coding => 0xaa,
				   sm_default_msg_id => 0xbb,
				   user_message_reference => 'user msg ref',
				   source_port => '9999',
				   destination_port => '8888',
				   sar_msg_ref_num => "\xaa\xbb",
				   sar_total_segments => "\x01",
				   sar_segment_seqnum => "\x01",     # 1 out of 1
				   user_response_code => "\xaa",
				   privacy_indicator => "\x03",  # secret
				   payload_type => "\x01",  # WCMP
				   message_payload => ('A' x 1024),
				   callback_num => "\x01\x05\x061234",  # ascii, TON=alphanum, NPI=Land mobile
				   source_subaddress => "\xa01234567890123456789012",
				   dest_subaddress => "\xa02101234567890123456789",
				   language_indicator => "\x05", # Portuguese
				   its_session_info => "\x33\x01", # Session 0x33, dialogue unit 0, end of session
				   network_error_code => "\x03\x00\x00",  # GSM no error
				   message_state => "\x01",  # Delivery Pending (DPF)
				   receipted_message_id => "abcdef",
				   ) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 5)
		&& ($pdu->{status} == 0)
		&& ($pdu->{service_type} eq 'foosv')
		&& ($pdu->{source_addr_ton} == 0x11)
		&& ($pdu->{source_addr_npi} == 0x22)
		&& ($pdu->{source_addr} eq '8199998888')
		&& ($pdu->{dest_addr_ton} == 0x33)
		&& ($pdu->{dest_addr_npi} == 0x44)
		&& ($pdu->{destination_addr} eq '19258887777')
		&& ($pdu->{esm_class} == 0x55)
		&& ($pdu->{protocol_id} == 0x66)
		&& ($pdu->{priority_flag} == 0x77)
		&& ($pdu->{schedule_delivery_time} eq '0123456789abcdef')
		&& ($pdu->{validity_period} eq 'FEDCBA9876543210')
		&& ($pdu->{registered_delivery} == 0x88)
		&& ($pdu->{replace_if_present_flag} == 0x99)
		&& ($pdu->{data_coding} == 0xaa)
		&& ($pdu->{sm_default_msg_id} == 0xbb)
		&& ($pdu->{short_message} eq '')
		&& ($pdu->{user_message_reference} eq 'user msg ref')
		&& ($pdu->{source_port} eq '9999')
		&& ($pdu->{destination_port} eq '8888')
		&& ($pdu->{sar_msg_ref_num} eq "\xaa\xbb")
		&& ($pdu->{sar_total_segments} eq "\x01")
		&& ($pdu->{sar_segment_seqnum} eq "\x01")     # 1 out of 1
		&& ($pdu->{user_response_code} eq "\xaa")
		&& ($pdu->{privacy_indicator} eq "\x03")  # secret
		&& ($pdu->{payload_type} eq "\x01")  # WCMP
		&& ($pdu->{message_payload} eq ('A' x 1024))
		&& ($pdu->{callback_num} eq "\x01\x05\x061234")  # ascii, TON=alphanum, NPI=Land mobile
		&& ($pdu->{source_subaddress} eq "\xa01234567890123456789012")
		&& ($pdu->{dest_subaddress} eq "\xa02101234567890123456789")
		&& ($pdu->{language_indicator} eq "\x05") # Portuguese
		&& ($pdu->{its_session_info} eq "\x33\x01") # Session 0x33, dialogue unit 0, end of session
		&& ($pdu->{network_error_code} eq "\x03\x00\x00")  # GSM no error
		&& ($pdu->{message_state} eq "\x01")  # Delivery Pending (DPF)
		&& ($pdu->{receipted_message_id} eq "abcdef")
		) {
		print "ok 25  (seq=$seq)\n";
	    } else {
		fail_pdu(25, $pdu);
	    }
	    
	    $seq = $cli->deliver_sm_resp(seq=>$seq,
					 message_id=>'1234567') or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80000005)
		&& ($pdu->{status} == 0)
		&& ($pdu->{message_id} eq '1234567')
		) {
		print "ok 26  (seq=$seq)\n";
	    } else {
		fail_pdu(26, $pdu);
	    }

	    ### Data SM
	    
	    $seq = $cli->data_sm(destination_addr => '19258887777') or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x103)
		&& ($pdu->{status} == 0)
		&& ($pdu->{service_type} eq '')
		&& ($pdu->{source_addr_ton} == 0)
		&& ($pdu->{source_addr_npi} == 0)
		&& ($pdu->{source_addr} eq '')
		&& ($pdu->{dest_addr_ton} == 0)
		&& ($pdu->{dest_addr_npi} == 0)
		&& ($pdu->{destination_addr} eq '19258887777')
		&& ($pdu->{esm_class} == 0)
		&& ($pdu->{registered_delivery} == 0)
		&& ($pdu->{data_coding} == 0)
		) {
		print "ok 27  (seq=$seq)\n";
	    } else {
		fail_pdu(27, $pdu);
	    }
	    
	    $seq = $serv->data_sm_resp(seq=>$seq,
				       message_id=>'') or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80000103)
		&& ($pdu->{status} == 0)
		&& ($pdu->{message_id} eq '')
		) {
		print "ok 28  (seq=$seq)\n";
	    } else {
		fail_pdu(28, $pdu);
	    }
	    
	    $seq = $cli->data_sm(service_type => 'foosv',
				   source_addr_ton => 0x11,
				   source_addr_npi => 0x22,
				   source_addr => '8199998888',
				   dest_addr_ton => 0x33,
				   dest_addr_npi => 0x44,
				   destination_addr => '19258887777',
				   esm_class => 0x55,
				   registered_delivery => 0x88,
				   data_coding => 0xaa,
				   ) or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x103)
		&& ($pdu->{status} == 0)
		&& ($pdu->{service_type} eq 'foosv')
		&& ($pdu->{source_addr_ton} == 0x11)
		&& ($pdu->{source_addr_npi} == 0x22)
		&& ($pdu->{source_addr} eq '8199998888')
		&& ($pdu->{dest_addr_ton} == 0x33)
		&& ($pdu->{dest_addr_npi} == 0x44)
		&& ($pdu->{destination_addr} eq '19258887777')
		&& ($pdu->{esm_class} == 0x55)
		&& ($pdu->{registered_delivery} == 0x88)
		&& ($pdu->{data_coding} == 0xaa)
		) {
		print "ok 29  (seq=$seq)\n";
	    } else {
		fail_pdu(29, $pdu);
	    }
	    
	    $seq = $serv->data_sm_resp(seq=>$seq,
				       message_id=>'1234567') or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80000103)
		&& ($pdu->{status} == 0)
		&& ($pdu->{message_id} eq '1234567')
		) {
		print "ok 30  (seq=$seq)\n";
	    } else {
		fail_pdu(30, $pdu);
	    }

	    $seq = $cli->data_sm(service_type => 'foosv',
				 source_addr_ton => 0x11,
				 source_addr_npi => 0x22,
				 source_addr => '8199998888',
				 dest_addr_ton => 0x33,
				 dest_addr_npi => 0x44,
				 destination_addr => '19258887777',
				 esm_class => 0x55,
				 registered_delivery => 0x88,
				 data_coding => 0xaa,
				 source_port => '9999',
				 source_addr_subunit => "\xee",
				 source_network_type => "\x01",  # GSM
				 source_bearer_type => "\x08",   # cellcast
				 source_telematics_id => "\x00",
				 destination_port => '8888',
				 dest_addr_subunit => "\xdd",
				 dest_network_type => "\x01",  # GSM
				 dest_bearer_type => "\x08",   # cellcast
				 dest_telematics_id => "\x00",
				 sar_msg_ref_num => "\xaa\xbb",
				 sar_total_segments => "\x01",
				 sar_segment_seqnum => "\x01",     # 1 out of 1
				 more_messages_to_send => "\x01",  # Yes
				 qos_time_to_live => "\x3c", # retain msg for 60 seconds
				 payload_type => "\x01",  # WCMP
				 message_payload => ('A' x 1024),
				 set_dpf => "\x00",  # Don't set delivery pending flag
				 receipted_message_id => "abcdef",
				 message_state => "\x01",  # Delivery Pending (DPF)
				 network_error_code => "\x03\x00\x00",  # GSM no error
				 user_message_reference => 'user msg ref',
				 privacy_indicator => "\x03",  # secret
				 callback_num => "\x01\x05\x061234",  # ascii, TON=alphanum, NPI=Land mobile
				 callback_num_pres_ind => "\x05",
				 callback_num_atag => "\x03Greg",  # Latin1 Greg
				 source_subaddress => "\xa01234567890123456789012",
				 dest_subaddress => "\xa02101234567890123456789",
				 user_response_code => "\xaa",
				 display_time => "\x02", # Invoke
				 sms_signal => "\x11\x22",
				 ms_validity => "\x03",  # For your eyes only
				 ms_msg_wait_facilities => "\x82",  # email waiting icon
				 number_of_messages => "\x63",
				 alert_on_message_delivery => "",  # Value has to be empty
				 language_indicator => "\x05", # Portuguese
				 its_reply_type => "\x03",     # Password
				 its_session_info => "\x33\x01", # Session 0x33, dialogue unit 0, end of session
				 ) or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x103)
		&& ($pdu->{status} == 0)
		&& ($pdu->{service_type} eq 'foosv')
		&& ($pdu->{source_addr_ton} == 0x11)
		&& ($pdu->{source_addr_npi} == 0x22)
		&& ($pdu->{source_addr} eq '8199998888')
		&& ($pdu->{dest_addr_ton} == 0x33)
		&& ($pdu->{dest_addr_npi} == 0x44)
		&& ($pdu->{destination_addr} eq '19258887777')
		&& ($pdu->{esm_class} == 0x55)
		&& ($pdu->{registered_delivery} == 0x88)
		&& ($pdu->{data_coding} == 0xaa)
		&& ($pdu->{source_port} eq '9999')
		&& ($pdu->{source_addr_subunit} eq "\xee")
		&& ($pdu->{source_network_type} eq "\x01")  # GSM
		&& ($pdu->{source_bearer_type} eq "\x08")   # cellcast
		&& ($pdu->{source_telematics_id} eq "\x00")
		&& ($pdu->{destination_port} eq '8888')
		&& ($pdu->{dest_addr_subunit} eq "\xdd")
		&& ($pdu->{dest_network_type} eq "\x01")  # GSM
		&& ($pdu->{dest_bearer_type} eq "\x08")   # cellcast
		&& ($pdu->{dest_telematics_id} eq "\x00")
		&& ($pdu->{sar_msg_ref_num} eq "\xaa\xbb")
		&& ($pdu->{sar_total_segments} eq "\x01")
		&& ($pdu->{sar_segment_seqnum} eq "\x01")     # 1 out of 1
		&& ($pdu->{more_messages_to_send} eq "\x01")  # Yes
		&& ($pdu->{payload_type} eq "\x01")  # WCMP
		&& ($pdu->{message_payload} eq ('A' x 1024))
		&& ($pdu->{set_dpf} eq "\x00")
		&& ($pdu->{receipted_message_id} eq "abcdef")
		&& ($pdu->{message_state} eq "\x01")  # Delivery Pending (DPF)
		&& ($pdu->{network_error_code} eq "\x03\x00\x00")  # GSM no error
		&& ($pdu->{user_message_reference} eq 'user msg ref')
		&& ($pdu->{privacy_indicator} eq "\x03")  # secret
		&& ($pdu->{callback_num} eq "\x01\x05\x061234")  # ascii, TON=alphanum, NPI=Land mobile
		&& ($pdu->{callback_num_pres_ind} eq "\x05")
		&& ($pdu->{callback_num_atag} eq "\x03Greg")  # Latin1 Greg
		&& ($pdu->{source_subaddress} eq "\xa01234567890123456789012")
		&& ($pdu->{dest_subaddress} eq "\xa02101234567890123456789")
		&& ($pdu->{user_response_code} eq "\xaa")
		&& ($pdu->{display_time} eq "\x02") # Invoke
		&& ($pdu->{sms_signal} eq "\x11\x22")
		&& ($pdu->{ms_validity} eq "\x03")  # For your eyes only
		&& ($pdu->{ms_msg_wait_facilities} eq "\x82")  # email waiting icon
		&& ($pdu->{number_of_messages} eq "\x63")
		&& ($pdu->{alert_on_message_delivery} eq "")  # Value has to be empty
		&& ($pdu->{language_indicator} eq "\x05") # Portuguese
		&& ($pdu->{its_reply_type} eq "\x03")     # Password
		&& ($pdu->{its_session_info} eq "\x33\x01") # Session 0x33, dialogue unit 0, end of session
		) {
		print "ok 31  (seq=$seq)\n";
	    } else {
		fail_pdu(31, $pdu);
	    }
	    
	    $seq = $serv->data_sm_resp(seq=>$seq,
				       message_id=>'1234567',
				       delivery_failure_reason => "\x03", # Temporary network error
				       network_error_code => "\x03\x00\x00",  # GSM no error
				       additional_status_info_text => "Hello mom",
				       dpf_result => "\x01",  # DPF set
				       ) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80000103)
		&& ($pdu->{status} == 0)
		&& ($pdu->{message_id} eq '1234567')
		&& ($pdu->{delivery_failure_reason} eq "\x03") # Temporary network error
		&& ($pdu->{network_error_code} eq "\x03\x00\x00")  # GSM no error
		&& ($pdu->{additional_status_info_text} eq "Hello mom")
		&& ($pdu->{dpf_result} eq "\x01")  # DPF set
		) {
		print "ok 32  (seq=$seq)\n";
	    } else {
		fail_pdu(32, $pdu);
	    }

	    ### Submit Multi
	    
	    $seq = $cli->submit_multi(dest_flag => [ Net::SMPP::MULTIDESTFLAG_SME_Address, Net::SMPP::MULTIDESTFLAG_dist_list ],
				      destination_addr => [ '19258887777', 'distlist'],
				      ) or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x21)
		&& ($pdu->{status} == 0)
		&& ($pdu->{service_type} eq '')
		&& ($pdu->{source_addr_ton} == 0)
		&& ($pdu->{source_addr_npi} == 0)
		&& ($pdu->{source_addr} eq '')
		&& ($pdu->{number_of_dests} == 2)
		&& ($pdu->{dest_flag}[0] == 1)
		&& ($pdu->{dest_addr_ton}[0] == 0)
		&& ($pdu->{dest_addr_npi}[0] == 0)
		&& ($pdu->{destination_addr}[0] eq '19258887777')
		&& ($pdu->{dest_flag}[1] == 2)
		&& ($pdu->{dest_addr_ton}[1] == 0)
		&& ($pdu->{dest_addr_npi}[1] == 0)
		&& ($pdu->{destination_addr}[1] eq 'distlist')
		&& ($pdu->{esm_class} == 0)
		&& ($pdu->{protocol_id} == 0)
		&& ($pdu->{priority_flag} == 0)
		&& ($pdu->{schedule_delivery_time} eq '')
		&& ($pdu->{validity_period} eq '')
		&& ($pdu->{registered_delivery} == 0)
		&& ($pdu->{replace_if_present_flag} == 0)
		&& ($pdu->{data_coding} == 0)
		&& ($pdu->{sm_default_msg_id} == 0)
		&& ($pdu->{short_message} eq '')
		) {
		print "ok 33  (seq=$seq)\n";
	    } else {
		fail_pdu(33, $pdu);
	    }
	    
	    $seq = $serv->submit_multi_resp(seq=>$seq,
					    message_id=>'',
					    destination_addr  => [ '19258887777', 'distlist'],
					    error_status_code => [ 1,2 ],
					    ) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80000021)
		&& ($pdu->{status} == 0)
		&& ($pdu->{message_id} eq '')
		&& ($pdu->{no_unsuccess} == 2)
		&& ($pdu->{error_status_code}[0] == 1)
		&& ($pdu->{dest_addr_ton}[0] == 0)
		&& ($pdu->{dest_addr_npi}[0] == 0)
		&& ($pdu->{destination_addr}[0] eq '19258887777')
		&& ($pdu->{error_status_code}[1] == 2)
		&& ($pdu->{dest_addr_ton}[1] == 0)
		&& ($pdu->{dest_addr_npi}[1] == 0)
		&& ($pdu->{destination_addr}[1] eq 'distlist')
		) {
		print "ok 34  (seq=$seq)\n";
	    } else {
		fail_pdu(34, $pdu);
	    }
	    
	    $seq = $cli->submit_multi(service_type => 'foosv',
				   source_addr_ton => 0x11,
				   source_addr_npi => 0x22,
				   source_addr => '8199998888',
				      dest_flag => [ Net::SMPP::MULTIDESTFLAG_SME_Address, Net::SMPP::MULTIDESTFLAG_dist_list ],
				      destination_addr => [ '19258887777', 'distlist'],
				      dest_addr_ton => [ 0x33 ],
				      dest_addr_npi => [ 0x44 ],
				   esm_class => 0x55,
				   protocol_id => 0x66,
				   priority_flag => 0x77,
				   schedule_delivery_time => '0123456789abcdef',
				   validity_period => 'FEDCBA9876543210',
				   registered_delivery => 0x88,
				   replace_if_present_flag => 0x99,
				   data_coding => 0xaa,
				   sm_default_msg_id => 0xbb,
				   short_message => 'foobar',
				   ) or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x21)
		&& ($pdu->{status} == 0)
		&& ($pdu->{service_type} eq 'foosv')
		&& ($pdu->{source_addr_ton} == 0x11)
		&& ($pdu->{source_addr_npi} == 0x22)
		&& ($pdu->{source_addr} eq '8199998888')
		&& ($pdu->{number_of_dests} == 2)
		&& ($pdu->{dest_flag}[0] == 1)
		&& ($pdu->{dest_addr_ton}[0] == 0x33)
		&& ($pdu->{dest_addr_npi}[0] == 0x44)
		&& ($pdu->{destination_addr}[0] eq '19258887777')
		&& ($pdu->{dest_flag}[1] == 2)
		&& ($pdu->{destination_addr}[1] eq 'distlist')
		&& ($pdu->{esm_class} == 0x55)
		&& ($pdu->{protocol_id} == 0x66)
		&& ($pdu->{priority_flag} == 0x77)
		&& ($pdu->{schedule_delivery_time} eq '0123456789abcdef')
		&& ($pdu->{validity_period} eq 'FEDCBA9876543210')
		&& ($pdu->{registered_delivery} == 0x88)
		&& ($pdu->{replace_if_present_flag} == 0x99)
		&& ($pdu->{data_coding} == 0xaa)
		&& ($pdu->{sm_default_msg_id} == 0xbb)
		&& ($pdu->{short_message} eq 'foobar')
		) {
		print "ok 35  (seq=$seq)\n";
	    } else {
		fail_pdu(35, $pdu);
	    }
	    
	    $seq = $serv->submit_multi_resp(seq=>$seq,
					    message_id=>'1234567',
					    dest_addr_ton => [ 0x33 ],
					    dest_addr_npi => [ 0x44 ],
					    destination_addr  => [ '19258887777', 'distlist'],
					    error_status_code => [ 1, 2 ],
					    ) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80000021)
		&& ($pdu->{status} == 0)
		&& ($pdu->{message_id} eq '1234567')
		&& ($pdu->{no_unsuccess} == 2)
		&& ($pdu->{error_status_code}[0] == 1)
		&& ($pdu->{dest_addr_ton}[0] == 0x33)
		&& ($pdu->{dest_addr_npi}[0] == 0x44)
		&& ($pdu->{destination_addr}[0] eq '19258887777')
		&& ($pdu->{error_status_code}[1] == 2)
		&& ($pdu->{destination_addr}[1] eq 'distlist')
		) {
		print "ok 36  (seq=$seq)\n";
	    } else {
		fail_pdu(36, $pdu);
	    }

	    $seq = $cli->submit_multi(service_type => 'foosv',
				   source_addr_ton => 0x11,
				   source_addr_npi => 0x22,
				   source_addr => '8199998888',
				      dest_flag => [ Net::SMPP::MULTIDESTFLAG_SME_Address, Net::SMPP::MULTIDESTFLAG_dist_list ],
				      destination_addr => [ '19258887777', 'distlist'],
				      dest_addr_ton => [ 0x33 ],
				      dest_addr_npi => [ 0x44 ],
				   esm_class => 0x55,
				   protocol_id => 0x66,
				   priority_flag => 0x77,
				   schedule_delivery_time => '0123456789abcdef',
				   validity_period => 'FEDCBA9876543210',
				   registered_delivery => 0x88,
				   replace_if_present_flag => 0x99,
				   data_coding => 0xaa,
				   sm_default_msg_id => 0xbb,
				      user_message_reference => 'user msg ref',
				      source_port => '9999',
				      source_addr_subunit => "\xee",
				      destination_port => '8888',
				      dest_addr_subunit => "\xdd",
				      sar_msg_ref_num => "\xaa\xbb",
				      sar_total_segments => "\x01",
				      sar_segment_seqnum => "\x01",     # 1 out of 1
				      payload_type => "\x01",  # WCMP
				      message_payload => ('A' x 1024),
				      privacy_indicator => "\x03",  # secret
				      callback_num => "\x01\x05\x061234",  # ascii, TON=alphanum, NPI=Land mobile
				      callback_num_pres_ind => "\x05",
				      callback_num_atag => "\x03Greg",  # Latin1 Greg
				      source_subaddress => "\xa01234567890123456789012",
				      dest_subaddress => "\xa02101234567890123456789",
				      display_time => "\x02", # Invoke
				      sms_signal => "\x11\x22",
				      ms_validity => "\x03",  # For your eyes only
				      ms_msg_wait_facilities => "\x82",  # email waiting icon
				      alert_on_message_delivery => "",  # Value has to be empty
				      language_indicator => "\x05", # Portuguese
				   ) or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x21)
		&& ($pdu->{status} == 0)
		&& ($pdu->{service_type} eq 'foosv')
		&& ($pdu->{source_addr_ton} == 0x11)
		&& ($pdu->{source_addr_npi} == 0x22)
		&& ($pdu->{source_addr} eq '8199998888')
		&& ($pdu->{number_of_dests} == 2)
		&& ($pdu->{dest_flag}[0] == 1)
		&& ($pdu->{dest_addr_ton}[0] == 0x33)
		&& ($pdu->{dest_addr_npi}[0] == 0x44)
		&& ($pdu->{destination_addr}[0] eq '19258887777')
		&& ($pdu->{dest_flag}[1] == 2)
		&& ($pdu->{destination_addr}[1] eq 'distlist')
		&& ($pdu->{esm_class} == 0x55)
		&& ($pdu->{protocol_id} == 0x66)
		&& ($pdu->{priority_flag} == 0x77)
		&& ($pdu->{schedule_delivery_time} eq '0123456789abcdef')
		&& ($pdu->{validity_period} eq 'FEDCBA9876543210')
		&& ($pdu->{registered_delivery} == 0x88)
		&& ($pdu->{replace_if_present_flag} == 0x99)
		&& ($pdu->{data_coding} == 0xaa)
		&& ($pdu->{sm_default_msg_id} == 0xbb)
		&& ($pdu->{short_message} eq '')
		&& ($pdu->{user_message_reference} eq 'user msg ref')
		&& ($pdu->{source_port} eq '9999')
		&& ($pdu->{source_addr_subunit} eq "\xee")
		&& ($pdu->{destination_port} eq '8888')
		&& ($pdu->{dest_addr_subunit} eq "\xdd")
		&& ($pdu->{sar_msg_ref_num} eq "\xaa\xbb")
		&& ($pdu->{sar_total_segments} eq "\x01")
		&& ($pdu->{sar_segment_seqnum} eq "\x01")     # 1 out of 1
		&& ($pdu->{payload_type} eq "\x01")  # WCMP
		&& ($pdu->{message_payload} eq ('A' x 1024))
		&& ($pdu->{privacy_indicator} eq "\x03")  # secret
		&& ($pdu->{callback_num} eq "\x01\x05\x061234")  # ascii, TON=alphanum, NPI=Land mobile
		&& ($pdu->{callback_num_pres_ind} eq "\x05")
		&& ($pdu->{callback_num_atag} eq "\x03Greg")  # Latin1 Greg
		&& ($pdu->{source_subaddress} eq "\xa01234567890123456789012")
		&& ($pdu->{dest_subaddress} eq "\xa02101234567890123456789")
		&& ($pdu->{display_time} eq "\x02") # Invoke
		&& ($pdu->{sms_signal} eq "\x11\x22")
		&& ($pdu->{ms_validity} eq "\x03")  # For your eyes only
		&& ($pdu->{ms_msg_wait_facilities} eq "\x82")  # email waiting icon
		&& ($pdu->{alert_on_message_delivery} eq "")  # Value has to be empty
		&& ($pdu->{language_indicator} eq "\x05") # Portuguese
		) {
		print "ok 37  (seq=$seq)\n";
	    } else {
		fail_pdu(37, $pdu);
	    }
	    
	    $seq = $serv->submit_multi_resp(seq=>$seq,
					    message_id=>'1234567',
					    dest_addr_ton => [ 0x33 ],
					    dest_addr_npi => [ 0x44 ],
					    destination_addr  => [ '19258887777', 'distlist'],
					    error_status_code => [ 1, 2 ],
					    ) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80000021)
		&& ($pdu->{status} == 0)
		&& ($pdu->{message_id} eq '1234567')
		&& ($pdu->{no_unsuccess} == 2)
		&& ($pdu->{error_status_code}[0] == 1)
		&& ($pdu->{dest_addr_ton}[0] == 0x33)
		&& ($pdu->{dest_addr_npi}[0] == 0x44)
		&& ($pdu->{destination_addr}[0] eq '19258887777')
		&& ($pdu->{error_status_code}[1] == 2)
		&& ($pdu->{destination_addr}[1] eq 'distlist')
		) {
		print "ok 38  (seq=$seq)\n";
	    } else {
		fail_pdu(38, $pdu);
	    }

	    ### Query SM

	    $seq = $cli->query_sm(message_id => '') or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 3)
		&& ($pdu->{status} == 0)
		&& ($pdu->{message_id} eq '')
		&& ($pdu->{source_addr_ton} == 0)
		&& ($pdu->{source_addr_npi} == 0)
		&& ($pdu->{source_addr} eq '')
		) {
		print "ok 39  (seq=$seq)\n";
	    } else {
		fail_pdu(39, $pdu);
	    }
	    
	    $seq = $serv->query_sm_resp(seq => $seq,
					message_id => '',
					message_state => Net::SMPP::MSGSTATE_accepted) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80000003)
		&& ($pdu->{status} == 0)
		&& ($pdu->{message_id} eq '')
		&& ($pdu->{message_state} == 6)
		&& ($pdu->{final_date} eq '')
		&& ($pdu->{error_code} == 0)
		) {
		print "ok 40  (seq=$seq)\n";
	    } else {
		fail_pdu(40, $pdu);
	    }

	    $seq = $cli->query_sm(message_id => 'testi',
				  source_addr_ton => 0x22,
				  source_addr_npi => 0x33,
				  source_addr => '19257778888'
				  ) or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 3)
		&& ($pdu->{status} == 0)
		&& ($pdu->{message_id} eq 'testi')
		&& ($pdu->{source_addr_ton} == 0x22)
		&& ($pdu->{source_addr_npi} == 0x33)
		&& ($pdu->{source_addr} eq '19257778888')
		) {
		print "ok 41  (seq=$seq)\n";
	    } else {
		fail_pdu(41, $pdu);
	    }
	    
	    $seq = $serv->query_sm_resp(seq=>$seq,
					message_id => 'defghi',
					message_state => Net::SMPP::MSGSTATE_accepted,
					final_date => '0123456789abcdef',
					error_code => 0x11,
					) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80000003)
		&& ($pdu->{message_id} eq 'defghi')
		&& ($pdu->{message_state} == 6)
		&& ($pdu->{final_date} eq '0123456789abcdef')
		&& ($pdu->{error_code} == 0x11)
		) {
		print "ok 42  (seq=$seq)\n";
	    } else {
		fail_pdu(42, $pdu);
	    }

	    ### Cancel SM

	    $seq = $cli->cancel_sm() or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 8)
		&& ($pdu->{status} == 0)
		&& ($pdu->{service_type} eq '')
		&& ($pdu->{message_id} eq '')
		&& ($pdu->{source_addr_ton} == 0)
		&& ($pdu->{source_addr_npi} == 0)
		&& ($pdu->{source_addr} eq '')
		&& ($pdu->{dest_addr_ton} == 0)
		&& ($pdu->{dest_addr_npi} == 0)
		&& ($pdu->{destination_addr} eq '')
		) {
		print "ok 43  (seq=$seq)\n";
	    } else {
		fail_pdu(43, $pdu);
	    }
	    
	    $seq = $serv->cancel_sm_resp(seq => $seq) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80000008)
		&& ($pdu->{status} == 0)
		) {
		print "ok 44  (seq=$seq)\n";
	    } else {
		fail_pdu(44, $pdu);
	    }

	    $seq = $cli->cancel_sm(service_type => 'servt',
				   message_id => 'testi',
				   source_addr_ton => 0x22,
				   source_addr_npi => 0x33,
				   source_addr => '19257778888',
				   dest_addr_ton => 0x44,
				   dest_addr_npi => 0x55,
				   destination_addr => '19257776666',
				   ) or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 8)
		&& ($pdu->{status} == 0)
		&& ($pdu->{service_type} eq 'servt')
		&& ($pdu->{message_id} eq 'testi')
		&& ($pdu->{source_addr_ton} == 0x22)
		&& ($pdu->{source_addr_npi} == 0x33)
		&& ($pdu->{source_addr} eq '19257778888')
		&& ($pdu->{dest_addr_ton} == 0x44)
		&& ($pdu->{dest_addr_npi} == 0x55)
		&& ($pdu->{destination_addr} eq '19257776666')
		) {
		print "ok 45  (seq=$seq)\n";
	    } else {
		fail_pdu(45, $pdu);
	    }
	    
	    $seq = $serv->cancel_sm_resp(seq=>$seq) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80000008)
		&& ($pdu->{status} == 0)
		) {
		print "ok 46  (seq=$seq)\n";
	    } else {
		fail_pdu(46, $pdu);
	    }

	    ### Replace SM

	    $seq = $cli->replace_sm(message_id => '') or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 7)
		&& ($pdu->{status} == 0)
		&& ($pdu->{message_id} eq '')
		&& ($pdu->{source_addr_ton} == 0)
		&& ($pdu->{source_addr_npi} == 0)
		&& ($pdu->{source_addr} eq '')
		&& ($pdu->{schedule_delivery_time} eq '')
		&& ($pdu->{validity_period} eq '')
		&& ($pdu->{registered_delivery} == 0)
		&& ($pdu->{sm_default_msg_id} == 0)
		&& ($pdu->{short_message} eq '')
		) {
		print "ok 47  (seq=$seq)\n";
	    } else {
		fail_pdu(47, $pdu);
	    }
	    
	    $seq = $serv->replace_sm_resp(seq => $seq) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80000007)
		&& ($pdu->{status} == 0)
		) {
		print "ok 48  (seq=$seq)\n";
	    } else {
		fail_pdu(48, $pdu);
	    }

	    $seq = $cli->replace_sm(message_id => 'testi',
				    source_addr_ton => 0x22,
				    source_addr_npi => 0x33,
				    source_addr => '19257778888',
				    schedule_delivery_time => '0123456789abcdef',
				    validity_period => 'ABCDEF0987654321',
				    registered_delivery => 0x44,
				    sm_default_msg_id => 0x55,
				    short_message => 'foobar',
				    ) or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 7)
		&& ($pdu->{status} == 0)
		&& ($pdu->{message_id} eq 'testi')
		&& ($pdu->{source_addr_ton} == 0x22)
		&& ($pdu->{source_addr_npi} == 0x33)
		&& ($pdu->{source_addr} eq '19257778888')
		&& ($pdu->{schedule_delivery_time} eq '0123456789abcdef')
		&& ($pdu->{validity_period} eq 'ABCDEF0987654321')
		&& ($pdu->{registered_delivery} == 0x44)
		&& ($pdu->{sm_default_msg_id} == 0x55)
		&& ($pdu->{short_message} eq 'foobar')
		) {
		print "ok 49  (seq=$seq)\n";
	    } else {
		fail_pdu(49, $pdu);
	    }
	    
	    $seq = $serv->replace_sm_resp(seq=>$seq) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80000007)
		&& ($pdu->{status} == 0)
		) {
		print "ok 50  (seq=$seq)\n";
	    } else {
		fail_pdu(50, $pdu);
	    }

	    ### Enquire Link

	    $seq = $cli->enquire_link() or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x15)
		&& ($pdu->{status} == 0)
		) {
		print "ok 51  (seq=$seq)\n";
	    } else {
		fail_pdu(51, $pdu);
	    }
	    
	    $seq = $serv->enquire_link_resp(seq => $seq) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80000015)
		&& ($pdu->{status} == 0)
		) {
		print "ok 52  (seq=$seq)\n";
	    } else {
		fail_pdu(52, $pdu);
	    }

	    ### Alert Notification

	    $seq = $serv->alert_notification(esme_addr => '') or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x102)
		&& ($pdu->{status} == 0)
		&& ($pdu->{source_addr_ton} == 0)
		&& ($pdu->{source_addr_npi} == 0)
		&& ($pdu->{source_addr} eq '')
		&& ($pdu->{esme_addr_ton} == 0)
		&& ($pdu->{esme_addr_npi} == 0)
		&& ($pdu->{esme_addr} eq '')
		) {
		print "ok 53  (seq=$seq)\n";
	    } else {
		fail_pdu(53, $pdu);
	    }

	    $seq = $serv->alert_notification(source_addr_ton => 0x11,
					     source_addr_npi => 0x22,
					     source_addr => '19258889999',
					     esme_addr_ton => 0x33,
					     esme_addr_npi => 0x44,
					     esme_addr => '19258887777',
					     ) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x102)
		&& ($pdu->{status} == 0)
		&& ($pdu->{source_addr_ton} == 0x11)
		&& ($pdu->{source_addr_npi} == 0x22)
		&& ($pdu->{source_addr} eq '19258889999')
		&& ($pdu->{esme_addr_ton} == 0x33)
		&& ($pdu->{esme_addr_npi} == 0x44)
		&& ($pdu->{esme_addr} eq '19258887777')
		) {
		print "ok 54  (seq=$seq)\n";
	    } else {
		fail_pdu(54, $pdu);
	    }

	    $seq = $serv->alert_notification(source_addr_ton => 0x11,
					     source_addr_npi => 0x22,
					     source_addr => '19258889999',
					     esme_addr_ton => 0x33,
					     esme_addr_npi => 0x44,
					     esme_addr => '19258887777',
					     ms_availability_status => "\x01",  # Denied
					     ) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x102)
		&& ($pdu->{status} == 0)
		&& ($pdu->{source_addr_ton} == 0x11)
		&& ($pdu->{source_addr_npi} == 0x22)
		&& ($pdu->{source_addr} eq '19258889999')
		&& ($pdu->{esme_addr_ton} == 0x33)
		&& ($pdu->{esme_addr_npi} == 0x44)
		&& ($pdu->{esme_addr} eq '19258887777')
		&& ($pdu->{ms_availability_status} eq "\x01")
		) {
		print "ok 55  (seq=$seq)\n";
	    } else {
		fail_pdu(55, $pdu);
	    }

	    ### end of v34 tests

	    undef $cli;
	} else {
	    print "fail 4\n\t*** Could not accept connection\n";
	    print "\t*** Skipping tests 5..55";
	    $fail++;
	}
	undef $serv;
    } else {
	print "fail 3\n\t*** Could not contact test server on localhost:2251\n";
	print "\t*** Skipping tests 4..55";
	$fail++;
    }
    undef $listen;
} else {
    print "fail 2\n\t*** Failed to create test server on port 2251.\n";
    print "\t*** Check if some other service is already using this port.\n";
    print "\t*** Skipping tests 3..55\n";
    $fail++;
}

###
### Tests for v4.0
###

$listen = Net::SMPP->new_listen('localhost',
                              port => 2251,
                              smpp_version => 0x40,
			      async=>1,
                              );
if ($listen) {
    print  "ok 56\n";

    $cli = Net::SMPP->new_connect('localhost',
				  port => 2251,
				  smpp_version => 0x40,
				  async=>1,
				  );
    if ($cli) {
	print "ok 57\n";

	$serv = $listen->accept;
	if ($serv) {
	    print "ok 58\n";
	    
	    ### Check sending every type of PDU. Note that this is
	    ### not necessarily a meaningful dialog - it only
	    ### tries to test packet assembly and disassembly.
	    ### In general, constants are specified explicitly as
	    ### numbers to ensure that errors in the constant
	    ### definitions themselves are caught.
	    ###
	    ### Every PDU is first tested in its default form with
	    ### only mandatory arguments supplied and letting everything
	    ### else take default values. Next PDU is tested with
	    ### all normal arguments and finally with all optional arguments.
	    
	    $seq = $cli->bind_transmitter(interface_type=>0) or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x10002)
		&& ($pdu->{status} == 0)
		&& ($pdu->{system_id} eq '')
		&& ($pdu->{password} eq '')
		&& ($pdu->{system_type} eq '')
		&& ($pdu->{interface_version} == 0)
		&& ($pdu->{addr_ton} == 0)
		&& ($pdu->{addr_npi} == 0)
		&& ($pdu->{address_range} eq '')
		&& ($pdu->{facilities_mask} == 0)
		) {
		print "ok 59  (seq=$seq)\n";
	    } else {
		fail_pdu(59, $pdu);
	    }
	    
	    $seq = $serv->bind_transmitter_resp(seq=>$seq) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80010002)
		&& ($pdu->{status} == 0)
		&& ($pdu->{system_id} eq '')
		&& ($pdu->{facilities_mask} == 0)
		) {
		print "ok 60  (seq=$seq)\n";
	    } else {
		fail_pdu(60, $pdu);
	    }

	    $seq = $cli->bind_transmitter(system_id => 'testi',
					  password  => 'salainen',
					  system_type => 'penkki',
					  interface_type => 0x11,
					  addr_ton => 0x22,
					  addr_npi => 0x33,
					  address_range => '^\+1',
					  facilities_mask => 0x12345678,
					  ) or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x10002)
		&& ($pdu->{status} == 0)
		&& ($pdu->{system_id} eq 'testi')
		&& ($pdu->{password} eq 'salainen')
		&& ($pdu->{system_type} eq 'penkki')
		&& ($pdu->{interface_version} == 0x11)
		&& ($pdu->{addr_ton} == 0x22)
		&& ($pdu->{addr_npi} == 0x33)
		&& ($pdu->{address_range} eq '^\+1')
		&& ($pdu->{facilities_mask} == 0x12345678)
		) {
		print "ok 61  (seq=$seq)\n";
	    } else {
		fail_pdu(61, $pdu);
	    }
	    
	    $seq = $serv->bind_transmitter_resp(seq=>$seq,
						status=>0x44,
						system_id=>'tuoli',
						facilities_mask => 0x87654321,
						) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80010002)
		&& ($pdu->{status} == 0x44)
		&& ($pdu->{system_id} eq 'tuoli')
		&& ($pdu->{facilities_mask} == 0x87654321)
		) {
		print "ok 62  (seq=$seq)\n";
	    } else {
		fail_pdu(62, $pdu);
	    }
	    
	    ### Outbind

	    $seq = $serv->outbind() or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x1000b)
		&& ($pdu->{status} == 0)
		&& ($pdu->{password} eq '')
		) {
		print "ok 63  (seq=$seq)\n";
	    } else {
		fail_pdu(63, $pdu);
	    }
	    
	    $seq = $serv->outbind(password => 'sala') or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x1000b)
		&& ($pdu->{status} == 0)
		&& ($pdu->{password} eq 'sala')
		) {
		print "ok 64  (seq=$seq)\n";
	    } else {
		fail_pdu(64, $pdu);
	    }

	    ### Unbind

	    $seq = $cli->unbind() or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x10006)
		&& ($pdu->{status} == 0)
		) {
		print "ok 65  (seq=$seq)\n";
	    } else {
		fail_pdu(65, $pdu);
	    }

	    $seq = $serv->unbind_resp(seq=>$seq) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80010006)
		&& ($pdu->{status} == 0)
		) {
		print "ok 66  (seq=$seq)\n";
	    } else {
		fail_pdu(66, $pdu);
	    }
	    
	    ### Generic NACK

	    $seq = $cli->generic_nack(seq=>$seq) or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80010000)
		&& ($pdu->{status} == 0)
		) {
		print "ok 67  (seq=$seq)\n";
	    } else {
		fail_pdu(67, $pdu);
	    }
	    
	    ### Deliver SM
	    
	    $seq = $serv->deliver_sm(destination_addr => '19258887777') or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x10005)
		&& ($pdu->{status} == 0)
		&& ($pdu->{source_addr_ton} == 0)
		&& ($pdu->{source_addr_npi} == 0)
		&& ($pdu->{source_addr} eq '')
		&& ($pdu->{dest_addr_ton} == 0)
		&& ($pdu->{dest_addr_npi} == 0)
		&& ($pdu->{destination_addr} eq '19258887777')
		&& ($pdu->{msg_reference} eq '')
		&& ($pdu->{esm_class} == 0)
		&& ($pdu->{protocol_id} == 0)
		&& ($pdu->{priority_flag} == 0)
		&& ($pdu->{schedule_delivery_time} eq '')
		&& ($pdu->{data_coding} == 0)
		&& ($pdu->{short_message} eq '')
		) {
		print "ok 68  (seq=$seq)\n";
	    } else {
		fail_pdu(68, $pdu);
	    }
	    
	    $seq = $cli->deliver_sm_resp(seq=>$seq) or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80010005)
		&& ($pdu->{status} == 0)
		) {
		print "ok 69  (seq=$seq)\n";
	    } else {
		fail_pdu(69, $pdu);
	    }
	    
	    $seq = $serv->deliver_sm(
				   source_addr_ton => 0x11,
				   source_addr_npi => 0x22,
				   source_addr => '8199998888',
				   dest_addr_ton => 0x33,
				   dest_addr_npi => 0x44,
				   destination_addr => '19258887777',
				   msg_reference => '12345678',
				   esm_class => 0x55,
				   protocol_id => 0x66,
				   priority_flag => 0x77,
				   schedule_delivery_time => '0123456789abcdef',
				   data_coding => 0xaa,
				   short_message => 'foobar',
				   ) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x10005)
		&& ($pdu->{status} == 0)
		&& ($pdu->{source_addr_ton} == 0x11)
		&& ($pdu->{source_addr_npi} == 0x22)
		&& ($pdu->{source_addr} eq '8199998888')
		&& ($pdu->{dest_addr_ton} == 0x33)
		&& ($pdu->{dest_addr_npi} == 0x44)
		&& ($pdu->{destination_addr} eq '19258887777')
		&& ($pdu->{msg_reference} eq '12345678')
		&& ($pdu->{esm_class} == 0x55)
		&& ($pdu->{protocol_id} == 0x66)
		&& ($pdu->{priority_flag} == 0x77)
		&& ($pdu->{schedule_delivery_time} eq '0123456789abcdef')
		&& ($pdu->{data_coding} == 0xaa)
		&& ($pdu->{short_message} eq 'foobar')
		) {
		print "ok 70  (seq=$seq)\n";
	    } else {
		fail_pdu(70, $pdu);
	    }
	    
	    $seq = $cli->deliver_sm_resp(seq=>$seq) or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80010005)
		&& ($pdu->{status} == 0)
		) {
		print "ok 71  (seq=$seq)\n";
	    } else {
		fail_pdu(71, $pdu);
	    }

	    ### Delivery Receipt
	    
	    $seq = $cli->delivery_receipt(destination_addr => '19258887777') or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x10009)
		&& ($pdu->{status} == 0)
		&& ($pdu->{source_addr_ton} == 0)
		&& ($pdu->{source_addr_npi} == 0)
		&& ($pdu->{source_addr} eq '')
		&& ($pdu->{dest_addr_ton} == 0)
		&& ($pdu->{dest_addr_npi} == 0)
		&& ($pdu->{destination_addr} eq '19258887777')
		&& ($pdu->{msg_reference} == '')
		&& ($pdu->{num_msgs_submitted} == 0)
		&& ($pdu->{num_msgs_delivered} == 0)
		&& ($pdu->{submit_date} eq '')
		&& ($pdu->{done_date} eq '')
		&& ($pdu->{message_state} == 0)
		&& ($pdu->{network_error_code} == 0)
		&& ($pdu->{data_coding} == 0)
		&& ($pdu->{short_message} eq '')
		) {
		print "ok 72  (seq=$seq)\n";
	    } else {
		fail_pdu(72, $pdu);
	    }
	    
	    $seq = $serv->delivery_receipt_resp(seq=>$seq) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80010009)
		&& ($pdu->{status} == 0)
		) {
		print "ok 73  (seq=$seq)\n";
	    } else {
		fail_pdu(73, $pdu);
	    }
	    
	    $seq = $cli->delivery_receipt(source_addr_ton => 0x11,
				 source_addr_npi => 0x22,
				 source_addr => '8199998888',
				 dest_addr_ton => 0x33,
				 dest_addr_npi => 0x44,
				 destination_addr => '19258887777',
				 msg_reference => '12345678',
				 num_msgs_submitted => 1,
				 num_msgs_delivered => 2,
				 submit_date => '0123456789abcdef',
				 done_date => 'ABCDEF0987654321',
				 message_state => 3,
				 network_error_code => 4,
				 data_coding => 0xaa,
				 short_message => 'foobar',
				   ) or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x10009)
		&& ($pdu->{status} == 0)
		&& ($pdu->{source_addr_ton} == 0x11)
		&& ($pdu->{source_addr_npi} == 0x22)
		&& ($pdu->{source_addr} eq '8199998888')
		&& ($pdu->{dest_addr_ton} == 0x33)
		&& ($pdu->{dest_addr_npi} == 0x44)
		&& ($pdu->{destination_addr} eq '19258887777')
		&& ($pdu->{msg_reference} eq '12345678')
		&& ($pdu->{num_msgs_submitted} == 1)
		&& ($pdu->{num_msgs_delivered} == 2)
		&& ($pdu->{submit_date} eq '0123456789abcdef')
		&& ($pdu->{done_date} eq 'ABCDEF0987654321')
		&& ($pdu->{message_state} == 3)
		&& ($pdu->{network_error_code} == 4)
		&& ($pdu->{data_coding} == 0xaa)
		&& ($pdu->{short_message} eq 'foobar')
		) {
		print "ok 74  (seq=$seq)\n";
	    } else {
		fail_pdu(74, $pdu);
	    }
	    
	    $seq = $serv->delivery_receipt_resp(seq=>$seq) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80010009)
		&& ($pdu->{status} == 0)
		) {
		print "ok 75  (seq=$seq)\n";
	    } else {
		fail_pdu(75, $pdu);
	    }

	    ### Submit SM
	    
	    $seq = $cli->submit_sm(destination_addr => [ '19258887777', 'distlist'],
				   ) or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x10004)
		&& ($pdu->{status} == 0)
		&& ($pdu->{message_class} eq 0xffff)
		&& ($pdu->{source_addr_ton} == 0)
		&& ($pdu->{source_addr_npi} == 0)
		&& ($pdu->{source_addr} eq '')
		&& ($pdu->{number_of_dests} == 2)
		&& ($pdu->{dest_addr_ton}[0] == 0)
		&& ($pdu->{dest_addr_npi}[0] == 0)
		&& ($pdu->{destination_addr}[0] eq '19258887777')
		&& ($pdu->{dest_addr_ton}[1] == 0)
		&& ($pdu->{dest_addr_npi}[1] == 0)
		&& ($pdu->{destination_addr}[1] eq 'distlist')
		&& ($pdu->{messaging_mode} == 0)
		&& ($pdu->{msg_reference} eq '')
		&& ($pdu->{telematic_interworking} == 0xff)
		&& ($pdu->{priority_level} == 0xff)
		&& ($pdu->{schedule_delivery_time} eq '')
		&& ($pdu->{validity_period} == 0)
		&& ($pdu->{registered_delivery_mode} == 0)
		&& ($pdu->{data_coding} == 0)
		&& ($pdu->{sm_default_msg_id} == 0)
		&& ($pdu->{short_message} eq '')
		) {
		print "ok 76  (seq=$seq)\n";
	    } else {
		fail_pdu(76, $pdu);
	    }
	    
	    $seq = $serv->submit_sm_resp(seq=>$seq,
					 message_id => '12345678',
					 destination_addr  => [ '19258887777', 'distlist'],
					 error_status_code => [ 1,2 ],
					 ) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80010004)
		&& ($pdu->{status} == 0)
		&& ($pdu->{message_id} eq '12345678')
		&& ($pdu->{num_unsuccess} == 2)
		&& ($pdu->{error_status_code}[0] == 1)
		&& ($pdu->{dest_addr_ton}[0] == 0)
		&& ($pdu->{dest_addr_npi}[0] == 0)
		&& ($pdu->{destination_addr}[0] eq '19258887777')
		&& ($pdu->{error_status_code}[1] == 2)
		&& ($pdu->{dest_addr_ton}[1] == 0)
		&& ($pdu->{dest_addr_npi}[1] == 0)
		&& ($pdu->{destination_addr}[1] eq 'distlist')
		) {
		print "ok 77  (seq=$seq)\n";
	    } else {
		fail_pdu(77, $pdu);
	    }
	    
	    $seq = $cli->submit_sm(message_class => 0xeeee,
				   source_addr_ton => 0x11,
				   source_addr_npi => 0x22,
				   source_addr => '8199998888',
				      destination_addr => [ '19258887777', 'distlist'],
				      dest_addr_ton => [ 0x33 ],
				      dest_addr_npi => [ 0x44 ],
				   messaging_mode => 0x55,
				   msg_reference => '01234567',
				   telematic_interworking => 0x66,
				   priority_level => 0x77,
				   schedule_delivery_time => '0123456789abcdef',
				   validity_period => 0xbbbb,
				   registered_delivery => 0x88,
				   data_coding => 0xaa,
				   sm_default_msg_id => 0xbb,
				   short_message => 'foobar',
				   ) or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x10004)
		&& ($pdu->{status} == 0)
		&& ($pdu->{message_class} == 0xeeee)
		&& ($pdu->{source_addr_ton} == 0x11)
		&& ($pdu->{source_addr_npi} == 0x22)
		&& ($pdu->{source_addr} eq '8199998888')
		&& ($pdu->{number_of_dests} == 2)
		&& ($pdu->{dest_addr_ton}[0] == 0x33)
		&& ($pdu->{dest_addr_npi}[0] == 0x44)
		&& ($pdu->{destination_addr}[0] eq '19258887777')
		&& ($pdu->{destination_addr}[1] eq 'distlist')
		&& ($pdu->{messaging_mode} == 0x55)
		&& ($pdu->{msg_reference} eq '01234567')
		&& ($pdu->{telematic_interworking} == 0x66)
		&& ($pdu->{priority_level} == 0x77)
		&& ($pdu->{schedule_delivery_time} eq '0123456789abcdef')
		&& ($pdu->{validity_period} == 0xbbbb)
		&& ($pdu->{registered_delivery} == 0x88)
		&& ($pdu->{data_coding} == 0xaa)
		&& ($pdu->{sm_default_msg_id} == 0xbb)
		&& ($pdu->{short_message} eq 'foobar')
		) {
		print "ok 78  (seq=$seq)\n";
	    } else {
		fail_pdu(78, $pdu);
	    }
	    
	    $seq = $serv->submit_sm_resp(seq=>$seq,
					    message_id=>'1234567',
					    dest_addr_ton => [ 0x33 ],
					    dest_addr_npi => [ 0x44 ],
					    destination_addr  => [ '19258887777', 'distlist'],
					    error_status_code => [ 1, 2 ],
					    ) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80010004)
		&& ($pdu->{status} == 0)
		&& ($pdu->{message_id} eq '1234567')
		&& ($pdu->{num_unsuccess} == 2)
		&& ($pdu->{error_status_code}[0] == 1)
		&& ($pdu->{dest_addr_ton}[0] == 0x33)
		&& ($pdu->{dest_addr_npi}[0] == 0x44)
		&& ($pdu->{destination_addr}[0] eq '19258887777')
		&& ($pdu->{error_status_code}[1] == 2)
		&& ($pdu->{destination_addr}[1] eq 'distlist')
		) {
		print "ok 79  (seq=$seq)\n";
	    } else {
		fail_pdu(79, $pdu);
	    }

	    ### Query SM

	    $seq = $cli->query_sm(message_id => '') or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x10003)
		&& ($pdu->{status} == 0)
		&& ($pdu->{message_id} eq '')
		&& ($pdu->{source_addr_ton} == 0)
		&& ($pdu->{source_addr_npi} == 0)
		&& ($pdu->{source_addr} eq '')
		&& ($pdu->{dest_addr_ton} == 0)
		&& ($pdu->{dest_addr_npi} == 0)
		&& ($pdu->{destination_addr} eq '')
		) {
		print "ok 80  (seq=$seq)\n";
	    } else {
		fail_pdu(80, $pdu);
	    }
	    
	    $seq = $serv->query_sm_resp(seq => $seq,
					message_id => '',
					message_state => Net::SMPP::MSGSTATE_accepted) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80010003)
		&& ($pdu->{status} == 0)
		&& ($pdu->{message_id} eq '')
		&& ($pdu->{message_state} == 6)
		&& ($pdu->{final_date} eq '')
		&& ($pdu->{error_code} == 0)
		) {
		print "ok 81  (seq=$seq)\n";
	    } else {
		fail_pdu(81, $pdu);
	    }

	    $seq = $cli->query_sm(message_id => 'testi',
				  source_addr_ton => 0x22,
				  source_addr_npi => 0x33,
				  source_addr => '19257778888',
				  dest_addr_ton => 0x44,
				  dest_addr_npi => 0x55,
				  destination_addr => '19253334444',
				  ) or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x10003)
		&& ($pdu->{status} == 0)
		&& ($pdu->{message_id} eq 'testi')
		&& ($pdu->{source_addr_ton} == 0x22)
		&& ($pdu->{source_addr_npi} == 0x33)
		&& ($pdu->{source_addr} eq '19257778888')
		&& ($pdu->{dest_addr_ton} == 0x44)
		&& ($pdu->{dest_addr_npi} == 0x55)
		&& ($pdu->{destination_addr} eq '19253334444')
		) {
		print "ok 82  (seq=$seq)\n";
	    } else {
		fail_pdu(82, $pdu);
	    }
	    
	    $seq = $serv->query_sm_resp(seq=>$seq,
					message_id => 'defghi',
					message_state => Net::SMPP::MSGSTATE_accepted,
					final_date => '0123456789abcdef',
					error_code => 0x11,
					) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80010003)
		&& ($pdu->{message_id} eq 'defghi')
		&& ($pdu->{message_state} == 6)
		&& ($pdu->{final_date} eq '0123456789abcdef')
		&& ($pdu->{error_code} == 0x11)
		) {
		print "ok 83  (seq=$seq)\n";
	    } else {
		fail_pdu(83, $pdu);
	    }

	    ### Cancel SM

	    $seq = $cli->cancel_sm() or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x10008)
		&& ($pdu->{status} == 0)
		&& ($pdu->{message_class} == 0)
		&& ($pdu->{message_id} eq '')
		&& ($pdu->{source_addr_ton} == 0)
		&& ($pdu->{source_addr_npi} == 0)
		&& ($pdu->{source_addr} eq '')
		&& ($pdu->{dest_addr_ton} == 0)
		&& ($pdu->{dest_addr_npi} == 0)
		&& ($pdu->{destination_addr} eq '')
		) {
		print "ok 84  (seq=$seq)\n";
	    } else {
		fail_pdu(84, $pdu);
	    }
	    
	    $seq = $serv->cancel_sm_resp(seq => $seq) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80010008)
		&& ($pdu->{status} == 0)
		) {
		print "ok 85  (seq=$seq)\n";
	    } else {
		fail_pdu(85, $pdu);
	    }

	    $seq = $cli->cancel_sm(message_class => 0xeeee,
				   message_id => 'testi',
				   source_addr_ton => 0x22,
				   source_addr_npi => 0x33,
				   source_addr => '19257778888',
				   dest_addr_ton => 0x44,
				   dest_addr_npi => 0x55,
				   destination_addr => '19257776666',
				   ) or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x10008)
		&& ($pdu->{status} == 0)
		&& ($pdu->{message_class} == 0xeeee)
		&& ($pdu->{message_id} eq 'testi')
		&& ($pdu->{source_addr_ton} == 0x22)
		&& ($pdu->{source_addr_npi} == 0x33)
		&& ($pdu->{source_addr} eq '19257778888')
		&& ($pdu->{dest_addr_ton} == 0x44)
		&& ($pdu->{dest_addr_npi} == 0x55)
		&& ($pdu->{destination_addr} eq '19257776666')
		) {
		print "ok 86  (seq=$seq)\n";
	    } else {
		fail_pdu(86, $pdu);
	    }
	    
	    $seq = $serv->cancel_sm_resp(seq=>$seq) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80010008)
		&& ($pdu->{status} == 0)
		) {
		print "ok 87  (seq=$seq)\n";
	    } else {
		fail_pdu(87, $pdu);
	    }

	    ### Replace SM

	    $seq = $cli->replace_sm(message_id => '') or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x10007)
		&& ($pdu->{status} == 0)
		&& ($pdu->{message_id} eq '')
		&& ($pdu->{source_addr_ton} == 0)
		&& ($pdu->{source_addr_npi} == 0)
		&& ($pdu->{source_addr} eq '')
		&& ($pdu->{dest_addr_ton} == 0)
		&& ($pdu->{dest_addr_npi} == 0)
		&& ($pdu->{destination_addr} eq '')
		&& ($pdu->{schedule_delivery_time} eq '')
		&& ($pdu->{validity_period} == 0)
		&& ($pdu->{registered_delivery} == 0)
		&& ($pdu->{data_coding} == 0)
		&& ($pdu->{sm_default_msg_id} == 0)
		&& ($pdu->{short_message} eq '')
		) {
		print "ok 88  (seq=$seq)\n";
	    } else {
		fail_pdu(88, $pdu);
	    }
	    
	    $seq = $serv->replace_sm_resp(seq => $seq) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80010007)
		&& ($pdu->{status} == 0)
		) {
		print "ok 89  (seq=$seq)\n";
	    } else {
		fail_pdu(89, $pdu);
	    }

	    $seq = $cli->replace_sm(message_id => 'testi',
				    source_addr_ton => 0x22,
				    source_addr_npi => 0x33,
				    source_addr => '19257778888',
				    dest_addr_ton => 0x77,
				    dest_addr_npi => 0x88,
				    destination_addr => '19251112222',
				    schedule_delivery_time => '0123456789abcdef',
				    validity_period => 0xdddd,
				    registered_delivery => 0x44,
				    data_coding => 0x66,
				    sm_default_msg_id => 0x55,
				    short_message => 'foobar',
				    ) or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x10007)
		&& ($pdu->{status} == 0)
		&& ($pdu->{message_id} eq 'testi')
		&& ($pdu->{source_addr_ton} == 0x22)
		&& ($pdu->{source_addr_npi} == 0x33)
		&& ($pdu->{source_addr} eq '19257778888')
		&& ($pdu->{dest_addr_ton} == 0x77)
		&& ($pdu->{dest_addr_npi} == 0x88)
		&& ($pdu->{destination_addr} eq '19251112222')
		&& ($pdu->{schedule_delivery_time} eq '0123456789abcdef')
		&& ($pdu->{validity_period} == 0xdddd)
		&& ($pdu->{registered_delivery} == 0x44)
		&& ($pdu->{data_coding} == 0x66)
		&& ($pdu->{sm_default_msg_id} == 0x55)
		&& ($pdu->{short_message} eq 'foobar')
		) {
		print "ok 90  (seq=$seq)\n";
	    } else {
		fail_pdu(90, $pdu);
	    }
	    
	    $seq = $serv->replace_sm_resp(seq=>$seq) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x80010007)
		&& ($pdu->{status} == 0)
		) {
		print "ok 91  (seq=$seq)\n";
	    } else {
		fail_pdu(91, $pdu);
	    }
	    
	    ### Enquire Link

	    $seq = $cli->enquire_link() or die;
	    $pdu = $serv->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x1000a)
		&& ($pdu->{status} == 0)
		) {
		print "ok 92  (seq=$seq)\n";
	    } else {
		fail_pdu(92, $pdu);
	    }
	    
	    $seq = $serv->enquire_link_resp(seq => $seq) or die;
	    $pdu = $cli->read_pdu() or die;
	    if (($pdu->{seq} == $seq) && $pdu->{known_pdu}
		&& ($pdu->{cmd} == 0x8001000a)
		&& ($pdu->{status} == 0)
		&& ($pdu->status == 0)
		) {
		print "ok 93  (seq=$seq)\n";
	    } else {
		fail_pdu(93, $pdu);
	    }

	    ### end of v40 tests

	    undef $cli;
	} else {
	    print "fail 58\n\t*** Could not accept connection\n";
	    print "\t*** Skipping tests 59..93";
	    $fail++;
	}
	undef $serv;
    } else {
	print "fail 57\n\t*** Could not contact test server on localhost:2251\n";
	print "\t*** Skipping tests 58..93";
	$fail++;
    }
    undef $listen;
} else {
    print "fail 56\n\t*** Failed to create test server on port 2251.\n";
    print "\t*** Check if some other service is already using this port.\n";
    print "\t*** Skipping tests 57..93\n";
    $fail++;
}

### The end

if ($fail) {
    print "*** Bummer. $fail tests failed.\n";
} else {
    print "All tests successful.\n";
}

#exit;

### Debugging section

for $test (qw(abcdefgh abcdefg abcedf abcde abcd abc ab a abcdefghi abcdefghij abcdefghabcdefgh)) {
    print "Testing >$test< len=".length($test)."\n";
    $x = Net::SMPP::pack_7bit($test);
    $y = Net::SMPP::unpack_7bit($x);
    print "        >$y< len=".length($y)."\n";
    print Net::SMPP::hexdump($x,"\t");
    print Net::SMPP::hexdump($y,"\t");
}

#EOF
