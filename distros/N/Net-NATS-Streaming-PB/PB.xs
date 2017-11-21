#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif
#ifdef do_open
#undef do_open
#endif
#ifdef do_close
#undef do_close
#endif
#ifdef New
#undef New
#endif
#include <stdint.h>
#include <sstream>
#ifdef Move
#undef Move
#endif
#include "nats_streaming.pb.h"

using namespace std;


typedef ::Net::NATS::Streaming::PB::PubMsg __Net__NATS__Streaming__PB__PubMsg;
typedef ::Net::NATS::Streaming::PB::PubAck __Net__NATS__Streaming__PB__PubAck;
typedef ::Net::NATS::Streaming::PB::MsgProto __Net__NATS__Streaming__PB__MsgProto;
typedef ::Net::NATS::Streaming::PB::Ack __Net__NATS__Streaming__PB__Ack;
typedef ::Net::NATS::Streaming::PB::ConnectRequest __Net__NATS__Streaming__PB__ConnectRequest;
typedef ::Net::NATS::Streaming::PB::ConnectResponse __Net__NATS__Streaming__PB__ConnectResponse;
typedef ::Net::NATS::Streaming::PB::SubscriptionRequest __Net__NATS__Streaming__PB__SubscriptionRequest;
typedef ::Net::NATS::Streaming::PB::SubscriptionResponse __Net__NATS__Streaming__PB__SubscriptionResponse;
typedef ::Net::NATS::Streaming::PB::UnsubscribeRequest __Net__NATS__Streaming__PB__UnsubscribeRequest;
typedef ::Net::NATS::Streaming::PB::CloseRequest __Net__NATS__Streaming__PB__CloseRequest;
typedef ::Net::NATS::Streaming::PB::CloseResponse __Net__NATS__Streaming__PB__CloseResponse;


static ::Net::NATS::Streaming::PB::Ack *
__Net__NATS__Streaming__PB__Ack_from_hashref ( SV * sv0 )
{
  ::Net::NATS::Streaming::PB::Ack * msg0 = new ::Net::NATS::Streaming::PB::Ack;

  if ( SvROK(sv0) && SvTYPE(SvRV(sv0)) == SVt_PVHV ) {
    HV *  hv0 = (HV *)SvRV(sv0);
    SV ** sv1;

    if ( (sv1 = hv_fetch(hv0, "subject", sizeof("subject") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_subject(sval);
    }
    if ( (sv1 = hv_fetch(hv0, "sequence", sizeof("sequence") - 1, 0)) != NULL ) {
      uint64_t uv0 = strtoull(SvPV_nolen(*sv1), NULL, 0);

      msg0->set_sequence(uv0);
    }
  }

  return msg0;
}

static ::Net::NATS::Streaming::PB::CloseRequest *
__Net__NATS__Streaming__PB__CloseRequest_from_hashref ( SV * sv0 )
{
  ::Net::NATS::Streaming::PB::CloseRequest * msg0 = new ::Net::NATS::Streaming::PB::CloseRequest;

  if ( SvROK(sv0) && SvTYPE(SvRV(sv0)) == SVt_PVHV ) {
    HV *  hv0 = (HV *)SvRV(sv0);
    SV ** sv1;

    if ( (sv1 = hv_fetch(hv0, "clientID", sizeof("clientID") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_clientid(sval);
    }
  }

  return msg0;
}

static ::Net::NATS::Streaming::PB::CloseResponse *
__Net__NATS__Streaming__PB__CloseResponse_from_hashref ( SV * sv0 )
{
  ::Net::NATS::Streaming::PB::CloseResponse * msg0 = new ::Net::NATS::Streaming::PB::CloseResponse;

  if ( SvROK(sv0) && SvTYPE(SvRV(sv0)) == SVt_PVHV ) {
    HV *  hv0 = (HV *)SvRV(sv0);
    SV ** sv1;

    if ( (sv1 = hv_fetch(hv0, "error", sizeof("error") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_error(sval);
    }
  }

  return msg0;
}

static ::Net::NATS::Streaming::PB::ConnectRequest *
__Net__NATS__Streaming__PB__ConnectRequest_from_hashref ( SV * sv0 )
{
  ::Net::NATS::Streaming::PB::ConnectRequest * msg0 = new ::Net::NATS::Streaming::PB::ConnectRequest;

  if ( SvROK(sv0) && SvTYPE(SvRV(sv0)) == SVt_PVHV ) {
    HV *  hv0 = (HV *)SvRV(sv0);
    SV ** sv1;

    if ( (sv1 = hv_fetch(hv0, "clientID", sizeof("clientID") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_clientid(sval);
    }
    if ( (sv1 = hv_fetch(hv0, "heartbeatInbox", sizeof("heartbeatInbox") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_heartbeatinbox(sval);
    }
  }

  return msg0;
}

static ::Net::NATS::Streaming::PB::ConnectResponse *
__Net__NATS__Streaming__PB__ConnectResponse_from_hashref ( SV * sv0 )
{
  ::Net::NATS::Streaming::PB::ConnectResponse * msg0 = new ::Net::NATS::Streaming::PB::ConnectResponse;

  if ( SvROK(sv0) && SvTYPE(SvRV(sv0)) == SVt_PVHV ) {
    HV *  hv0 = (HV *)SvRV(sv0);
    SV ** sv1;

    if ( (sv1 = hv_fetch(hv0, "pubPrefix", sizeof("pubPrefix") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_pubprefix(sval);
    }
    if ( (sv1 = hv_fetch(hv0, "subRequests", sizeof("subRequests") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_subrequests(sval);
    }
    if ( (sv1 = hv_fetch(hv0, "unsubRequests", sizeof("unsubRequests") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_unsubrequests(sval);
    }
    if ( (sv1 = hv_fetch(hv0, "closeRequests", sizeof("closeRequests") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_closerequests(sval);
    }
    if ( (sv1 = hv_fetch(hv0, "error", sizeof("error") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_error(sval);
    }
    if ( (sv1 = hv_fetch(hv0, "subCloseRequests", sizeof("subCloseRequests") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_subcloserequests(sval);
    }
    if ( (sv1 = hv_fetch(hv0, "publicKey", sizeof("publicKey") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_publickey(sval);
    }
  }

  return msg0;
}

static ::Net::NATS::Streaming::PB::MsgProto *
__Net__NATS__Streaming__PB__MsgProto_from_hashref ( SV * sv0 )
{
  ::Net::NATS::Streaming::PB::MsgProto * msg0 = new ::Net::NATS::Streaming::PB::MsgProto;

  if ( SvROK(sv0) && SvTYPE(SvRV(sv0)) == SVt_PVHV ) {
    HV *  hv0 = (HV *)SvRV(sv0);
    SV ** sv1;

    if ( (sv1 = hv_fetch(hv0, "sequence", sizeof("sequence") - 1, 0)) != NULL ) {
      uint64_t uv0 = strtoull(SvPV_nolen(*sv1), NULL, 0);

      msg0->set_sequence(uv0);
    }
    if ( (sv1 = hv_fetch(hv0, "subject", sizeof("subject") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_subject(sval);
    }
    if ( (sv1 = hv_fetch(hv0, "reply", sizeof("reply") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_reply(sval);
    }
    if ( (sv1 = hv_fetch(hv0, "data", sizeof("data") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;

      str = SvPV(*sv1, len);
      msg0->set_data(str, len);
    }
    if ( (sv1 = hv_fetch(hv0, "timestamp", sizeof("timestamp") - 1, 0)) != NULL ) {
      int64_t iv0 = strtoll(SvPV_nolen(*sv1), NULL, 0);

      msg0->set_timestamp(iv0);
    }
    if ( (sv1 = hv_fetch(hv0, "redelivered", sizeof("redelivered") - 1, 0)) != NULL ) {
      msg0->set_redelivered(SvIV(*sv1));
    }
    if ( (sv1 = hv_fetch(hv0, "CRC32", sizeof("CRC32") - 1, 0)) != NULL ) {
      msg0->set_crc32(SvUV(*sv1));
    }
  }

  return msg0;
}

static ::Net::NATS::Streaming::PB::PubAck *
__Net__NATS__Streaming__PB__PubAck_from_hashref ( SV * sv0 )
{
  ::Net::NATS::Streaming::PB::PubAck * msg0 = new ::Net::NATS::Streaming::PB::PubAck;

  if ( SvROK(sv0) && SvTYPE(SvRV(sv0)) == SVt_PVHV ) {
    HV *  hv0 = (HV *)SvRV(sv0);
    SV ** sv1;

    if ( (sv1 = hv_fetch(hv0, "guid", sizeof("guid") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_guid(sval);
    }
    if ( (sv1 = hv_fetch(hv0, "error", sizeof("error") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_error(sval);
    }
  }

  return msg0;
}

static ::Net::NATS::Streaming::PB::PubMsg *
__Net__NATS__Streaming__PB__PubMsg_from_hashref ( SV * sv0 )
{
  ::Net::NATS::Streaming::PB::PubMsg * msg0 = new ::Net::NATS::Streaming::PB::PubMsg;

  if ( SvROK(sv0) && SvTYPE(SvRV(sv0)) == SVt_PVHV ) {
    HV *  hv0 = (HV *)SvRV(sv0);
    SV ** sv1;

    if ( (sv1 = hv_fetch(hv0, "clientID", sizeof("clientID") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_clientid(sval);
    }
    if ( (sv1 = hv_fetch(hv0, "guid", sizeof("guid") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_guid(sval);
    }
    if ( (sv1 = hv_fetch(hv0, "subject", sizeof("subject") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_subject(sval);
    }
    if ( (sv1 = hv_fetch(hv0, "reply", sizeof("reply") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_reply(sval);
    }
    if ( (sv1 = hv_fetch(hv0, "data", sizeof("data") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;

      str = SvPV(*sv1, len);
      msg0->set_data(str, len);
    }
    if ( (sv1 = hv_fetch(hv0, "sha256", sizeof("sha256") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;

      str = SvPV(*sv1, len);
      msg0->set_sha256(str, len);
    }
  }

  return msg0;
}

static ::Net::NATS::Streaming::PB::SubscriptionRequest *
__Net__NATS__Streaming__PB__SubscriptionRequest_from_hashref ( SV * sv0 )
{
  ::Net::NATS::Streaming::PB::SubscriptionRequest * msg0 = new ::Net::NATS::Streaming::PB::SubscriptionRequest;

  if ( SvROK(sv0) && SvTYPE(SvRV(sv0)) == SVt_PVHV ) {
    HV *  hv0 = (HV *)SvRV(sv0);
    SV ** sv1;

    if ( (sv1 = hv_fetch(hv0, "clientID", sizeof("clientID") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_clientid(sval);
    }
    if ( (sv1 = hv_fetch(hv0, "subject", sizeof("subject") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_subject(sval);
    }
    if ( (sv1 = hv_fetch(hv0, "qGroup", sizeof("qGroup") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_qgroup(sval);
    }
    if ( (sv1 = hv_fetch(hv0, "inbox", sizeof("inbox") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_inbox(sval);
    }
    if ( (sv1 = hv_fetch(hv0, "maxInFlight", sizeof("maxInFlight") - 1, 0)) != NULL ) {
      msg0->set_maxinflight(SvIV(*sv1));
    }
    if ( (sv1 = hv_fetch(hv0, "ackWaitInSecs", sizeof("ackWaitInSecs") - 1, 0)) != NULL ) {
      msg0->set_ackwaitinsecs(SvIV(*sv1));
    }
    if ( (sv1 = hv_fetch(hv0, "durableName", sizeof("durableName") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_durablename(sval);
    }
    if ( (sv1 = hv_fetch(hv0, "startPosition", sizeof("startPosition") - 1, 0)) != NULL ) {
      msg0->set_startposition((::Net::NATS::Streaming::PB::StartPosition)SvIV(*sv1));
    }
    if ( (sv1 = hv_fetch(hv0, "startSequence", sizeof("startSequence") - 1, 0)) != NULL ) {
      uint64_t uv0 = strtoull(SvPV_nolen(*sv1), NULL, 0);

      msg0->set_startsequence(uv0);
    }
    if ( (sv1 = hv_fetch(hv0, "startTimeDelta", sizeof("startTimeDelta") - 1, 0)) != NULL ) {
      int64_t iv0 = strtoll(SvPV_nolen(*sv1), NULL, 0);

      msg0->set_starttimedelta(iv0);
    }
  }

  return msg0;
}

static ::Net::NATS::Streaming::PB::SubscriptionResponse *
__Net__NATS__Streaming__PB__SubscriptionResponse_from_hashref ( SV * sv0 )
{
  ::Net::NATS::Streaming::PB::SubscriptionResponse * msg0 = new ::Net::NATS::Streaming::PB::SubscriptionResponse;

  if ( SvROK(sv0) && SvTYPE(SvRV(sv0)) == SVt_PVHV ) {
    HV *  hv0 = (HV *)SvRV(sv0);
    SV ** sv1;

    if ( (sv1 = hv_fetch(hv0, "ackInbox", sizeof("ackInbox") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_ackinbox(sval);
    }
    if ( (sv1 = hv_fetch(hv0, "error", sizeof("error") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_error(sval);
    }
  }

  return msg0;
}

static ::Net::NATS::Streaming::PB::UnsubscribeRequest *
__Net__NATS__Streaming__PB__UnsubscribeRequest_from_hashref ( SV * sv0 )
{
  ::Net::NATS::Streaming::PB::UnsubscribeRequest * msg0 = new ::Net::NATS::Streaming::PB::UnsubscribeRequest;

  if ( SvROK(sv0) && SvTYPE(SvRV(sv0)) == SVt_PVHV ) {
    HV *  hv0 = (HV *)SvRV(sv0);
    SV ** sv1;

    if ( (sv1 = hv_fetch(hv0, "clientID", sizeof("clientID") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_clientid(sval);
    }
    if ( (sv1 = hv_fetch(hv0, "subject", sizeof("subject") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_subject(sval);
    }
    if ( (sv1 = hv_fetch(hv0, "inbox", sizeof("inbox") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_inbox(sval);
    }
    if ( (sv1 = hv_fetch(hv0, "durableName", sizeof("durableName") - 1, 0)) != NULL ) {
      STRLEN len;
      char * str;
      string sval;

      str = SvPV(*sv1, len);
      sval.assign(str, len);
      msg0->set_durablename(sval);
    }
  }

  return msg0;
}


MODULE = Net::NATS::Streaming::PB::Ack PACKAGE = Net::NATS::Streaming::PB::Ack
PROTOTYPES: ENABLE


SV *
::Net::NATS::Streaming::PB::Ack::new (...)
  PREINIT:
    ::Net::NATS::Streaming::PB::Ack * rv = NULL;

  CODE:
    if ( strcmp(CLASS,"Net::NATS::Streaming::PB::Ack") ) {
      croak("invalid class %s",CLASS);
    }
    if ( items == 2 && ST(1) != Nullsv ) {
      if ( SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV ) {
        rv = __Net__NATS__Streaming__PB__Ack_from_hashref(ST(1));
      } else {
        STRLEN len;
        char * str;

        rv = new ::Net::NATS::Streaming::PB::Ack;
        str = SvPV(ST(1), len);
        if ( str != NULL ) {
          rv->ParseFromArray(str, len);
        }
      }
    } else {
      rv = new ::Net::NATS::Streaming::PB::Ack;
    }
    RETVAL = newSV(0);
    sv_setref_pv(RETVAL, "Net::NATS::Streaming::PB::Ack", (void *)rv);

  OUTPUT:
    RETVAL


void
DESTROY(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::Ack * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::Ack") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__Ack *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::Ack");
    }
    if ( THIS != NULL ) {
      delete THIS;
    }


void
copy_from(svTHIS, sv)
  SV * svTHIS
  SV * sv
  CODE:
    ::Net::NATS::Streaming::PB::Ack * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::Ack") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__Ack *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::Ack");
    }
    if ( THIS != NULL && sv != NULL ) {
      if ( sv_derived_from(sv, "Net::NATS::Streaming::PB::Ack") ) {
        IV tmp = SvIV((SV *)SvRV(sv));
        ::Net::NATS::Streaming::PB::Ack * other = INT2PTR(__Net__NATS__Streaming__PB__Ack *, tmp);

        THIS->CopyFrom(*other);
      } else if ( SvROK(sv) &&
                  SvTYPE(SvRV(sv)) == SVt_PVHV ) {
        ::Net::NATS::Streaming::PB::Ack * other = __Net__NATS__Streaming__PB__Ack_from_hashref(sv);
        THIS->CopyFrom(*other);
        delete other;
      }
    }


void
merge_from(svTHIS, sv)
  SV * svTHIS
  SV * sv
  CODE:
    ::Net::NATS::Streaming::PB::Ack * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::Ack") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__Ack *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::Ack");
    }
    if ( THIS != NULL && sv != NULL ) {
      if ( sv_derived_from(sv, "Net::NATS::Streaming::PB::Ack") ) {
        IV tmp = SvIV((SV *)SvRV(sv));
        ::Net::NATS::Streaming::PB::Ack * other = INT2PTR(__Net__NATS__Streaming__PB__Ack *, tmp);

        THIS->MergeFrom(*other);
      } else if ( SvROK(sv) &&
                  SvTYPE(SvRV(sv)) == SVt_PVHV ) {
        ::Net::NATS::Streaming::PB::Ack * other = __Net__NATS__Streaming__PB__Ack_from_hashref(sv);
        THIS->MergeFrom(*other);
        delete other;
      }
    }


void
clear(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::Ack * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::Ack") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__Ack *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::Ack");
    }
    if ( THIS != NULL ) {
      THIS->Clear();
    }


int
is_initialized(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::Ack * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::Ack") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__Ack *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::Ack");
    }
    if ( THIS != NULL ) {
      RETVAL = THIS->IsInitialized();
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


SV *
error_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string estr;

  CODE:
    ::Net::NATS::Streaming::PB::Ack * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::Ack") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__Ack *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::Ack");
    }
    if ( THIS != NULL ) {
      estr = THIS->InitializationErrorString();
    }
    RETVAL = newSVpv(estr.c_str(), estr.length());

  OUTPUT:
    RETVAL


void
discard_unkown_fields(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::Ack * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::Ack") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__Ack *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::Ack");
    }
    if ( THIS != NULL ) {
      THIS->DiscardUnknownFields();
    }


SV *
debug_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string dstr;

  CODE:
    ::Net::NATS::Streaming::PB::Ack * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::Ack") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__Ack *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::Ack");
    }
    if ( THIS != NULL ) {
      dstr = THIS->DebugString();
    }
    RETVAL = newSVpv(dstr.c_str(), dstr.length());

  OUTPUT:
    RETVAL


SV *
short_debug_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string dstr;

  CODE:
    ::Net::NATS::Streaming::PB::Ack * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::Ack") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__Ack *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::Ack");
    }
    if ( THIS != NULL ) {
      dstr = THIS->ShortDebugString();
    }
    RETVAL = newSVpv(dstr.c_str(), dstr.length());

  OUTPUT:
    RETVAL


int
unpack(svTHIS, arg)
  SV * svTHIS
  SV * arg
  PREINIT:
    STRLEN len;
    char * str;

  CODE:
    ::Net::NATS::Streaming::PB::Ack * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::Ack") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__Ack *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::Ack");
    }
    if ( THIS != NULL ) {
      str = SvPV(arg, len);
      if ( str != NULL ) {
        RETVAL = THIS->ParseFromArray(str, len);
      } else {
        RETVAL = 0;
      }
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


SV *
pack(svTHIS)
  SV * svTHIS
  PREINIT:
    string output;

  CODE:
    ::Net::NATS::Streaming::PB::Ack * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::Ack") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__Ack *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::Ack");
    }
    if ( THIS != NULL ) {
      if ( THIS->IsInitialized() ) {
        if ( THIS->SerializePartialToString(&output)!= true ) {
          RETVAL = Nullsv;
        } else {
          RETVAL = newSVpvn(output.c_str(), output.length());
        }
      } else {
        croak("Can't serialize message of type 'Net::NATS::Streaming::PB::Ack' because it is missing required fields: %s",
              THIS->InitializationErrorString().c_str());
      }
    } else {
      RETVAL = Nullsv;
    }

  OUTPUT:
    RETVAL


int
length(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::Ack * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::Ack") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__Ack *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::Ack");
    }
    if ( THIS != NULL ) {
      RETVAL = THIS->ByteSize();
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


void
fields(svTHIS)
  SV * svTHIS
  PPCODE:
    (void)svTHIS;
    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newSVpv("subject",0)));
    PUSHs(sv_2mortal(newSVpv("sequence",0)));


SV *
to_hashref(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::Ack * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::Ack") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__Ack *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::Ack");
    }
    if ( THIS != NULL ) {
      HV * hv0 = newHV();
      ::Net::NATS::Streaming::PB::Ack * msg0 = THIS;

      if ( msg0->has_subject() ) {
        SV * sv0 = newSVpv(msg0->subject().c_str(), msg0->subject().length());
        hv_store(hv0, "subject", sizeof("subject") - 1, sv0, 0);
      }
      if ( msg0->has_sequence() ) {
        ostringstream ost0;

        ost0 << msg0->sequence();
        SV * sv0 = newSVpv(ost0.str().c_str(), ost0.str().length());
        hv_store(hv0, "sequence", sizeof("sequence") - 1, sv0, 0);
      }
      RETVAL = newRV_noinc((SV *)hv0);
    } else {
      RETVAL = Nullsv;
    }

  OUTPUT:
    RETVAL


I32
has_subject(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::Ack * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::Ack") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__Ack *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::Ack");
    }
    RETVAL = THIS->has_subject();

  OUTPUT:
    RETVAL


void
clear_subject(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::Ack * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::Ack") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__Ack *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::Ack");
    }
    THIS->clear_subject();


void
subject(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::Ack * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::Ack") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__Ack *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::Ack");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->subject().c_str(),
                              THIS->subject().length()));
      PUSHs(sv);
    }


void
set_subject(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::Ack * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::Ack") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__Ack *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::Ack");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_subject(sval);


I32
has_sequence(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::Ack * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::Ack") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__Ack *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::Ack");
    }
    RETVAL = THIS->has_sequence();

  OUTPUT:
    RETVAL


void
clear_sequence(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::Ack * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::Ack") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__Ack *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::Ack");
    }
    THIS->clear_sequence();


void
sequence(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;
    ostringstream ost;

  PPCODE:
    ::Net::NATS::Streaming::PB::Ack * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::Ack") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__Ack *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::Ack");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      ost.str("");
      ost << THIS->sequence();
      sv = sv_2mortal(newSVpv(ost.str().c_str(),
                              ost.str().length()));
      PUSHs(sv);
    }


void
set_sequence(svTHIS, svVAL)
  SV * svTHIS
  char *svVAL

  PREINIT:
    unsigned long long lval;

  CODE:
    lval = strtoull((svVAL) ? svVAL : "", NULL, 0);
    ::Net::NATS::Streaming::PB::Ack * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::Ack") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__Ack *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::Ack");
    }
    THIS->set_sequence(lval);





MODULE = Net::NATS::Streaming::PB::CloseRequest PACKAGE = Net::NATS::Streaming::PB::CloseRequest
PROTOTYPES: ENABLE


SV *
::Net::NATS::Streaming::PB::CloseRequest::new (...)
  PREINIT:
    ::Net::NATS::Streaming::PB::CloseRequest * rv = NULL;

  CODE:
    if ( strcmp(CLASS,"Net::NATS::Streaming::PB::CloseRequest") ) {
      croak("invalid class %s",CLASS);
    }
    if ( items == 2 && ST(1) != Nullsv ) {
      if ( SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV ) {
        rv = __Net__NATS__Streaming__PB__CloseRequest_from_hashref(ST(1));
      } else {
        STRLEN len;
        char * str;

        rv = new ::Net::NATS::Streaming::PB::CloseRequest;
        str = SvPV(ST(1), len);
        if ( str != NULL ) {
          rv->ParseFromArray(str, len);
        }
      }
    } else {
      rv = new ::Net::NATS::Streaming::PB::CloseRequest;
    }
    RETVAL = newSV(0);
    sv_setref_pv(RETVAL, "Net::NATS::Streaming::PB::CloseRequest", (void *)rv);

  OUTPUT:
    RETVAL


void
DESTROY(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::CloseRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseRequest");
    }
    if ( THIS != NULL ) {
      delete THIS;
    }


void
copy_from(svTHIS, sv)
  SV * svTHIS
  SV * sv
  CODE:
    ::Net::NATS::Streaming::PB::CloseRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseRequest");
    }
    if ( THIS != NULL && sv != NULL ) {
      if ( sv_derived_from(sv, "Net::NATS::Streaming::PB::CloseRequest") ) {
        IV tmp = SvIV((SV *)SvRV(sv));
        ::Net::NATS::Streaming::PB::CloseRequest * other = INT2PTR(__Net__NATS__Streaming__PB__CloseRequest *, tmp);

        THIS->CopyFrom(*other);
      } else if ( SvROK(sv) &&
                  SvTYPE(SvRV(sv)) == SVt_PVHV ) {
        ::Net::NATS::Streaming::PB::CloseRequest * other = __Net__NATS__Streaming__PB__CloseRequest_from_hashref(sv);
        THIS->CopyFrom(*other);
        delete other;
      }
    }


void
merge_from(svTHIS, sv)
  SV * svTHIS
  SV * sv
  CODE:
    ::Net::NATS::Streaming::PB::CloseRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseRequest");
    }
    if ( THIS != NULL && sv != NULL ) {
      if ( sv_derived_from(sv, "Net::NATS::Streaming::PB::CloseRequest") ) {
        IV tmp = SvIV((SV *)SvRV(sv));
        ::Net::NATS::Streaming::PB::CloseRequest * other = INT2PTR(__Net__NATS__Streaming__PB__CloseRequest *, tmp);

        THIS->MergeFrom(*other);
      } else if ( SvROK(sv) &&
                  SvTYPE(SvRV(sv)) == SVt_PVHV ) {
        ::Net::NATS::Streaming::PB::CloseRequest * other = __Net__NATS__Streaming__PB__CloseRequest_from_hashref(sv);
        THIS->MergeFrom(*other);
        delete other;
      }
    }


void
clear(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::CloseRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseRequest");
    }
    if ( THIS != NULL ) {
      THIS->Clear();
    }


int
is_initialized(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::CloseRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseRequest");
    }
    if ( THIS != NULL ) {
      RETVAL = THIS->IsInitialized();
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


SV *
error_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string estr;

  CODE:
    ::Net::NATS::Streaming::PB::CloseRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseRequest");
    }
    if ( THIS != NULL ) {
      estr = THIS->InitializationErrorString();
    }
    RETVAL = newSVpv(estr.c_str(), estr.length());

  OUTPUT:
    RETVAL


void
discard_unkown_fields(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::CloseRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseRequest");
    }
    if ( THIS != NULL ) {
      THIS->DiscardUnknownFields();
    }


SV *
debug_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string dstr;

  CODE:
    ::Net::NATS::Streaming::PB::CloseRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseRequest");
    }
    if ( THIS != NULL ) {
      dstr = THIS->DebugString();
    }
    RETVAL = newSVpv(dstr.c_str(), dstr.length());

  OUTPUT:
    RETVAL


SV *
short_debug_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string dstr;

  CODE:
    ::Net::NATS::Streaming::PB::CloseRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseRequest");
    }
    if ( THIS != NULL ) {
      dstr = THIS->ShortDebugString();
    }
    RETVAL = newSVpv(dstr.c_str(), dstr.length());

  OUTPUT:
    RETVAL


int
unpack(svTHIS, arg)
  SV * svTHIS
  SV * arg
  PREINIT:
    STRLEN len;
    char * str;

  CODE:
    ::Net::NATS::Streaming::PB::CloseRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseRequest");
    }
    if ( THIS != NULL ) {
      str = SvPV(arg, len);
      if ( str != NULL ) {
        RETVAL = THIS->ParseFromArray(str, len);
      } else {
        RETVAL = 0;
      }
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


SV *
pack(svTHIS)
  SV * svTHIS
  PREINIT:
    string output;

  CODE:
    ::Net::NATS::Streaming::PB::CloseRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseRequest");
    }
    if ( THIS != NULL ) {
      if ( THIS->IsInitialized() ) {
        if ( THIS->SerializePartialToString(&output)!= true ) {
          RETVAL = Nullsv;
        } else {
          RETVAL = newSVpvn(output.c_str(), output.length());
        }
      } else {
        croak("Can't serialize message of type 'Net::NATS::Streaming::PB::CloseRequest' because it is missing required fields: %s",
              THIS->InitializationErrorString().c_str());
      }
    } else {
      RETVAL = Nullsv;
    }

  OUTPUT:
    RETVAL


int
length(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::CloseRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseRequest");
    }
    if ( THIS != NULL ) {
      RETVAL = THIS->ByteSize();
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


void
fields(svTHIS)
  SV * svTHIS
  PPCODE:
    (void)svTHIS;
    EXTEND(SP, 1);
    PUSHs(sv_2mortal(newSVpv("clientID",0)));


SV *
to_hashref(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::CloseRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseRequest");
    }
    if ( THIS != NULL ) {
      HV * hv0 = newHV();
      ::Net::NATS::Streaming::PB::CloseRequest * msg0 = THIS;

      if ( msg0->has_clientid() ) {
        SV * sv0 = newSVpv(msg0->clientid().c_str(), msg0->clientid().length());
        hv_store(hv0, "clientID", sizeof("clientID") - 1, sv0, 0);
      }
      RETVAL = newRV_noinc((SV *)hv0);
    } else {
      RETVAL = Nullsv;
    }

  OUTPUT:
    RETVAL


I32
has_clientID(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::CloseRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseRequest");
    }
    RETVAL = THIS->has_clientid();

  OUTPUT:
    RETVAL


void
clear_clientID(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::CloseRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseRequest");
    }
    THIS->clear_clientid();


void
clientID(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::CloseRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseRequest");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->clientid().c_str(),
                              THIS->clientid().length()));
      PUSHs(sv);
    }


void
set_clientID(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::CloseRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseRequest");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_clientid(sval);

MODULE = Net::NATS::Streaming::PB::CloseResponse PACKAGE = Net::NATS::Streaming::PB::CloseResponse
PROTOTYPES: ENABLE


SV *
::Net::NATS::Streaming::PB::CloseResponse::new (...)
  PREINIT:
    ::Net::NATS::Streaming::PB::CloseResponse * rv = NULL;

  CODE:
    if ( strcmp(CLASS,"Net::NATS::Streaming::PB::CloseResponse") ) {
      croak("invalid class %s",CLASS);
    }
    if ( items == 2 && ST(1) != Nullsv ) {
      if ( SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV ) {
        rv = __Net__NATS__Streaming__PB__CloseResponse_from_hashref(ST(1));
      } else {
        STRLEN len;
        char * str;

        rv = new ::Net::NATS::Streaming::PB::CloseResponse;
        str = SvPV(ST(1), len);
        if ( str != NULL ) {
          rv->ParseFromArray(str, len);
        }
      }
    } else {
      rv = new ::Net::NATS::Streaming::PB::CloseResponse;
    }
    RETVAL = newSV(0);
    sv_setref_pv(RETVAL, "Net::NATS::Streaming::PB::CloseResponse", (void *)rv);

  OUTPUT:
    RETVAL


void
DESTROY(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::CloseResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseResponse");
    }
    if ( THIS != NULL ) {
      delete THIS;
    }


void
copy_from(svTHIS, sv)
  SV * svTHIS
  SV * sv
  CODE:
    ::Net::NATS::Streaming::PB::CloseResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseResponse");
    }
    if ( THIS != NULL && sv != NULL ) {
      if ( sv_derived_from(sv, "Net::NATS::Streaming::PB::CloseResponse") ) {
        IV tmp = SvIV((SV *)SvRV(sv));
        ::Net::NATS::Streaming::PB::CloseResponse * other = INT2PTR(__Net__NATS__Streaming__PB__CloseResponse *, tmp);

        THIS->CopyFrom(*other);
      } else if ( SvROK(sv) &&
                  SvTYPE(SvRV(sv)) == SVt_PVHV ) {
        ::Net::NATS::Streaming::PB::CloseResponse * other = __Net__NATS__Streaming__PB__CloseResponse_from_hashref(sv);
        THIS->CopyFrom(*other);
        delete other;
      }
    }


void
merge_from(svTHIS, sv)
  SV * svTHIS
  SV * sv
  CODE:
    ::Net::NATS::Streaming::PB::CloseResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseResponse");
    }
    if ( THIS != NULL && sv != NULL ) {
      if ( sv_derived_from(sv, "Net::NATS::Streaming::PB::CloseResponse") ) {
        IV tmp = SvIV((SV *)SvRV(sv));
        ::Net::NATS::Streaming::PB::CloseResponse * other = INT2PTR(__Net__NATS__Streaming__PB__CloseResponse *, tmp);

        THIS->MergeFrom(*other);
      } else if ( SvROK(sv) &&
                  SvTYPE(SvRV(sv)) == SVt_PVHV ) {
        ::Net::NATS::Streaming::PB::CloseResponse * other = __Net__NATS__Streaming__PB__CloseResponse_from_hashref(sv);
        THIS->MergeFrom(*other);
        delete other;
      }
    }


void
clear(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::CloseResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseResponse");
    }
    if ( THIS != NULL ) {
      THIS->Clear();
    }


int
is_initialized(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::CloseResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseResponse");
    }
    if ( THIS != NULL ) {
      RETVAL = THIS->IsInitialized();
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


SV *
error_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string estr;

  CODE:
    ::Net::NATS::Streaming::PB::CloseResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseResponse");
    }
    if ( THIS != NULL ) {
      estr = THIS->InitializationErrorString();
    }
    RETVAL = newSVpv(estr.c_str(), estr.length());

  OUTPUT:
    RETVAL


void
discard_unkown_fields(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::CloseResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseResponse");
    }
    if ( THIS != NULL ) {
      THIS->DiscardUnknownFields();
    }


SV *
debug_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string dstr;

  CODE:
    ::Net::NATS::Streaming::PB::CloseResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseResponse");
    }
    if ( THIS != NULL ) {
      dstr = THIS->DebugString();
    }
    RETVAL = newSVpv(dstr.c_str(), dstr.length());

  OUTPUT:
    RETVAL


SV *
short_debug_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string dstr;

  CODE:
    ::Net::NATS::Streaming::PB::CloseResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseResponse");
    }
    if ( THIS != NULL ) {
      dstr = THIS->ShortDebugString();
    }
    RETVAL = newSVpv(dstr.c_str(), dstr.length());

  OUTPUT:
    RETVAL


int
unpack(svTHIS, arg)
  SV * svTHIS
  SV * arg
  PREINIT:
    STRLEN len;
    char * str;

  CODE:
    ::Net::NATS::Streaming::PB::CloseResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseResponse");
    }
    if ( THIS != NULL ) {
      str = SvPV(arg, len);
      if ( str != NULL ) {
        RETVAL = THIS->ParseFromArray(str, len);
      } else {
        RETVAL = 0;
      }
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


SV *
pack(svTHIS)
  SV * svTHIS
  PREINIT:
    string output;

  CODE:
    ::Net::NATS::Streaming::PB::CloseResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseResponse");
    }
    if ( THIS != NULL ) {
      if ( THIS->IsInitialized() ) {
        if ( THIS->SerializePartialToString(&output)!= true ) {
          RETVAL = Nullsv;
        } else {
          RETVAL = newSVpvn(output.c_str(), output.length());
        }
      } else {
        croak("Can't serialize message of type 'Net::NATS::Streaming::PB::CloseResponse' because it is missing required fields: %s",
              THIS->InitializationErrorString().c_str());
      }
    } else {
      RETVAL = Nullsv;
    }

  OUTPUT:
    RETVAL


int
length(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::CloseResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseResponse");
    }
    if ( THIS != NULL ) {
      RETVAL = THIS->ByteSize();
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


void
fields(svTHIS)
  SV * svTHIS
  PPCODE:
    (void)svTHIS;
    EXTEND(SP, 1);
    PUSHs(sv_2mortal(newSVpv("error",0)));


SV *
to_hashref(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::CloseResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseResponse");
    }
    if ( THIS != NULL ) {
      HV * hv0 = newHV();
      ::Net::NATS::Streaming::PB::CloseResponse * msg0 = THIS;

      if ( msg0->has_error() ) {
        SV * sv0 = newSVpv(msg0->error().c_str(), msg0->error().length());
        hv_store(hv0, "error", sizeof("error") - 1, sv0, 0);
      }
      RETVAL = newRV_noinc((SV *)hv0);
    } else {
      RETVAL = Nullsv;
    }

  OUTPUT:
    RETVAL


I32
has_error(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::CloseResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseResponse");
    }
    RETVAL = THIS->has_error();

  OUTPUT:
    RETVAL


void
clear_error(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::CloseResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseResponse");
    }
    THIS->clear_error();


void
error(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::CloseResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseResponse");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->error().c_str(),
                              THIS->error().length()));
      PUSHs(sv);
    }


void
set_error(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::CloseResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::CloseResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__CloseResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::CloseResponse");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_error(sval);

MODULE = Net::NATS::Streaming::PB::ConnectRequest PACKAGE = Net::NATS::Streaming::PB::ConnectRequest
PROTOTYPES: ENABLE


SV *
::Net::NATS::Streaming::PB::ConnectRequest::new (...)
  PREINIT:
    ::Net::NATS::Streaming::PB::ConnectRequest * rv = NULL;

  CODE:
    if ( strcmp(CLASS,"Net::NATS::Streaming::PB::ConnectRequest") ) {
      croak("invalid class %s",CLASS);
    }
    if ( items == 2 && ST(1) != Nullsv ) {
      if ( SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV ) {
        rv = __Net__NATS__Streaming__PB__ConnectRequest_from_hashref(ST(1));
      } else {
        STRLEN len;
        char * str;

        rv = new ::Net::NATS::Streaming::PB::ConnectRequest;
        str = SvPV(ST(1), len);
        if ( str != NULL ) {
          rv->ParseFromArray(str, len);
        }
      }
    } else {
      rv = new ::Net::NATS::Streaming::PB::ConnectRequest;
    }
    RETVAL = newSV(0);
    sv_setref_pv(RETVAL, "Net::NATS::Streaming::PB::ConnectRequest", (void *)rv);

  OUTPUT:
    RETVAL


void
DESTROY(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::ConnectRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectRequest");
    }
    if ( THIS != NULL ) {
      delete THIS;
    }


void
copy_from(svTHIS, sv)
  SV * svTHIS
  SV * sv
  CODE:
    ::Net::NATS::Streaming::PB::ConnectRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectRequest");
    }
    if ( THIS != NULL && sv != NULL ) {
      if ( sv_derived_from(sv, "Net::NATS::Streaming::PB::ConnectRequest") ) {
        IV tmp = SvIV((SV *)SvRV(sv));
        ::Net::NATS::Streaming::PB::ConnectRequest * other = INT2PTR(__Net__NATS__Streaming__PB__ConnectRequest *, tmp);

        THIS->CopyFrom(*other);
      } else if ( SvROK(sv) &&
                  SvTYPE(SvRV(sv)) == SVt_PVHV ) {
        ::Net::NATS::Streaming::PB::ConnectRequest * other = __Net__NATS__Streaming__PB__ConnectRequest_from_hashref(sv);
        THIS->CopyFrom(*other);
        delete other;
      }
    }


void
merge_from(svTHIS, sv)
  SV * svTHIS
  SV * sv
  CODE:
    ::Net::NATS::Streaming::PB::ConnectRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectRequest");
    }
    if ( THIS != NULL && sv != NULL ) {
      if ( sv_derived_from(sv, "Net::NATS::Streaming::PB::ConnectRequest") ) {
        IV tmp = SvIV((SV *)SvRV(sv));
        ::Net::NATS::Streaming::PB::ConnectRequest * other = INT2PTR(__Net__NATS__Streaming__PB__ConnectRequest *, tmp);

        THIS->MergeFrom(*other);
      } else if ( SvROK(sv) &&
                  SvTYPE(SvRV(sv)) == SVt_PVHV ) {
        ::Net::NATS::Streaming::PB::ConnectRequest * other = __Net__NATS__Streaming__PB__ConnectRequest_from_hashref(sv);
        THIS->MergeFrom(*other);
        delete other;
      }
    }


void
clear(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::ConnectRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectRequest");
    }
    if ( THIS != NULL ) {
      THIS->Clear();
    }


int
is_initialized(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::ConnectRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectRequest");
    }
    if ( THIS != NULL ) {
      RETVAL = THIS->IsInitialized();
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


SV *
error_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string estr;

  CODE:
    ::Net::NATS::Streaming::PB::ConnectRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectRequest");
    }
    if ( THIS != NULL ) {
      estr = THIS->InitializationErrorString();
    }
    RETVAL = newSVpv(estr.c_str(), estr.length());

  OUTPUT:
    RETVAL


void
discard_unkown_fields(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::ConnectRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectRequest");
    }
    if ( THIS != NULL ) {
      THIS->DiscardUnknownFields();
    }


SV *
debug_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string dstr;

  CODE:
    ::Net::NATS::Streaming::PB::ConnectRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectRequest");
    }
    if ( THIS != NULL ) {
      dstr = THIS->DebugString();
    }
    RETVAL = newSVpv(dstr.c_str(), dstr.length());

  OUTPUT:
    RETVAL


SV *
short_debug_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string dstr;

  CODE:
    ::Net::NATS::Streaming::PB::ConnectRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectRequest");
    }
    if ( THIS != NULL ) {
      dstr = THIS->ShortDebugString();
    }
    RETVAL = newSVpv(dstr.c_str(), dstr.length());

  OUTPUT:
    RETVAL


int
unpack(svTHIS, arg)
  SV * svTHIS
  SV * arg
  PREINIT:
    STRLEN len;
    char * str;

  CODE:
    ::Net::NATS::Streaming::PB::ConnectRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectRequest");
    }
    if ( THIS != NULL ) {
      str = SvPV(arg, len);
      if ( str != NULL ) {
        RETVAL = THIS->ParseFromArray(str, len);
      } else {
        RETVAL = 0;
      }
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


SV *
pack(svTHIS)
  SV * svTHIS
  PREINIT:
    string output;

  CODE:
    ::Net::NATS::Streaming::PB::ConnectRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectRequest");
    }
    if ( THIS != NULL ) {
      if ( THIS->IsInitialized() ) {
        if ( THIS->SerializePartialToString(&output)!= true ) {
          RETVAL = Nullsv;
        } else {
          RETVAL = newSVpvn(output.c_str(), output.length());
        }
      } else {
        croak("Can't serialize message of type 'Net::NATS::Streaming::PB::ConnectRequest' because it is missing required fields: %s",
              THIS->InitializationErrorString().c_str());
      }
    } else {
      RETVAL = Nullsv;
    }

  OUTPUT:
    RETVAL


int
length(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::ConnectRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectRequest");
    }
    if ( THIS != NULL ) {
      RETVAL = THIS->ByteSize();
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


void
fields(svTHIS)
  SV * svTHIS
  PPCODE:
    (void)svTHIS;
    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newSVpv("clientID",0)));
    PUSHs(sv_2mortal(newSVpv("heartbeatInbox",0)));


SV *
to_hashref(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::ConnectRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectRequest");
    }
    if ( THIS != NULL ) {
      HV * hv0 = newHV();
      ::Net::NATS::Streaming::PB::ConnectRequest * msg0 = THIS;

      if ( msg0->has_clientid() ) {
        SV * sv0 = newSVpv(msg0->clientid().c_str(), msg0->clientid().length());
        hv_store(hv0, "clientID", sizeof("clientID") - 1, sv0, 0);
      }
      if ( msg0->has_heartbeatinbox() ) {
        SV * sv0 = newSVpv(msg0->heartbeatinbox().c_str(), msg0->heartbeatinbox().length());
        hv_store(hv0, "heartbeatInbox", sizeof("heartbeatInbox") - 1, sv0, 0);
      }
      RETVAL = newRV_noinc((SV *)hv0);
    } else {
      RETVAL = Nullsv;
    }

  OUTPUT:
    RETVAL


I32
has_clientID(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::ConnectRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectRequest");
    }
    RETVAL = THIS->has_clientid();

  OUTPUT:
    RETVAL


void
clear_clientID(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::ConnectRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectRequest");
    }
    THIS->clear_clientid();


void
clientID(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::ConnectRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectRequest");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->clientid().c_str(),
                              THIS->clientid().length()));
      PUSHs(sv);
    }


void
set_clientID(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::ConnectRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectRequest");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_clientid(sval);


I32
has_heartbeatInbox(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::ConnectRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectRequest");
    }
    RETVAL = THIS->has_heartbeatinbox();

  OUTPUT:
    RETVAL


void
clear_heartbeatInbox(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::ConnectRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectRequest");
    }
    THIS->clear_heartbeatinbox();


void
heartbeatInbox(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::ConnectRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectRequest");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->heartbeatinbox().c_str(),
                              THIS->heartbeatinbox().length()));
      PUSHs(sv);
    }


void
set_heartbeatInbox(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::ConnectRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectRequest");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_heartbeatinbox(sval);

MODULE = Net::NATS::Streaming::PB::ConnectResponse PACKAGE = Net::NATS::Streaming::PB::ConnectResponse
PROTOTYPES: ENABLE


SV *
::Net::NATS::Streaming::PB::ConnectResponse::new (...)
  PREINIT:
    ::Net::NATS::Streaming::PB::ConnectResponse * rv = NULL;

  CODE:
    if ( strcmp(CLASS,"Net::NATS::Streaming::PB::ConnectResponse") ) {
      croak("invalid class %s",CLASS);
    }
    if ( items == 2 && ST(1) != Nullsv ) {
      if ( SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV ) {
        rv = __Net__NATS__Streaming__PB__ConnectResponse_from_hashref(ST(1));
      } else {
        STRLEN len;
        char * str;

        rv = new ::Net::NATS::Streaming::PB::ConnectResponse;
        str = SvPV(ST(1), len);
        if ( str != NULL ) {
          rv->ParseFromArray(str, len);
        }
      }
    } else {
      rv = new ::Net::NATS::Streaming::PB::ConnectResponse;
    }
    RETVAL = newSV(0);
    sv_setref_pv(RETVAL, "Net::NATS::Streaming::PB::ConnectResponse", (void *)rv);

  OUTPUT:
    RETVAL


void
DESTROY(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    if ( THIS != NULL ) {
      delete THIS;
    }


void
copy_from(svTHIS, sv)
  SV * svTHIS
  SV * sv
  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    if ( THIS != NULL && sv != NULL ) {
      if ( sv_derived_from(sv, "Net::NATS::Streaming::PB::ConnectResponse") ) {
        IV tmp = SvIV((SV *)SvRV(sv));
        ::Net::NATS::Streaming::PB::ConnectResponse * other = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);

        THIS->CopyFrom(*other);
      } else if ( SvROK(sv) &&
                  SvTYPE(SvRV(sv)) == SVt_PVHV ) {
        ::Net::NATS::Streaming::PB::ConnectResponse * other = __Net__NATS__Streaming__PB__ConnectResponse_from_hashref(sv);
        THIS->CopyFrom(*other);
        delete other;
      }
    }


void
merge_from(svTHIS, sv)
  SV * svTHIS
  SV * sv
  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    if ( THIS != NULL && sv != NULL ) {
      if ( sv_derived_from(sv, "Net::NATS::Streaming::PB::ConnectResponse") ) {
        IV tmp = SvIV((SV *)SvRV(sv));
        ::Net::NATS::Streaming::PB::ConnectResponse * other = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);

        THIS->MergeFrom(*other);
      } else if ( SvROK(sv) &&
                  SvTYPE(SvRV(sv)) == SVt_PVHV ) {
        ::Net::NATS::Streaming::PB::ConnectResponse * other = __Net__NATS__Streaming__PB__ConnectResponse_from_hashref(sv);
        THIS->MergeFrom(*other);
        delete other;
      }
    }


void
clear(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    if ( THIS != NULL ) {
      THIS->Clear();
    }


int
is_initialized(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    if ( THIS != NULL ) {
      RETVAL = THIS->IsInitialized();
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


SV *
error_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string estr;

  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    if ( THIS != NULL ) {
      estr = THIS->InitializationErrorString();
    }
    RETVAL = newSVpv(estr.c_str(), estr.length());

  OUTPUT:
    RETVAL


void
discard_unkown_fields(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    if ( THIS != NULL ) {
      THIS->DiscardUnknownFields();
    }


SV *
debug_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string dstr;

  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    if ( THIS != NULL ) {
      dstr = THIS->DebugString();
    }
    RETVAL = newSVpv(dstr.c_str(), dstr.length());

  OUTPUT:
    RETVAL


SV *
short_debug_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string dstr;

  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    if ( THIS != NULL ) {
      dstr = THIS->ShortDebugString();
    }
    RETVAL = newSVpv(dstr.c_str(), dstr.length());

  OUTPUT:
    RETVAL


int
unpack(svTHIS, arg)
  SV * svTHIS
  SV * arg
  PREINIT:
    STRLEN len;
    char * str;

  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    if ( THIS != NULL ) {
      str = SvPV(arg, len);
      if ( str != NULL ) {
        RETVAL = THIS->ParseFromArray(str, len);
      } else {
        RETVAL = 0;
      }
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


SV *
pack(svTHIS)
  SV * svTHIS
  PREINIT:
    string output;

  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    if ( THIS != NULL ) {
      if ( THIS->IsInitialized() ) {
        if ( THIS->SerializePartialToString(&output)!= true ) {
          RETVAL = Nullsv;
        } else {
          RETVAL = newSVpvn(output.c_str(), output.length());
        }
      } else {
        croak("Can't serialize message of type 'Net::NATS::Streaming::PB::ConnectResponse' because it is missing required fields: %s",
              THIS->InitializationErrorString().c_str());
      }
    } else {
      RETVAL = Nullsv;
    }

  OUTPUT:
    RETVAL


int
length(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    if ( THIS != NULL ) {
      RETVAL = THIS->ByteSize();
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


void
fields(svTHIS)
  SV * svTHIS
  PPCODE:
    (void)svTHIS;
    EXTEND(SP, 7);
    PUSHs(sv_2mortal(newSVpv("pubPrefix",0)));
    PUSHs(sv_2mortal(newSVpv("subRequests",0)));
    PUSHs(sv_2mortal(newSVpv("unsubRequests",0)));
    PUSHs(sv_2mortal(newSVpv("closeRequests",0)));
    PUSHs(sv_2mortal(newSVpv("error",0)));
    PUSHs(sv_2mortal(newSVpv("subCloseRequests",0)));
    PUSHs(sv_2mortal(newSVpv("publicKey",0)));


SV *
to_hashref(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    if ( THIS != NULL ) {
      HV * hv0 = newHV();
      ::Net::NATS::Streaming::PB::ConnectResponse * msg0 = THIS;

      if ( msg0->has_pubprefix() ) {
        SV * sv0 = newSVpv(msg0->pubprefix().c_str(), msg0->pubprefix().length());
        hv_store(hv0, "pubPrefix", sizeof("pubPrefix") - 1, sv0, 0);
      }
      if ( msg0->has_subrequests() ) {
        SV * sv0 = newSVpv(msg0->subrequests().c_str(), msg0->subrequests().length());
        hv_store(hv0, "subRequests", sizeof("subRequests") - 1, sv0, 0);
      }
      if ( msg0->has_unsubrequests() ) {
        SV * sv0 = newSVpv(msg0->unsubrequests().c_str(), msg0->unsubrequests().length());
        hv_store(hv0, "unsubRequests", sizeof("unsubRequests") - 1, sv0, 0);
      }
      if ( msg0->has_closerequests() ) {
        SV * sv0 = newSVpv(msg0->closerequests().c_str(), msg0->closerequests().length());
        hv_store(hv0, "closeRequests", sizeof("closeRequests") - 1, sv0, 0);
      }
      if ( msg0->has_error() ) {
        SV * sv0 = newSVpv(msg0->error().c_str(), msg0->error().length());
        hv_store(hv0, "error", sizeof("error") - 1, sv0, 0);
      }
      if ( msg0->has_subcloserequests() ) {
        SV * sv0 = newSVpv(msg0->subcloserequests().c_str(), msg0->subcloserequests().length());
        hv_store(hv0, "subCloseRequests", sizeof("subCloseRequests") - 1, sv0, 0);
      }
      if ( msg0->has_publickey() ) {
        SV * sv0 = newSVpv(msg0->publickey().c_str(), msg0->publickey().length());
        hv_store(hv0, "publicKey", sizeof("publicKey") - 1, sv0, 0);
      }
      RETVAL = newRV_noinc((SV *)hv0);
    } else {
      RETVAL = Nullsv;
    }

  OUTPUT:
    RETVAL


I32
has_pubPrefix(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    RETVAL = THIS->has_pubprefix();

  OUTPUT:
    RETVAL


void
clear_pubPrefix(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    THIS->clear_pubprefix();


void
pubPrefix(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->pubprefix().c_str(),
                              THIS->pubprefix().length()));
      PUSHs(sv);
    }


void
set_pubPrefix(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_pubprefix(sval);


I32
has_subRequests(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    RETVAL = THIS->has_subrequests();

  OUTPUT:
    RETVAL


void
clear_subRequests(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    THIS->clear_subrequests();


void
subRequests(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->subrequests().c_str(),
                              THIS->subrequests().length()));
      PUSHs(sv);
    }


void
set_subRequests(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_subrequests(sval);


I32
has_unsubRequests(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    RETVAL = THIS->has_unsubrequests();

  OUTPUT:
    RETVAL


void
clear_unsubRequests(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    THIS->clear_unsubrequests();


void
unsubRequests(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->unsubrequests().c_str(),
                              THIS->unsubrequests().length()));
      PUSHs(sv);
    }


void
set_unsubRequests(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_unsubrequests(sval);


I32
has_closeRequests(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    RETVAL = THIS->has_closerequests();

  OUTPUT:
    RETVAL


void
clear_closeRequests(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    THIS->clear_closerequests();


void
closeRequests(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->closerequests().c_str(),
                              THIS->closerequests().length()));
      PUSHs(sv);
    }


void
set_closeRequests(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_closerequests(sval);


I32
has_error(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    RETVAL = THIS->has_error();

  OUTPUT:
    RETVAL


void
clear_error(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    THIS->clear_error();


void
error(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->error().c_str(),
                              THIS->error().length()));
      PUSHs(sv);
    }


void
set_error(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_error(sval);


I32
has_subCloseRequests(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    RETVAL = THIS->has_subcloserequests();

  OUTPUT:
    RETVAL


void
clear_subCloseRequests(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    THIS->clear_subcloserequests();


void
subCloseRequests(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->subcloserequests().c_str(),
                              THIS->subcloserequests().length()));
      PUSHs(sv);
    }


void
set_subCloseRequests(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_subcloserequests(sval);


I32
has_publicKey(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    RETVAL = THIS->has_publickey();

  OUTPUT:
    RETVAL


void
clear_publicKey(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    THIS->clear_publickey();


void
publicKey(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->publickey().c_str(),
                              THIS->publickey().length()));
      PUSHs(sv);
    }


void
set_publicKey(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::ConnectResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::ConnectResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__ConnectResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::ConnectResponse");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_publickey(sval);

MODULE = Net::NATS::Streaming::PB::MsgProto PACKAGE = Net::NATS::Streaming::PB::MsgProto
PROTOTYPES: ENABLE


SV *
::Net::NATS::Streaming::PB::MsgProto::new (...)
  PREINIT:
    ::Net::NATS::Streaming::PB::MsgProto * rv = NULL;

  CODE:
    if ( strcmp(CLASS,"Net::NATS::Streaming::PB::MsgProto") ) {
      croak("invalid class %s",CLASS);
    }
    if ( items == 2 && ST(1) != Nullsv ) {
      if ( SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV ) {
        rv = __Net__NATS__Streaming__PB__MsgProto_from_hashref(ST(1));
      } else {
        STRLEN len;
        char * str;

        rv = new ::Net::NATS::Streaming::PB::MsgProto;
        str = SvPV(ST(1), len);
        if ( str != NULL ) {
          rv->ParseFromArray(str, len);
        }
      }
    } else {
      rv = new ::Net::NATS::Streaming::PB::MsgProto;
    }
    RETVAL = newSV(0);
    sv_setref_pv(RETVAL, "Net::NATS::Streaming::PB::MsgProto", (void *)rv);

  OUTPUT:
    RETVAL


void
DESTROY(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    if ( THIS != NULL ) {
      delete THIS;
    }


void
copy_from(svTHIS, sv)
  SV * svTHIS
  SV * sv
  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    if ( THIS != NULL && sv != NULL ) {
      if ( sv_derived_from(sv, "Net::NATS::Streaming::PB::MsgProto") ) {
        IV tmp = SvIV((SV *)SvRV(sv));
        ::Net::NATS::Streaming::PB::MsgProto * other = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);

        THIS->CopyFrom(*other);
      } else if ( SvROK(sv) &&
                  SvTYPE(SvRV(sv)) == SVt_PVHV ) {
        ::Net::NATS::Streaming::PB::MsgProto * other = __Net__NATS__Streaming__PB__MsgProto_from_hashref(sv);
        THIS->CopyFrom(*other);
        delete other;
      }
    }


void
merge_from(svTHIS, sv)
  SV * svTHIS
  SV * sv
  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    if ( THIS != NULL && sv != NULL ) {
      if ( sv_derived_from(sv, "Net::NATS::Streaming::PB::MsgProto") ) {
        IV tmp = SvIV((SV *)SvRV(sv));
        ::Net::NATS::Streaming::PB::MsgProto * other = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);

        THIS->MergeFrom(*other);
      } else if ( SvROK(sv) &&
                  SvTYPE(SvRV(sv)) == SVt_PVHV ) {
        ::Net::NATS::Streaming::PB::MsgProto * other = __Net__NATS__Streaming__PB__MsgProto_from_hashref(sv);
        THIS->MergeFrom(*other);
        delete other;
      }
    }


void
clear(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    if ( THIS != NULL ) {
      THIS->Clear();
    }


int
is_initialized(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    if ( THIS != NULL ) {
      RETVAL = THIS->IsInitialized();
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


SV *
error_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string estr;

  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    if ( THIS != NULL ) {
      estr = THIS->InitializationErrorString();
    }
    RETVAL = newSVpv(estr.c_str(), estr.length());

  OUTPUT:
    RETVAL


void
discard_unkown_fields(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    if ( THIS != NULL ) {
      THIS->DiscardUnknownFields();
    }


SV *
debug_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string dstr;

  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    if ( THIS != NULL ) {
      dstr = THIS->DebugString();
    }
    RETVAL = newSVpv(dstr.c_str(), dstr.length());

  OUTPUT:
    RETVAL


SV *
short_debug_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string dstr;

  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    if ( THIS != NULL ) {
      dstr = THIS->ShortDebugString();
    }
    RETVAL = newSVpv(dstr.c_str(), dstr.length());

  OUTPUT:
    RETVAL


int
unpack(svTHIS, arg)
  SV * svTHIS
  SV * arg
  PREINIT:
    STRLEN len;
    char * str;

  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    if ( THIS != NULL ) {
      str = SvPV(arg, len);
      if ( str != NULL ) {
        RETVAL = THIS->ParseFromArray(str, len);
      } else {
        RETVAL = 0;
      }
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


SV *
pack(svTHIS)
  SV * svTHIS
  PREINIT:
    string output;

  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    if ( THIS != NULL ) {
      if ( THIS->IsInitialized() ) {
        if ( THIS->SerializePartialToString(&output)!= true ) {
          RETVAL = Nullsv;
        } else {
          RETVAL = newSVpvn(output.c_str(), output.length());
        }
      } else {
        croak("Can't serialize message of type 'Net::NATS::Streaming::PB::MsgProto' because it is missing required fields: %s",
              THIS->InitializationErrorString().c_str());
      }
    } else {
      RETVAL = Nullsv;
    }

  OUTPUT:
    RETVAL


int
length(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    if ( THIS != NULL ) {
      RETVAL = THIS->ByteSize();
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


void
fields(svTHIS)
  SV * svTHIS
  PPCODE:
    (void)svTHIS;
    EXTEND(SP, 7);
    PUSHs(sv_2mortal(newSVpv("sequence",0)));
    PUSHs(sv_2mortal(newSVpv("subject",0)));
    PUSHs(sv_2mortal(newSVpv("reply",0)));
    PUSHs(sv_2mortal(newSVpv("data",0)));
    PUSHs(sv_2mortal(newSVpv("timestamp",0)));
    PUSHs(sv_2mortal(newSVpv("redelivered",0)));
    PUSHs(sv_2mortal(newSVpv("CRC32",0)));


SV *
to_hashref(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    if ( THIS != NULL ) {
      HV * hv0 = newHV();
      ::Net::NATS::Streaming::PB::MsgProto * msg0 = THIS;

      if ( msg0->has_sequence() ) {
        ostringstream ost0;

        ost0 << msg0->sequence();
        SV * sv0 = newSVpv(ost0.str().c_str(), ost0.str().length());
        hv_store(hv0, "sequence", sizeof("sequence") - 1, sv0, 0);
      }
      if ( msg0->has_subject() ) {
        SV * sv0 = newSVpv(msg0->subject().c_str(), msg0->subject().length());
        hv_store(hv0, "subject", sizeof("subject") - 1, sv0, 0);
      }
      if ( msg0->has_reply() ) {
        SV * sv0 = newSVpv(msg0->reply().c_str(), msg0->reply().length());
        hv_store(hv0, "reply", sizeof("reply") - 1, sv0, 0);
      }
      if ( msg0->has_data() ) {
        SV * sv0 = newSVpv(msg0->data().c_str(), msg0->data().length());
        hv_store(hv0, "data", sizeof("data") - 1, sv0, 0);
      }
      if ( msg0->has_timestamp() ) {
        ostringstream ost0;

        ost0 << msg0->timestamp();
        SV * sv0 = newSVpv(ost0.str().c_str(), ost0.str().length());
        hv_store(hv0, "timestamp", sizeof("timestamp") - 1, sv0, 0);
      }
      if ( msg0->has_redelivered() ) {
        SV * sv0 = newSViv(msg0->redelivered());
        hv_store(hv0, "redelivered", sizeof("redelivered") - 1, sv0, 0);
      }
      if ( msg0->has_crc32() ) {
        SV * sv0 = newSVuv(msg0->crc32());
        hv_store(hv0, "CRC32", sizeof("CRC32") - 1, sv0, 0);
      }
      RETVAL = newRV_noinc((SV *)hv0);
    } else {
      RETVAL = Nullsv;
    }

  OUTPUT:
    RETVAL


I32
has_sequence(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    RETVAL = THIS->has_sequence();

  OUTPUT:
    RETVAL


void
clear_sequence(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    THIS->clear_sequence();


void
sequence(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;
    ostringstream ost;

  PPCODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      ost.str("");
      ost << THIS->sequence();
      sv = sv_2mortal(newSVpv(ost.str().c_str(),
                              ost.str().length()));
      PUSHs(sv);
    }


void
set_sequence(svTHIS, svVAL)
  SV * svTHIS
  char *svVAL

  PREINIT:
    unsigned long long lval;

  CODE:
    lval = strtoull((svVAL) ? svVAL : "", NULL, 0);
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    THIS->set_sequence(lval);


I32
has_subject(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    RETVAL = THIS->has_subject();

  OUTPUT:
    RETVAL


void
clear_subject(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    THIS->clear_subject();


void
subject(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->subject().c_str(),
                              THIS->subject().length()));
      PUSHs(sv);
    }


void
set_subject(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_subject(sval);


I32
has_reply(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    RETVAL = THIS->has_reply();

  OUTPUT:
    RETVAL


void
clear_reply(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    THIS->clear_reply();


void
reply(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->reply().c_str(),
                              THIS->reply().length()));
      PUSHs(sv);
    }


void
set_reply(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_reply(sval);


I32
has_data(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    RETVAL = THIS->has_data();

  OUTPUT:
    RETVAL


void
clear_data(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    THIS->clear_data();


void
data(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->data().c_str(),
                              THIS->data().length()));
      PUSHs(sv);
    }


void
set_data(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;

  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    str = SvPV(svVAL, len);
    THIS->set_data(str, len);


I32
has_timestamp(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    RETVAL = THIS->has_timestamp();

  OUTPUT:
    RETVAL


void
clear_timestamp(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    THIS->clear_timestamp();


void
timestamp(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;
    ostringstream ost;

  PPCODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      ost.str("");
      ost << THIS->timestamp();
      sv = sv_2mortal(newSVpv(ost.str().c_str(),
                              ost.str().length()));
      PUSHs(sv);
    }


void
set_timestamp(svTHIS, svVAL)
  SV * svTHIS
  char *svVAL

  PREINIT:
    long long lval;

  CODE:
    lval = strtoll((svVAL) ? svVAL : "", NULL, 0);
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    THIS->set_timestamp(lval);


I32
has_redelivered(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    RETVAL = THIS->has_redelivered();

  OUTPUT:
    RETVAL


void
clear_redelivered(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    THIS->clear_redelivered();


void
redelivered(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSViv(THIS->redelivered()));
      PUSHs(sv);
    }


void
set_redelivered(svTHIS, svVAL)
  SV * svTHIS
  IV svVAL

  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    THIS->set_redelivered(svVAL);


I32
has_CRC32(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    RETVAL = THIS->has_crc32();

  OUTPUT:
    RETVAL


void
clear_CRC32(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    THIS->clear_crc32();


void
CRC32(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVuv(THIS->crc32()));
      PUSHs(sv);
    }


void
set_CRC32(svTHIS, svVAL)
  SV * svTHIS
  UV svVAL

  CODE:
    ::Net::NATS::Streaming::PB::MsgProto * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::MsgProto") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__MsgProto *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::MsgProto");
    }
    THIS->set_crc32(svVAL);

MODULE = Net::NATS::Streaming::PB::PubAck PACKAGE = Net::NATS::Streaming::PB::PubAck
PROTOTYPES: ENABLE


SV *
::Net::NATS::Streaming::PB::PubAck::new (...)
  PREINIT:
    ::Net::NATS::Streaming::PB::PubAck * rv = NULL;

  CODE:
    if ( strcmp(CLASS,"Net::NATS::Streaming::PB::PubAck") ) {
      croak("invalid class %s",CLASS);
    }
    if ( items == 2 && ST(1) != Nullsv ) {
      if ( SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV ) {
        rv = __Net__NATS__Streaming__PB__PubAck_from_hashref(ST(1));
      } else {
        STRLEN len;
        char * str;

        rv = new ::Net::NATS::Streaming::PB::PubAck;
        str = SvPV(ST(1), len);
        if ( str != NULL ) {
          rv->ParseFromArray(str, len);
        }
      }
    } else {
      rv = new ::Net::NATS::Streaming::PB::PubAck;
    }
    RETVAL = newSV(0);
    sv_setref_pv(RETVAL, "Net::NATS::Streaming::PB::PubAck", (void *)rv);

  OUTPUT:
    RETVAL


void
DESTROY(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::PubAck * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubAck") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubAck *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubAck");
    }
    if ( THIS != NULL ) {
      delete THIS;
    }


void
copy_from(svTHIS, sv)
  SV * svTHIS
  SV * sv
  CODE:
    ::Net::NATS::Streaming::PB::PubAck * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubAck") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubAck *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubAck");
    }
    if ( THIS != NULL && sv != NULL ) {
      if ( sv_derived_from(sv, "Net::NATS::Streaming::PB::PubAck") ) {
        IV tmp = SvIV((SV *)SvRV(sv));
        ::Net::NATS::Streaming::PB::PubAck * other = INT2PTR(__Net__NATS__Streaming__PB__PubAck *, tmp);

        THIS->CopyFrom(*other);
      } else if ( SvROK(sv) &&
                  SvTYPE(SvRV(sv)) == SVt_PVHV ) {
        ::Net::NATS::Streaming::PB::PubAck * other = __Net__NATS__Streaming__PB__PubAck_from_hashref(sv);
        THIS->CopyFrom(*other);
        delete other;
      }
    }


void
merge_from(svTHIS, sv)
  SV * svTHIS
  SV * sv
  CODE:
    ::Net::NATS::Streaming::PB::PubAck * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubAck") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubAck *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubAck");
    }
    if ( THIS != NULL && sv != NULL ) {
      if ( sv_derived_from(sv, "Net::NATS::Streaming::PB::PubAck") ) {
        IV tmp = SvIV((SV *)SvRV(sv));
        ::Net::NATS::Streaming::PB::PubAck * other = INT2PTR(__Net__NATS__Streaming__PB__PubAck *, tmp);

        THIS->MergeFrom(*other);
      } else if ( SvROK(sv) &&
                  SvTYPE(SvRV(sv)) == SVt_PVHV ) {
        ::Net::NATS::Streaming::PB::PubAck * other = __Net__NATS__Streaming__PB__PubAck_from_hashref(sv);
        THIS->MergeFrom(*other);
        delete other;
      }
    }


void
clear(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::PubAck * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubAck") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubAck *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubAck");
    }
    if ( THIS != NULL ) {
      THIS->Clear();
    }


int
is_initialized(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::PubAck * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubAck") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubAck *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubAck");
    }
    if ( THIS != NULL ) {
      RETVAL = THIS->IsInitialized();
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


SV *
error_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string estr;

  CODE:
    ::Net::NATS::Streaming::PB::PubAck * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubAck") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubAck *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubAck");
    }
    if ( THIS != NULL ) {
      estr = THIS->InitializationErrorString();
    }
    RETVAL = newSVpv(estr.c_str(), estr.length());

  OUTPUT:
    RETVAL


void
discard_unkown_fields(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::PubAck * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubAck") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubAck *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubAck");
    }
    if ( THIS != NULL ) {
      THIS->DiscardUnknownFields();
    }


SV *
debug_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string dstr;

  CODE:
    ::Net::NATS::Streaming::PB::PubAck * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubAck") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubAck *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubAck");
    }
    if ( THIS != NULL ) {
      dstr = THIS->DebugString();
    }
    RETVAL = newSVpv(dstr.c_str(), dstr.length());

  OUTPUT:
    RETVAL


SV *
short_debug_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string dstr;

  CODE:
    ::Net::NATS::Streaming::PB::PubAck * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubAck") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubAck *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubAck");
    }
    if ( THIS != NULL ) {
      dstr = THIS->ShortDebugString();
    }
    RETVAL = newSVpv(dstr.c_str(), dstr.length());

  OUTPUT:
    RETVAL


int
unpack(svTHIS, arg)
  SV * svTHIS
  SV * arg
  PREINIT:
    STRLEN len;
    char * str;

  CODE:
    ::Net::NATS::Streaming::PB::PubAck * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubAck") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubAck *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubAck");
    }
    if ( THIS != NULL ) {
      str = SvPV(arg, len);
      if ( str != NULL ) {
        RETVAL = THIS->ParseFromArray(str, len);
      } else {
        RETVAL = 0;
      }
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


SV *
pack(svTHIS)
  SV * svTHIS
  PREINIT:
    string output;

  CODE:
    ::Net::NATS::Streaming::PB::PubAck * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubAck") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubAck *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubAck");
    }
    if ( THIS != NULL ) {
      if ( THIS->IsInitialized() ) {
        if ( THIS->SerializePartialToString(&output)!= true ) {
          RETVAL = Nullsv;
        } else {
          RETVAL = newSVpvn(output.c_str(), output.length());
        }
      } else {
        croak("Can't serialize message of type 'Net::NATS::Streaming::PB::PubAck' because it is missing required fields: %s",
              THIS->InitializationErrorString().c_str());
      }
    } else {
      RETVAL = Nullsv;
    }

  OUTPUT:
    RETVAL


int
length(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::PubAck * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubAck") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubAck *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubAck");
    }
    if ( THIS != NULL ) {
      RETVAL = THIS->ByteSize();
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


void
fields(svTHIS)
  SV * svTHIS
  PPCODE:
    (void)svTHIS;
    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newSVpv("guid",0)));
    PUSHs(sv_2mortal(newSVpv("error",0)));


SV *
to_hashref(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::PubAck * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubAck") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubAck *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubAck");
    }
    if ( THIS != NULL ) {
      HV * hv0 = newHV();
      ::Net::NATS::Streaming::PB::PubAck * msg0 = THIS;

      if ( msg0->has_guid() ) {
        SV * sv0 = newSVpv(msg0->guid().c_str(), msg0->guid().length());
        hv_store(hv0, "guid", sizeof("guid") - 1, sv0, 0);
      }
      if ( msg0->has_error() ) {
        SV * sv0 = newSVpv(msg0->error().c_str(), msg0->error().length());
        hv_store(hv0, "error", sizeof("error") - 1, sv0, 0);
      }
      RETVAL = newRV_noinc((SV *)hv0);
    } else {
      RETVAL = Nullsv;
    }

  OUTPUT:
    RETVAL


I32
has_guid(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::PubAck * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubAck") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubAck *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubAck");
    }
    RETVAL = THIS->has_guid();

  OUTPUT:
    RETVAL


void
clear_guid(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::PubAck * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubAck") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubAck *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubAck");
    }
    THIS->clear_guid();


void
guid(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::PubAck * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubAck") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubAck *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubAck");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->guid().c_str(),
                              THIS->guid().length()));
      PUSHs(sv);
    }


void
set_guid(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::PubAck * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubAck") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubAck *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubAck");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_guid(sval);


I32
has_error(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::PubAck * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubAck") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubAck *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubAck");
    }
    RETVAL = THIS->has_error();

  OUTPUT:
    RETVAL


void
clear_error(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::PubAck * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubAck") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubAck *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubAck");
    }
    THIS->clear_error();


void
error(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::PubAck * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubAck") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubAck *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubAck");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->error().c_str(),
                              THIS->error().length()));
      PUSHs(sv);
    }


void
set_error(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::PubAck * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubAck") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubAck *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubAck");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_error(sval);

MODULE = Net::NATS::Streaming::PB::PubMsg PACKAGE = Net::NATS::Streaming::PB::PubMsg
PROTOTYPES: ENABLE


SV *
::Net::NATS::Streaming::PB::PubMsg::new (...)
  PREINIT:
    ::Net::NATS::Streaming::PB::PubMsg * rv = NULL;

  CODE:
    if ( strcmp(CLASS,"Net::NATS::Streaming::PB::PubMsg") ) {
      croak("invalid class %s",CLASS);
    }
    if ( items == 2 && ST(1) != Nullsv ) {
      if ( SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV ) {
        rv = __Net__NATS__Streaming__PB__PubMsg_from_hashref(ST(1));
      } else {
        STRLEN len;
        char * str;

        rv = new ::Net::NATS::Streaming::PB::PubMsg;
        str = SvPV(ST(1), len);
        if ( str != NULL ) {
          rv->ParseFromArray(str, len);
        }
      }
    } else {
      rv = new ::Net::NATS::Streaming::PB::PubMsg;
    }
    RETVAL = newSV(0);
    sv_setref_pv(RETVAL, "Net::NATS::Streaming::PB::PubMsg", (void *)rv);

  OUTPUT:
    RETVAL


void
DESTROY(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    if ( THIS != NULL ) {
      delete THIS;
    }


void
copy_from(svTHIS, sv)
  SV * svTHIS
  SV * sv
  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    if ( THIS != NULL && sv != NULL ) {
      if ( sv_derived_from(sv, "Net::NATS::Streaming::PB::PubMsg") ) {
        IV tmp = SvIV((SV *)SvRV(sv));
        ::Net::NATS::Streaming::PB::PubMsg * other = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);

        THIS->CopyFrom(*other);
      } else if ( SvROK(sv) &&
                  SvTYPE(SvRV(sv)) == SVt_PVHV ) {
        ::Net::NATS::Streaming::PB::PubMsg * other = __Net__NATS__Streaming__PB__PubMsg_from_hashref(sv);
        THIS->CopyFrom(*other);
        delete other;
      }
    }


void
merge_from(svTHIS, sv)
  SV * svTHIS
  SV * sv
  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    if ( THIS != NULL && sv != NULL ) {
      if ( sv_derived_from(sv, "Net::NATS::Streaming::PB::PubMsg") ) {
        IV tmp = SvIV((SV *)SvRV(sv));
        ::Net::NATS::Streaming::PB::PubMsg * other = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);

        THIS->MergeFrom(*other);
      } else if ( SvROK(sv) &&
                  SvTYPE(SvRV(sv)) == SVt_PVHV ) {
        ::Net::NATS::Streaming::PB::PubMsg * other = __Net__NATS__Streaming__PB__PubMsg_from_hashref(sv);
        THIS->MergeFrom(*other);
        delete other;
      }
    }


void
clear(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    if ( THIS != NULL ) {
      THIS->Clear();
    }


int
is_initialized(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    if ( THIS != NULL ) {
      RETVAL = THIS->IsInitialized();
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


SV *
error_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string estr;

  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    if ( THIS != NULL ) {
      estr = THIS->InitializationErrorString();
    }
    RETVAL = newSVpv(estr.c_str(), estr.length());

  OUTPUT:
    RETVAL


void
discard_unkown_fields(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    if ( THIS != NULL ) {
      THIS->DiscardUnknownFields();
    }


SV *
debug_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string dstr;

  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    if ( THIS != NULL ) {
      dstr = THIS->DebugString();
    }
    RETVAL = newSVpv(dstr.c_str(), dstr.length());

  OUTPUT:
    RETVAL


SV *
short_debug_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string dstr;

  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    if ( THIS != NULL ) {
      dstr = THIS->ShortDebugString();
    }
    RETVAL = newSVpv(dstr.c_str(), dstr.length());

  OUTPUT:
    RETVAL


int
unpack(svTHIS, arg)
  SV * svTHIS
  SV * arg
  PREINIT:
    STRLEN len;
    char * str;

  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    if ( THIS != NULL ) {
      str = SvPV(arg, len);
      if ( str != NULL ) {
        RETVAL = THIS->ParseFromArray(str, len);
      } else {
        RETVAL = 0;
      }
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


SV *
pack(svTHIS)
  SV * svTHIS
  PREINIT:
    string output;

  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    if ( THIS != NULL ) {
      if ( THIS->IsInitialized() ) {
        if ( THIS->SerializePartialToString(&output)!= true ) {
          RETVAL = Nullsv;
        } else {
          RETVAL = newSVpvn(output.c_str(), output.length());
        }
      } else {
        croak("Can't serialize message of type 'Net::NATS::Streaming::PB::PubMsg' because it is missing required fields: %s",
              THIS->InitializationErrorString().c_str());
      }
    } else {
      RETVAL = Nullsv;
    }

  OUTPUT:
    RETVAL


int
length(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    if ( THIS != NULL ) {
      RETVAL = THIS->ByteSize();
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


void
fields(svTHIS)
  SV * svTHIS
  PPCODE:
    (void)svTHIS;
    EXTEND(SP, 6);
    PUSHs(sv_2mortal(newSVpv("clientID",0)));
    PUSHs(sv_2mortal(newSVpv("guid",0)));
    PUSHs(sv_2mortal(newSVpv("subject",0)));
    PUSHs(sv_2mortal(newSVpv("reply",0)));
    PUSHs(sv_2mortal(newSVpv("data",0)));
    PUSHs(sv_2mortal(newSVpv("sha256",0)));


SV *
to_hashref(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    if ( THIS != NULL ) {
      HV * hv0 = newHV();
      ::Net::NATS::Streaming::PB::PubMsg * msg0 = THIS;

      if ( msg0->has_clientid() ) {
        SV * sv0 = newSVpv(msg0->clientid().c_str(), msg0->clientid().length());
        hv_store(hv0, "clientID", sizeof("clientID") - 1, sv0, 0);
      }
      if ( msg0->has_guid() ) {
        SV * sv0 = newSVpv(msg0->guid().c_str(), msg0->guid().length());
        hv_store(hv0, "guid", sizeof("guid") - 1, sv0, 0);
      }
      if ( msg0->has_subject() ) {
        SV * sv0 = newSVpv(msg0->subject().c_str(), msg0->subject().length());
        hv_store(hv0, "subject", sizeof("subject") - 1, sv0, 0);
      }
      if ( msg0->has_reply() ) {
        SV * sv0 = newSVpv(msg0->reply().c_str(), msg0->reply().length());
        hv_store(hv0, "reply", sizeof("reply") - 1, sv0, 0);
      }
      if ( msg0->has_data() ) {
        SV * sv0 = newSVpv(msg0->data().c_str(), msg0->data().length());
        hv_store(hv0, "data", sizeof("data") - 1, sv0, 0);
      }
      if ( msg0->has_sha256() ) {
        SV * sv0 = newSVpv(msg0->sha256().c_str(), msg0->sha256().length());
        hv_store(hv0, "sha256", sizeof("sha256") - 1, sv0, 0);
      }
      RETVAL = newRV_noinc((SV *)hv0);
    } else {
      RETVAL = Nullsv;
    }

  OUTPUT:
    RETVAL


I32
has_clientID(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    RETVAL = THIS->has_clientid();

  OUTPUT:
    RETVAL


void
clear_clientID(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    THIS->clear_clientid();


void
clientID(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->clientid().c_str(),
                              THIS->clientid().length()));
      PUSHs(sv);
    }


void
set_clientID(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_clientid(sval);


I32
has_guid(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    RETVAL = THIS->has_guid();

  OUTPUT:
    RETVAL


void
clear_guid(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    THIS->clear_guid();


void
guid(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->guid().c_str(),
                              THIS->guid().length()));
      PUSHs(sv);
    }


void
set_guid(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_guid(sval);


I32
has_subject(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    RETVAL = THIS->has_subject();

  OUTPUT:
    RETVAL


void
clear_subject(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    THIS->clear_subject();


void
subject(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->subject().c_str(),
                              THIS->subject().length()));
      PUSHs(sv);
    }


void
set_subject(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_subject(sval);


I32
has_reply(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    RETVAL = THIS->has_reply();

  OUTPUT:
    RETVAL


void
clear_reply(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    THIS->clear_reply();


void
reply(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->reply().c_str(),
                              THIS->reply().length()));
      PUSHs(sv);
    }


void
set_reply(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_reply(sval);


I32
has_data(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    RETVAL = THIS->has_data();

  OUTPUT:
    RETVAL


void
clear_data(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    THIS->clear_data();


void
data(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->data().c_str(),
                              THIS->data().length()));
      PUSHs(sv);
    }


void
set_data(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;

  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    str = SvPV(svVAL, len);
    THIS->set_data(str, len);


I32
has_sha256(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    RETVAL = THIS->has_sha256();

  OUTPUT:
    RETVAL


void
clear_sha256(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    THIS->clear_sha256();


void
sha256(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->sha256().c_str(),
                              THIS->sha256().length()));
      PUSHs(sv);
    }


void
set_sha256(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;

  CODE:
    ::Net::NATS::Streaming::PB::PubMsg * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::PubMsg") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__PubMsg *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::PubMsg");
    }
    str = SvPV(svVAL, len);
    THIS->set_sha256(str, len);

MODULE = Net::NATS::Streaming::PB::SubscriptionRequest PACKAGE = Net::NATS::Streaming::PB::SubscriptionRequest
PROTOTYPES: ENABLE


SV *
::Net::NATS::Streaming::PB::SubscriptionRequest::new (...)
  PREINIT:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * rv = NULL;

  CODE:
    if ( strcmp(CLASS,"Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      croak("invalid class %s",CLASS);
    }
    if ( items == 2 && ST(1) != Nullsv ) {
      if ( SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV ) {
        rv = __Net__NATS__Streaming__PB__SubscriptionRequest_from_hashref(ST(1));
      } else {
        STRLEN len;
        char * str;

        rv = new ::Net::NATS::Streaming::PB::SubscriptionRequest;
        str = SvPV(ST(1), len);
        if ( str != NULL ) {
          rv->ParseFromArray(str, len);
        }
      }
    } else {
      rv = new ::Net::NATS::Streaming::PB::SubscriptionRequest;
    }
    RETVAL = newSV(0);
    sv_setref_pv(RETVAL, "Net::NATS::Streaming::PB::SubscriptionRequest", (void *)rv);

  OUTPUT:
    RETVAL


void
DESTROY(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    if ( THIS != NULL ) {
      delete THIS;
    }


void
copy_from(svTHIS, sv)
  SV * svTHIS
  SV * sv
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    if ( THIS != NULL && sv != NULL ) {
      if ( sv_derived_from(sv, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
        IV tmp = SvIV((SV *)SvRV(sv));
        ::Net::NATS::Streaming::PB::SubscriptionRequest * other = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);

        THIS->CopyFrom(*other);
      } else if ( SvROK(sv) &&
                  SvTYPE(SvRV(sv)) == SVt_PVHV ) {
        ::Net::NATS::Streaming::PB::SubscriptionRequest * other = __Net__NATS__Streaming__PB__SubscriptionRequest_from_hashref(sv);
        THIS->CopyFrom(*other);
        delete other;
      }
    }


void
merge_from(svTHIS, sv)
  SV * svTHIS
  SV * sv
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    if ( THIS != NULL && sv != NULL ) {
      if ( sv_derived_from(sv, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
        IV tmp = SvIV((SV *)SvRV(sv));
        ::Net::NATS::Streaming::PB::SubscriptionRequest * other = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);

        THIS->MergeFrom(*other);
      } else if ( SvROK(sv) &&
                  SvTYPE(SvRV(sv)) == SVt_PVHV ) {
        ::Net::NATS::Streaming::PB::SubscriptionRequest * other = __Net__NATS__Streaming__PB__SubscriptionRequest_from_hashref(sv);
        THIS->MergeFrom(*other);
        delete other;
      }
    }


void
clear(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    if ( THIS != NULL ) {
      THIS->Clear();
    }


int
is_initialized(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    if ( THIS != NULL ) {
      RETVAL = THIS->IsInitialized();
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


SV *
error_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string estr;

  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    if ( THIS != NULL ) {
      estr = THIS->InitializationErrorString();
    }
    RETVAL = newSVpv(estr.c_str(), estr.length());

  OUTPUT:
    RETVAL


void
discard_unkown_fields(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    if ( THIS != NULL ) {
      THIS->DiscardUnknownFields();
    }


SV *
debug_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string dstr;

  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    if ( THIS != NULL ) {
      dstr = THIS->DebugString();
    }
    RETVAL = newSVpv(dstr.c_str(), dstr.length());

  OUTPUT:
    RETVAL


SV *
short_debug_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string dstr;

  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    if ( THIS != NULL ) {
      dstr = THIS->ShortDebugString();
    }
    RETVAL = newSVpv(dstr.c_str(), dstr.length());

  OUTPUT:
    RETVAL


int
unpack(svTHIS, arg)
  SV * svTHIS
  SV * arg
  PREINIT:
    STRLEN len;
    char * str;

  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    if ( THIS != NULL ) {
      str = SvPV(arg, len);
      if ( str != NULL ) {
        RETVAL = THIS->ParseFromArray(str, len);
      } else {
        RETVAL = 0;
      }
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


SV *
pack(svTHIS)
  SV * svTHIS
  PREINIT:
    string output;

  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    if ( THIS != NULL ) {
      if ( THIS->IsInitialized() ) {
        if ( THIS->SerializePartialToString(&output)!= true ) {
          RETVAL = Nullsv;
        } else {
          RETVAL = newSVpvn(output.c_str(), output.length());
        }
      } else {
        croak("Can't serialize message of type 'Net::NATS::Streaming::PB::SubscriptionRequest' because it is missing required fields: %s",
              THIS->InitializationErrorString().c_str());
      }
    } else {
      RETVAL = Nullsv;
    }

  OUTPUT:
    RETVAL


int
length(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    if ( THIS != NULL ) {
      RETVAL = THIS->ByteSize();
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


void
fields(svTHIS)
  SV * svTHIS
  PPCODE:
    (void)svTHIS;
    EXTEND(SP, 10);
    PUSHs(sv_2mortal(newSVpv("clientID",0)));
    PUSHs(sv_2mortal(newSVpv("subject",0)));
    PUSHs(sv_2mortal(newSVpv("qGroup",0)));
    PUSHs(sv_2mortal(newSVpv("inbox",0)));
    PUSHs(sv_2mortal(newSVpv("maxInFlight",0)));
    PUSHs(sv_2mortal(newSVpv("ackWaitInSecs",0)));
    PUSHs(sv_2mortal(newSVpv("durableName",0)));
    PUSHs(sv_2mortal(newSVpv("startPosition",0)));
    PUSHs(sv_2mortal(newSVpv("startSequence",0)));
    PUSHs(sv_2mortal(newSVpv("startTimeDelta",0)));


SV *
to_hashref(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    if ( THIS != NULL ) {
      HV * hv0 = newHV();
      ::Net::NATS::Streaming::PB::SubscriptionRequest * msg0 = THIS;

      if ( msg0->has_clientid() ) {
        SV * sv0 = newSVpv(msg0->clientid().c_str(), msg0->clientid().length());
        hv_store(hv0, "clientID", sizeof("clientID") - 1, sv0, 0);
      }
      if ( msg0->has_subject() ) {
        SV * sv0 = newSVpv(msg0->subject().c_str(), msg0->subject().length());
        hv_store(hv0, "subject", sizeof("subject") - 1, sv0, 0);
      }
      if ( msg0->has_qgroup() ) {
        SV * sv0 = newSVpv(msg0->qgroup().c_str(), msg0->qgroup().length());
        hv_store(hv0, "qGroup", sizeof("qGroup") - 1, sv0, 0);
      }
      if ( msg0->has_inbox() ) {
        SV * sv0 = newSVpv(msg0->inbox().c_str(), msg0->inbox().length());
        hv_store(hv0, "inbox", sizeof("inbox") - 1, sv0, 0);
      }
      if ( msg0->has_maxinflight() ) {
        SV * sv0 = newSViv(msg0->maxinflight());
        hv_store(hv0, "maxInFlight", sizeof("maxInFlight") - 1, sv0, 0);
      }
      if ( msg0->has_ackwaitinsecs() ) {
        SV * sv0 = newSViv(msg0->ackwaitinsecs());
        hv_store(hv0, "ackWaitInSecs", sizeof("ackWaitInSecs") - 1, sv0, 0);
      }
      if ( msg0->has_durablename() ) {
        SV * sv0 = newSVpv(msg0->durablename().c_str(), msg0->durablename().length());
        hv_store(hv0, "durableName", sizeof("durableName") - 1, sv0, 0);
      }
      if ( msg0->has_startposition() ) {
        SV * sv0 = newSViv(msg0->startposition());
        hv_store(hv0, "startPosition", sizeof("startPosition") - 1, sv0, 0);
      }
      if ( msg0->has_startsequence() ) {
        ostringstream ost0;

        ost0 << msg0->startsequence();
        SV * sv0 = newSVpv(ost0.str().c_str(), ost0.str().length());
        hv_store(hv0, "startSequence", sizeof("startSequence") - 1, sv0, 0);
      }
      if ( msg0->has_starttimedelta() ) {
        ostringstream ost0;

        ost0 << msg0->starttimedelta();
        SV * sv0 = newSVpv(ost0.str().c_str(), ost0.str().length());
        hv_store(hv0, "startTimeDelta", sizeof("startTimeDelta") - 1, sv0, 0);
      }
      RETVAL = newRV_noinc((SV *)hv0);
    } else {
      RETVAL = Nullsv;
    }

  OUTPUT:
    RETVAL


I32
has_clientID(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    RETVAL = THIS->has_clientid();

  OUTPUT:
    RETVAL


void
clear_clientID(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    THIS->clear_clientid();


void
clientID(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->clientid().c_str(),
                              THIS->clientid().length()));
      PUSHs(sv);
    }


void
set_clientID(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_clientid(sval);


I32
has_subject(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    RETVAL = THIS->has_subject();

  OUTPUT:
    RETVAL


void
clear_subject(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    THIS->clear_subject();


void
subject(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->subject().c_str(),
                              THIS->subject().length()));
      PUSHs(sv);
    }


void
set_subject(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_subject(sval);


I32
has_qGroup(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    RETVAL = THIS->has_qgroup();

  OUTPUT:
    RETVAL


void
clear_qGroup(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    THIS->clear_qgroup();


void
qGroup(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->qgroup().c_str(),
                              THIS->qgroup().length()));
      PUSHs(sv);
    }


void
set_qGroup(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_qgroup(sval);


I32
has_inbox(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    RETVAL = THIS->has_inbox();

  OUTPUT:
    RETVAL


void
clear_inbox(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    THIS->clear_inbox();


void
inbox(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->inbox().c_str(),
                              THIS->inbox().length()));
      PUSHs(sv);
    }


void
set_inbox(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_inbox(sval);


I32
has_maxInFlight(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    RETVAL = THIS->has_maxinflight();

  OUTPUT:
    RETVAL


void
clear_maxInFlight(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    THIS->clear_maxinflight();


void
maxInFlight(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSViv(THIS->maxinflight()));
      PUSHs(sv);
    }


void
set_maxInFlight(svTHIS, svVAL)
  SV * svTHIS
  IV svVAL

  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    THIS->set_maxinflight(svVAL);


I32
has_ackWaitInSecs(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    RETVAL = THIS->has_ackwaitinsecs();

  OUTPUT:
    RETVAL


void
clear_ackWaitInSecs(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    THIS->clear_ackwaitinsecs();


void
ackWaitInSecs(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSViv(THIS->ackwaitinsecs()));
      PUSHs(sv);
    }


void
set_ackWaitInSecs(svTHIS, svVAL)
  SV * svTHIS
  IV svVAL

  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    THIS->set_ackwaitinsecs(svVAL);


I32
has_durableName(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    RETVAL = THIS->has_durablename();

  OUTPUT:
    RETVAL


void
clear_durableName(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    THIS->clear_durablename();


void
durableName(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->durablename().c_str(),
                              THIS->durablename().length()));
      PUSHs(sv);
    }


void
set_durableName(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_durablename(sval);


I32
has_startPosition(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    RETVAL = THIS->has_startposition();

  OUTPUT:
    RETVAL


void
clear_startPosition(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    THIS->clear_startposition();


void
startPosition(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSViv(THIS->startposition()));
      PUSHs(sv);
    }


void
set_startPosition(svTHIS, svVAL)
  SV * svTHIS
  IV svVAL

  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    if ( ::Net::NATS::Streaming::PB::StartPosition_IsValid(svVAL) ) {
      THIS->set_startposition((::Net::NATS::Streaming::PB::StartPosition)svVAL);
    }


I32
has_startSequence(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    RETVAL = THIS->has_startsequence();

  OUTPUT:
    RETVAL


void
clear_startSequence(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    THIS->clear_startsequence();


void
startSequence(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;
    ostringstream ost;

  PPCODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      ost.str("");
      ost << THIS->startsequence();
      sv = sv_2mortal(newSVpv(ost.str().c_str(),
                              ost.str().length()));
      PUSHs(sv);
    }


void
set_startSequence(svTHIS, svVAL)
  SV * svTHIS
  char *svVAL

  PREINIT:
    unsigned long long lval;

  CODE:
    lval = strtoull((svVAL) ? svVAL : "", NULL, 0);
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    THIS->set_startsequence(lval);


I32
has_startTimeDelta(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    RETVAL = THIS->has_starttimedelta();

  OUTPUT:
    RETVAL


void
clear_startTimeDelta(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    THIS->clear_starttimedelta();


void
startTimeDelta(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;
    ostringstream ost;

  PPCODE:
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      ost.str("");
      ost << THIS->starttimedelta();
      sv = sv_2mortal(newSVpv(ost.str().c_str(),
                              ost.str().length()));
      PUSHs(sv);
    }


void
set_startTimeDelta(svTHIS, svVAL)
  SV * svTHIS
  char *svVAL

  PREINIT:
    long long lval;

  CODE:
    lval = strtoll((svVAL) ? svVAL : "", NULL, 0);
    ::Net::NATS::Streaming::PB::SubscriptionRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionRequest");
    }
    THIS->set_starttimedelta(lval);

MODULE = Net::NATS::Streaming::PB::SubscriptionResponse PACKAGE = Net::NATS::Streaming::PB::SubscriptionResponse
PROTOTYPES: ENABLE


SV *
::Net::NATS::Streaming::PB::SubscriptionResponse::new (...)
  PREINIT:
    ::Net::NATS::Streaming::PB::SubscriptionResponse * rv = NULL;

  CODE:
    if ( strcmp(CLASS,"Net::NATS::Streaming::PB::SubscriptionResponse") ) {
      croak("invalid class %s",CLASS);
    }
    if ( items == 2 && ST(1) != Nullsv ) {
      if ( SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV ) {
        rv = __Net__NATS__Streaming__PB__SubscriptionResponse_from_hashref(ST(1));
      } else {
        STRLEN len;
        char * str;

        rv = new ::Net::NATS::Streaming::PB::SubscriptionResponse;
        str = SvPV(ST(1), len);
        if ( str != NULL ) {
          rv->ParseFromArray(str, len);
        }
      }
    } else {
      rv = new ::Net::NATS::Streaming::PB::SubscriptionResponse;
    }
    RETVAL = newSV(0);
    sv_setref_pv(RETVAL, "Net::NATS::Streaming::PB::SubscriptionResponse", (void *)rv);

  OUTPUT:
    RETVAL


void
DESTROY(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionResponse");
    }
    if ( THIS != NULL ) {
      delete THIS;
    }


void
copy_from(svTHIS, sv)
  SV * svTHIS
  SV * sv
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionResponse");
    }
    if ( THIS != NULL && sv != NULL ) {
      if ( sv_derived_from(sv, "Net::NATS::Streaming::PB::SubscriptionResponse") ) {
        IV tmp = SvIV((SV *)SvRV(sv));
        ::Net::NATS::Streaming::PB::SubscriptionResponse * other = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionResponse *, tmp);

        THIS->CopyFrom(*other);
      } else if ( SvROK(sv) &&
                  SvTYPE(SvRV(sv)) == SVt_PVHV ) {
        ::Net::NATS::Streaming::PB::SubscriptionResponse * other = __Net__NATS__Streaming__PB__SubscriptionResponse_from_hashref(sv);
        THIS->CopyFrom(*other);
        delete other;
      }
    }


void
merge_from(svTHIS, sv)
  SV * svTHIS
  SV * sv
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionResponse");
    }
    if ( THIS != NULL && sv != NULL ) {
      if ( sv_derived_from(sv, "Net::NATS::Streaming::PB::SubscriptionResponse") ) {
        IV tmp = SvIV((SV *)SvRV(sv));
        ::Net::NATS::Streaming::PB::SubscriptionResponse * other = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionResponse *, tmp);

        THIS->MergeFrom(*other);
      } else if ( SvROK(sv) &&
                  SvTYPE(SvRV(sv)) == SVt_PVHV ) {
        ::Net::NATS::Streaming::PB::SubscriptionResponse * other = __Net__NATS__Streaming__PB__SubscriptionResponse_from_hashref(sv);
        THIS->MergeFrom(*other);
        delete other;
      }
    }


void
clear(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionResponse");
    }
    if ( THIS != NULL ) {
      THIS->Clear();
    }


int
is_initialized(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionResponse");
    }
    if ( THIS != NULL ) {
      RETVAL = THIS->IsInitialized();
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


SV *
error_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string estr;

  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionResponse");
    }
    if ( THIS != NULL ) {
      estr = THIS->InitializationErrorString();
    }
    RETVAL = newSVpv(estr.c_str(), estr.length());

  OUTPUT:
    RETVAL


void
discard_unkown_fields(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionResponse");
    }
    if ( THIS != NULL ) {
      THIS->DiscardUnknownFields();
    }


SV *
debug_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string dstr;

  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionResponse");
    }
    if ( THIS != NULL ) {
      dstr = THIS->DebugString();
    }
    RETVAL = newSVpv(dstr.c_str(), dstr.length());

  OUTPUT:
    RETVAL


SV *
short_debug_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string dstr;

  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionResponse");
    }
    if ( THIS != NULL ) {
      dstr = THIS->ShortDebugString();
    }
    RETVAL = newSVpv(dstr.c_str(), dstr.length());

  OUTPUT:
    RETVAL


int
unpack(svTHIS, arg)
  SV * svTHIS
  SV * arg
  PREINIT:
    STRLEN len;
    char * str;

  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionResponse");
    }
    if ( THIS != NULL ) {
      str = SvPV(arg, len);
      if ( str != NULL ) {
        RETVAL = THIS->ParseFromArray(str, len);
      } else {
        RETVAL = 0;
      }
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


SV *
pack(svTHIS)
  SV * svTHIS
  PREINIT:
    string output;

  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionResponse");
    }
    if ( THIS != NULL ) {
      if ( THIS->IsInitialized() ) {
        if ( THIS->SerializePartialToString(&output)!= true ) {
          RETVAL = Nullsv;
        } else {
          RETVAL = newSVpvn(output.c_str(), output.length());
        }
      } else {
        croak("Can't serialize message of type 'Net::NATS::Streaming::PB::SubscriptionResponse' because it is missing required fields: %s",
              THIS->InitializationErrorString().c_str());
      }
    } else {
      RETVAL = Nullsv;
    }

  OUTPUT:
    RETVAL


int
length(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionResponse");
    }
    if ( THIS != NULL ) {
      RETVAL = THIS->ByteSize();
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


void
fields(svTHIS)
  SV * svTHIS
  PPCODE:
    (void)svTHIS;
    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newSVpv("ackInbox",0)));
    PUSHs(sv_2mortal(newSVpv("error",0)));


SV *
to_hashref(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionResponse");
    }
    if ( THIS != NULL ) {
      HV * hv0 = newHV();
      ::Net::NATS::Streaming::PB::SubscriptionResponse * msg0 = THIS;

      if ( msg0->has_ackinbox() ) {
        SV * sv0 = newSVpv(msg0->ackinbox().c_str(), msg0->ackinbox().length());
        hv_store(hv0, "ackInbox", sizeof("ackInbox") - 1, sv0, 0);
      }
      if ( msg0->has_error() ) {
        SV * sv0 = newSVpv(msg0->error().c_str(), msg0->error().length());
        hv_store(hv0, "error", sizeof("error") - 1, sv0, 0);
      }
      RETVAL = newRV_noinc((SV *)hv0);
    } else {
      RETVAL = Nullsv;
    }

  OUTPUT:
    RETVAL


I32
has_ackInbox(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionResponse");
    }
    RETVAL = THIS->has_ackinbox();

  OUTPUT:
    RETVAL


void
clear_ackInbox(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionResponse");
    }
    THIS->clear_ackinbox();


void
ackInbox(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::SubscriptionResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionResponse");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->ackinbox().c_str(),
                              THIS->ackinbox().length()));
      PUSHs(sv);
    }


void
set_ackInbox(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionResponse");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_ackinbox(sval);


I32
has_error(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionResponse");
    }
    RETVAL = THIS->has_error();

  OUTPUT:
    RETVAL


void
clear_error(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionResponse");
    }
    THIS->clear_error();


void
error(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::SubscriptionResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionResponse");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->error().c_str(),
                              THIS->error().length()));
      PUSHs(sv);
    }


void
set_error(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::SubscriptionResponse * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::SubscriptionResponse") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__SubscriptionResponse *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::SubscriptionResponse");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_error(sval);

MODULE = Net::NATS::Streaming::PB::UnsubscribeRequest PACKAGE = Net::NATS::Streaming::PB::UnsubscribeRequest
PROTOTYPES: ENABLE


SV *
::Net::NATS::Streaming::PB::UnsubscribeRequest::new (...)
  PREINIT:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * rv = NULL;

  CODE:
    if ( strcmp(CLASS,"Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      croak("invalid class %s",CLASS);
    }
    if ( items == 2 && ST(1) != Nullsv ) {
      if ( SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV ) {
        rv = __Net__NATS__Streaming__PB__UnsubscribeRequest_from_hashref(ST(1));
      } else {
        STRLEN len;
        char * str;

        rv = new ::Net::NATS::Streaming::PB::UnsubscribeRequest;
        str = SvPV(ST(1), len);
        if ( str != NULL ) {
          rv->ParseFromArray(str, len);
        }
      }
    } else {
      rv = new ::Net::NATS::Streaming::PB::UnsubscribeRequest;
    }
    RETVAL = newSV(0);
    sv_setref_pv(RETVAL, "Net::NATS::Streaming::PB::UnsubscribeRequest", (void *)rv);

  OUTPUT:
    RETVAL


void
DESTROY(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::UnsubscribeRequest");
    }
    if ( THIS != NULL ) {
      delete THIS;
    }


void
copy_from(svTHIS, sv)
  SV * svTHIS
  SV * sv
  CODE:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::UnsubscribeRequest");
    }
    if ( THIS != NULL && sv != NULL ) {
      if ( sv_derived_from(sv, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
        IV tmp = SvIV((SV *)SvRV(sv));
        ::Net::NATS::Streaming::PB::UnsubscribeRequest * other = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);

        THIS->CopyFrom(*other);
      } else if ( SvROK(sv) &&
                  SvTYPE(SvRV(sv)) == SVt_PVHV ) {
        ::Net::NATS::Streaming::PB::UnsubscribeRequest * other = __Net__NATS__Streaming__PB__UnsubscribeRequest_from_hashref(sv);
        THIS->CopyFrom(*other);
        delete other;
      }
    }


void
merge_from(svTHIS, sv)
  SV * svTHIS
  SV * sv
  CODE:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::UnsubscribeRequest");
    }
    if ( THIS != NULL && sv != NULL ) {
      if ( sv_derived_from(sv, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
        IV tmp = SvIV((SV *)SvRV(sv));
        ::Net::NATS::Streaming::PB::UnsubscribeRequest * other = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);

        THIS->MergeFrom(*other);
      } else if ( SvROK(sv) &&
                  SvTYPE(SvRV(sv)) == SVt_PVHV ) {
        ::Net::NATS::Streaming::PB::UnsubscribeRequest * other = __Net__NATS__Streaming__PB__UnsubscribeRequest_from_hashref(sv);
        THIS->MergeFrom(*other);
        delete other;
      }
    }


void
clear(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::UnsubscribeRequest");
    }
    if ( THIS != NULL ) {
      THIS->Clear();
    }


int
is_initialized(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::UnsubscribeRequest");
    }
    if ( THIS != NULL ) {
      RETVAL = THIS->IsInitialized();
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


SV *
error_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string estr;

  CODE:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::UnsubscribeRequest");
    }
    if ( THIS != NULL ) {
      estr = THIS->InitializationErrorString();
    }
    RETVAL = newSVpv(estr.c_str(), estr.length());

  OUTPUT:
    RETVAL


void
discard_unkown_fields(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::UnsubscribeRequest");
    }
    if ( THIS != NULL ) {
      THIS->DiscardUnknownFields();
    }


SV *
debug_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string dstr;

  CODE:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::UnsubscribeRequest");
    }
    if ( THIS != NULL ) {
      dstr = THIS->DebugString();
    }
    RETVAL = newSVpv(dstr.c_str(), dstr.length());

  OUTPUT:
    RETVAL


SV *
short_debug_string(svTHIS)
  SV * svTHIS
  PREINIT:
    string dstr;

  CODE:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::UnsubscribeRequest");
    }
    if ( THIS != NULL ) {
      dstr = THIS->ShortDebugString();
    }
    RETVAL = newSVpv(dstr.c_str(), dstr.length());

  OUTPUT:
    RETVAL


int
unpack(svTHIS, arg)
  SV * svTHIS
  SV * arg
  PREINIT:
    STRLEN len;
    char * str;

  CODE:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::UnsubscribeRequest");
    }
    if ( THIS != NULL ) {
      str = SvPV(arg, len);
      if ( str != NULL ) {
        RETVAL = THIS->ParseFromArray(str, len);
      } else {
        RETVAL = 0;
      }
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


SV *
pack(svTHIS)
  SV * svTHIS
  PREINIT:
    string output;

  CODE:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::UnsubscribeRequest");
    }
    if ( THIS != NULL ) {
      if ( THIS->IsInitialized() ) {
        if ( THIS->SerializePartialToString(&output)!= true ) {
          RETVAL = Nullsv;
        } else {
          RETVAL = newSVpvn(output.c_str(), output.length());
        }
      } else {
        croak("Can't serialize message of type 'Net::NATS::Streaming::PB::UnsubscribeRequest' because it is missing required fields: %s",
              THIS->InitializationErrorString().c_str());
      }
    } else {
      RETVAL = Nullsv;
    }

  OUTPUT:
    RETVAL


int
length(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::UnsubscribeRequest");
    }
    if ( THIS != NULL ) {
      RETVAL = THIS->ByteSize();
    } else {
      RETVAL = 0;
    }

  OUTPUT:
    RETVAL


void
fields(svTHIS)
  SV * svTHIS
  PPCODE:
    (void)svTHIS;
    EXTEND(SP, 4);
    PUSHs(sv_2mortal(newSVpv("clientID",0)));
    PUSHs(sv_2mortal(newSVpv("subject",0)));
    PUSHs(sv_2mortal(newSVpv("inbox",0)));
    PUSHs(sv_2mortal(newSVpv("durableName",0)));


SV *
to_hashref(svTHIS)
  SV * svTHIS
  CODE:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::UnsubscribeRequest");
    }
    if ( THIS != NULL ) {
      HV * hv0 = newHV();
      ::Net::NATS::Streaming::PB::UnsubscribeRequest * msg0 = THIS;

      if ( msg0->has_clientid() ) {
        SV * sv0 = newSVpv(msg0->clientid().c_str(), msg0->clientid().length());
        hv_store(hv0, "clientID", sizeof("clientID") - 1, sv0, 0);
      }
      if ( msg0->has_subject() ) {
        SV * sv0 = newSVpv(msg0->subject().c_str(), msg0->subject().length());
        hv_store(hv0, "subject", sizeof("subject") - 1, sv0, 0);
      }
      if ( msg0->has_inbox() ) {
        SV * sv0 = newSVpv(msg0->inbox().c_str(), msg0->inbox().length());
        hv_store(hv0, "inbox", sizeof("inbox") - 1, sv0, 0);
      }
      if ( msg0->has_durablename() ) {
        SV * sv0 = newSVpv(msg0->durablename().c_str(), msg0->durablename().length());
        hv_store(hv0, "durableName", sizeof("durableName") - 1, sv0, 0);
      }
      RETVAL = newRV_noinc((SV *)hv0);
    } else {
      RETVAL = Nullsv;
    }

  OUTPUT:
    RETVAL


I32
has_clientID(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::UnsubscribeRequest");
    }
    RETVAL = THIS->has_clientid();

  OUTPUT:
    RETVAL


void
clear_clientID(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::UnsubscribeRequest");
    }
    THIS->clear_clientid();


void
clientID(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::UnsubscribeRequest");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->clientid().c_str(),
                              THIS->clientid().length()));
      PUSHs(sv);
    }


void
set_clientID(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::UnsubscribeRequest");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_clientid(sval);


I32
has_subject(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::UnsubscribeRequest");
    }
    RETVAL = THIS->has_subject();

  OUTPUT:
    RETVAL


void
clear_subject(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::UnsubscribeRequest");
    }
    THIS->clear_subject();


void
subject(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::UnsubscribeRequest");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->subject().c_str(),
                              THIS->subject().length()));
      PUSHs(sv);
    }


void
set_subject(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::UnsubscribeRequest");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_subject(sval);


I32
has_inbox(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::UnsubscribeRequest");
    }
    RETVAL = THIS->has_inbox();

  OUTPUT:
    RETVAL


void
clear_inbox(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::UnsubscribeRequest");
    }
    THIS->clear_inbox();


void
inbox(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::UnsubscribeRequest");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->inbox().c_str(),
                              THIS->inbox().length()));
      PUSHs(sv);
    }


void
set_inbox(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::UnsubscribeRequest");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_inbox(sval);


I32
has_durableName(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::UnsubscribeRequest");
    }
    RETVAL = THIS->has_durablename();

  OUTPUT:
    RETVAL


void
clear_durableName(svTHIS)
  SV * svTHIS;
  CODE:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::UnsubscribeRequest");
    }
    THIS->clear_durablename();


void
durableName(svTHIS)
  SV * svTHIS;
PREINIT:
    SV * sv;

  PPCODE:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::UnsubscribeRequest");
    }
    if ( THIS != NULL ) {
      EXTEND(SP,1);
      sv = sv_2mortal(newSVpv(THIS->durablename().c_str(),
                              THIS->durablename().length()));
      PUSHs(sv);
    }


void
set_durableName(svTHIS, svVAL)
  SV * svTHIS
  SV *svVAL

  PREINIT:
    char * str;
    STRLEN len;
    string sval;

  CODE:
    ::Net::NATS::Streaming::PB::UnsubscribeRequest * THIS;
    if ( sv_derived_from(svTHIS, "Net::NATS::Streaming::PB::UnsubscribeRequest") ) {
      IV tmp = SvIV((SV *)SvRV(svTHIS));
      THIS = INT2PTR(__Net__NATS__Streaming__PB__UnsubscribeRequest *, tmp);
    } else {
      croak("THIS is not of type Net::NATS::Streaming::PB::UnsubscribeRequest");
    }
    str = SvPV(svVAL, len);
    sval.assign(str, len);
    THIS->set_durablename(sval);

MODULE = Net::NATS::Streaming::PB PACKAGE = Net::NATS::Streaming::PB
PROTOTYPES: ENABLE


