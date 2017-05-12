 #
 # Copyright (c) 1997-2009 Michael Fuhr.  All rights reserved.  This
 # program is free software; you can redistribute it and/or modify it
 # under the same terms as Perl itself.
 #
 # Net::DNS is currently maintained by a group, led by:
 #       Chris Reinhardt
 #       ctriv@net-dns.org
 #
 # Net::DNS was created by:
 #       Michael Fuhr
 #       mike@fuhr.org 
 #
 # Modified ever so slightly and those changes are
 # Copyright 2003-2009 Michael Robinton. All rights reserved.  This
 # program is free software; you can redistribute it and/or modify it
 # under the same terms as Perl itself.
 #
 #
 # int dn_expand(unsigned char *msg, unsigned char *eomorig,
 #	unsigned char *comp_dn, unsigned char *exp_dn, int length);
 #	   
 # dn_expand
 #	dn_expand() expands the compressed domain name given by the
 #	pointer comp _dn into a full domain name. Expanded names are
 #	converted to upper case. The compressed name is contained in
 #	a query or reply message; msg is a pointer to the beginning
 #	of that message. Expanded names are stored in the buffer
 #	referenced by the exp_dn buffer of size length, which should
 #	be large enough to hold the expanded result.
 #
 #	dn_expand() returns the size of the compressed name, or  -1
 #	if there was an error. 
 #

void
dn_expand(buffer, offset) 
	SV * buffer
	int offset
    PROTOTYPE: $$		
    PPCODE:
	STRLEN len;
	u_char * buf;
	char name[MAXDNAME];
	int size;

	if (SvROK(buffer)) 
	    buffer = SvRV(buffer);

	buf = (u_char *)SvPV(buffer, len);
	size = dn_expand(buf, buf+len, buf+offset, &name[0], MAXDNAME);

	if (size < 0) {
	    XSRETURN_EMPTY;
	} else {
	    EXTEND(SP, 2);
	    PUSHs(sv_2mortal(newSViv(size + offset)));
	    PUSHs(sv_2mortal(newSVpv(name, 0)));
	}
	XSRETURN(2);

