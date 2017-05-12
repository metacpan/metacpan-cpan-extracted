#include "net_drizzle.h"

=pod

=head1 NAME

Net::Drizzle::Result - result object for Net::Drizzle

=head1 METHODS

=over 4

=cut

MODULE = Net::Drizzle::Result  PACKAGE = Net::Drizzle::Result

VERSIONCHECK: DISABLE

=item my $column = $result->column_next();

Get next buffered column from a result structure.

=cut
net_col*
column_next(SV *self_sv)
CODE:
    net_result *self_result = XS_STATE(net_result*, self_sv);
    drizzle_result_st *result = self_result->result;
    drizzle_column_st * col = drizzle_column_next(result);
    if (col) {
        RETVAL = _create_col(self_sv, col);
    } else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

=item my $err = $result->error_code();

get the error code for result.

=cut
int
error_code(net_result *self)
CODE:
    drizzle_result_st *result = self->result;
    if (result == NULL) {
        Perl_croak(aTHX_ "result is null");
    }
    RETVAL = drizzle_result_error_code(result);
OUTPUT:
    RETVAL

=item my $err = $result->error();

get the error message for result.

=cut
const char*
error(net_result *self)
CODE:
    drizzle_result_st *result = self->result;
    RETVAL = drizzle_result_error(result);
OUTPUT:
    RETVAL

=item my $info = $result->info();

get the info message.

=cut
const char*
info(net_result *self)
CODE:
    drizzle_result_st *result = self->result;
    RETVAL = drizzle_result_info(result);
OUTPUT:
    RETVAL



uint64_t
row_count(net_result *self)
CODE:
    drizzle_result_st *result = self->result;
    RETVAL = drizzle_result_row_count(result);
OUTPUT:
    RETVAL


uint64_t
insert_id(net_result *self)
CODE:
    drizzle_result_st *result = self->result;
    RETVAL = drizzle_result_insert_id(result);
OUTPUT:
    RETVAL


uint16_t
warning_count(net_result *self)
CODE:
    drizzle_result_st *result = self->result;
    RETVAL = drizzle_result_warning_count(result);
OUTPUT:
    RETVAL


=item my $column_count = $result->column_count();

get the number of columns.

=cut
unsigned int
column_count(net_result *self)
CODE:
    drizzle_result_st *result = self->result;
    RETVAL = drizzle_result_column_count(result);
OUTPUT:
    RETVAL

=item $result->buffer();

Buffer all data for a result.

=cut
drizzle_return_t
buffer(net_result *self)
CODE:
    drizzle_result_st *result = self->result;
    drizzle_return_t ret = drizzle_result_buffer(result);
    if (ret != DRIZZLE_RETURN_OK) {
        drizzle_con_st * con = drizzle_result_drizzle_con(result);
        drizzle_st * drizzle = drizzle_con_drizzle(con);
        Perl_croak(aTHX_ "drizzle_result_buffer:%s\n", drizzle_error(drizzle));
    }
    RETVAL = ret;
OUTPUT:
    RETVAL

=item my $col = $result->column_read();

Read column information.

=cut
net_col*
column_read(SV *self_sv)
CODE:
    net_result * self_result = XS_STATE(net_result *, self_sv);
    drizzle_result_st *result = self_result->result;
    drizzle_return_t ret;
    drizzle_column_st *col = drizzle_column_read(result, NULL, &ret);
    if (col != NULL) {
        RETVAL = _create_col(self_sv, col);
    } else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

=item $result->row_next();

Get next buffered row from a fully buffered result.

=item $result->fetchrow_arrayref();

alias of row_next() for DBI users

=cut
SV*
row_next(net_result *self)
CODE:
    drizzle_result_st *result = self->result;
    drizzle_row_t row = drizzle_row_next(result);
    uint16_t cnt = drizzle_result_column_count(result);
    if (row) {
        RETVAL = row2arrayref(row, cnt);
    } else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

=item row_buffer

Buffer one row.

=cut
SV*
row_buffer(net_result *self)
CODE:
    drizzle_result_st *result = self->result;
    drizzle_return_t ret;
    drizzle_row_t row = drizzle_row_buffer(result, &ret);
    uint16_t cnt = drizzle_result_column_count(result);
    if (ret == DRIZZLE_RETURN_OK && row) {
        RETVAL = row2arrayref(row, cnt);
    } else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL


=item $result->set_column_count($n);

Set the number of fields in a result set.

=cut
SV*
set_column_count(SV*self_sv, U16 column_count)
CODE:
    net_result * self_result = XS_STATE(net_result*, self_sv);
    drizzle_result_st *result = self_result->result;
    drizzle_result_set_column_count(result, column_count);
    RETVAL = SvREFCNT_inc(self_sv);
OUTPUT:
    RETVAL

=item my $column = $result->column_create();

Create a instance of Net::Drizzle::Column.

=cut
net_col*
column_create(SV* self_sv)
CODE:
    net_result * self_result = XS_STATE(net_result*, self_sv);
    drizzle_result_st *result = self_result->result;
    drizzle_column_st *col_raw = drizzle_column_create(result, NULL);
    if (col_raw == NULL) {
        drizzle_con_st * con = drizzle_result_drizzle_con(result);
        drizzle_st * drizzle = drizzle_con_drizzle(con);
        Perl_croak(aTHX_ "drizzle_column_create:%s\n", drizzle_error(drizzle));
    }

    RETVAL = _create_col(self_sv, col_raw);
OUTPUT:
    RETVAL

=item $result->calc_row_size();

Set result row packet size from field and size arrays.

=cut
SV*
calc_row_size(SV * self, ...)
CODE:
    drizzle_result_st *result = XS_STATE(net_result*, self)->result;
    int i;
    size_t *sizes;
    drizzle_field_t * fields;
    Newx(sizes,  items-1, size_t);
    Newx(fields, items-1, drizzle_field_t);
    for (i=1; i<items; i++) { /* 1 means "skip SV* self" */
        STRLEN len;
        fields[i-1] = SvPV(ST(i), len);
        sizes[i-1]  = len;
        LOG("%d, %s, %d\n", i-1, fields[i-1], sizes[i-1]);
    }
    drizzle_result_calc_row_size(result, fields, sizes);
    Safefree(sizes);
    Safefree(fields);
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL

=item $result->fields_write(...);

Send a fields over a connection

=cut
SV*
fields_write(SV * self, ...)
CODE:
    drizzle_result_st *result = XS_STATE(net_result*, self)->result;
    int i;
    for (i=1; i<items; i++) { /* 1 means "skip SV* self" */
        size_t size;
        drizzle_field_t field;
        field = SvPV(ST(i), size);
        drizzle_return_t ret = drizzle_field_write(result, field, size, size);
        if (ret != DRIZZLE_RETURN_OK) {
            drizzle_con_st * con = drizzle_result_drizzle_con(result);
            drizzle_st * drizzle = drizzle_con_drizzle(con);
            Perl_croak(aTHX_ "drizzle_column_create:%s\n", drizzle_error(drizzle));
        }
    }
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL

=item my $row_number = $result->row_read;

Get next row number for unbuffered results. Use the $result->field* functions
to read individual fields after this function succeeds.

=cut
uint64_t
row_read(net_result *result)
CODE:
    drizzle_return_t ret;
    uint64_t cur = drizzle_row_read(result->result, &ret);
    if (ret != DRIZZLE_RETURN_OK) {
        drizzle_con_st * con = drizzle_result_drizzle_con(result->result);
        drizzle_st * drizzle = drizzle_con_drizzle(con);
        Perl_croak(aTHX_ "drizzle_column_create:%s\n", drizzle_error(drizzle));
    }
    RETVAL = cur;
OUTPUT:
    RETVAL

=item my ($ret, $field) = $res->field_buffer();

Buffer one field.

=cut
void
field_buffer(net_result *result)
PPCODE:
    /* my ($ret, $field) = $res->field_buffer(); */
    drizzle_return_t ret;
    size_t total;
    drizzle_field_t field = drizzle_field_buffer(result->result, &total, &ret);
    mXPUSHi(ret);
    mXPUSHs(field != NULL ? newSVpv(field, total) : newSV(0));
    XSRETURN(2);

=back

=head2 METHODS for servers

=over 4

=item $result->set_eof();

Set EOF for a result.

=cut
SV *
set_eof(SV *self_sv, bool eof)
CODE:
    net_result * self_result = XS_STATE(net_result *, self_sv);
    drizzle_result_st *result = self_result->result;
    drizzle_result_set_eof(result, eof);
    RETVAL = SvREFCNT_inc_simple(self_sv);
OUTPUT:
    RETVAL

=item $result->write($flush);

Write result packet.

=cut
SV *
write(SV *self_sv, bool flush)
CODE:
    net_result * self_result = XS_STATE(net_result *, self_sv);
    drizzle_result_st *result = self_result->result;
    drizzle_con_st * con = drizzle_result_drizzle_con(result);
    drizzle_result_write(con, result, flush);
    RETVAL = SvREFCNT_inc(self_sv);
OUTPUT:
    RETVAL

=item $result->row_write();

Write next row.

=cut
void
row_write(net_result *result)
CODE:
    drizzle_row_write(result->result);


void
DESTROY(net_result *self)
CODE:
    LOG("DESTROY result 0x%X, drizzle->refcnt=%d\n", (unsigned int)self->drizzle, (int)SvREFCNT(self->drizzle));

    if (self->drizzle != NULL) {
        SvREFCNT_dec(self->drizzle);
    }
    if (self->con != NULL) {
        SvREFCNT_dec(self->con);
    }
    if (self->query != NULL) {
        SvREFCNT_dec(self->query);
    }
    Safefree(self);

=back

=head1 SEE ALSO

L<Net::Drizzle>

=cut

