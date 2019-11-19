MODULE = MsgPack::Raw                 PACKAGE = MsgPack::Raw::Unpacker

Unpacker
new (class)
	SV *class

	PREINIT:
		msgpack_raw_unpacker *self;

	CODE:
		Newxz (self, 1, msgpack_raw_unpacker);
		if (!msgpack_unpacker_init (&self->unpacker, MSGPACK_UNPACKER_INIT_BUFFER_SIZE))
		{
			Safefree (self);
			croak ("Could not allocate msgpack unpacker");
		}

		RETVAL = self;

	OUTPUT: RETVAL

void
DESTROY (self)
	Unpacker self

	CODE:
		msgpack_unpacker_destroy (&self->unpacker);
		Safefree (self);

void
feed (self, buffer)
	Unpacker self
	SV *buffer

	PREINIT:
		const char *b;
		STRLEN size, available;

	CODE:
		b = SvPV (buffer, size);

		available = msgpack_unpacker_buffer_capacity (&self->unpacker);
		if (size > available)
		{
			STRLEN extra = size-available;
			msgpack_unpacker_reserve_buffer (&self->unpacker, extra);
		}

		memcpy (msgpack_unpacker_buffer (&self->unpacker), b, size);
		msgpack_unpacker_buffer_consumed (&self->unpacker, size);

void
next (self)
	Unpacker self

	PREINIT:
		msgpack_unpacked u;
		msgpack_unpack_return ret;

	PPCODE:
		msgpack_unpacked_init (&u);
		ret = msgpack_unpacker_next (&self->unpacker, &u);
		switch (ret)
		{
			case MSGPACK_UNPACK_SUCCESS:
				mXPUSHs (decode_msgpack (&u.data));
				msgpack_unpacked_destroy (&u);
				XSRETURN (1);
				break;

			case MSGPACK_UNPACK_CONTINUE:
				msgpack_unpacked_destroy (&u);
				XSRETURN_UNDEF;
				break;

			case MSGPACK_UNPACK_PARSE_ERROR:
				msgpack_unpacked_destroy (&u);
				croak ("unpack: parse error");
				break;

			case MSGPACK_UNPACK_NOMEM_ERROR:
				msgpack_unpacked_destroy (&u);
				croak ("unpack: oom");
				break;

			default:
				msgpack_unpacked_destroy (&u);
				croak ("unpack: unknown error");
				break;
		}

