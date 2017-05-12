#<fix major=>"4" minor=>"4">

package PFIX::FIX44;

use strict;
use warnings;

use Data::Dumper;

my $fix44;

sub getFix() {
	return $fix44;
}

BEGIN {
	print "BEGIN block of PFIX::FIX44\n";
	$fix44 = {
		header => [
			{ name => "BeginString",            required => "Y" },
			{ name => "BodyLength",             required => "Y" },
			{ name => "MsgType",                required => "Y" },
			{ name => "SenderCompID",           required => "Y" },
			{ name => "TargetCompID",           required => "Y" },
			{ name => "OnBehalfOfCompID",       required => "N" },
			{ name => "DeliverToCompID",        required => "N" },
			{ name => "SecureDataLen",          required => "N" },
			{ name => "SecureData",             required => "N" },
			{ name => "MsgSeqNum",              required => "Y" },
			{ name => "SenderSubID",            required => "N" },
			{ name => "SenderLocationID",       required => "N" },
			{ name => "TargetSubID",            required => "N" },
			{ name => "TargetLocationID",       required => "N" },
			{ name => "OnBehalfOfSubID",        required => "N" },
			{ name => "OnBehalfOfLocationID",   required => "N" },
			{ name => "DeliverToSubID",         required => "N" },
			{ name => "DeliverToLocationID",    required => "N" },
			{ name => "PossDupFlag",            required => "N" },
			{ name => "PossResend",             required => "N" },
			{ name => "SendingTime",            required => "Y" },
			{ name => "OrigSendingTime",        required => "N" },
			{ name => "XmlDataLen",             required => "N" },
			{ name => "XmlData",                required => "N" },
			{ name => "MessageEncoding",        required => "N" },
			{ name => "LastMsgSeqNumProcessed", required => "N" },
			{
				name     => "NoHops",
				required => "N",
				group    => [
					{ name => "HopCompID",      required => "N" },
					{ name => "HopSendingTime", required => "N" },
					{ name => "HopRefID",       required => "N" }
				]
			}
		],

		trailer => [
			{ name => "SignatureLength", required => "N" },
			{ name => "Signature",       required => "N" },
			{ name => "CheckSum",        required => "Y" }
		],

		messages => [
			{
				name    => "Heartbeat",
				msgtype => "0",
				msgcat  => "admin",
				fields  => [ { name => "TestReqID", required => "N" } ]
			},
			{
				name    => "Logon",
				msgtype => "A",
				msgcat  => "admin",
				fields  => [
					{ name => "EncryptMethod",         required => "Y" },
					{ name => "HeartBtInt",            required => "Y" },
					{ name => "RawDataLength",         required => "N" },
					{ name => "RawData",               required => "N" },
					{ name => "ResetSeqNumFlag",       required => "N" },
					{ name => "NextExpectedMsgSeqNum", required => "N" },
					{ name => "MaxMessageSize",        required => "N" },
					{
						name     => "NoMsgTypes",
						required => "N",
						group    => [
							{ name => "RefMsgType",   required => "N" },
							{ name => "MsgDirection", required => "N" }
						]
					},
					{ name => "TestMessageIndicator", required => "N" },
					{ name => "Username",             required => "N" },
					{ name => "Password",             required => "N" }
				]
			},
			{
				name    => "TestRequest",
				msgtype => "1",
				msgcat  => "admin",
				fields  => [ { name => "TestReqID", required => "Y" }, ]
			},
			{
				name    => "ResendRequest",
				msgtype => "2",
				msgcat  => "admin",
				fields  => [
					{ name => "BeginSeqNo", required => "Y" },
					{ name => "EndSeqNo",   required => "Y" },
				]
			},
			{
				name    => "Reject",
				msgtype => "3",
				msgcat  => "admin",
				fields  => [
					{ name => "RefSeqNum",           required => "Y" },
					{ name => "RefTagID",            required => "N" },
					{ name => "RefMsgType",          required => "N" },
					{ name => "SessionRejectReason", required => "N" },
					{ name => "Text",                required => "N" },
					{ name => "EncodedTextLen",      required => "N" },
					{ name => "EncodedText",         required => "N" },
				]
			},
			{
				name    => "SequenceReset",
				msgtype => "4",
				msgcat  => "admin",
				fields  => [
					{ name => "GapFillFlag", required => "N" },
					{ name => "NewSeqNo",    required => "Y" },
				]
			},
			{
				name    => "Logout",
				msgtype => "5",
				msgcat  => "admin",
				fields  => [
					{ name => "Text",           required => "N" },
					{ name => "EncodedTextLen", required => "N" },
					{ name => "EncodedText",    required => "N" },
				]
			},
			{
				name    => "BusinessMessageReject",
				msgtype => "j",
				msgcat  => "app",
				fields  => [
					{ name => "RefSeqNum",            required => "N" },
					{ name => "RefMsgType",           required => "Y" },
					{ name => "BusinessRejectRefID",  required => "N" },
					{ name => "BusinessRejectReason", required => "Y" },
					{ name => "Text",                 required => "N" },
					{ name => "EncodedTextLen",       required => "N" },
					{ name => "EncodedText",          required => "N" },
				]
			},
			{
				name    => "UserRequest",
				msgtype => "BE",
				msgcat  => "app",
				fields  => [
					{ name => "UserRequestID",   required => "Y" },
					{ name => "UserRequestType", required => "Y" },
					{ name => "Username",        required => "Y" },
					{ name => "Password",        required => "N" },
					{ name => "NewPassword",     required => "N" },
					{ name => "RawDataLength",   required => "N" },
					{ name => "RawData",         required => "N" },
				]
			},
			{
				name    => "UserResponse",
				msgtype => "BF",
				msgcat  => "app",
				fields  => [
					{ name => "UserRequestID",  required => "Y" },
					{ name => "Username",       required => "Y" },
					{ name => "UserStatus",     required => "N" },
					{ name => "UserStatusText", required => "N" },
				]
			},
			{
				name    => "Advertisement",
				msgtype => "7",
				msgcat  => "app",
				fields  => [
					{ name => "AdvId",        required => "Y" },
					{ name => "AdvTransType", required => "Y" },
					{ name => "AdvRefID",     required => "N" },
					{
						name      => "Instrument",
						required  => "Y",
						component => "Y"
					},
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "Y",
								component => "Y"
							},
						]
					},
					{ name => "AdvSide",             required => "Y" },
					{ name => "Quantity",            required => "Y" },
					{ name => "QtyType",             required => "N" },
					{ name => "Price",               required => "N" },
					{ name => "Currency",            required => "N" },
					{ name => "TradeDate",           required => "N" },
					{ name => "TransactTime",        required => "N" },
					{ name => "Text",                required => "N" },
					{ name => "EncodedTextLen",      required => "N" },
					{ name => "EncodedText",         required => "N" },
					{ name => "URLLink",             required => "N" },
					{ name => "LastMkt",             required => "N" },
					{ name => "TradingSessionID",    required => "N" },
					{ name => "TradingSessionSubID", required => "N" },
				]
			},
			{
				name    => "IndicationOfInterest",
				msgtype => "6",
				msgcat  => "app",
				fields  => [
					{ name => "IOIid",        required => "Y" },
					{ name => "IOITransType", required => "Y" },
					{ name => "IOIRefID",     required => "N" },
					{
						name      => "Instrument",
						required  => "Y",
						component => "Y"
					},
					{
						name      => "FinancingDetails",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "Side",    required => "Y" },
					{ name => "QtyType", required => "N" },
					{
						name      => "OrderQtyData",
						required  => "N",
						component => "Y"
					},
					{ name => "IOIQty",   required => "Y" },
					{ name => "Currency", required => "N" },
					{
						name      => "Stipulations",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
							{ name => "LegIOIQty", required => "N" },
							{
								name      => "LegStipulations",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "PriceType",      required => "N" },
					{ name => "Price",          required => "N" },
					{ name => "ValidUntilTime", required => "N" },
					{ name => "IOIQltyInd",     required => "N" },
					{ name => "IOINaturalFlag", required => "N" },
					{
						name     => "NoIOIQualifiers",
						required => "N",
						group =>
						  [ { name => "IOIQualifier", required => "N" }, ]
					},
					{ name => "Text",           required => "N" },
					{ name => "EncodedTextLen", required => "N" },
					{ name => "EncodedText",    required => "N" },
					{ name => "TransactTime",   required => "N" },
					{ name => "URLLink",        required => "N" },
					{
						name     => "NoRoutingIDs",
						required => "N",
						group    => [
							{ name => "RoutingType", required => "N" },
							{ name => "RoutingID",   required => "N" },
						]
					},
					{
						name      => "SpreadOrBenchmarkCurveData",
						required  => "N",
						component => "Y"
					},
					{
						name      => "YieldData",
						required  => "N",
						component => "Y"
					},
				]
			},
			{
				name    => "News",
				msgtype => "B",
				msgcat  => "app",
				fields  => [
					{ name => "OrigTime",           required => "N" },
					{ name => "Urgency",            required => "N" },
					{ name => "Headline",           required => "Y" },
					{ name => "EncodedHeadlineLen", required => "N" },
					{ name => "EncodedHeadline",    required => "N" },
					{
						name     => "NoRoutingIDs",
						required => "N",
						group    => [
							{ name => "RoutingType", required => "N" },
							{ name => "RoutingID",   required => "N" },
						]
					},
					{
						name     => "NoRelatedSym",
						required => "N",
						group    => [
							{
								name      => "Instrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name     => "LinesOfText",
						required => "Y",
						group    => [
							{ name => "Text",           required => "Y" },
							{ name => "EncodedTextLen", required => "N" },
							{ name => "EncodedText",    required => "N" },
						]
					},
					{ name => "URLLink",       required => "N" },
					{ name => "RawDataLength", required => "N" },
					{ name => "RawData",       required => "N" },
				]
			},
			{
				name    => "Email",
				msgtype => "C",
				msgcat  => "app",
				fields  => [
					{ name => "EmailThreadID",     required => "Y" },
					{ name => "EmailType",         required => "Y" },
					{ name => "OrigTime",          required => "N" },
					{ name => "Subject",           required => "Y" },
					{ name => "EncodedSubjectLen", required => "N" },
					{ name => "EncodedSubject",    required => "N" },
					{
						name     => "NoRoutingIDs",
						required => "N",
						group    => [
							{ name => "RoutingType", required => "N" },
							{ name => "RoutingID",   required => "N" },
						]
					},
					{
						name     => "NoRelatedSym",
						required => "N",
						group    => [
							{
								name      => "Instrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "OrderID", required => "N" },
					{ name => "ClOrdID", required => "N" },
					{
						name     => "LinesOfText",
						required => "Y",
						group    => [
							{ name => "Text",           required => "Y" },
							{ name => "EncodedTextLen", required => "N" },
							{ name => "EncodedText",    required => "N" },
						]
					},
					{ name => "RawDataLength", required => "N" },
					{ name => "RawData",       required => "N" },
				]
			},
			{
				name    => "QuoteRequest",
				msgtype => "R",
				msgcat  => "app",
				fields  => [
					{ name => "QuoteReqID",    required => "Y" },
					{ name => "RFQReqID",      required => "N" },
					{ name => "ClOrdID",       required => "N" },
					{ name => "OrderCapacity", required => "N" },
					{
						name     => "NoRelatedSym",
						required => "Y",
						group    => [
							{
								name      => "Instrument",
								required  => "Y",
								component => "Y"
							},
							{
								name      => "FinancingDetails",
								required  => "N",
								component => "Y"
							},
							{
								name     => "NoUnderlyings",
								required => "N",
								group    => [
									{
										name      => "UnderlyingInstrument",
										required  => "N",
										component => "Y"
									},
								]
							},
							{ name => "PrevClosePx",      required => "N" },
							{ name => "QuoteRequestType", required => "N" },
							{ name => "QuoteType",        required => "N" },
							{ name => "TradingSessionID", required => "N" },
							{
								name     => "TradingSessionSubID",
								required => "N"
							},
							{
								name     => "TradeOriginationDate",
								required => "N"
							},
							{ name => "Side",    required => "N" },
							{ name => "QtyType", required => "N" },
							{
								name      => "OrderQtyData",
								required  => "N",
								component => "Y"
							},
							{ name => "SettlType",  required => "N" },
							{ name => "SettlDate",  required => "N" },
							{ name => "SettlDate2", required => "N" },
							{ name => "OrderQty2",  required => "N" },
							{ name => "Currency",   required => "N" },
							{
								name      => "Stipulations",
								required  => "N",
								component => "Y"
							},
							{ name => "Account",      required => "N" },
							{ name => "AcctIDSource", required => "N" },
							{ name => "AccountType",  required => "N" },
							{
								name     => "NoLegs",
								required => "N",
								group    => [
									{
										name      => "InstrumentLeg",
										required  => "N",
										component => "Y"
									},
									{ name => "LegQty", required => "N" },
									{
										name     => "LegSwapType",
										required => "N"
									},
									{
										name     => "LegSettlType",
										required => "N"
									},
									{
										name     => "LegSettlDate",
										required => "N"
									},
									{
										name      => "LegStipulations",
										required  => "N",
										component => "Y"
									},
									{
										name      => "NestedParties",
										required  => "N",
										component => "Y"
									},
									{
										name      => "LegBenchmarkCurveData",
										required  => "N",
										component => "Y"
									},
								]
							},
							{
								name     => "NoQuoteQualifiers",
								required => "N",
								group    => [
									{
										name     => "QuoteQualifier",
										required => "N"
									},
								]
							},
							{ name => "QuotePriceType", required => "N" },
							{ name => "OrdType",        required => "N" },
							{ name => "ValidUntilTime", required => "N" },
							{ name => "ExpireTime",     required => "N" },
							{ name => "TransactTime",   required => "N" },
							{
								name      => "SpreadOrBenchmarkCurveData",
								required  => "N",
								component => "Y"
							},
							{ name => "PriceType", required => "N" },
							{ name => "Price",     required => "N" },
							{ name => "Price2",    required => "N" },
							{
								name      => "YieldData",
								required  => "N",
								component => "Y"
							},
							{
								name      => "Parties",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "Text",           required => "N" },
					{ name => "EncodedTextLen", required => "N" },
					{ name => "EncodedText",    required => "N" },
				]
			},
			{
				name    => "QuoteResponse",
				msgtype => "AJ",
				msgcat  => "app",
				fields  => [
					{ name => "QuoteRespID",   required => "Y" },
					{ name => "QuoteID",       required => "N" },
					{ name => "QuoteRespType", required => "Y" },
					{ name => "ClOrdID",       required => "N" },
					{ name => "OrderCapacity", required => "N" },
					{ name => "IOIid",         required => "N" },
					{ name => "QuoteType",     required => "N" },
					{
						name     => "NoQuoteQualifiers",
						required => "N",
						group =>
						  [ { name => "QuoteQualifier", required => "N" }, ]
					},
					{ name => "Parties", required => "N", component => "Y" },
					{ name => "TradingSessionID",    required => "N" },
					{ name => "TradingSessionSubID", required => "N" },
					{
						name      => "Instrument",
						required  => "Y",
						component => "Y"
					},
					{
						name      => "FinancingDetails",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "Side", required => "N" },
					{
						name      => "OrderQtyData",
						required  => "N",
						component => "Y"
					},
					{ name => "SettlType",  required => "N" },
					{ name => "SettlDate",  required => "N" },
					{ name => "SettlDate2", required => "N" },
					{ name => "OrderQty2",  required => "N" },
					{ name => "Currency",   required => "N" },
					{
						name      => "Stipulations",
						required  => "N",
						component => "Y"
					},
					{ name => "Account",      required => "N" },
					{ name => "AcctIDSource", required => "N" },
					{ name => "AccountType",  required => "N" },
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
							{ name => "LegQty",       required => "N" },
							{ name => "LegSwapType",  required => "N" },
							{ name => "LegSettlType", required => "N" },
							{ name => "LegSettlDate", required => "N" },
							{
								name      => "LegStipulations",
								required  => "N",
								component => "Y"
							},
							{
								name      => "NestedParties",
								required  => "N",
								component => "Y"
							},
							{ name => "LegPriceType", required => "N" },
							{ name => "LegBidPx",     required => "N" },
							{ name => "LegOfferPx",   required => "N" },
							{
								name      => "LegBenchmarkCurveData",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "BidPx",                required => "N" },
					{ name => "OfferPx",              required => "N" },
					{ name => "MktBidPx",             required => "N" },
					{ name => "MktOfferPx",           required => "N" },
					{ name => "MinBidSize",           required => "N" },
					{ name => "BidSize",              required => "N" },
					{ name => "MinOfferSize",         required => "N" },
					{ name => "OfferSize",            required => "N" },
					{ name => "ValidUntilTime",       required => "N" },
					{ name => "BidSpotRate",          required => "N" },
					{ name => "OfferSpotRate",        required => "N" },
					{ name => "BidForwardPoints",     required => "N" },
					{ name => "OfferForwardPoints",   required => "N" },
					{ name => "MidPx",                required => "N" },
					{ name => "BidYield",             required => "N" },
					{ name => "MidYield",             required => "N" },
					{ name => "OfferYield",           required => "N" },
					{ name => "TransactTime",         required => "N" },
					{ name => "OrdType",              required => "N" },
					{ name => "BidForwardPoints2",    required => "N" },
					{ name => "OfferForwardPoints2",  required => "N" },
					{ name => "SettlCurrBidFxRate",   required => "N" },
					{ name => "SettlCurrOfferFxRate", required => "N" },
					{ name => "SettlCurrFxRateCalc",  required => "N" },
					{ name => "Commission",           required => "N" },
					{ name => "CommType",             required => "N" },
					{ name => "CustOrderCapacity",    required => "N" },
					{ name => "ExDestination",        required => "N" },
					{ name => "Text",                 required => "N" },
					{ name => "EncodedTextLen",       required => "N" },
					{ name => "EncodedText",          required => "N" },
					{ name => "Price",                required => "N" },
					{ name => "PriceType",            required => "N" },
					{
						name      => "SpreadOrBenchmarkCurveData",
						required  => "N",
						component => "Y"
					},
					{
						name      => "YieldData",
						required  => "N",
						component => "Y"
					},
				]
			},
			{
				name    => "QuoteRequestReject",
				msgtype => "AG",
				msgcat  => "app",
				fields  => [
					{ name => "QuoteReqID",               required => "Y" },
					{ name => "RFQReqID",                 required => "N" },
					{ name => "QuoteRequestRejectReason", required => "Y" },
					{
						name     => "NoRelatedSym",
						required => "Y",
						group    => [
							{
								name      => "Instrument",
								required  => "Y",
								component => "Y"
							},
							{
								name      => "FinancingDetails",
								required  => "N",
								component => "Y"
							},
							{
								name     => "NoUnderlyings",
								required => "N",
								group    => [
									{
										name      => "UnderlyingInstrument",
										required  => "N",
										component => "Y"
									},
								]
							},
							{ name => "PrevClosePx",      required => "N" },
							{ name => "QuoteRequestType", required => "N" },
							{ name => "QuoteType",        required => "N" },
							{ name => "TradingSessionID", required => "N" },
							{
								name     => "TradingSessionSubID",
								required => "N"
							},
							{
								name     => "TradeOriginationDate",
								required => "N"
							},
							{ name => "Side",    required => "N" },
							{ name => "QtyType", required => "N" },
							{
								name      => "OrderQtyData",
								required  => "N",
								component => "Y"
							},
							{ name => "SettlType",  required => "N" },
							{ name => "SettlDate",  required => "N" },
							{ name => "SettlDate2", required => "N" },
							{ name => "OrderQty2",  required => "N" },
							{ name => "Currency",   required => "N" },
							{
								name      => "Stipulations",
								required  => "N",
								component => "Y"
							},
							{ name => "Account",      required => "N" },
							{ name => "AcctIDSource", required => "N" },
							{ name => "AccountType",  required => "N" },
							{
								name     => "NoLegs",
								required => "N",
								group    => [
									{
										name      => "InstrumentLeg",
										required  => "N",
										component => "Y"
									},
									{ name => "LegQty", required => "N" },
									{
										name     => "LegSwapType",
										required => "N"
									},
									{
										name     => "LegSettlType",
										required => "N"
									},
									{
										name     => "LegSettlDate",
										required => "N"
									},
									{
										name      => "LegStipulations",
										required  => "N",
										component => "Y"
									},
									{
										name      => "NestedParties",
										required  => "N",
										component => "Y"
									},
									{
										name      => "LegBenchmarkCurveData",
										required  => "N",
										component => "Y"
									},
								]
							},
						]
					},
					{
						name     => "NoQuoteQualifiers",
						required => "N",
						group =>
						  [ { name => "QuoteQualifier", required => "N" }, ]
					},
					{ name => "QuotePriceType", required => "N" },
					{ name => "OrdType",        required => "N" },
					{ name => "ExpireTime",     required => "N" },
					{ name => "TransactTime",   required => "N" },
					{
						name      => "SpreadOrBenchmarkCurveData",
						required  => "N",
						component => "Y"
					},
					{ name => "PriceType", required => "N" },
					{ name => "Price",     required => "N" },
					{ name => "Price2",    required => "N" },
					{
						name      => "YieldData",
						required  => "N",
						component => "Y"
					},
					{ name => "Parties", required => "N", component => "Y" },
					{ name => "Text",    required => "N" },
					{ name => "EncodedTextLen", required => "N" },
					{ name => "EncodedText",    required => "N" },
				]
			},
			{
				name    => "RFQRequest",
				msgtype => "AH",
				msgcat  => "app",
				fields  => [
					{ name => "RFQReqID", required => "Y" },
					{
						name     => "NoRelatedSym",
						required => "Y",
						group    => [
							{
								name      => "Instrument",
								required  => "Y",
								component => "Y"
							},
							{
								name     => "NoUnderlyings",
								required => "N",
								group    => [
									{
										name      => "UnderlyingInstrument",
										required  => "N",
										component => "Y"
									},
								]
							},
							{
								name     => "NoLegs",
								required => "N",
								group    => [
									{
										name      => "InstrumentLeg",
										required  => "N",
										component => "Y"
									},
								]
							},
							{ name => "PrevClosePx",      required => "N" },
							{ name => "QuoteRequestType", required => "N" },
							{ name => "QuoteType",        required => "N" },
							{ name => "TradingSessionID", required => "N" },
							{
								name     => "TradingSessionSubID",
								required => "N"
							},
						]
					},
					{ name => "SubscriptionRequestType", required => "N" },
				]
			},
			{
				name    => "Quote",
				msgtype => "S",
				msgcat  => "app",
				fields  => [
					{ name => "QuoteReqID",  required => "N" },
					{ name => "QuoteID",     required => "Y" },
					{ name => "QuoteRespID", required => "N" },
					{ name => "QuoteType",   required => "N" },
					{
						name     => "NoQuoteQualifiers",
						required => "N",
						group =>
						  [ { name => "QuoteQualifier", required => "N" }, ]
					},
					{ name => "QuoteResponseLevel", required => "N" },
					{ name => "Parties", required => "N", component => "Y" },
					{ name => "TradingSessionID",    required => "N" },
					{ name => "TradingSessionSubID", required => "N" },
					{
						name      => "Instrument",
						required  => "Y",
						component => "Y"
					},
					{
						name      => "FinancingDetails",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "Side", required => "N" },
					{
						name      => "OrderQtyData",
						required  => "N",
						component => "Y"
					},
					{ name => "SettlType",  required => "N" },
					{ name => "SettlDate",  required => "N" },
					{ name => "SettlDate2", required => "N" },
					{ name => "OrderQty2",  required => "N" },
					{ name => "Currency",   required => "N" },
					{
						name      => "Stipulations",
						required  => "N",
						component => "Y"
					},
					{ name => "Account",      required => "N" },
					{ name => "AcctIDSource", required => "N" },
					{ name => "AccountType",  required => "N" },
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
							{ name => "LegQty",       required => "N" },
							{ name => "LegSwapType",  required => "N" },
							{ name => "LegSettlType", required => "N" },
							{ name => "LegSettlDate", required => "N" },
							{
								name      => "LegStipulations",
								required  => "N",
								component => "Y"
							},
							{
								name      => "NestedParties",
								required  => "N",
								component => "Y"
							},
							{ name => "LegPriceType", required => "N" },
							{ name => "LegBidPx",     required => "N" },
							{ name => "LegOfferPx",   required => "N" },
							{
								name      => "LegBenchmarkCurveData",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "BidPx",                required => "N" },
					{ name => "OfferPx",              required => "N" },
					{ name => "MktBidPx",             required => "N" },
					{ name => "MktOfferPx",           required => "N" },
					{ name => "MinBidSize",           required => "N" },
					{ name => "BidSize",              required => "N" },
					{ name => "MinOfferSize",         required => "N" },
					{ name => "OfferSize",            required => "N" },
					{ name => "ValidUntilTime",       required => "N" },
					{ name => "BidSpotRate",          required => "N" },
					{ name => "OfferSpotRate",        required => "N" },
					{ name => "BidForwardPoints",     required => "N" },
					{ name => "OfferForwardPoints",   required => "N" },
					{ name => "MidPx",                required => "N" },
					{ name => "BidYield",             required => "N" },
					{ name => "MidYield",             required => "N" },
					{ name => "OfferYield",           required => "N" },
					{ name => "TransactTime",         required => "N" },
					{ name => "OrdType",              required => "N" },
					{ name => "BidForwardPoints2",    required => "N" },
					{ name => "OfferForwardPoints2",  required => "N" },
					{ name => "SettlCurrBidFxRate",   required => "N" },
					{ name => "SettlCurrOfferFxRate", required => "N" },
					{ name => "SettlCurrFxRateCalc",  required => "N" },
					{ name => "CommType",             required => "N" },
					{ name => "Commission",           required => "N" },
					{ name => "CustOrderCapacity",    required => "N" },
					{ name => "ExDestination",        required => "N" },
					{ name => "OrderCapacity",        required => "N" },
					{ name => "PriceType",            required => "N" },
					{
						name      => "SpreadOrBenchmarkCurveData",
						required  => "N",
						component => "Y"
					},
					{
						name      => "YieldData",
						required  => "N",
						component => "Y"
					},
					{ name => "Text",           required => "N" },
					{ name => "EncodedTextLen", required => "N" },
					{ name => "EncodedText",    required => "N" },
				]
			},
			{
				name    => "QuoteCancel",
				msgtype => "Z",
				msgcat  => "app",
				fields  => [
					{ name => "QuoteReqID",         required => "N" },
					{ name => "QuoteID",            required => "Y" },
					{ name => "QuoteCancelType",    required => "Y" },
					{ name => "QuoteResponseLevel", required => "N" },
					{ name => "Parties", required => "N", component => "Y" },
					{ name => "Account", required => "N" },
					{ name => "AcctIDSource",        required => "N" },
					{ name => "AccountType",         required => "N" },
					{ name => "TradingSessionID",    required => "N" },
					{ name => "TradingSessionSubID", required => "N" },
					{
						name     => "NoQuoteEntries",
						required => "N",
						group    => [
							{
								name      => "Instrument",
								required  => "N",
								component => "Y"
							},
							{
								name      => "FinancingDetails",
								required  => "N",
								component => "Y"
							},
							{
								name     => "NoUnderlyings",
								required => "N",
								group    => [
									{
										name      => "UnderlyingInstrument",
										required  => "N",
										component => "Y"
									},
								]
							},
							{
								name     => "NoLegs",
								required => "N",
								group    => [
									{
										name      => "InstrumentLeg",
										required  => "N",
										component => "Y"
									},
								]
							},
						]
					},
				]
			},
			{
				name    => "QuoteStatusRequest",
				msgtype => "a",
				msgcat  => "app",
				fields  => [
					{ name => "QuoteStatusReqID", required => "N" },
					{ name => "QuoteID",          required => "N" },
					{
						name      => "Instrument",
						required  => "Y",
						component => "Y"
					},
					{
						name      => "FinancingDetails",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "Parties", required => "N", component => "Y" },
					{ name => "Account", required => "N" },
					{ name => "AcctIDSource",            required => "N" },
					{ name => "AccountType",             required => "N" },
					{ name => "TradingSessionID",        required => "N" },
					{ name => "TradingSessionSubID",     required => "N" },
					{ name => "SubscriptionRequestType", required => "N" },
				]
			},
			{
				name    => "QuoteStatusReport",
				msgtype => "AI",
				msgcat  => "app",
				fields  => [
					{ name => "QuoteStatusReqID", required => "N" },
					{ name => "QuoteReqID",       required => "N" },
					{ name => "QuoteID",          required => "Y" },
					{ name => "QuoteRespID",      required => "N" },
					{ name => "QuoteType",        required => "N" },
					{ name => "Parties", required => "N", component => "Y" },
					{ name => "TradingSessionID",    required => "N" },
					{ name => "TradingSessionSubID", required => "N" },
					{
						name      => "Instrument",
						required  => "Y",
						component => "Y"
					},
					{
						name      => "FinancingDetails",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "Side", required => "N" },
					{
						name      => "OrderQtyData",
						required  => "N",
						component => "Y"
					},
					{ name => "SettlType",  required => "N" },
					{ name => "SettlDate",  required => "N" },
					{ name => "SettlDate2", required => "N" },
					{ name => "OrderQty2",  required => "N" },
					{ name => "Currency",   required => "N" },
					{
						name      => "Stipulations",
						required  => "N",
						component => "Y"
					},
					{ name => "Account",      required => "N" },
					{ name => "AcctIDSource", required => "N" },
					{ name => "AccountType",  required => "N" },
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
							{ name => "LegQty",       required => "N" },
							{ name => "LegSwapType",  required => "N" },
							{ name => "LegSettlType", required => "N" },
							{ name => "LegSettlDate", required => "N" },
							{
								name      => "LegStipulations",
								required  => "N",
								component => "Y"
							},
							{
								name      => "NestedParties",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name     => "NoQuoteQualifiers",
						required => "N",
						group =>
						  [ { name => "QuoteQualifier", required => "N" }, ]
					},
					{ name => "ExpireTime", required => "N" },
					{ name => "Price",      required => "N" },
					{ name => "PriceType",  required => "N" },
					{
						name      => "SpreadOrBenchmarkCurveData",
						required  => "N",
						component => "Y"
					},
					{
						name      => "YieldData",
						required  => "N",
						component => "Y"
					},
					{ name => "BidPx",                required => "N" },
					{ name => "OfferPx",              required => "N" },
					{ name => "MktBidPx",             required => "N" },
					{ name => "MktOfferPx",           required => "N" },
					{ name => "MinBidSize",           required => "N" },
					{ name => "BidSize",              required => "N" },
					{ name => "MinOfferSize",         required => "N" },
					{ name => "OfferSize",            required => "N" },
					{ name => "ValidUntilTime",       required => "N" },
					{ name => "BidSpotRate",          required => "N" },
					{ name => "OfferSpotRate",        required => "N" },
					{ name => "BidForwardPoints",     required => "N" },
					{ name => "OfferForwardPoints",   required => "N" },
					{ name => "MidPx",                required => "N" },
					{ name => "BidYield",             required => "N" },
					{ name => "MidYield",             required => "N" },
					{ name => "OfferYield",           required => "N" },
					{ name => "TransactTime",         required => "N" },
					{ name => "OrdType",              required => "N" },
					{ name => "BidForwardPoints2",    required => "N" },
					{ name => "OfferForwardPoints2",  required => "N" },
					{ name => "SettlCurrBidFxRate",   required => "N" },
					{ name => "SettlCurrOfferFxRate", required => "N" },
					{ name => "SettlCurrFxRateCalc",  required => "N" },
					{ name => "CommType",             required => "N" },
					{ name => "Commission",           required => "N" },
					{ name => "CustOrderCapacity",    required => "N" },
					{ name => "ExDestination",        required => "N" },
					{ name => "QuoteStatus",          required => "N" },
					{ name => "Text",                 required => "N" },
					{ name => "EncodedTextLen",       required => "N" },
					{ name => "EncodedText",          required => "N" },
				]
			},
			{
				name    => "MassQuote",
				msgtype => "i",
				msgcat  => "app",
				fields  => [
					{ name => "QuoteReqID",         required => "N" },
					{ name => "QuoteID",            required => "Y" },
					{ name => "QuoteType",          required => "N" },
					{ name => "QuoteResponseLevel", required => "N" },
					{ name => "Parties", required => "N", component => "Y" },
					{ name => "Account", required => "N" },
					{ name => "AcctIDSource", required => "N" },
					{ name => "AccountType",  required => "N" },
					{ name => "DefBidSize",   required => "N" },
					{ name => "DefOfferSize", required => "N" },
					{
						name     => "NoQuoteSets",
						required => "Y",
						group    => [
							{ name => "QuoteSetID", required => "Y" },
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
							{
								name     => "QuoteSetValidUntilTime",
								required => "N"
							},
							{ name => "TotNoQuoteEntries", required => "Y" },
							{ name => "LastFragment",      required => "N" },
							{
								name     => "NoQuoteEntries",
								required => "Y",
								group    => [
									{
										name     => "QuoteEntryID",
										required => "Y"
									},
									{
										name      => "Instrument",
										required  => "N",
										component => "Y"
									},
									{
										name     => "NoLegs",
										required => "N",
										group    => [
											{
												name      => "InstrumentLeg",
												required  => "N",
												component => "Y"
											},
										]
									},
									{ name => "BidPx",     required => "N" },
									{ name => "OfferPx",   required => "N" },
									{ name => "BidSize",   required => "N" },
									{ name => "OfferSize", required => "N" },
									{
										name     => "ValidUntilTime",
										required => "N"
									},
									{
										name     => "BidSpotRate",
										required => "N"
									},
									{
										name     => "OfferSpotRate",
										required => "N"
									},
									{
										name     => "BidForwardPoints",
										required => "N"
									},
									{
										name     => "OfferForwardPoints",
										required => "N"
									},
									{ name => "MidPx",      required => "N" },
									{ name => "BidYield",   required => "N" },
									{ name => "MidYield",   required => "N" },
									{ name => "OfferYield", required => "N" },
									{
										name     => "TransactTime",
										required => "N"
									},
									{
										name     => "TradingSessionID",
										required => "N"
									},
									{
										name     => "TradingSessionSubID",
										required => "N"
									},
									{ name => "SettlDate",  required => "N" },
									{ name => "OrdType",    required => "N" },
									{ name => "SettlDate2", required => "N" },
									{ name => "OrderQty2",  required => "N" },
									{
										name     => "BidForwardPoints2",
										required => "N"
									},
									{
										name     => "OfferForwardPoints2",
										required => "N"
									},
									{ name => "Currency", required => "N" },
								]
							},
						]
					},
				]
			},
			{
				name    => "MassQuoteAcknowledgement",
				msgtype => "b",
				msgcat  => "app",
				fields  => [
					{ name => "QuoteReqID",         required => "N" },
					{ name => "QuoteID",            required => "N" },
					{ name => "QuoteStatus",        required => "Y" },
					{ name => "QuoteRejectReason",  required => "N" },
					{ name => "QuoteResponseLevel", required => "N" },
					{ name => "QuoteType",          required => "N" },
					{ name => "Parties", required => "N", component => "Y" },
					{ name => "Account", required => "N" },
					{ name => "AcctIDSource",   required => "N" },
					{ name => "AccountType",    required => "N" },
					{ name => "Text",           required => "N" },
					{ name => "EncodedTextLen", required => "N" },
					{ name => "EncodedText",    required => "N" },
					{
						name     => "NoQuoteSets",
						required => "N",
						group    => [
							{ name => "QuoteSetID", required => "N" },
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
							{ name => "TotNoQuoteEntries", required => "N" },
							{ name => "LastFragment",      required => "N" },
							{
								name     => "NoQuoteEntries",
								required => "N",
								group    => [
									{
										name     => "QuoteEntryID",
										required => "N"
									},
									{
										name      => "Instrument",
										required  => "N",
										component => "Y"
									},
									{
										name     => "NoLegs",
										required => "N",
										group    => [
											{
												name      => "InstrumentLeg",
												required  => "N",
												component => "Y"
											},
										]
									},
									{ name => "BidPx",     required => "N" },
									{ name => "OfferPx",   required => "N" },
									{ name => "BidSize",   required => "N" },
									{ name => "OfferSize", required => "N" },
									{
										name     => "ValidUntilTime",
										required => "N"
									},
									{
										name     => "BidSpotRate",
										required => "N"
									},
									{
										name     => "OfferSpotRate",
										required => "N"
									},
									{
										name     => "BidForwardPoints",
										required => "N"
									},
									{
										name     => "OfferForwardPoints",
										required => "N"
									},
									{ name => "MidPx",      required => "N" },
									{ name => "BidYield",   required => "N" },
									{ name => "MidYield",   required => "N" },
									{ name => "OfferYield", required => "N" },
									{
										name     => "TransactTime",
										required => "N"
									},
									{
										name     => "TradingSessionID",
										required => "N"
									},
									{
										name     => "TradingSessionSubID",
										required => "N"
									},
									{ name => "SettlDate",  required => "N" },
									{ name => "OrdType",    required => "N" },
									{ name => "SettlDate2", required => "N" },
									{ name => "OrderQty2",  required => "N" },
									{
										name     => "BidForwardPoints2",
										required => "N"
									},
									{
										name     => "OfferForwardPoints2",
										required => "N"
									},
									{ name => "Currency", required => "N" },
									{
										name     => "QuoteEntryRejectReason",
										required => "N"
									},
								]
							},
						]
					},
				]
			},
			{
				name    => "MarketDataRequest",
				msgtype => "V",
				msgcat  => "app",
				fields  => [
					{ name => "MDReqID",                 required => "Y" },
					{ name => "SubscriptionRequestType", required => "Y" },
					{ name => "MarketDepth",             required => "Y" },
					{ name => "MDUpdateType",            required => "N" },
					{ name => "AggregatedBook",          required => "N" },
					{ name => "OpenCloseSettlFlag",      required => "N" },
					{ name => "Scope",                   required => "N" },
					{ name => "MDImplicitDelete",        required => "N" },
					{
						name     => "NoMDEntryTypes",
						required => "Y",
						group =>
						  [ { name => "MDEntryType", required => "Y" }, ]
					},
					{
						name     => "NoRelatedSym",
						required => "Y",
						group    => [
							{
								name      => "Instrument",
								required  => "Y",
								component => "Y"
							},
							{
								name     => "NoUnderlyings",
								required => "N",
								group    => [
									{
										name      => "UnderlyingInstrument",
										required  => "N",
										component => "Y"
									},
								]
							},
							{
								name     => "NoLegs",
								required => "N",
								group    => [
									{
										name      => "InstrumentLeg",
										required  => "N",
										component => "Y"
									},
								]
							},
						]
					},
					{
						name     => "NoTradingSessions",
						required => "N",
						group    => [
							{ name => "TradingSessionID", required => "N" },
							{
								name     => "TradingSessionSubID",
								required => "N"
							},
						]
					},
					{ name => "ApplQueueAction", required => "N" },
					{ name => "ApplQueueMax",    required => "N" },
				]
			},
			{
				name    => "MarketDataSnapshotFullRefresh",
				msgtype => "W",
				msgcat  => "app",
				fields  => [
					{ name => "MDReqID", required => "N" },
					{
						name      => "Instrument",
						required  => "Y",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "FinancialStatus", required => "N" },
					{ name => "CorporateAction", required => "N" },
					{ name => "NetChgPrevDay",   required => "N" },
					{
						name     => "NoMDEntries",
						required => "Y",
						group    => [
							{ name => "MDEntryType",      required => "Y" },
							{ name => "MDEntryPx",        required => "N" },
							{ name => "Currency",         required => "N" },
							{ name => "MDEntrySize",      required => "N" },
							{ name => "MDEntryDate",      required => "N" },
							{ name => "MDEntryTime",      required => "N" },
							{ name => "TickDirection",    required => "N" },
							{ name => "MDMkt",            required => "N" },
							{ name => "TradingSessionID", required => "N" },
							{
								name     => "TradingSessionSubID",
								required => "N"
							},
							{ name => "QuoteCondition",     required => "N" },
							{ name => "TradeCondition",     required => "N" },
							{ name => "MDEntryOriginator",  required => "N" },
							{ name => "LocationID",         required => "N" },
							{ name => "DeskID",             required => "N" },
							{ name => "OpenCloseSettlFlag", required => "N" },
							{ name => "TimeInForce",        required => "N" },
							{ name => "ExpireDate",         required => "N" },
							{ name => "ExpireTime",         required => "N" },
							{ name => "MinQty",             required => "N" },
							{ name => "ExecInst",           required => "N" },
							{ name => "SellerDays",         required => "N" },
							{ name => "OrderID",            required => "N" },
							{ name => "QuoteEntryID",       required => "N" },
							{ name => "MDEntryBuyer",       required => "N" },
							{ name => "MDEntrySeller",      required => "N" },
							{ name => "NumberOfOrders",     required => "N" },
							{ name => "MDEntryPositionNo",  required => "N" },
							{ name => "Scope",              required => "N" },
							{ name => "PriceDelta",         required => "N" },
							{ name => "Text",               required => "N" },
							{ name => "EncodedTextLen",     required => "N" },
							{ name => "EncodedText",        required => "N" },
						]
					},
					{ name => "ApplQueueDepth",      required => "N" },
					{ name => "ApplQueueResolution", required => "N" },
				]
			},
			{
				name    => "MarketDataIncrementalRefresh",
				msgtype => "X",
				msgcat  => "app",
				fields  => [
					{ name => "MDReqID", required => "N" },
					{
						name     => "NoMDEntries",
						required => "Y",
						group    => [
							{ name => "MDUpdateAction", required => "Y" },
							{ name => "DeleteReason",   required => "N" },
							{ name => "MDEntryType",    required => "N" },
							{ name => "MDEntryID",      required => "N" },
							{ name => "MDEntryRefID",   required => "N" },
							{
								name      => "Instrument",
								required  => "N",
								component => "Y"
							},
							{
								name     => "NoUnderlyings",
								required => "N",
								group    => [
									{
										name      => "UnderlyingInstrument",
										required  => "N",
										component => "Y"
									},
								]
							},
							{
								name     => "NoLegs",
								required => "N",
								group    => [
									{
										name      => "InstrumentLeg",
										required  => "N",
										component => "Y"
									},
								]
							},
							{ name => "FinancialStatus",  required => "N" },
							{ name => "CorporateAction",  required => "N" },
							{ name => "MDEntryPx",        required => "N" },
							{ name => "Currency",         required => "N" },
							{ name => "MDEntrySize",      required => "N" },
							{ name => "MDEntryDate",      required => "N" },
							{ name => "MDEntryTime",      required => "N" },
							{ name => "TickDirection",    required => "N" },
							{ name => "MDMkt",            required => "N" },
							{ name => "TradingSessionID", required => "N" },
							{
								name     => "TradingSessionSubID",
								required => "N"
							},
							{ name => "QuoteCondition",     required => "N" },
							{ name => "TradeCondition",     required => "N" },
							{ name => "MDEntryOriginator",  required => "N" },
							{ name => "LocationID",         required => "N" },
							{ name => "DeskID",             required => "N" },
							{ name => "OpenCloseSettlFlag", required => "N" },
							{ name => "TimeInForce",        required => "N" },
							{ name => "ExpireDate",         required => "N" },
							{ name => "ExpireTime",         required => "N" },
							{ name => "MinQty",             required => "N" },
							{ name => "ExecInst",           required => "N" },
							{ name => "SellerDays",         required => "N" },
							{ name => "OrderID",            required => "N" },
							{ name => "QuoteEntryID",       required => "N" },
							{ name => "MDEntryBuyer",       required => "N" },
							{ name => "MDEntrySeller",      required => "N" },
							{ name => "NumberOfOrders",     required => "N" },
							{ name => "MDEntryPositionNo",  required => "N" },
							{ name => "Scope",              required => "N" },
							{ name => "PriceDelta",         required => "N" },
							{ name => "NetChgPrevDay",      required => "N" },
							{ name => "Text",               required => "N" },
							{ name => "EncodedTextLen",     required => "N" },
							{ name => "EncodedText",        required => "N" },
						]
					},
					{ name => "ApplQueueDepth",      required => "N" },
					{ name => "ApplQueueResolution", required => "N" },
				]
			},
			{
				name    => "MarketDataRequestReject",
				msgtype => "Y",
				msgcat  => "app",
				fields  => [
					{ name => "MDReqID",        required => "Y" },
					{ name => "MDReqRejReason", required => "N" },
					{
						name     => "NoAltMDSource",
						required => "N",
						group =>
						  [ { name => "AltMDSourceID", required => "N" }, ]
					},
					{ name => "Text",           required => "N" },
					{ name => "EncodedTextLen", required => "N" },
					{ name => "EncodedText",    required => "N" },
				]
			},
			{
				name    => "SecurityDefinitionRequest",
				msgtype => "c",
				msgcat  => "app",
				fields  => [
					{ name => "SecurityReqID",       required => "Y" },
					{ name => "SecurityRequestType", required => "Y" },
					{
						name      => "Instrument",
						required  => "N",
						component => "Y"
					},
					{
						name      => "InstrumentExtension",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "Currency",            required => "N" },
					{ name => "Text",                required => "N" },
					{ name => "EncodedTextLen",      required => "N" },
					{ name => "EncodedText",         required => "N" },
					{ name => "TradingSessionID",    required => "N" },
					{ name => "TradingSessionSubID", required => "N" },
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "ExpirationCycle",         required => "N" },
					{ name => "SubscriptionRequestType", required => "N" },
				]
			},
			{
				name    => "SecurityDefinition",
				msgtype => "d",
				msgcat  => "app",
				fields  => [
					{ name => "SecurityReqID",        required => "Y" },
					{ name => "SecurityResponseID",   required => "Y" },
					{ name => "SecurityResponseType", required => "Y" },
					{
						name      => "Instrument",
						required  => "N",
						component => "Y"
					},
					{
						name      => "InstrumentExtension",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "Currency",            required => "N" },
					{ name => "TradingSessionID",    required => "N" },
					{ name => "TradingSessionSubID", required => "N" },
					{ name => "Text",                required => "N" },
					{ name => "EncodedTextLen",      required => "N" },
					{ name => "EncodedText",         required => "N" },
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "ExpirationCycle", required => "N" },
					{ name => "RoundLot",        required => "N" },
					{ name => "MinTradeVol",     required => "N" },
				]
			},
			{
				name    => "SecurityTypeRequest",
				msgtype => "v",
				msgcat  => "app",
				fields  => [
					{ name => "SecurityReqID",       required => "Y" },
					{ name => "Text",                required => "N" },
					{ name => "EncodedTextLen",      required => "N" },
					{ name => "EncodedText",         required => "N" },
					{ name => "TradingSessionID",    required => "N" },
					{ name => "TradingSessionSubID", required => "N" },
					{ name => "Product",             required => "N" },
					{ name => "SecurityType",        required => "N" },
					{ name => "SecuritySubType",     required => "N" },
				]
			},
			{
				name    => "SecurityTypes",
				msgtype => "w",
				msgcat  => "app",
				fields  => [
					{ name => "SecurityReqID",        required => "Y" },
					{ name => "SecurityResponseID",   required => "Y" },
					{ name => "SecurityResponseType", required => "Y" },
					{ name => "TotNoSecurityTypes",   required => "N" },
					{ name => "LastFragment",         required => "N" },
					{
						name     => "NoSecurityTypes",
						required => "N",
						group    => [
							{ name => "SecurityType",    required => "N" },
							{ name => "SecuritySubType", required => "N" },
							{ name => "Product",         required => "N" },
							{ name => "CFICode",         required => "N" },
						]
					},
					{ name => "Text",                    required => "N" },
					{ name => "EncodedTextLen",          required => "N" },
					{ name => "EncodedText",             required => "N" },
					{ name => "TradingSessionID",        required => "N" },
					{ name => "TradingSessionSubID",     required => "N" },
					{ name => "SubscriptionRequestType", required => "N" },
				]
			},
			{
				name    => "SecurityListRequest",
				msgtype => "x",
				msgcat  => "app",
				fields  => [
					{ name => "SecurityReqID",           required => "Y" },
					{ name => "SecurityListRequestType", required => "Y" },
					{
						name      => "Instrument",
						required  => "N",
						component => "Y"
					},
					{
						name      => "InstrumentExtension",
						required  => "N",
						component => "Y"
					},
					{
						name      => "FinancingDetails",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "Currency",                required => "N" },
					{ name => "Text",                    required => "N" },
					{ name => "EncodedTextLen",          required => "N" },
					{ name => "EncodedText",             required => "N" },
					{ name => "TradingSessionID",        required => "N" },
					{ name => "TradingSessionSubID",     required => "N" },
					{ name => "SubscriptionRequestType", required => "N" },
				]
			},
			{
				name    => "SecurityList",
				msgtype => "y",
				msgcat  => "app",
				fields  => [
					{ name => "SecurityReqID",         required => "Y" },
					{ name => "SecurityResponseID",    required => "Y" },
					{ name => "SecurityRequestResult", required => "Y" },
					{ name => "TotNoRelatedSym",       required => "N" },
					{ name => "LastFragment",          required => "N" },
					{
						name     => "NoRelatedSym",
						required => "N",
						group    => [
							{
								name      => "Instrument",
								required  => "N",
								component => "Y"
							},
							{
								name      => "InstrumentExtension",
								required  => "N",
								component => "Y"
							},
							{
								name      => "FinancingDetails",
								required  => "N",
								component => "Y"
							},
							{
								name     => "NoUnderlyings",
								required => "N",
								group    => [
									{
										name      => "UnderlyingInstrument",
										required  => "N",
										component => "Y"
									},
								]
							},
							{ name => "Currency", required => "N" },
							{
								name      => "Stipulations",
								required  => "N",
								component => "Y"
							},
							{
								name     => "NoLegs",
								required => "N",
								group    => [
									{
										name      => "InstrumentLeg",
										required  => "N",
										component => "Y"
									},
									{
										name     => "LegSwapType",
										required => "N"
									},
									{
										name     => "LegSettlType",
										required => "N"
									},
									{
										name      => "LegStipulations",
										required  => "N",
										component => "Y"
									},
									{
										name      => "LegBenchmarkCurveData",
										required  => "N",
										component => "Y"
									},
								]
							},
							{
								name      => "SpreadOrBenchmarkCurveData",
								required  => "N",
								component => "Y"
							},
							{
								name      => "YieldData",
								required  => "N",
								component => "Y"
							},
							{ name => "RoundLot",         required => "N" },
							{ name => "MinTradeVol",      required => "N" },
							{ name => "TradingSessionID", required => "N" },
							{
								name     => "TradingSessionSubID",
								required => "N"
							},
							{ name => "ExpirationCycle", required => "N" },
							{ name => "Text",            required => "N" },
							{ name => "EncodedTextLen",  required => "N" },
							{ name => "EncodedText",     required => "N" },
						]
					},
				]
			},
			{
				name    => "DerivativeSecurityListRequest",
				msgtype => "z",
				msgcat  => "app",
				fields  => [
					{ name => "SecurityReqID",           required => "Y" },
					{ name => "SecurityListRequestType", required => "Y" },
					{
						name      => "UnderlyingInstrument",
						required  => "N",
						component => "Y"
					},
					{ name => "SecuritySubType",         required => "N" },
					{ name => "Currency",                required => "N" },
					{ name => "Text",                    required => "N" },
					{ name => "EncodedTextLen",          required => "N" },
					{ name => "EncodedText",             required => "N" },
					{ name => "TradingSessionID",        required => "N" },
					{ name => "TradingSessionSubID",     required => "N" },
					{ name => "SubscriptionRequestType", required => "N" },
				]
			},
			{
				name    => "DerivativeSecurityList",
				msgtype => "AA",
				msgcat  => "app",
				fields  => [
					{ name => "SecurityReqID",         required => "Y" },
					{ name => "SecurityResponseID",    required => "Y" },
					{ name => "SecurityRequestResult", required => "Y" },
					{
						name      => "UnderlyingInstrument",
						required  => "N",
						component => "Y"
					},
					{ name => "TotNoRelatedSym", required => "N" },
					{ name => "LastFragment",    required => "N" },
					{
						name     => "NoRelatedSym",
						required => "N",
						group    => [
							{
								name      => "Instrument",
								required  => "N",
								component => "Y"
							},
							{ name => "Currency",        required => "N" },
							{ name => "ExpirationCycle", required => "N" },
							{
								name      => "InstrumentExtension",
								required  => "N",
								component => "Y"
							},
							{
								name     => "NoLegs",
								required => "N",
								group    => [
									{
										name      => "InstrumentLeg",
										required  => "N",
										component => "Y"
									},
								]
							},
							{ name => "TradingSessionID", required => "N" },
							{
								name     => "TradingSessionSubID",
								required => "N"
							},
							{ name => "Text",           required => "N" },
							{ name => "EncodedTextLen", required => "N" },
							{ name => "EncodedText",    required => "N" },
						]
					},
				]
			},
			{
				name    => "SecurityStatusRequest",
				msgtype => "e",
				msgcat  => "app",
				fields  => [
					{ name => "SecurityStatusReqID", required => "Y" },
					{
						name      => "Instrument",
						required  => "Y",
						component => "Y"
					},
					{
						name      => "InstrumentExtension",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "Currency",                required => "N" },
					{ name => "SubscriptionRequestType", required => "Y" },
					{ name => "TradingSessionID",        required => "N" },
					{ name => "TradingSessionSubID",     required => "N" },
				]
			},
			{
				name    => "SecurityStatus",
				msgtype => "f",
				msgcat  => "app",
				fields  => [
					{ name => "SecurityStatusReqID", required => "N" },
					{
						name      => "Instrument",
						required  => "Y",
						component => "Y"
					},
					{
						name      => "InstrumentExtension",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "Currency",              required => "N" },
					{ name => "TradingSessionID",      required => "N" },
					{ name => "TradingSessionSubID",   required => "N" },
					{ name => "UnsolicitedIndicator",  required => "N" },
					{ name => "SecurityTradingStatus", required => "N" },
					{ name => "FinancialStatus",       required => "N" },
					{ name => "CorporateAction",       required => "N" },
					{ name => "HaltReason",            required => "N" },
					{ name => "InViewOfCommon",        required => "N" },
					{ name => "DueToRelated",          required => "N" },
					{ name => "BuyVolume",             required => "N" },
					{ name => "SellVolume",            required => "N" },
					{ name => "HighPx",                required => "N" },
					{ name => "LowPx",                 required => "N" },
					{ name => "LastPx",                required => "N" },
					{ name => "TransactTime",          required => "N" },
					{ name => "Adjustment",            required => "N" },
					{ name => "Text",                  required => "N" },
					{ name => "EncodedTextLen",        required => "N" },
					{ name => "EncodedText",           required => "N" },
				]
			},
			{
				name    => "TradingSessionStatusRequest",
				msgtype => "g",
				msgcat  => "app",
				fields  => [
					{ name => "TradSesReqID",            required => "Y" },
					{ name => "TradingSessionID",        required => "N" },
					{ name => "TradingSessionSubID",     required => "N" },
					{ name => "TradSesMethod",           required => "N" },
					{ name => "TradSesMode",             required => "N" },
					{ name => "SubscriptionRequestType", required => "Y" },
				]
			},
			{
				name    => "TradingSessionStatus",
				msgtype => "h",
				msgcat  => "app",
				fields  => [
					{ name => "TradSesReqID",           required => "N" },
					{ name => "TradingSessionID",       required => "Y" },
					{ name => "TradingSessionSubID",    required => "N" },
					{ name => "TradSesMethod",          required => "N" },
					{ name => "TradSesMode",            required => "N" },
					{ name => "UnsolicitedIndicator",   required => "N" },
					{ name => "TradSesStatus",          required => "Y" },
					{ name => "TradSesStatusRejReason", required => "N" },
					{ name => "TradSesStartTime",       required => "N" },
					{ name => "TradSesOpenTime",        required => "N" },
					{ name => "TradSesPreCloseTime",    required => "N" },
					{ name => "TradSesCloseTime",       required => "N" },
					{ name => "TradSesEndTime",         required => "N" },
					{ name => "TotalVolumeTraded",      required => "N" },
					{ name => "Text",                   required => "N" },
					{ name => "EncodedTextLen",         required => "N" },
					{ name => "EncodedText",            required => "N" },
				]
			},
			{
				name    => "NewOrderSingle",
				msgtype => "D",
				msgcat  => "app",
				fields  => [
					{ name => "ClOrdID",          required => "Y" },
					{ name => "SecondaryClOrdID", required => "N" },
					{ name => "ClOrdLinkID",      required => "N" },
					{ name => "Parties", required => "N", component => "Y" },
					{ name => "TradeOriginationDate", required => "N" },
					{ name => "TradeDate",            required => "N" },
					{ name => "Account",              required => "N" },
					{ name => "AcctIDSource",         required => "N" },
					{ name => "AccountType",          required => "N" },
					{ name => "DayBookingInst",       required => "N" },
					{ name => "BookingUnit",          required => "N" },
					{ name => "PreallocMethod",       required => "N" },
					{ name => "AllocID",              required => "N" },
					{
						name     => "NoAllocs",
						required => "N",
						group    => [
							{ name => "AllocAccount",       required => "N" },
							{ name => "AllocAcctIDSource",  required => "N" },
							{ name => "AllocSettlCurrency", required => "N" },
							{ name => "IndividualAllocID",  required => "N" },
							{
								name      => "NestedParties",
								required  => "N",
								component => "Y"
							},
							{ name => "AllocQty", required => "N" },
						]
					},
					{ name => "SettlType",            required => "N" },
					{ name => "SettlDate",            required => "N" },
					{ name => "CashMargin",           required => "N" },
					{ name => "ClearingFeeIndicator", required => "N" },
					{ name => "HandlInst",            required => "N" },
					{ name => "ExecInst",             required => "N" },
					{ name => "MinQty",               required => "N" },
					{ name => "MaxFloor",             required => "N" },
					{ name => "ExDestination",        required => "N" },
					{
						name     => "NoTradingSessions",
						required => "N",
						group    => [
							{ name => "TradingSessionID", required => "N" },
							{
								name     => "TradingSessionSubID",
								required => "N"
							},
						]
					},
					{ name => "ProcessCode", required => "N" },
					{
						name      => "Instrument",
						required  => "Y",
						component => "Y"
					},
					{
						name      => "FinancingDetails",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "PrevClosePx",  required => "N" },
					{ name => "Side",         required => "Y" },
					{ name => "LocateReqd",   required => "N" },
					{ name => "TransactTime", required => "Y" },
					{
						name      => "Stipulations",
						required  => "N",
						component => "Y"
					},
					{ name => "QtyType", required => "N" },
					{
						name      => "OrderQtyData",
						required  => "Y",
						component => "Y"
					},
					{ name => "OrdType",   required => "Y" },
					{ name => "PriceType", required => "N" },
					{ name => "Price",     required => "N" },
					{ name => "StopPx",    required => "N" },
					{
						name      => "SpreadOrBenchmarkCurveData",
						required  => "N",
						component => "Y"
					},
					{
						name      => "YieldData",
						required  => "N",
						component => "Y"
					},
					{ name => "Currency",      required => "N" },
					{ name => "ComplianceID",  required => "N" },
					{ name => "SolicitedFlag", required => "N" },
					{ name => "IOIid",         required => "N" },
					{ name => "QuoteID",       required => "N" },
					{ name => "TimeInForce",   required => "N" },
					{ name => "EffectiveTime", required => "N" },
					{ name => "ExpireDate",    required => "N" },
					{ name => "ExpireTime",    required => "N" },
					{ name => "GTBookingInst", required => "N" },
					{
						name      => "CommissionData",
						required  => "N",
						component => "Y"
					},
					{ name => "OrderCapacity",      required => "N" },
					{ name => "OrderRestrictions",  required => "N" },
					{ name => "CustOrderCapacity",  required => "N" },
					{ name => "ForexReq",           required => "N" },
					{ name => "SettlCurrency",      required => "N" },
					{ name => "BookingType",        required => "N" },
					{ name => "Text",               required => "N" },
					{ name => "EncodedTextLen",     required => "N" },
					{ name => "EncodedText",        required => "N" },
					{ name => "SettlDate2",         required => "N" },
					{ name => "OrderQty2",          required => "N" },
					{ name => "Price2",             required => "N" },
					{ name => "PositionEffect",     required => "N" },
					{ name => "CoveredOrUncovered", required => "N" },
					{ name => "MaxShow",            required => "N" },
					{
						name      => "PegInstructions",
						required  => "N",
						component => "Y"
					},
					{
						name      => "DiscretionInstructions",
						required  => "N",
						component => "Y"
					},
					{ name => "TargetStrategy",           required => "N" },
					{ name => "TargetStrategyParameters", required => "N" },
					{ name => "ParticipationRate",        required => "N" },
					{ name => "CancellationRights",       required => "N" },
					{ name => "MoneyLaunderingStatus",    required => "N" },
					{ name => "RegistID",                 required => "N" },
					{ name => "Designation",              required => "N" },
				]
			},
			{
				name    => "ExecutionReport",
				msgtype => "8",
				msgcat  => "app",
				fields  => [
					{ name => "OrderID",          required => "Y" },
					{ name => "SecondaryOrderID", required => "N" },
					{ name => "SecondaryClOrdID", required => "N" },
					{ name => "SecondaryExecID",  required => "N" },
					{ name => "ClOrdID",          required => "N" },
					{ name => "OrigClOrdID",      required => "N" },
					{ name => "ClOrdLinkID",      required => "N" },
					{ name => "QuoteRespID",      required => "N" },
					{ name => "OrdStatusReqID",   required => "N" },
					{ name => "MassStatusReqID",  required => "N" },
					{ name => "TotNumReports",    required => "N" },
					{ name => "LastRptRequested", required => "N" },
					{ name => "Parties", required => "N", component => "Y" },
					{ name => "TradeOriginationDate", required => "N" },
					{
						name     => "NoContraBrokers",
						required => "N",
						group    => [
							{ name => "ContraBroker",    required => "N" },
							{ name => "ContraTrader",    required => "N" },
							{ name => "ContraTradeQty",  required => "N" },
							{ name => "ContraTradeTime", required => "N" },
							{ name => "ContraLegRefID",  required => "N" },
						]
					},
					{ name => "ListID",                required => "N" },
					{ name => "CrossID",               required => "N" },
					{ name => "OrigCrossID",           required => "N" },
					{ name => "CrossType",             required => "N" },
					{ name => "ExecID",                required => "Y" },
					{ name => "ExecRefID",             required => "N" },
					{ name => "ExecType",              required => "Y" },
					{ name => "OrdStatus",             required => "Y" },
					{ name => "WorkingIndicator",      required => "N" },
					{ name => "OrdRejReason",          required => "N" },
					{ name => "ExecRestatementReason", required => "N" },
					{ name => "Account",               required => "N" },
					{ name => "AcctIDSource",          required => "N" },
					{ name => "AccountType",           required => "N" },
					{ name => "DayBookingInst",        required => "N" },
					{ name => "BookingUnit",           required => "N" },
					{ name => "PreallocMethod",        required => "N" },
					{ name => "SettlType",             required => "N" },
					{ name => "SettlDate",             required => "N" },
					{ name => "CashMargin",            required => "N" },
					{ name => "ClearingFeeIndicator",  required => "N" },
					{
						name      => "Instrument",
						required  => "Y",
						component => "Y"
					},
					{
						name      => "FinancingDetails",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "Side", required => "Y" },
					{
						name      => "Stipulations",
						required  => "N",
						component => "Y"
					},
					{ name => "QtyType", required => "N" },
					{
						name      => "OrderQtyData",
						required  => "N",
						component => "Y"
					},
					{ name => "OrdType",   required => "N" },
					{ name => "PriceType", required => "N" },
					{ name => "Price",     required => "N" },
					{ name => "StopPx",    required => "N" },
					{
						name      => "PegInstructions",
						required  => "N",
						component => "Y"
					},
					{
						name      => "DiscretionInstructions",
						required  => "N",
						component => "Y"
					},
					{ name => "PeggedPrice",               required => "N" },
					{ name => "DiscretionPrice",           required => "N" },
					{ name => "TargetStrategy",            required => "N" },
					{ name => "TargetStrategyParameters",  required => "N" },
					{ name => "ParticipationRate",         required => "N" },
					{ name => "TargetStrategyPerformance", required => "N" },
					{ name => "Currency",                  required => "N" },
					{ name => "ComplianceID",              required => "N" },
					{ name => "SolicitedFlag",             required => "N" },
					{ name => "TimeInForce",               required => "N" },
					{ name => "EffectiveTime",             required => "N" },
					{ name => "ExpireDate",                required => "N" },
					{ name => "ExpireTime",                required => "N" },
					{ name => "ExecInst",                  required => "N" },
					{ name => "OrderCapacity",             required => "N" },
					{ name => "OrderRestrictions",         required => "N" },
					{ name => "CustOrderCapacity",         required => "N" },
					{ name => "LastQty",                   required => "N" },
					{ name => "UnderlyingLastQty",         required => "N" },
					{ name => "LastPx",                    required => "N" },
					{ name => "UnderlyingLastPx",          required => "N" },
					{ name => "LastParPx",                 required => "N" },
					{ name => "LastSpotRate",              required => "N" },
					{ name => "LastForwardPoints",         required => "N" },
					{ name => "LastMkt",                   required => "N" },
					{ name => "TradingSessionID",          required => "N" },
					{ name => "TradingSessionSubID",       required => "N" },
					{ name => "TimeBracket",               required => "N" },
					{ name => "LastCapacity",              required => "N" },
					{ name => "LeavesQty",                 required => "Y" },
					{ name => "CumQty",                    required => "Y" },
					{ name => "AvgPx",                     required => "Y" },
					{ name => "DayOrderQty",               required => "N" },
					{ name => "DayCumQty",                 required => "N" },
					{ name => "DayAvgPx",                  required => "N" },
					{ name => "GTBookingInst",             required => "N" },
					{ name => "TradeDate",                 required => "N" },
					{ name => "TransactTime",              required => "N" },
					{ name => "ReportToExch",              required => "N" },
					{
						name      => "CommissionData",
						required  => "N",
						component => "Y"
					},
					{
						name      => "SpreadOrBenchmarkCurveData",
						required  => "N",
						component => "Y"
					},
					{
						name      => "YieldData",
						required  => "N",
						component => "Y"
					},
					{ name => "GrossTradeAmt",         required => "N" },
					{ name => "NumDaysInterest",       required => "N" },
					{ name => "ExDate",                required => "N" },
					{ name => "AccruedInterestRate",   required => "N" },
					{ name => "AccruedInterestAmt",    required => "N" },
					{ name => "InterestAtMaturity",    required => "N" },
					{ name => "EndAccruedInterestAmt", required => "N" },
					{ name => "StartCash",             required => "N" },
					{ name => "EndCash",               required => "N" },
					{ name => "TradedFlatSwitch",      required => "N" },
					{ name => "BasisFeatureDate",      required => "N" },
					{ name => "BasisFeaturePrice",     required => "N" },
					{ name => "Concession",            required => "N" },
					{ name => "TotalTakedown",         required => "N" },
					{ name => "NetMoney",              required => "N" },
					{ name => "SettlCurrAmt",          required => "N" },
					{ name => "SettlCurrency",         required => "N" },
					{ name => "SettlCurrFxRate",       required => "N" },
					{ name => "SettlCurrFxRateCalc",   required => "N" },
					{ name => "HandlInst",             required => "N" },
					{ name => "MinQty",                required => "N" },
					{ name => "MaxFloor",              required => "N" },
					{ name => "PositionEffect",        required => "N" },
					{ name => "MaxShow",               required => "N" },
					{ name => "BookingType",           required => "N" },
					{ name => "Text",                  required => "N" },
					{ name => "EncodedTextLen",        required => "N" },
					{ name => "EncodedText",           required => "N" },
					{ name => "SettlDate2",            required => "N" },
					{ name => "OrderQty2",             required => "N" },
					{ name => "LastForwardPoints2",    required => "N" },
					{ name => "MultiLegReportingType", required => "N" },
					{ name => "CancellationRights",    required => "N" },
					{ name => "MoneyLaunderingStatus", required => "N" },
					{ name => "RegistID",              required => "N" },
					{ name => "Designation",           required => "N" },
					{ name => "TransBkdTime",          required => "N" },
					{ name => "ExecValuationPoint",    required => "N" },
					{ name => "ExecPriceType",         required => "N" },
					{ name => "ExecPriceAdjustment",   required => "N" },
					{ name => "PriorityIndicator",     required => "N" },
					{ name => "PriceImprovement",      required => "N" },
					{ name => "LastLiquidityInd",      required => "N" },
					{
						name     => "NoContAmts",
						required => "N",
						group    => [
							{ name => "ContAmtType",  required => "N" },
							{ name => "ContAmtValue", required => "N" },
							{ name => "ContAmtCurr",  required => "N" },
						]
					},
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
							{ name => "LegQty",      required => "N" },
							{ name => "LegSwapType", required => "N" },
							{
								name      => "LegStipulations",
								required  => "N",
								component => "Y"
							},
							{ name => "LegPositionEffect", required => "N" },
							{
								name     => "LegCoveredOrUncovered",
								required => "N"
							},
							{
								name      => "NestedParties",
								required  => "N",
								component => "Y"
							},
							{ name => "LegRefID",     required => "N" },
							{ name => "LegPrice",     required => "N" },
							{ name => "LegSettlType", required => "N" },
							{ name => "LegSettlDate", required => "N" },
							{ name => "LegLastPx",    required => "N" },
						]
					},
					{ name => "CopyMsgIndicator", required => "N" },
					{
						name     => "NoMiscFees",
						required => "N",
						group    => [
							{ name => "MiscFeeAmt",   required => "N" },
							{ name => "MiscFeeCurr",  required => "N" },
							{ name => "MiscFeeType",  required => "N" },
							{ name => "MiscFeeBasis", required => "N" },
						]
					},
				]
			},
			{
				name    => "DontKnowTrade",
				msgtype => "Q",
				msgcat  => "app",
				fields  => [
					{ name => "OrderID",          required => "Y" },
					{ name => "SecondaryOrderID", required => "N" },
					{ name => "ExecID",           required => "Y" },
					{ name => "DKReason",         required => "Y" },
					{
						name      => "Instrument",
						required  => "Y",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "Side", required => "Y" },
					{
						name      => "OrderQtyData",
						required  => "Y",
						component => "Y"
					},
					{ name => "LastQty",        required => "N" },
					{ name => "LastPx",         required => "N" },
					{ name => "Text",           required => "N" },
					{ name => "EncodedTextLen", required => "N" },
					{ name => "EncodedText",    required => "N" },
				]
			},
			{
				name    => "OrderCancelReplaceRequest",
				msgtype => "G",
				msgcat  => "app",
				fields  => [
					{ name => "OrderID", required => "N" },
					{ name => "Parties", required => "N", component => "Y" },
					{ name => "TradeOriginationDate", required => "N" },
					{ name => "TradeDate",            required => "N" },
					{ name => "OrigClOrdID",          required => "Y" },
					{ name => "ClOrdID",              required => "Y" },
					{ name => "SecondaryClOrdID",     required => "N" },
					{ name => "ClOrdLinkID",          required => "N" },
					{ name => "ListID",               required => "N" },
					{ name => "OrigOrdModTime",       required => "N" },
					{ name => "Account",              required => "N" },
					{ name => "AcctIDSource",         required => "N" },
					{ name => "AccountType",          required => "N" },
					{ name => "DayBookingInst",       required => "N" },
					{ name => "BookingUnit",          required => "N" },
					{ name => "PreallocMethod",       required => "N" },
					{ name => "AllocID",              required => "N" },
					{
						name     => "NoAllocs",
						required => "N",
						group    => [
							{ name => "AllocAccount",       required => "N" },
							{ name => "AllocAcctIDSource",  required => "N" },
							{ name => "AllocSettlCurrency", required => "N" },
							{ name => "IndividualAllocID",  required => "N" },
							{
								name      => "NestedParties",
								required  => "N",
								component => "Y"
							},
							{ name => "AllocQty", required => "N" },
						]
					},
					{ name => "SettlType",            required => "N" },
					{ name => "SettlDate",            required => "N" },
					{ name => "CashMargin",           required => "N" },
					{ name => "ClearingFeeIndicator", required => "N" },
					{ name => "HandlInst",            required => "N" },
					{ name => "ExecInst",             required => "N" },
					{ name => "MinQty",               required => "N" },
					{ name => "MaxFloor",             required => "N" },
					{ name => "ExDestination",        required => "N" },
					{
						name     => "NoTradingSessions",
						required => "N",
						group    => [
							{ name => "TradingSessionID", required => "N" },
							{
								name     => "TradingSessionSubID",
								required => "N"
							},
						]
					},
					{
						name      => "Instrument",
						required  => "Y",
						component => "Y"
					},
					{
						name      => "FinancingDetails",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "Side",         required => "Y" },
					{ name => "TransactTime", required => "Y" },
					{ name => "QtyType",      required => "N" },
					{
						name      => "OrderQtyData",
						required  => "Y",
						component => "Y"
					},
					{ name => "OrdType",   required => "Y" },
					{ name => "PriceType", required => "N" },
					{ name => "Price",     required => "N" },
					{ name => "StopPx",    required => "N" },
					{
						name      => "SpreadOrBenchmarkCurveData",
						required  => "N",
						component => "Y"
					},
					{
						name      => "YieldData",
						required  => "N",
						component => "Y"
					},
					{
						name      => "PegInstructions",
						required  => "N",
						component => "Y"
					},
					{
						name      => "DiscretionInstructions",
						required  => "N",
						component => "Y"
					},
					{ name => "TargetStrategy",           required => "N" },
					{ name => "TargetStrategyParameters", required => "N" },
					{ name => "ParticipationRate",        required => "N" },
					{ name => "ComplianceID",             required => "N" },
					{ name => "SolicitedFlag",            required => "N" },
					{ name => "Currency",                 required => "N" },
					{ name => "TimeInForce",              required => "N" },
					{ name => "EffectiveTime",            required => "N" },
					{ name => "ExpireDate",               required => "N" },
					{ name => "ExpireTime",               required => "N" },
					{ name => "GTBookingInst",            required => "N" },
					{
						name      => "CommissionData",
						required  => "N",
						component => "Y"
					},
					{ name => "OrderCapacity",         required => "N" },
					{ name => "OrderRestrictions",     required => "N" },
					{ name => "CustOrderCapacity",     required => "N" },
					{ name => "ForexReq",              required => "N" },
					{ name => "SettlCurrency",         required => "N" },
					{ name => "BookingType",           required => "N" },
					{ name => "Text",                  required => "N" },
					{ name => "EncodedTextLen",        required => "N" },
					{ name => "EncodedText",           required => "N" },
					{ name => "SettlDate2",            required => "N" },
					{ name => "OrderQty2",             required => "N" },
					{ name => "Price2",                required => "N" },
					{ name => "PositionEffect",        required => "N" },
					{ name => "CoveredOrUncovered",    required => "N" },
					{ name => "MaxShow",               required => "N" },
					{ name => "LocateReqd",            required => "N" },
					{ name => "CancellationRights",    required => "N" },
					{ name => "MoneyLaunderingStatus", required => "N" },
					{ name => "RegistID",              required => "N" },
					{ name => "Designation",           required => "N" },
				]
			},
			{
				name    => "OrderCancelRequest",
				msgtype => "F",
				msgcat  => "app",
				fields  => [
					{ name => "OrigClOrdID",      required => "Y" },
					{ name => "OrderID",          required => "N" },
					{ name => "ClOrdID",          required => "Y" },
					{ name => "SecondaryClOrdID", required => "N" },
					{ name => "ClOrdLinkID",      required => "N" },
					{ name => "ListID",           required => "N" },
					{ name => "OrigOrdModTime",   required => "N" },
					{ name => "Account",          required => "N" },
					{ name => "AcctIDSource",     required => "N" },
					{ name => "AccountType",      required => "N" },
					{ name => "Parties", required => "N", component => "Y" },
					{
						name      => "Instrument",
						required  => "Y",
						component => "Y"
					},
					{
						name      => "FinancingDetails",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "Side",         required => "Y" },
					{ name => "TransactTime", required => "Y" },
					{
						name      => "OrderQtyData",
						required  => "Y",
						component => "Y"
					},
					{ name => "ComplianceID",   required => "N" },
					{ name => "Text",           required => "N" },
					{ name => "EncodedTextLen", required => "N" },
					{ name => "EncodedText",    required => "N" },
				]
			},
			{
				name    => "OrderCancelReject",
				msgtype => "9",
				msgcat  => "app",
				fields  => [
					{ name => "OrderID",              required => "Y" },
					{ name => "SecondaryOrderID",     required => "N" },
					{ name => "SecondaryClOrdID",     required => "N" },
					{ name => "ClOrdID",              required => "Y" },
					{ name => "ClOrdLinkID",          required => "N" },
					{ name => "OrigClOrdID",          required => "Y" },
					{ name => "OrdStatus",            required => "Y" },
					{ name => "WorkingIndicator",     required => "N" },
					{ name => "OrigOrdModTime",       required => "N" },
					{ name => "ListID",               required => "N" },
					{ name => "Account",              required => "N" },
					{ name => "AcctIDSource",         required => "N" },
					{ name => "AccountType",          required => "N" },
					{ name => "TradeOriginationDate", required => "N" },
					{ name => "TradeDate",            required => "N" },
					{ name => "TransactTime",         required => "N" },
					{ name => "CxlRejResponseTo",     required => "Y" },
					{ name => "CxlRejReason",         required => "N" },
					{ name => "Text",                 required => "N" },
					{ name => "EncodedTextLen",       required => "N" },
					{ name => "EncodedText",          required => "N" },
				]
			},
			{
				name    => "OrderStatusRequest",
				msgtype => "H",
				msgcat  => "app",
				fields  => [
					{ name => "OrderID",          required => "N" },
					{ name => "ClOrdID",          required => "Y" },
					{ name => "SecondaryClOrdID", required => "N" },
					{ name => "ClOrdLinkID",      required => "N" },
					{ name => "Parties", required => "N", component => "Y" },
					{ name => "OrdStatusReqID", required => "N" },
					{ name => "Account",        required => "N" },
					{ name => "AcctIDSource",   required => "N" },
					{
						name      => "Instrument",
						required  => "Y",
						component => "Y"
					},
					{
						name      => "FinancingDetails",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "Side", required => "Y" },
				]
			},
			{
				name    => "OrderMassCancelRequest",
				msgtype => "q",
				msgcat  => "app",
				fields  => [
					{ name => "ClOrdID",               required => "Y" },
					{ name => "SecondaryClOrdID",      required => "N" },
					{ name => "MassCancelRequestType", required => "Y" },
					{ name => "TradingSessionID",      required => "N" },
					{ name => "TradingSessionSubID",   required => "N" },
					{
						name      => "Instrument",
						required  => "N",
						component => "Y"
					},
					{
						name      => "UnderlyingInstrument",
						required  => "N",
						component => "Y"
					},
					{ name => "Side",           required => "N" },
					{ name => "TransactTime",   required => "Y" },
					{ name => "Text",           required => "N" },
					{ name => "EncodedTextLen", required => "N" },
					{ name => "EncodedText",    required => "N" },
				]
			},
			{
				name    => "OrderMassCancelReport",
				msgtype => "r",
				msgcat  => "app",
				fields  => [
					{ name => "ClOrdID",                required => "N" },
					{ name => "SecondaryClOrdID",       required => "N" },
					{ name => "OrderID",                required => "Y" },
					{ name => "SecondaryOrderID",       required => "N" },
					{ name => "MassCancelRequestType",  required => "Y" },
					{ name => "MassCancelResponse",     required => "Y" },
					{ name => "MassCancelRejectReason", required => "N" },
					{ name => "TotalAffectedOrders",    required => "N" },
					{
						name     => "NoAffectedOrders",
						required => "N",
						group    => [
							{ name => "OrigClOrdID",     required => "N" },
							{ name => "AffectedOrderID", required => "N" },
							{
								name     => "AffectedSecondaryOrderID",
								required => "N"
							},
						]
					},
					{ name => "TradingSessionID",    required => "N" },
					{ name => "TradingSessionSubID", required => "N" },
					{
						name      => "Instrument",
						required  => "N",
						component => "Y"
					},
					{
						name      => "UnderlyingInstrument",
						required  => "N",
						component => "Y"
					},
					{ name => "Side",           required => "N" },
					{ name => "TransactTime",   required => "N" },
					{ name => "Text",           required => "N" },
					{ name => "EncodedTextLen", required => "N" },
					{ name => "EncodedText",    required => "N" },
				]
			},
			{
				name    => "OrderMassStatusRequest",
				msgtype => "AF",
				msgcat  => "app",
				fields  => [
					{ name => "MassStatusReqID",   required => "Y" },
					{ name => "MassStatusReqType", required => "Y" },
					{ name => "Parties", required => "N", component => "Y" },
					{ name => "Account", required => "N" },
					{ name => "AcctIDSource",        required => "N" },
					{ name => "TradingSessionID",    required => "N" },
					{ name => "TradingSessionSubID", required => "N" },
					{
						name      => "Instrument",
						required  => "N",
						component => "Y"
					},
					{
						name      => "UnderlyingInstrument",
						required  => "N",
						component => "Y"
					},
					{ name => "Side", required => "N" },
				]
			},
			{
				name    => "NewOrderCross",
				msgtype => "s",
				msgcat  => "app",
				fields  => [
					{ name => "CrossID",             required => "Y" },
					{ name => "CrossType",           required => "Y" },
					{ name => "CrossPrioritization", required => "Y" },
					{
						name     => "NoSides",
						required => "Y",
						group    => [
							{ name => "Side",             required => "Y" },
							{ name => "ClOrdID",          required => "Y" },
							{ name => "SecondaryClOrdID", required => "N" },
							{ name => "ClOrdLinkID",      required => "N" },
							{
								name      => "Parties",
								required  => "N",
								component => "Y"
							},
							{
								name     => "TradeOriginationDate",
								required => "N"
							},
							{ name => "TradeDate",      required => "N" },
							{ name => "Account",        required => "N" },
							{ name => "AcctIDSource",   required => "N" },
							{ name => "AccountType",    required => "N" },
							{ name => "DayBookingInst", required => "N" },
							{ name => "BookingUnit",    required => "N" },
							{ name => "PreallocMethod", required => "N" },
							{ name => "AllocID",        required => "N" },
							{
								name     => "NoAllocs",
								required => "N",
								group    => [
									{
										name     => "AllocAccount",
										required => "N"
									},
									{
										name     => "AllocAcctIDSource",
										required => "N"
									},
									{
										name     => "AllocSettlCurrency",
										required => "N"
									},
									{
										name     => "IndividualAllocID",
										required => "N"
									},
									{
										name      => "NestedParties",
										required  => "N",
										component => "Y"
									},
									{ name => "AllocQty", required => "N" },
								]
							},
							{ name => "QtyType", required => "N" },
							{
								name      => "OrderQtyData",
								required  => "Y",
								component => "Y"
							},
							{
								name      => "CommissionData",
								required  => "N",
								component => "Y"
							},
							{ name => "OrderCapacity",      required => "N" },
							{ name => "OrderRestrictions",  required => "N" },
							{ name => "CustOrderCapacity",  required => "N" },
							{ name => "ForexReq",           required => "N" },
							{ name => "SettlCurrency",      required => "N" },
							{ name => "BookingType",        required => "N" },
							{ name => "Text",               required => "N" },
							{ name => "EncodedTextLen",     required => "N" },
							{ name => "EncodedText",        required => "N" },
							{ name => "PositionEffect",     required => "N" },
							{ name => "CoveredOrUncovered", required => "N" },
							{ name => "CashMargin",         required => "N" },
							{
								name     => "ClearingFeeIndicator",
								required => "N"
							},
							{ name => "SolicitedFlag",    required => "N" },
							{ name => "SideComplianceID", required => "N" },
						]
					},
					{
						name      => "Instrument",
						required  => "Y",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "SettlType",     required => "N" },
					{ name => "SettlDate",     required => "N" },
					{ name => "HandlInst",     required => "N" },
					{ name => "ExecInst",      required => "N" },
					{ name => "MinQty",        required => "N" },
					{ name => "MaxFloor",      required => "N" },
					{ name => "ExDestination", required => "N" },
					{
						name     => "NoTradingSessions",
						required => "N",
						group    => [
							{ name => "TradingSessionID", required => "N" },
							{
								name     => "TradingSessionSubID",
								required => "N"
							},
						]
					},
					{ name => "ProcessCode",  required => "N" },
					{ name => "PrevClosePx",  required => "N" },
					{ name => "LocateReqd",   required => "N" },
					{ name => "TransactTime", required => "Y" },
					{
						name      => "Stipulations",
						required  => "N",
						component => "Y"
					},
					{ name => "OrdType",   required => "Y" },
					{ name => "PriceType", required => "N" },
					{ name => "Price",     required => "N" },
					{ name => "StopPx",    required => "N" },
					{
						name      => "SpreadOrBenchmarkCurveData",
						required  => "N",
						component => "Y"
					},
					{
						name      => "YieldData",
						required  => "N",
						component => "Y"
					},
					{ name => "Currency",      required => "N" },
					{ name => "ComplianceID",  required => "N" },
					{ name => "IOIid",         required => "N" },
					{ name => "QuoteID",       required => "N" },
					{ name => "TimeInForce",   required => "N" },
					{ name => "EffectiveTime", required => "N" },
					{ name => "ExpireDate",    required => "N" },
					{ name => "ExpireTime",    required => "N" },
					{ name => "GTBookingInst", required => "N" },
					{ name => "MaxShow",       required => "N" },
					{
						name      => "PegInstructions",
						required  => "N",
						component => "Y"
					},
					{
						name      => "DiscretionInstructions",
						required  => "N",
						component => "Y"
					},
					{ name => "TargetStrategy",           required => "N" },
					{ name => "TargetStrategyParameters", required => "N" },
					{ name => "ParticipationRate",        required => "N" },
					{ name => "CancellationRights",       required => "N" },
					{ name => "MoneyLaunderingStatus",    required => "N" },
					{ name => "RegistID",                 required => "N" },
					{ name => "Designation",              required => "N" },
				]
			},
			{
				name    => "CrossOrderCancelReplaceRequest",
				msgtype => "t",
				msgcat  => "app",
				fields  => [
					{ name => "OrderID",             required => "N" },
					{ name => "CrossID",             required => "Y" },
					{ name => "OrigCrossID",         required => "Y" },
					{ name => "CrossType",           required => "Y" },
					{ name => "CrossPrioritization", required => "Y" },
					{
						name     => "NoSides",
						required => "Y",
						group    => [
							{ name => "Side",             required => "Y" },
							{ name => "OrigClOrdID",      required => "Y" },
							{ name => "ClOrdID",          required => "Y" },
							{ name => "SecondaryClOrdID", required => "N" },
							{ name => "ClOrdLinkID",      required => "N" },
							{ name => "OrigOrdModTime",   required => "N" },
							{
								name      => "Parties",
								required  => "N",
								component => "Y"
							},
							{
								name     => "TradeOriginationDate",
								required => "N"
							},
							{ name => "TradeDate",      required => "N" },
							{ name => "Account",        required => "N" },
							{ name => "AcctIDSource",   required => "N" },
							{ name => "AccountType",    required => "N" },
							{ name => "DayBookingInst", required => "N" },
							{ name => "BookingUnit",    required => "N" },
							{ name => "PreallocMethod", required => "N" },
							{ name => "AllocID",        required => "N" },
							{
								name     => "NoAllocs",
								required => "N",
								group    => [
									{
										name     => "AllocAccount",
										required => "N"
									},
									{
										name     => "AllocAcctIDSource",
										required => "N"
									},
									{
										name     => "AllocSettlCurrency",
										required => "N"
									},
									{
										name     => "IndividualAllocID",
										required => "N"
									},
									{
										name      => "NestedParties",
										required  => "N",
										component => "Y"
									},
									{ name => "AllocQty", required => "N" },
								]
							},
							{ name => "QtyType", required => "N" },
							{
								name      => "OrderQtyData",
								required  => "Y",
								component => "Y"
							},
							{
								name      => "CommissionData",
								required  => "N",
								component => "Y"
							},
							{ name => "OrderCapacity",      required => "N" },
							{ name => "OrderRestrictions",  required => "N" },
							{ name => "CustOrderCapacity",  required => "N" },
							{ name => "ForexReq",           required => "N" },
							{ name => "SettlCurrency",      required => "N" },
							{ name => "BookingType",        required => "N" },
							{ name => "Text",               required => "N" },
							{ name => "EncodedTextLen",     required => "N" },
							{ name => "EncodedText",        required => "N" },
							{ name => "PositionEffect",     required => "N" },
							{ name => "CoveredOrUncovered", required => "N" },
							{ name => "CashMargin",         required => "N" },
							{
								name     => "ClearingFeeIndicator",
								required => "N"
							},
							{ name => "SolicitedFlag",    required => "N" },
							{ name => "SideComplianceID", required => "N" },
						]
					},
					{
						name      => "Instrument",
						required  => "Y",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "SettlType",     required => "N" },
					{ name => "SettlDate",     required => "N" },
					{ name => "HandlInst",     required => "N" },
					{ name => "ExecInst",      required => "N" },
					{ name => "MinQty",        required => "N" },
					{ name => "MaxFloor",      required => "N" },
					{ name => "ExDestination", required => "N" },
					{
						name     => "NoTradingSessions",
						required => "N",
						group    => [
							{ name => "TradingSessionID", required => "N" },
							{
								name     => "TradingSessionSubID",
								required => "N"
							},
						]
					},
					{ name => "ProcessCode",  required => "N" },
					{ name => "PrevClosePx",  required => "N" },
					{ name => "LocateReqd",   required => "N" },
					{ name => "TransactTime", required => "Y" },
					{
						name      => "Stipulations",
						required  => "N",
						component => "Y"
					},
					{ name => "OrdType",   required => "Y" },
					{ name => "PriceType", required => "N" },
					{ name => "Price",     required => "N" },
					{ name => "StopPx",    required => "N" },
					{
						name      => "SpreadOrBenchmarkCurveData",
						required  => "N",
						component => "Y"
					},
					{
						name      => "YieldData",
						required  => "N",
						component => "Y"
					},
					{ name => "Currency",      required => "N" },
					{ name => "ComplianceID",  required => "N" },
					{ name => "IOIid",         required => "N" },
					{ name => "QuoteID",       required => "N" },
					{ name => "TimeInForce",   required => "N" },
					{ name => "EffectiveTime", required => "N" },
					{ name => "ExpireDate",    required => "N" },
					{ name => "ExpireTime",    required => "N" },
					{ name => "GTBookingInst", required => "N" },
					{ name => "MaxShow",       required => "N" },
					{
						name      => "PegInstructions",
						required  => "N",
						component => "Y"
					},
					{
						name      => "DiscretionInstructions",
						required  => "N",
						component => "Y"
					},
					{ name => "TargetStrategy",           required => "N" },
					{ name => "TargetStrategyParameters", required => "N" },
					{ name => "ParticipationRate",        required => "N" },
					{ name => "CancellationRights",       required => "N" },
					{ name => "MoneyLaunderingStatus",    required => "N" },
					{ name => "RegistID",                 required => "N" },
					{ name => "Designation",              required => "N" },
				]
			},
			{
				name    => "CrossOrderCancelRequest",
				msgtype => "u",
				msgcat  => "app",
				fields  => [
					{ name => "OrderID",             required => "N" },
					{ name => "CrossID",             required => "Y" },
					{ name => "OrigCrossID",         required => "Y" },
					{ name => "CrossType",           required => "Y" },
					{ name => "CrossPrioritization", required => "Y" },
					{
						name     => "NoSides",
						required => "Y",
						group    => [
							{ name => "Side",             required => "Y" },
							{ name => "OrigClOrdID",      required => "Y" },
							{ name => "ClOrdID",          required => "Y" },
							{ name => "SecondaryClOrdID", required => "N" },
							{ name => "ClOrdLinkID",      required => "N" },
							{ name => "OrigOrdModTime",   required => "N" },
							{
								name      => "Parties",
								required  => "N",
								component => "Y"
							},
							{
								name     => "TradeOriginationDate",
								required => "N"
							},
							{ name => "TradeDate", required => "N" },
							{
								name      => "OrderQtyData",
								required  => "Y",
								component => "Y"
							},
							{ name => "ComplianceID",   required => "N" },
							{ name => "Text",           required => "N" },
							{ name => "EncodedTextLen", required => "N" },
							{ name => "EncodedText",    required => "N" },
						]
					},
					{
						name      => "Instrument",
						required  => "Y",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "TransactTime", required => "Y" },
				]
			},
			{
				name    => "NewOrderMultileg",
				msgtype => "AB",
				msgcat  => "app",
				fields  => [
					{ name => "ClOrdID",          required => "Y" },
					{ name => "SecondaryClOrdID", required => "N" },
					{ name => "ClOrdLinkID",      required => "N" },
					{ name => "Parties", required => "N", component => "Y" },
					{ name => "TradeOriginationDate", required => "N" },
					{ name => "TradeDate",            required => "N" },
					{ name => "Account",              required => "N" },
					{ name => "AcctIDSource",         required => "N" },
					{ name => "AccountType",          required => "N" },
					{ name => "DayBookingInst",       required => "N" },
					{ name => "BookingUnit",          required => "N" },
					{ name => "PreallocMethod",       required => "N" },
					{ name => "AllocID",              required => "N" },
					{
						name     => "NoAllocs",
						required => "N",
						group    => [
							{ name => "AllocAccount",       required => "N" },
							{ name => "AllocAcctIDSource",  required => "N" },
							{ name => "AllocSettlCurrency", required => "N" },
							{ name => "IndividualAllocID",  required => "N" },
							{
								name      => "NestedParties3",
								required  => "N",
								component => "Y"
							},
							{ name => "AllocQty", required => "N" },
						]
					},
					{ name => "SettlType",            required => "N" },
					{ name => "SettlDate",            required => "N" },
					{ name => "CashMargin",           required => "N" },
					{ name => "ClearingFeeIndicator", required => "N" },
					{ name => "HandlInst",            required => "N" },
					{ name => "ExecInst",             required => "N" },
					{ name => "MinQty",               required => "N" },
					{ name => "MaxFloor",             required => "N" },
					{ name => "ExDestination",        required => "N" },
					{
						name     => "NoTradingSessions",
						required => "N",
						group    => [
							{ name => "TradingSessionID", required => "N" },
							{
								name     => "TradingSessionSubID",
								required => "N"
							},
						]
					},
					{ name => "ProcessCode", required => "N" },
					{ name => "Side",        required => "Y" },
					{
						name      => "Instrument",
						required  => "Y",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "PrevClosePx", required => "N" },
					{
						name     => "NoLegs",
						required => "Y",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
							{ name => "LegQty",      required => "N" },
							{ name => "LegSwapType", required => "N" },
							{
								name      => "LegStipulations",
								required  => "N",
								component => "Y"
							},
							{
								name     => "NoLegAllocs",
								required => "N",
								group    => [
									{
										name     => "LegAllocAccount",
										required => "N"
									},
									{
										name     => "LegIndividualAllocID",
										required => "N"
									},
									{
										name      => "NestedParties2",
										required  => "N",
										component => "Y"
									},
									{
										name     => "LegAllocQty",
										required => "N"
									},
									{
										name     => "LegAllocAcctIDSource",
										required => "N"
									},
									{
										name     => "LegSettlCurrency",
										required => "N"
									},
								]
							},
							{ name => "LegPositionEffect", required => "N" },
							{
								name     => "LegCoveredOrUncovered",
								required => "N"
							},
							{
								name      => "NestedParties",
								required  => "N",
								component => "Y"
							},
							{ name => "LegRefID",     required => "N" },
							{ name => "LegPrice",     required => "N" },
							{ name => "LegSettlType", required => "N" },
							{ name => "LegSettlDate", required => "N" },
						]
					},
					{ name => "LocateReqd",   required => "N" },
					{ name => "TransactTime", required => "Y" },
					{ name => "QtyType",      required => "N" },
					{
						name      => "OrderQtyData",
						required  => "Y",
						component => "Y"
					},
					{ name => "OrdType",       required => "Y" },
					{ name => "PriceType",     required => "N" },
					{ name => "Price",         required => "N" },
					{ name => "StopPx",        required => "N" },
					{ name => "Currency",      required => "N" },
					{ name => "ComplianceID",  required => "N" },
					{ name => "SolicitedFlag", required => "N" },
					{ name => "IOIid",         required => "N" },
					{ name => "QuoteID",       required => "N" },
					{ name => "TimeInForce",   required => "N" },
					{ name => "EffectiveTime", required => "N" },
					{ name => "ExpireDate",    required => "N" },
					{ name => "ExpireTime",    required => "N" },
					{ name => "GTBookingInst", required => "N" },
					{
						name      => "CommissionData",
						required  => "N",
						component => "Y"
					},
					{ name => "OrderCapacity",      required => "N" },
					{ name => "OrderRestrictions",  required => "N" },
					{ name => "CustOrderCapacity",  required => "N" },
					{ name => "ForexReq",           required => "N" },
					{ name => "SettlCurrency",      required => "N" },
					{ name => "BookingType",        required => "N" },
					{ name => "Text",               required => "N" },
					{ name => "EncodedTextLen",     required => "N" },
					{ name => "EncodedText",        required => "N" },
					{ name => "PositionEffect",     required => "N" },
					{ name => "CoveredOrUncovered", required => "N" },
					{ name => "MaxShow",            required => "N" },
					{
						name      => "PegInstructions",
						required  => "N",
						component => "Y"
					},
					{
						name      => "DiscretionInstructions",
						required  => "N",
						component => "Y"
					},
					{ name => "TargetStrategy",           required => "N" },
					{ name => "TargetStrategyParameters", required => "N" },
					{ name => "ParticipationRate",        required => "N" },
					{ name => "CancellationRights",       required => "N" },
					{ name => "MoneyLaunderingStatus",    required => "N" },
					{ name => "RegistID",                 required => "N" },
					{ name => "Designation",              required => "N" },
					{ name => "MultiLegRptTypeReq",       required => "N" },
				]
			},
			{
				name    => "MultilegOrderCancelReplaceRequest",
				msgtype => "AC",
				msgcat  => "app",
				fields  => [
					{ name => "OrderID",          required => "N" },
					{ name => "OrigClOrdID",      required => "Y" },
					{ name => "ClOrdID",          required => "Y" },
					{ name => "SecondaryClOrdID", required => "N" },
					{ name => "ClOrdLinkID",      required => "N" },
					{ name => "OrigOrdModTime",   required => "N" },
					{ name => "Parties", required => "N", component => "Y" },
					{ name => "TradeOriginationDate", required => "N" },
					{ name => "TradeDate",            required => "N" },
					{ name => "Account",              required => "N" },
					{ name => "AcctIDSource",         required => "N" },
					{ name => "AccountType",          required => "N" },
					{ name => "DayBookingInst",       required => "N" },
					{ name => "BookingUnit",          required => "N" },
					{ name => "PreallocMethod",       required => "N" },
					{ name => "AllocID",              required => "N" },
					{
						name     => "NoAllocs",
						required => "N",
						group    => [
							{ name => "AllocAccount",       required => "N" },
							{ name => "AllocAcctIDSource",  required => "N" },
							{ name => "AllocSettlCurrency", required => "N" },
							{ name => "IndividualAllocID",  required => "N" },
							{
								name      => "NestedParties3",
								required  => "N",
								component => "Y"
							},
							{ name => "AllocQty", required => "N" },
						]
					},
					{ name => "SettlType",            required => "N" },
					{ name => "SettlDate",            required => "N" },
					{ name => "CashMargin",           required => "N" },
					{ name => "ClearingFeeIndicator", required => "N" },
					{ name => "HandlInst",            required => "N" },
					{ name => "ExecInst",             required => "N" },
					{ name => "MinQty",               required => "N" },
					{ name => "MaxFloor",             required => "N" },
					{ name => "ExDestination",        required => "N" },
					{
						name     => "NoTradingSessions",
						required => "N",
						group    => [
							{ name => "TradingSessionID", required => "N" },
							{
								name     => "TradingSessionSubID",
								required => "N"
							},
						]
					},
					{ name => "ProcessCode", required => "N" },
					{ name => "Side",        required => "Y" },
					{
						name      => "Instrument",
						required  => "Y",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "PrevClosePx", required => "N" },
					{
						name     => "NoLegs",
						required => "Y",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
							{ name => "LegQty",      required => "N" },
							{ name => "LegSwapType", required => "N" },
							{
								name      => "LegStipulations",
								required  => "N",
								component => "Y"
							},
							{
								name     => "NoLegAllocs",
								required => "N",
								group    => [
									{
										name     => "LegAllocAccount",
										required => "N"
									},
									{
										name     => "LegIndividualAllocID",
										required => "N"
									},
									{
										name      => "NestedParties2",
										required  => "N",
										component => "Y"
									},
									{
										name     => "LegAllocQty",
										required => "N"
									},
									{
										name     => "LegAllocAcctIDSource",
										required => "N"
									},
									{
										name     => "LegSettlCurrency",
										required => "N"
									},
								]
							},
							{ name => "LegPositionEffect", required => "N" },
							{
								name     => "LegCoveredOrUncovered",
								required => "N"
							},
							{
								name      => "NestedParties",
								required  => "N",
								component => "Y"
							},
							{ name => "LegRefID",     required => "N" },
							{ name => "LegPrice",     required => "N" },
							{ name => "LegSettlType", required => "N" },
							{ name => "LegSettlDate", required => "N" },
						]
					},
					{ name => "LocateReqd",   required => "N" },
					{ name => "TransactTime", required => "Y" },
					{ name => "QtyType",      required => "N" },
					{
						name      => "OrderQtyData",
						required  => "Y",
						component => "Y"
					},
					{ name => "OrdType",       required => "Y" },
					{ name => "PriceType",     required => "N" },
					{ name => "Price",         required => "N" },
					{ name => "StopPx",        required => "N" },
					{ name => "Currency",      required => "N" },
					{ name => "ComplianceID",  required => "N" },
					{ name => "SolicitedFlag", required => "N" },
					{ name => "IOIid",         required => "N" },
					{ name => "QuoteID",       required => "N" },
					{ name => "TimeInForce",   required => "N" },
					{ name => "EffectiveTime", required => "N" },
					{ name => "ExpireDate",    required => "N" },
					{ name => "ExpireTime",    required => "N" },
					{ name => "GTBookingInst", required => "N" },
					{
						name      => "CommissionData",
						required  => "N",
						component => "Y"
					},
					{ name => "OrderCapacity",      required => "N" },
					{ name => "OrderRestrictions",  required => "N" },
					{ name => "CustOrderCapacity",  required => "N" },
					{ name => "ForexReq",           required => "N" },
					{ name => "SettlCurrency",      required => "N" },
					{ name => "BookingType",        required => "N" },
					{ name => "Text",               required => "N" },
					{ name => "EncodedTextLen",     required => "N" },
					{ name => "EncodedText",        required => "N" },
					{ name => "PositionEffect",     required => "N" },
					{ name => "CoveredOrUncovered", required => "N" },
					{ name => "MaxShow",            required => "N" },
					{
						name      => "PegInstructions",
						required  => "N",
						component => "Y"
					},
					{
						name      => "DiscretionInstructions",
						required  => "N",
						component => "Y"
					},
					{ name => "TargetStrategy",           required => "N" },
					{ name => "TargetStrategyParameters", required => "N" },
					{ name => "ParticipationRate",        required => "N" },
					{ name => "CancellationRights",       required => "N" },
					{ name => "MoneyLaunderingStatus",    required => "N" },
					{ name => "RegistID",                 required => "N" },
					{ name => "Designation",              required => "N" },
					{ name => "MultiLegRptTypeReq",       required => "N" },
				]
			},
			{
				name    => "BidRequest",
				msgtype => "k",
				msgcat  => "app",
				fields  => [
					{ name => "BidID",               required => "N" },
					{ name => "ClientBidID",         required => "Y" },
					{ name => "BidRequestTransType", required => "Y" },
					{ name => "ListName",            required => "N" },
					{ name => "TotNoRelatedSym",     required => "Y" },
					{ name => "BidType",             required => "Y" },
					{ name => "NumTickets",          required => "N" },
					{ name => "Currency",            required => "N" },
					{ name => "SideValue1",          required => "N" },
					{ name => "SideValue2",          required => "N" },
					{
						name     => "NoBidDescriptors",
						required => "N",
						group    => [
							{ name => "BidDescriptorType", required => "N" },
							{ name => "BidDescriptor",     required => "N" },
							{ name => "SideValueInd",      required => "N" },
							{ name => "LiquidityValue",    required => "N" },
							{
								name     => "LiquidityNumSecurities",
								required => "N"
							},
							{ name => "LiquidityPctLow",  required => "N" },
							{ name => "LiquidityPctHigh", required => "N" },
							{ name => "EFPTrackingError", required => "N" },
							{ name => "FairValue",        required => "N" },
							{ name => "OutsideIndexPct",  required => "N" },
							{ name => "ValueOfFutures",   required => "N" },
						]
					},
					{
						name     => "NoBidComponents",
						required => "N",
						group    => [
							{ name => "ListID",           required => "N" },
							{ name => "Side",             required => "N" },
							{ name => "TradingSessionID", required => "N" },
							{
								name     => "TradingSessionSubID",
								required => "N"
							},
							{ name => "NetGrossInd",  required => "N" },
							{ name => "SettlType",    required => "N" },
							{ name => "SettlDate",    required => "N" },
							{ name => "Account",      required => "N" },
							{ name => "AcctIDSource", required => "N" },
						]
					},
					{ name => "LiquidityIndType",    required => "N" },
					{ name => "WtAverageLiquidity",  required => "N" },
					{ name => "ExchangeForPhysical", required => "N" },
					{ name => "OutMainCntryUIndex",  required => "N" },
					{ name => "CrossPercent",        required => "N" },
					{ name => "ProgRptReqs",         required => "N" },
					{ name => "ProgPeriodInterval",  required => "N" },
					{ name => "IncTaxInd",           required => "N" },
					{ name => "ForexReq",            required => "N" },
					{ name => "NumBidders",          required => "N" },
					{ name => "TradeDate",           required => "N" },
					{ name => "BidTradeType",        required => "Y" },
					{ name => "BasisPxType",         required => "Y" },
					{ name => "StrikeTime",          required => "N" },
					{ name => "Text",                required => "N" },
					{ name => "EncodedTextLen",      required => "N" },
					{ name => "EncodedText",         required => "N" },
				]
			},
			{
				name    => "BidResponse",
				msgtype => "l",
				msgcat  => "app",
				fields  => [
					{ name => "BidID",       required => "N" },
					{ name => "ClientBidID", required => "N" },
					{
						name     => "NoBidComponents",
						required => "Y",
						group    => [
							{
								name      => "CommissionData",
								required  => "Y",
								component => "Y"
							},
							{ name => "ListID",           required => "N" },
							{ name => "Country",          required => "N" },
							{ name => "Side",             required => "N" },
							{ name => "Price",            required => "N" },
							{ name => "PriceType",        required => "N" },
							{ name => "FairValue",        required => "N" },
							{ name => "NetGrossInd",      required => "N" },
							{ name => "SettlType",        required => "N" },
							{ name => "SettlDate",        required => "N" },
							{ name => "TradingSessionID", required => "N" },
							{
								name     => "TradingSessionSubID",
								required => "N"
							},
							{ name => "Text",           required => "N" },
							{ name => "EncodedTextLen", required => "N" },
							{ name => "EncodedText",    required => "N" },
						]
					},
				]
			},
			{
				name    => "NewOrderList",
				msgtype => "E",
				msgcat  => "app",
				fields  => [
					{ name => "ListID",                     required => "Y" },
					{ name => "BidID",                      required => "N" },
					{ name => "ClientBidID",                required => "N" },
					{ name => "ProgRptReqs",                required => "N" },
					{ name => "BidType",                    required => "Y" },
					{ name => "ProgPeriodInterval",         required => "N" },
					{ name => "CancellationRights",         required => "N" },
					{ name => "MoneyLaunderingStatus",      required => "N" },
					{ name => "RegistID",                   required => "N" },
					{ name => "ListExecInstType",           required => "N" },
					{ name => "ListExecInst",               required => "N" },
					{ name => "EncodedListExecInstLen",     required => "N" },
					{ name => "EncodedListExecInst",        required => "N" },
					{ name => "AllowableOneSidednessPct",   required => "N" },
					{ name => "AllowableOneSidednessValue", required => "N" },
					{ name => "AllowableOneSidednessCurr",  required => "N" },
					{ name => "TotNoOrders",                required => "Y" },
					{ name => "LastFragment",               required => "N" },
					{
						name     => "NoOrders",
						required => "Y",
						group    => [
							{ name => "ClOrdID",          required => "Y" },
							{ name => "SecondaryClOrdID", required => "N" },
							{ name => "ListSeqNo",        required => "Y" },
							{ name => "ClOrdLinkID",      required => "N" },
							{ name => "SettlInstMode",    required => "N" },
							{
								name      => "Parties",
								required  => "N",
								component => "Y"
							},
							{
								name     => "TradeOriginationDate",
								required => "N"
							},
							{ name => "TradeDate",      required => "N" },
							{ name => "Account",        required => "N" },
							{ name => "AcctIDSource",   required => "N" },
							{ name => "AccountType",    required => "N" },
							{ name => "DayBookingInst", required => "N" },
							{ name => "BookingUnit",    required => "N" },
							{ name => "AllocID",        required => "N" },
							{ name => "PreallocMethod", required => "N" },
							{
								name     => "NoAllocs",
								required => "N",
								group    => [
									{
										name     => "AllocAccount",
										required => "N"
									},
									{
										name     => "AllocAcctIDSource",
										required => "N"
									},
									{
										name     => "AllocSettlCurrency",
										required => "N"
									},
									{
										name     => "IndividualAllocID",
										required => "N"
									},
									{
										name      => "NestedParties",
										required  => "N",
										component => "Y"
									},
									{ name => "AllocQty", required => "N" },
								]
							},
							{ name => "SettlType",  required => "N" },
							{ name => "SettlDate",  required => "N" },
							{ name => "CashMargin", required => "N" },
							{
								name     => "ClearingFeeIndicator",
								required => "N"
							},
							{ name => "HandlInst",     required => "N" },
							{ name => "ExecInst",      required => "N" },
							{ name => "MinQty",        required => "N" },
							{ name => "MaxFloor",      required => "N" },
							{ name => "ExDestination", required => "N" },
							{
								name     => "NoTradingSessions",
								required => "N",
								group    => [
									{
										name     => "TradingSessionID",
										required => "N"
									},
									{
										name     => "TradingSessionSubID",
										required => "N"
									},
								]
							},
							{ name => "ProcessCode", required => "N" },
							{
								name      => "Instrument",
								required  => "Y",
								component => "Y"
							},
							{
								name     => "NoUnderlyings",
								required => "N",
								group    => [
									{
										name      => "UnderlyingInstrument",
										required  => "N",
										component => "Y"
									},
								]
							},
							{ name => "PrevClosePx",  required => "N" },
							{ name => "Side",         required => "Y" },
							{ name => "SideValueInd", required => "N" },
							{ name => "LocateReqd",   required => "N" },
							{ name => "TransactTime", required => "N" },
							{
								name      => "Stipulations",
								required  => "N",
								component => "Y"
							},
							{ name => "QtyType", required => "N" },
							{
								name      => "OrderQtyData",
								required  => "Y",
								component => "Y"
							},
							{ name => "OrdType",   required => "N" },
							{ name => "PriceType", required => "N" },
							{ name => "Price",     required => "N" },
							{ name => "StopPx",    required => "N" },
							{
								name      => "SpreadOrBenchmarkCurveData",
								required  => "N",
								component => "Y"
							},
							{
								name      => "YieldData",
								required  => "N",
								component => "Y"
							},
							{ name => "Currency",      required => "N" },
							{ name => "ComplianceID",  required => "N" },
							{ name => "SolicitedFlag", required => "N" },
							{ name => "IOIid",         required => "N" },
							{ name => "QuoteID",       required => "N" },
							{ name => "TimeInForce",   required => "N" },
							{ name => "EffectiveTime", required => "N" },
							{ name => "ExpireDate",    required => "N" },
							{ name => "ExpireTime",    required => "N" },
							{ name => "GTBookingInst", required => "N" },
							{
								name      => "CommissionData",
								required  => "N",
								component => "Y"
							},
							{ name => "OrderCapacity",      required => "N" },
							{ name => "OrderRestrictions",  required => "N" },
							{ name => "CustOrderCapacity",  required => "N" },
							{ name => "ForexReq",           required => "N" },
							{ name => "SettlCurrency",      required => "N" },
							{ name => "BookingType",        required => "N" },
							{ name => "Text",               required => "N" },
							{ name => "EncodedTextLen",     required => "N" },
							{ name => "EncodedText",        required => "N" },
							{ name => "SettlDate2",         required => "N" },
							{ name => "OrderQty2",          required => "N" },
							{ name => "Price2",             required => "N" },
							{ name => "PositionEffect",     required => "N" },
							{ name => "CoveredOrUncovered", required => "N" },
							{ name => "MaxShow",            required => "N" },
							{
								name      => "PegInstructions",
								required  => "N",
								component => "Y"
							},
							{
								name      => "DiscretionInstructions",
								required  => "N",
								component => "Y"
							},
							{ name => "TargetStrategy", required => "N" },
							{
								name     => "TargetStrategyParameters",
								required => "N"
							},
							{ name => "ParticipationRate", required => "N" },
							{ name => "Designation",       required => "N" },
						]
					},
				]
			},
			{
				name    => "ListStrikePrice",
				msgtype => "m",
				msgcat  => "app",
				fields  => [
					{ name => "ListID",       required => "Y" },
					{ name => "TotNoStrikes", required => "Y" },
					{ name => "LastFragment", required => "N" },
					{
						name     => "NoStrikes",
						required => "Y",
						group    => [
							{
								name      => "Instrument",
								required  => "Y",
								component => "Y"
							},
						]
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
							{ name => "PrevClosePx",      required => "N" },
							{ name => "ClOrdID",          required => "N" },
							{ name => "SecondaryClOrdID", required => "N" },
							{ name => "Side",             required => "N" },
							{ name => "Price",            required => "Y" },
							{ name => "Currency",         required => "N" },
							{ name => "Text",             required => "N" },
							{ name => "EncodedTextLen",   required => "N" },
							{ name => "EncodedText",      required => "N" },
						]
					},
				]
			},
			{
				name    => "ListStatus",
				msgtype => "N",
				msgcat  => "app",
				fields  => [
					{ name => "ListID",                   required => "Y" },
					{ name => "ListStatusType",           required => "Y" },
					{ name => "NoRpts",                   required => "Y" },
					{ name => "ListOrderStatus",          required => "Y" },
					{ name => "RptSeq",                   required => "Y" },
					{ name => "ListStatusText",           required => "N" },
					{ name => "EncodedListStatusTextLen", required => "N" },
					{ name => "EncodedListStatusText",    required => "N" },
					{ name => "TransactTime",             required => "N" },
					{ name => "TotNoOrders",              required => "Y" },
					{ name => "LastFragment",             required => "N" },
					{
						name     => "NoOrders",
						required => "Y",
						group    => [
							{ name => "ClOrdID",          required => "Y" },
							{ name => "SecondaryClOrdID", required => "N" },
							{ name => "CumQty",           required => "Y" },
							{ name => "OrdStatus",        required => "Y" },
							{ name => "WorkingIndicator", required => "N" },
							{ name => "LeavesQty",        required => "Y" },
							{ name => "CxlQty",           required => "Y" },
							{ name => "AvgPx",            required => "Y" },
							{ name => "OrdRejReason",     required => "N" },
							{ name => "Text",             required => "N" },
							{ name => "EncodedTextLen",   required => "N" },
							{ name => "EncodedText",      required => "N" },
						]
					},
				]
			},
			{
				name    => "ListExecute",
				msgtype => "L",
				msgcat  => "app",
				fields  => [
					{ name => "ListID",         required => "Y" },
					{ name => "ClientBidID",    required => "N" },
					{ name => "BidID",          required => "N" },
					{ name => "TransactTime",   required => "Y" },
					{ name => "Text",           required => "N" },
					{ name => "EncodedTextLen", required => "N" },
					{ name => "EncodedText",    required => "N" },
				]
			},
			{
				name    => "ListCancelRequest",
				msgtype => "K",
				msgcat  => "app",
				fields  => [
					{ name => "ListID",               required => "Y" },
					{ name => "TransactTime",         required => "Y" },
					{ name => "TradeOriginationDate", required => "N" },
					{ name => "TradeDate",            required => "N" },
					{ name => "Text",                 required => "N" },
					{ name => "EncodedTextLen",       required => "N" },
					{ name => "EncodedText",          required => "N" },
				]
			},
			{
				name    => "ListStatusRequest",
				msgtype => "M",
				msgcat  => "app",
				fields  => [
					{ name => "ListID",         required => "Y" },
					{ name => "Text",           required => "N" },
					{ name => "EncodedTextLen", required => "N" },
					{ name => "EncodedText",    required => "N" },
				]
			},
			{
				name    => "AllocationInstruction",
				msgtype => "J",
				msgcat  => "app",
				fields  => [
					{ name => "AllocID",                required => "Y" },
					{ name => "AllocTransType",         required => "Y" },
					{ name => "AllocType",              required => "Y" },
					{ name => "SecondaryAllocID",       required => "N" },
					{ name => "RefAllocID",             required => "N" },
					{ name => "AllocCancReplaceReason", required => "N" },
					{ name => "AllocIntermedReqType",   required => "N" },
					{ name => "AllocLinkID",            required => "N" },
					{ name => "AllocLinkType",          required => "N" },
					{ name => "BookingRefID",           required => "N" },
					{ name => "AllocNoOrdersType",      required => "Y" },
					{
						name     => "NoOrders",
						required => "N",
						group    => [
							{ name => "ClOrdID",          required => "N" },
							{ name => "OrderID",          required => "N" },
							{ name => "SecondaryOrderID", required => "N" },
							{ name => "SecondaryClOrdID", required => "N" },
							{ name => "ListID",           required => "N" },
							{
								name      => "NestedParties2",
								required  => "N",
								component => "Y"
							},
							{ name => "OrderQty",        required => "N" },
							{ name => "OrderAvgPx",      required => "N" },
							{ name => "OrderBookingQty", required => "N" },
						]
					},
					{
						name     => "NoExecs",
						required => "N",
						group    => [
							{ name => "LastQty",         required => "N" },
							{ name => "ExecID",          required => "N" },
							{ name => "SecondaryExecID", required => "N" },
							{ name => "LastPx",          required => "N" },
							{ name => "LastParPx",       required => "N" },
							{ name => "LastCapacity",    required => "N" },
						]
					},
					{ name => "PreviouslyReported", required => "N" },
					{ name => "ReversalIndicator",  required => "N" },
					{ name => "MatchType",          required => "N" },
					{ name => "Side",               required => "Y" },
					{
						name      => "Instrument",
						required  => "Y",
						component => "Y"
					},
					{
						name      => "InstrumentExtension",
						required  => "N",
						component => "Y"
					},
					{
						name      => "FinancingDetails",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "Quantity",             required => "Y" },
					{ name => "QtyType",              required => "N" },
					{ name => "LastMkt",              required => "N" },
					{ name => "TradeOriginationDate", required => "N" },
					{ name => "TradingSessionID",     required => "N" },
					{ name => "TradingSessionSubID",  required => "N" },
					{ name => "PriceType",            required => "N" },
					{ name => "AvgPx",                required => "Y" },
					{ name => "AvgParPx",             required => "N" },
					{
						name      => "SpreadOrBenchmarkCurveData",
						required  => "N",
						component => "Y"
					},
					{ name => "Currency",       required => "N" },
					{ name => "AvgPxPrecision", required => "N" },
					{ name => "Parties", required => "N", component => "Y" },
					{ name => "TradeDate",               required => "Y" },
					{ name => "TransactTime",            required => "N" },
					{ name => "SettlType",               required => "N" },
					{ name => "SettlDate",               required => "N" },
					{ name => "BookingType",             required => "N" },
					{ name => "GrossTradeAmt",           required => "N" },
					{ name => "Concession",              required => "N" },
					{ name => "TotalTakedown",           required => "N" },
					{ name => "NetMoney",                required => "N" },
					{ name => "PositionEffect",          required => "N" },
					{ name => "AutoAcceptIndicator",     required => "N" },
					{ name => "Text",                    required => "N" },
					{ name => "EncodedTextLen",          required => "N" },
					{ name => "EncodedText",             required => "N" },
					{ name => "NumDaysInterest",         required => "N" },
					{ name => "AccruedInterestRate",     required => "N" },
					{ name => "AccruedInterestAmt",      required => "N" },
					{ name => "TotalAccruedInterestAmt", required => "N" },
					{ name => "InterestAtMaturity",      required => "N" },
					{ name => "EndAccruedInterestAmt",   required => "N" },
					{ name => "StartCash",               required => "N" },
					{ name => "EndCash",                 required => "N" },
					{ name => "LegalConfirm",            required => "N" },
					{
						name      => "Stipulations",
						required  => "N",
						component => "Y"
					},
					{
						name      => "YieldData",
						required  => "N",
						component => "Y"
					},
					{ name => "TotNoAllocs",  required => "N" },
					{ name => "LastFragment", required => "N" },
					{
						name     => "NoAllocs",
						required => "Y",
						group    => [
							{ name => "AllocAccount",      required => "Y" },
							{ name => "AllocAcctIDSource", required => "N" },
							{ name => "MatchStatus",       required => "N" },
							{ name => "AllocPrice",        required => "N" },
							{ name => "AllocQty",          required => "Y" },
							{ name => "IndividualAllocID", required => "N" },
							{ name => "ProcessCode",       required => "N" },
							{
								name      => "NestedParties",
								required  => "N",
								component => "Y"
							},
							{
								name     => "NotifyBrokerOfCredit",
								required => "N"
							},
							{ name => "AllocHandlInst", required => "N" },
							{ name => "AllocText",      required => "N" },
							{
								name     => "EncodedAllocTextLen",
								required => "N"
							},
							{ name => "EncodedAllocText", required => "N" },
							{
								name      => "CommissionData",
								required  => "N",
								component => "Y"
							},
							{ name => "AllocAvgPx",         required => "N" },
							{ name => "AllocNetMoney",      required => "N" },
							{ name => "SettlCurrAmt",       required => "N" },
							{ name => "AllocSettlCurrAmt",  required => "N" },
							{ name => "SettlCurrency",      required => "N" },
							{ name => "AllocSettlCurrency", required => "N" },
							{ name => "SettlCurrFxRate",    required => "N" },
							{
								name     => "SettlCurrFxRateCalc",
								required => "N"
							},
							{ name => "AccruedInterestAmt", required => "N" },
							{
								name     => "AllocAccruedInterestAmt",
								required => "N"
							},
							{
								name     => "AllocInterestAtMaturity",
								required => "N"
							},
							{ name => "SettlInstMode", required => "N" },
							{
								name     => "NoMiscFees",
								required => "N",
								group    => [
									{ name => "MiscFeeAmt", required => "N" },
									{
										name     => "MiscFeeCurr",
										required => "N"
									},
									{
										name     => "MiscFeeType",
										required => "N"
									},
									{
										name     => "MiscFeeBasis",
										required => "N"
									},
								]
							},
							{
								name     => "NoClearingInstructions",
								required => "N"
							},
							{
								name     => "ClearingInstruction",
								required => "N"
							},
							{
								name     => "ClearingFeeIndicator",
								required => "N"
							},
							{ name => "AllocSettlInstType", required => "N" },
							{
								name      => "SettlInstructionsData",
								required  => "N",
								component => "Y"
							},
						]
					},
				]
			},
			{
				name    => "AllocationInstructionAck",
				msgtype => "P",
				msgcat  => "app",
				fields  => [
					{ name => "AllocID", required => "Y" },
					{ name => "Parties", required => "N", component => "Y" },
					{ name => "SecondaryAllocID",     required => "N" },
					{ name => "TradeDate",            required => "N" },
					{ name => "TransactTime",         required => "Y" },
					{ name => "AllocStatus",          required => "Y" },
					{ name => "AllocRejCode",         required => "N" },
					{ name => "AllocType",            required => "N" },
					{ name => "AllocIntermedReqType", required => "N" },
					{ name => "MatchStatus",          required => "N" },
					{ name => "Product",              required => "N" },
					{ name => "SecurityType",         required => "N" },
					{ name => "Text",                 required => "N" },
					{ name => "EncodedTextLen",       required => "N" },
					{ name => "EncodedText",          required => "N" },
					{
						name     => "NoAllocs",
						required => "N",
						group    => [
							{ name => "AllocAccount",      required => "N" },
							{ name => "AllocAcctIDSource", required => "N" },
							{ name => "AllocPrice",        required => "N" },
							{ name => "IndividualAllocID", required => "N" },
							{
								name     => "IndividualAllocRejCode",
								required => "N"
							},
							{ name => "AllocText", required => "N" },
							{
								name     => "EncodedAllocTextLen",
								required => "N"
							},
							{ name => "EncodedAllocText", required => "N" },
						]
					},
				]
			},
			{
				name    => "AllocationReport",
				msgtype => "AS",
				msgcat  => "app",
				fields  => [
					{ name => "AllocReportID",          required => "Y" },
					{ name => "AllocID",                required => "N" },
					{ name => "AllocTransType",         required => "Y" },
					{ name => "AllocReportRefID",       required => "N" },
					{ name => "AllocCancReplaceReason", required => "N" },
					{ name => "SecondaryAllocID",       required => "N" },
					{ name => "AllocReportType",        required => "Y" },
					{ name => "AllocStatus",            required => "Y" },
					{ name => "AllocRejCode",           required => "N" },
					{ name => "RefAllocID",             required => "N" },
					{ name => "AllocIntermedReqType",   required => "N" },
					{ name => "AllocLinkID",            required => "N" },
					{ name => "AllocLinkType",          required => "N" },
					{ name => "BookingRefID",           required => "N" },
					{ name => "AllocNoOrdersType",      required => "Y" },
					{
						name     => "NoOrders",
						required => "N",
						group    => [
							{ name => "ClOrdID",          required => "N" },
							{ name => "OrderID",          required => "N" },
							{ name => "SecondaryOrderID", required => "N" },
							{ name => "SecondaryClOrdID", required => "N" },
							{ name => "ListID",           required => "N" },
							{
								name      => "NestedParties2",
								required  => "N",
								component => "Y"
							},
							{ name => "OrderQty",        required => "N" },
							{ name => "OrderAvgPx",      required => "N" },
							{ name => "OrderBookingQty", required => "N" },
						]
					},
					{
						name     => "NoExecs",
						required => "N",
						group    => [
							{ name => "LastQty",         required => "N" },
							{ name => "ExecID",          required => "N" },
							{ name => "SecondaryExecID", required => "N" },
							{ name => "LastPx",          required => "N" },
							{ name => "LastParPx",       required => "N" },
							{ name => "LastCapacity",    required => "N" },
						]
					},
					{ name => "PreviouslyReported", required => "N" },
					{ name => "ReversalIndicator",  required => "N" },
					{ name => "MatchType",          required => "N" },
					{ name => "Side",               required => "Y" },
					{
						name      => "Instrument",
						required  => "Y",
						component => "Y"
					},
					{
						name      => "InstrumentExtension",
						required  => "N",
						component => "Y"
					},
					{
						name      => "FinancingDetails",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "Quantity",             required => "Y" },
					{ name => "QtyType",              required => "N" },
					{ name => "LastMkt",              required => "N" },
					{ name => "TradeOriginationDate", required => "N" },
					{ name => "TradingSessionID",     required => "N" },
					{ name => "TradingSessionSubID",  required => "N" },
					{ name => "PriceType",            required => "N" },
					{ name => "AvgPx",                required => "Y" },
					{ name => "AvgParPx",             required => "N" },
					{
						name      => "SpreadOrBenchmarkCurveData",
						required  => "N",
						component => "Y"
					},
					{ name => "Currency",       required => "N" },
					{ name => "AvgPxPrecision", required => "N" },
					{ name => "Parties", required => "N", component => "Y" },
					{ name => "TradeDate",               required => "Y" },
					{ name => "TransactTime",            required => "N" },
					{ name => "SettlType",               required => "N" },
					{ name => "SettlDate",               required => "N" },
					{ name => "BookingType",             required => "N" },
					{ name => "GrossTradeAmt",           required => "N" },
					{ name => "Concession",              required => "N" },
					{ name => "TotalTakedown",           required => "N" },
					{ name => "NetMoney",                required => "N" },
					{ name => "PositionEffect",          required => "N" },
					{ name => "AutoAcceptIndicator",     required => "N" },
					{ name => "Text",                    required => "N" },
					{ name => "EncodedTextLen",          required => "N" },
					{ name => "EncodedText",             required => "N" },
					{ name => "NumDaysInterest",         required => "N" },
					{ name => "AccruedInterestRate",     required => "N" },
					{ name => "AccruedInterestAmt",      required => "N" },
					{ name => "TotalAccruedInterestAmt", required => "N" },
					{ name => "InterestAtMaturity",      required => "N" },
					{ name => "EndAccruedInterestAmt",   required => "N" },
					{ name => "StartCash",               required => "N" },
					{ name => "EndCash",                 required => "N" },
					{ name => "LegalConfirm",            required => "N" },
					{
						name      => "Stipulations",
						required  => "N",
						component => "Y"
					},
					{
						name      => "YieldData",
						required  => "N",
						component => "Y"
					},
					{ name => "TotNoAllocs",  required => "N" },
					{ name => "LastFragment", required => "N" },
					{
						name     => "NoAllocs",
						required => "Y",
						group    => [
							{ name => "AllocAccount",      required => "Y" },
							{ name => "AllocAcctIDSource", required => "N" },
							{ name => "MatchStatus",       required => "N" },
							{ name => "AllocPrice",        required => "N" },
							{ name => "AllocQty",          required => "Y" },
							{ name => "IndividualAllocID", required => "N" },
							{ name => "ProcessCode",       required => "N" },
							{
								name      => "NestedParties",
								required  => "N",
								component => "Y"
							},
							{
								name     => "NotifyBrokerOfCredit",
								required => "N"
							},
							{ name => "AllocHandlInst", required => "N" },
							{ name => "AllocText",      required => "N" },
							{
								name     => "EncodedAllocTextLen",
								required => "N"
							},
							{ name => "EncodedAllocText", required => "N" },
							{
								name      => "CommissionData",
								required  => "N",
								component => "Y"
							},
							{ name => "AllocAvgPx",         required => "N" },
							{ name => "AllocNetMoney",      required => "N" },
							{ name => "SettlCurrAmt",       required => "N" },
							{ name => "AllocSettlCurrAmt",  required => "N" },
							{ name => "SettlCurrency",      required => "N" },
							{ name => "AllocSettlCurrency", required => "N" },
							{ name => "SettlCurrFxRate",    required => "N" },
							{
								name     => "SettlCurrFxRateCalc",
								required => "N"
							},
							{
								name     => "AllocAccruedInterestAmt",
								required => "N"
							},
							{
								name     => "AllocInterestAtMaturity",
								required => "N"
							},
							{
								name     => "NoMiscFees",
								required => "N",
								group    => [
									{ name => "MiscFeeAmt", required => "N" },
									{
										name     => "MiscFeeCurr",
										required => "N"
									},
									{
										name     => "MiscFeeType",
										required => "N"
									},
									{
										name     => "MiscFeeBasis",
										required => "N"
									},
								]
							},
							{
								name     => "NoClearingInstructions",
								required => "N",
								group    => [
									{
										name     => "ClearingInstruction",
										required => "N"
									},
								]
							},
							{
								name     => "ClearingFeeIndicator",
								required => "N"
							},
							{ name => "AllocSettlInstType", required => "N" },
							{
								name      => "SettlInstructionsData",
								required  => "N",
								component => "Y"
							},
						]
					},
				]
			},
			{
				name    => "AllocationReportAck",
				msgtype => "AT",
				msgcat  => "app",
				fields  => [
					{ name => "AllocReportID", required => "Y" },
					{ name => "AllocID",       required => "Y" },
					{ name => "Parties", required => "N", component => "Y" },
					{ name => "SecondaryAllocID",     required => "N" },
					{ name => "TradeDate",            required => "N" },
					{ name => "TransactTime",         required => "Y" },
					{ name => "AllocStatus",          required => "Y" },
					{ name => "AllocRejCode",         required => "N" },
					{ name => "AllocReportType",      required => "N" },
					{ name => "AllocIntermedReqType", required => "N" },
					{ name => "MatchStatus",          required => "N" },
					{ name => "Product",              required => "N" },
					{ name => "SecurityType",         required => "N" },
					{ name => "Text",                 required => "N" },
					{ name => "EncodedTextLen",       required => "N" },
					{ name => "EncodedText",          required => "N" },
					{
						name     => "NoAllocs",
						required => "N",
						group    => [
							{ name => "AllocAccount",      required => "N" },
							{ name => "AllocAcctIDSource", required => "N" },
							{ name => "AllocPrice",        required => "N" },
							{ name => "IndividualAllocID", required => "N" },
							{
								name     => "IndividualAllocRejCode",
								required => "N"
							},
							{ name => "AllocText", required => "N" },
							{
								name     => "EncodedAllocTextLen",
								required => "N"
							},
							{ name => "EncodedAllocText", required => "N" },
						]
					},
				]
			},
			{
				name    => "Confirmation",
				msgtype => "AK",
				msgcat  => "app",
				fields  => [
					{ name => "ConfirmID",        required => "Y" },
					{ name => "ConfirmRefID",     required => "N" },
					{ name => "ConfirmReqID",     required => "N" },
					{ name => "ConfirmTransType", required => "Y" },
					{ name => "ConfirmType",      required => "Y" },
					{ name => "CopyMsgIndicator", required => "N" },
					{ name => "LegalConfirm",     required => "N" },
					{ name => "ConfirmStatus",    required => "Y" },
					{ name => "Parties", required => "N", component => "Y" },
					{
						name     => "NoOrders",
						required => "N",
						group    => [
							{ name => "ClOrdID",          required => "N" },
							{ name => "OrderID",          required => "N" },
							{ name => "SecondaryOrderID", required => "N" },
							{ name => "SecondaryClOrdID", required => "N" },
							{ name => "ListID",           required => "N" },
							{
								name      => "NestedParties2",
								required  => "N",
								component => "Y"
							},
							{ name => "OrderQty",        required => "N" },
							{ name => "OrderAvgPx",      required => "N" },
							{ name => "OrderBookingQty", required => "N" },
						]
					},
					{ name => "AllocID",           required => "N" },
					{ name => "SecondaryAllocID",  required => "N" },
					{ name => "IndividualAllocID", required => "N" },
					{ name => "TransactTime",      required => "Y" },
					{ name => "TradeDate",         required => "Y" },
					{
						name      => "TrdRegTimestamps",
						required  => "N",
						component => "Y"
					},
					{
						name      => "Instrument",
						required  => "Y",
						component => "Y"
					},
					{
						name      => "InstrumentExtension",
						required  => "N",
						component => "Y"
					},
					{
						name      => "FinancingDetails",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "Y",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name     => "NoLegs",
						required => "Y",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name      => "YieldData",
						required  => "N",
						component => "Y"
					},
					{ name => "AllocQty", required => "Y" },
					{ name => "QtyType",  required => "N" },
					{ name => "Side",     required => "Y" },
					{ name => "Currency", required => "N" },
					{ name => "LastMkt",  required => "N" },
					{
						name     => "NoCapacities",
						required => "Y",
						group    => [
							{ name => "OrderCapacity",     required => "Y" },
							{ name => "OrderRestrictions", required => "N" },
							{ name => "OrderCapacityQty",  required => "Y" },
						]
					},
					{ name => "AllocAccount",      required => "Y" },
					{ name => "AllocAcctIDSource", required => "N" },
					{ name => "AllocAccountType",  required => "N" },
					{ name => "AvgPx",             required => "Y" },
					{ name => "AvgPxPrecision",    required => "N" },
					{ name => "PriceType",         required => "N" },
					{ name => "AvgParPx",          required => "N" },
					{
						name      => "SpreadOrBenchmarkCurveData",
						required  => "N",
						component => "Y"
					},
					{ name => "ReportedPx",            required => "N" },
					{ name => "Text",                  required => "N" },
					{ name => "EncodedTextLen",        required => "N" },
					{ name => "EncodedText",           required => "N" },
					{ name => "ProcessCode",           required => "N" },
					{ name => "GrossTradeAmt",         required => "Y" },
					{ name => "NumDaysInterest",       required => "N" },
					{ name => "ExDate",                required => "N" },
					{ name => "AccruedInterestRate",   required => "N" },
					{ name => "AccruedInterestAmt",    required => "N" },
					{ name => "InterestAtMaturity",    required => "N" },
					{ name => "EndAccruedInterestAmt", required => "N" },
					{ name => "StartCash",             required => "N" },
					{ name => "EndCash",               required => "N" },
					{ name => "Concession",            required => "N" },
					{ name => "TotalTakedown",         required => "N" },
					{ name => "NetMoney",              required => "Y" },
					{ name => "MaturityNetMoney",      required => "N" },
					{ name => "SettlCurrAmt",          required => "N" },
					{ name => "SettlCurrency",         required => "N" },
					{ name => "SettlCurrFxRate",       required => "N" },
					{ name => "SettlCurrFxRateCalc",   required => "N" },
					{ name => "SettlType",             required => "N" },
					{ name => "SettlDate",             required => "N" },
					{
						name      => "SettlInstructionsData",
						required  => "N",
						component => "Y"
					},
					{
						name      => "CommissionData",
						required  => "N",
						component => "Y"
					},
					{ name => "SharedCommission", required => "N" },
					{
						name      => "Stipulations",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoMiscFees",
						required => "N",
						group    => [
							{ name => "MiscFeeAmt",   required => "N" },
							{ name => "MiscFeeCurr",  required => "N" },
							{ name => "MiscFeeType",  required => "N" },
							{ name => "MiscFeeBasis", required => "N" },
						]
					},
				]
			},
			{
				name    => "ConfirmationAck",
				msgtype => "AU",
				msgcat  => "app",
				fields  => [
					{ name => "ConfirmID",        required => "Y" },
					{ name => "TradeDate",        required => "Y" },
					{ name => "TransactTime",     required => "Y" },
					{ name => "AffirmStatus",     required => "Y" },
					{ name => "ConfirmRejReason", required => "N" },
					{ name => "MatchStatus",      required => "N" },
					{ name => "Text",             required => "N" },
					{ name => "EncodedTextLen",   required => "N" },
					{ name => "EncodedText",      required => "N" },
				]
			},
			{
				name    => "ConfirmationRequest",
				msgtype => "BH",
				msgcat  => "app",
				fields  => [
					{ name => "ConfirmReqID", required => "Y" },
					{ name => "ConfirmType",  required => "Y" },
					{
						name     => "NoOrders",
						required => "N",
						group    => [
							{ name => "ClOrdID",          required => "N" },
							{ name => "OrderID",          required => "N" },
							{ name => "SecondaryOrderID", required => "N" },
							{ name => "SecondaryClOrdID", required => "N" },
							{ name => "ListID",           required => "N" },
							{
								name      => "NestedParties2",
								required  => "N",
								component => "Y"
							},
							{ name => "OrderQty",        required => "N" },
							{ name => "OrderAvgPx",      required => "N" },
							{ name => "OrderBookingQty", required => "N" },
						]
					},
					{ name => "AllocID",           required => "N" },
					{ name => "SecondaryAllocID",  required => "N" },
					{ name => "IndividualAllocID", required => "N" },
					{ name => "TransactTime",      required => "Y" },
					{ name => "AllocAccount",      required => "N" },
					{ name => "AllocAcctIDSource", required => "N" },
					{ name => "AllocAccountType",  required => "N" },
					{ name => "Text",              required => "N" },
					{ name => "EncodedTextLen",    required => "N" },
					{ name => "EncodedText",       required => "N" },
				]
			},
			{
				name    => "SettlementInstructions",
				msgtype => "T",
				msgcat  => "app",
				fields  => [
					{ name => "SettlInstMsgID",      required => "Y" },
					{ name => "SettlInstReqID",      required => "N" },
					{ name => "SettlInstMode",       required => "Y" },
					{ name => "SettlInstReqRejCode", required => "N" },
					{ name => "Text",                required => "N" },
					{ name => "EncodedTextLen",      required => "N" },
					{ name => "EncodedText",         required => "N" },
					{ name => "SettlInstSource",     required => "N" },
					{ name => "ClOrdID",             required => "N" },
					{ name => "TransactTime",        required => "Y" },
					{
						name     => "NoSettlInst",
						required => "N",
						group    => [
							{ name => "SettlInstID",        required => "N" },
							{ name => "SettlInstTransType", required => "N" },
							{ name => "SettlInstRefID",     required => "N" },
							{
								name      => "Parties",
								required  => "N",
								component => "Y"
							},
							{ name => "Side",           required => "N" },
							{ name => "Product",        required => "N" },
							{ name => "SecurityType",   required => "N" },
							{ name => "CFICode",        required => "N" },
							{ name => "EffectiveTime",  required => "N" },
							{ name => "ExpireTime",     required => "N" },
							{ name => "LastUpdateTime", required => "N" },
							{
								name      => "SettlInstructionsData",
								required  => "N",
								component => "Y"
							},
							{ name => "PaymentMethod",     required => "N" },
							{ name => "PaymentRef",        required => "N" },
							{ name => "CardHolderName",    required => "N" },
							{ name => "CardNumber",        required => "N" },
							{ name => "CardStartDate",     required => "N" },
							{ name => "CardExpDate",       required => "N" },
							{ name => "CardIssNum",        required => "N" },
							{ name => "PaymentDate",       required => "N" },
							{ name => "PaymentRemitterID", required => "N" },
						]
					},
				]
			},
			{
				name    => "SettlementInstructionRequest",
				msgtype => "AV",
				msgcat  => "app",
				fields  => [
					{ name => "SettlInstReqID", required => "Y" },
					{ name => "TransactTime",   required => "Y" },
					{ name => "Parties", required => "N", component => "Y" },
					{ name => "AllocAccount",      required => "N" },
					{ name => "AllocAcctIDSource", required => "N" },
					{ name => "Side",              required => "N" },
					{ name => "Product",           required => "N" },
					{ name => "SecurityType",      required => "N" },
					{ name => "CFICode",           required => "N" },
					{ name => "EffectiveTime",     required => "N" },
					{ name => "ExpireTime",        required => "N" },
					{ name => "LastUpdateTime",    required => "N" },
					{ name => "StandInstDbType",   required => "N" },
					{ name => "StandInstDbName",   required => "N" },
					{ name => "StandInstDbID",     required => "N" },
				]
			},
			{
				name    => "TradeCaptureReportRequest",
				msgtype => "AD",
				msgcat  => "app",
				fields  => [
					{ name => "TradeRequestID",          required => "Y" },
					{ name => "TradeRequestType",        required => "Y" },
					{ name => "SubscriptionRequestType", required => "N" },
					{ name => "TradeReportID",           required => "N" },
					{ name => "SecondaryTradeReportID",  required => "N" },
					{ name => "ExecID",                  required => "N" },
					{ name => "ExecType",                required => "N" },
					{ name => "OrderID",                 required => "N" },
					{ name => "ClOrdID",                 required => "N" },
					{ name => "MatchStatus",             required => "N" },
					{ name => "TrdType",                 required => "N" },
					{ name => "TrdSubType",              required => "N" },
					{ name => "TransferReason",          required => "N" },
					{ name => "SecondaryTrdType",        required => "N" },
					{ name => "TradeLinkID",             required => "N" },
					{ name => "TrdMatchID",              required => "N" },
					{ name => "Parties", required => "N", component => "Y" },
					{
						name      => "Instrument",
						required  => "N",
						component => "Y"
					},
					{
						name      => "InstrumentExtension",
						required  => "N",
						component => "Y"
					},
					{
						name      => "FinancingDetails",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name     => "NoDates",
						required => "N",
						group    => [
							{ name => "TradeDate",    required => "N" },
							{ name => "TransactTime", required => "N" },
						]
					},
					{ name => "ClearingBusinessDate",  required => "N" },
					{ name => "TradingSessionID",      required => "N" },
					{ name => "TradingSessionSubID",   required => "N" },
					{ name => "TimeBracket",           required => "N" },
					{ name => "Side",                  required => "N" },
					{ name => "MultiLegReportingType", required => "N" },
					{ name => "TradeInputSource",      required => "N" },
					{ name => "TradeInputDevice",      required => "N" },
					{ name => "ResponseTransportType", required => "N" },
					{ name => "ResponseDestination",   required => "N" },
					{ name => "Text",                  required => "N" },
					{ name => "EncodedTextLen",        required => "N" },
					{ name => "EncodedText",           required => "N" },
				]
			},
			{
				name    => "TradeCaptureReportRequestAck",
				msgtype => "AQ",
				msgcat  => "app",
				fields  => [
					{ name => "TradeRequestID",          required => "Y" },
					{ name => "TradeRequestType",        required => "Y" },
					{ name => "SubscriptionRequestType", required => "N" },
					{ name => "TotNumTradeReports",      required => "N" },
					{ name => "TradeRequestResult",      required => "Y" },
					{ name => "TradeRequestStatus",      required => "Y" },
					{
						name      => "Instrument",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "MultiLegReportingType", required => "N" },
					{ name => "ResponseTransportType", required => "N" },
					{ name => "ResponseDestination",   required => "N" },
					{ name => "Text",                  required => "N" },
					{ name => "EncodedTextLen",        required => "N" },
					{ name => "EncodedText",           required => "N" },
				]
			},
			{
				name    => "TradeCaptureReport",
				msgtype => "AE",
				msgcat  => "app",
				fields  => [
					{ name => "TradeReportID",             required => "Y" },
					{ name => "TradeReportTransType",      required => "N" },
					{ name => "TradeReportType",           required => "N" },
					{ name => "TradeRequestID",            required => "N" },
					{ name => "TrdType",                   required => "N" },
					{ name => "TrdSubType",                required => "N" },
					{ name => "SecondaryTrdType",          required => "N" },
					{ name => "TransferReason",            required => "N" },
					{ name => "ExecType",                  required => "N" },
					{ name => "TotNumTradeReports",        required => "N" },
					{ name => "LastRptRequested",          required => "N" },
					{ name => "UnsolicitedIndicator",      required => "N" },
					{ name => "SubscriptionRequestType",   required => "N" },
					{ name => "TradeReportRefID",          required => "N" },
					{ name => "SecondaryTradeReportRefID", required => "N" },
					{ name => "SecondaryTradeReportID",    required => "N" },
					{ name => "TradeLinkID",               required => "N" },
					{ name => "TrdMatchID",                required => "N" },
					{ name => "ExecID",                    required => "N" },
					{ name => "OrdStatus",                 required => "N" },
					{ name => "SecondaryExecID",           required => "N" },
					{ name => "ExecRestatementReason",     required => "N" },
					{ name => "PreviouslyReported",        required => "Y" },
					{ name => "PriceType",                 required => "N" },
					{
						name      => "Instrument",
						required  => "Y",
						component => "Y"
					},
					{
						name      => "FinancingDetails",
						required  => "N",
						component => "Y"
					},
					{
						name      => "OrderQtyData",
						required  => "N",
						component => "Y"
					},
					{ name => "QtyType", required => "N" },
					{
						name      => "YieldData",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "UnderlyingTradingSessionID", required => "N" },
					{
						name     => "UnderlyingTradingSessionSubID",
						required => "N"
					},
					{ name => "LastQty",              required => "Y" },
					{ name => "LastPx",               required => "Y" },
					{ name => "LastParPx",            required => "N" },
					{ name => "LastSpotRate",         required => "N" },
					{ name => "LastForwardPoints",    required => "N" },
					{ name => "LastMkt",              required => "N" },
					{ name => "TradeDate",            required => "Y" },
					{ name => "ClearingBusinessDate", required => "N" },
					{ name => "AvgPx",                required => "N" },
					{
						name      => "SpreadOrBenchmarkCurveData",
						required  => "N",
						component => "Y"
					},
					{ name => "AvgPxIndicator", required => "N" },
					{
						name      => "PositionAmountData",
						required  => "N",
						component => "Y"
					},
					{ name => "MultiLegReportingType", required => "N" },
					{ name => "TradeLegRefID",         required => "N" },
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
							{ name => "LegQty",      required => "N" },
							{ name => "LegSwapType", required => "N" },
							{
								name      => "LegStipulations",
								required  => "N",
								component => "Y"
							},
							{ name => "LegPositionEffect", required => "N" },
							{
								name     => "LegCoveredOrUncovered",
								required => "N"
							},
							{
								name      => "NestedParties",
								required  => "N",
								component => "Y"
							},
							{ name => "LegRefID",     required => "N" },
							{ name => "LegPrice",     required => "N" },
							{ name => "LegSettlType", required => "N" },
							{ name => "LegSettlDate", required => "N" },
							{ name => "LegLastPx",    required => "N" },
						]
					},
					{ name => "TransactTime", required => "Y" },
					{
						name      => "TrdRegTimestamps",
						required  => "N",
						component => "Y"
					},
					{ name => "SettlType",   required => "N" },
					{ name => "SettlDate",   required => "N" },
					{ name => "MatchStatus", required => "N" },
					{ name => "MatchType",   required => "N" },
					{
						name     => "NoSides",
						required => "Y",
						group    => [
							{ name => "Side",             required => "Y" },
							{ name => "OrderID",          required => "Y" },
							{ name => "SecondaryOrderID", required => "N" },
							{ name => "ClOrdID",          required => "N" },
							{ name => "SecondaryClOrdID", required => "N" },
							{ name => "ListID",           required => "N" },
							{
								name      => "Parties",
								required  => "N",
								component => "Y"
							},
							{ name => "Account",      required => "N" },
							{ name => "AcctIDSource", required => "N" },
							{ name => "AccountType",  required => "N" },
							{ name => "ProcessCode",  required => "N" },
							{ name => "OddLot",       required => "N" },
							{
								name     => "NoClearingInstructions",
								required => "N",
								group    => [
									{
										name     => "ClearingInstruction",
										required => "N"
									},
								]
							},
							{
								name     => "ClearingFeeIndicator",
								required => "N"
							},
							{ name => "TradeInputSource",  required => "N" },
							{ name => "TradeInputDevice",  required => "N" },
							{ name => "OrderInputDevice",  required => "N" },
							{ name => "Currency",          required => "N" },
							{ name => "ComplianceID",      required => "N" },
							{ name => "SolicitedFlag",     required => "N" },
							{ name => "OrderCapacity",     required => "N" },
							{ name => "OrderRestrictions", required => "N" },
							{ name => "CustOrderCapacity", required => "N" },
							{ name => "OrdType",           required => "N" },
							{ name => "ExecInst",          required => "N" },
							{ name => "TransBkdTime",      required => "N" },
							{ name => "TradingSessionID",  required => "N" },
							{
								name     => "TradingSessionSubID",
								required => "N"
							},
							{ name => "TimeBracket", required => "N" },
							{
								name      => "CommissionData",
								required  => "N",
								component => "Y"
							},
							{ name => "GrossTradeAmt",   required => "N" },
							{ name => "NumDaysInterest", required => "N" },
							{ name => "ExDate",          required => "N" },
							{
								name     => "AccruedInterestRate",
								required => "N"
							},
							{ name => "AccruedInterestAmt", required => "N" },
							{ name => "InterestAtMaturity", required => "N" },
							{
								name     => "EndAccruedInterestAmt",
								required => "N"
							},
							{ name => "StartCash",       required => "N" },
							{ name => "EndCash",         required => "N" },
							{ name => "Concession",      required => "N" },
							{ name => "TotalTakedown",   required => "N" },
							{ name => "NetMoney",        required => "N" },
							{ name => "SettlCurrAmt",    required => "N" },
							{ name => "SettlCurrency",   required => "N" },
							{ name => "SettlCurrFxRate", required => "N" },
							{
								name     => "SettlCurrFxRateCalc",
								required => "N"
							},
							{ name => "PositionEffect", required => "N" },
							{ name => "Text",           required => "N" },
							{ name => "EncodedTextLen", required => "N" },
							{ name => "EncodedText",    required => "N" },
							{
								name     => "SideMultiLegReportingType",
								required => "N"
							},
							{
								name     => "NoContAmts",
								required => "N",
								group    => [
									{
										name     => "ContAmtType",
										required => "N"
									},
									{
										name     => "ContAmtValue",
										required => "N"
									},
									{
										name     => "ContAmtCurr",
										required => "N"
									},
								]
							},
							{
								name      => "Stipulations",
								required  => "N",
								component => "Y"
							},
							{
								name     => "NoMiscFees",
								required => "N",
								group    => [
									{ name => "MiscFeeAmt", required => "N" },
									{
										name     => "MiscFeeCurr",
										required => "N"
									},
									{
										name     => "MiscFeeType",
										required => "N"
									},
									{
										name     => "MiscFeeBasis",
										required => "N"
									},
								]
							},
							{ name => "ExchangeRule", required => "N" },
							{
								name     => "TradeAllocIndicator",
								required => "N"
							},
							{ name => "PreallocMethod", required => "N" },
							{ name => "AllocID",        required => "N" },
							{
								name     => "NoAllocs",
								required => "N",
								group    => [
									{
										name     => "AllocAccount",
										required => "N"
									},
									{
										name     => "AllocAcctIDSource",
										required => "N"
									},
									{
										name     => "AllocSettlCurrency",
										required => "N"
									},
									{
										name     => "IndividualAllocID",
										required => "N"
									},
									{
										name      => "NestedParties2",
										required  => "N",
										component => "Y"
									},
									{ name => "AllocQty", required => "N" },
								]
							},
						]
					},
					{ name => "CopyMsgIndicator",    required => "N" },
					{ name => "PublishTrdIndicator", required => "N" },
					{ name => "ShortSaleReason",     required => "N" },
				]
			},
			{
				name    => "TradeCaptureReportAck",
				msgtype => "AR",
				msgcat  => "app",
				fields  => [
					{ name => "TradeReportID",             required => "Y" },
					{ name => "TradeReportTransType",      required => "N" },
					{ name => "TradeReportType",           required => "N" },
					{ name => "TrdType",                   required => "N" },
					{ name => "TrdSubType",                required => "N" },
					{ name => "SecondaryTrdType",          required => "N" },
					{ name => "TransferReason",            required => "N" },
					{ name => "ExecType",                  required => "Y" },
					{ name => "TradeReportRefID",          required => "N" },
					{ name => "SecondaryTradeReportRefID", required => "N" },
					{ name => "TrdRptStatus",              required => "N" },
					{ name => "TradeReportRejectReason",   required => "N" },
					{ name => "SecondaryTradeReportID",    required => "N" },
					{ name => "SubscriptionRequestType",   required => "N" },
					{ name => "TradeLinkID",               required => "N" },
					{ name => "TrdMatchID",                required => "N" },
					{ name => "ExecID",                    required => "N" },
					{ name => "SecondaryExecID",           required => "N" },
					{
						name      => "Instrument",
						required  => "Y",
						component => "Y"
					},
					{ name => "TransactTime", required => "N" },
					{
						name      => "TrdRegTimestamps",
						required  => "N",
						component => "Y"
					},
					{ name => "ResponseTransportType", required => "N" },
					{ name => "ResponseDestination",   required => "N" },
					{ name => "Text",                  required => "N" },
					{ name => "EncodedTextLen",        required => "N" },
					{ name => "EncodedText",           required => "N" },
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
							{ name => "LegQty",      required => "N" },
							{ name => "LegSwapType", required => "N" },
							{
								name      => "LegStipulations",
								required  => "N",
								component => "Y"
							},
							{ name => "LegPositionEffect", required => "N" },
							{
								name     => "LegCoveredOrUncovered",
								required => "N"
							},
							{
								name      => "NestedParties",
								required  => "N",
								component => "Y"
							},
							{ name => "LegRefID",     required => "N" },
							{ name => "LegPrice",     required => "N" },
							{ name => "LegSettlType", required => "N" },
							{ name => "LegSettlDate", required => "N" },
							{ name => "LegLastPx",    required => "N" },
						]
					},
					{ name => "ClearingFeeIndicator", required => "N" },
					{ name => "OrderCapacity",        required => "N" },
					{ name => "OrderRestrictions",    required => "N" },
					{ name => "CustOrderCapacity",    required => "N" },
					{ name => "Account",              required => "N" },
					{ name => "AcctIDSource",         required => "N" },
					{ name => "AccountType",          required => "N" },
					{ name => "PositionEffect",       required => "N" },
					{ name => "PreallocMethod",       required => "N" },
					{
						name     => "NoAllocs",
						required => "N",
						group    => [
							{ name => "AllocAccount",       required => "N" },
							{ name => "AllocAcctIDSource",  required => "N" },
							{ name => "AllocSettlCurrency", required => "N" },
							{ name => "IndividualAllocID",  required => "N" },
							{
								name      => "NestedParties2",
								required  => "N",
								component => "Y"
							},
							{ name => "AllocQty", required => "N" },
						]
					},
				]
			},
			{
				name    => "RegistrationInstructions",
				msgtype => "o",
				msgcat  => "app",
				fields  => [
					{ name => "RegistID",        required => "Y" },
					{ name => "RegistTransType", required => "Y" },
					{ name => "RegistRefID",     required => "Y" },
					{ name => "ClOrdID",         required => "N" },
					{ name => "Parties", required => "N", component => "Y" },
					{ name => "Account", required => "N" },
					{ name => "AcctIDSource",     required => "N" },
					{ name => "RegistAcctType",   required => "N" },
					{ name => "TaxAdvantageType", required => "N" },
					{ name => "OwnershipType",    required => "N" },
					{
						name     => "NoRegistDtls",
						required => "N",
						group    => [
							{ name => "RegistDtls",  required => "N" },
							{ name => "RegistEmail", required => "N" },
							{ name => "MailingDtls", required => "N" },
							{ name => "MailingInst", required => "N" },
							{
								name      => "NestedParties",
								required  => "N",
								component => "Y"
							},
							{ name => "OwnerType",   required => "N" },
							{ name => "DateOfBirth", required => "N" },
							{
								name     => "InvestorCountryOfResidence",
								required => "N"
							},
						]
					},
					{
						name     => "NoDistribInsts",
						required => "N",
						group    => [
							{
								name     => "DistribPaymentMethod",
								required => "N"
							},
							{ name => "DistribPercentage", required => "N" },
							{ name => "CashDistribCurr",   required => "N" },
							{
								name     => "CashDistribAgentName",
								required => "N"
							},
							{
								name     => "CashDistribAgentCode",
								required => "N"
							},
							{
								name     => "CashDistribAgentAcctNumber",
								required => "N"
							},
							{ name => "CashDistribPayRef", required => "N" },
							{
								name     => "CashDistribAgentAcctName",
								required => "N"
							},
						]
					},
				]
			},
			{
				name    => "RegistrationInstructionsResponse",
				msgtype => "p",
				msgcat  => "app",
				fields  => [
					{ name => "RegistID",        required => "Y" },
					{ name => "RegistTransType", required => "Y" },
					{ name => "RegistRefID",     required => "Y" },
					{ name => "ClOrdID",         required => "N" },
					{ name => "Parties", required => "N", component => "Y" },
					{ name => "Account", required => "N" },
					{ name => "AcctIDSource",        required => "N" },
					{ name => "RegistStatus",        required => "Y" },
					{ name => "RegistRejReasonCode", required => "N" },
					{ name => "RegistRejReasonText", required => "N" },
				]
			},
			{
				name    => "PositionMaintenanceRequest",
				msgtype => "AL",
				msgcat  => "app",
				fields  => [
					{ name => "PosReqID",             required => "Y" },
					{ name => "PosTransType",         required => "Y" },
					{ name => "PosMaintAction",       required => "Y" },
					{ name => "OrigPosReqRefID",      required => "N" },
					{ name => "PosMaintRptRefID",     required => "N" },
					{ name => "ClearingBusinessDate", required => "Y" },
					{ name => "SettlSessID",          required => "N" },
					{ name => "SettlSessSubID",       required => "N" },
					{ name => "Parties", required => "Y", component => "Y" },
					{ name => "Account", required => "Y" },
					{ name => "AcctIDSource", required => "N" },
					{ name => "AccountType",  required => "Y" },
					{
						name      => "Instrument",
						required  => "Y",
						component => "Y"
					},
					{ name => "Currency", required => "N" },
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name     => "NoTradingSessions",
						required => "N",
						group    => [
							{ name => "TradingSessionID", required => "N" },
							{
								name     => "TradingSessionSubID",
								required => "N"
							},
						]
					},
					{ name => "TransactTime", required => "Y" },
					{
						name      => "PositionQty",
						required  => "Y",
						component => "Y"
					},
					{ name => "AdjustmentType", required => "N" },
					{
						name     => "ContraryInstructionIndicator",
						required => "N"
					},
					{ name => "PriorSpreadIndicator", required => "N" },
					{ name => "ThresholdAmount",      required => "N" },
					{ name => "Text",                 required => "N" },
					{ name => "EncodedTextLen",       required => "N" },
					{ name => "EncodedText",          required => "N" },
				]
			},
			{
				name    => "PositionMaintenanceReport",
				msgtype => "AM",
				msgcat  => "app",
				fields  => [
					{ name => "PosMaintRptID",        required => "Y" },
					{ name => "PosTransType",         required => "Y" },
					{ name => "PosReqID",             required => "N" },
					{ name => "PosMaintAction",       required => "Y" },
					{ name => "OrigPosReqRefID",      required => "Y" },
					{ name => "PosMaintStatus",       required => "Y" },
					{ name => "PosMaintResult",       required => "N" },
					{ name => "ClearingBusinessDate", required => "Y" },
					{ name => "SettlSessID",          required => "N" },
					{ name => "SettlSessSubID",       required => "N" },
					{ name => "Parties", required => "N", component => "Y" },
					{ name => "Account", required => "Y" },
					{ name => "AcctIDSource", required => "N" },
					{ name => "AccountType",  required => "Y" },
					{
						name      => "Instrument",
						required  => "Y",
						component => "Y"
					},
					{ name => "Currency", required => "N" },
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name     => "NoTradingSessions",
						required => "N",
						group    => [
							{ name => "TradingSessionID", required => "N" },
							{
								name     => "TradingSessionSubID",
								required => "N"
							},
						]
					},
					{ name => "TransactTime", required => "Y" },
					{
						name      => "PositionQty",
						required  => "Y",
						component => "Y"
					},
					{
						name      => "PositionAmountData",
						required  => "Y",
						component => "Y"
					},
					{ name => "AdjustmentType",  required => "N" },
					{ name => "ThresholdAmount", required => "N" },
					{ name => "Text",            required => "N" },
					{ name => "EncodedTextLen",  required => "N" },
					{ name => "EncodedText",     required => "N" },
				]
			},
			{
				name    => "RequestForPositions",
				msgtype => "AN",
				msgcat  => "app",
				fields  => [
					{ name => "PosReqID",                required => "Y" },
					{ name => "PosReqType",              required => "Y" },
					{ name => "MatchStatus",             required => "N" },
					{ name => "SubscriptionRequestType", required => "N" },
					{ name => "Parties", required => "Y", component => "Y" },
					{ name => "Account", required => "Y" },
					{ name => "AcctIDSource", required => "N" },
					{ name => "AccountType",  required => "Y" },
					{
						name      => "Instrument",
						required  => "N",
						component => "Y"
					},
					{ name => "Currency", required => "N" },
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "ClearingBusinessDate", required => "Y" },
					{ name => "SettlSessID",          required => "N" },
					{ name => "SettlSessSubID",       required => "N" },
					{
						name     => "NoTradingSessions",
						required => "N",
						group    => [
							{ name => "TradingSessionID", required => "N" },
							{
								name     => "TradingSessionSubID",
								required => "N"
							},
						]
					},
					{ name => "TransactTime",          required => "Y" },
					{ name => "ResponseTransportType", required => "N" },
					{ name => "ResponseDestination",   required => "N" },
					{ name => "Text",                  required => "N" },
					{ name => "EncodedTextLen",        required => "N" },
					{ name => "EncodedText",           required => "N" },
				]
			},
			{
				name    => "RequestForPositionsAck",
				msgtype => "AO",
				msgcat  => "app",
				fields  => [
					{ name => "PosMaintRptID",        required => "Y" },
					{ name => "PosReqID",             required => "N" },
					{ name => "TotalNumPosReports",   required => "N" },
					{ name => "UnsolicitedIndicator", required => "N" },
					{ name => "PosReqResult",         required => "Y" },
					{ name => "PosReqStatus",         required => "Y" },
					{ name => "Parties", required => "Y", component => "Y" },
					{ name => "Account", required => "Y" },
					{ name => "AcctIDSource", required => "N" },
					{ name => "AccountType",  required => "Y" },
					{
						name      => "Instrument",
						required  => "N",
						component => "Y"
					},
					{ name => "Currency", required => "N" },
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "ResponseTransportType", required => "N" },
					{ name => "ResponseDestination",   required => "N" },
					{ name => "Text",                  required => "N" },
					{ name => "EncodedTextLen",        required => "N" },
					{ name => "EncodedText",           required => "N" },
				]
			},
			{
				name    => "PositionReport",
				msgtype => "AP",
				msgcat  => "app",
				fields  => [
					{ name => "PosMaintRptID",           required => "Y" },
					{ name => "PosReqID",                required => "N" },
					{ name => "PosReqType",              required => "N" },
					{ name => "SubscriptionRequestType", required => "N" },
					{ name => "TotalNumPosReports",      required => "N" },
					{ name => "UnsolicitedIndicator",    required => "N" },
					{ name => "PosReqResult",            required => "Y" },
					{ name => "ClearingBusinessDate",    required => "Y" },
					{ name => "SettlSessID",             required => "N" },
					{ name => "SettlSessSubID",          required => "N" },
					{ name => "Parties", required => "Y", component => "Y" },
					{ name => "Account", required => "Y" },
					{ name => "AcctIDSource", required => "N" },
					{ name => "AccountType",  required => "Y" },
					{
						name      => "Instrument",
						required  => "N",
						component => "Y"
					},
					{ name => "Currency",        required => "N" },
					{ name => "SettlPrice",      required => "Y" },
					{ name => "SettlPriceType",  required => "Y" },
					{ name => "PriorSettlPrice", required => "Y" },
					{
						name     => "NoLegs",
						required => "N",
						group    => [
							{
								name      => "InstrumentLeg",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
							{
								name     => "UnderlyingSettlPrice",
								required => "Y"
							},
							{
								name     => "UnderlyingSettlPriceType",
								required => "Y"
							},
						]
					},
					{
						name      => "PositionQty",
						required  => "Y",
						component => "Y"
					},
					{
						name      => "PositionAmountData",
						required  => "Y",
						component => "Y"
					},
					{ name => "RegistStatus",   required => "N" },
					{ name => "DeliveryDate",   required => "N" },
					{ name => "Text",           required => "N" },
					{ name => "EncodedTextLen", required => "N" },
					{ name => "EncodedText",    required => "N" },
				]
			},
			{
				name    => "AssignmentReport",
				msgtype => "AW",
				msgcat  => "app",
				fields  => [
					{ name => "AsgnRptID",               required => "Y" },
					{ name => "TotNumAssignmentReports", required => "N" },
					{ name => "LastRptRequested",        required => "N" },
					{ name => "Parties", required => "Y", component => "Y" },
					{ name => "Account", required => "N" },
					{ name => "AccountType", required => "Y" },
					{
						name      => "Instrument",
						required  => "N",
						component => "Y"
					},
					{ name => "Currency", required => "N" },
					{ name => "NoLegs",   required => "N" },
					{
						name      => "InstrumentLeg",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{
						name      => "PositionQty",
						required  => "Y",
						component => "Y"
					},
					{
						name      => "PositionAmountData",
						required  => "Y",
						component => "Y"
					},
					{ name => "ThresholdAmount",      required => "N" },
					{ name => "SettlPrice",           required => "Y" },
					{ name => "SettlPriceType",       required => "Y" },
					{ name => "UnderlyingSettlPrice", required => "Y" },
					{ name => "ExpireDate",           required => "N" },
					{ name => "AssignmentMethod",     required => "Y" },
					{ name => "AssignmentUnit",       required => "N" },
					{ name => "OpenInterest",         required => "Y" },
					{ name => "ExerciseMethod",       required => "Y" },
					{ name => "SettlSessID",          required => "Y" },
					{ name => "SettlSessSubID",       required => "Y" },
					{ name => "ClearingBusinessDate", required => "Y" },
					{ name => "Text",                 required => "N" },
					{ name => "EncodedTextLen",       required => "N" },
					{ name => "EncodedText",          required => "N" },
				]
			},
			{
				name    => "CollateralRequest",
				msgtype => "AX",
				msgcat  => "app",
				fields  => [
					{ name => "CollReqID",      required => "Y" },
					{ name => "CollAsgnReason", required => "Y" },
					{ name => "TransactTime",   required => "Y" },
					{ name => "ExpireTime",     required => "N" },
					{ name => "Parties", required => "N", component => "Y" },
					{ name => "Account", required => "N" },
					{ name => "AccountType",      required => "N" },
					{ name => "ClOrdID",          required => "N" },
					{ name => "OrderID",          required => "N" },
					{ name => "SecondaryOrderID", required => "N" },
					{ name => "SecondaryClOrdID", required => "N" },
					{
						name     => "NoExecs",
						required => "N",
						group    => [ { name => "ExecID", required => "N" }, ]
					},
					{
						name     => "NoTrades",
						required => "N",
						group    => [
							{ name => "TradeReportID", required => "N" },
							{
								name     => "SecondaryTradeReportID",
								required => "N"
							},
						]
					},
					{
						name      => "Instrument",
						required  => "N",
						component => "Y"
					},
					{
						name      => "FinancingDetails",
						required  => "N",
						component => "Y"
					},
					{ name => "SettlDate", required => "N" },
					{ name => "Quantity",  required => "N" },
					{ name => "QtyType",   required => "N" },
					{ name => "Currency",  required => "N" },
					{ name => "NoLegs",    required => "N" },
					{
						name      => "InstrumentLeg",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
							{ name => "CollAction", required => "N" },
						]
					},
					{ name => "MarginExcess",    required => "N" },
					{ name => "TotalNetValue",   required => "N" },
					{ name => "CashOutstanding", required => "N" },
					{
						name      => "TrdRegTimestamps",
						required  => "N",
						component => "Y"
					},
					{ name => "Side", required => "N" },
					{
						name     => "NoMiscFees",
						required => "N",
						group    => [
							{ name => "MiscFeeAmt",   required => "N" },
							{ name => "MiscFeeCurr",  required => "N" },
							{ name => "MiscFeeType",  required => "N" },
							{ name => "MiscFeeBasis", required => "N" },
						]
					},
					{ name => "Price",                 required => "N" },
					{ name => "PriceType",             required => "N" },
					{ name => "AccruedInterestAmt",    required => "N" },
					{ name => "EndAccruedInterestAmt", required => "N" },
					{ name => "StartCash",             required => "N" },
					{ name => "EndCash",               required => "N" },
					{
						name      => "SpreadOrBenchmarkCurveData",
						required  => "N",
						component => "Y"
					},
					{
						name      => "Stipulations",
						required  => "N",
						component => "Y"
					},
					{ name => "TradingSessionID",     required => "N" },
					{ name => "TradingSessionSubID",  required => "N" },
					{ name => "SettlSessID",          required => "N" },
					{ name => "SettlSessSubID",       required => "N" },
					{ name => "ClearingBusinessDate", required => "N" },
					{ name => "Text",                 required => "N" },
					{ name => "EncodedTextLen",       required => "N" },
					{ name => "EncodedText",          required => "N" },
				]
			},
			{
				name    => "CollateralAssignment",
				msgtype => "AY",
				msgcat  => "app",
				fields  => [
					{ name => "CollAsgnID",        required => "Y" },
					{ name => "CollReqID",         required => "N" },
					{ name => "CollAsgnReason",    required => "Y" },
					{ name => "CollAsgnTransType", required => "Y" },
					{ name => "CollAsgnRefID",     required => "N" },
					{ name => "TransactTime",      required => "Y" },
					{ name => "ExpireTime",        required => "N" },
					{ name => "Parties", required => "N", component => "Y" },
					{ name => "Account", required => "N" },
					{ name => "AccountType",      required => "N" },
					{ name => "ClOrdID",          required => "N" },
					{ name => "OrderID",          required => "N" },
					{ name => "SecondaryOrderID", required => "N" },
					{ name => "SecondaryClOrdID", required => "N" },
					{
						name     => "NoExecs",
						required => "N",
						group    => [ { name => "ExecID", required => "N" }, ]
					},
					{
						name     => "NoTrades",
						required => "N",
						group    => [
							{ name => "TradeReportID", required => "N" },
							{
								name     => "SecondaryTradeReportID",
								required => "N"
							},
						]
					},
					{
						name      => "Instrument",
						required  => "N",
						component => "Y"
					},
					{
						name      => "FinancingDetails",
						required  => "N",
						component => "Y"
					},
					{ name => "SettlDate", required => "N" },
					{ name => "Quantity",  required => "N" },
					{ name => "QtyType",   required => "N" },
					{ name => "Currency",  required => "N" },
					{ name => "NoLegs",    required => "N" },
					{
						name      => "InstrumentLeg",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
							{ name => "CollAction", required => "N" },
						]
					},
					{ name => "MarginExcess",    required => "N" },
					{ name => "TotalNetValue",   required => "N" },
					{ name => "CashOutstanding", required => "N" },
					{
						name      => "TrdRegTimestamps",
						required  => "N",
						component => "Y"
					},
					{ name => "Side", required => "N" },
					{
						name     => "NoMiscFees",
						required => "N",
						group    => [
							{ name => "MiscFeeAmt",   required => "N" },
							{ name => "MiscFeeCurr",  required => "N" },
							{ name => "MiscFeeType",  required => "N" },
							{ name => "MiscFeeBasis", required => "N" },
						]
					},
					{ name => "Price",                 required => "N" },
					{ name => "PriceType",             required => "N" },
					{ name => "AccruedInterestAmt",    required => "N" },
					{ name => "EndAccruedInterestAmt", required => "N" },
					{ name => "StartCash",             required => "N" },
					{ name => "EndCash",               required => "N" },
					{
						name      => "SpreadOrBenchmarkCurveData",
						required  => "N",
						component => "Y"
					},
					{
						name      => "Stipulations",
						required  => "N",
						component => "Y"
					},
					{
						name      => "SettlInstructionsData",
						required  => "N",
						component => "Y"
					},
					{ name => "TradingSessionID",     required => "N" },
					{ name => "TradingSessionSubID",  required => "N" },
					{ name => "SettlSessID",          required => "N" },
					{ name => "SettlSessSubID",       required => "N" },
					{ name => "ClearingBusinessDate", required => "N" },
					{ name => "Text",                 required => "N" },
					{ name => "EncodedTextLen",       required => "N" },
					{ name => "EncodedText",          required => "N" },
				]
			},
			{
				name    => "CollateralResponse",
				msgtype => "AZ",
				msgcat  => "app",
				fields  => [
					{ name => "CollRespID",           required => "Y" },
					{ name => "CollAsgnID",           required => "Y" },
					{ name => "CollReqID",            required => "N" },
					{ name => "CollAsgnReason",       required => "Y" },
					{ name => "CollAsgnTransType",    required => "N" },
					{ name => "CollAsgnRespType",     required => "Y" },
					{ name => "CollAsgnRejectReason", required => "N" },
					{ name => "TransactTime",         required => "Y" },
					{ name => "Parties", required => "N", component => "Y" },
					{ name => "Account", required => "N" },
					{ name => "AccountType",      required => "N" },
					{ name => "ClOrdID",          required => "N" },
					{ name => "OrderID",          required => "N" },
					{ name => "SecondaryOrderID", required => "N" },
					{ name => "SecondaryClOrdID", required => "N" },
					{
						name     => "NoExecs",
						required => "N",
						group    => [ { name => "ExecID", required => "N" }, ]
					},
					{
						name     => "NoTrades",
						required => "N",
						group    => [
							{ name => "TradeReportID", required => "N" },
							{
								name     => "SecondaryTradeReportID",
								required => "N"
							},
						]
					},
					{
						name      => "Instrument",
						required  => "N",
						component => "Y"
					},
					{
						name      => "FinancingDetails",
						required  => "N",
						component => "Y"
					},
					{ name => "SettlDate", required => "N" },
					{ name => "Quantity",  required => "N" },
					{ name => "QtyType",   required => "N" },
					{ name => "Currency",  required => "N" },
					{ name => "NoLegs",    required => "N" },
					{
						name      => "InstrumentLeg",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
							{ name => "CollAction", required => "N" },
						]
					},
					{ name => "MarginExcess",    required => "N" },
					{ name => "TotalNetValue",   required => "N" },
					{ name => "CashOutstanding", required => "N" },
					{
						name      => "TrdRegTimestamps",
						required  => "N",
						component => "Y"
					},
					{ name => "Side", required => "N" },
					{
						name     => "NoMiscFees",
						required => "N",
						group    => [
							{ name => "MiscFeeAmt",   required => "N" },
							{ name => "MiscFeeCurr",  required => "N" },
							{ name => "MiscFeeType",  required => "N" },
							{ name => "MiscFeeBasis", required => "N" },
						]
					},
					{ name => "Price",                 required => "N" },
					{ name => "PriceType",             required => "N" },
					{ name => "AccruedInterestAmt",    required => "N" },
					{ name => "EndAccruedInterestAmt", required => "N" },
					{ name => "StartCash",             required => "N" },
					{ name => "EndCash",               required => "N" },
					{
						name      => "SpreadOrBenchmarkCurveData",
						required  => "N",
						component => "Y"
					},
					{
						name      => "Stipulations",
						required  => "N",
						component => "Y"
					},
					{ name => "Text",           required => "N" },
					{ name => "EncodedTextLen", required => "N" },
					{ name => "EncodedText",    required => "N" },
				]
			},
			{
				name    => "CollateralReport",
				msgtype => "BA",
				msgcat  => "app",
				fields  => [
					{ name => "CollRptID",        required => "Y" },
					{ name => "CollInquiryID",    required => "N" },
					{ name => "CollStatus",       required => "Y" },
					{ name => "TotNumReports",    required => "N" },
					{ name => "LastRptRequested", required => "N" },
					{ name => "Parties", required => "N", component => "Y" },
					{ name => "Account", required => "N" },
					{ name => "AccountType",      required => "N" },
					{ name => "ClOrdID",          required => "N" },
					{ name => "OrderID",          required => "N" },
					{ name => "SecondaryOrderID", required => "N" },
					{ name => "SecondaryClOrdID", required => "N" },
					{
						name     => "NoExecs",
						required => "N",
						group    => [ { name => "ExecID", required => "N" }, ]
					},
					{
						name     => "NoTrades",
						required => "N",
						group    => [
							{ name => "TradeReportID", required => "N" },
							{
								name     => "SecondaryTradeReportID",
								required => "N"
							},
						]
					},
					{
						name      => "Instrument",
						required  => "N",
						component => "Y"
					},
					{
						name      => "FinancingDetails",
						required  => "N",
						component => "Y"
					},
					{ name => "SettlDate", required => "N" },
					{ name => "Quantity",  required => "N" },
					{ name => "QtyType",   required => "N" },
					{ name => "Currency",  required => "N" },
					{ name => "NoLegs",    required => "N" },
					{
						name      => "InstrumentLeg",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "MarginExcess",    required => "N" },
					{ name => "TotalNetValue",   required => "N" },
					{ name => "CashOutstanding", required => "N" },
					{
						name      => "TrdRegTimestamps",
						required  => "N",
						component => "Y"
					},
					{ name => "Side", required => "N" },
					{
						name     => "NoMiscFees",
						required => "N",
						group    => [
							{ name => "MiscFeeAmt",   required => "N" },
							{ name => "MiscFeeCurr",  required => "N" },
							{ name => "MiscFeeType",  required => "N" },
							{ name => "MiscFeeBasis", required => "N" },
						]
					},
					{ name => "Price",                 required => "N" },
					{ name => "PriceType",             required => "N" },
					{ name => "AccruedInterestAmt",    required => "N" },
					{ name => "EndAccruedInterestAmt", required => "N" },
					{ name => "StartCash",             required => "N" },
					{ name => "EndCash",               required => "N" },
					{
						name      => "SpreadOrBenchmarkCurveData",
						required  => "N",
						component => "Y"
					},
					{
						name      => "Stipulations",
						required  => "N",
						component => "Y"
					},
					{
						name      => "SettlInstructionsData",
						required  => "N",
						component => "Y"
					},
					{ name => "TradingSessionID",     required => "N" },
					{ name => "TradingSessionSubID",  required => "N" },
					{ name => "SettlSessID",          required => "N" },
					{ name => "SettlSessSubID",       required => "N" },
					{ name => "ClearingBusinessDate", required => "N" },
					{ name => "Text",                 required => "N" },
					{ name => "EncodedTextLen",       required => "N" },
					{ name => "EncodedText",          required => "N" },
				]
			},
			{
				name    => "CollateralInquiry",
				msgtype => "BB",
				msgcat  => "app",
				fields  => [
					{ name => "CollInquiryID", required => "N" },
					{
						name     => "NoCollInquiryQualifier",
						required => "N",
						group    => [
							{
								name     => "CollInquiryQualifier",
								required => "N"
							},
						]
					},
					{ name => "SubscriptionRequestType", required => "N" },
					{ name => "ResponseTransportType",   required => "N" },
					{ name => "ResponseDestination",     required => "N" },
					{ name => "Parties", required => "N", component => "Y" },
					{ name => "Account", required => "N" },
					{ name => "AccountType",      required => "N" },
					{ name => "ClOrdID",          required => "N" },
					{ name => "OrderID",          required => "N" },
					{ name => "SecondaryOrderID", required => "N" },
					{ name => "SecondaryClOrdID", required => "N" },
					{
						name     => "NoExecs",
						required => "N",
						group    => [ { name => "ExecID", required => "N" }, ]
					},
					{
						name     => "NoTrades",
						required => "N",
						group    => [
							{ name => "TradeReportID", required => "N" },
							{
								name     => "SecondaryTradeReportID",
								required => "N"
							},
						]
					},
					{
						name      => "Instrument",
						required  => "N",
						component => "Y"
					},
					{
						name      => "FinancingDetails",
						required  => "N",
						component => "Y"
					},
					{ name => "SettlDate", required => "N" },
					{ name => "Quantity",  required => "N" },
					{ name => "QtyType",   required => "N" },
					{ name => "Currency",  required => "N" },
					{ name => "NoLegs",    required => "N" },
					{
						name      => "InstrumentLeg",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "MarginExcess",    required => "N" },
					{ name => "TotalNetValue",   required => "N" },
					{ name => "CashOutstanding", required => "N" },
					{
						name      => "TrdRegTimestamps",
						required  => "N",
						component => "Y"
					},
					{ name => "Side",                  required => "N" },
					{ name => "Price",                 required => "N" },
					{ name => "PriceType",             required => "N" },
					{ name => "AccruedInterestAmt",    required => "N" },
					{ name => "EndAccruedInterestAmt", required => "N" },
					{ name => "StartCash",             required => "N" },
					{ name => "EndCash",               required => "N" },
					{
						name      => "SpreadOrBenchmarkCurveData",
						required  => "N",
						component => "Y"
					},
					{
						name      => "Stipulations",
						required  => "N",
						component => "Y"
					},
					{
						name      => "SettlInstructionsData",
						required  => "N",
						component => "Y"
					},
					{ name => "TradingSessionID",     required => "N" },
					{ name => "TradingSessionSubID",  required => "N" },
					{ name => "SettlSessID",          required => "N" },
					{ name => "SettlSessSubID",       required => "N" },
					{ name => "ClearingBusinessDate", required => "N" },
					{ name => "Text",                 required => "N" },
					{ name => "EncodedTextLen",       required => "N" },
					{ name => "EncodedText",          required => "N" },
				]
			},
			{
				name    => "NetworkStatusRequest",
				msgtype => "BC",
				msgcat  => "app",
				fields  => [
					{ name => "NetworkRequestType", required => "Y" },
					{ name => "NetworkRequestID",   required => "Y" },
					{
						name     => "NoCompIDs",
						required => "N",
						group    => [
							{ name => "RefCompID",  required => "N" },
							{ name => "RefSubID",   required => "N" },
							{ name => "LocationID", required => "N" },
							{ name => "DeskID",     required => "N" },
						]
					},
				]
			},
			{
				name    => "NetworkStatusResponse",
				msgtype => "BD",
				msgcat  => "app",
				fields  => [
					{ name => "NetworkStatusResponseType", required => "Y" },
					{ name => "NetworkRequestID",          required => "N" },
					{ name => "NetworkResponseID",         required => "N" },
					{ name => "LastNetworkResponseID",     required => "N" },
					{
						name     => "NoCompIDs",
						required => "Y",
						group    => [
							{ name => "RefCompID",   required => "N" },
							{ name => "RefSubID",    required => "N" },
							{ name => "LocationID",  required => "N" },
							{ name => "DeskID",      required => "N" },
							{ name => "StatusValue", required => "N" },
							{ name => "StatusText",  required => "N" },
						]
					},
				]
			},
			{
				name    => "CollateralInquiryAck",
				msgtype => "BG",
				msgcat  => "app",
				fields  => [
					{ name => "CollInquiryID",     required => "Y" },
					{ name => "CollInquiryStatus", required => "Y" },
					{ name => "CollInquiryResult", required => "N" },
					{
						name     => "NoCollInquiryQualifier",
						required => "N",
						group    => [
							{
								name     => "CollInquiryQualifier",
								required => "N"
							},
						]
					},
					{ name => "TotNumReports", required => "N" },
					{ name => "Parties", required => "N", component => "Y" },
					{ name => "Account", required => "N" },
					{ name => "AccountType",      required => "N" },
					{ name => "ClOrdID",          required => "N" },
					{ name => "OrderID",          required => "N" },
					{ name => "SecondaryOrderID", required => "N" },
					{ name => "SecondaryClOrdID", required => "N" },
					{
						name     => "NoExecs",
						required => "N",
						group    => [ { name => "ExecID", required => "N" }, ]
					},
					{
						name     => "NoTrades",
						required => "N",
						group    => [
							{ name => "TradeReportID", required => "N" },
							{
								name     => "SecondaryTradeReportID",
								required => "N"
							},
						]
					},
					{
						name      => "Instrument",
						required  => "N",
						component => "Y"
					},
					{
						name      => "FinancingDetails",
						required  => "N",
						component => "Y"
					},
					{ name => "SettlDate", required => "N" },
					{ name => "Quantity",  required => "N" },
					{ name => "QtyType",   required => "N" },
					{ name => "Currency",  required => "N" },
					{ name => "NoLegs",    required => "N" },
					{
						name      => "InstrumentLeg",
						required  => "N",
						component => "Y"
					},
					{
						name     => "NoUnderlyings",
						required => "N",
						group    => [
							{
								name      => "UnderlyingInstrument",
								required  => "N",
								component => "Y"
							},
						]
					},
					{ name => "TradingSessionID",      required => "N" },
					{ name => "TradingSessionSubID",   required => "N" },
					{ name => "SettlSessID",           required => "N" },
					{ name => "SettlSessSubID",        required => "N" },
					{ name => "ClearingBusinessDate",  required => "N" },
					{ name => "ResponseTransportType", required => "N" },
					{ name => "ResponseDestination",   required => "N" },
					{ name => "Text",                  required => "N" },
					{ name => "EncodedTextLen",        required => "N" },
					{ name => "EncodedText",           required => "N" },
				]
			},
		],

		components => [
			{
				name   => "Instrument",
				fields => [
					{ name => "Symbol",           required => "Y" },
					{ name => "SymbolSfx",        required => "N" },
					{ name => "SecurityID",       required => "N" },
					{ name => "SecurityIDSource", required => "N" },
					{
						name     => "NoSecurityAltID",
						required => "N",
						group    => [
							{ name => "SecurityAltID", required => "N" },
							{
								name     => "SecurityAltIDSource",
								required => "N"
							},
						]
					},
					{ name => "Product",                    required => "N" },
					{ name => "CFICode",                    required => "N" },
					{ name => "SecurityType",               required => "N" },
					{ name => "SecuritySubType",            required => "N" },
					{ name => "MaturityMonthYear",          required => "N" },
					{ name => "MaturityDate",               required => "N" },
					{ name => "CouponPaymentDate",          required => "N" },
					{ name => "IssueDate",                  required => "N" },
					{ name => "RepoCollateralSecurityType", required => "N" },
					{ name => "RepurchaseTerm",             required => "N" },
					{ name => "RepurchaseRate",             required => "N" },
					{ name => "Factor",                     required => "N" },
					{ name => "CreditRating",               required => "N" },
					{ name => "InstrRegistry",              required => "N" },
					{ name => "CountryOfIssue",             required => "N" },
					{ name => "StateOrProvinceOfIssue",     required => "N" },
					{ name => "LocaleOfIssue",              required => "N" },
					{ name => "RedemptionDate",             required => "N" },
					{ name => "StrikePrice",                required => "N" },
					{ name => "StrikeCurrency",             required => "N" },
					{ name => "OptAttribute",               required => "N" },
					{ name => "ContractMultiplier",         required => "N" },
					{ name => "CouponRate",                 required => "N" },
					{ name => "SecurityExchange",           required => "N" },
					{ name => "Issuer",                     required => "N" },
					{ name => "EncodedIssuerLen",           required => "N" },
					{ name => "EncodedIssuer",              required => "N" },
					{ name => "SecurityDesc",               required => "N" },
					{ name => "EncodedSecurityDescLen",     required => "N" },
					{ name => "EncodedSecurityDesc",        required => "N" },
					{ name => "Pool",                       required => "N" },
					{ name => "ContractSettlMonth",         required => "N" },
					{ name => "CPProgram",                  required => "N" },
					{ name => "CPRegType",                  required => "N" },
					{
						name     => "NoEvents",
						required => "N",
						group    => [
							{ name => "EventType", required => "N" },
							{ name => "EventDate", required => "N" },
							{ name => "EventPx",   required => "N" },
							{ name => "EventText", required => "N" },
						]
					},
					{ name => "DatedDate",           required => "N" },
					{ name => "InterestAccrualDate", required => "N" },
				]
			},
			{
				name   => "UnderlyingInstrument",
				fields => [
					{ name => "UnderlyingSymbol",           required => "Y" },
					{ name => "UnderlyingSymbolSfx",        required => "N" },
					{ name => "UnderlyingSecurityID",       required => "N" },
					{ name => "UnderlyingSecurityIDSource", required => "N" },
					{
						name     => "NoUnderlyingSecurityAltID",
						required => "N",
						group    => [
							{
								name     => "UnderlyingSecurityAltID",
								required => "N"
							},
							{
								name     => "UnderlyingSecurityAltIDSource",
								required => "N"
							},
						]
					},
					{ name => "UnderlyingProduct",         required => "N" },
					{ name => "UnderlyingCFICode",         required => "N" },
					{ name => "UnderlyingSecurityType",    required => "N" },
					{ name => "UnderlyingSecuritySubType", required => "N" },
					{
						name     => "UnderlyingMaturityMonthYear",
						required => "N"
					},
					{ name => "UnderlyingMaturityDate", required => "N" },
					{
						name     => "UnderlyingCouponPaymentDate",
						required => "N"
					},
					{ name => "UnderlyingIssueDate", required => "N" },
					{
						name     => "UnderlyingRepoCollateralSecurityType",
						required => "N"
					},
					{ name => "UnderlyingRepurchaseTerm", required => "N" },
					{ name => "UnderlyingRepurchaseRate", required => "N" },
					{ name => "UnderlyingFactor",         required => "N" },
					{ name => "UnderlyingCreditRating",   required => "N" },
					{ name => "UnderlyingInstrRegistry",  required => "N" },
					{ name => "UnderlyingCountryOfIssue", required => "N" },
					{
						name     => "UnderlyingStateOrProvinceOfIssue",
						required => "N"
					},
					{ name => "UnderlyingLocaleOfIssue",  required => "N" },
					{ name => "UnderlyingRedemptionDate", required => "N" },
					{ name => "UnderlyingStrikePrice",    required => "N" },
					{ name => "UnderlyingStrikeCurrency", required => "N" },
					{ name => "UnderlyingOptAttribute",   required => "N" },
					{
						name     => "UnderlyingContractMultiplier",
						required => "N"
					},
					{ name => "UnderlyingCouponRate",       required => "N" },
					{ name => "UnderlyingSecurityExchange", required => "N" },
					{ name => "UnderlyingIssuer",           required => "N" },
					{ name => "EncodedUnderlyingIssuerLen", required => "N" },
					{ name => "EncodedUnderlyingIssuer",    required => "N" },
					{ name => "UnderlyingSecurityDesc",     required => "N" },
					{
						name     => "EncodedUnderlyingSecurityDescLen",
						required => "N"
					},
					{
						name     => "EncodedUnderlyingSecurityDesc",
						required => "N"
					},
					{ name => "UnderlyingCPProgram",    required => "N" },
					{ name => "UnderlyingCPRegType",    required => "N" },
					{ name => "UnderlyingCurrency",     required => "N" },
					{ name => "UnderlyingQty",          required => "N" },
					{ name => "UnderlyingPx",           required => "N" },
					{ name => "UnderlyingDirtyPrice",   required => "N" },
					{ name => "UnderlyingEndPrice",     required => "N" },
					{ name => "UnderlyingStartValue",   required => "N" },
					{ name => "UnderlyingCurrentValue", required => "N" },
					{ name => "UnderlyingEndValue",     required => "N" },
					{
						name      => "UnderlyingStipulations",
						required  => "N",
						component => "Y"
					},
				]
			},
			{
				name   => "InstrumentLeg",
				fields => [
					{ name => "LegSymbol",           required => "N" },
					{ name => "LegSymbolSfx",        required => "N" },
					{ name => "LegSecurityID",       required => "N" },
					{ name => "LegSecurityIDSource", required => "N" },
					{
						name     => "NoLegSecurityAltID",
						required => "N",
						group    => [
							{ name => "LegSecurityAltID", required => "N" },
							{
								name     => "LegSecurityAltIDSource",
								required => "N"
							},
						]
					},
					{ name => "LegProduct",           required => "N" },
					{ name => "LegCFICode",           required => "N" },
					{ name => "LegSecurityType",      required => "N" },
					{ name => "LegSecuritySubType",   required => "N" },
					{ name => "LegMaturityMonthYear", required => "N" },
					{ name => "LegMaturityDate",      required => "N" },
					{ name => "LegCouponPaymentDate", required => "N" },
					{ name => "LegIssueDate",         required => "N" },
					{
						name     => "LegRepoCollateralSecurityType",
						required => "N"
					},
					{ name => "LegRepurchaseTerm",         required => "N" },
					{ name => "LegRepurchaseRate",         required => "N" },
					{ name => "LegFactor",                 required => "N" },
					{ name => "LegCreditRating",           required => "N" },
					{ name => "LegInstrRegistry",          required => "N" },
					{ name => "LegCountryOfIssue",         required => "N" },
					{ name => "LegStateOrProvinceOfIssue", required => "N" },
					{ name => "LegLocaleOfIssue",          required => "N" },
					{ name => "LegRedemptionDate",         required => "N" },
					{ name => "LegStrikePrice",            required => "N" },
					{ name => "LegStrikeCurrency",         required => "N" },
					{ name => "LegOptAttribute",           required => "N" },
					{ name => "LegContractMultiplier",     required => "N" },
					{ name => "LegCouponRate",             required => "N" },
					{ name => "LegSecurityExchange",       required => "N" },
					{ name => "LegIssuer",                 required => "N" },
					{ name => "EncodedLegIssuerLen",       required => "N" },
					{ name => "EncodedLegIssuer",          required => "N" },
					{ name => "LegSecurityDesc",           required => "N" },
					{ name => "EncodedLegSecurityDescLen", required => "N" },
					{ name => "EncodedLegSecurityDesc",    required => "N" },
					{ name => "LegRatioQty",               required => "N" },
					{ name => "LegSide",                   required => "N" },
					{ name => "LegCurrency",               required => "N" },
					{ name => "LegPool",                   required => "N" },
					{ name => "LegDatedDate",              required => "N" },
					{ name => "LegContractSettlMonth",     required => "N" },
					{ name => "LegInterestAccrualDate",    required => "N" },
				]
			},
			{
				name   => "InstrumentExtension",
				fields => [
					{ name => "DeliveryForm", required => "N" },
					{ name => "PctAtRisk",    required => "N" },
					{
						name     => "NoInstrAttrib",
						required => "N",
						group    => [
							{ name => "InstrAttribType",  required => "N" },
							{ name => "InstrAttribValue", required => "N" },
						]
					},
				]
			},
			{
				name   => "OrderQtyData",
				fields => [
					{ name => "OrderQty",          required => "N" },
					{ name => "CashOrderQty",      required => "N" },
					{ name => "OrderPercent",      required => "N" },
					{ name => "RoundingDirection", required => "N" },
					{ name => "RoundingModulus",   required => "N" },
				]
			},
			{
				name   => "CommissionData",
				fields => [
					{ name => "Commission",    required => "N" },
					{ name => "CommType",      required => "N" },
					{ name => "CommCurrency",  required => "N" },
					{ name => "FundRenewWaiv", required => "N" },
				]
			},
			{
				name   => "Parties",
				fields => [
					{
						name     => "NoPartyIDs",
						required => "N",
						group    => [
							{ name => "PartyID",       required => "N" },
							{ name => "PartyIDSource", required => "N" },
							{ name => "PartyRole",     required => "N" },
							{
								name     => "NoPartySubIDs",
								required => "N",
								group    => [
									{ name => "PartySubID", required => "N" },
									{
										name     => "PartySubIDType",
										required => "N"
									},
								]
							},
						]
					},
				]
			},
			{
				name   => "NestedParties",
				fields => [
					{
						name     => "NoNestedPartyIDs",
						required => "N",
						group    => [
							{ name => "NestedPartyID", required => "N" },
							{
								name     => "NestedPartyIDSource",
								required => "N"
							},
							{ name => "NestedPartyRole", required => "N" },
							{
								name     => "NoNestedPartySubIDs",
								required => "N",
								group    => [
									{
										name     => "NestedPartySubID",
										required => "N"
									},
									{
										name     => "NestedPartySubIDType",
										required => "N"
									},
								]
							},
						]
					},
				]
			},
			{
				name   => "NestedParties2",
				fields => [
					{
						name     => "NoNested2PartyIDs",
						required => "N",
						group    => [
							{ name => "Nested2PartyID", required => "N" },
							{
								name     => "Nested2PartyIDSource",
								required => "N"
							},
							{ name => "Nested2PartyRole", required => "N" },
							{
								name     => "NoNested2PartySubIDs",
								required => "N",
								group    => [
									{
										name     => "Nested2PartySubID",
										required => "N"
									},
									{
										name     => "Nested2PartySubIDType",
										required => "N"
									},
								]
							},
						]
					},
				]
			},
			{
				name   => "NestedParties3",
				fields => [
					{
						name     => "NoNested3PartyIDs",
						required => "N",
						group    => [
							{ name => "Nested3PartyID", required => "N" },
							{
								name     => "Nested3PartyIDSource",
								required => "N"
							},
							{ name => "Nested3PartyRole", required => "N" },
							{
								name     => "NoNested3PartySubIDs",
								required => "N",
								group    => [
									{
										name     => "Nested3PartySubID",
										required => "N"
									},
									{
										name     => "Nested3PartySubIDType",
										required => "N"
									},
								]
							},
						]
					},
				]
			},
			{
				name   => "SettlParties",
				fields => [
					{
						name     => "NoSettlPartyIDs",
						required => "N",
						group    => [
							{ name => "SettlPartyID",       required => "N" },
							{ name => "SettlPartyIDSource", required => "N" },
							{ name => "SettlPartyRole",     required => "N" },
							{
								name     => "NoSettlPartySubIDs",
								required => "N",
								group    => [
									{
										name     => "SettlPartySubID",
										required => "N"
									},
									{
										name     => "SettlPartySubIDType",
										required => "N"
									},
								]
							},
						]
					},
				]
			},
			{
				name   => "SpreadOrBenchmarkCurveData",
				fields => [
					{ name => "Spread",                    required => "N" },
					{ name => "BenchmarkCurveCurrency",    required => "N" },
					{ name => "BenchmarkCurveName",        required => "N" },
					{ name => "BenchmarkCurvePoint",       required => "N" },
					{ name => "BenchmarkPrice",            required => "N" },
					{ name => "BenchmarkPriceType",        required => "N" },
					{ name => "BenchmarkSecurityID",       required => "N" },
					{ name => "BenchmarkSecurityIDSource", required => "N" },
				]
			},
			{
				name   => "LegBenchmarkCurveData",
				fields => [
					{ name => "LegBenchmarkCurveCurrency", required => "N" },
					{ name => "LegBenchmarkCurveName",     required => "N" },
					{ name => "LegBenchmarkCurvePoint",    required => "N" },
					{ name => "LegBenchmarkPrice",         required => "N" },
					{ name => "LegBenchmarkPriceType",     required => "N" },
				]
			},
			{
				name   => "Stipulations",
				fields => [
					{
						name     => "NoStipulations",
						required => "N",
						group    => [
							{ name => "StipulationType",  required => "N" },
							{ name => "StipulationValue", required => "N" },
						]
					},
				]
			},
			{
				name   => "UnderlyingStipulations",
				fields => [
					{
						name     => "NoUnderlyingStips",
						required => "N",
						group    => [
							{ name => "UnderlyingStipType", required => "N" },
							{
								name     => "UnderlyingStipValue",
								required => "N"
							},
						]
					},
				]
			},
			{
				name   => "LegStipulations",
				fields => [
					{
						name     => "NoLegStipulations",
						required => "N",
						group    => [
							{ name => "LegStipulationType", required => "N" },
							{
								name     => "LegStipulationValue",
								required => "N"
							},
						]
					},
				]
			},
			{
				name   => "YieldData",
				fields => [
					{ name => "YieldType",                required => "N" },
					{ name => "Yield",                    required => "N" },
					{ name => "YieldCalcDate",            required => "N" },
					{ name => "YieldRedemptionDate",      required => "N" },
					{ name => "YieldRedemptionPrice",     required => "N" },
					{ name => "YieldRedemptionPriceType", required => "N" },
				]
			},
			{
				name   => "PositionQty",
				fields => [
					{
						name     => "NoPositions",
						required => "Y",
						group    => [
							{ name => "PosType",      required => "N" },
							{ name => "LongQty",      required => "N" },
							{ name => "ShortQty",     required => "N" },
							{ name => "PosQtyStatus", required => "N" },
							{
								name      => "NestedParties",
								required  => "N",
								component => "Y"
							},
						]
					},
				]
			},
			{
				name   => "PositionAmountData",
				fields => [
					{
						name     => "NoPosAmt",
						required => "Y",
						group    => [
							{ name => "PosAmtType", required => "Y" },
							{ name => "PosAmt",     required => "Y" },
						]
					},
				]
			},
			{
				name   => "TrdRegTimestamps",
				fields => [
					{
						name     => "NoTrdRegTimestamps",
						required => "Y",
						group    => [
							{ name => "TrdRegTimestamp", required => "N" },
							{
								name     => "TrdRegTimestampType",
								required => "N"
							},
							{
								name     => "TrdRegTimestampOrigin",
								required => "N"
							},
						]
					},
				]
			},
			{
				name   => "SettlInstructionsData",
				fields => [
					{ name => "SettlDeliveryType", required => "N" },
					{ name => "StandInstDbType",   required => "N" },
					{ name => "StandInstDbName",   required => "N" },
					{ name => "StandInstDbID",     required => "N" },
					{
						name     => "NoDlvyInst",
						required => "N",
						group    => [
							{ name => "SettlInstSource", required => "N" },
							{ name => "DlvyInstType",    required => "N" },
							{
								name      => "SettlParties",
								required  => "N",
								component => "Y"
							},
						]
					},
				]
			},
			{
				name   => "PegInstructions",
				fields => [
					{ name => "PegOffsetValue",    required => "N" },
					{ name => "PegMoveType",       required => "N" },
					{ name => "PegOffsetType",     required => "N" },
					{ name => "PegLimitType",      required => "N" },
					{ name => "PegRoundDirection", required => "N" },
					{ name => "PegScope",          required => "N" },
				]
			},
			{
				name   => "DiscretionInstructions",
				fields => [
					{ name => "DiscretionInst",           required => "N" },
					{ name => "DiscretionOffsetValue",    required => "N" },
					{ name => "DiscretionMoveType",       required => "N" },
					{ name => "DiscretionOffsetType",     required => "N" },
					{ name => "DiscretionLimitType",      required => "N" },
					{ name => "DiscretionRoundDirection", required => "N" },
					{ name => "DiscretionScope",          required => "N" },
				]
			},
			{
				name   => "FinancingDetails",
				fields => [
					{ name => "AgreementDesc",     required => "N" },
					{ name => "AgreementID",       required => "N" },
					{ name => "AgreementDate",     required => "N" },
					{ name => "AgreementCurrency", required => "N" },
					{ name => "TerminationType",   required => "N" },
					{ name => "StartDate",         required => "N" },
					{ name => "EndDate",           required => "N" },
					{ name => "DeliveryType",      required => "N" },
					{ name => "MarginRatio",       required => "N" },
				]
			},
		],

		fields => [
			{ number => "1", name => "Account",  type => "STRING" },
			{ number => "2", name => "AdvId",    type => "STRING" },
			{ number => "3", name => "AdvRefID", type => "STRING" },
			{
				number => "4",
				name   => "AdvSide",
				type   => "CHAR",
				enum   => [
					{ name => "B", description => "BUY" },
					{ name => "S", description => "SELL" },
					{ name => "X", description => "CROSS" },
					{ name => "T", description => "TRADE" },
				]
			},
			{
				number => "5",
				name   => "AdvTransType",
				type   => "STRING",
				enum   => [
					{ name => "N", description => "NEW" },
					{ name => "C", description => "CANCEL" },
					{ name => "R", description => "REPLACE" },
				]
			},
			{ number => "6",  name => "AvgPx",       type => "PRICE" },
			{ number => "7",  name => "BeginSeqNo",  type => "SEQNUM" },
			{ number => "8",  name => "BeginString", type => "STRING" },
			{ number => "9",  name => "BodyLength",  type => "LENGTH" },
			{ number => "10", name => "CheckSum",    type => "STRING" },
			{ number => "11", name => "ClOrdID",     type => "STRING" },
			{ number => "12", name => "Commission",  type => "AMT" },
			{
				number => "13",
				name   => "CommType",
				type   => "CHAR",
				enum   => [
					{ name => "1", description => "PER_UNIT" },
					{ name => "2", description => "PERCENTAGE" },
					{ name => "3", description => "ABSOLUTE" },
					{
						name        => "4",
						description => "PERCENTAGE_WAIVED_CASH_DISCOUNT"
					},
					{
						name        => "5",
						description => "PERCENTAGE_WAIVED_ENHANCED_UNITS"
					},
					{
						name        => "6",
						description => "POINTS_PER_BOND_OR_OR_CONTRACT"
					},
				]
			},
			{ number => "14", name => "CumQty",   type => "QTY" },
			{ number => "15", name => "Currency", type => "CURRENCY" },
			{ number => "16", name => "EndSeqNo", type => "SEQNUM" },
			{ number => "17", name => "ExecID",   type => "STRING" },
			{
				number => "18",
				name   => "ExecInst",
				type   => "MULTIPLEVALUESTRING",
				enum   => [
					{ name => "1", description => "NOT_HELD" },
					{ name => "2", description => "WORK" },
					{ name => "3", description => "GO_ALONG" },
					{ name => "4", description => "OVER_THE_DAY" },
					{ name => "5", description => "HELD" },
					{
						name        => "6",
						description => "PARTICIPATE_DONT_INITIATE"
					},
					{ name => "7", description => "STRICT_SCALE" },
					{ name => "8", description => "TRY_TO_SCALE" },
					{ name => "9", description => "STAY_ON_BIDSIDE" },
					{ name => "0", description => "STAY_ON_OFFERSIDE" },
					{ name => "A", description => "NO_CROSS" },
					{ name => "B", description => "OK_TO_CROSS" },
					{ name => "C", description => "CALL_FIRST" },
					{ name => "D", description => "PERCENT_OF_VOLUME" },
					{ name => "E", description => "DO_NOT_INCREASE" },
					{ name => "F", description => "DO_NOT_REDUCE" },
					{ name => "G", description => "ALL_OR_NONE" },
					{
						name        => "H",
						description => "REINSTATE_ON_SYSTEM_FAILURE"
					},
					{ name => "I", description => "INSTITUTIONS_ONLY" },
					{
						name        => "J",
						description => "REINSTATE_ON_TRADING_HALT"
					},
					{ name => "K", description => "CANCEL_ON_TRADING_HALT" },
					{ name => "L", description => "LAST_PEG" },
					{ name => "M", description => "MID_PRICE" },
					{ name => "N", description => "NON_NEGOTIABLE" },
					{ name => "O", description => "OPENING_PEG" },
					{ name => "P", description => "MARKET_PEG" },
					{
						name        => "Q",
						description => "CANCEL_ON_SYSTEM_FAILURE"
					},
					{ name => "R", description => "PRIMARY_PEG" },
					{ name => "S", description => "SUSPEND" },
					{
						name => "T",
						description =>
"FIXED_PEG_TO_LOCAL_BEST_BID_OR_OFFER_AT_TIME_OF_ORDER"
					},
					{
						name        => "U",
						description => "CUSTOMER_DISPLAY_INSTRUCTION"
					},
					{ name => "V", description => "NETTING" },
					{ name => "W", description => "PEG_TO_VWAP" },
					{ name => "X", description => "TRADE_ALONG" },
					{ name => "Y", description => "TRY_TO_STOP" },
					{ name => "Z", description => "CANCEL_IF_NOT_BEST" },
					{ name => "a", description => "TRAILING_STOP_PEG" },
					{ name => "b", description => "STRICT_LIMIT" },
					{
						name        => "c",
						description => "IGNORE_PRICE_VALIDITY_CHECKS"
					},
					{ name => "d", description => "PEG_TO_LIMIT_PRICE" },
					{ name => "e", description => "WORK_TO_TARGET_STRATEGY" },
				]
			},
			{ number => "19", name => "ExecRefID", type => "STRING" },
			{
				number => "21",
				name   => "HandlInst",
				type   => "CHAR",
				enum   => [
					{
						name        => "1",
						description => "AUTOMATED_EXECUTION_ORDER_PRIVATE"
					},
					{
						name        => "2",
						description => "AUTOMATED_EXECUTION_ORDER_PUBLIC"
					},
					{ name => "3", description => "MANUAL_ORDER" },
				]
			},
			{
				number => "22",
				name   => "SecurityIDSource",
				type   => "STRING",
				enum   => [
					{ name => "1", description => "CUSIP" },
					{ name => "2", description => "SEDOL" },
					{ name => "3", description => "QUIK" },
					{ name => "4", description => "ISIN_NUMBER" },
					{ name => "5", description => "RIC_CODE" },
					{ name => "6", description => "ISO_CURRENCY_CODE" },
					{ name => "7", description => "ISO_COUNTRY_CODE" },
					{ name => "8", description => "EXCHANGE_SYMBOL" },
					{
						name        => "9",
						description => "CONSOLIDATED_TAPE_ASSOCIATION"
					},
					{ name => "A", description => "BLOOMBERG_SYMBOL" },
					{ name => "B", description => "WERTPAPIER" },
					{ name => "C", description => "DUTCH" },
					{ name => "D", description => "VALOREN" },
					{ name => "E", description => "SICOVAM" },
					{ name => "F", description => "BELGIAN" },
					{ name => "G", description => "COMMON" },
					{
						name        => "H",
						description => "CLEARING_HOUSE_CLEARING_ORGANIZATION"
					},
					{
						name        => "I",
						description => "ISDA_FPML_PRODUCT_SPECIFICATION"
					},
					{
						name        => "J",
						description => "OPTIONS_PRICE_REPORTING_AUTHORITY"
					},
				]
			},
			{ number => "23", name => "IOIid", type => "STRING" },
			{
				number => "25",
				name   => "IOIQltyInd",
				type   => "CHAR",
				enum   => [
					{ name => "L", description => "LOW" },
					{ name => "M", description => "MEDIUM" },
					{ name => "H", description => "HIGH" },
				]
			},
			{ number => "26", name => "IOIRefID", type => "STRING" },
			{ number => "27", name => "IOIQty",   type => "STRING" },
			{
				number => "28",
				name   => "IOITransType",
				type   => "CHAR",
				enum   => [
					{ name => "N", description => "NEW" },
					{ name => "C", description => "CANCEL" },
					{ name => "R", description => "REPLACE" },
				]
			},
			{
				number => "29",
				name   => "LastCapacity",
				type   => "CHAR",
				enum   => [
					{ name => "1", description => "AGENT" },
					{ name => "2", description => "CROSS_AS_AGENT" },
					{ name => "3", description => "CROSS_AS_PRINCIPAL" },
					{ name => "4", description => "PRINCIPAL" },
				]
			},
			{ number => "30", name => "LastMkt",     type => "EXCHANGE" },
			{ number => "31", name => "LastPx",      type => "PRICE" },
			{ number => "32", name => "LastQty",     type => "QTY" },
			{ number => "33", name => "LinesOfText", type => "NUMINGROUP" },
			{ number => "34", name => "MsgSeqNum",   type => "SEQNUM" },
			{
				number => "35",
				name   => "MsgType",
				type   => "STRING",
				enum   => [
					{ name => "0", description => "HEARTBEAT" },
					{ name => "1", description => "TEST_REQUEST" },
					{ name => "2", description => "RESEND_REQUEST" },
					{ name => "3", description => "REJECT" },
					{ name => "4", description => "SEQUENCE_RESET" },
					{ name => "5", description => "LOGOUT" },
					{ name => "6", description => "INDICATION_OF_INTEREST" },
					{ name => "7", description => "ADVERTISEMENT" },
					{ name => "8", description => "EXECUTION_REPORT" },
					{ name => "9", description => "ORDER_CANCEL_REJECT" },
					{ name => "A", description => "LOGON" },
					{ name => "B", description => "NEWS" },
					{ name => "C", description => "EMAIL" },
					{ name => "D", description => "ORDER_SINGLE" },
					{ name => "E", description => "ORDER_LIST" },
					{ name => "F", description => "ORDER_CANCEL_REQUEST" },
					{
						name        => "G",
						description => "ORDER_CANCEL_REPLACE_REQUEST"
					},
					{ name => "H", description => "ORDER_STATUS_REQUEST" },
					{ name => "J", description => "ALLOCATION_INSTRUCTION" },
					{ name => "K", description => "LIST_CANCEL_REQUEST" },
					{ name => "L", description => "LIST_EXECUTE" },
					{ name => "M", description => "LIST_STATUS_REQUEST" },
					{ name => "N", description => "LIST_STATUS" },
					{
						name        => "P",
						description => "ALLOCATION_INSTRUCTION_ACK"
					},
					{ name => "Q", description => "DONT_KNOW_TRADE" },
					{ name => "R", description => "QUOTE_REQUEST" },
					{ name => "S", description => "QUOTE" },
					{ name => "T", description => "SETTLEMENT_INSTRUCTIONS" },
					{ name => "V", description => "MARKET_DATA_REQUEST" },
					{
						name        => "W",
						description => "MARKET_DATA_SNAPSHOT_FULL_REFRESH"
					},
					{
						name        => "X",
						description => "MARKET_DATA_INCREMENTAL_REFRESH"
					},
					{
						name        => "Y",
						description => "MARKET_DATA_REQUEST_REJECT"
					},
					{ name => "Z", description => "QUOTE_CANCEL" },
					{ name => "a", description => "QUOTE_STATUS_REQUEST" },
					{
						name        => "b",
						description => "MASS_QUOTE_ACKNOWLEDGEMENT"
					},
					{
						name        => "c",
						description => "SECURITY_DEFINITION_REQUEST"
					},
					{ name => "d", description => "SECURITY_DEFINITION" },
					{ name => "e", description => "SECURITY_STATUS_REQUEST" },
					{ name => "f", description => "SECURITY_STATUS" },
					{
						name        => "g",
						description => "TRADING_SESSION_STATUS_REQUEST"
					},
					{ name => "h", description => "TRADING_SESSION_STATUS" },
					{ name => "i", description => "MASS_QUOTE" },
					{ name => "j", description => "BUSINESS_MESSAGE_REJECT" },
					{ name => "k", description => "BID_REQUEST" },
					{ name => "l", description => "BID_RESPONSE" },
					{ name => "m", description => "LIST_STRIKE_PRICE" },
					{ name => "n", description => "XML_MESSAGE" },
					{
						name        => "o",
						description => "REGISTRATION_INSTRUCTIONS"
					},
					{
						name        => "p",
						description => "REGISTRATION_INSTRUCTIONS_RESPONSE"
					},
					{
						name        => "q",
						description => "ORDER_MASS_CANCEL_REQUEST"
					},
					{
						name        => "r",
						description => "ORDER_MASS_CANCEL_REPORT"
					},
					{ name => "s", description => "NEW_ORDER_CROSS" },
					{
						name        => "t",
						description => "CROSS_ORDER_CANCEL_REPLACE_REQUEST"
					},
					{
						name        => "u",
						description => "CROSS_ORDER_CANCEL_REQUEST"
					},
					{ name => "v", description => "SECURITY_TYPE_REQUEST" },
					{ name => "w", description => "SECURITY_TYPES" },
					{ name => "x", description => "SECURITY_LIST_REQUEST" },
					{ name => "y", description => "SECURITY_LIST" },
					{
						name        => "z",
						description => "DERIVATIVE_SECURITY_LIST_REQUEST"
					},
					{
						name        => "AA",
						description => "DERIVATIVE_SECURITY_LIST"
					},
					{ name => "AB", description => "NEW_ORDER_MULTILEG" },
					{
						name        => "AC",
						description => "MULTILEG_ORDER_CANCEL_REPLACE"
					},
					{
						name        => "AD",
						description => "TRADE_CAPTURE_REPORT_REQUEST"
					},
					{ name => "AE", description => "TRADE_CAPTURE_REPORT" },
					{
						name        => "AF",
						description => "ORDER_MASS_STATUS_REQUEST"
					},
					{ name => "AG", description => "QUOTE_REQUEST_REJECT" },
					{ name => "AH", description => "RFQ_REQUEST" },
					{ name => "AI", description => "QUOTE_STATUS_REPORT" },
					{ name => "AJ", description => "QUOTE_RESPONSE" },
					{ name => "AK", description => "CONFIRMATION" },
					{
						name        => "AL",
						description => "POSITION_MAINTENANCE_REQUEST"
					},
					{
						name        => "AM",
						description => "POSITION_MAINTENANCE_REPORT"
					},
					{ name => "AN", description => "REQUEST_FOR_POSITIONS" },
					{
						name        => "AO",
						description => "REQUEST_FOR_POSITIONS_ACK"
					},
					{ name => "AP", description => "POSITION_REPORT" },
					{
						name        => "AQ",
						description => "TRADE_CAPTURE_REPORT_REQUEST_ACK"
					},
					{
						name        => "AR",
						description => "TRADE_CAPTURE_REPORT_ACK"
					},
					{ name => "AS", description => "ALLOCATION_REPORT" },
					{ name => "AT", description => "ALLOCATION_REPORT_ACK" },
					{ name => "AU", description => "CONFIRMATION_ACK" },
					{
						name        => "AV",
						description => "SETTLEMENT_INSTRUCTION_REQUEST"
					},
					{ name => "AW", description => "ASSIGNMENT_REPORT" },
					{ name => "AX", description => "COLLATERAL_REQUEST" },
					{ name => "AY", description => "COLLATERAL_ASSIGNMENT" },
					{ name => "AZ", description => "COLLATERAL_RESPONSE" },
					{ name => "BA", description => "COLLATERAL_REPORT" },
					{ name => "BB", description => "COLLATERAL_INQUIRY" },
					{ name => "BC", description => "NETWORK_STATUS_REQUEST" },
					{
						name        => "BD",
						description => "NETWORK_STATUS_RESPONSE"
					},
					{ name => "BE", description => "USER_REQUEST" },
					{ name => "BF", description => "USER_RESPONSE" },
					{ name => "BG", description => "COLLATERAL_INQUIRY_ACK" },
					{ name => "BH", description => "CONFIRMATION_REQUEST" },
				]
			},
			{ number => "36", name => "NewSeqNo", type => "SEQNUM" },
			{ number => "37", name => "OrderID",  type => "STRING" },
			{ number => "38", name => "OrderQty", type => "QTY" },
			{
				number => "39",
				name   => "OrdStatus",
				type   => "CHAR",
				enum   => [
					{ name => "0", description => "NEW" },
					{ name => "1", description => "PARTIALLY_FILLED" },
					{ name => "2", description => "FILLED" },
					{ name => "3", description => "DONE_FOR_DAY" },
					{ name => "4", description => "CANCELED" },
					{ name => "5", description => "REPLACED" },
					{ name => "6", description => "PENDING_CANCEL" },
					{ name => "7", description => "STOPPED" },
					{ name => "8", description => "REJECTED" },
					{ name => "9", description => "SUSPENDED" },
					{ name => "A", description => "PENDING_NEW" },
					{ name => "B", description => "CALCULATED" },
					{ name => "C", description => "EXPIRED" },
					{ name => "D", description => "ACCEPTED_FOR_BIDDING" },
					{ name => "E", description => "PENDING_REPLACE" },
				]
			},
			{
				number => "40",
				name   => "OrdType",
				type   => "CHAR",
				enum   => [
					{ name => "1", description => "MARKET" },
					{ name => "2", description => "LIMIT" },
					{ name => "3", description => "STOP" },
					{ name => "4", description => "STOP_LIMIT" },
					{ name => "5", description => "MARKET_ON_CLOSE" },
					{ name => "6", description => "WITH_OR_WITHOUT" },
					{ name => "7", description => "LIMIT_OR_BETTER" },
					{ name => "8", description => "LIMIT_WITH_OR_WITHOUT" },
					{ name => "9", description => "ON_BASIS" },
					{ name => "A", description => "ON_CLOSE" },
					{ name => "B", description => "LIMIT_ON_CLOSE" },
					{ name => "C", description => "FOREX_MARKET" },
					{ name => "D", description => "PREVIOUSLY_QUOTED" },
					{ name => "E", description => "PREVIOUSLY_INDICATED" },
					{ name => "F", description => "FOREX_LIMIT" },
					{ name => "G", description => "FOREX_SWAP" },
					{ name => "H", description => "FOREX_PREVIOUSLY_QUOTED" },
					{ name => "I", description => "FUNARI" },
					{ name => "J", description => "MARKET_IF_TOUCHED" },
					{
						name        => "K",
						description => "MARKET_WITH_LEFTOVER_AS_LIMIT"
					},
					{
						name        => "L",
						description => "PREVIOUS_FUND_VALUATION_POINT"
					},
					{
						name        => "M",
						description => "NEXT_FUND_VALUATION_POINT"
					},
					{ name => "P", description => "PEGGED" },
				]
			},
			{ number => "41", name => "OrigClOrdID", type => "STRING" },
			{ number => "42", name => "OrigTime",    type => "UTCTIMESTAMP" },
			{ number => "43", name => "PossDupFlag", type => "BOOLEAN" },
			{ number => "44", name => "Price",       type => "PRICE" },
			{ number => "45", name => "RefSeqNum",   type => "SEQNUM" },
			{ number => "48", name => "SecurityID",  type => "STRING" },
			{ number => "49", name => "SenderCompID", type => "STRING" },
			{ number => "50", name => "SenderSubID",  type => "STRING" },
			{ number => "52", name => "SendingTime", type => "UTCTIMESTAMP" },
			{ number => "53", name => "Quantity",    type => "QTY" },
			{
				number => "54",
				name   => "Side",
				type   => "CHAR",
				enum   => [
					{ name => "1", description => "BUY" },
					{ name => "2", description => "SELL" },
					{ name => "3", description => "BUY_MINUS" },
					{ name => "4", description => "SELL_PLUS" },
					{ name => "5", description => "SELL_SHORT" },
					{ name => "6", description => "SELL_SHORT_EXEMPT" },
					{ name => "7", description => "UNDISCLOSED" },
					{ name => "8", description => "CROSS" },
					{ name => "9", description => "CROSS_SHORT" },
					{ name => "A", description => "CROSS_SHORT_EXEMPT" },
					{ name => "B", description => "AS_DEFINED" },
					{ name => "C", description => "OPPOSITE" },
					{ name => "D", description => "SUBSCRIBE" },
					{ name => "E", description => "REDEEM" },
					{ name => "F", description => "LEND" },
					{ name => "G", description => "BORROW" },
				]
			},
			{ number => "55", name => "Symbol",       type => "STRING" },
			{ number => "56", name => "TargetCompID", type => "STRING" },
			{ number => "57", name => "TargetSubID",  type => "STRING" },
			{ number => "58", name => "Text",         type => "STRING" },
			{
				number => "59",
				name   => "TimeInForce",
				type   => "CHAR",
				enum   => [
					{ name => "0", description => "DAY" },
					{ name => "1", description => "GOOD_TILL_CANCEL" },
					{ name => "2", description => "AT_THE_OPENING" },
					{ name => "3", description => "IMMEDIATE_OR_CANCEL" },
					{ name => "4", description => "FILL_OR_KILL" },
					{ name => "5", description => "GOOD_TILL_CROSSING" },
					{ name => "6", description => "GOOD_TILL_DATE" },
					{ name => "7", description => "AT_THE_CLOSE" },
				]
			},
			{
				number => "60",
				name   => "TransactTime",
				type   => "UTCTIMESTAMP"
			},
			{
				number => "61",
				name   => "Urgency",
				type   => "CHAR",
				enum   => [
					{ name => "0", description => "NORMAL" },
					{ name => "1", description => "FLASH" },
					{ name => "2", description => "BACKGROUND" },
				]
			},
			{
				number => "62",
				name   => "ValidUntilTime",
				type   => "UTCTIMESTAMP"
			},
			{
				number => "63",
				name   => "SettlType",
				type   => "CHAR",
				enum   => [
					{ name => "0", description => "REGULAR" },
					{ name => "1", description => "CASH" },
					{ name => "2", description => "NEXT_DAY" },
					{ name => "3", description => "T_PLUS_2" },
					{ name => "4", description => "T_PLUS_3" },
					{ name => "5", description => "T_PLUS_4" },
					{ name => "6", description => "FUTURE" },
					{ name => "7", description => "WHEN_AND_IF_ISSUED" },
					{ name => "8", description => "SELLERS_OPTION" },
					{ name => "9", description => "T_PLUS_5" },
				]
			},
			{ number => "64", name => "SettlDate", type => "LOCALMKTDATE" },
			{
				number           => "65",
				name             => "SymbolSfx",
				type             => "STRING",
				allowOtherValues => "true",
				enum             => [
					{ name => "WI", description => "WHEN_ISSUED" },
					{
						name        => "CD",
						description => "A_EUCP_WITH_LUMP_SUM_INTEREST"
					},
				]
			},
			{ number => "66", name => "ListID",       type => "STRING" },
			{ number => "67", name => "ListSeqNo",    type => "INT" },
			{ number => "68", name => "TotNoOrders",  type => "INT" },
			{ number => "69", name => "ListExecInst", type => "STRING" },
			{ number => "70", name => "AllocID",      type => "STRING" },
			{
				number => "71",
				name   => "AllocTransType",
				type   => "CHAR",
				enum   => [
					{ name => "0", description => "NEW" },
					{ name => "1", description => "REPLACE" },
					{ name => "2", description => "CANCEL" },
					{ name => "3", description => "PRELIMINARY" },
					{ name => "4", description => "CALCULATED" },
					{
						name        => "5",
						description => "CALCULATED_WITHOUT_PRELIMINARY"
					},
				]
			},
			{ number => "72", name => "RefAllocID", type => "STRING" },
			{ number => "73", name => "NoOrders",   type => "NUMINGROUP" },
			{ number => "74", name => "AvgPxPrecision", type => "INT" },
			{ number => "75", name => "TradeDate", type => "LOCALMKTDATE" },
			{
				number => "77",
				name   => "PositionEffect",
				type   => "CHAR",
				enum   => [
					{ name => "O", description => "OPEN" },
					{ name => "C", description => "CLOSE" },
					{ name => "R", description => "ROLLED" },
					{ name => "F", description => "FIFO" },
				]
			},
			{ number => "78", name => "NoAllocs",     type => "NUMINGROUP" },
			{ number => "79", name => "AllocAccount", type => "STRING" },
			{ number => "80", name => "AllocQty",     type => "QTY" },
			{
				number => "81",
				name   => "ProcessCode",
				type   => "CHAR",
				enum   => [
					{ name => "0", description => "REGULAR" },
					{ name => "1", description => "SOFT_DOLLAR" },
					{ name => "2", description => "STEP_IN" },
					{ name => "3", description => "STEP_OUT" },
					{ name => "4", description => "SOFT_DOLLAR_STEP_IN" },
					{ name => "5", description => "SOFT_DOLLAR_STEP_OUT" },
					{ name => "6", description => "PLAN_SPONSOR" },
				]
			},
			{ number => "82", name => "NoRpts",     type => "NUMINGROUP" },
			{ number => "83", name => "RptSeq",     type => "INT" },
			{ number => "84", name => "CxlQty",     type => "QTY" },
			{ number => "85", name => "NoDlvyInst", type => "NUMINGROUP" },
			{
				number => "87",
				name   => "AllocStatus",
				type   => "INT",
				enum   => [
					{ name => "0", description => "ACCEPTED" },
					{ name => "1", description => "BLOCK_LEVEL_REJECT" },
					{ name => "2", description => "ACCOUNT_LEVEL_REJECT" },
					{ name => "3", description => "RECEIVED" },
					{ name => "4", description => "INCOMPLETE" },
					{
						name        => "5",
						description => "REJECTED_BY_INTERMEDIARY"
					},
				]
			},
			{
				number => "88",
				name   => "AllocRejCode",
				type   => "INT",
				enum   => [
					{ name => "0", description => "UNKNOWN_ACCOUNT" },
					{ name => "1", description => "INCORRECT_QUANTITY" },
					{ name => "2", description => "INCORRECT_AVERAGE_PRICE" },
					{
						name        => "3",
						description => "UNKNOWN_EXECUTING_BROKER_MNEMONIC"
					},
					{ name => "4", description => "COMMISSION_DIFFERENCE" },
					{ name => "5", description => "UNKNOWN_ORDERID" },
					{ name => "6", description => "UNKNOWN_LISTID" },
					{ name => "7", description => "OTHER" },
					{
						name        => "8",
						description => "INCORRECT_ALLOCATED_QUANTITY"
					},
					{ name => "9", description => "CALCULATION_DIFFERENCE" },
					{
						name        => "10",
						description => "UNKNOWN_OR_STALE_EXEC_ID"
					},
					{ name => "11", description => "MISMATCHED_DATA_VALUE" },
					{ name => "12", description => "UNKNOWN_CLORDID" },
					{
						name        => "13",
						description => "WAREHOUSE_REQUEST_REJECTED"
					},
				]
			},
			{ number => "89", name => "Signature",       type => "DATA" },
			{ number => "90", name => "SecureDataLen",   type => "LENGTH" },
			{ number => "91", name => "SecureData",      type => "DATA" },
			{ number => "93", name => "SignatureLength", type => "LENGTH" },
			{
				number => "94",
				name   => "EmailType",
				type   => "CHAR",
				enum   => [
					{ name => "0", description => "NEW" },
					{ name => "1", description => "REPLY" },
					{ name => "2", description => "ADMIN_REPLY" },
				]
			},
			{ number => "95", name => "RawDataLength", type => "LENGTH" },
			{ number => "96", name => "RawData",       type => "DATA" },
			{ number => "97", name => "PossResend",    type => "BOOLEAN" },
			{
				number => "98",
				name   => "EncryptMethod",
				type   => "INT",
				enum   => [
					{ name => "0", description => "NONE_OTHER" },
					{ name => "1", description => "PKCS" },
					{ name => "2", description => "DES" },
					{ name => "3", description => "PKCS_DES" },
					{ name => "4", description => "PGP_DES" },
					{ name => "5", description => "PGP_DES_MD5" },
					{ name => "6", description => "PEM_DES_MD5" },
				]
			},
			{ number => "99",  name => "StopPx",        type => "PRICE" },
			{ number => "100", name => "ExDestination", type => "EXCHANGE" },
			{
				number => "102",
				name   => "CxlRejReason",
				type   => "INT",
				enum   => [
					{ name => "0", description => "TOO_LATE_TO_CANCEL" },
					{ name => "1", description => "UNKNOWN_ORDER" },
					{ name => "2", description => "BROKER_EXCHANGE_OPTION" },
					{
						name => "3",
						description =>
"ORDER_ALREADY_IN_PENDING_CANCEL_OR_PENDING_REPLACE_STATUS"
					},
					{
						name => "4",
						description =>
						  "UNABLE_TO_PROCESS_ORDER_MASS_CANCEL_REQUEST"
					},
					{
						name => "5",
						description =>
"ORIGORDMODTIME_DID_NOT_MATCH_LAST_TRANSACTTIME_OF_ORDER"
					},
					{
						name        => "6",
						description => "DUPLICATE_CLORDID_RECEIVED"
					},
					{ name => "99", description => "OTHER" },
				]
			},
			{
				number => "103",
				name   => "OrdRejReason",
				type   => "INT",
				enum   => [
					{ name => "0", description => "BROKER_EXCHANGE_OPTION" },
					{ name => "1", description => "UNKNOWN_SYMBOL" },
					{ name => "2", description => "EXCHANGE_CLOSED" },
					{ name => "3", description => "ORDER_EXCEEDS_LIMIT" },
					{ name => "4", description => "TOO_LATE_TO_ENTER" },
					{ name => "5", description => "UNKNOWN_ORDER" },
					{ name => "6", description => "DUPLICATE_ORDER" },
					{
						name => "7",
						description =>
						  "DUPLICATE_OF_A_VERBALLY_COMMUNICATED_ORDER"
					},
					{ name => "8",  description => "STALE_ORDER" },
					{ name => "9",  description => "TRADE_ALONG_REQUIRED" },
					{ name => "10", description => "INVALID_INVESTOR_ID" },
					{
						name        => "11",
						description => "UNSUPPORTED_ORDER_CHARACTERISTIC"
					},
					{ name => "12", description => "SURVEILLENCE_OPTION" },
					{ name => "13", description => "INCORRECT_QUANTITY" },
					{
						name        => "14",
						description => "INCORRECT_ALLOCATED_QUANTITY"
					},
					{ name => "15", description => "UNKNOWN_ACCOUNT" },
					{ name => "99", description => "OTHER" },
				]
			},
			{
				number => "104",
				name   => "IOIQualifier",
				type   => "CHAR",
				enum   => [
					{ name => "A", description => "ALL_OR_NONE" },
					{ name => "B", description => "MARKET_ON_CLOSE" },
					{ name => "C", description => "AT_THE_CLOSE" },
					{ name => "D", description => "VWAP" },
					{ name => "I", description => "IN_TOUCH_WITH" },
					{ name => "L", description => "LIMIT" },
					{ name => "M", description => "MORE_BEHIND" },
					{ name => "O", description => "AT_THE_OPEN" },
					{ name => "P", description => "TAKING_A_POSITION" },
					{ name => "Q", description => "AT_THE_MARKET" },
					{ name => "R", description => "READY_TO_TRADE" },
					{ name => "S", description => "PORTFOLIO_SHOWN" },
					{ name => "T", description => "THROUGH_THE_DAY" },
					{ name => "V", description => "VERSUS" },
					{ name => "W", description => "INDICATION_WORKING_AWAY" },
					{ name => "X", description => "CROSSING_OPPORTUNITY" },
					{ name => "Y", description => "AT_THE_MIDPOINT" },
					{ name => "Z", description => "PRE_OPEN" },
				]
			},
			{ number => "105", name => "WaveNo",       type => "STRING" },
			{ number => "106", name => "Issuer",       type => "STRING" },
			{ number => "107", name => "SecurityDesc", type => "STRING" },
			{ number => "108", name => "HeartBtInt",   type => "INT" },
			{ number => "110", name => "MinQty",       type => "QTY" },
			{ number => "111", name => "MaxFloor",     type => "QTY" },
			{ number => "112", name => "TestReqID",    type => "STRING" },
			{ number => "113", name => "ReportToExch", type => "BOOLEAN" },
			{ number => "114", name => "LocateReqd",   type => "BOOLEAN" },
			{ number => "115", name => "OnBehalfOfCompID", type => "STRING" },
			{ number => "116", name => "OnBehalfOfSubID",  type => "STRING" },
			{ number => "117", name => "QuoteID",          type => "STRING" },
			{ number => "118", name => "NetMoney",         type => "AMT" },
			{ number => "119", name => "SettlCurrAmt",     type => "AMT" },
			{ number => "120", name => "SettlCurrency", type => "CURRENCY" },
			{ number => "121", name => "ForexReq",      type => "BOOLEAN" },
			{
				number => "122",
				name   => "OrigSendingTime",
				type   => "UTCTIMESTAMP"
			},
			{ number => "123", name => "GapFillFlag", type => "BOOLEAN" },
			{ number => "124", name => "NoExecs",     type => "NUMINGROUP" },
			{ number => "126", name => "ExpireTime", type => "UTCTIMESTAMP" },
			{
				number => "127",
				name   => "DKReason",
				type   => "CHAR",
				enum   => [
					{ name => "A", description => "UNKNOWN_SYMBOL" },
					{ name => "B", description => "WRONG_SIDE" },
					{ name => "C", description => "QUANTITY_EXCEEDS_ORDER" },
					{ name => "D", description => "NO_MATCHING_ORDER" },
					{ name => "E", description => "PRICE_EXCEEDS_LIMIT" },
					{ name => "F", description => "CALCULATION_DIFFERENCE" },
					{ name => "Z", description => "OTHER" },
				]
			},
			{ number => "128", name => "DeliverToCompID", type => "STRING" },
			{ number => "129", name => "DeliverToSubID",  type => "STRING" },
			{ number => "130", name => "IOINaturalFlag",  type => "BOOLEAN" },
			{ number => "131", name => "QuoteReqID",      type => "STRING" },
			{ number => "132", name => "BidPx",           type => "PRICE" },
			{ number => "133", name => "OfferPx",         type => "PRICE" },
			{ number => "134", name => "BidSize",         type => "QTY" },
			{ number => "135", name => "OfferSize",       type => "QTY" },
			{ number => "136", name => "NoMiscFees",  type => "NUMINGROUP" },
			{ number => "137", name => "MiscFeeAmt",  type => "AMT" },
			{ number => "138", name => "MiscFeeCurr", type => "CURRENCY" },
			{
				number => "139",
				name   => "MiscFeeType",
				type   => "CHAR",
				enum   => [
					{ name => "1", description => "REGULATORY" },
					{ name => "2", description => "TAX" },
					{ name => "3", description => "LOCAL_COMMISSION" },
					{ name => "4", description => "EXCHANGE_FEES" },
					{ name => "5", description => "STAMP" },
					{ name => "6", description => "LEVY" },
					{ name => "7", description => "OTHER" },
					{ name => "8", description => "MARKUP" },
					{ name => "9", description => "CONSUMPTION_TAX" },
				]
			},
			{ number => "140", name => "PrevClosePx",     type => "PRICE" },
			{ number => "141", name => "ResetSeqNumFlag", type => "BOOLEAN" },
			{ number => "142", name => "SenderLocationID", type => "STRING" },
			{ number => "143", name => "TargetLocationID", type => "STRING" },
			{
				number => "144",
				name   => "OnBehalfOfLocationID",
				type   => "STRING"
			},
			{
				number => "145",
				name   => "DeliverToLocationID",
				type   => "STRING"
			},
			{ number => "146", name => "NoRelatedSym", type => "NUMINGROUP" },
			{ number => "147", name => "Subject",      type => "STRING" },
			{ number => "148", name => "Headline",     type => "STRING" },
			{ number => "149", name => "URLLink",      type => "STRING" },
			{
				number => "150",
				name   => "ExecType",
				type   => "CHAR",
				enum   => [
					{ name => "0", description => "NEW" },
					{ name => "1", description => "PARTIAL_FILL" },
					{ name => "2", description => "FILL" },
					{ name => "3", description => "DONE_FOR_DAY" },
					{ name => "4", description => "CANCELED" },
					{ name => "5", description => "REPLACE" },
					{ name => "6", description => "PENDING_CANCEL" },
					{ name => "7", description => "STOPPED" },
					{ name => "8", description => "REJECTED" },
					{ name => "9", description => "SUSPENDED" },
					{ name => "A", description => "PENDING_NEW" },
					{ name => "B", description => "CALCULATED" },
					{ name => "C", description => "EXPIRED" },
					{ name => "D", description => "RESTATED" },
					{ name => "E", description => "PENDING_REPLACE" },
					{ name => "F", description => "TRADE" },
					{ name => "G", description => "TRADE_CORRECT" },
					{ name => "H", description => "TRADE_CANCEL" },
					{ name => "I", description => "ORDER_STATUS" },
				]
			},
			{ number => "151", name => "LeavesQty",       type => "QTY" },
			{ number => "152", name => "CashOrderQty",    type => "QTY" },
			{ number => "153", name => "AllocAvgPx",      type => "PRICE" },
			{ number => "154", name => "AllocNetMoney",   type => "AMT" },
			{ number => "155", name => "SettlCurrFxRate", type => "FLOAT" },
			{
				number => "156",
				name   => "SettlCurrFxRateCalc",
				type   => "CHAR",
				enum   => [
					{ name => "M", description => "MULTIPLY" },
					{ name => "D", description => "DIVIDE" },
				]
			},
			{ number => "157", name => "NumDaysInterest", type => "INT" },
			{
				number => "158",
				name   => "AccruedInterestRate",
				type   => "PERCENTAGE"
			},
			{ number => "159", name => "AccruedInterestAmt", type => "AMT" },
			{
				number => "160",
				name   => "SettlInstMode",
				type   => "CHAR",
				enum   => [
					{ name => "0", description => "DEFAULT" },
					{
						name        => "1",
						description => "STANDING_INSTRUCTIONS_PROVIDED"
					},
					{
						name        => "4",
						description => "SPECIFIC_ORDER_FOR_A_SINGLE_ACCOUNT"
					},
					{ name => "5", description => "REQUEST_REJECT" },
				]
			},
			{ number => "161", name => "AllocText",   type => "STRING" },
			{ number => "162", name => "SettlInstID", type => "STRING" },
			{
				number => "163",
				name   => "SettlInstTransType",
				type   => "CHAR",
				enum   => [
					{ name => "N", description => "NEW" },
					{ name => "C", description => "CANCEL" },
					{ name => "R", description => "REPLACE" },
					{ name => "T", description => "RESTATE" },
				]
			},
			{ number => "164", name => "EmailThreadID", type => "STRING" },
			{
				number => "165",
				name   => "SettlInstSource",
				type   => "CHAR",
				enum   => [
					{ name => "1", description => "BROKERS_INSTRUCTIONS" },
					{
						name        => "2",
						description => "INSTITUTIONS_INSTRUCTIONS"
					},
					{ name => "3", description => "INVESTOR" },
				]
			},
			{
				number => "167",
				name   => "SecurityType",
				type   => "STRING",
				enum   => [
					{ name => "?", description => "WILDCARD" },
					{
						name        => "ABS",
						description => "ASSET_BACKED_SECURITIES"
					},
					{
						name        => "AMENDED",
						description => "AMENDED_AND_RESTATED"
					},
					{
						name        => "AN",
						description => "OTHER_ANTICIPATION_NOTES"
					},
					{ name => "BA",     description => "BANKERS_ACCEPTANCE" },
					{ name => "BN",     description => "BANK_NOTES" },
					{ name => "BOX",    description => "BILL_OF_EXCHANGES" },
					{ name => "BRADY",  description => "BRADY_BOND" },
					{ name => "BRIDGE", description => "BRIDGE_LOAN" },
					{ name => "BUYSELL", description => "BUY_SELLBACK" },
					{ name => "CB",      description => "CONVERTIBLE_BOND" },
					{ name => "CD", description => "CERTIFICATE_OF_DEPOSIT" },
					{ name => "CL", description => "CALL_LOANS" },
					{
						name        => "CMBS",
						description => "CORP_MORTGAGE_BACKED_SECURITIES"
					},
					{
						name        => "CMO",
						description => "COLLATERALIZED_MORTGAGE_OBLIGATION"
					},
					{
						name        => "COFO",
						description => "CERTIFICATE_OF_OBLIGATION"
					},
					{
						name        => "COFP",
						description => "CERTIFICATE_OF_PARTICIPATION"
					},
					{ name => "CORP", description => "CORPORATE_BOND" },
					{ name => "CP",   description => "COMMERCIAL_PAPER" },
					{
						name        => "CPP",
						description => "CORPORATE_PRIVATE_PLACEMENT"
					},
					{ name => "CS",      description => "COMMON_STOCK" },
					{ name => "DEFLTED", description => "DEFAULTED" },
					{ name => "DINP", description => "DEBTOR_IN_POSSESSION" },
					{ name => "DN",   description => "DEPOSIT_NOTES" },
					{ name => "DUAL", description => "DUAL_CURRENCY" },
					{
						name        => "EUCD",
						description => "EURO_CERTIFICATE_OF_DEPOSIT"
					},
					{
						name        => "EUCORP",
						description => "EURO_CORPORATE_BOND"
					},
					{
						name        => "EUCP",
						description => "EURO_COMMERCIAL_PAPER"
					},
					{ name => "EUSOV", description => "EURO_SOVEREIGNS" },
					{
						name        => "EUSUPRA",
						description => "EURO_SUPRANATIONAL_COUPONS"
					},
					{ name => "FAC", description => "FEDERAL_AGENCY_COUPON" },
					{
						name        => "FADN",
						description => "FEDERAL_AGENCY_DISCOUNT_NOTE"
					},
					{
						name        => "FOR",
						description => "FOREIGN_EXCHANGE_CONTRACT"
					},
					{ name => "FORWARD", description => "FORWARD" },
					{ name => "FUT",     description => "FUTURE" },
					{
						name        => "GO",
						description => "GENERAL_OBLIGATION_BONDS"
					},
					{ name => "IET",     description => "IOETTE_MORTGAGE" },
					{ name => "LOFC",    description => "LETTER_OF_CREDIT" },
					{ name => "LQN",     description => "LIQUIDITY_NOTE" },
					{ name => "MATURED", description => "MATURED" },
					{
						name        => "MBS",
						description => "MORTGAGE_BACKED_SECURITIES"
					},
					{ name => "MF", description => "MUTUAL_FUND" },
					{
						name        => "MIO",
						description => "MORTGAGE_INTEREST_ONLY"
					},
					{ name => "MLEG", description => "MULTI_LEG_INSTRUMENT" },
					{
						name        => "MPO",
						description => "MORTGAGE_PRINCIPAL_ONLY"
					},
					{
						name        => "MPP",
						description => "MORTGAGE_PRIVATE_PLACEMENT"
					},
					{
						name        => "MPT",
						description => "MISCELLANEOUS_PASS_THROUGH"
					},
					{ name => "MT",    description => "MANDATORY_TENDER" },
					{ name => "MTN",   description => "MEDIUM_TERM_NOTES" },
					{ name => "NONE",  description => "NO_SECURITY_TYPE" },
					{ name => "ONITE", description => "OVERNIGHT" },
					{ name => "OPT",   description => "OPTION" },
					{
						name        => "PEF",
						description => "PRIVATE_EXPORT_FUNDING"
					},
					{ name => "PFAND", description => "PFANDBRIEFE" },
					{ name => "PN",    description => "PROMISSORY_NOTE" },
					{ name => "PS",    description => "PREFERRED_STOCK" },
					{ name => "PZFJ",  description => "PLAZOS_FIJOS" },
					{
						name        => "RAN",
						description => "REVENUE_ANTICIPATION_NOTE"
					},
					{ name => "REPLACD", description => "REPLACED" },
					{ name => "REPO",    description => "REPURCHASE" },
					{ name => "RETIRED", description => "RETIRED" },
					{ name => "REV",     description => "REVENUE_BONDS" },
					{ name => "RVLV",    description => "REVOLVER_LOAN" },
					{
						name        => "RVLVTRM",
						description => "REVOLVER_TERM_LOAN"
					},
					{ name => "SECLOAN", description => "SECURITIES_LOAN" },
					{
						name        => "SECPLEDGE",
						description => "SECURITIES_PLEDGE"
					},
					{ name => "SPCLA", description => "SPECIAL_ASSESSMENT" },
					{ name => "SPCLO", description => "SPECIAL_OBLIGATION" },
					{ name => "SPCLT", description => "SPECIAL_TAX" },
					{ name => "STN", description => "SHORT_TERM_LOAN_NOTE" },
					{ name => "STRUCT", description => "STRUCTURED_NOTES" },
					{
						name        => "SUPRA",
						description => "USD_SUPRANATIONAL_COUPONS"
					},
					{ name => "SWING", description => "SWING_LINE_FACILITY" },
					{ name => "TAN", description => "TAX_ANTICIPATION_NOTE" },
					{ name => "TAXA",  description => "TAX_ALLOCATION" },
					{ name => "TBA",   description => "TO_BE_ANNOUNCED" },
					{ name => "TBILL", description => "US_TREASURY_BILL" },
					{ name => "TBOND", description => "US_TREASURY_BOND" },
					{
						name => "TCAL",
						description =>
						  "PRINCIPAL_STRIP_OF_A_CALLABLE_BOND_OR_NOTE"
					},
					{ name => "TD", description => "TIME_DEPOSIT" },
					{
						name        => "TECP",
						description => "TAX_EXEMPT_COMMERCIAL_PAPER"
					},
					{ name => "TERM", description => "TERM_LOAN" },
					{
						name        => "TINT",
						description => "INTEREST_STRIP_FROM_ANY_BOND_OR_NOTE"
					},
					{
						name => "TIPS",
						description =>
						  "TREASURY_INFLATION_PROTECTED_SECURITIES"
					},
					{ name => "TNOTE", description => "US_TREASURY_NOTE" },
					{
						name => "TPRN",
						description =>
						  "PRINCIPAL_STRIP_FROM_A_NON_CALLABLE_BOND_OR_NOTE"
					},
					{
						name        => "TRAN",
						description => "TAX_AND_REVENUE_ANTICIPATION_NOTE"
					},
					{
						name        => "VRDN",
						description => "VARIABLE_RATE_DEMAND_NOTE"
					},
					{ name => "WAR",     description => "WARRANT" },
					{ name => "WITHDRN", description => "WITHDRAWN" },
					{ name => "XCN",    description => "EXTENDED_COMM_NOTE" },
					{ name => "XLINKD", description => "INDEXED_LINKED" },
					{
						name        => "YANK",
						description => "YANKEE_CORPORATE_BOND"
					},
					{
						name        => "YCD",
						description => "YANKEE_CERTIFICATE_OF_DEPOSIT"
					},
				]
			},
			{
				number => "168",
				name   => "EffectiveTime",
				type   => "UTCTIMESTAMP"
			},
			{
				number => "169",
				name   => "StandInstDbType",
				type   => "INT",
				enum   => [
					{ name => "0", description => "OTHER" },
					{ name => "1", description => "DTC_SID" },
					{ name => "2", description => "THOMSON_ALERT" },
					{ name => "3", description => "A_GLOBAL_CUSTODIAN" },
					{ name => "4", description => "ACCOUNTNET" },
				]
			},
			{ number => "170", name => "StandInstDbName", type => "STRING" },
			{ number => "171", name => "StandInstDbID",   type => "STRING" },
			{
				number => "172",
				name   => "SettlDeliveryType",
				type   => "INT",
				enum   => [
					{ name => "0", description => "VERSUS_PAYMENT" },
					{ name => "1", description => "FREE" },
					{ name => "2", description => "TRI_PARTY" },
					{ name => "3", description => "HOLD_IN_CUSTODY" },
				]
			},
			{ number => "188", name => "BidSpotRate", type => "PRICE" },
			{
				number => "189",
				name   => "BidForwardPoints",
				type   => "PRICEOFFSET"
			},
			{ number => "190", name => "OfferSpotRate", type => "PRICE" },
			{
				number => "191",
				name   => "OfferForwardPoints",
				type   => "PRICEOFFSET"
			},
			{ number => "192", name => "OrderQty2",  type => "QTY" },
			{ number => "193", name => "SettlDate2", type => "LOCALMKTDATE" },
			{ number => "194", name => "LastSpotRate", type => "PRICE" },
			{
				number => "195",
				name   => "LastForwardPoints",
				type   => "PRICEOFFSET"
			},
			{ number => "196", name => "AllocLinkID", type => "STRING" },
			{
				number => "197",
				name   => "AllocLinkType",
				type   => "INT",
				enum   => [
					{ name => "0", description => "F_X_NETTING" },
					{ name => "1", description => "F_X_SWAP" },
				]
			},
			{ number => "198", name => "SecondaryOrderID", type => "STRING" },
			{
				number => "199",
				name   => "NoIOIQualifiers",
				type   => "NUMINGROUP"
			},
			{
				number => "200",
				name   => "MaturityMonthYear",
				type   => "MONTHYEAR"
			},
			{ number => "202", name => "StrikePrice", type => "PRICE" },
			{
				number => "203",
				name   => "CoveredOrUncovered",
				type   => "INT",
				enum   => [
					{ name => "0", description => "COVERED" },
					{ name => "1", description => "UNCOVERED" },
				]
			},
			{ number => "206", name => "OptAttribute", type => "CHAR" },
			{
				number => "207",
				name   => "SecurityExchange",
				type   => "EXCHANGE"
			},
			{
				number => "208",
				name   => "NotifyBrokerOfCredit",
				type   => "BOOLEAN"
			},
			{
				number => "209",
				name   => "AllocHandlInst",
				type   => "INT",
				enum   => [
					{ name => "1", description => "MATCH" },
					{ name => "2", description => "FORWARD" },
					{ name => "3", description => "FORWARD_AND_MATCH" },
				]
			},
			{ number => "210", name => "MaxShow",        type => "QTY" },
			{ number => "211", name => "PegOffsetValue", type => "FLOAT" },
			{ number => "212", name => "XmlDataLen",     type => "LENGTH" },
			{ number => "213", name => "XmlData",        type => "DATA" },
			{ number => "214", name => "SettlInstRefID", type => "STRING" },
			{ number => "215", name => "NoRoutingIDs", type => "NUMINGROUP" },
			{
				number => "216",
				name   => "RoutingType",
				type   => "INT",
				enum   => [
					{ name => "1", description => "TARGET_FIRM" },
					{ name => "2", description => "TARGET_LIST" },
					{ name => "3", description => "BLOCK_FIRM" },
					{ name => "4", description => "BLOCK_LIST" },
				]
			},
			{ number => "217", name => "RoutingID", type => "STRING" },
			{ number => "218", name => "Spread",    type => "PRICEOFFSET" },
			{
				number => "220",
				name   => "BenchmarkCurveCurrency",
				type   => "CURRENCY"
			},
			{
				number => "221",
				name   => "BenchmarkCurveName",
				type   => "STRING",
				enum   => [
					{ name => "MuniAAA",     description => "MUNIAAA" },
					{ name => "FutureSWAP",  description => "FUTURESWAP" },
					{ name => "LIBID",       description => "LIBID" },
					{ name => "LIBOR",       description => "LIBOR" },
					{ name => "OTHER",       description => "OTHER" },
					{ name => "SWAP",        description => "SWAP" },
					{ name => "Treasury",    description => "TREASURY" },
					{ name => "Euribor",     description => "EURIBOR" },
					{ name => "Pfandbriefe", description => "PFANDBRIEFE" },
					{ name => "EONIA",       description => "EONIA" },
					{ name => "SONIA",       description => "SONIA" },
					{ name => "EUREPO",      description => "EUREPO" },
				]
			},
			{
				number => "222",
				name   => "BenchmarkCurvePoint",
				type   => "STRING"
			},
			{ number => "223", name => "CouponRate", type => "PERCENTAGE" },
			{
				number => "224",
				name   => "CouponPaymentDate",
				type   => "LOCALMKTDATE"
			},
			{ number => "225", name => "IssueDate", type => "LOCALMKTDATE" },
			{ number => "226", name => "RepurchaseTerm", type => "INT" },
			{
				number => "227",
				name   => "RepurchaseRate",
				type   => "PERCENTAGE"
			},
			{ number => "228", name => "Factor", type => "FLOAT" },
			{
				number => "229",
				name   => "TradeOriginationDate",
				type   => "LOCALMKTDATE"
			},
			{ number => "230", name => "ExDate", type => "LOCALMKTDATE" },
			{
				number => "231",
				name   => "ContractMultiplier",
				type   => "FLOAT"
			},
			{
				number => "232",
				name   => "NoStipulations",
				type   => "NUMINGROUP"
			},
			{
				number => "233",
				name   => "StipulationType",
				type   => "STRING",
				enum   => [
					{ name => "AMT", description => "AMT" },
					{
						name        => "AUTOREINV",
						description => "AUTO_REINVESTMENT_AT_OR_BETTER"
					},
					{ name => "BANKQUAL", description => "BANK_QUALIFIED" },
					{ name => "BGNCON", description => "BARGAIN_CONDITIONS" },
					{ name => "COUPON", description => "COUPON_RANGE" },
					{
						name        => "CURRENCY",
						description => "ISO_CURRENCY_CODE"
					},
					{
						name        => "CUSTOMDATE",
						description => "CUSTOM_START_END_DATE"
					},
					{
						name        => "GEOG",
						description => "GEOGRAPHICS_AND_PERCENT_RANGE"
					},
					{
						name        => "HAIRCUT",
						description => "VALUATION_DISCOUNT"
					},
					{ name => "INSURED", description => "INSURED" },
					{
						name        => "ISSUE",
						description => "YEAR_OR_YEAR_MONTH_OF_ISSUE"
					},
					{ name => "ISSUER", description => "ISSUERS_TICKER" },
					{
						name        => "ISSUESIZE",
						description => "ISSUE_SIZE_RANGE"
					},
					{ name => "LOOKBACK", description => "LOOKBACK_DAYS" },
					{
						name        => "LOT",
						description => "EXPLICIT_LOT_IDENTIFIER"
					},
					{ name => "LOTVAR", description => "LOT_VARIANCE" },
					{
						name        => "MAT",
						description => "MATURITY_YEAR_AND_MONTH"
					},
					{ name => "MATURITY", description => "MATURITY_RANGE" },
					{
						name        => "MAXSUBS",
						description => "MAXIMUM_SUBSTITUTIONS"
					},
					{ name => "MINQTY",  description => "MINIMUM_QUANTITY" },
					{ name => "MININCR", description => "MINIMUM_INCREMENT" },
					{
						name        => "MINDNOM",
						description => "MINIMUM_DENOMINATION"
					},
					{
						name        => "PAYFREQ",
						description => "PAYMENT_FREQUENCY_CALENDAR"
					},
					{ name => "PIECES", description => "NUMBER_OF_PIECES" },
					{ name => "PMAX",   description => "POOLS_MAXIMUM" },
					{ name => "PPM",    description => "POOLS_PER_MILLION" },
					{ name => "PPL",    description => "POOLS_PER_LOT" },
					{ name => "PPT",    description => "POOLS_PER_TRADE" },
					{ name => "PRICE",  description => "PRICE_RANGE" },
					{
						name        => "PRICEFREQ",
						description => "PRICING_FREQUENCY"
					},
					{ name => "PROD",    description => "PRODUCTION_YEAR" },
					{ name => "PROTECT", description => "CALL_PROTECTION" },
					{ name => "PURPOSE", description => "PURPOSE" },
					{
						name        => "PXSOURCE",
						description => "BENCHMARK_PRICE_SOURCE"
					},
					{
						name        => "RATING",
						description => "RATING_SOURCE_AND_RANGE"
					},
					{ name => "RESTRICTED", description => "RESTRICTED" },
					{ name => "SECTOR",     description => "MARKET_SECTOR" },
					{
						name        => "SECTYPE",
						description => "SECURITYTYPE_INCLUDED_OR_EXCLUDED"
					},
					{ name => "STRUCT", description => "STRUCTURE" },
					{
						name        => "SUBSFREQ",
						description => "SUBSTITUTIONS_FREQUENCY"
					},
					{
						name        => "SUBSLEFT",
						description => "SUBSTITUTIONS_LEFT"
					},
					{ name => "TEXT",   description => "FREEFORM_TEXT" },
					{ name => "TRDVAR", description => "TRADE_VARIANCE" },
					{
						name        => "WAC",
						description => "WEIGHTED_AVERAGE_COUPON"
					},
					{
						name        => "WAL",
						description => "WEIGHTED_AVERAGE_LIFE_COUPON"
					},
					{
						name        => "WALA",
						description => "WEIGHTED_AVERAGE_LOAN_AGE"
					},
					{
						name        => "WAM",
						description => "WEIGHTED_AVERAGE_MATURITY"
					},
					{ name => "WHOLE", description => "WHOLE_POOL" },
					{ name => "YIELD", description => "YIELD_RANGE" },
					{
						name        => "SMM",
						description => "SINGLE_MONTHLY_MORTALITY"
					},
					{
						name        => "CPR",
						description => "CONSTANT_PREPAYMENT_RATE"
					},
					{
						name        => "CPY",
						description => "CONSTANT_PREPAYMENT_YIELD"
					},
					{
						name        => "CPP",
						description => "CONSTANT_PREPAYMENT_PENALTY"
					},
					{
						name        => "ABS",
						description => "ABSOLUTE_PREPAYMENT_SPEED"
					},
					{
						name        => "MPR",
						description => "MONTHLY_PREPAYMENT_RATE"
					},
					{
						name        => "PSA",
						description => "PERCENT_OF_BMA_PREPAYMENT_CURVE"
					},
					{
						name => "PPC",
						description =>
						  "PERCENT_OF_PROSPECTUS_PREPAYMENT_CURVE"
					},
					{
						name => "MHP",
						description =>
						  "PERCENT_OF_MANUFACTURED_HOUSING_PREPAYMENT_CURVE"
					},
					{
						name => "HEP",
						description =>
						  "FINAL_CPR_OF_HOME_EQUITY_PREPAYMENT_CURVE"
					},
				]
			},
			{
				number => "234",
				name   => "StipulationValue",
				type   => "STRING",
				enum   => [
					{ name => "CD", description => "SPECIAL_CUM_DIVIDEND" },
					{ name => "XD", description => "SPECIAL_EX_DIVIDEND" },
					{ name => "CC", description => "SPECIAL_CUM_COUPON" },
					{ name => "XC", description => "SPECIAL_EX_COUPON" },
					{ name => "CB", description => "SPECIAL_CUM_BONUS" },
					{ name => "XB", description => "SPECIAL_EX_BONUS" },
					{ name => "CR", description => "SPECIAL_CUM_RIGHTS" },
					{ name => "XR", description => "SPECIAL_EX_RIGHTS" },
					{
						name        => "CP",
						description => "SPECIAL_CUM_CAPITAL_REPAYMENTS"
					},
					{
						name        => "XP",
						description => "SPECIAL_EX_CAPITAL_REPAYMENTS"
					},
					{ name => "CS", description => "CASH_SETTLEMENT" },
					{ name => "SP", description => "SPECIAL_PRICE" },
					{
						name => "TR",
						description =>
						  "REPORT_FOR_EUROPEAN_EQUITY_MARKET_SECURITIES"
					},
					{ name => "GD", description => "GUARANTEED_DELIVERY" },
				]
			},
			{
				number => "235",
				name   => "YieldType",
				type   => "STRING",
				enum   => [
					{ name => "AFTERTAX", description => "AFTER_TAX_YIELD" },
					{ name => "ANNUAL",   description => "ANNUAL_YIELD" },
					{ name => "ATISSUE",  description => "YIELD_AT_ISSUE" },
					{
						name        => "AVGMATURITY",
						description => "YIELD_TO_AVERAGE_MATURITY"
					},
					{ name => "BOOK", description => "BOOK_YIELD" },
					{ name => "CALL", description => "YIELD_TO_NEXT_CALL" },
					{
						name        => "CHANGE",
						description => "YIELD_CHANGE_SINCE_CLOSE"
					},
					{ name => "CLOSE",    description => "CLOSING_YIELD" },
					{ name => "COMPOUND", description => "COMPOUND_YIELD" },
					{ name => "CURRENT",  description => "CURRENT_YIELD" },
					{ name => "GROSS",    description => "TRUE_GROSS_YIELD" },
					{
						name        => "GOVTEQUIV",
						description => "GOVERNMENT_EQUIVALENT_YIELD"
					},
					{
						name        => "INFLATION",
						description => "YIELD_WITH_INFLATION_ASSUMPTION"
					},
					{
						name        => "INVERSEFLOATER",
						description => "INVERSE_FLOATER_BOND_YIELD"
					},
					{
						name        => "LASTCLOSE",
						description => "MOST_RECENT_CLOSING_YIELD"
					},
					{
						name        => "LASTMONTH",
						description => "CLOSING_YIELD_MOST_RECENT_MONTH"
					},
					{
						name        => "LASTQUARTER",
						description => "CLOSING_YIELD_MOST_RECENT_QUARTER"
					},
					{
						name        => "LASTYEAR",
						description => "CLOSING_YIELD_MOST_RECENT_YEAR"
					},
					{
						name        => "LONGAVGLIFE",
						description => "YIELD_TO_LONGEST_AVERAGE_LIFE"
					},
					{ name => "MARK", description => "MARK_TO_MARKET_YIELD" },
					{
						name        => "MATURITY",
						description => "YIELD_TO_MATURITY"
					},
					{
						name        => "NEXTREFUND",
						description => "YIELD_TO_NEXT_REFUND"
					},
					{
						name        => "OPENAVG",
						description => "OPEN_AVERAGE_YIELD"
					},
					{ name => "PUT", description => "YIELD_TO_NEXT_PUT" },
					{
						name        => "PREVCLOSE",
						description => "PREVIOUS_CLOSE_YIELD"
					},
					{ name => "PROCEEDS", description => "PROCEEDS_YIELD" },
					{
						name        => "SEMIANNUAL",
						description => "SEMI_ANNUAL_YIELD"
					},
					{
						name        => "SHORTAVGLIFE",
						description => "YIELD_TO_SHORTEST_AVERAGE_LIFE"
					},
					{ name => "SIMPLE", description => "SIMPLE_YIELD" },
					{
						name        => "TAXEQUIV",
						description => "TAX_EQUIVALENT_YIELD"
					},
					{
						name        => "TENDER",
						description => "YIELD_TO_TENDER_DATE"
					},
					{ name => "TRUE", description => "TRUE_YIELD" },
					{
						name        => "VALUE1_32",
						description => "YIELD_VALUE_OF_1_32"
					},
					{ name => "WORST", description => "YIELD_TO_WORST" },
				]
			},
			{ number => "236", name => "Yield", type => "PERCENTAGE" },
			{ number => "237", name => "TotalTakedown", type => "AMT" },
			{ number => "238", name => "Concession",    type => "AMT" },
			{
				number => "239",
				name   => "RepoCollateralSecurityType",
				type   => "INT"
			},
			{
				number => "240",
				name   => "RedemptionDate",
				type   => "LOCALMKTDATE"
			},
			{
				number => "241",
				name   => "UnderlyingCouponPaymentDate",
				type   => "LOCALMKTDATE"
			},
			{
				number => "242",
				name   => "UnderlyingIssueDate",
				type   => "LOCALMKTDATE"
			},
			{
				number => "243",
				name   => "UnderlyingRepoCollateralSecurityType",
				type   => "INT"
			},
			{
				number => "244",
				name   => "UnderlyingRepurchaseTerm",
				type   => "INT"
			},
			{
				number => "245",
				name   => "UnderlyingRepurchaseRate",
				type   => "PERCENTAGE"
			},
			{ number => "246", name => "UnderlyingFactor", type => "FLOAT" },
			{
				number => "247",
				name   => "UnderlyingRedemptionDate",
				type   => "LOCALMKTDATE"
			},
			{
				number => "248",
				name   => "LegCouponPaymentDate",
				type   => "LOCALMKTDATE"
			},
			{
				number => "249",
				name   => "LegIssueDate",
				type   => "LOCALMKTDATE"
			},
			{
				number => "250",
				name   => "LegRepoCollateralSecurityType",
				type   => "INT"
			},
			{ number => "251", name => "LegRepurchaseTerm", type => "INT" },
			{
				number => "252",
				name   => "LegRepurchaseRate",
				type   => "PERCENTAGE"
			},
			{ number => "253", name => "LegFactor", type => "FLOAT" },
			{
				number => "254",
				name   => "LegRedemptionDate",
				type   => "LOCALMKTDATE"
			},
			{ number => "255", name => "CreditRating", type => "STRING" },
			{
				number => "256",
				name   => "UnderlyingCreditRating",
				type   => "STRING"
			},
			{ number => "257", name => "LegCreditRating", type => "STRING" },
			{
				number => "258",
				name   => "TradedFlatSwitch",
				type   => "BOOLEAN"
			},
			{
				number => "259",
				name   => "BasisFeatureDate",
				type   => "LOCALMKTDATE"
			},
			{ number => "260", name => "BasisFeaturePrice", type => "PRICE" },
			{ number => "262", name => "MDReqID", type => "STRING" },
			{
				number => "263",
				name   => "SubscriptionRequestType",
				type   => "CHAR",
				enum   => [
					{ name => "0", description => "SNAPSHOT" },
					{ name => "1", description => "SNAPSHOT_PLUS_UPDATES" },
					{
						name => "2",
						description =>
						  "DISABLE_PREVIOUS_SNAPSHOT_PLUS_UPDATE_REQUEST"
					},
				]
			},
			{
				number => "264",
				name   => "MarketDepth",
				type   => "INT",
				enum   => [
					{ name => "0", description => "FULL_BOOK" },
					{ name => "1", description => "TOP_OF_BOOK" },
				]
			},
			{
				number => "265",
				name   => "MDUpdateType",
				type   => "INT",
				enum   => [
					{ name => "0", description => "FULL_REFRESH" },
					{ name => "1", description => "INCREMENTAL_REFRESH" },
				]
			},
			{ number => "266", name => "AggregatedBook", type => "BOOLEAN" },
			{
				number => "267",
				name   => "NoMDEntryTypes",
				type   => "NUMINGROUP"
			},
			{ number => "268", name => "NoMDEntries", type => "NUMINGROUP" },
			{
				number => "269",
				name   => "MDEntryType",
				type   => "CHAR",
				enum   => [
					{ name => "0", description => "BID" },
					{ name => "1", description => "OFFER" },
					{ name => "2", description => "TRADE" },
					{ name => "3", description => "INDEX_VALUE" },
					{ name => "4", description => "OPENING_PRICE" },
					{ name => "5", description => "CLOSING_PRICE" },
					{ name => "6", description => "SETTLEMENT_PRICE" },
					{
						name        => "7",
						description => "TRADING_SESSION_HIGH_PRICE"
					},
					{
						name        => "8",
						description => "TRADING_SESSION_LOW_PRICE"
					},
					{
						name        => "9",
						description => "TRADING_SESSION_VWAP_PRICE"
					},
					{ name => "A", description => "IMBALANCE" },
					{ name => "B", description => "TRADE_VOLUME" },
					{ name => "C", description => "OPEN_INTEREST" },
				]
			},
			{ number => "270", name => "MDEntryPx",   type => "PRICE" },
			{ number => "271", name => "MDEntrySize", type => "QTY" },
			{ number => "272", name => "MDEntryDate", type => "UTCDATEONLY" },
			{ number => "273", name => "MDEntryTime", type => "UTCTIMEONLY" },
			{
				number => "274",
				name   => "TickDirection",
				type   => "CHAR",
				enum   => [
					{ name => "0", description => "PLUS_TICK" },
					{ name => "1", description => "ZERO_PLUS_TICK" },
					{ name => "2", description => "MINUS_TICK" },
					{ name => "3", description => "ZERO_MINUS_TICK" },
				]
			},
			{ number => "275", name => "MDMkt", type => "EXCHANGE" },
			{
				number => "276",
				name   => "QuoteCondition",
				type   => "MULTIPLEVALUESTRING",
				enum   => [
					{ name => "A", description => "OPEN_ACTIVE" },
					{ name => "B", description => "CLOSED_INACTIVE" },
					{ name => "C", description => "EXCHANGE_BEST" },
					{ name => "D", description => "CONSOLIDATED_BEST" },
					{ name => "E", description => "LOCKED" },
					{ name => "F", description => "CROSSED" },
					{ name => "G", description => "DEPTH" },
					{ name => "H", description => "FAST_TRADING" },
					{ name => "I", description => "NON_FIRM" },
				]
			},
			{
				number => "277",
				name   => "TradeCondition",
				type   => "MULTIPLEVALUESTRING",
				enum   => [
					{ name => "A", description => "CASH_MARKET" },
					{ name => "B", description => "AVERAGE_PRICE_TRADE" },
					{ name => "C", description => "CASH_TRADE" },
					{ name => "D", description => "NEXT_DAY_MARKET" },
					{
						name        => "E",
						description => "OPENING_REOPENING_TRADE_DETAIL"
					},
					{ name => "F", description => "INTRADAY_TRADE_DETAIL" },
					{ name => "G", description => "RULE127" },
					{ name => "H", description => "RULE155" },
					{ name => "I", description => "SOLD_LAST" },
					{ name => "J", description => "NEXT_DAY_TRADE" },
					{ name => "K", description => "OPENED" },
					{ name => "L", description => "SELLER" },
					{ name => "M", description => "SOLD" },
					{ name => "N", description => "STOPPED_STOCK" },
					{ name => "P", description => "IMBALANCE_MORE_BUYERS" },
					{ name => "Q", description => "IMBALANCE_MORE_SELLERS" },
					{ name => "R", description => "OPENING_PRICE" },
				]
			},
			{ number => "278", name => "MDEntryID", type => "STRING" },
			{
				number => "279",
				name   => "MDUpdateAction",
				type   => "CHAR",
				enum   => [
					{ name => "0", description => "NEW" },
					{ name => "1", description => "CHANGE" },
					{ name => "2", description => "DELETE" },
				]
			},
			{ number => "280", name => "MDEntryRefID", type => "STRING" },
			{
				number => "281",
				name   => "MDReqRejReason",
				type   => "CHAR",
				enum   => [
					{ name => "0", description => "UNKNOWN_SYMBOL" },
					{ name => "1", description => "DUPLICATE_MDREQID" },
					{ name => "2", description => "INSUFFICIENT_BANDWIDTH" },
					{
						name        => "3",
						description => "INSUFFICIENT_PERMISSIONS"
					},
					{
						name        => "4",
						description => "UNSUPPORTED_SUBSCRIPTIONREQUESTTYPE"
					},
					{ name => "5", description => "UNSUPPORTED_MARKETDEPTH" },
					{
						name        => "6",
						description => "UNSUPPORTED_MDUPDATETYPE"
					},
					{
						name        => "7",
						description => "UNSUPPORTED_AGGREGATEDBOOK"
					},
					{ name => "8", description => "UNSUPPORTED_MDENTRYTYPE" },
					{
						name        => "9",
						description => "UNSUPPORTED_TRADINGSESSIONID"
					},
					{ name => "A", description => "UNSUPPORTED_SCOPE" },
					{
						name        => "B",
						description => "UNSUPPORTED_OPENCLOSESETTLEFLAG"
					},
					{
						name        => "C",
						description => "UNSUPPORTED_MDIMPLICITDELETE"
					},
				]
			},
			{
				number => "282",
				name   => "MDEntryOriginator",
				type   => "STRING"
			},
			{ number => "283", name => "LocationID", type => "STRING" },
			{ number => "284", name => "DeskID",     type => "STRING" },
			{
				number => "285",
				name   => "DeleteReason",
				type   => "CHAR",
				enum   => [
					{ name => "0", description => "CANCELATION_TRADE_BUST" },
					{ name => "1", description => "ERROR" },
				]
			},
			{
				number => "286",
				name   => "OpenCloseSettlFlag",
				type   => "MULTIPLEVALUESTRING",
				enum   => [
					{
						name        => "0",
						description => "DAILY_OPEN_CLOSE_SETTLEMENT_ENTRY"
					},
					{
						name        => "1",
						description => "SESSION_OPEN_CLOSE_SETTLEMENT_ENTRY"
					},
					{
						name        => "2",
						description => "DELIVERY_SETTLEMENT_ENTRY"
					},
					{ name => "3", description => "EXPECTED_ENTRY" },
					{
						name        => "4",
						description => "ENTRY_FROM_PREVIOUS_BUSINESS_DAY"
					},
					{ name => "5", description => "THEORETICAL_PRICE_VALUE" },
				]
			},
			{ number => "287", name => "SellerDays",    type => "INT" },
			{ number => "288", name => "MDEntryBuyer",  type => "STRING" },
			{ number => "289", name => "MDEntrySeller", type => "STRING" },
			{ number => "290", name => "MDEntryPositionNo", type => "INT" },
			{
				number => "291",
				name   => "FinancialStatus",
				type   => "MULTIPLEVALUESTRING",
				enum   => [
					{ name => "1", description => "BANKRUPT" },
					{ name => "2", description => "PENDING_DELISTING" },
				]
			},
			{
				number => "292",
				name   => "CorporateAction",
				type   => "MULTIPLEVALUESTRING",
				enum   => [
					{ name => "A", description => "EX_DIVIDEND" },
					{ name => "B", description => "EX_DISTRIBUTION" },
					{ name => "C", description => "EX_RIGHTS" },
					{ name => "D", description => "NEW" },
					{ name => "E", description => "EX_INTEREST" },
				]
			},
			{ number => "293", name => "DefBidSize",   type => "QTY" },
			{ number => "294", name => "DefOfferSize", type => "QTY" },
			{
				number => "295",
				name   => "NoQuoteEntries",
				type   => "NUMINGROUP"
			},
			{ number => "296", name => "NoQuoteSets", type => "NUMINGROUP" },
			{
				number => "297",
				name   => "QuoteStatus",
				type   => "INT",
				enum   => [
					{ name => "0", description => "ACCEPTED" },
					{ name => "1", description => "CANCELED_FOR_SYMBOL" },
					{
						name        => "2",
						description => "CANCELED_FOR_SECURITY_TYPE"
					},
					{ name => "3", description => "CANCELED_FOR_UNDERLYING" },
					{ name => "4", description => "CANCELED_ALL" },
					{ name => "5", description => "REJECTED" },
					{ name => "6", description => "REMOVED_FROM_MARKET" },
					{ name => "7", description => "EXPIRED" },
					{ name => "8", description => "QUERY" },
					{ name => "9", description => "QUOTE_NOT_FOUND" },
					{ name => "10", description => "PENDING" },
					{ name => "11", description => "PASS" },
					{ name => "12", description => "LOCKED_MARKET_WARNING" },
					{ name => "13", description => "CROSS_MARKET_WARNING" },
					{
						name        => "14",
						description => "CANCELED_DUE_TO_LOCK_MARKET"
					},
					{
						name        => "15",
						description => "CANCELED_DUE_TO_CROSS_MARKET"
					},
				]
			},
			{
				number => "298",
				name   => "QuoteCancelType",
				type   => "INT",
				enum   => [
					{ name => "1", description => "CANCEL_FOR_SYMBOL" },
					{
						name        => "2",
						description => "CANCEL_FOR_SECURITY_TYPE"
					},
					{
						name        => "3",
						description => "CANCEL_FOR_UNDERLYING_SYMBOL"
					},
					{ name => "4", description => "CANCEL_ALL_QUOTES" },
				]
			},
			{ number => "299", name => "QuoteEntryID", type => "STRING" },
			{
				number => "300",
				name   => "QuoteRejectReason",
				type   => "INT",
				enum   => [
					{ name => "1", description => "UNKNOWN_SYMBOL" },
					{ name => "2", description => "EXCHANGE_CLOSED" },
					{
						name        => "3",
						description => "QUOTE_REQUEST_EXCEEDS_LIMIT"
					},
					{ name => "4", description => "TOO_LATE_TO_ENTER" },
					{ name => "5", description => "UNKNOWN_QUOTE" },
					{ name => "6", description => "DUPLICATE_QUOTE" },
					{ name => "7", description => "INVALID_BID_ASK_SPREAD" },
					{ name => "8", description => "INVALID_PRICE" },
					{
						name        => "9",
						description => "NOT_AUTHORIZED_TO_QUOTE_SECURITY"
					},
				]
			},
			{
				number => "301",
				name   => "QuoteResponseLevel",
				type   => "INT",
				enum   => [
					{ name => "0", description => "NO_ACKNOWLEDGEMENT" },
					{
						name => "1",
						description =>
						  "ACKNOWLEDGE_ONLY_NEGATIVE_OR_ERRONEOUS_QUOTES"
					},
					{
						name        => "2",
						description => "ACKNOWLEDGE_EACH_QUOTE_MESSAGES"
					},
				]
			},
			{ number => "302", name => "QuoteSetID", type => "STRING" },
			{
				number => "303",
				name   => "QuoteRequestType",
				type   => "INT",
				enum   => [
					{ name => "1", description => "MANUAL" },
					{ name => "2", description => "AUTOMATIC" },
				]
			},
			{ number => "304", name => "TotNoQuoteEntries", type => "INT" },
			{
				number => "305",
				name   => "UnderlyingSecurityIDSource",
				type   => "STRING"
			},
			{ number => "306", name => "UnderlyingIssuer", type => "STRING" },
			{
				number => "307",
				name   => "UnderlyingSecurityDesc",
				type   => "STRING"
			},
			{
				number => "308",
				name   => "UnderlyingSecurityExchange",
				type   => "EXCHANGE"
			},
			{
				number => "309",
				name   => "UnderlyingSecurityID",
				type   => "STRING"
			},
			{
				number => "310",
				name   => "UnderlyingSecurityType",
				type   => "STRING"
			},
			{ number => "311", name => "UnderlyingSymbol", type => "STRING" },
			{
				number => "312",
				name   => "UnderlyingSymbolSfx",
				type   => "STRING"
			},
			{
				number => "313",
				name   => "UnderlyingMaturityMonthYear",
				type   => "MONTHYEAR"
			},
			{
				number => "316",
				name   => "UnderlyingStrikePrice",
				type   => "PRICE"
			},
			{
				number => "317",
				name   => "UnderlyingOptAttribute",
				type   => "CHAR"
			},
			{
				number => "318",
				name   => "UnderlyingCurrency",
				type   => "CURRENCY"
			},
			{ number => "320", name => "SecurityReqID", type => "STRING" },
			{
				number => "321",
				name   => "SecurityRequestType",
				type   => "INT",
				enum   => [
					{
						name => "0",
						description =>
						  "REQUEST_SECURITY_IDENTITY_AND_SPECIFICATIONS"
					},
					{
						name => "1",
						description =>
"REQUEST_SECURITY_IDENTITY_FOR_THE_SPECIFICATIONS_PROVIDED"
					},
					{
						name        => "2",
						description => "REQUEST_LIST_SECURITY_TYPES"
					},
					{ name => "3", description => "REQUEST_LIST_SECURITIES" },
				]
			},
			{
				number => "322",
				name   => "SecurityResponseID",
				type   => "STRING"
			},
			{
				number => "323",
				name   => "SecurityResponseType",
				type   => "INT",
				enum   => [
					{
						name        => "1",
						description => "ACCEPT_SECURITY_PROPOSAL_AS_IS"
					},
					{
						name => "2",
						description =>
"ACCEPT_SECURITY_PROPOSAL_WITH_REVISIONS_AS_INDICATED_IN_THE_MESSAGE"
					},
					{
						name => "3",
						description =>
						  "LIST_OF_SECURITY_TYPES_RETURNED_PER_REQUEST"
					},
					{
						name => "4",
						description =>
						  "LIST_OF_SECURITIES_RETURNED_PER_REQUEST"
					},
					{
						name        => "5",
						description => "REJECT_SECURITY_PROPOSAL"
					},
					{
						name        => "6",
						description => "CAN_NOT_MATCH_SELECTION_CRITERIA"
					},
				]
			},
			{
				number => "324",
				name   => "SecurityStatusReqID",
				type   => "STRING"
			},
			{
				number => "325",
				name   => "UnsolicitedIndicator",
				type   => "BOOLEAN"
			},
			{
				number => "326",
				name   => "SecurityTradingStatus",
				type   => "INT",
				enum   => [
					{ name => "1", description => "OPENING_DELAY" },
					{ name => "2", description => "TRADING_HALT" },
					{ name => "3", description => "RESUME" },
					{ name => "4", description => "NO_OPEN_NO_RESUME" },
					{ name => "5", description => "PRICE_INDICATION" },
					{
						name        => "6",
						description => "TRADING_RANGE_INDICATION"
					},
					{ name => "7", description => "MARKET_IMBALANCE_BUY" },
					{ name => "8", description => "MARKET_IMBALANCE_SELL" },
					{
						name        => "9",
						description => "MARKET_ON_CLOSE_IMBALANCE_BUY"
					},
					{
						name        => "10",
						description => "MARKET_ON_CLOSE_IMBALANCE_SELL"
					},
					{ name => "11", description => "NOT_ASSIGNED" },
					{ name => "12", description => "NO_MARKET_IMBALANCE" },
					{
						name        => "13",
						description => "NO_MARKET_ON_CLOSE_IMBALANCE"
					},
					{ name => "14", description => "ITS_PRE_OPENING" },
					{ name => "15", description => "NEW_PRICE_INDICATION" },
					{
						name        => "16",
						description => "TRADE_DISSEMINATION_TIME"
					},
					{
						name        => "17",
						description => "READY_TO_TRADE_START_OF_SESSION"
					},
					{
						name => "18",
						description =>
						  "NOT_AVAILABLE_FOR_TRADING_END_OF_SESSION"
					},
					{
						name        => "19",
						description => "NOT_TRADED_ON_THIS_MARKET"
					},
					{ name => "20", description => "UNKNOWN_OR_INVALID" },
					{ name => "21", description => "PRE_OPEN" },
					{ name => "22", description => "OPENING_ROTATION" },
					{ name => "23", description => "FAST_MARKET" },
				]
			},
			{
				number => "327",
				name   => "HaltReason",
				type   => "CHAR",
				enum   => [
					{ name => "I", description => "ORDER_IMBALANCE" },
					{ name => "X", description => "EQUIPMENT_CHANGEOVER" },
					{ name => "P", description => "NEWS_PENDING" },
					{ name => "D", description => "NEWS_DISSEMINATION" },
					{ name => "E", description => "ORDER_INFLUX" },
					{ name => "M", description => "ADDITIONAL_INFORMATION" },
				]
			},
			{ number => "328", name => "InViewOfCommon", type => "BOOLEAN" },
			{ number => "329", name => "DueToRelated",   type => "BOOLEAN" },
			{ number => "330", name => "BuyVolume",      type => "QTY" },
			{ number => "331", name => "SellVolume",     type => "QTY" },
			{ number => "332", name => "HighPx",         type => "PRICE" },
			{ number => "333", name => "LowPx",          type => "PRICE" },
			{
				number => "334",
				name   => "Adjustment",
				type   => "INT",
				enum   => [
					{ name => "1", description => "CANCEL" },
					{ name => "2", description => "ERROR" },
					{ name => "3", description => "CORRECTION" },
				]
			},
			{ number => "335", name => "TradSesReqID",     type => "STRING" },
			{ number => "336", name => "TradingSessionID", type => "STRING" },
			{ number => "337", name => "ContraTrader",     type => "STRING" },
			{
				number => "338",
				name   => "TradSesMethod",
				type   => "INT",
				enum   => [
					{ name => "1", description => "ELECTRONIC" },
					{ name => "2", description => "OPEN_OUTCRY" },
					{ name => "3", description => "TWO_PARTY" },
				]
			},
			{
				number => "339",
				name   => "TradSesMode",
				type   => "INT",
				enum   => [
					{ name => "1", description => "TESTING" },
					{ name => "2", description => "SIMULATED" },
					{ name => "3", description => "PRODUCTION" },
				]
			},
			{
				number => "340",
				name   => "TradSesStatus",
				type   => "INT",
				enum   => [
					{ name => "0", description => "UNKNOWN" },
					{ name => "1", description => "HALTED" },
					{ name => "2", description => "OPEN" },
					{ name => "3", description => "CLOSED" },
					{ name => "4", description => "PRE_OPEN" },
					{ name => "5", description => "PRE_CLOSE" },
					{ name => "6", description => "REQUEST_REJECTED" },
				]
			},
			{
				number => "341",
				name   => "TradSesStartTime",
				type   => "UTCTIMESTAMP"
			},
			{
				number => "342",
				name   => "TradSesOpenTime",
				type   => "UTCTIMESTAMP"
			},
			{
				number => "343",
				name   => "TradSesPreCloseTime",
				type   => "UTCTIMESTAMP"
			},
			{
				number => "344",
				name   => "TradSesCloseTime",
				type   => "UTCTIMESTAMP"
			},
			{
				number => "345",
				name   => "TradSesEndTime",
				type   => "UTCTIMESTAMP"
			},
			{ number => "346", name => "NumberOfOrders", type => "INT" },
			{
				number => "347",
				name   => "MessageEncoding",
				type   => "STRING",
				enum   => [
					{ name => "ISO-2022-JP", description => "ISO_2022_JP" },
					{ name => "EUC-JP",      description => "EUC_JP" },
					{ name => "SHIFT_JIS",   description => "SHIFT_JIS" },
					{ name => "UTF-8",       description => "UTF_8" },
				]
			},
			{ number => "348", name => "EncodedIssuerLen", type => "LENGTH" },
			{ number => "349", name => "EncodedIssuer",    type => "DATA" },
			{
				number => "350",
				name   => "EncodedSecurityDescLen",
				type   => "LENGTH"
			},
			{
				number => "351",
				name   => "EncodedSecurityDesc",
				type   => "DATA"
			},
			{
				number => "352",
				name   => "EncodedListExecInstLen",
				type   => "LENGTH"
			},
			{
				number => "353",
				name   => "EncodedListExecInst",
				type   => "DATA"
			},
			{ number => "354", name => "EncodedTextLen", type => "LENGTH" },
			{ number => "355", name => "EncodedText",    type => "DATA" },
			{
				number => "356",
				name   => "EncodedSubjectLen",
				type   => "LENGTH"
			},
			{ number => "357", name => "EncodedSubject", type => "DATA" },
			{
				number => "358",
				name   => "EncodedHeadlineLen",
				type   => "LENGTH"
			},
			{ number => "359", name => "EncodedHeadline", type => "DATA" },
			{
				number => "360",
				name   => "EncodedAllocTextLen",
				type   => "LENGTH"
			},
			{ number => "361", name => "EncodedAllocText", type => "DATA" },
			{
				number => "362",
				name   => "EncodedUnderlyingIssuerLen",
				type   => "LENGTH"
			},
			{
				number => "363",
				name   => "EncodedUnderlyingIssuer",
				type   => "DATA"
			},
			{
				number => "364",
				name   => "EncodedUnderlyingSecurityDescLen",
				type   => "LENGTH"
			},
			{
				number => "365",
				name   => "EncodedUnderlyingSecurityDesc",
				type   => "DATA"
			},
			{ number => "366", name => "AllocPrice", type => "PRICE" },
			{
				number => "367",
				name   => "QuoteSetValidUntilTime",
				type   => "UTCTIMESTAMP"
			},
			{
				number => "368",
				name   => "QuoteEntryRejectReason",
				type   => "INT",
				enum   => [
					{ name => "1", description => "UNKNOWN_SYMBOL" },
					{ name => "2", description => "EXCHANGE_CLOSED" },
					{ name => "3", description => "QUOTE_EXCEEDS_LIMIT" },
					{ name => "4", description => "TOO_LATE_TO_ENTER" },
					{ name => "5", description => "UNKNOWN_QUOTE" },
					{ name => "6", description => "DUPLICATE_QUOTE" },
					{ name => "7", description => "INVALID_BID_ASK_SPREAD" },
					{ name => "8", description => "INVALID_PRICE" },
					{
						name        => "9",
						description => "NOT_AUTHORIZED_TO_QUOTE_SECURITY"
					},
				]
			},
			{
				number => "369",
				name   => "LastMsgSeqNumProcessed",
				type   => "SEQNUM"
			},
			{ number => "371", name => "RefTagID",   type => "INT" },
			{ number => "372", name => "RefMsgType", type => "STRING" },
			{
				number => "373",
				name   => "SessionRejectReason",
				type   => "INT",
				enum   => [
					{ name => "0", description => "INVALID_TAG_NUMBER" },
					{ name => "1", description => "REQUIRED_TAG_MISSING" },
					{
						name        => "2",
						description => "TAG_NOT_DEFINED_FOR_THIS_MESSAGE_TYPE"
					},
					{ name => "3", description => "UNDEFINED_TAG" },
					{
						name        => "4",
						description => "TAG_SPECIFIED_WITHOUT_A_VALUE"
					},
					{ name => "5", description => "VALUE_IS_INCORRECT" },
					{
						name        => "6",
						description => "INCORRECT_DATA_FORMAT_FOR_VALUE"
					},
					{ name => "7", description => "DECRYPTION_PROBLEM" },
					{ name => "8", description => "SIGNATURE_PROBLEM" },
					{ name => "9", description => "COMPID_PROBLEM" },
					{
						name        => "10",
						description => "SENDINGTIME_ACCURACY_PROBLEM"
					},
					{ name => "11", description => "INVALID_MSGTYPE" },
					{ name => "12", description => "XML_VALIDATION_ERROR" },
					{
						name        => "13",
						description => "TAG_APPEARS_MORE_THAN_ONCE"
					},
					{
						name        => "14",
						description => "TAG_SPECIFIED_OUT_OF_REQUIRED_ORDER"
					},
					{
						name        => "15",
						description => "REPEATING_GROUP_FIELDS_OUT_OF_ORDER"
					},
					{
						name => "16",
						description =>
						  "INCORRECT_NUMINGROUP_COUNT_FOR_REPEATING_GROUP"
					},
					{
						name => "17",
						description =>
						  "NON_DATA_VALUE_INCLUDES_FIELD_DELIMITER"
					},
					{ name => "99", description => "OTHER" },
				]
			},
			{
				number => "374",
				name   => "BidRequestTransType",
				type   => "CHAR",
				enum   => [
					{ name => "N", description => "NEW" },
					{ name => "C", description => "CANCEL" },
				]
			},
			{ number => "375", name => "ContraBroker",  type => "STRING" },
			{ number => "376", name => "ComplianceID",  type => "STRING" },
			{ number => "377", name => "SolicitedFlag", type => "BOOLEAN" },
			{
				number => "378",
				name   => "ExecRestatementReason",
				type   => "INT",
				enum   => [
					{ name => "0", description => "GT_CORPORATE_ACTION" },
					{ name => "1", description => "GT_RENEWAL_RESTATEMENT" },
					{ name => "2", description => "VERBAL_CHANGE" },
					{ name => "3", description => "REPRICING_OF_ORDER" },
					{ name => "4", description => "BROKER_OPTION" },
					{
						name        => "5",
						description => "PARTIAL_DECLINE_OF_ORDERQTY"
					},
					{ name => "6", description => "CANCEL_ON_TRADING_HALT" },
					{
						name        => "7",
						description => "CANCEL_ON_SYSTEM_FAILURE"
					},
					{ name => "8", description => "MARKET_OPTION" },
					{ name => "9", description => "CANCELED_NOT_BEST" },
				]
			},
			{
				number => "379",
				name   => "BusinessRejectRefID",
				type   => "STRING"
			},
			{
				number => "380",
				name   => "BusinessRejectReason",
				type   => "INT",
				enum   => [
					{ name => "0", description => "OTHER" },
					{ name => "1", description => "UNKOWN_ID" },
					{ name => "2", description => "UNKNOWN_SECURITY" },
					{
						name        => "3",
						description => "UNSUPPORTED_MESSAGE_TYPE"
					},
					{
						name        => "4",
						description => "APPLICATION_NOT_AVAILABLE"
					},
					{
						name        => "5",
						description => "CONDITIONALLY_REQUIRED_FIELD_MISSING"
					},
					{ name => "6", description => "NOT_AUTHORIZED" },
					{
						name => "7",
						description =>
						  "DELIVERTO_FIRM_NOT_AVAILABLE_AT_THIS_TIME"
					},
				]
			},
			{ number => "381", name => "GrossTradeAmt", type => "AMT" },
			{
				number => "382",
				name   => "NoContraBrokers",
				type   => "NUMINGROUP"
			},
			{ number => "383", name => "MaxMessageSize", type => "LENGTH" },
			{ number => "384", name => "NoMsgTypes", type => "NUMINGROUP" },
			{
				number => "385",
				name   => "MsgDirection",
				type   => "CHAR",
				enum   => [
					{ name => "S", description => "SEND" },
					{ name => "R", description => "RECEIVE" },
				]
			},
			{
				number => "386",
				name   => "NoTradingSessions",
				type   => "NUMINGROUP"
			},
			{ number => "387", name => "TotalVolumeTraded", type => "QTY" },
			{
				number => "388",
				name   => "DiscretionInst",
				type   => "CHAR",
				enum   => [
					{
						name        => "0",
						description => "RELATED_TO_DISPLAYED_PRICE"
					},
					{ name => "1", description => "RELATED_TO_MARKET_PRICE" },
					{
						name        => "2",
						description => "RELATED_TO_PRIMARY_PRICE"
					},
					{
						name        => "3",
						description => "RELATED_TO_LOCAL_PRIMARY_PRICE"
					},
					{
						name        => "4",
						description => "RELATED_TO_MIDPOINT_PRICE"
					},
					{
						name        => "5",
						description => "RELATED_TO_LAST_TRADE_PRICE"
					},
					{ name => "6", description => "RELATED_TO_VWAP" },
				]
			},
			{
				number => "389",
				name   => "DiscretionOffsetValue",
				type   => "FLOAT"
			},
			{ number => "390", name => "BidID",           type => "STRING" },
			{ number => "391", name => "ClientBidID",     type => "STRING" },
			{ number => "392", name => "ListName",        type => "STRING" },
			{ number => "393", name => "TotNoRelatedSym", type => "INT" },
			{
				number => "394",
				name   => "BidType",
				type   => "INT",
				enum   => [
					{ name => "1", description => "NON_DISCLOSED" },
					{ name => "2", description => "DISCLOSED_STYLE" },
					{ name => "3", description => "NO_BIDDING_PROCESS" },
				]
			},
			{ number => "395", name => "NumTickets", type => "INT" },
			{ number => "396", name => "SideValue1", type => "AMT" },
			{ number => "397", name => "SideValue2", type => "AMT" },
			{
				number => "398",
				name   => "NoBidDescriptors",
				type   => "NUMINGROUP"
			},
			{
				number => "399",
				name   => "BidDescriptorType",
				type   => "INT",
				enum   => [
					{ name => "1", description => "SECTOR" },
					{ name => "2", description => "COUNTRY" },
					{ name => "3", description => "INDEX" },
				]
			},
			{ number => "400", name => "BidDescriptor", type => "STRING" },
			{
				number => "401",
				name   => "SideValueInd",
				type   => "INT",
				enum   => [
					{ name => "1", description => "SIDEVALUE1" },
					{ name => "2", description => "SIDEVALUE2" },
				]
			},
			{
				number => "402",
				name   => "LiquidityPctLow",
				type   => "PERCENTAGE"
			},
			{
				number => "403",
				name   => "LiquidityPctHigh",
				type   => "PERCENTAGE"
			},
			{ number => "404", name => "LiquidityValue", type => "AMT" },
			{
				number => "405",
				name   => "EFPTrackingError",
				type   => "PERCENTAGE"
			},
			{ number => "406", name => "FairValue", type => "AMT" },
			{
				number => "407",
				name   => "OutsideIndexPct",
				type   => "PERCENTAGE"
			},
			{ number => "408", name => "ValueOfFutures", type => "AMT" },
			{
				number => "409",
				name   => "LiquidityIndType",
				type   => "INT",
				enum   => [
					{ name => "1", description => "FIVEDAY_MOVING_AVERAGE" },
					{
						name        => "2",
						description => "TWENTYDAY_MOVING_AVERAGE"
					},
					{ name => "3", description => "NORMAL_MARKET_SIZE" },
					{ name => "4", description => "OTHER" },
				]
			},
			{
				number => "410",
				name   => "WtAverageLiquidity",
				type   => "PERCENTAGE"
			},
			{
				number => "411",
				name   => "ExchangeForPhysical",
				type   => "BOOLEAN"
			},
			{ number => "412", name => "OutMainCntryUIndex", type => "AMT" },
			{ number => "413", name => "CrossPercent", type => "PERCENTAGE" },
			{
				number => "414",
				name   => "ProgRptReqs",
				type   => "INT",
				enum   => [
					{
						name => "1",
						description =>
"BUYSIDE_EXPLICITLY_REQUESTS_STATUS_USING_STATUSREQUEST"
					},
					{
						name => "2",
						description =>
"SELLSIDE_PERIODICALLY_SENDS_STATUS_USING_LISTSTATUS"
					},
					{
						name        => "3",
						description => "REAL_TIME_EXECUTION_REPORTS"
					},
				]
			},
			{ number => "415", name => "ProgPeriodInterval", type => "INT" },
			{
				number => "416",
				name   => "IncTaxInd",
				type   => "INT",
				enum   => [
					{ name => "1", description => "NET" },
					{ name => "2", description => "GROSS" },
				]
			},
			{ number => "417", name => "NumBidders", type => "INT" },
			{
				number => "418",
				name   => "BidTradeType",
				type   => "CHAR",
				enum   => [
					{ name => "R", description => "RISK_TRADE" },
					{ name => "G", description => "VWAP_GUARANTEE" },
					{ name => "A", description => "AGENCY" },
					{ name => "J", description => "GUARANTEED_CLOSE" },
				]
			},
			{
				number => "419",
				name   => "BasisPxType",
				type   => "CHAR",
				enum   => [
					{
						name        => "2",
						description => "CLOSING_PRICE_AT_MORNING_SESSION"
					},
					{ name => "3", description => "CLOSING_PRICE" },
					{ name => "4", description => "CURRENT_PRICE" },
					{ name => "5", description => "SQ" },
					{ name => "6", description => "VWAP_THROUGH_A_DAY" },
					{
						name        => "7",
						description => "VWAP_THROUGH_A_MORNING_SESSION"
					},
					{
						name        => "8",
						description => "VWAP_THROUGH_AN_AFTERNOON_SESSION"
					},
					{
						name        => "9",
						description => "VWAP_THROUGH_A_DAY_EXCEPT_YORI"
					},
					{
						name => "A",
						description =>
						  "VWAP_THROUGH_A_MORNING_SESSION_EXCEPT_YORI"
					},
					{
						name => "B",
						description =>
						  "VWAP_THROUGH_AN_AFTERNOON_SESSION_EXCEPT_YORI"
					},
					{ name => "C", description => "STRIKE" },
					{ name => "D", description => "OPEN" },
					{ name => "Z", description => "OTHERS" },
				]
			},
			{
				number => "420",
				name   => "NoBidComponents",
				type   => "NUMINGROUP"
			},
			{ number => "421", name => "Country",      type => "COUNTRY" },
			{ number => "422", name => "TotNoStrikes", type => "INT" },
			{
				number => "423",
				name   => "PriceType",
				type   => "INT",
				enum   => [
					{ name => "1", description => "PERCENTAGE" },
					{ name => "2", description => "PER_UNIT" },
					{ name => "3", description => "FIXED_AMOUNT" },
					{ name => "4", description => "DISCOUNT" },
					{ name => "5", description => "PREMIUM" },
					{ name => "6", description => "SPREAD" },
					{ name => "7", description => "TED_PRICE" },
					{ name => "8", description => "TED_YIELD" },
					{ name => "9", description => "YIELD" },
				]
			},
			{ number => "424", name => "DayOrderQty", type => "QTY" },
			{ number => "425", name => "DayCumQty",   type => "QTY" },
			{ number => "426", name => "DayAvgPx",    type => "PRICE" },
			{
				number => "427",
				name   => "GTBookingInst",
				type   => "INT",
				enum   => [
					{
						name => "0",
						description =>
						  "BOOK_OUT_ALL_TRADES_ON_DAY_OF_EXECUTION"
					},
					{
						name => "1",
						description =>
"ACCUMULATE_EXECUTIONS_UNTIL_ORDER_IS_FILLED_OR_EXPIRES"
					},
					{
						name => "2",
						description =>
						  "ACCUMULATE_UNTIL_VERBALLY_NOTIFIED_OTHERWISE"
					},
				]
			},
			{ number => "428", name => "NoStrikes", type => "NUMINGROUP" },
			{
				number => "429",
				name   => "ListStatusType",
				type   => "INT",
				enum   => [
					{ name => "1", description => "ACK" },
					{ name => "2", description => "RESPONSE" },
					{ name => "3", description => "TIMED" },
					{ name => "4", description => "EXECSTARTED" },
					{ name => "5", description => "ALLDONE" },
					{ name => "6", description => "ALERT" },
				]
			},
			{
				number => "430",
				name   => "NetGrossInd",
				type   => "INT",
				enum   => [
					{ name => "1", description => "NET" },
					{ name => "2", description => "GROSS" },
				]
			},
			{
				number => "431",
				name   => "ListOrderStatus",
				type   => "INT",
				enum   => [
					{ name => "1", description => "INBIDDINGPROCESS" },
					{ name => "2", description => "RECEIVEDFOREXECUTION" },
					{ name => "3", description => "EXECUTING" },
					{ name => "4", description => "CANCELING" },
					{ name => "5", description => "ALERT" },
					{ name => "6", description => "ALL_DONE" },
					{ name => "7", description => "REJECT" },
				]
			},
			{ number => "432", name => "ExpireDate", type => "LOCALMKTDATE" },
			{
				number => "433",
				name   => "ListExecInstType",
				type   => "CHAR",
				enum   => [
					{ name => "1", description => "IMMEDIATE" },
					{
						name        => "2",
						description => "WAIT_FOR_EXECUTE_INSTRUCTION"
					},
					{
						name        => "3",
						description => "EXCHANGE_SWITCH_CIV_ORDER_SELL_DRIVEN"
					},
					{
						name => "4",
						description =>
						  "EXCHANGE_SWITCH_CIV_ORDER_BUY_DRIVEN_CASH_TOP_UP"
					},
					{
						name => "5",
						description =>
						  "EXCHANGE_SWITCH_CIV_ORDER_BUY_DRIVEN_CASH_WITHDRAW"
					},
				]
			},
			{
				number => "434",
				name   => "CxlRejResponseTo",
				type   => "CHAR",
				enum   => [
					{ name => "1", description => "ORDER_CANCEL_REQUEST" },
					{
						name        => "2",
						description => "ORDER_CANCEL_REPLACE_REQUEST"
					},
				]
			},
			{
				number => "435",
				name   => "UnderlyingCouponRate",
				type   => "PERCENTAGE"
			},
			{
				number => "436",
				name   => "UnderlyingContractMultiplier",
				type   => "FLOAT"
			},
			{ number => "437", name => "ContraTradeQty", type => "QTY" },
			{
				number => "438",
				name   => "ContraTradeTime",
				type   => "UTCTIMESTAMP"
			},
			{
				number => "441",
				name   => "LiquidityNumSecurities",
				type   => "INT"
			},
			{
				number => "442",
				name   => "MultiLegReportingType",
				type   => "CHAR",
				enum   => [
					{ name => "1", description => "SINGLE_SECURITY" },
					{
						name => "2",
						description =>
						  "INDIVIDUAL_LEG_OF_A_MULTI_LEG_SECURITY"
					},
					{ name => "3", description => "MULTI_LEG_SECURITY" },
				]
			},
			{ number => "443", name => "StrikeTime", type => "UTCTIMESTAMP" },
			{ number => "444", name => "ListStatusText", type => "STRING" },
			{
				number => "445",
				name   => "EncodedListStatusTextLen",
				type   => "LENGTH"
			},
			{
				number => "446",
				name   => "EncodedListStatusText",
				type   => "DATA"
			},
			{
				number => "447",
				name   => "PartyIDSource",
				type   => "CHAR",
				enum   => [
					{ name => "B", description => "BIC" },
					{
						name => "C",
						description =>
						  "GENERALLY_ACCEPTED_MARKET_PARTICIPANT_IDENTIFIER"
					},
					{ name => "D", description => "PROPRIETARY_CUSTOM_CODE" },
					{ name => "E", description => "ISO_COUNTRY_CODE" },
					{
						name        => "F",
						description => "SETTLEMENT_ENTITY_LOCATION"
					},
					{ name => "G", description => "MIC" },
					{
						name        => "H",
						description => "CSD_PARTICIPANT_MEMBER_CODE"
					},
					{ name => "1", description => "KOREAN_INVESTOR_ID" },
					{
						name => "2",
						description =>
						  "TAIWANESE_QUALIFIED_FOREIGN_INVESTOR_ID_QFII_FID"
					},
					{
						name        => "3",
						description => "TAIWANESE_TRADING_ACCOUNT"
					},
					{
						name        => "4",
						description => "MALAYSIAN_CENTRAL_DEPOSITORY_NUMBER"
					},
					{ name => "5", description => "CHINESE_B_SHARE" },
					{
						name => "6",
						description =>
						  "UK_NATIONAL_INSURANCE_OR_PENSION_NUMBER"
					},
					{
						name        => "7",
						description => "US_SOCIAL_SECURITY_NUMBER"
					},
					{
						name        => "8",
						description => "US_EMPLOYER_IDENTIFICATION_NUMBER"
					},
					{
						name        => "9",
						description => "AUSTRALIAN_BUSINESS_NUMBER"
					},
					{
						name        => "A",
						description => "AUSTRALIAN_TAX_FILE_NUMBER"
					},
					{ name => "I", description => "DIRECTED_BROKER" },
				]
			},
			{ number => "448", name => "PartyID", type => "STRING" },
			{
				number => "451",
				name   => "NetChgPrevDay",
				type   => "PRICEOFFSET"
			},
			{
				number => "452",
				name   => "PartyRole",
				type   => "INT",
				enum   => [
					{ name => "1",  description => "EXECUTING_FIRM" },
					{ name => "2",  description => "BROKER_OF_CREDIT" },
					{ name => "3",  description => "CLIENT_ID" },
					{ name => "4",  description => "CLEARING_FIRM" },
					{ name => "5",  description => "INVESTOR_ID" },
					{ name => "6",  description => "INTRODUCING_FIRM" },
					{ name => "7",  description => "ENTERING_FIRM" },
					{ name => "8",  description => "LOCATE_LENDING_FIRM" },
					{ name => "9",  description => "FUND_MANAGER_CLIENT_ID" },
					{ name => "10", description => "SETTLEMENT_LOCATION" },
					{
						name        => "11",
						description => "ORDER_ORIGINATION_TRADER"
					},
					{ name => "12", description => "EXECUTING_TRADER" },
					{ name => "13", description => "ORDER_ORIGINATION_FIRM" },
					{ name => "14", description => "GIVEUP_CLEARING_FIRM" },
					{
						name        => "15",
						description => "CORRESPONDANT_CLEARING_FIRM"
					},
					{ name => "16", description => "EXECUTING_SYSTEM" },
					{ name => "17", description => "CONTRA_FIRM" },
					{ name => "18", description => "CONTRA_CLEARING_FIRM" },
					{ name => "19", description => "SPONSORING_FIRM" },
					{ name => "20", description => "UNDERLYING_CONTRA_FIRM" },
					{ name => "21", description => "CLEARING_ORGANIZATION" },
					{ name => "22", description => "EXCHANGE" },
					{ name => "24", description => "CUSTOMER_ACCOUNT" },
					{
						name        => "25",
						description => "CORRESPONDENT_CLEARING_ORGANIZATION"
					},
					{ name => "26", description => "CORRESPONDENT_BROKER" },
					{ name => "27", description => "BUYER_SELLER" },
					{ name => "28", description => "CUSTODIAN" },
					{ name => "29", description => "INTERMEDIARY" },
					{ name => "30", description => "AGENT" },
					{ name => "31", description => "SUB_CUSTODIAN" },
					{ name => "32", description => "BENEFICIARY" },
					{ name => "33", description => "INTERESTED_PARTY" },
					{ name => "34", description => "REGULATORY_BODY" },
					{ name => "35", description => "LIQUIDITY_PROVIDER" },
					{ name => "36", description => "ENTERING_TRADER" },
					{ name => "37", description => "CONTRA_TRADER" },
					{ name => "38", description => "POSITION_ACCOUNT" },
				]
			},
			{ number => "453", name => "NoPartyIDs", type => "NUMINGROUP" },
			{
				number => "454",
				name   => "NoSecurityAltID",
				type   => "NUMINGROUP"
			},
			{ number => "455", name => "SecurityAltID", type => "STRING" },
			{
				number => "456",
				name   => "SecurityAltIDSource",
				type   => "STRING"
			},
			{
				number => "457",
				name   => "NoUnderlyingSecurityAltID",
				type   => "NUMINGROUP"
			},
			{
				number => "458",
				name   => "UnderlyingSecurityAltID",
				type   => "STRING"
			},
			{
				number => "459",
				name   => "UnderlyingSecurityAltIDSource",
				type   => "STRING"
			},
			{
				number => "460",
				name   => "Product",
				type   => "INT",
				enum   => [
					{ name => "1",  description => "AGENCY" },
					{ name => "2",  description => "COMMODITY" },
					{ name => "3",  description => "CORPORATE" },
					{ name => "4",  description => "CURRENCY" },
					{ name => "5",  description => "EQUITY" },
					{ name => "6",  description => "GOVERNMENT" },
					{ name => "7",  description => "INDEX" },
					{ name => "8",  description => "LOAN" },
					{ name => "9",  description => "MONEYMARKET" },
					{ name => "10", description => "MORTGAGE" },
					{ name => "11", description => "MUNICIPAL" },
					{ name => "12", description => "OTHER" },
					{ name => "13", description => "FINANCING" },
				]
			},
			{ number => "461", name => "CFICode", type => "STRING" },
			{ number => "462", name => "UnderlyingProduct", type => "INT" },
			{
				number => "463",
				name   => "UnderlyingCFICode",
				type   => "STRING"
			},
			{
				number => "464",
				name   => "TestMessageIndicator",
				type   => "BOOLEAN"
			},
			{
				number => "465",
				name   => "QuantityType",
				type   => "INT",
				enum   => [
					{ name => "1", description => "SHARES" },
					{ name => "2", description => "BONDS" },
					{ name => "3", description => "CURRENTFACE" },
					{ name => "4", description => "ORIGINALFACE" },
					{ name => "5", description => "CURRENCY" },
					{ name => "6", description => "CONTRACTS" },
					{ name => "7", description => "OTHER" },
					{ name => "8", description => "PAR" },
				]
			},
			{ number => "466", name => "BookingRefID", type => "STRING" },
			{
				number => "467",
				name   => "IndividualAllocID",
				type   => "STRING"
			},
			{
				number => "468",
				name   => "RoundingDirection",
				type   => "CHAR",
				enum   => [
					{ name => "0", description => "ROUND_TO_NEAREST" },
					{ name => "1", description => "ROUND_DOWN" },
					{ name => "2", description => "ROUND_UP" },
				]
			},
			{ number => "469", name => "RoundingModulus", type => "FLOAT" },
			{ number => "470", name => "CountryOfIssue",  type => "COUNTRY" },
			{
				number => "471",
				name   => "StateOrProvinceOfIssue",
				type   => "STRING"
			},
			{ number => "472", name => "LocaleOfIssue", type => "STRING" },
			{ number => "473", name => "NoRegistDtls", type => "NUMINGROUP" },
			{ number => "474", name => "MailingDtls",  type => "STRING" },
			{
				number => "475",
				name   => "InvestorCountryOfResidence",
				type   => "COUNTRY"
			},
			{ number => "476", name => "PaymentRef", type => "STRING" },
			{
				number => "477",
				name   => "DistribPaymentMethod",
				type   => "INT",
				enum   => [
					{ name => "1", description => "CREST" },
					{ name => "2", description => "NSCC" },
					{ name => "3", description => "EUROCLEAR" },
					{ name => "4", description => "CLEARSTREAM" },
					{ name => "5", description => "CHEQUE" },
					{ name => "6", description => "TELEGRAPHIC_TRANSFER" },
					{ name => "7", description => "FEDWIRE" },
					{ name => "8", description => "DIRECT_CREDIT" },
					{ name => "9", description => "ACH_CREDIT" },
				]
			},
			{
				number => "478",
				name   => "CashDistribCurr",
				type   => "CURRENCY"
			},
			{ number => "479", name => "CommCurrency", type => "CURRENCY" },
			{
				number => "480",
				name   => "CancellationRights",
				type   => "CHAR",
				enum   => [
					{ name => "N", description => "NO_EXECUTION_ONLY" },
					{ name => "M", description => "NO_WAIVER_AGREEMENT" },
					{ name => "O", description => "NO_INSTITUTIONAL" },
				]
			},
			{
				number => "481",
				name   => "MoneyLaunderingStatus",
				type   => "CHAR",
				enum   => [
					{ name => "Y", description => "PASSED" },
					{ name => "N", description => "NOT_CHECKED" },
					{ name => "1", description => "EXEMPT_BELOW_THE_LIMIT" },
					{
						name        => "2",
						description => "EXEMPT_CLIENT_MONEY_TYPE_EXEMPTION"
					},
					{
						name => "3",
						description =>
						  "EXEMPT_AUTHORISED_CREDIT_OR_FINANCIAL_INSTITUTION"
					},
				]
			},
			{ number => "482", name => "MailingInst", type => "STRING" },
			{
				number => "483",
				name   => "TransBkdTime",
				type   => "UTCTIMESTAMP"
			},
			{
				number => "484",
				name   => "ExecPriceType",
				type   => "CHAR",
				enum   => [
					{ name => "B", description => "BID_PRICE" },
					{ name => "C", description => "CREATION_PRICE" },
					{
						name => "D",
						description =>
						  "CREATION_PRICE_PLUS_ADJUSTMENT_PERCENT"
					},
					{
						name        => "E",
						description => "CREATION_PRICE_PLUS_ADJUSTMENT_AMOUNT"
					},
					{ name => "O", description => "OFFER_PRICE" },
					{
						name        => "P",
						description => "OFFER_PRICE_MINUS_ADJUSTMENT_PERCENT"
					},
					{
						name        => "Q",
						description => "OFFER_PRICE_MINUS_ADJUSTMENT_AMOUNT"
					},
					{ name => "S", description => "SINGLE_PRICE" },
				]
			},
			{
				number => "485",
				name   => "ExecPriceAdjustment",
				type   => "FLOAT"
			},
			{
				number => "486",
				name   => "DateOfBirth",
				type   => "LOCALMKTDATE"
			},
			{
				number => "487",
				name   => "TradeReportTransType",
				type   => "INT",
				enum   => [
					{ name => "0", description => "NEW" },
					{ name => "1", description => "CANCEL" },
					{ name => "2", description => "REPLACE" },
					{ name => "3", description => "RELEASE" },
					{ name => "4", description => "REVERSE" },
				]
			},
			{ number => "488", name => "CardHolderName", type => "STRING" },
			{ number => "489", name => "CardNumber",     type => "STRING" },
			{
				number => "490",
				name   => "CardExpDate",
				type   => "LOCALMKTDATE"
			},
			{ number => "491", name => "CardIssNum", type => "STRING" },
			{
				number => "492",
				name   => "PaymentMethod",
				type   => "INT",
				enum   => [
					{ name => "1", description => "CREST" },
					{ name => "2", description => "NSCC" },
					{ name => "3", description => "EUROCLEAR" },
					{ name => "4", description => "CLEARSTREAM" },
					{ name => "5", description => "CHEQUE" },
					{ name => "6", description => "TELEGRAPHIC_TRANSFER" },
					{ name => "7", description => "FEDWIRE" },
					{ name => "8", description => "DEBIT_CARD" },
					{ name => "9", description => "DIRECT_DEBIT" },
				]
			},
			{ number => "493", name => "RegistAcctType", type => "STRING" },
			{ number => "494", name => "Designation",    type => "STRING" },
			{
				number => "495",
				name   => "TaxAdvantageType",
				type   => "INT",
				enum   => [
					{ name => "0", description => "NONE" },
					{ name => "1", description => "MAXI_ISA" },
					{ name => "2", description => "TESSA" },
					{ name => "3", description => "MINI_CASH_ISA" },
					{
						name        => "4",
						description => "MINI_STOCKS_AND_SHARES_ISA"
					},
					{ name => "5",   description => "MINI_INSURANCE_ISA" },
					{ name => "6",   description => "CURRENT_YEAR_PAYMENT" },
					{ name => "7",   description => "PRIOR_YEAR_PAYMENT" },
					{ name => "8",   description => "ASSET_TRANSFER" },
					{ name => "9",   description => "EMPLOYEE_PRIOR_YEAR" },
					{ name => "999", description => "OTHER" },
				]
			},
			{
				number => "496",
				name   => "RegistRejReasonText",
				type   => "STRING"
			},
			{
				number => "497",
				name   => "FundRenewWaiv",
				type   => "CHAR",
				enum   => [
					{ name => "Y", description => "YES" },
					{ name => "N", description => "NO" },
				]
			},
			{
				number => "498",
				name   => "CashDistribAgentName",
				type   => "STRING"
			},
			{
				number => "499",
				name   => "CashDistribAgentCode",
				type   => "STRING"
			},
			{
				number => "500",
				name   => "CashDistribAgentAcctNumber",
				type   => "STRING"
			},
			{
				number => "501",
				name   => "CashDistribPayRef",
				type   => "STRING"
			},
			{
				number => "502",
				name   => "CashDistribAgentAcctName",
				type   => "STRING"
			},
			{
				number => "503",
				name   => "CardStartDate",
				type   => "LOCALMKTDATE"
			},
			{
				number => "504",
				name   => "PaymentDate",
				type   => "LOCALMKTDATE"
			},
			{
				number => "505",
				name   => "PaymentRemitterID",
				type   => "STRING"
			},
			{
				number => "506",
				name   => "RegistStatus",
				type   => "CHAR",
				enum   => [
					{ name => "A", description => "ACCEPTED" },
					{ name => "R", description => "REJECTED" },
					{ name => "H", description => "HELD" },
					{ name => "N", description => "REMINDER" },
				]
			},
			{
				number => "507",
				name   => "RegistRejReasonCode",
				type   => "INT",
				enum   => [
					{
						name        => "1",
						description => "INVALID_UNACCEPTABLE_ACCOUNT_TYPE"
					},
					{
						name        => "2",
						description => "INVALID_UNACCEPTABLE_TAX_EXEMPT_TYPE"
					},
					{
						name        => "3",
						description => "INVALID_UNACCEPTABLE_OWNERSHIP_TYPE"
					},
					{
						name        => "4",
						description => "INVALID_UNACCEPTABLE_NO_REG_DETLS"
					},
					{
						name        => "5",
						description => "INVALID_UNACCEPTABLE_REG_SEQ_NO"
					},
					{
						name        => "6",
						description => "INVALID_UNACCEPTABLE_REG_DTLS"
					},
					{
						name        => "7",
						description => "INVALID_UNACCEPTABLE_MAILING_DTLS"
					},
					{
						name        => "8",
						description => "INVALID_UNACCEPTABLE_MAILING_INST"
					},
					{
						name        => "9",
						description => "INVALID_UNACCEPTABLE_INVESTOR_ID"
					},
					{
						name => "10",
						description =>
						  "INVALID_UNACCEPTABLE_INVESTOR_ID_SOURCE"
					},
					{
						name        => "11",
						description => "INVALID_UNACCEPTABLE_DATE_OF_BIRTH"
					},
					{
						name => "12",
						description =>
						  "INVALID_UNACCEPTABLE_INVESTOR_COUNTRY_OF_RESIDENCE"
					},
					{
						name        => "13",
						description => "INVALID_UNACCEPTABLE_NODISTRIBINSTNS"
					},
					{
						name => "14",
						description =>
						  "INVALID_UNACCEPTABLE_DISTRIB_PERCENTAGE"
					},
					{
						name => "15",
						description =>
						  "INVALID_UNACCEPTABLE_DISTRIB_PAYMENT_METHOD"
					},
					{
						name => "16",
						description =>
						  "INVALID_UNACCEPTABLE_CASH_DISTRIB_AGENT_ACCT_NAME"
					},
					{
						name => "17",
						description =>
						  "INVALID_UNACCEPTABLE_CASH_DISTRIB_AGENT_CODE"
					},
					{
						name => "18",
						description =>
						  "INVALID_UNACCEPTABLE_CASH_DISTRIB_AGENT_ACCT_NUM"
					},
					{ name => "99", description => "OTHER" },
				]
			},
			{ number => "508", name => "RegistRefID", type => "STRING" },
			{ number => "509", name => "RegistDtls",  type => "STRING" },
			{
				number => "510",
				name   => "NoDistribInsts",
				type   => "NUMINGROUP"
			},
			{ number => "511", name => "RegistEmail", type => "STRING" },
			{
				number => "512",
				name   => "DistribPercentage",
				type   => "PERCENTAGE"
			},
			{ number => "513", name => "RegistID", type => "STRING" },
			{
				number => "514",
				name   => "RegistTransType",
				type   => "CHAR",
				enum   => [
					{ name => "0", description => "NEW" },
					{ name => "1", description => "REPLACE" },
					{ name => "2", description => "CANCEL" },
				]
			},
			{
				number => "515",
				name   => "ExecValuationPoint",
				type   => "UTCTIMESTAMP"
			},
			{ number => "516", name => "OrderPercent", type => "PERCENTAGE" },
			{
				number => "517",
				name   => "OwnershipType",
				type   => "CHAR",
				enum   => [
					{ name => "J", description => "JOINT_INVESTORS" },
					{ name => "T", description => "TENANTS_IN_COMMON" },
					{ name => "2", description => "JOINT_TRUSTEES" },
				]
			},
			{ number => "518", name => "NoContAmts", type => "NUMINGROUP" },
			{
				number => "519",
				name   => "ContAmtType",
				type   => "INT",
				enum   => [
					{ name => "1", description => "COMMISSION_AMOUNT" },
					{ name => "2", description => "COMMISSION_PERCENT" },
					{ name => "3", description => "INITIAL_CHARGE_AMOUNT" },
					{ name => "4", description => "INITIAL_CHARGE_PERCENT" },
					{ name => "5", description => "DISCOUNT_AMOUNT" },
					{ name => "6", description => "DISCOUNT_PERCENT" },
					{ name => "7", description => "DILUTION_LEVY_AMOUNT" },
					{ name => "8", description => "DILUTION_LEVY_PERCENT" },
					{ name => "9", description => "EXIT_CHARGE_AMOUNT" },
				]
			},
			{ number => "520", name => "ContAmtValue", type => "FLOAT" },
			{ number => "521", name => "ContAmtCurr",  type => "CURRENCY" },
			{
				number => "522",
				name   => "OwnerType",
				type   => "INT",
				enum   => [
					{ name => "1", description => "INDIVIDUAL_INVESTOR" },
					{ name => "2", description => "PUBLIC_COMPANY" },
					{ name => "3", description => "PRIVATE_COMPANY" },
					{ name => "4", description => "INDIVIDUAL_TRUSTEE" },
					{ name => "5", description => "COMPANY_TRUSTEE" },
					{ name => "6", description => "PENSION_PLAN" },
					{
						name        => "7",
						description => "CUSTODIAN_UNDER_GIFTS_TO_MINORS_ACT"
					},
					{ name => "8", description => "TRUSTS" },
					{ name => "9", description => "FIDUCIARIES" },
				]
			},
			{ number => "523", name => "PartySubID",    type => "STRING" },
			{ number => "524", name => "NestedPartyID", type => "STRING" },
			{
				number => "525",
				name   => "NestedPartyIDSource",
				type   => "CHAR"
			},
			{ number => "526", name => "SecondaryClOrdID", type => "STRING" },
			{ number => "527", name => "SecondaryExecID",  type => "STRING" },
			{
				number => "528",
				name   => "OrderCapacity",
				type   => "CHAR",
				enum   => [
					{ name => "A", description => "AGENCY" },
					{ name => "G", description => "PROPRIETARY" },
					{ name => "I", description => "INDIVIDUAL" },
					{ name => "P", description => "PRINCIPAL" },
					{ name => "R", description => "RISKLESS_PRINCIPAL" },
					{ name => "W", description => "AGENT_FOR_OTHER_MEMBER" },
				]
			},
			{
				number => "529",
				name   => "OrderRestrictions",
				type   => "MULTIPLEVALUESTRING",
				enum   => [
					{ name => "1", description => "PROGRAM_TRADE" },
					{ name => "2", description => "INDEX_ARBITRAGE" },
					{ name => "3", description => "NON_INDEX_ARBITRAGE" },
					{ name => "4", description => "COMPETING_MARKET_MAKER" },
					{
						name => "5",
						description =>
"ACTING_AS_MARKET_MAKER_OR_SPECIALIST_IN_THE_SECURITY"
					},
					{
						name => "6",
						description =>
"ACTING_AS_MARKET_MAKER_OR_SPECIALIST_IN_THE_UNDERLYING_SECURITY_OF_A_DERIVATIVE_SECURITY"
					},
					{ name => "7", description => "FOREIGN_ENTITY" },
					{
						name        => "8",
						description => "EXTERNAL_MARKET_PARTICIPANT"
					},
					{
						name => "9",
						description =>
						  "EXTERNAL_INTER_CONNECTED_MARKET_LINKAGE"
					},
					{ name => "A", description => "RISKLESS_ARBITRAGE" },
				]
			},
			{
				number => "530",
				name   => "MassCancelRequestType",
				type   => "CHAR",
				enum   => [
					{
						name        => "1",
						description => "CANCEL_ORDERS_FOR_A_SECURITY"
					},
					{
						name => "2",
						description =>
						  "CANCEL_ORDERS_FOR_AN_UNDERLYING_SECURITY"
					},
					{
						name        => "3",
						description => "CANCEL_ORDERS_FOR_A_PRODUCT"
					},
					{
						name        => "4",
						description => "CANCEL_ORDERS_FOR_A_CFICODE"
					},
					{
						name        => "5",
						description => "CANCEL_ORDERS_FOR_A_SECURITYTYPE"
					},
					{
						name        => "6",
						description => "CANCEL_ORDERS_FOR_A_TRADING_SESSION"
					},
					{ name => "7", description => "CANCEL_ALL_ORDERS" },
				]
			},
			{
				number => "531",
				name   => "MassCancelResponse",
				type   => "CHAR",
				enum   => [
					{ name => "0", description => "CANCEL_REQUEST_REJECTED" },
					{
						name        => "1",
						description => "CANCEL_ORDERS_FOR_A_SECURITY"
					},
					{
						name => "2",
						description =>
						  "CANCEL_ORDERS_FOR_AN_UNDERLYING_SECURITY"
					},
					{
						name        => "3",
						description => "CANCEL_ORDERS_FOR_A_PRODUCT"
					},
					{
						name        => "4",
						description => "CANCEL_ORDERS_FOR_A_CFICODE"
					},
					{
						name        => "5",
						description => "CANCEL_ORDERS_FOR_A_SECURITYTYPE"
					},
					{
						name        => "6",
						description => "CANCEL_ORDERS_FOR_A_TRADING_SESSION"
					},
					{ name => "7", description => "CANCEL_ALL_ORDERS" },
				]
			},
			{
				number => "532",
				name   => "MassCancelRejectReason",
				type   => "CHAR",
				enum   => [
					{
						name        => "0",
						description => "MASS_CANCEL_NOT_SUPPORTED"
					},
					{
						name        => "1",
						description => "INVALID_OR_UNKNOWN_SECURITY"
					},
					{
						name        => "2",
						description => "INVALID_OR_UNKNOWN_UNDERLYING"
					},
					{
						name        => "3",
						description => "INVALID_OR_UNKNOWN_PRODUCT"
					},
					{
						name        => "4",
						description => "INVALID_OR_UNKNOWN_CFICODE"
					},
					{
						name        => "5",
						description => "INVALID_OR_UNKNOWN_SECURITY_TYPE"
					},
					{
						name        => "6",
						description => "INVALID_OR_UNKNOWN_TRADING_SESSION"
					},
				]
			},
			{ number => "533", name => "TotalAffectedOrders", type => "INT" },
			{ number => "534", name => "NoAffectedOrders",    type => "INT" },
			{ number => "535", name => "AffectedOrderID", type => "STRING" },
			{
				number => "536",
				name   => "AffectedSecondaryOrderID",
				type   => "STRING"
			},
			{
				number => "537",
				name   => "QuoteType",
				type   => "INT",
				enum   => [
					{ name => "0", description => "INDICATIVE" },
					{ name => "1", description => "TRADEABLE" },
					{ name => "2", description => "RESTRICTED_TRADEABLE" },
					{ name => "3", description => "COUNTER" },
				]
			},
			{ number => "538", name => "NestedPartyRole", type => "INT" },
			{
				number => "539",
				name   => "NoNestedPartyIDs",
				type   => "NUMINGROUP"
			},
			{
				number => "540",
				name   => "TotalAccruedInterestAmt",
				type   => "AMT"
			},
			{
				number => "541",
				name   => "MaturityDate",
				type   => "LOCALMKTDATE"
			},
			{
				number => "542",
				name   => "UnderlyingMaturityDate",
				type   => "LOCALMKTDATE"
			},
			{ number => "543", name => "InstrRegistry", type => "STRING" },
			{
				number => "544",
				name   => "CashMargin",
				type   => "CHAR",
				enum   => [
					{ name => "1", description => "CASH" },
					{ name => "2", description => "MARGIN_OPEN" },
					{ name => "3", description => "MARGIN_CLOSE" },
				]
			},
			{ number => "545", name => "NestedPartySubID", type => "STRING" },
			{
				number => "546",
				name   => "Scope",
				type   => "MULTIPLEVALUESTRING",
				enum   => [
					{ name => "1", description => "LOCAL" },
					{ name => "2", description => "NATIONAL" },
					{ name => "3", description => "GLOBAL" },
				]
			},
			{
				number => "547",
				name   => "MDImplicitDelete",
				type   => "BOOLEAN"
			},
			{ number => "548", name => "CrossID", type => "STRING" },
			{
				number => "549",
				name   => "CrossType",
				type   => "INT",
				enum   => [
					{
						name => "1",
						description =>
						  "CROSS_TRADE_WHICH_IS_EXECUTED_COMPLETELY_OR_NOT"
					},
					{
						name => "2",
						description =>
"CROSS_TRADE_WHICH_IS_EXECUTED_PARTIALLY_AND_THE_REST_IS_CANCELLED"
					},
					{
						name => "3",
						description =>
"CROSS_TRADE_WHICH_IS_PARTIALLY_EXECUTED_WITH_THE_UNFILLED_PORTIONS_REMAINING_ACTIVE"
					},
					{
						name => "4",
						description =>
"CROSS_TRADE_IS_EXECUTED_WITH_EXISTING_ORDERS_WITH_THE_SAME_PRICE"
					},
				]
			},
			{
				number => "550",
				name   => "CrossPrioritization",
				type   => "INT",
				enum   => [
					{ name => "0", description => "NONE" },
					{ name => "1", description => "BUY_SIDE_IS_PRIORITIZED" },
					{
						name        => "2",
						description => "SELL_SIDE_IS_PRIORITIZED"
					},
				]
			},
			{ number => "551", name => "OrigCrossID", type => "STRING" },
			{
				number => "552",
				name   => "NoSides",
				type   => "NUMINGROUP",
				enum   => [
					{ name => "1", description => "ONE_SIDE" },
					{ name => "2", description => "BOTH_SIDES" },
				]
			},
			{ number => "553", name => "Username",    type => "STRING" },
			{ number => "554", name => "Password",    type => "STRING" },
			{ number => "555", name => "NoLegs",      type => "NUMINGROUP" },
			{ number => "556", name => "LegCurrency", type => "CURRENCY" },
			{ number => "557", name => "TotNoSecurityTypes", type => "INT" },
			{
				number => "558",
				name   => "NoSecurityTypes",
				type   => "NUMINGROUP"
			},
			{
				number => "559",
				name   => "SecurityListRequestType",
				type   => "INT",
				enum   => [
					{ name => "0", description => "SYMBOL" },
					{
						name        => "1",
						description => "SECURITYTYPE_AND_OR_CFICODE"
					},
					{ name => "2", description => "PRODUCT" },
					{ name => "3", description => "TRADINGSESSIONID" },
					{ name => "4", description => "ALL_SECURITIES" },
				]
			},
			{
				number => "560",
				name   => "SecurityRequestResult",
				type   => "INT",
				enum   => [
					{ name => "0", description => "VALID_REQUEST" },
					{
						name        => "1",
						description => "INVALID_OR_UNSUPPORTED_REQUEST"
					},
					{
						name => "2",
						description =>
						  "NO_INSTRUMENTS_FOUND_THAT_MATCH_SELECTION_CRITERIA"
					},
					{
						name => "3",
						description =>
						  "NOT_AUTHORIZED_TO_RETRIEVE_INSTRUMENT_DATA"
					},
					{
						name => "4",
						description =>
						  "INSTRUMENT_DATA_TEMPORARILY_UNAVAILABLE"
					},
					{
						name => "5",
						description =>
						  "REQUEST_FOR_INSTRUMENT_DATA_NOT_SUPPORTED"
					},
				]
			},
			{ number => "561", name => "RoundLot",    type => "QTY" },
			{ number => "562", name => "MinTradeVol", type => "QTY" },
			{
				number => "563",
				name   => "MultiLegRptTypeReq",
				type   => "INT",
				enum   => [
					{
						name        => "0",
						description => "REPORT_BY_MULITLEG_SECURITY_ONLY"
					},
					{
						name => "1",
						description =>
"REPORT_BY_MULTILEG_SECURITY_AND_BY_INSTRUMENT_LEGS_BELONGING_TO_THE_MULTILEG_SECURITY"
					},
					{
						name => "2",
						description =>
"REPORT_BY_INSTRUMENT_LEGS_BELONGING_TO_THE_MULTILEG_SECURITY_ONLY"
					},
				]
			},
			{ number => "564", name => "LegPositionEffect", type => "CHAR" },
			{
				number => "565",
				name   => "LegCoveredOrUncovered",
				type   => "INT"
			},
			{ number => "566", name => "LegPrice", type => "PRICE" },
			{
				number => "567",
				name   => "TradSesStatusRejReason",
				type   => "INT",
				enum   => [
					{
						name        => "1",
						description => "UNKNOWN_OR_INVALID_TRADINGSESSIONID"
					},
				]
			},
			{ number => "568", name => "TradeRequestID", type => "STRING" },
			{
				number => "569",
				name   => "TradeRequestType",
				type   => "INT",
				enum   => [
					{ name => "0", description => "ALL_TRADES" },
					{
						name => "1",
						description =>
"MATCHED_TRADES_MATCHING_CRITERIA_PROVIDED_ON_REQUEST"
					},
					{
						name        => "2",
						description => "UNMATCHED_TRADES_THAT_MATCH_CRITERIA"
					},
					{
						name        => "3",
						description => "UNREPORTED_TRADES_THAT_MATCH_CRITERIA"
					},
					{
						name        => "4",
						description => "ADVISORIES_THAT_MATCH_CRITERIA"
					},
				]
			},
			{
				number => "570",
				name   => "PreviouslyReported",
				type   => "BOOLEAN"
			},
			{ number => "571", name => "TradeReportID",    type => "STRING" },
			{ number => "572", name => "TradeReportRefID", type => "STRING" },
			{
				number => "573",
				name   => "MatchStatus",
				type   => "CHAR",
				enum   => [
					{
						name        => "0",
						description => "COMPARED_MATCHED_OR_AFFIRMED"
					},
					{
						name        => "1",
						description => "UNCOMPARED_UNMATCHED_OR_UNAFFIRMED"
					},
					{ name => "2", description => "ADVISORY_OR_ALERT" },
				]
			},
			{ number => "574", name => "MatchType", type => "STRING" },
			{ number => "575", name => "OddLot",    type => "BOOLEAN" },
			{
				number => "576",
				name   => "NoClearingInstructions",
				type   => "INT"
			},
			{
				number => "577",
				name   => "ClearingInstruction",
				type   => "INT",
				enum   => [
					{ name => "0", description => "PROCESS_NORMALLY" },
					{
						name        => "1",
						description => "EXCLUDE_FROM_ALL_NETTING"
					},
					{ name => "2", description => "BILATERAL_NETTING_ONLY" },
					{ name => "3", description => "EX_CLEARING" },
					{ name => "4", description => "SPECIAL_TRADE" },
					{ name => "5", description => "MULTILATERAL_NETTING" },
					{
						name        => "6",
						description => "CLEAR_AGAINST_CENTRAL_COUNTERPARTY"
					},
					{
						name        => "7",
						description => "EXCLUDE_FROM_CENTRAL_COUNTERPARTY"
					},
					{ name => "8", description => "MANUAL_MODE" },
					{ name => "9", description => "AUTOMATIC_POSTING_MODE" },
				]
			},
			{ number => "578", name => "TradeInputSource", type => "STRING" },
			{ number => "579", name => "TradeInputDevice", type => "STRING" },
			{ number => "580", name => "NoDates",          type => "INT" },
			{
				number => "581",
				name   => "AccountType",
				type   => "INT",
				enum   => [
					{
						name => "1",
						description =>
						  "ACCOUNT_IS_CARRIED_ON_CUSTOMER_SIDE_OF_BOOKS"
					},
					{
						name => "2",
						description =>
						  "ACCOUNT_IS_CARRIED_ON_NON_CUSTOMER_SIDE_OF_BOOKS"
					},
					{ name => "3", description => "HOUSE_TRADER" },
					{ name => "4", description => "FLOOR_TRADER" },
					{
						name => "6",
						description =>
"ACCOUNT_IS_CARRIED_ON_NON_CUSTOMER_SIDE_OF_BOOKS_AND_IS_CROSS_MARGINED"
					},
					{
						name => "7",
						description =>
						  "ACCOUNT_IS_HOUSE_TRADER_AND_IS_CROSS_MARGINED"
					},
					{
						name        => "8",
						description => "JOINT_BACKOFFICE_ACCOUNT"
					},
				]
			},
			{
				number => "582",
				name   => "CustOrderCapacity",
				type   => "INT",
				enum   => [
					{
						name        => "1",
						description => "MEMBER_TRADING_FOR_THEIR_OWN_ACCOUNT"
					},
					{
						name => "2",
						description =>
						  "CLEARING_FIRM_TRADING_FOR_ITS_PROPRIETARY_ACCOUNT"
					},
					{
						name        => "3",
						description => "MEMBER_TRADING_FOR_ANOTHER_MEMBER"
					},
					{ name => "4", description => "ALL_OTHER" },
				]
			},
			{ number => "583", name => "ClOrdLinkID",     type => "STRING" },
			{ number => "584", name => "MassStatusReqID", type => "STRING" },
			{
				number => "585",
				name   => "MassStatusReqType",
				type   => "INT",
				enum   => [
					{
						name        => "1",
						description => "STATUS_FOR_ORDERS_FOR_A_SECURITY"
					},
					{
						name => "2",
						description =>
						  "STATUS_FOR_ORDERS_FOR_AN_UNDERLYING_SECURITY"
					},
					{
						name        => "3",
						description => "STATUS_FOR_ORDERS_FOR_A_PRODUCT"
					},
					{
						name        => "4",
						description => "STATUS_FOR_ORDERS_FOR_A_CFICODE"
					},
					{
						name        => "5",
						description => "STATUS_FOR_ORDERS_FOR_A_SECURITYTYPE"
					},
					{
						name => "6",
						description =>
						  "STATUS_FOR_ORDERS_FOR_A_TRADING_SESSION"
					},
					{ name => "7", description => "STATUS_FOR_ALL_ORDERS" },
					{
						name        => "8",
						description => "STATUS_FOR_ORDERS_FOR_A_PARTYID"
					},
				]
			},
			{
				number => "586",
				name   => "OrigOrdModTime",
				type   => "UTCTIMESTAMP"
			},
			{ number => "587", name => "LegSettlType", type => "CHAR" },
			{
				number => "588",
				name   => "LegSettlDate",
				type   => "LOCALMKTDATE"
			},
			{
				number => "589",
				name   => "DayBookingInst",
				type   => "CHAR",
				enum   => [
					{
						name => "0",
						description =>
"CAN_TRIGGER_BOOKING_WITHOUT_REFERENCE_TO_THE_ORDER_INITIATOR"
					},
					{
						name => "1",
						description =>
						  "SPEAK_WITH_ORDER_INITIATOR_BEFORE_BOOKING"
					},
					{ name => "2", description => "ACCUMULATE" },
				]
			},
			{
				number => "590",
				name   => "BookingUnit",
				type   => "CHAR",
				enum   => [
					{
						name => "0",
						description =>
						  "EACH_PARTIAL_EXECUTION_IS_A_BOOKABLE_UNIT"
					},
					{
						name => "1",
						description =>
"AGGREGATE_PARTIAL_EXECUTIONS_ON_THIS_ORDER_AND_BOOK_ONE_TRADE_PER_ORDER"
					},
					{
						name => "2",
						description =>
"AGGREGATE_EXECUTIONS_FOR_THIS_SYMBOL_SIDE_AND_SETTLEMENT_DATE"
					},
				]
			},
			{
				number => "591",
				name   => "PreallocMethod",
				type   => "CHAR",
				enum   => [
					{ name => "0", description => "PRO_RATA" },
					{ name => "1", description => "DO_NOT_PRO_RATA" },
				]
			},
			{
				number => "592",
				name   => "UnderlyingCountryOfIssue",
				type   => "COUNTRY"
			},
			{
				number => "593",
				name   => "UnderlyingStateOrProvinceOfIssue",
				type   => "STRING"
			},
			{
				number => "594",
				name   => "UnderlyingLocaleOfIssue",
				type   => "STRING"
			},
			{
				number => "595",
				name   => "UnderlyingInstrRegistry",
				type   => "STRING"
			},
			{
				number => "596",
				name   => "LegCountryOfIssue",
				type   => "COUNTRY"
			},
			{
				number => "597",
				name   => "LegStateOrProvinceOfIssue",
				type   => "STRING"
			},
			{ number => "598", name => "LegLocaleOfIssue", type => "STRING" },
			{ number => "599", name => "LegInstrRegistry", type => "STRING" },
			{ number => "600", name => "LegSymbol",        type => "STRING" },
			{ number => "601", name => "LegSymbolSfx",     type => "STRING" },
			{ number => "602", name => "LegSecurityID",    type => "STRING" },
			{
				number => "603",
				name   => "LegSecurityIDSource",
				type   => "STRING"
			},
			{
				number => "604",
				name   => "NoLegSecurityAltID",
				type   => "STRING"
			},
			{ number => "605", name => "LegSecurityAltID", type => "STRING" },
			{
				number => "606",
				name   => "LegSecurityAltIDSource",
				type   => "STRING"
			},
			{ number => "607", name => "LegProduct",      type => "INT" },
			{ number => "608", name => "LegCFICode",      type => "STRING" },
			{ number => "609", name => "LegSecurityType", type => "STRING" },
			{
				number => "610",
				name   => "LegMaturityMonthYear",
				type   => "MONTHYEAR"
			},
			{
				number => "611",
				name   => "LegMaturityDate",
				type   => "LOCALMKTDATE"
			},
			{ number => "612", name => "LegStrikePrice",  type => "PRICE" },
			{ number => "613", name => "LegOptAttribute", type => "CHAR" },
			{
				number => "614",
				name   => "LegContractMultiplier",
				type   => "FLOAT"
			},
			{
				number => "615",
				name   => "LegCouponRate",
				type   => "PERCENTAGE"
			},
			{
				number => "616",
				name   => "LegSecurityExchange",
				type   => "EXCHANGE"
			},
			{ number => "617", name => "LegIssuer", type => "STRING" },
			{
				number => "618",
				name   => "EncodedLegIssuerLen",
				type   => "LENGTH"
			},
			{ number => "619", name => "EncodedLegIssuer", type => "DATA" },
			{ number => "620", name => "LegSecurityDesc",  type => "STRING" },
			{
				number => "621",
				name   => "EncodedLegSecurityDescLen",
				type   => "LENGTH"
			},
			{
				number => "622",
				name   => "EncodedLegSecurityDesc",
				type   => "DATA"
			},
			{ number => "623", name => "LegRatioQty", type => "FLOAT" },
			{ number => "624", name => "LegSide",     type => "CHAR" },
			{
				number => "625",
				name   => "TradingSessionSubID",
				type   => "STRING"
			},
			{
				number => "626",
				name   => "AllocType",
				type   => "INT",
				enum   => [
					{ name => "1", description => "CALCULATED" },
					{ name => "2", description => "PRELIMINARY" },
					{
						name        => "5",
						description => "READY_TO_BOOK_SINGLE_ORDER"
					},
					{ name => "7", description => "WAREHOUSE_INSTRUCTION" },
					{ name => "8", description => "REQUEST_TO_INTERMEDIARY" },
				]
			},
			{ number => "627", name => "NoHops",    type => "NUMINGROUP" },
			{ number => "628", name => "HopCompID", type => "STRING" },
			{
				number => "629",
				name   => "HopSendingTime",
				type   => "UTCTIMESTAMP"
			},
			{ number => "630", name => "HopRefID",   type => "SEQNUM" },
			{ number => "631", name => "MidPx",      type => "PRICE" },
			{ number => "632", name => "BidYield",   type => "PERCENTAGE" },
			{ number => "633", name => "MidYield",   type => "PERCENTAGE" },
			{ number => "634", name => "OfferYield", type => "PERCENTAGE" },
			{
				number => "635",
				name   => "ClearingFeeIndicator",
				type   => "STRING",
				enum   => [
					{ name => "B", description => "CBOE_MEMBER" },
					{ name => "C", description => "NON_MEMBER_AND_CUSTOMER" },
					{
						name        => "E",
						description => "EQUITY_MEMBER_AND_CLEARING_MEMBER"
					},
					{
						name => "F",
						description =>
"FULL_AND_ASSOCIATE_MEMBER_TRADING_FOR_OWN_ACCOUNT_AND_AS_FLOOR_BROKERS"
					},
					{ name => "H", description => "FIRMS_106H_AND_106J" },
					{
						name => "I",
						description =>
						  "GIM_IDEM_AND_COM_MEMBERSHIP_INTEREST_HOLDERS"
					},
					{
						name        => "L",
						description => "LESSEE_AND_106F_EMPLOYEES"
					},
					{
						name        => "M",
						description => "ALL_OTHER_OWNERSHIP_TYPES"
					},
				]
			},
			{
				number => "636",
				name   => "WorkingIndicator",
				type   => "BOOLEAN"
			},
			{ number => "637", name => "LegLastPx", type => "PRICE" },
			{
				number => "638",
				name   => "PriorityIndicator",
				type   => "INT",
				enum   => [
					{ name => "0", description => "PRIORITY_UNCHANGED" },
					{
						name => "1",
						description =>
						  "LOST_PRIORITY_AS_RESULT_OF_ORDER_CHANGE"
					},
				]
			},
			{
				number => "639",
				name   => "PriceImprovement",
				type   => "PRICEOFFSET"
			},
			{ number => "640", name => "Price2", type => "PRICE" },
			{
				number => "641",
				name   => "LastForwardPoints2",
				type   => "PRICEOFFSET"
			},
			{
				number => "642",
				name   => "BidForwardPoints2",
				type   => "PRICEOFFSET"
			},
			{
				number => "643",
				name   => "OfferForwardPoints2",
				type   => "PRICEOFFSET"
			},
			{ number => "644", name => "RFQReqID",         type => "STRING" },
			{ number => "645", name => "MktBidPx",         type => "PRICE" },
			{ number => "646", name => "MktOfferPx",       type => "PRICE" },
			{ number => "647", name => "MinBidSize",       type => "QTY" },
			{ number => "648", name => "MinOfferSize",     type => "QTY" },
			{ number => "649", name => "QuoteStatusReqID", type => "STRING" },
			{ number => "650", name => "LegalConfirm", type => "BOOLEAN" },
			{ number => "651", name => "UnderlyingLastPx",  type => "PRICE" },
			{ number => "652", name => "UnderlyingLastQty", type => "QTY" },
			{ number => "654", name => "LegRefID",       type => "STRING" },
			{ number => "655", name => "ContraLegRefID", type => "STRING" },
			{
				number => "656",
				name   => "SettlCurrBidFxRate",
				type   => "FLOAT"
			},
			{
				number => "657",
				name   => "SettlCurrOfferFxRate",
				type   => "FLOAT"
			},
			{
				number => "658",
				name   => "QuoteRequestRejectReason",
				type   => "INT",
				enum   => [
					{ name => "1", description => "UNKNOWN_SYMBOL" },
					{ name => "2", description => "EXCHANGE_CLOSED" },
					{
						name        => "3",
						description => "QUOTE_REQUEST_EXCEEDS_LIMIT"
					},
					{ name => "4", description => "TOO_LATE_TO_ENTER" },
					{ name => "5", description => "INVALID_PRICE" },
					{
						name        => "6",
						description => "NOT_AUTHORIZED_TO_REQUEST_QUOTE"
					},
					{ name => "7", description => "NO_MATCH_FOR_INQUIRY" },
					{
						name        => "8",
						description => "NO_MARKET_FOR_INSTRUMENT"
					},
					{ name => "9",  description => "NO_INVENTORY" },
					{ name => "10", description => "PASS" },
					{ name => "99", description => "OTHER" },
				]
			},
			{ number => "659", name => "SideComplianceID", type => "STRING" },
			{
				number => "660",
				name   => "AcctIDSource",
				type   => "INT",
				enum   => [
					{ name => "1", description => "BIC" },
					{ name => "2", description => "SID_CODE" },
					{ name => "3", description => "TFM" },
					{ name => "4", description => "OMGEO" },
					{ name => "5", description => "DTCC_CODE" },
				]
			},
			{ number => "661", name => "AllocAcctIDSource", type => "INT" },
			{ number => "662", name => "BenchmarkPrice",    type => "PRICE" },
			{ number => "663", name => "BenchmarkPriceType", type => "INT" },
			{ number => "664", name => "ConfirmID", type => "STRING" },
			{
				number => "665",
				name   => "ConfirmStatus",
				type   => "INT",
				enum   => [
					{ name => "1", description => "RECEIVED" },
					{ name => "2", description => "MISMATCHED_ACCOUNT" },
					{
						name        => "3",
						description => "MISSING_SETTLEMENT_INSTRUCTIONS"
					},
					{ name => "4", description => "CONFIRMED" },
					{ name => "5", description => "REQUEST_REJECTED" },
				]
			},
			{
				number => "666",
				name   => "ConfirmTransType",
				type   => "INT",
				enum   => [
					{ name => "0", description => "NEW" },
					{ name => "1", description => "REPLACE" },
					{ name => "2", description => "CANCEL" },
				]
			},
			{
				number => "667",
				name   => "ContractSettlMonth",
				type   => "MONTHYEAR"
			},
			{
				number => "668",
				name   => "DeliveryForm",
				type   => "INT",
				enum   => [
					{ name => "1", description => "BOOKENTRY" },
					{ name => "2", description => "BEARER" },
				]
			},
			{ number => "669", name => "LastParPx",   type => "PRICE" },
			{ number => "670", name => "NoLegAllocs", type => "NUMINGROUP" },
			{ number => "671", name => "LegAllocAccount", type => "STRING" },
			{
				number => "672",
				name   => "LegIndividualAllocID",
				type   => "STRING"
			},
			{ number => "673", name => "LegAllocQty", type => "QTY" },
			{
				number => "674",
				name   => "LegAllocAcctIDSource",
				type   => "STRING"
			},
			{
				number => "675",
				name   => "LegSettlCurrency",
				type   => "CURRENCY"
			},
			{
				number => "676",
				name   => "LegBenchmarkCurveCurrency",
				type   => "CURRENCY"
			},
			{
				number => "677",
				name   => "LegBenchmarkCurveName",
				type   => "STRING"
			},
			{
				number => "678",
				name   => "LegBenchmarkCurvePoint",
				type   => "STRING"
			},
			{ number => "679", name => "LegBenchmarkPrice", type => "PRICE" },
			{
				number => "680",
				name   => "LegBenchmarkPriceType",
				type   => "INT"
			},
			{ number => "681", name => "LegBidPx",  type => "PRICE" },
			{ number => "682", name => "LegIOIQty", type => "STRING" },
			{
				number => "683",
				name   => "NoLegStipulations",
				type   => "NUMINGROUP"
			},
			{ number => "684", name => "LegOfferPx",   type => "PRICE" },
			{ number => "685", name => "LegOrderQty",  type => "QTY" },
			{ number => "686", name => "LegPriceType", type => "INT" },
			{ number => "687", name => "LegQty",       type => "QTY" },
			{
				number => "688",
				name   => "LegStipulationType",
				type   => "STRING"
			},
			{
				number => "689",
				name   => "LegStipulationValue",
				type   => "STRING"
			},
			{
				number => "690",
				name   => "LegSwapType",
				type   => "INT",
				enum   => [
					{ name => "1", description => "PAR_FOR_PAR" },
					{ name => "2", description => "MODIFIED_DURATION" },
					{ name => "4", description => "RISK" },
					{ name => "5", description => "PROCEEDS" },
				]
			},
			{ number => "691", name => "Pool", type => "STRING" },
			{
				number => "692",
				name   => "QuotePriceType",
				type   => "INT",
				enum   => [
					{ name => "1", description => "PERCENT" },
					{ name => "2", description => "PER_SHARE" },
					{ name => "3", description => "FIXED_AMOUNT" },
					{ name => "4", description => "DISCOUNT" },
					{ name => "5", description => "PREMIUM" },
					{
						name        => "6",
						description => "BASIS_POINTS_RELATIVE_TO_BENCHMARK"
					},
					{ name => "7", description => "TED_PRICE" },
					{ name => "8", description => "TED_YIELD" },
					{ name => "9", description => "YIELD_SPREAD" },
				]
			},
			{ number => "693", name => "QuoteRespID", type => "STRING" },
			{
				number => "694",
				name   => "QuoteRespType",
				type   => "INT",
				enum   => [
					{ name => "1", description => "HIT_LIFT" },
					{ name => "2", description => "COUNTER" },
					{ name => "3", description => "EXPIRED" },
					{ name => "4", description => "COVER" },
					{ name => "5", description => "DONE_AWAY" },
					{ name => "6", description => "PASS" },
				]
			},
			{ number => "695", name => "QuoteQualifier", type => "CHAR" },
			{
				number => "696",
				name   => "YieldRedemptionDate",
				type   => "LOCALMKTDATE"
			},
			{
				number => "697",
				name   => "YieldRedemptionPrice",
				type   => "PRICE"
			},
			{
				number => "698",
				name   => "YieldRedemptionPriceType",
				type   => "INT"
			},
			{
				number => "699",
				name   => "BenchmarkSecurityID",
				type   => "STRING"
			},
			{
				number => "700",
				name   => "ReversalIndicator",
				type   => "BOOLEAN"
			},
			{
				number => "701",
				name   => "YieldCalcDate",
				type   => "LOCALMKTDATE"
			},
			{ number => "702", name => "NoPositions", type => "NUMINGROUP" },
			{
				number => "703",
				name   => "PosType",
				type   => "STRING",
				enum   => [
					{ name => "TQ",  description => "TRANSACTION_QUANTITY" },
					{ name => "IAS", description => "INTRA_SPREAD_QTY" },
					{ name => "IES", description => "INTER_SPREAD_QTY" },
					{ name => "FIN", description => "END_OF_DAY_QTY" },
					{ name => "SOD", description => "START_OF_DAY_QTY" },
					{ name => "EX",  description => "OPTION_EXERCISE_QTY" },
					{ name => "AS",  description => "OPTION_ASSIGNMENT" },
					{
						name        => "TX",
						description => "TRANSACTION_FROM_EXERCISE"
					},
					{
						name        => "TA",
						description => "TRANSACTION_FROM_ASSIGNMENT"
					},
					{ name => "PIT", description => "PIT_TRADE_QTY" },
					{ name => "TRF", description => "TRANSFER_TRADE_QTY" },
					{ name => "ETR", description => "ELECTRONIC_TRADE_QTY" },
					{ name => "ALC", description => "ALLOCATION_TRADE_QTY" },
					{ name => "PA",  description => "ADJUSTMENT_QTY" },
					{ name => "ASF", description => "AS_OF_TRADE_QTY" },
					{ name => "DLV", description => "DELIVERY_QTY" },
					{ name => "TOT", description => "TOTAL_TRANSACTION_QTY" },
					{ name => "XM",  description => "CROSS_MARGIN_QTY" },
					{ name => "SPL", description => "INTEGRAL_SPLIT" },
				]
			},
			{ number => "704", name => "LongQty",  type => "QTY" },
			{ number => "705", name => "ShortQty", type => "QTY" },
			{
				number => "706",
				name   => "PosQtyStatus",
				type   => "INT",
				enum   => [
					{ name => "0", description => "SUBMITTED" },
					{ name => "1", description => "ACCEPTED" },
					{ name => "2", description => "REJECTED" },
				]
			},
			{
				number => "707",
				name   => "PosAmtType",
				type   => "STRING",
				enum   => [
					{
						name        => "FMTM",
						description => "FINAL_MARK_TO_MARKET_AMOUNT"
					},
					{
						name        => "IMTM",
						description => "INCREMENTAL_MARK_TO_MARKET_AMOUNT"
					},
					{
						name        => "TVAR",
						description => "TRADE_VARIATION_AMOUNT"
					},
					{
						name        => "SMTM",
						description => "START_OF_DAY_MARK_TO_MARKET_AMOUNT"
					},
					{ name => "PREM", description => "PREMIUM_AMOUNT" },
					{ name => "CRES", description => "CASH_RESIDUAL_AMOUNT" },
					{ name => "CASH", description => "CASH_AMOUNT" },
					{
						name        => "VADJ",
						description => "VALUE_ADJUSTED_AMOUNT"
					},
				]
			},
			{ number => "708", name => "PosAmt", type => "AMT" },
			{
				number => "709",
				name   => "PosTransType",
				type   => "INT",
				enum   => [
					{ name => "1", description => "EXERCISE" },
					{ name => "2", description => "DO_NOT_EXERCISE" },
					{ name => "3", description => "POSITION_ADJUSTMENT" },
					{
						name => "4",
						description =>
						  "POSITION_CHANGE_SUBMISSION_MARGIN_DISPOSITION"
					},
					{ name => "5", description => "PLEDGE" },
				]
			},
			{ number => "710", name => "PosReqID", type => "STRING" },
			{
				number => "711",
				name   => "NoUnderlyings",
				type   => "NUMINGROUP"
			},
			{
				number => "712",
				name   => "PosMaintAction",
				type   => "INT",
				enum   => [
					{ name => "1", description => "NEW" },
					{ name => "2", description => "REPLACE" },
					{ name => "3", description => "CANCEL" },
				]
			},
			{ number => "713", name => "OrigPosReqRefID",  type => "STRING" },
			{ number => "714", name => "PosMaintRptRefID", type => "STRING" },
			{
				number => "715",
				name   => "ClearingBusinessDate",
				type   => "LOCALMKTDATE"
			},
			{ number => "716", name => "SettlSessID",    type => "STRING" },
			{ number => "717", name => "SettlSessSubID", type => "STRING" },
			{
				number => "718",
				name   => "AdjustmentType",
				type   => "INT",
				enum   => [
					{
						name        => "0",
						description => "PROCESS_REQUEST_AS_MARGIN_DISPOSITION"
					},
					{ name => "1", description => "DELTA_PLUS" },
					{ name => "2", description => "DELTA_MINUS" },
					{ name => "3", description => "FINAL" },
				]
			},
			{
				number => "719",
				name   => "ContraryInstructionIndicator",
				type   => "BOOLEAN"
			},
			{
				number => "720",
				name   => "PriorSpreadIndicator",
				type   => "BOOLEAN"
			},
			{ number => "721", name => "PosMaintRptID", type => "STRING" },
			{
				number => "722",
				name   => "PosMaintStatus",
				type   => "INT",
				enum   => [
					{ name => "0", description => "ACCEPTED" },
					{ name => "1", description => "ACCEPTED_WITH_WARNINGS" },
					{ name => "2", description => "REJECTED" },
					{ name => "3", description => "COMPLETED" },
					{ name => "4", description => "COMPLETED_WITH_WARNINGS" },
				]
			},
			{
				number => "723",
				name   => "PosMaintResult",
				type   => "INT",
				enum   => [
					{
						name => "0",
						description =>
						  "SUCCESSFUL_COMPLETION_NO_WARNINGS_OR_ERRORS"
					},
					{ name => "1", description => "REJECTED" },
				]
			},
			{
				number => "724",
				name   => "PosReqType",
				type   => "INT",
				enum   => [
					{ name => "0", description => "POSITIONS" },
					{ name => "1", description => "TRADES" },
					{ name => "2", description => "EXERCISES" },
					{ name => "3", description => "ASSIGNMENTS" },
				]
			},
			{
				number => "725",
				name   => "ResponseTransportType",
				type   => "INT",
				enum   => [
					{ name => "0", description => "INBAND" },
					{ name => "1", description => "OUT_OF_BAND" },
				]
			},
			{
				number => "726",
				name   => "ResponseDestination",
				type   => "STRING"
			},
			{ number => "727", name => "TotalNumPosReports", type => "INT" },
			{
				number => "728",
				name   => "PosReqResult",
				type   => "INT",
				enum   => [
					{ name => "0", description => "VALID_REQUEST" },
					{
						name        => "1",
						description => "INVALID_OR_UNSUPPORTED_REQUEST"
					},
					{
						name => "2",
						description =>
						  "NO_POSITIONS_FOUND_THAT_MATCH_CRITERIA"
					},
					{
						name        => "3",
						description => "NOT_AUTHORIZED_TO_REQUEST_POSITIONS"
					},
					{
						name        => "4",
						description => "REQUEST_FOR_POSITION_NOT_SUPPORTED"
					},
					{ name => "99", description => "OTHER" },
				]
			},
			{
				number => "729",
				name   => "PosReqStatus",
				type   => "INT",
				enum   => [
					{ name => "0", description => "COMPLETED" },
					{ name => "1", description => "COMPLETED_WITH_WARNINGS" },
					{ name => "2", description => "REJECTED" },
				]
			},
			{ number => "730", name => "SettlPrice", type => "PRICE" },
			{
				number => "731",
				name   => "SettlPriceType",
				type   => "INT",
				enum   => [
					{ name => "1", description => "FINAL" },
					{ name => "2", description => "THEORETICAL" },
				]
			},
			{
				number => "732",
				name   => "UnderlyingSettlPrice",
				type   => "PRICE"
			},
			{
				number => "733",
				name   => "UnderlyingSettlPriceType",
				type   => "INT"
			},
			{ number => "734", name => "PriorSettlPrice", type => "PRICE" },
			{
				number => "735",
				name   => "NoQuoteQualifiers",
				type   => "NUMINGROUP"
			},
			{
				number => "736",
				name   => "AllocSettlCurrency",
				type   => "CURRENCY"
			},
			{ number => "737", name => "AllocSettlCurrAmt",  type => "AMT" },
			{ number => "738", name => "InterestAtMaturity", type => "AMT" },
			{
				number => "739",
				name   => "LegDatedDate",
				type   => "LOCALMKTDATE"
			},
			{ number => "740", name => "LegPool", type => "STRING" },
			{
				number => "741",
				name   => "AllocInterestAtMaturity",
				type   => "AMT"
			},
			{
				number => "742",
				name   => "AllocAccruedInterestAmt",
				type   => "AMT"
			},
			{
				number => "743",
				name   => "DeliveryDate",
				type   => "LOCALMKTDATE"
			},
			{
				number => "744",
				name   => "AssignmentMethod",
				type   => "CHAR",
				enum   => [
					{ name => "R", description => "RANDOM" },
					{ name => "P", description => "PRORATA" },
				]
			},
			{ number => "745", name => "AssignmentUnit", type => "QTY" },
			{ number => "746", name => "OpenInterest",   type => "AMT" },
			{
				number => "747",
				name   => "ExerciseMethod",
				type   => "CHAR",
				enum   => [
					{ name => "A", description => "AUTOMATIC" },
					{ name => "M", description => "MANUAL" },
				]
			},
			{ number => "748", name => "TotNumTradeReports", type => "INT" },
			{
				number => "749",
				name   => "TradeRequestResult",
				type   => "INT",
				enum   => [
					{ name => "0", description => "SUCCESSFUL" },
					{
						name        => "1",
						description => "INVALID_OR_UNKNOWN_INSTRUMENT"
					},
					{
						name        => "2",
						description => "INVALID_TYPE_OF_TRADE_REQUESTED"
					},
					{ name => "3", description => "INVALID_PARTIES" },
					{
						name        => "4",
						description => "INVALID_TRANSPORT_TYPE_REQUESTED"
					},
					{
						name        => "5",
						description => "INVALID_DESTINATION_REQUESTED"
					},
					{
						name        => "8",
						description => "TRADEREQUESTTYPE_NOT_SUPPORTED"
					},
					{
						name => "9",
						description =>
						  "UNAUTHORIZED_FOR_TRADE_CAPTURE_REPORT_REQUEST"
					},
				]
			},
			{
				number => "750",
				name   => "TradeRequestStatus",
				type   => "INT",
				enum   => [
					{ name => "0", description => "ACCEPTED" },
					{ name => "1", description => "COMPLETED" },
					{ name => "2", description => "REJECTED" },
				]
			},
			{
				number => "751",
				name   => "TradeReportRejectReason",
				type   => "INT",
				enum   => [
					{ name => "0", description => "SUCCESSFUL" },
					{
						name        => "1",
						description => "INVALID_PARTY_INFORMATION"
					},
					{ name => "2", description => "UNKNOWN_INSTRUMENT" },
					{
						name        => "3",
						description => "UNAUTHORIZED_TO_REPORT_TRADES"
					},
					{ name => "4", description => "INVALID_TRADE_TYPE" },
				]
			},
			{
				number => "752",
				name   => "SideMultiLegReportingType",
				type   => "INT",
				enum   => [
					{ name => "1", description => "SINGLE_SECURITY" },
					{
						name => "2",
						description =>
						  "INDIVIDUAL_LEG_OF_A_MULTI_LEG_SECURITY"
					},
					{ name => "3", description => "MULTI_LEG_SECURITY" },
				]
			},
			{ number => "753", name => "NoPosAmt", type => "NUMINGROUP" },
			{
				number => "754",
				name   => "AutoAcceptIndicator",
				type   => "BOOLEAN"
			},
			{ number => "755", name => "AllocReportID", type => "STRING" },
			{
				number => "756",
				name   => "NoNested2PartyIDs",
				type   => "NUMINGROUP"
			},
			{ number => "757", name => "Nested2PartyID", type => "STRING" },
			{
				number => "758",
				name   => "Nested2PartyIDSource",
				type   => "CHAR"
			},
			{ number => "759", name => "Nested2PartyRole", type => "INT" },
			{
				number => "760",
				name   => "Nested2PartySubID",
				type   => "STRING"
			},
			{
				number => "761",
				name   => "BenchmarkSecurityIDSource",
				type   => "STRING",
				enum   => [
					{ name => "1", description => "CUSIP" },
					{ name => "2", description => "SEDOL" },
					{ name => "3", description => "QUIK" },
					{ name => "4", description => "ISIN_NUMBER" },
					{ name => "5", description => "RIC_CODE" },
					{ name => "6", description => "ISO_CURRENCY_CODE" },
					{ name => "7", description => "ISO_COUNTRY_CODE" },
					{ name => "8", description => "EXCHANGE_SYMBOL" },
					{
						name        => "9",
						description => "CONSOLIDATED_TAPE_ASSOCIATION"
					},
					{ name => "A", description => "BLOOMBERG_SYMBOL" },
					{ name => "B", description => "WERTPAPIER" },
					{ name => "C", description => "DUTCH" },
					{ name => "D", description => "VALOREN" },
					{ name => "E", description => "SICOVAM" },
					{ name => "F", description => "BELGIAN" },
					{ name => "G", description => "COMMON" },
					{
						name        => "H",
						description => "CLEARING_HOUSE_CLEARING_ORGANIZATION"
					},
					{
						name        => "I",
						description => "ISDA_FPML_PRODUCT_SPECIFICATION"
					},
					{
						name        => "J",
						description => "OPTIONS_PRICE_REPORTING_AUTHORITY"
					},
				]
			},
			{ number => "762", name => "SecuritySubType", type => "STRING" },
			{
				number => "763",
				name   => "UnderlyingSecuritySubType",
				type   => "STRING"
			},
			{
				number => "764",
				name   => "LegSecuritySubType",
				type   => "STRING"
			},
			{
				number => "765",
				name   => "AllowableOneSidednessPct",
				type   => "PERCENTAGE"
			},
			{
				number => "766",
				name   => "AllowableOneSidednessValue",
				type   => "AMT"
			},
			{
				number => "767",
				name   => "AllowableOneSidednessCurr",
				type   => "CURRENCY"
			},
			{
				number => "768",
				name   => "NoTrdRegTimestamps",
				type   => "NUMINGROUP"
			},
			{
				number => "769",
				name   => "TrdRegTimestamp",
				type   => "UTCTIMESTAMP"
			},
			{
				number => "770",
				name   => "TrdRegTimestampType",
				type   => "INT",
				enum   => [
					{ name => "1", description => "EXECUTION_TIME" },
					{ name => "2", description => "TIME_IN" },
					{ name => "3", description => "TIME_OUT" },
					{ name => "4", description => "BROKER_RECEIPT" },
					{ name => "5", description => "BROKER_EXECUTION" },
				]
			},
			{
				number => "771",
				name   => "TrdRegTimestampOrigin",
				type   => "STRING"
			},
			{ number => "772", name => "ConfirmRefID", type => "STRING" },
			{
				number => "773",
				name   => "ConfirmType",
				type   => "INT",
				enum   => [
					{ name => "1", description => "STATUS" },
					{ name => "2", description => "CONFIRMATION" },
					{
						name        => "3",
						description => "CONFIRMATION_REQUEST_REJECTED"
					},
				]
			},
			{
				number => "774",
				name   => "ConfirmRejReason",
				type   => "INT",
				enum   => [
					{ name => "1", description => "MISMATCHED_ACCOUNT" },
					{
						name        => "2",
						description => "MISSING_SETTLEMENT_INSTRUCTIONS"
					},
				]
			},
			{
				number => "775",
				name   => "BookingType",
				type   => "INT",
				enum   => [
					{ name => "0", description => "REGULAR_BOOKING" },
					{ name => "1", description => "CFD" },
					{ name => "2", description => "TOTAL_RETURN_SWAP" },
				]
			},
			{
				number => "776",
				name   => "IndividualAllocRejCode",
				type   => "INT"
			},
			{ number => "777", name => "SettlInstMsgID", type => "STRING" },
			{ number => "778", name => "NoSettlInst", type => "NUMINGROUP" },
			{
				number => "779",
				name   => "LastUpdateTime",
				type   => "UTCTIMESTAMP"
			},
			{
				number => "780",
				name   => "AllocSettlInstType",
				type   => "INT",
				enum   => [
					{
						name        => "0",
						description => "USE_DEFAULT_INSTRUCTIONS"
					},
					{
						name        => "1",
						description => "DERIVE_FROM_PARAMETERS_PROVIDED"
					},
					{ name => "2", description => "FULL_DETAILS_PROVIDED" },
					{ name => "3", description => "SSI_DB_IDS_PROVIDED" },
					{ name => "4", description => "PHONE_FOR_INSTRUCTIONS" },
				]
			},
			{
				number => "781",
				name   => "NoSettlPartyIDs",
				type   => "NUMINGROUP"
			},
			{ number => "782", name => "SettlPartyID", type => "STRING" },
			{ number => "783", name => "SettlPartyIDSource", type => "CHAR" },
			{ number => "784", name => "SettlPartyRole",     type => "INT" },
			{ number => "785", name => "SettlPartySubID", type => "STRING" },
			{ number => "786", name => "SettlPartySubIDType", type => "INT" },
			{
				number => "787",
				name   => "DlvyInstType",
				type   => "CHAR",
				enum   => [
					{ name => "S", description => "SECURITIES" },
					{ name => "C", description => "CASH" },
				]
			},
			{
				number => "788",
				name   => "TerminationType",
				type   => "INT",
				enum   => [
					{ name => "1", description => "OVERNIGHT" },
					{ name => "2", description => "TERM" },
					{ name => "3", description => "FLEXIBLE" },
					{ name => "4", description => "OPEN" },
				]
			},
			{
				number => "789",
				name   => "NextExpectedMsgSeqNum",
				type   => "SEQNUM"
			},
			{ number => "790", name => "OrdStatusReqID", type => "STRING" },
			{ number => "791", name => "SettlInstReqID", type => "STRING" },
			{
				number => "792",
				name   => "SettlInstReqRejCode",
				type   => "INT",
				enum   => [
					{
						name        => "0",
						description => "UNABLE_TO_PROCESS_REQUEST"
					},
					{ name => "1", description => "UNKNOWN_ACCOUNT" },
					{
						name => "2",
						description =>
						  "NO_MATCHING_SETTLEMENT_INSTRUCTIONS_FOUND"
					},
				]
			},
			{ number => "793", name => "SecondaryAllocID", type => "STRING" },
			{
				number => "794",
				name   => "AllocReportType",
				type   => "INT",
				enum   => [
					{
						name        => "3",
						description => "SELLSIDE_CALCULATED_USING_PRELIMINARY"
					},
					{
						name => "4",
						description =>
						  "SELLSIDE_CALCULATED_WITHOUT_PRELIMINARY"
					},
					{ name => "5", description => "WAREHOUSE_RECAP" },
					{ name => "8", description => "REQUEST_TO_INTERMEDIARY" },
				]
			},
			{ number => "795", name => "AllocReportRefID", type => "STRING" },
			{
				number => "796",
				name   => "AllocCancReplaceReason",
				type   => "INT",
				enum   => [
					{
						name        => "1",
						description => "ORIGINAL_DETAILS_INCOMPLETE_INCORRECT"
					},
					{
						name        => "2",
						description => "CHANGE_IN_UNDERLYING_ORDER_DETAILS"
					},
				]
			},
			{
				number => "797",
				name   => "CopyMsgIndicator",
				type   => "BOOLEAN"
			},
			{
				number => "798",
				name   => "AllocAccountType",
				type   => "INT",
				enum   => [
					{
						name => "1",
						description =>
						  "ACCOUNT_IS_CARRIED_ON_CUSTOMER_SIDE_OF_BOOKS"
					},
					{
						name => "2",
						description =>
						  "ACCOUNT_IS_CARRIED_ON_NON_CUSTOMER_SIDE_OF_BOOKS"
					},
					{ name => "3", description => "HOUSE_TRADER" },
					{ name => "4", description => "FLOOR_TRADER" },
					{
						name => "6",
						description =>
"ACCOUNT_IS_CARRIED_ON_NON_CUSTOMER_SIDE_OF_BOOKS_AND_IS_CROSS_MARGINED"
					},
					{
						name => "7",
						description =>
						  "ACCOUNT_IS_HOUSE_TRADER_AND_IS_CROSS_MARGINED"
					},
					{
						name        => "8",
						description => "JOINT_BACKOFFICE_ACCOUNT"
					},
				]
			},
			{ number => "799", name => "OrderAvgPx",      type => "PRICE" },
			{ number => "800", name => "OrderBookingQty", type => "QTY" },
			{
				number => "801",
				name   => "NoSettlPartySubIDs",
				type   => "NUMINGROUP"
			},
			{
				number => "802",
				name   => "NoPartySubIDs",
				type   => "NUMINGROUP"
			},
			{ number => "803", name => "PartySubIDType", type => "INT" },
			{
				number => "804",
				name   => "NoNestedPartySubIDs",
				type   => "NUMINGROUP"
			},
			{
				number => "805",
				name   => "NestedPartySubIDType",
				type   => "INT"
			},
			{
				number => "806",
				name   => "NoNested2PartySubIDs",
				type   => "NUMINGROUP"
			},
			{
				number => "807",
				name   => "Nested2PartySubIDType",
				type   => "INT"
			},
			{
				number => "808",
				name   => "AllocIntermedReqType",
				type   => "INT",
				enum   => [
					{ name => "1", description => "PENDING_ACCEPT" },
					{ name => "2", description => "PENDING_RELEASE" },
					{ name => "3", description => "PENDING_REVERSAL" },
					{ name => "4", description => "ACCEPT" },
					{ name => "5", description => "BLOCK_LEVEL_REJECT" },
					{ name => "6", description => "ACCOUNT_LEVEL_REJECT" },
				]
			},
			{ number => "810", name => "UnderlyingPx",   type => "PRICE" },
			{ number => "811", name => "PriceDelta",     type => "FLOAT" },
			{ number => "812", name => "ApplQueueMax",   type => "INT" },
			{ number => "813", name => "ApplQueueDepth", type => "INT" },
			{
				number => "814",
				name   => "ApplQueueResolution",
				type   => "INT",
				enum   => [
					{ name => "0", description => "NO_ACTION_TAKEN" },
					{ name => "1", description => "QUEUE_FLUSHED" },
					{ name => "2", description => "OVERLAY_LAST" },
					{ name => "3", description => "END_SESSION" },
				]
			},
			{
				number => "815",
				name   => "ApplQueueAction",
				type   => "INT",
				enum   => [
					{ name => "0", description => "NO_ACTION_TAKEN" },
					{ name => "1", description => "QUEUE_FLUSHED" },
					{ name => "2", description => "OVERLAY_LAST" },
					{ name => "3", description => "END_SESSION" },
				]
			},
			{
				number => "816",
				name   => "NoAltMDSource",
				type   => "NUMINGROUP"
			},
			{ number => "817", name => "AltMDSourceID", type => "STRING" },
			{
				number => "818",
				name   => "SecondaryTradeReportID",
				type   => "STRING"
			},
			{
				number => "819",
				name   => "AvgPxIndicator",
				type   => "INT",
				enum   => [
					{ name => "0", description => "NO_AVERAGE_PRICING" },
					{
						name => "1",
						description =>
"TRADE_IS_PART_OF_AN_AVERAGE_PRICE_GROUP_IDENTIFIED_BY_THE_TRADELINKID"
					},
					{
						name => "2",
						description =>
"LAST_TRADE_IN_THE_AVERAGE_PRICE_GROUP_IDENTIFIED_BY_THE_TRADELINKID"
					},
				]
			},
			{ number => "820", name => "TradeLinkID",      type => "STRING" },
			{ number => "821", name => "OrderInputDevice", type => "STRING" },
			{
				number => "822",
				name   => "UnderlyingTradingSessionID",
				type   => "STRING"
			},
			{
				number => "823",
				name   => "UnderlyingTradingSessionSubID",
				type   => "STRING"
			},
			{ number => "824", name => "TradeLegRefID", type => "STRING" },
			{ number => "825", name => "ExchangeRule",  type => "STRING" },
			{
				number => "826",
				name   => "TradeAllocIndicator",
				type   => "INT",
				enum   => [
					{ name => "0", description => "ALLOCATION_NOT_REQUIRED" },
					{ name => "1", description => "ALLOCATION_REQUIRED" },
					{
						name => "2",
						description =>
						  "USE_ALLOCATION_PROVIDED_WITH_THE_TRADE"
					},
				]
			},
			{
				number => "827",
				name   => "ExpirationCycle",
				type   => "INT",
				enum   => [
					{
						name        => "0",
						description => "EXPIRE_ON_TRADING_SESSION_CLOSE"
					},
					{
						name        => "1",
						description => "EXPIRE_ON_TRADING_SESSION_OPEN"
					},
				]
			},
			{
				number => "828",
				name   => "TrdType",
				type   => "INT",
				enum   => [
					{ name => "0", description => "REGULAR_TRADE" },
					{ name => "1", description => "BLOCK_TRADE" },
					{ name => "2", description => "EFP" },
					{ name => "3", description => "TRANSFER" },
					{ name => "4", description => "LATE_TRADE" },
					{ name => "5", description => "T_TRADE" },
					{
						name        => "6",
						description => "WEIGHTED_AVERAGE_PRICE_TRADE"
					},
					{ name => "7", description => "BUNCHED_TRADE" },
					{ name => "8", description => "LATE_BUNCHED_TRADE" },
					{
						name        => "9",
						description => "PRIOR_REFERENCE_PRICE_TRADE"
					},
				]
			},
			{ number => "829", name => "TrdSubType",     type => "INT" },
			{ number => "830", name => "TransferReason", type => "STRING" },
			{ number => "831", name => "AsgnReqID",      type => "STRING" },
			{
				number => "832",
				name   => "TotNumAssignmentReports",
				type   => "INT"
			},
			{ number => "833", name => "AsgnRptID", type => "STRING" },
			{
				number => "834",
				name   => "ThresholdAmount",
				type   => "PRICEOFFSET"
			},
			{
				number => "835",
				name   => "PegMoveType",
				type   => "INT",
				enum   => [
					{ name => "0", description => "FLOATING" },
					{ name => "1", description => "FIXED" },
				]
			},
			{
				number => "836",
				name   => "PegOffsetType",
				type   => "INT",
				enum   => [
					{ name => "0", description => "PRICE" },
					{ name => "1", description => "BASIS_POINTS" },
					{ name => "2", description => "TICKS" },
					{ name => "3", description => "PRICE_TIER_LEVEL" },
				]
			},
			{
				number => "837",
				name   => "PegLimitType",
				type   => "INT",
				enum   => [
					{ name => "0", description => "OR_BETTER" },
					{ name => "1", description => "STRICT" },
					{ name => "2", description => "OR_WORSE" },
				]
			},
			{
				number => "838",
				name   => "PegRoundDirection",
				type   => "INT",
				enum   => [
					{ name => "1", description => "MORE_AGGRESSIVE" },
					{ name => "2", description => "MORE_PASSIVE" },
				]
			},
			{ number => "839", name => "PeggedPrice", type => "PRICE" },
			{
				number => "840",
				name   => "PegScope",
				type   => "INT",
				enum   => [
					{ name => "1", description => "LOCAL" },
					{ name => "2", description => "NATIONAL" },
					{ name => "3", description => "GLOBAL" },
					{
						name        => "4",
						description => "NATIONAL_EXCLUDING_LOCAL"
					},
				]
			},
			{
				number => "841",
				name   => "DiscretionMoveType",
				type   => "INT",
				enum   => [
					{ name => "0", description => "FLOATING" },
					{ name => "1", description => "FIXED" },
				]
			},
			{
				number => "842",
				name   => "DiscretionOffsetType",
				type   => "INT",
				enum   => [
					{ name => "0", description => "PRICE" },
					{ name => "1", description => "BASIS_POINTS" },
					{ name => "2", description => "TICKS" },
					{ name => "3", description => "PRICE_TIER_LEVEL" },
				]
			},
			{
				number => "843",
				name   => "DiscretionLimitType",
				type   => "INT",
				enum   => [
					{ name => "0", description => "OR_BETTER" },
					{ name => "1", description => "STRICT" },
					{ name => "2", description => "OR_WORSE" },
				]
			},
			{
				number => "844",
				name   => "DiscretionRoundDirection",
				type   => "INT",
				enum   => [
					{ name => "1", description => "MORE_AGGRESSIVE" },
					{ name => "2", description => "MORE_PASSIVE" },
				]
			},
			{ number => "845", name => "DiscretionPrice", type => "PRICE" },
			{
				number => "846",
				name   => "DiscretionScope",
				type   => "INT",
				enum   => [
					{ name => "1", description => "LOCAL" },
					{ name => "2", description => "NATIONAL" },
					{ name => "3", description => "GLOBAL" },
					{
						name        => "4",
						description => "NATIONAL_EXCLUDING_LOCAL"
					},
				]
			},
			{ number => "847", name => "TargetStrategy", type => "INT" },
			{
				number => "848",
				name   => "TargetStrategyParameters",
				type   => "STRING"
			},
			{
				number => "849",
				name   => "ParticipationRate",
				type   => "PERCENTAGE"
			},
			{
				number => "850",
				name   => "TargetStrategyPerformance",
				type   => "FLOAT"
			},
			{
				number => "851",
				name   => "LastLiquidityInd",
				type   => "INT",
				enum   => [
					{ name => "1", description => "ADDED_LIQUIDITY" },
					{ name => "2", description => "REMOVED_LIQUIDITY" },
					{ name => "3", description => "LIQUIDITY_ROUTED_OUT" },
				]
			},
			{
				number => "852",
				name   => "PublishTrdIndicator",
				type   => "BOOLEAN"
			},
			{
				number => "853",
				name   => "ShortSaleReason",
				type   => "INT",
				enum   => [
					{ name => "0", description => "DEALER_SOLD_SHORT" },
					{
						name        => "1",
						description => "DEALER_SOLD_SHORT_EXEMPT"
					},
					{
						name        => "2",
						description => "SELLING_CUSTOMER_SOLD_SHORT"
					},
					{
						name        => "3",
						description => "SELLING_CUSTOMER_SOLD_SHORT_EXEMPT"
					},
					{
						name => "4",
						description =>
"QUALIFED_SERVICE_REPRESENTATIVE_OR_AUTOMATIC_GIVEUP_CONTRA_SIDE_SOLD_SHORT"
					},
					{
						name => "5",
						description =>
						  "QSR_OR_AGU_CONTRA_SIDE_SOLD_SHORT_EXEMPT"
					},
				]
			},
			{
				number => "854",
				name   => "QtyType",
				type   => "INT",
				enum   => [
					{ name => "0", description => "UNITS" },
					{ name => "1", description => "CONTRACTS" },
				]
			},
			{ number => "855", name => "SecondaryTrdType", type => "INT" },
			{
				number => "856",
				name   => "TradeReportType",
				type   => "INT",
				enum   => [
					{ name => "0", description => "SUBMIT" },
					{ name => "1", description => "ALLEGED" },
					{ name => "2", description => "ACCEPT" },
					{ name => "3", description => "DECLINE" },
					{ name => "4", description => "ADDENDUM" },
					{ name => "5", description => "NO_WAS" },
					{ name => "6", description => "TRADE_REPORT_CANCEL" },
					{ name => "7", description => "LOCKED_IN_TRADE_BREAK" },
				]
			},
			{
				number => "857",
				name   => "AllocNoOrdersType",
				type   => "INT",
				enum   => [
					{ name => "0", description => "NOT_SPECIFIED" },
					{ name => "1", description => "EXPLICIT_LIST_PROVIDED" },
				]
			},
			{ number => "858", name => "SharedCommission", type => "AMT" },
			{ number => "859", name => "ConfirmReqID",     type => "STRING" },
			{ number => "860", name => "AvgParPx",         type => "PRICE" },
			{ number => "861", name => "ReportedPx",       type => "PRICE" },
			{ number => "862", name => "NoCapacities", type => "NUMINGROUP" },
			{ number => "863", name => "OrderCapacityQty", type => "QTY" },
			{ number => "864", name => "NoEvents", type => "NUMINGROUP" },
			{
				number => "865",
				name   => "EventType",
				type   => "INT",
				enum   => [
					{ name => "1", description => "PUT" },
					{ name => "2", description => "CALL" },
					{ name => "3", description => "TENDER" },
					{ name => "4", description => "SINKING_FUND_CALL" },
				]
			},
			{ number => "866", name => "EventDate", type => "LOCALMKTDATE" },
			{ number => "867", name => "EventPx",   type => "PRICE" },
			{ number => "868", name => "EventText", type => "STRING" },
			{ number => "869", name => "PctAtRisk", type => "PERCENTAGE" },
			{
				number => "870",
				name   => "NoInstrAttrib",
				type   => "NUMINGROUP"
			},
			{
				number => "871",
				name   => "InstrAttribType",
				type   => "INT",
				enum   => [
					{ name => "1", description => "FLAT" },
					{ name => "2", description => "ZERO_COUPON" },
					{ name => "3", description => "INTEREST_BEARING" },
					{ name => "4", description => "NO_PERIODIC_PAYMENTS" },
					{ name => "5", description => "VARIABLE_RATE" },
					{ name => "6", description => "LESS_FEE_FOR_PUT" },
					{ name => "7", description => "STEPPED_COUPON" },
					{ name => "8", description => "COUPON_PERIOD" },
					{ name => "9", description => "WHEN_AND_IF_ISSUED" },
				]
			},
			{ number => "872", name => "InstrAttribValue", type => "STRING" },
			{ number => "873", name => "DatedDate", type => "LOCALMKTDATE" },
			{
				number => "874",
				name   => "InterestAccrualDate",
				type   => "LOCALMKTDATE"
			},
			{ number => "875", name => "CPProgram", type => "INT" },
			{ number => "876", name => "CPRegType", type => "STRING" },
			{
				number => "877",
				name   => "UnderlyingCPProgram",
				type   => "STRING"
			},
			{
				number => "878",
				name   => "UnderlyingCPRegType",
				type   => "STRING"
			},
			{ number => "879", name => "UnderlyingQty", type => "QTY" },
			{ number => "880", name => "TrdMatchID",    type => "STRING" },
			{
				number => "881",
				name   => "SecondaryTradeReportRefID",
				type   => "STRING"
			},
			{
				number => "882",
				name   => "UnderlyingDirtyPrice",
				type   => "PRICE"
			},
			{
				number => "883",
				name   => "UnderlyingEndPrice",
				type   => "PRICE"
			},
			{
				number => "884",
				name   => "UnderlyingStartValue",
				type   => "AMT"
			},
			{
				number => "885",
				name   => "UnderlyingCurrentValue",
				type   => "AMT"
			},
			{ number => "886", name => "UnderlyingEndValue", type => "AMT" },
			{
				number => "887",
				name   => "NoUnderlyingStips",
				type   => "NUMINGROUP"
			},
			{
				number => "888",
				name   => "UnderlyingStipType",
				type   => "STRING"
			},
			{
				number => "889",
				name   => "UnderlyingStipValue",
				type   => "STRING"
			},
			{ number => "890", name => "MaturityNetMoney", type => "AMT" },
			{
				number => "891",
				name   => "MiscFeeBasis",
				type   => "INT",
				enum   => [
					{ name => "0", description => "ABSOLUTE" },
					{ name => "1", description => "PER_UNIT" },
					{ name => "2", description => "PERCENTAGE" },
				]
			},
			{ number => "892", name => "TotNoAllocs",  type => "INT" },
			{ number => "893", name => "LastFragment", type => "BOOLEAN" },
			{ number => "894", name => "CollReqID",    type => "STRING" },
			{
				number => "895",
				name   => "CollAsgnReason",
				type   => "INT",
				enum   => [
					{ name => "0", description => "INITIAL" },
					{ name => "1", description => "SCHEDULED" },
					{ name => "2", description => "TIME_WARNING" },
					{ name => "3", description => "MARGIN_DEFICIENCY" },
					{ name => "4", description => "MARGIN_EXCESS" },
					{
						name        => "5",
						description => "FORWARD_COLLATERAL_DEMAND"
					},
					{ name => "6", description => "EVENT_OF_DEFAULT" },
					{ name => "7", description => "ADVERSE_TAX_EVENT" },
				]
			},
			{
				number => "896",
				name   => "CollInquiryQualifier",
				type   => "INT",
				enum   => [
					{ name => "0", description => "TRADEDATE" },
					{ name => "1", description => "GC_INSTRUMENT" },
					{ name => "2", description => "COLLATERALINSTRUMENT" },
					{ name => "3", description => "SUBSTITUTION_ELIGIBLE" },
					{ name => "4", description => "NOT_ASSIGNED" },
					{ name => "5", description => "PARTIALLY_ASSIGNED" },
					{ name => "6", description => "FULLY_ASSIGNED" },
					{ name => "7", description => "OUTSTANDING_TRADES" },
				]
			},
			{ number => "897", name => "NoTrades",     type => "NUMINGROUP" },
			{ number => "898", name => "MarginRatio",  type => "PERCENTAGE" },
			{ number => "899", name => "MarginExcess", type => "AMT" },
			{ number => "900", name => "TotalNetValue",   type => "AMT" },
			{ number => "901", name => "CashOutstanding", type => "AMT" },
			{ number => "902", name => "CollAsgnID",      type => "STRING" },
			{
				number => "903",
				name   => "CollAsgnTransType",
				type   => "INT",
				enum   => [
					{ name => "0", description => "NEW" },
					{ name => "1", description => "REPLACE" },
					{ name => "2", description => "CANCEL" },
					{ name => "3", description => "RELEASE" },
					{ name => "4", description => "REVERSE" },
				]
			},
			{ number => "904", name => "CollRespID", type => "STRING" },
			{
				number => "905",
				name   => "CollAsgnRespType",
				type   => "INT",
				enum   => [
					{ name => "0", description => "RECEIVED" },
					{ name => "1", description => "ACCEPTED" },
					{ name => "2", description => "DECLINED" },
					{ name => "3", description => "REJECTED" },
				]
			},
			{
				number => "906",
				name   => "CollAsgnRejectReason",
				type   => "INT",
				enum   => [
					{ name => "0", description => "UNKNOWN_DEAL" },
					{
						name        => "1",
						description => "UNKNOWN_OR_INVALID_INSTRUMENT"
					},
					{
						name        => "2",
						description => "UNAUTHORIZED_TRANSACTION"
					},
					{ name => "3", description => "INSUFFICIENT_COLLATERAL" },
					{
						name        => "4",
						description => "INVALID_TYPE_OF_COLLATERAL"
					},
					{ name => "5", description => "EXCESSIVE_SUBSTITUTION" },
				]
			},
			{ number => "907", name => "CollAsgnRefID", type => "STRING" },
			{ number => "908", name => "CollRptID",     type => "STRING" },
			{ number => "909", name => "CollInquiryID", type => "STRING" },
			{
				number => "910",
				name   => "CollStatus",
				type   => "INT",
				enum   => [
					{ name => "0", description => "UNASSIGNED" },
					{ name => "1", description => "PARTIALLY_ASSIGNED" },
					{ name => "2", description => "ASSIGNMENT_PROPOSED" },
					{ name => "3", description => "ASSIGNED" },
					{ name => "4", description => "CHALLENGED" },
				]
			},
			{ number => "911", name => "TotNumReports", type => "INT" },
			{
				number => "912",
				name   => "LastRptRequested",
				type   => "BOOLEAN"
			},
			{ number => "913", name => "AgreementDesc", type => "STRING" },
			{ number => "914", name => "AgreementID",   type => "STRING" },
			{
				number => "915",
				name   => "AgreementDate",
				type   => "LOCALMKTDATE"
			},
			{ number => "916", name => "StartDate", type => "LOCALMKTDATE" },
			{ number => "917", name => "EndDate",   type => "LOCALMKTDATE" },
			{
				number => "918",
				name   => "AgreementCurrency",
				type   => "CURRENCY"
			},
			{
				number => "919",
				name   => "DeliveryType",
				type   => "INT",
				enum   => [
					{ name => "0", description => "VERSUS_PAYMENT" },
					{ name => "1", description => "FREE" },
					{ name => "2", description => "TRI_PARTY" },
					{ name => "3", description => "HOLD_IN_CUSTODY" },
				]
			},
			{
				number => "920",
				name   => "EndAccruedInterestAmt",
				type   => "AMT"
			},
			{ number => "921", name => "StartCash",     type => "AMT" },
			{ number => "922", name => "EndCash",       type => "AMT" },
			{ number => "923", name => "UserRequestID", type => "STRING" },
			{
				number => "924",
				name   => "UserRequestType",
				type   => "INT",
				enum   => [
					{ name => "1", description => "LOGONUSER" },
					{ name => "2", description => "LOGOFFUSER" },
					{ name => "3", description => "CHANGEPASSWORDFORUSER" },
					{
						name        => "4",
						description => "REQUEST_INDIVIDUAL_USER_STATUS"
					},
				]
			},
			{ number => "925", name => "NewPassword", type => "STRING" },
			{
				number => "926",
				name   => "UserStatus",
				type   => "INT",
				enum   => [
					{ name => "1", description => "LOGGED_IN" },
					{ name => "2", description => "NOT_LOGGED_IN" },
					{ name => "3", description => "USER_NOT_RECOGNISED" },
					{ name => "4", description => "PASSWORD_INCORRECT" },
					{ name => "5", description => "PASSWORD_CHANGED" },
					{ name => "6", description => "OTHER" },
				]
			},
			{ number => "927", name => "UserStatusText", type => "STRING" },
			{
				number => "928",
				name   => "StatusValue",
				type   => "INT",
				enum   => [
					{ name => "1", description => "CONNECTED" },
					{
						name        => "2",
						description => "NOT_CONNECTED_DOWN_EXPECTED_UP"
					},
					{
						name        => "3",
						description => "NOT_CONNECTED_DOWN_EXPECTED_DOWN"
					},
					{ name => "4", description => "IN_PROCESS" },
				]
			},
			{ number => "929", name => "StatusText", type => "STRING" },
			{ number => "930", name => "RefCompID",  type => "STRING" },
			{ number => "931", name => "RefSubID",   type => "STRING" },
			{
				number => "932",
				name   => "NetworkResponseID",
				type   => "STRING"
			},
			{ number => "933", name => "NetworkRequestID", type => "STRING" },
			{
				number => "934",
				name   => "LastNetworkResponseID",
				type   => "STRING"
			},
			{
				number => "935",
				name   => "NetworkRequestType",
				type   => "INT",
				enum   => [
					{ name => "1", description => "SNAPSHOT" },
					{ name => "2", description => "SUBSCRIBE" },
					{ name => "4", description => "STOP_SUBSCRIBING" },
					{ name => "8", description => "LEVEL_OF_DETAIL" },
				]
			},
			{ number => "936", name => "NoCompIDs", type => "NUMINGROUP" },
			{
				number => "937",
				name   => "NetworkStatusResponseType",
				type   => "INT",
				enum   => [
					{ name => "1", description => "FULL" },
					{ name => "2", description => "INCREMENTAL_UPDATE" },
				]
			},
			{
				number => "938",
				name   => "NoCollInquiryQualifier",
				type   => "NUMINGROUP"
			},
			{
				number => "939",
				name   => "TrdRptStatus",
				type   => "INT",
				enum   => [
					{ name => "0", description => "ACCEPTED" },
					{ name => "1", description => "REJECTED" },
				]
			},
			{
				number => "940",
				name   => "AffirmStatus",
				type   => "INT",
				enum   => [
					{ name => "1", description => "RECEIVED" },
					{ name => "2", description => "CONFIRM_REJECTED" },
					{ name => "3", description => "AFFIRMED" },
				]
			},
			{
				number => "941",
				name   => "UnderlyingStrikeCurrency",
				type   => "CURRENCY"
			},
			{
				number => "942",
				name   => "LegStrikeCurrency",
				type   => "CURRENCY"
			},
			{ number => "943", name => "TimeBracket", type => "STRING" },
			{
				number => "944",
				name   => "CollAction",
				type   => "INT",
				enum   => [
					{ name => "0", description => "RETAIN" },
					{ name => "1", description => "ADD" },
					{ name => "2", description => "REMOVE" },
				]
			},
			{
				number => "945",
				name   => "CollInquiryStatus",
				type   => "INT",
				enum   => [
					{ name => "0", description => "ACCEPTED" },
					{ name => "1", description => "ACCEPTED_WITH_WARNINGS" },
					{ name => "2", description => "COMPLETED" },
					{ name => "3", description => "COMPLETED_WITH_WARNINGS" },
					{ name => "4", description => "REJECTED" },
				]
			},
			{
				number => "946",
				name   => "CollInquiryResult",
				type   => "INT",
				enum   => [
					{ name => "0", description => "SUCCESSFUL" },
					{
						name        => "1",
						description => "INVALID_OR_UNKNOWN_INSTRUMENT"
					},
					{
						name        => "2",
						description => "INVALID_OR_UNKNOWN_COLLATERAL_TYPE"
					},
					{ name => "3", description => "INVALID_PARTIES" },
					{
						name        => "4",
						description => "INVALID_TRANSPORT_TYPE_REQUESTED"
					},
					{
						name        => "5",
						description => "INVALID_DESTINATION_REQUESTED"
					},
					{
						name => "6",
						description =>
						  "NO_COLLATERAL_FOUND_FOR_THE_TRADE_SPECIFIED"
					},
					{
						name => "7",
						description =>
						  "NO_COLLATERAL_FOUND_FOR_THE_ORDER_SPECIFIED"
					},
					{
						name        => "8",
						description => "COLLATERAL_INQUIRY_TYPE_NOT_SUPPORTED"
					},
					{
						name        => "9",
						description => "UNAUTHORIZED_FOR_COLLATERAL_INQUIRY"
					},
					{ name => "99", description => "OTHER" },
				]
			},
			{ number => "947", name => "StrikeCurrency", type => "CURRENCY" },
			{
				number => "948",
				name   => "NoNested3PartyIDs",
				type   => "NUMINGROUP"
			},
			{ number => "949", name => "Nested3PartyID", type => "STRING" },
			{
				number => "950",
				name   => "Nested3PartyIDSource",
				type   => "CHAR"
			},
			{ number => "951", name => "Nested3PartyRole", type => "INT" },
			{
				number => "952",
				name   => "NoNested3PartySubIDs",
				type   => "NUMINGROUP"
			},
			{
				number => "953",
				name   => "Nested3PartySubID",
				type   => "STRING"
			},
			{
				number => "954",
				name   => "Nested3PartySubIDType",
				type   => "INT"
			},
			{
				number => "955",
				name   => "LegContractSettlMonth",
				type   => "MONTHYEAR"
			},
			{
				number => "956",
				name   => "LegInterestAccrualDate",
				type   => "LOCALMKTDATE"
			},
		],
	};
}

1;

