#include "net_drizzle.h"

=head1 NAME

Net::Drizzle::Query - Query object for Net::Drizzle

=head1 METHODS

=over 4

=cut

MODULE = Net::Drizzle::Query  PACKAGE = Net::Drizzle::Query

VERSIONCHECK: DISABLE

=item con

Get a connection for a query.

=cut

SV*
con(SV*self)
CODE:
    net_query *query = XS_STATE(net_query*, self);
    drizzle_con_st * con = drizzle_query_con(query->query);
    assert(con);
    RETVAL = _create_con(query->drizzle, con);
OUTPUT:
    RETVAL

=item string

Get the string for a query.

=cut
void
string(SV*self)
PPCODE:
    net_query *query = XS_STATE(net_query*, self);
    size_t size;
    const char * str = drizzle_query_string(query->query, &size);
    mXPUSHs(newSVpvn(str, size));
    XSRETURN(1);

=item result

Get the result for a query.

=back

=cut
SV*
result(SV*self)
CODE:
    net_query *query = XS_STATE(net_query*, self);
    drizzle_result_st *result = drizzle_query_result(query->query);
    if (result != NULL) {
        RETVAL = _create_result(query->con, self, result);
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

void
DESTROY(SV *self_sv)
CODE:
    net_query *self = XS_STATE(net_query*, self_sv);

    LOG("DESTROY query 0x%X, drizzle->refcnt=%d\n", (unsigned int)self->drizzle, (int)SvREFCNT(self->drizzle));

    if (self->drizzle != NULL) {
        SvREFCNT_dec(self->drizzle);
    }
    if (self->con != NULL) {
        SvREFCNT_dec(self->con);
    }
    Safefree(self);

=head1 SEE ALSO

L<Net::Drizzle>

=cut

