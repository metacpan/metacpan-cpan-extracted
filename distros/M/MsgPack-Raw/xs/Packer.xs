MODULE = MsgPack::Raw                 PACKAGE = MsgPack::Raw::Packer

Packer
new (class)
	SV *class

	PREINIT:
		msgpack_raw_packer *self;

	CODE:
		Newxz (self, 1, msgpack_raw_packer);
		msgpack_packer_init (&self->packer, self, msgpack_raw_packer_write);

		RETVAL = self;

	OUTPUT: RETVAL

SV *
pack (self, content)
	Packer self
	SV *content

	CODE:
		// create the output buffer
		self->data = sv_2mortal (newSV (64));
		SvPOK_only (self->data);
		encode_msgpack (self, content);

		SvREFCNT_inc (self->data);
		RETVAL = self->data;

	OUTPUT: RETVAL

void
DESTROY (self)
	Packer self

	CODE:
		Safefree (self);
