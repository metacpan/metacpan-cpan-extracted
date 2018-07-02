package Pcore::Ext::Lib::Overrides::Classic;

use Pcore -l10n;

# set buffered store defaults: pageSize, leadingBufferZone
sub EXT_override_data_BufferedStore : Override('Ext.data.BufferedStore') : Ext('classic') {
    return {
        config => {

            # to load the first page with the single request
            pageSize          => 200,
            leadingBufferZone => 100
        }
    };
}

# https: //www.sencha.com/forum/showthread.php?304363-Buffered-Store-Fatal-HasRange-Call
# this bug is present in classic v6.2.0
# TODO test under v6.5.3
sub EXT_override_data_PageMap : Override('Ext.data.PageMap') : Ext('classic') {
    return {
        hasRange => func [ 'start', 'end' ],
        <<'JS',
            var pageNumber = this.getPageFromRecordIndex(start),
                endPageNumber = this.getPageFromRecordIndex(end);

            for (; pageNumber <= endPageNumber; pageNumber++) {
                if (!this.hasPage(pageNumber)) {
                    return false;
                }
            }

            return true;
JS
    };
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Lib::Overrides::Classic

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
