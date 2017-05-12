#include "net_drizzle.h"

=head1 NAME

Net::Drizzle::Column - Column object for Net::Drizzle

=head1 METHODS

=over 4

=cut

MODULE = Net::Drizzle::Column  PACKAGE = Net::Drizzle::Column

VERSIONCHECK: DISABLE


const char*
catalog(SV*self)
CODE:
    /**
     *     my $catalog = $column->catalog;
     *
     * Get catalog for a column.
     *
     */
    const char *ret = drizzle_column_catalog((XS_STATE(net_col*, self))->col);
    if (ret != NULL) {
        RETVAL = ret;
    } else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

SV*
set_catalog(SV*self, const char* arg)
CODE:
    /**
     *     my $catalog = $column->catalog;
     *
     * Set catalog for a column.
     *
     */
    drizzle_column_set_catalog((XS_STATE(net_col*, self))->col, arg);
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL


const char*
db(SV*self)
CODE:
    /**
     *     my $db = $column->db;
     *
     * Get db for a column.
     *
     */
    const char *ret = drizzle_column_db((XS_STATE(net_col*, self))->col);
    if (ret != NULL) {
        RETVAL = ret;
    } else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

SV*
set_db(SV*self, const char* arg)
CODE:
    /**
     *     my $db = $column->db;
     *
     * Set db for a column.
     *
     */
    drizzle_column_set_db((XS_STATE(net_col*, self))->col, arg);
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL


const char*
table(SV*self)
CODE:
    /**
     *     my $table = $column->table;
     *
     * Get table for a column.
     *
     */
    const char *ret = drizzle_column_table((XS_STATE(net_col*, self))->col);
    if (ret != NULL) {
        RETVAL = ret;
    } else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

SV*
set_table(SV*self, const char* arg)
CODE:
    /**
     *     my $table = $column->table;
     *
     * Set table for a column.
     *
     */
    drizzle_column_set_table((XS_STATE(net_col*, self))->col, arg);
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL


const char*
orig_table(SV*self)
CODE:
    /**
     *     my $orig_table = $column->orig_table;
     *
     * Get orig_table for a column.
     *
     */
    const char *ret = drizzle_column_orig_table((XS_STATE(net_col*, self))->col);
    if (ret != NULL) {
        RETVAL = ret;
    } else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

SV*
set_orig_table(SV*self, const char* arg)
CODE:
    /**
     *     my $orig_table = $column->orig_table;
     *
     * Set orig_table for a column.
     *
     */
    drizzle_column_set_orig_table((XS_STATE(net_col*, self))->col, arg);
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL


const char*
name(SV*self)
CODE:
    /**
     *     my $name = $column->name;
     *
     * Get name for a column.
     *
     */
    const char *ret = drizzle_column_name((XS_STATE(net_col*, self))->col);
    if (ret != NULL) {
        RETVAL = ret;
    } else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

SV*
set_name(SV*self, const char* arg)
CODE:
    /**
     *     my $name = $column->name;
     *
     * Set name for a column.
     *
     */
    drizzle_column_set_name((XS_STATE(net_col*, self))->col, arg);
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL


const char*
orig_name(SV*self)
CODE:
    /**
     *     my $orig_name = $column->orig_name;
     *
     * Get orig_name for a column.
     *
     */
    const char *ret = drizzle_column_orig_name((XS_STATE(net_col*, self))->col);
    if (ret != NULL) {
        RETVAL = ret;
    } else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

SV*
set_orig_name(SV*self, const char* arg)
CODE:
    /**
     *     my $orig_name = $column->orig_name;
     *
     * Set orig_name for a column.
     *
     */
    drizzle_column_set_orig_name((XS_STATE(net_col*, self))->col, arg);
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL


=item set_charset

Set charset for column.

=cut

SV*
set_charset(SV*self, U8 arg)
CODE:
    drizzle_column_set_charset(XS_STATE(net_col*, self)->col, arg);
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL

=item set_size

Set size for column.

=cut

SV*
set_size(SV*self, U32 arg)
CODE:
    drizzle_column_set_size(XS_STATE(net_col*, self)->col, arg);
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL

=item set_type

Set type for column.

=cut

SV*
set_type(SV*self, int arg)
CODE:
    drizzle_column_set_type(XS_STATE(net_col*, self)->col, arg);
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL

=item write

Write column information.

=back

=cut

SV*
write(SV * self)
CODE:
    net_col *col = XS_STATE(net_col*, self);
    drizzle_result_st * result = drizzle_column_drizzle_result(col->col);
    drizzle_return_t ret = drizzle_column_write(result, col->col);
    if (ret != DRIZZLE_RETURN_OK) {
        drizzle_con_st * con = drizzle_result_drizzle_con(result);
        drizzle_st * drizzle = drizzle_con_drizzle(con);
        Perl_croak(aTHX_ "drizzle_column_write:%s\n", drizzle_error(drizzle));
    }
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL

void
DESTROY(net_col *self)
CODE:
    /**
     * Destructor.
     */
    LOG("DESTROY column 0x%X\n", (unsigned int)self->drizzle);

    if (self->drizzle != NULL) {
        SvREFCNT_dec(self->drizzle);
    }
    if (self->con != NULL) {
        SvREFCNT_dec(self->con);
    }
    if (self->result != NULL) {
        SvREFCNT_dec(self->result);
    }
    Safefree(self);

=head1 SEE ALSO

L<Net::Drizzle>

=cut

