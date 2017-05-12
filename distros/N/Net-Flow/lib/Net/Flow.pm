#!/usr/bin/perl
#
#
# Atsushi Kobayashi <akoba@nttv6.net>
#
# Acknowledgments
# This module was supported by the Ministry of Internal Affairs and
# Communications of Japan.
#
# Flow.pm - 2008/12/04
#
# Copyright (c) 2007-2008 NTT Information Sharing Platform Laboratories
#
# This package is free software and is provided "as is" without express
# or implied warranty.  It may be used, redistributed and/or modified
# under the terms of the Perl Artistic License (see
# http://www.perl.com/perl/misc/Artistic.html)
#

package Net::Flow;

use 5.008008;
use strict;
use warnings;

use Time::HiRes qw(tv_interval gettimeofday);
use Digest::MD5 qw(md5_hex);
use Data::Dumper;

use Exporter;

our @EXPORT_OK = qw(decode encode);
our $VERSION   = '1.003';

use constant NetFlowv5 => 5;
use constant NetFlowv8 => 8;
use constant NetFlowv9 => 9;
use constant IPFIX     => 10;

use constant NFWV9_DataTemplateSetId   => 0;
use constant NFWV9_OptionTemplateSetId => 1;

use constant IPFIX_DataTemplateSetId   => 2;
use constant IPFIX_OptionTemplateSetId => 3;

use constant MinDataSetId        => 256;
use constant VariableLength      => 65535;
use constant ShortVariableLength => 255;

my %TemplateForNetFlowv5 = (
	'SetId'      => 0,
	'TemplateId' => 0,
	'FieldCount' => 20,
	'Template'   => [
		{ 'Length' => 4,	'Id' => 8  }, # sourceIPv4Address
		{ 'Length' => 4,	'Id' => 12 }, # destinationIPv4Address
		{ 'Length' => 4,	'Id' => 15 }, # ipNextHopIPv4Address
		{ 'Length' => 2,	'Id' => 10 }, # ingressInterface
		{ 'Length' => 2,	'Id' => 14 }, # egressInterface
		{ 'Length' => 4,	'Id' => 2  }, # packetDeltaCount
		{ 'Length' => 4,	'Id' => 1  }, # octetDeltaCount
		{ 'Length' => 4,	'Id' => 22 }, # flowStartSysUpTime
		{ 'Length' => 4,	'Id' => 21 }, # flowEndSysUpTime
		{ 'Length' => 2,	'Id' => 7  }, # sourceTransportPort
		{ 'Length' => 2,	'Id' => 11 }, # destinationTransportPort
		{ 'Length' => 1,	'Id' => 210}, # paddingOctets
		{ 'Length' => 1,	'Id' => 6  }, # tcpControlBits
		{ 'Length' => 1,	'Id' => 4  }, # protocolIdentifier
		{ 'Length' => 1,	'Id' => 5  }, # ipClassOfService
		{ 'Length' => 2,	'Id' => 16 }, # bgpSourceAsNumber
		{ 'Length' => 2,	'Id' => 17 }, # bgpDestinationAsNumber
		{ 'Length' => 1,	'Id' => 9  }, # sourceIPv4PrefixLength
		{ 'Length' => 1,	'Id' => 13 }, # destinationIPv4PrefixLength
		{ 'Length' => 2,	'Id' => 210}, # paddingOctets
	],
);

#################### START sub encode() ####################
sub encode {

	my ( $InputHeaderRef, $InputTemplateRef, $InputFlowRef, $MaxDatagram ) = @_;
	my @Payloads            = ();
	my @FlowPacks           = ();
	my %FlowSetPayloads     = ();
	my $FlowSetHeaderLength = 4;
	my @Errors              = ();
	my $Error               = undef;

	# This is a terrible default, but it was the original behavior.
	$InputHeaderRef->{TemplateResendSecs} = 0
		unless defined $InputHeaderRef->{TemplateResendSecs};

	$InputHeaderRef->{_sysstarttime} ||= [gettimeofday];
  check_header($InputHeaderRef) unless defined $InputHeaderRef->{_header_len};

	my $sendTemplates = 1;    # Always is the default

	my $template_info;

	# if TemplateResendSecs is true someone has bothered to define it so
	# we can do some extra work to see if we really need to send
	# template info.
	if ( $InputHeaderRef->{TemplateResendSecs} ) {
		my $templates_id = scalar $InputTemplateRef;
		##warn "templates_id: $templates_id\n";
		$InputHeaderRef->{_template_info}->{$templates_id} ||= {};
		$template_info = $InputHeaderRef->{_template_info}->{$templates_id};
		my $hash = md5_hex( Dumper($InputTemplateRef) );
		##warn Dumper($InputTemplateRef) unless defined $template_info->{hash};
		$template_info->{hash} ||= $hash;
		if ( $template_info->{hash} ne $hash ) {
			##warn "$template_info->{hash} ne $hash", "\n";
			##warn Dumper($InputTemplateRef);
			$template_info->{hash} = $hash;
			delete $template_info->{_template_sent};
		}

		# This is a kludge until I come up with something better.  Using
		# the stringified $InputTemplateRef as an ID works, but if someone
		# is passing in a new ref everytime this will slowly leak memory.
		#
		# I have arbitrarily chosen 50 as too many sets of template
		# information to have.  Hopefully this will keep the amount of
		# looping through the _template_info hash to a minimum and also
		# prevent memory from leaking endlessly.
		if ( keys %{ $InputHeaderRef->{_template_info} } > 50 ) {
			for my $key ( keys %{ $InputHeaderRef->{_template_info} } ) {
				my $sent = $InputHeaderRef->{_template_info}->{$key}->{_template_sent};
				if ( time - $sent > $InputHeaderRef->{TemplateResendSecs} ) {
					delete $InputHeaderRef->{_template_info}->{$key};
				}
			}
		}

		$sendTemplates = (
			( !defined $template_info->{_template_sent} )
			? 1
			: ( ( time - $template_info->{_template_sent} ) >= $InputHeaderRef->{TemplateResendSecs} )
		);
	}

	#
	# check header reference
	#

	my ($ErrorRef) = &check_header($InputHeaderRef);

	push( @Errors, @{$ErrorRef} ) if ( defined $ErrorRef );

	my @flowRef;
	if ($sendTemplates) {
		push @flowRef, @{$InputTemplateRef};
		$template_info->{_template_sent} = time if ref $template_info eq 'HASH';
	}
	push @flowRef, @{$InputFlowRef};

	##warn scalar localtime ($template_info->{_template_sent}), "\n";

	foreach my $FlowRef (@flowRef) {
		my $PackRef           = undef;
		my $ErrorRef          = undef;
		my $DecodeTemplateRef = undef;

		unless ( defined $FlowRef->{SetId} ) {
			$Error = 'ERROR : NOTHING SETID VALUE';
			push( @Errors, $Error );
			next;
		}

		#
		# encode flow data
		#

		if ( $FlowRef->{SetId} >= MinDataSetId ) {

			#
			# searching for particular template
			#

			( $DecodeTemplateRef, $Error ) = &search_template( $FlowRef->{SetId}, $InputTemplateRef );

			if ( defined $DecodeTemplateRef ) {

				( $PackRef, $ErrorRef ) = &flow_encode( $FlowRef, $DecodeTemplateRef );

			} else {

				$Error = "ERROR : NO TEMPLATE TEMPLATE ID=$FlowRef->{SetId}";
				push( @Errors, $Error );

			}

			#
			# encode template data
			#

		} else {

			( $PackRef, $ErrorRef ) = &template_encode( $FlowRef, $InputHeaderRef );

		}

		push( @FlowPacks, $PackRef )
			if defined $PackRef;

		push( @Errors, @{$ErrorRef} ) if defined $ErrorRef;

	}

	unless (@FlowPacks) {

		$Error = 'ERROR : NO FLOW DATA';
		push( @Errors, $Error );
		return ( $InputHeaderRef, \@Payloads, \@Errors );

	}

	#
	# encode NetFlowv9/IPFIX datagram
	#

	my $FlowCount = 0;
	my $DataCount = 0;
	foreach my $FlowPackRef (@FlowPacks) {

		unless ( defined $FlowPackRef->{Pack} ) {
			warn 'undefined $FlowPackRef->{Pack}', "\n";
			next;
		}

		#
		# check datagram size
		#

		my $TotalLength = $InputHeaderRef->{_header_len};

		foreach my $SetId ( keys %FlowSetPayloads ) {

			$TotalLength += length( $FlowSetPayloads{$SetId} ) + $FlowSetHeaderLength;

		}

		if ( ( length( $FlowPackRef->{Pack} ) + $TotalLength ) > $MaxDatagram ) {

			#
			# make NetFlow/IPFIX datagram
			#

			push( @Payloads, &datagram_encode( $InputHeaderRef, \%FlowSetPayloads, \$FlowCount, \$DataCount ) );

			%FlowSetPayloads = ();
			$FlowCount       = 0;
			$DataCount       = 0;
		}

		$FlowSetPayloads{ $FlowPackRef->{SetId} } .= $FlowPackRef->{Pack};

		$DataCount++ if $FlowPackRef->{SetId} >= MinDataSetId;
		$FlowCount++;

	}

	# Push a final flow if any.
	if ( $FlowCount > 0 ) {
		push( @Payloads, &datagram_encode( $InputHeaderRef, \%FlowSetPayloads, \$FlowCount, \$DataCount ) );

	}

	return ( $InputHeaderRef, \@Payloads, \@Errors );

}
#################### END sub encode() ######################

#################### START sub check_header() ##############

sub check_header {
	my ($InputHeaderRef) = @_;

	my @Errors;
	my $Error;

	if ( $InputHeaderRef->{VersionNum} == IPFIX ) {
		$InputHeaderRef->{_header_len} = 16;
		$InputHeaderRef->{ObservationDomainId} ||= 0;
		$InputHeaderRef->{SequenceNum}         ||= 0;
		$InputHeaderRef->{_export_time} = $InputHeaderRef->{UnixSecs} || time;
	} else {
		if ( $InputHeaderRef->{VersionNum} != NetFlowv9 ) {
			if ( !defined $InputHeaderRef->{VersionNum} ) {
				$Error = 'WARNING : NO HEADER VERSION NUMBER';
			} else {
				$Error = "WARNING : NO SUPPORT HEADER VERSION NUMBER $InputHeaderRef->{VersionNum}";
			}
      push( @Errors, $Error );
		}
		$InputHeaderRef->{VersionNum} = NetFlowv9;

		$InputHeaderRef->{_header_len} = 20;
		$InputHeaderRef->{SourceId}    ||= 0;
		$InputHeaderRef->{SequenceNum} ||= 0;
		$InputHeaderRef->{_export_time} = $InputHeaderRef->{UnixSecs} || time;
		$InputHeaderRef->{SysUpTime} = int( tv_interval( $InputHeaderRef->{_sysstarttime} ) * 1000 );
	}

	return ( \@Errors );
}
#################### END sub check_header() ################

#################### START sub datagram_encode() ###########
sub datagram_encode {
	my ( $HeaderRef, $FlowSetPayloadRef, $FlowCountRef, $DataCountRef ) = @_;
	my $Payload = '';

	#
	# encode flow set data
	#

	foreach my $SetId ( sort { $a <=> $b } ( keys %{$FlowSetPayloadRef} ) ) {

		#
		# make padding part
		#

		my $padding = '';

		while ( ( length( $FlowSetPayloadRef->{$SetId} ) + length($padding) ) % 4 != 0 ) {
			$padding .= "\0";
		}

		my $set_len = ( length( $FlowSetPayloadRef->{$SetId} ) + length($padding) + 4 );

		# Pack set header
		$Payload .= pack( 'n2', $SetId, $set_len );

		# Pack set data
		$Payload .= $FlowSetPayloadRef->{$SetId};

		# Pack padding
		$Payload .= $padding;
	}

	if ( $HeaderRef->{VersionNum} == NetFlowv9 ) {

    $HeaderRef->{SysUpTime} ||= 0;
    $HeaderRef->{_export_time} ||= 0;
    $HeaderRef->{SequenceNum} ||= 0;
		$HeaderRef->{SequenceNum} = ( $HeaderRef->{SequenceNum} + 1 ) % 0xFFFFFFFF;
		$HeaderRef->{Count}       = $$FlowCountRef;

		$Payload = pack( 'n2N4', @{$HeaderRef}{qw{VersionNum Count SysUpTime _export_time SequenceNum SourceId}} ) . $Payload;

	} elsif ( $HeaderRef->{VersionNum} == IPFIX ) {

		$Payload = pack( 'n2N3', $HeaderRef->{VersionNum}, ( length($Payload) + $HeaderRef->{_header_len} ), @{$HeaderRef}{qw{_export_time SequenceNum ObservationDomainId}} ) . $Payload;

		$HeaderRef->{SequenceNum} = ( $HeaderRef->{SequenceNum} + $$DataCountRef ) % 0xFFFFFFFF;

	}


	return ( \$Payload );

}
#################### END sub datagram_encode() #############

#################### START sub flow_encode() ###############
sub flow_encode {
	my ( $FlowRef, $DecodeTemplateRef ) = @_;
	my %FlowData = ();
	my @Errors   = ();
	my $Error    = undef;
	my %Count    = ();

	$FlowData{SetId} = $DecodeTemplateRef->{TemplateId};

	foreach my $TemplateArrayRef ( @{ $DecodeTemplateRef->{Template} } ) {

		my $FlowValue = undef;


		$Count{ $TemplateArrayRef->{Id} } ||= 0;

		if ( defined $FlowRef->{ $TemplateArrayRef->{Id} } ) {

			#
			# One Template has multiple same Ids.
			#

			if ( ref $FlowRef->{ $TemplateArrayRef->{Id} } ) {

				$FlowValue = @{ $FlowRef->{ $TemplateArrayRef->{Id} } }[ $Count{ $TemplateArrayRef->{Id} } ];

				#
				# Each Id is different than others.
				#

			} else {

				$FlowValue = $FlowRef->{ $TemplateArrayRef->{Id} };

			}

			#
			# Variable Length Type
			#

			if ( $TemplateArrayRef->{Length} == VariableLength ) {

				my $Length = length($FlowValue);

				#
				# Value Length  < 255
				#

				if ( $Length < ShortVariableLength ) {

					$FlowData{Pack} .= pack( "C A$Length", $Length, $FlowValue );

					#
					# Value Length > 255
					#

				} else {

					$FlowData{Pack} .= pack( "C n A$Length", ShortVariableLength, $Length, $FlowValue );

				}

				#
				# Fixed Length Type
				#

			} else {

				$FlowData{Pack} .= pack( "A$TemplateArrayRef->{Length}", $FlowValue );

			}


		} else {
			$Data::Dumper::Sortkeys = sub {
				my $h = shift;
				return [
					sort {
						if ( $a =~ /^\d+$/ && $b =~ /^\d+$/ ) {
							$a <=> $b;
						} else {
							lc($a) cmp lc($b);
						}
					} ( keys %$h )
				];
			};

			$Error = "WARNING : NOT FIELD DATA INFORMATION ELEMENT ID=$TemplateArrayRef->{Id}";
			push( @Errors, $Error );

			if ( $TemplateArrayRef->{Length} == VariableLength ) {

				$FlowData{Pack} .= pack( 'C', 0 );

			} else {

				$FlowData{Pack} .= pack("a$TemplateArrayRef->{Length}");

			}

		}

		$Count{ $TemplateArrayRef->{Id} }++;

	}

	return ( \%FlowData, \@Errors );

}
#################### END sub flow_encode() #################

#################### START sub template_encode() ###########
sub template_encode {
	my ( $TemplateRef, $HeaderRef ) = @_;
	my %TemplateData = ();
	my $ScopeCount   = 0;
	my @Errors       = ();
	my $Error        = undef;

	#
	# check template hash reference
	#

	unless ( defined $TemplateRef->{TemplateId} ) {
		$Error = 'ERROR : NO TEMPLATE ID';
		push( @Errors, $Error );
	}

	unless ( defined $TemplateRef->{SetId} ) {
		$Error = 'ERROR : NO SET ID';
		push( @Errors, $Error );
	}

	if ( $HeaderRef->{VersionNum} == NetFlowv9 ) {

		if (   $TemplateRef->{SetId} != NFWV9_DataTemplateSetId
			&& $TemplateRef->{SetId} != NFWV9_OptionTemplateSetId ) {

			$Error = "ERROR : UNMATCH SET ID FOR NETFLOWV9 TEMPLATE=$TemplateRef->{TemplateId}";
			push( @Errors, $Error );

		}

	} elsif ( $HeaderRef->{VersionNum} == IPFIX ) {

		if (   $TemplateRef->{SetId} != IPFIX_DataTemplateSetId
			&& $TemplateRef->{SetId} != IPFIX_OptionTemplateSetId ) {

			$Error = "ERROR : UNMATCH SET ID FOR IPFIX TEMPLATE=$TemplateRef->{TemplateId}";
			push( @Errors, $Error );

		}

	}

	return ( \%TemplateData, \@Errors ) if $#Errors >= 0;

	$TemplateData{SetId} = $TemplateRef->{SetId};

	$ScopeCount = $TemplateRef->{ScopeCount}
		if defined $TemplateRef->{ScopeCount};

	$TemplateRef->{FieldCount} = $#{ $TemplateRef->{Template} } + 1
		unless defined $TemplateRef->{FieldCount};

	#
	# NetFlow v9 pack data template header
	#

	if ( $TemplateRef->{SetId} == NFWV9_DataTemplateSetId ) {

		$TemplateData{Pack} = pack( 'n2', @{$TemplateRef}{qw{TemplateId FieldCount}} );

		#
		# NetFlow v9 pack option template header
		#

	} elsif ( $TemplateRef->{SetId} == NFWV9_OptionTemplateSetId ) {

		$TemplateData{Pack} = pack( 'n3', $TemplateRef->{TemplateId}, $ScopeCount * 4, ( $#{ $TemplateRef->{Template} } + 1 - $ScopeCount ) * 4, );

		#
		# IPFIX pack data template header
		#

	} elsif ( $TemplateRef->{SetId} == IPFIX_DataTemplateSetId ) {

		#
		# Template Withdraw
		#

		if ( $TemplateRef->{FieldCount} == 0 ) {

			$TemplateData{Pack} = pack( 'n2', $TemplateRef->{TemplateId}, 0 );

		} else {

			$TemplateData{Pack} = pack( 'n2', @{$TemplateRef}{qw{TemplateId FieldCount}} );

		}

		#
		# IPFIX pack option template header
		#

	} elsif ( $TemplateRef->{SetId} == IPFIX_OptionTemplateSetId ) {

		#
		# Template Withdraw
		#

		if ( $TemplateRef->{FieldCount} == 0 ) {

			$TemplateData{Pack} = pack( 'n2', $TemplateRef->{TemplateId}, 0 );

		} else {

			$TemplateData{Pack} = pack(
				'n3',
				$TemplateRef->{TemplateId},
				( $#{ $TemplateRef->{Template} } + 1 ),    # -$ScopeCount
				$ScopeCount,
			);
		}

	}

	#
	# pack template
	#

	if ( $TemplateRef->{FieldCount} > 0 ) {

		foreach my $Ref ( @{ $TemplateRef->{Template} } ) {

			#
			# Enterprise Num
			#

			if ( $Ref->{Id} =~ /([\d]+)\.([\d]+)/ ) {

				$TemplateData{Pack} .= pack( 'n2N', $2 + 0x8000, $Ref->{Length}, $1, );

			} else {

				$TemplateData{Pack} .= pack( 'n2', $Ref->{Id}, $Ref->{Length} );

			}

		}

	}

	return ( \%TemplateData, \@Errors );

}
#################### END sub template_encode() #############


#################### START sub decode() ####################
sub decode {
	my ( $NetFlowPktRef, $InputTemplateRef ) = @_;
	my $NetFlowHeaderRef = undef;
	my $FlowSetHeaderRef = undef;
	my $TemplateRef      = undef;
	my @Template         = ();
	my @Flows            = ();
	my @Errors           = ();
	my $Error            = undef;

	my $OffSet        = 0;
	my $FlowSetOffSet = 0;
	my $FlowCount     = 0;

	#
	# check packet data
	#

	if ( ref($NetFlowPktRef) ne 'SCALAR' ) {

		$Error = 'ERROR : NO PACKET DATA';
		push( @Errors, $Error );

		return ( $NetFlowHeaderRef, \@Template, \@Flows, \@Errors );

	}

	#
	# insert template data
	#

	if ( defined($InputTemplateRef) || ref($InputTemplateRef) eq 'ARRAY' ) {

		push( @Template, @{$InputTemplateRef} );

	} elsif ( defined($InputTemplateRef) ) {

		$Error = 'WARNING : NOT REF TEMPLATE DATA';
		push( @Errors, $Error );

	}

	#
	# header decode
	#

	( $NetFlowHeaderRef, $Error ) = &header_decode( $NetFlowPktRef, \$OffSet );

	#
	# IPFIX decode
	#

	if ( $NetFlowHeaderRef->{VersionNum} == IPFIX ) {

		while ( $OffSet < $NetFlowHeaderRef->{Length} ) {

			my $DecodeTemplateRef = undef;
			my $FlowRef           = undef;
			my $TemplateRef       = undef;

			if ( ( length($$NetFlowPktRef) - $OffSet ) < 4 ) {

				if ( $FlowCount ne $NetFlowHeaderRef->{Count} ) {
					$Error = 'WARNING : UNMATCH FLOW COUNT';
					push( @Errors, $Error );
				}

				last;
			}

			$FlowSetOffSet = $OffSet;

			#
			# decode flowset
			#

			$FlowSetHeaderRef = &flowset_decode( $NetFlowPktRef, \$OffSet );

			#
			# search for template
			#

			if ( $FlowSetHeaderRef->{SetId} >= MinDataSetId ) {

				( $DecodeTemplateRef, $Error ) = &search_template( $FlowSetHeaderRef->{SetId}, \@Template );

				unless ( defined $DecodeTemplateRef ) {

					push( @Errors, $Error );
					$OffSet = $FlowSetHeaderRef->{Length} + $FlowSetOffSet
						if defined $FlowSetHeaderRef->{Length};

					next;

				}

			}

			while ( $FlowSetHeaderRef->{Length} > ( $OffSet - $FlowSetOffSet ) ) {

				#
				# check word alignment
				#

				if ( ( $FlowSetHeaderRef->{Length} - ( $OffSet - $FlowSetOffSet ) ) < 4 ) {

					$OffSet = $FlowSetHeaderRef->{Length} + $FlowSetOffSet;
					last;

				}

				#
				# decode data template or option Template
				#

				if ( $FlowSetHeaderRef->{SetId} < MinDataSetId ) {

					( $TemplateRef, $Error ) = &template_decode( $NetFlowPktRef, \$OffSet, $FlowSetHeaderRef, \$NetFlowHeaderRef->{VersionNum} );

					if ( defined $Error ) {

						push( @Errors, $Error );
						last;

					}

					$FlowCount++;

					@Template = grep { $_ if ( $_->{TemplateId} ne $TemplateRef->{TemplateId} ); } @Template;

					push( @Template, $TemplateRef );

					#
					# decode flow records
					#

				} else {

					( $FlowRef, $Error ) = &flow_decode( $NetFlowPktRef, \$OffSet, $DecodeTemplateRef );

					if ( defined $Error ) {
						push( @Errors, $Error );
						last;
					}

					$FlowCount++;
					push( @Flows, $FlowRef );

				}

			}

		}

		#
		# NetFlow version 9 decode
		#

	} elsif ( $NetFlowHeaderRef->{VersionNum} == NetFlowv9 ) {

		while ( $FlowCount < $NetFlowHeaderRef->{Count} ) {
			my $DecodeTemplateRef = undef;
			my $FlowRef           = undef;
			my $TemplateRef       = undef;

			if ( ( length($$NetFlowPktRef) - $OffSet ) < 4 ) {

				if ( $FlowCount ne $NetFlowHeaderRef->{Count} ) {
					$Error = 'WARNING : UNMATCH FLOW COUNT';
					push( @Errors, $Error );
				}

				last;
			}

			$FlowSetOffSet = $OffSet;

			#
			# decode flowset
			#

			$FlowSetHeaderRef = &flowset_decode( $NetFlowPktRef, \$OffSet );

			#
			# search for template
			#

			if ( $FlowSetHeaderRef->{SetId} >= MinDataSetId ) {

				( $DecodeTemplateRef, $Error ) = &search_template( $FlowSetHeaderRef->{SetId}, \@Template );

				unless ( defined $DecodeTemplateRef ) {

					push( @Errors, $Error );
					$OffSet = $FlowSetHeaderRef->{Length} + $FlowSetOffSet
						if defined $FlowSetHeaderRef->{Length};

					next;

				}

			}

			while ( $FlowSetHeaderRef->{Length} > ( $OffSet - $FlowSetOffSet ) ) {

				#
				# check word alignment
				#

				if ( ( $FlowSetHeaderRef->{Length} - ( $OffSet - $FlowSetOffSet ) ) < 4 ) {

					$OffSet = $FlowSetHeaderRef->{Length} + $FlowSetOffSet;
					last;

				}

				#
				# decode data template or option Template
				#

				if ( $FlowSetHeaderRef->{SetId} < MinDataSetId ) {

					( $TemplateRef, $Error ) = &template_decode( $NetFlowPktRef, \$OffSet, $FlowSetHeaderRef, \$NetFlowHeaderRef->{VersionNum} );

					if ( defined $Error ) {

						push( @Errors, $Error );
						last;

					}

					$FlowCount++;

					@Template = grep { $_ if ( $_->{TemplateId} ne $TemplateRef->{TemplateId} ); } @Template;

					push( @Template, $TemplateRef );

					#
					# decode flow records
					#

				} else {

					( $FlowRef, $Error ) = &flow_decode( $NetFlowPktRef, \$OffSet, $DecodeTemplateRef );

					if ( defined $Error ) {
						push( @Errors, $Error );
						last;
					}

					$FlowCount++;
					push( @Flows, $FlowRef );

				}

			}

		}

		#
		# NetFlow version 5 Decode
		#

	} elsif ( $NetFlowHeaderRef->{VersionNum} == NetFlowv5 ) {

		while ( $FlowCount < $NetFlowHeaderRef->{Count} ) {

			my $FlowRef = undef;

			( $FlowRef, $Error ) = &flow_decode( $NetFlowPktRef, \$OffSet, \%TemplateForNetFlowv5 );

			$FlowRef->{SetId} = undef;

			if ( defined $Error ) {

				push( @Errors, $Error );
				last;

			}

			$FlowCount++;
			push( @Flows, $FlowRef );

		}

		#
		# NetFlow version 8 Decode
		#

	} elsif ( $NetFlowHeaderRef->{VersionNum} == NetFlowv8 ) {

		$Error = 'ERROR : NOT SUPPORT NETFLOW VER.8';
		push( @Errors, $Error );

	} else {

		$Error = 'ERROR : NOT NETFLOW DATA';
		push( @Errors, $Error );

	}

	return ( $NetFlowHeaderRef, \@Template, \@Flows, \@Errors );

}
#################### END sub decode() ######################

#################### START sub search_template() ###########
sub search_template {
	my ( $TemplateId, $TemplatesArrayRef ) = @_;
	my $DecodeTemplateRef = undef;
	my $Error             = undef;

	( $DecodeTemplateRef, undef ) = grep { $_ if $_->{TemplateId} eq $TemplateId; } @{$TemplatesArrayRef};

	#
	# nothing template for flow data
	#

	unless ( defined $DecodeTemplateRef ) {
		$Error = "WARNING : NOT FOUND TEMPLATE=$TemplateId";
	}

	return ( $DecodeTemplateRef, $Error );

}

#################### START sub header_decode() #############
sub header_decode {
	my ( $NetFlowPktRef, $OffSetRef ) = @_;
	my %NetFlowHeader = ();
	my $error         = undef;

	#
	# Extract Version
	#

	( $NetFlowHeader{VersionNum} ) = unpack( 'n', $$NetFlowPktRef );

	$$OffSetRef += 2;

	if ( $NetFlowHeader{VersionNum} == IPFIX ) {

		( @NetFlowHeader{qw{Length UnixSecs SequenceNum ObservationDomainId}} ) = unpack( "x$$OffSetRef nN3", $$NetFlowPktRef );

		$$OffSetRef += 2 + 4 * 3;

	} elsif ( $NetFlowHeader{VersionNum} == NetFlowv9 ) {

		( @NetFlowHeader{qw{Count SysUpTime UnixSecs SequenceNum SourceId}} ) = unpack( "x$$OffSetRef nN4", $$NetFlowPktRef );

		$$OffSetRef += 2 + 4 * 4;

	} elsif ( $NetFlowHeader{VersionNum} == NetFlowv8 ) {
	} elsif ( $NetFlowHeader{VersionNum} == NetFlowv5 ) {

		my $Sampling = undef;

		(   @NetFlowHeader{
				qw{Count SysUpTime UnixSecs UnixNsecs FlowSequenceNum
					EngineType EngineId}
			},
			$Sampling
			)
			= unpack(
			"x$$OffSetRef nN4C2n",
			$$NetFlowPktRef
			);

		$NetFlowHeader{SamplingMode}     = $Sampling >> 14;
		$NetFlowHeader{SamplingInterval} = $Sampling & 0x3FFF;

		$$OffSetRef += 2 * 1 + 4 * 4 + 1 * 2 + 2 * 1;

	}

	return ( \%NetFlowHeader, $error );

}
#################### END sub header_decode() ###############

#################### START sub flowset_decode() ############
sub flowset_decode {
	my ( $NetFlowPktRef, $OffSetRef ) = @_;
	my %FlowSetHeader = ();
	my @errors        = ();
	my $error         = undef;

	( $FlowSetHeader{SetId}, $FlowSetHeader{Length} ) = unpack( "x$$OffSetRef n2", $$NetFlowPktRef );

	$$OffSetRef += 2 * 2;

	return ( \%FlowSetHeader );

}
#################### END sub flowset_decode() ##############

#################### START sub template_decode() ###########
sub template_decode {
	my ( $NetFlowPktRef, $OffSetRef, $FlowSetHeaderRef, $VerNumRef ) = @_;
	my %Template = ();
	my $error    = undef;

	$Template{SetId} = $FlowSetHeaderRef->{SetId};

	#
	# decode data template for NetFlow v9 or IPFIX
	#

	if (   $FlowSetHeaderRef->{SetId} == NFWV9_DataTemplateSetId
		|| $FlowSetHeaderRef->{SetId} == IPFIX_DataTemplateSetId ) {

		( @Template{qw{TemplateId FieldCount}} ) = unpack( "x$$OffSetRef n2", $$NetFlowPktRef );

		$$OffSetRef += 2 * 2;

		#
		# decode option template for IPFIX
		#

	} elsif ( $FlowSetHeaderRef->{SetId} == IPFIX_OptionTemplateSetId ) {

		( @Template{qw{TemplateId FieldCount}} ) = unpack( "x$$OffSetRef n2", $$NetFlowPktRef );

		$$OffSetRef += 2 * 2;

		#
		# template withdraw check
		#

		if ( $Template{FieldCount} != 0 ) {

			( $Template{ScopeCount} ) = unpack( "x$$OffSetRef n", $$NetFlowPktRef );
			$$OffSetRef += 2 * 1;

		}

		#
		# decode option template for NetFlow v9
		#

	} elsif ( $FlowSetHeaderRef->{SetId} == NFWV9_OptionTemplateSetId ) {

		( @Template{qw{TemplateId OptionScopeLength OptionLength}} ) = unpack( "x$$OffSetRef n3", $$NetFlowPktRef );

		$$OffSetRef += 2 * 3;

		$Template{FieldCount} = int( ( $Template{OptionScopeLength} + $Template{OptionLength} ) / 4 );

		$Template{ScopeCount} = int( ( $Template{OptionScopeLength} ) / 4 );

	}

	return ( undef, 'ERROR: No fieldcount' ) if ( !defined( $Template{FieldCount} ) );

	for ( my $n = 0; $n < $Template{FieldCount}; $n++ ) {

		if ( $FlowSetHeaderRef->{SetId} <= IPFIX_OptionTemplateSetId ) {

			( @{$Template{Template}->[$n]}{qw{Id Length}} ) = unpack( "x$$OffSetRef n2", $$NetFlowPktRef );
			$$OffSetRef += 2 * 2;

			#
			# check enterprise number
			#

			if ( $$VerNumRef >= 10 ) {

				if ( $Template{Template}->[$n]->{Id} & 0x8000 ) {

					$Template{Template}->[$n]->{Id} -= 0x8000;

					( $Template{Template}->[$n]->{EnterpriseNum} ) = unpack( "x$$OffSetRef N", $$NetFlowPktRef );

          # We have a PEN add it to the Id.
					$Template{Template}->[$n]->{Id} =
            join('.', @{$Template{Template}->[$n]}{qw{EnterpriseNum Id}});

					$$OffSetRef += 4;

				}

			}

		}

	}

	return ( \%Template, $error );

}
#################### END sub template_decode() #############

#################### START sub flow_decode() ###############
sub flow_decode {
	my ( $NetFlowPktRef, $OffSetRef, $TemplateRef ) = @_;
	my %Flow   = ();
	my $error  = undef;
	my $Length = undef;

	if ( defined $TemplateRef->{TemplateId} ) {

		$Flow{SetId} = $TemplateRef->{TemplateId};

	} else {

		$error = 'ERROR: NOT FOUND TEMPLATE ID';

	}

	foreach my $ref ( @{ $TemplateRef->{Template} } ) {

		#
		# Variable Length Type
		#

		if ( $ref->{Length} == VariableLength ) {

			$Length = unpack( "x$$OffSetRef C", $$NetFlowPktRef );

			$$OffSetRef++;

			if ( $Length == 255 ) {

				$Length = unpack( "x$$OffSetRef n", $$NetFlowPktRef );

				$$OffSetRef += 2;

			}

			#
			# Fixed Length Type
			#

		} else {

			$Length = $ref->{Length};

		}

		#
		# One Template has multiple same Ids.
		#

		if ( defined $Flow{ $ref->{Id} } ) {

			my $Value = unpack( "x$$OffSetRef a$Length", $$NetFlowPktRef );

			$Flow{ $ref->{Id} } = [ $Flow{ $ref->{Id} } ] unless ref $Flow{ $ref->{Id} };

			push( @{ $Flow{ $ref->{Id} } }, $Value );

			#
			# Each Id is different than others.
			#

		} else {

			$Flow{ $ref->{Id} } = unpack( "x$$OffSetRef a$Length", $$NetFlowPktRef );

		}

		$$OffSetRef += $Length;

	}

	return ( \%Flow, $error );

}
#################### END sub flow_decode() #################

1;

__END__

=head1 NAME


Net::Flow - decode and encode NetFlow/IPFIX datagrams.


=head1 SYNOPSIS

=head2 EXAMPLE#1 - Output Flow Records of NetFlow v5, v9 and IPFIX -

The following script simply outputs the received Flow Records after
decoding NetFlow/IPFIX datagrams. It can parse the NetFlow v5, v9 and
IPFIX. If it receive NetFlow v9/IPFIX datagrams, several Templates of
NetFlow/IPFIX can be kept as ARRAY reference $TemplateArrayRef. By
adding it as the input parameter, it can parse the NetFlow/IPFIX
datagrams without templates. If received Packet has same Template Id,
this Template is overwritten by new one.

use strict;
use warnings;

use Net::Flow qw(decode);
use Net::Flow::Constants qw(
	%informationElementsByName
	%informationElementsById
);
use IO::Socket::INET;

my $receive_port = 4739;				# IPFIX port
my $packet;
my %TemplateArrayRefs;
my $sock = IO::Socket::INET->new(
	LocalPort => $receive_port,
	Proto     => 'udp'
);

my $sender;
while ( $sender = $sock->recv( $packet, 0xFFFF ) ) {
	my ($sender_port, $sender_addr) = unpack_sockaddr_in($sender);
	$sender_addr = inet_ntoa($sender_addr);

	my ( $HeaderHashRef, $FlowArrayRef, $ErrorsArrayRef ) = ();

	# template ids are per src, destination, and observation domain.
	# Ideally the module will handle this, but the current API doesn't
	# really allow for this.  For now you are on your own.
	my ($version, $observationDomainId, $sourceId) = unpack('nx10N2', $packet);
	my $stream_id;
	if ($version == 9) {
		$stream_id = "$sender_port, $sender_addr, $sourceId";
	} else {
		$stream_id = "$sender_port, $sender_addr, $observationDomainId";
	}
	$TemplateArrayRefs{$stream_id} ||= [];
	my $TemplateArrayRef = $TemplateArrayRefs{$stream_id};
	( $HeaderHashRef, $TemplateArrayRef, $FlowArrayRef, $ErrorsArrayRef ) = Net::Flow::decode( \$packet, $TemplateArrayRef );

	grep { print "$_\n" } @{$ErrorsArrayRef} if ( @{$ErrorsArrayRef} );

	print "\n- Header Information -\n";
	foreach my $Key ( sort keys %{$HeaderHashRef} ) {
		printf ' %s = %3d' . "\n", $Key, $HeaderHashRef->{$Key};
	}

	foreach my $TemplateRef ( @{$TemplateArrayRef} ) {
		print "\n-- Template Information --\n";

		foreach my $TempKey ( sort keys %{$TemplateRef} ) {
			if ( $TempKey eq 'Template' ) {
				printf '  %s = ' . "\n", $TempKey;
				foreach my $Ref ( @{ $TemplateRef->{Template} } ) {
					foreach my $Key ( keys %{$Ref} ) {
						printf '   %s=%s', $Key, $Ref->{$Key};
					}
					print "\n";
				}
			} else {
				printf '  %s = %s' . "\n", $TempKey, $TemplateRef->{$TempKey};
			}
		}
	}

	foreach my $FlowRef ( @{$FlowArrayRef} ) {
		print "\n-- Flow Information --\n";

		foreach my $Id ( sort keys %{$FlowRef} ) {
			my $name = $informationElementsById{$Id}->{name} // "$Id";
			if ( $Id eq 'SetId' ) {
				print "  $Id=$FlowRef->{$Id}\n" if defined $FlowRef->{$Id};
			} elsif ( ref $FlowRef->{$Id} ) {
				printf '  Id=%s Value=', $name;
				foreach my $Value ( @{ $FlowRef->{$Id} } ) {
					printf '%s,', unpack( 'H*', $Value );
				}
				print "\n";
			} else {
				printf '  Id=%s Value=%s' . "\n", $name, unpack( 'H*', $FlowRef->{$Id} );
			}
		}
	}
}


1;

__END__


# Local Variables: ***
# mode:CPerl ***
# cperl-indent-level:2 ***
# perl-indent-level:2 ***
# tab-width: 2 ***
# indent-tabs-mode: t ***
# End: ***
#
# vim: ts=2 sw=2 noexpandtab


=head2 EXAMPLE#2 - Convert Protocol from NetFlow v5 to NetFlow v9 -

The following script converts NetFlow protocol from NetFlow v5 to
NetFlow v9 as converter. At first, it decodes NetFlow v5
datagram. After that, these flow records are encoded into NetFlow v9
according to the particular Template which include sampling interval
and sampling mode. And they are sent to the next Collector.

  use strict;
  use Net::Flow qw(decode encode);
  use IO::Socket::INET;

  my $receive_port = 9995;
  my $send_port    = 9996;

  my $packet        = undef;
  my $TemplateRef   = undef;
  my $MyTemplateRef = {
    'SetId'      => 0,
    'TemplateId' => 300,
    'Template'   => [
      { 'Length' => 4, 'Id' => 8  },    # sourceIPv4Address
      { 'Length' => 4, 'Id' => 12 },    # destinationIPv4Address
      { 'Length' => 4, 'Id' => 2  },    # packetDeltaCount
      { 'Length' => 4, 'Id' => 1  },    # octetDeltaCount
      { 'Length' => 2, 'Id' => 7  },    # sourceTransportPort
      { 'Length' => 2, 'Id' => 11 },    # destinationTransportPort
      { 'Length' => 1, 'Id' => 4  },    # protocolIdentifier
      { 'Length' => 1, 'Id' => 5  },    # ipClassOfService
      { 'Length' => 4, 'Id' => 34 },    # samplingInterval
      { 'Length' => 4, 'Id' => 35 },    # samplingAlgorithm
    ],
  };

  my @MyTemplates = ($MyTemplateRef);

  my $EncodeHeaderHashRef = {
    'SourceId'    => 0,         # optional
    'VersionNum'  => 9,
  };

  my $r_sock = IO::Socket::INET->new(
    LocalPort => $receive_port,
    Proto     => 'udp'
  );

  my $s_sock = IO::Socket::INET->new(
    PeerAddr => '127.0.0.1',
    PeerPort => $send_port,
    Proto    => 'udp'
  );

  while ( $r_sock->recv( $packet, 1548 ) ) {

    my $PktsArrayRef = undef;

    my ( $HeaderHashRef,
         undef,
         $FlowArrayRef,
         $ErrorsArrayRef )
      = Net::Flow::decode( \$packet, undef );

    grep { print "$_\n" } @{$ErrorsArrayRef} if ( @{$ErrorsArrayRef} );

    foreach my $HashRef ( @{$FlowArrayRef} ) {
      $HashRef->{"SetId"} = 300;
      $HashRef->{"34"} = pack( "N", $HeaderHashRef->{"SamplingInterval"} )
        if defined $HeaderHashRef->{"SamplingInterval"};
      $HashRef->{"35"} = pack( "N", $HeaderHashRef->{"SamplingMode"} )
        if defined $HeaderHashRef->{"SamplingMode"};
    }

    $EncodeHeaderHashRef->{"SysUpTime"} = $HeaderHashRef->{"SysUpTime"};
    $EncodeHeaderHashRef->{"UnixSecs"}  = $HeaderHashRef->{"UnixSecs"};

    ( $EncodeHeaderHashRef,
      $PktsArrayRef,
      $ErrorsArrayRef )
      = Net::Flow::encode( $EncodeHeaderHashRef, 
                           \@MyTemplates,
                           $FlowArrayRef,
                           1400 );

    grep { print "$_\n" } @{$ErrorsArrayRef} if ( @{$ErrorsArrayRef} );

    foreach my $Ref ( @{$PktsArrayRef} ) {
      $s_sock->send($$Ref);
    }

  }

=head1 DESCRIPTION

The Flow module provides the decoding function for NetFlow version 5,9
and IPFIX, and the encoding function for NetFlow version 9 and
IPFIX. It supports NetFlow version 9 (RFC3945) and NetFlow version 5
(http://www.cisco.com/) and IPFIX(RFC5101). You can easily make the
Flow Proxy, Protocol Converter and Flow Concentrator by using the
combination of both function, just like Flow Mediator (RFC6183). The
Mediator would have multiple functions by utilizing intermediate
process. And also, you can make the flexible Collector which can
receive any Templates by using the Storable perl module.

For standard information elements (ElementID, Name, Data Type, Data
Type Semantics, and Description) see
http://www.iana.org/assignments/ipfix/ipfix.xml

=head2 Important Note

Version 1.000 may break code that relies (or works around) the
previously broken encoding of IPFIX options templates.  NetFlow
version 9 is not affected by this change.  The semantics for
ScopeCount are now consistent when encoding v9 or IPFIX.


=head1 FUNCTIONS

=head2 decode method

  ( $HeaderHashRef,
    $TemplateArrayRef,
    $FlowArrayRef,
    $ErrorsArrayRef ) =
  Net::Flow::decode( \$Packets, $InputTemplateArrayRef );

It returns a HASH reference containing the NetFlow/IPFIX Header
information as $HeaderHashRef. And it returns ARRAY references with
the Template and Flow Record (each ARRAY element contains a HASH
reference for one Template or Flow Record) as $TemplateArrayRef or
$FlowArrayRef. In case of an error a reference to an ARRAY containing
the error messages is returned as $ErrorsArrayRef. The returned
$TemplateArrayRef can be input on the next received packet which
doesn't contain Template to decode it.

=head3 Return Values

=over 4

=item I<$HeaderHashRef>

A HASH reference containing information in case of IPFIX header, with
the following keys:

  "VersionNum"
  "Length"
  "UnixSecs"
  "SequenceNum"
  "ObservationDomainId"

A HASH reference containing information in case of NetFlow v9 header,
with the following keys:

  "VersionNum"
  "Count"
  "SysUpTime"
  "UnixSecs"
  "SequenceNum"
  "SourceId"

A HASH reference containing information in case of NetFlow v5 header,
with the following keys:

  "VersionNum"
  "Count"
  "SysUpTime"
  "UnixSecs"
  "UnixNsecs"
  "FlowSequenceNum"
  "EngineType"
  "EngineId"
  "SamplingMode"
  "SamplingInterval"

All values of above keys are shown as decimal.

The following addtional keys are also available
  "TemplateResendSecs"  # templates be resent at least this often (v9 and IPFIX)

TemplateResendSecs defaults to the old behavior of always sendng
template information.  A setting between 60 and 300 seconds is a
better interval for resending templates.

=item I<$TemplateArrayRef>

This ARRAY reference contains several Templates which are contained
input NetFlow/IPFIX packet and $InputTemplateArrayRef. Each Template
is given HASH references. This HASH reference provides Data Template
and Option Template, as follows.  A HASH reference containing
information in case of Data Template, with the following keys:

  "SetId"
  "TemplateId"
  "FieldCount"
  "Template"

A HASH reference containing information in case of Option Template,
with the following keys:

  "SetId"
  "TemplateId"
  "OptionScopeLength"
  "OptionLength"
  "FieldCount"
  "ScopeCount"
  "Template"

In case of IPFIX, "OptionScopeLength" and "OptionLength" are omitted.

In case of IPFIX, 0 value of "FieldCount" has a particular meaning. if
TemplateWithdrawMessage is received, "FieldCount" of corresponding
Template would become value of 0. A HASH reference containing
information in case of WithdrawTemplateMessage, with the following
keys:

  "SetId"
  "FieldCount"
  "TemplateId"

All values for above keys other than "Template" are shown as
decimal. The value for "Template" is a ARRAY references. Each ARRAY
element contains a HASH reference for one pair of "Id" and
"Length". This pair of "Id" and "Length" are shown as Field type. The
order of this ARRAY means the order of this Template to decode data. A
HASH reference containing information for each field type, with the
following keys:

  "Id"
  "Length"

If Enterprise Number is given in the IPFIX packets, the value of "Id"
is presented by concatenating string between the value of Enterprise
Number and the value of Information Element Id. For example, if
Enterprise Number is "3000" and Information Element Id is "100", the
value of "Id" becomes "3000.100". In case of IPFIX, 65535 value of
"Length" has a particular meaning. if "Length" is 65535, this field
type means variable length field. The length of field in each Flow
Record is different.

The values for "Length","TemplateId","FieldCount" are shown as decimal.

=item I<$FlowArrayRef>

This ARRAY reference contains several HASH references for each Flow
Record. This HASH reference provides Flow Record for Data Template and
Option Template, as follows. A HASH reference contains "SetId" and Ids
of Field type, as HASH key. The value for "SetId" is shown as decimal
which means decoded TemplateId. The "Id" number means Field type. The
value for "SetId" is shown as decimal. The value for "Id" number is
shown as binary data. The value of each field is directly extracted
from NetFlow/IPFIX packets without modification.

  "SetId"
  "Id"

If one Flow Record has multiple Fields of same type, the value for Id
number becomes a ARRAY references. Each ARRAY element is value shown
as binary data. The order of this ARRAY means the order of multiple
same Fields in one Flow Record.

=back

=head2 encode method

  ( undef, # $HeaderHashRef no longer necessary (see note)
    $PktsArrayRef,
    $ErrorsArrayRef )
    = Net::Flow::encode( $HeaderHashRef,
                         $TemplateArrayRef,
                         $FlowArrayRef,
                         $MaxSize,
                       );

Input parameters are same data structure returned from decode
function. "$MaxSize" means maximum payload size. This function make
several NetFlow payloads without exceeding the maximum size.

These values for the input $HeaderHashRef, such as "UnixSecs",
"SysUpTime","SourceId" and "ObservationDomainId", are used in this
method. The other values are ignored. These values for output
$HeaderHashRef means header information of the latest IPFIX/NetFlow
datagram.

NOTE (change in behavior starting with version 1.1):

encode used to return a modified copy of $HeaderHashRef.  Now
$HeaderHashRef is just modified in place.  $HeaderHashRef is still
returned, but it is already modified so there is no need to update it
again.  This change is intended to allow the module to more reliably
track.  If the old behavior is desired you can pass in a new anonymous
hashref from created from $HeaderHashRef like this {%$HeaderHashRef}.

=head3 Return Values

=over 4

=item I<$PktsArrayRef>

This ARRAY reference contains several SCALAR references for each
NetFlow datagram which is shown binary. It can be used as UDP
datagram.

=back

=head1 BUGS

Managing of flow streams is left to the user.

=head1 AUTHOR

Atsushi Kobayashi <akoba@nttv6.net>
http://www3.plala.or.jp/akoba/

Let me know your flow-based measurement system using Net::Flow.

=head1 MAINTAINER

Andrew Feren <acferen@gmail.com>

Let me know your flow-based measurement system using Net::Flow.

=head1 CONTRIBUTIONS

The source code since version 0.05 can be found on Github:

https://github.com/acferen/Net-Flow.git

Anyone interested in contributing is encouraged to submit patches.

=head1 ACKNOWLEDGMENTS

This perl module was supported by the Ministry of Internal Affairs and
Communications of Japan.

In the considerations of variable length fields, I have received
support from Philip Gladstone.

Thanks to Plixer International for their support.

=head1 COPYRIGHT

Copyright (c) 2007-2008 NTT Information Sharing Platform Laboratories

This package is free software and is provided "as is" without express
or implied warranty.  This library is free software; you can
redistribute it and/or modify it under the same terms as Perl itself,
either Perl version 5.8.8 or, at your option, any later version of
Perl 5 you may have available.

=cut

1;

__END__


# Local Variables: ***
# mode:CPerl ***
# cperl-indent-level:2 ***
# perl-indent-level:2 ***
# tab-width: 2 ***
# indent-tabs-mode: nil ***
# End: ***
#
# vim: ts=2 sw=2 expandtab
