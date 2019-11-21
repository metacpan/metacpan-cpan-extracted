#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newSVpvn_flags
#define NEED_newRV_noinc
#define NEED_sv_2pvbyte
#define NEED_sv_2pv_flags

#include "ppport.h"

#ifndef MUTABLE_AV
#define MUTABLE_AV(p) ((AV *)MUTABLE_PTR(p))
#endif

#ifndef MUTABLE_SV
#define MUTABLE_SV(p) ((SV *)MUTABLE_PTR(p))
#endif

#ifndef MUTABLE_HV
#define MUTABLE_HV(p) ((HV *)MUTABLE_PTR(p))
#endif

#include <msgpack.h>

#if !(IVSIZE == 8 || IVSIZE == 4 || IVSIZE == 2)
#error "msgpack only supports IVSIZE = 8, 4 or 2"
#endif

typedef struct
{
	int code;
	SV *message;
	const char *file;
	unsigned int line;
} msgpack_raw_error;

typedef struct
{
	msgpack_packer packer;
	SV *data;
} msgpack_raw_packer;

typedef struct
{
	msgpack_unpacker unpacker;
} msgpack_raw_unpacker;

typedef msgpack_raw_packer *Packer;
typedef msgpack_raw_unpacker *Unpacker;

#define MSGPACK_NEW_OBJ(rv, package, sv)                   \
	STMT_START {                                       \
		(rv) = sv_setref_pv (newSV(0), package, sv);   \
	} STMT_END

STATIC void *msgpack_sv_to_ptr (const char *type, SV *sv, const char *file, int line)
{
	SV *full_type = sv_2mortal (newSVpvf ("MsgPack::Raw::%s", type));

	if (!(sv_isobject (sv) && sv_derived_from (sv, SvPV_nolen (full_type))))
	croak("Argument is not of type %s @ (%s:%d)\n",
		SvPV_nolen (full_type), file, line);

	return INT2PTR (void *, SvIV ((SV *) SvRV (sv)));
}

#define MSGPACK_SV_TO_PTR(type, sv) \
	msgpack_sv_to_ptr(#type, sv, __FILE__, __LINE__)

STATIC int msgpack_raw_packer_write(void *data, const char *buf, size_t len)
{
	msgpack_raw_packer *packer = (msgpack_raw_packer *)data;

	sv_catpvn (packer->data, buf, len);

	return 0;
}

STATIC void encode_msgpack (msgpack_raw_packer *packer, SV *sv)
{
	if (SvIOKp (sv))
	{
		if (SvUOK (sv))
		{
			#if IVSIZE == 8
			msgpack_pack_uint64 (&packer->packer, SvUVX (sv));
			#elif IVSIZE == 4
			msgpack_pack_uint32 (&packer->packer, SvUVX (sv));
			#elif IVSIZE == 2
			msgpack_pack_uint16 (&packer->packer, SvUVX (sv));
			#endif
		}
		else
		{
			#if IVSIZE == 8
			msgpack_pack_int64 (&packer->packer, SvIVX (sv));
			#elif IVSIZE == 4
			msgpack_pack_int32 (&packer->packer, SvIVX (sv));
			#elif IVSIZE == 2
			msgpack_pack_int16 (&packer->packer, SvIVX (sv));
			#endif
		}
	}
	else if (SvPOKp (sv))
	{
		if (SvUTF8 (sv))
		{
			msgpack_pack_str (&packer->packer, SvCUR (sv));
			msgpack_pack_str_body (&packer->packer, SvPVX_const (sv), SvCUR (sv));
		}
		else
		{
			msgpack_pack_bin (&packer->packer, SvCUR (sv));
			msgpack_pack_bin_body (&packer->packer, SvPVX_const (sv), SvCUR (sv));
		}
	}
	else if (SvNOKp (sv))
	{
		msgpack_pack_double (&packer->packer, (double)SvNVX (sv));
	}
	else if (SvROK (sv))
	{
		if (sv_isobject (sv) && sv_derived_from (sv, "MsgPack::Raw::Bool"))
		{
			if (SvIV (SvRV (sv)))
				msgpack_pack_true (&packer->packer);
			else
				msgpack_pack_false (&packer->packer);
		}
		else if (sv_isobject (sv) && sv_derived_from (sv, "MsgPack::Raw::Ext"))
		{
			HV *hash = MUTABLE_HV (SvRV (sv));
			SV **type = hv_fetchs (hash, "type", 0);
			SV **data = hv_fetchs (hash, "data", 0);

			if (!type || !SvOK (*type))
				croak ("MsgPack::Raw::Ext object doesn't have a type member");
			if (!data || !SvOK (*data))
				croak ("MsgPack::Raw::Ext object doesn't have a data member");
			if (!SvIOK(*type) || SvIV(*type) < 0 || SvIV(*type)>255)
				croak ("MsgPack::Raw::Ext type invalid");

			msgpack_pack_ext (&packer->packer, SvCUR (*data), SvIV (*type));
			msgpack_pack_ext_body (&packer->packer, SvPVX_const (*data), SvCUR (*data));
		}
		else if (SvTYPE (SvRV (sv)) == SVt_PVHV)
		{
			HV *hash = MUTABLE_HV (SvRV (sv));
			I32 count = hv_iterinit (hash);
			HE *entry;

			msgpack_pack_map (&packer->packer, count);
			while ((entry = hv_iternext (hash)))
			{
				encode_msgpack (packer, hv_iterkeysv (entry));
				encode_msgpack (packer, hv_iterval (hash, entry));
			}
		}
		else if (SvTYPE (SvRV (sv)) == SVt_PVAV)
		{
			AV *list = MUTABLE_AV (SvRV (sv));
			STRLEN i, size = av_len (list)+1;

			msgpack_pack_array (&packer->packer, size);
			for (i = 0; i < size; ++i)
			{
				SV **value = av_fetch (list, i, 0);
				if (value && *value)
					encode_msgpack (packer, *value);
				else
					msgpack_pack_nil (&packer->packer);
			}
		}
		else
		{
			croak ("encountered object '%s', Data::MessagePack doesn't allow the object",
				SvPV_nolen (sv_2mortal (newRV_inc (sv))));
		}
	}
	else if (!SvOK (sv))
	{
		msgpack_pack_nil (&packer->packer);
	}
	else
	{
		croak ("cannot pack type: %d\n", SvTYPE (sv));
	}
}

STATIC SV *decode_msgpack (msgpack_object *obj)
{
	switch (obj->type)
	{
		// simple types
		case MSGPACK_OBJECT_NIL:              return &PL_sv_undef;
		case MSGPACK_OBJECT_POSITIVE_INTEGER: return newSVuv (obj->via.u64);
		case MSGPACK_OBJECT_NEGATIVE_INTEGER: return newSViv (obj->via.i64);
		case MSGPACK_OBJECT_FLOAT32:          // fall-through
		case MSGPACK_OBJECT_FLOAT64:          return newSVnv (obj->via.f64);
		case MSGPACK_OBJECT_STR:              return newSVpvn_utf8 (obj->via.str.ptr, obj->via.str.size, 1);
		case MSGPACK_OBJECT_BIN:              return newSVpvn (obj->via.bin.ptr, obj->via.bin.size);

		// complex types
		case MSGPACK_OBJECT_BOOLEAN:
		{
			return sv_bless (newRV_noinc (newSViv (obj->via.boolean)),
				gv_stashpv ("MsgPack::Raw::Bool", 0));
		}
		case MSGPACK_OBJECT_ARRAY:
		{
			AV *list = MUTABLE_AV (sv_2mortal (MUTABLE_SV (newAV())));
			msgpack_object *items = obj->via.array.ptr;
			uint32_t size = obj->via.array.size;

			while (size--)
			{
				av_push (list, decode_msgpack (items++));
			}

			return newRV_inc (MUTABLE_SV (list));
		}
		case MSGPACK_OBJECT_MAP:
		{
			HV *hash = MUTABLE_HV (sv_2mortal (MUTABLE_SV (newHV())));
			msgpack_object_kv *items = obj->via.map.ptr;
			uint32_t size = obj->via.map.size;

			while (size--)
			{
				SV *key = sv_2mortal (decode_msgpack (&items->key));
				SV *value = sv_2mortal (decode_msgpack (&items->val));

				hv_store (hash, SvPVX (key), SvCUR (key), value, 0);
				SvREFCNT_inc_NN (value);

				++items;
			}

			return newRV_inc (MUTABLE_SV (hash));
		}
		case MSGPACK_OBJECT_EXT:
		{
			HV *hash = MUTABLE_HV (sv_2mortal (MUTABLE_SV (newHV())));
			hv_stores (hash, "type", newSViv (obj->via.ext.type));
			hv_stores (hash, "data", newSVpvn (obj->via.ext.ptr, obj->via.ext.size));
			return sv_bless (newRV_inc (MUTABLE_SV (hash)),
				gv_stashpv ("MsgPack::Raw::Ext", 0));
		}

		default:
			croak ("unknown object type: %d", obj->type);
	}

	// unreachable
	return &PL_sv_undef;
}

MODULE = MsgPack::Raw               PACKAGE = MsgPack::Raw

INCLUDE: xs/Packer.xs
INCLUDE: xs/Unpacker.xs

