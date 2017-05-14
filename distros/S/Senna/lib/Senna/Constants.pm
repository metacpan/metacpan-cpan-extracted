# $Id: /mirror/Senna-Perl/lib/Senna/Constants.pm 2862 2006-08-26T15:08:36.484922Z daisuke  $
#
# Copyright (c) 2005-2006 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package Senna::Constants;
use strict;
use base qw(Exporter);
our(@EXPORT_OK, %EXPORT_TAGS);
BEGIN
{
    my %tags = (
        key_size => [ qw(
            SEN_VARCHAR_KEY
            SEN_INT_KEY
        ) ],
        flags => [ qw(
            SEN_INDEX_NORMALIZE
            SEN_INDEX_SPLIT_ALPHA
            SEN_INDEX_SPLIT_DIGIT
            SEN_INDEX_SPLIT_SYMBOL
            SEN_INDEX_MORPH_ANALYSE
            SEN_INDEX_NGRAM
            SEN_INDEX_DELIMITED
            SEN_INDEX_ENABLE_PREFIX_SEARCH
            SEN_INDEX_ENABLE_SUFFIX_SEARCH
            SEN_INDEX_DISABLE_SUFFIX_SEARCH
            SEN_INDEX_WITH_VACUUM
        ) ],
        encoding => [ qw(
            SEN_ENC_DEFAULT
            SEN_ENC_NONE
            SEN_ENC_EUCJP
            SEN_ENC_UTF8
            SEN_ENC_SJIS
        ) ],
        query => [ qw(
            SEN_QUERY_ADJ_DEC
            SEN_QUERY_ADJ_INC
            SEN_QUERY_ADJ_NEG
            SEN_QUERY_AND
            SEN_QUERY_BUT
            SEN_QUERY_PARENL
            SEN_QUERY_PARENR
            SEN_QUERY_PREFIX
            SEN_QUERY_QUOTEL
            SEN_QUERY_QUOTER
        ) ],
        rc => [ qw(
            SEN_RC_SUCCESS
            SEN_RC_MEMORY_EXHAUSTED
            SEN_RC_INVALID_FORMAT
            SEN_RC_FILE_ERR
            SEN_RC_INVALID_ARG
            SEN_RC_OTHER
        ) ],
        rec_unit => [ qw(
            SEN_REC_DOCUMENT
            SEN_REC_SECTION
            SEN_REC_POSITION
            SEN_REC_USERDEF
            SEN_REC_NONE
        ) ],
        sel_op => [ qw(
            SEN_SELOP_OR
            SEN_SELOP_AND
            SEN_SELOP_BUT
            SEN_SELOP_ADJUST
        ) ],
        sel_mode => [ qw(
            SEN_SELMODE_EXACT
            SEN_SELMODE_PARTIAL
            SEN_SELMODE_UNSPLIT
            SEN_SELMODE_NEAR
            SEN_SELMODE_SIMILAR
            SEN_SELMODE_TERM_EXTRACT
        ) ],
        sort => [ qw(
            SEN_SORT_ASC
            SEN_SORT_DESC
        ) ],
        log => [ qw(
            SEN_LOG_NONE
            SEN_LOG_EMERG
            SEN_LOG_ALERT
            SEN_LOG_CRIT
            SEN_LOG_ERROR
            SEN_LOG_WARNING
            SEN_LOG_NOTICE
            SEN_LOG_INFO
            SEN_LOG_DEBUG
            SEN_LOG_DUMP
        )],
    );
    $EXPORT_TAGS{all} = [];
    while (my($tag, $symbols) = each %tags) {
        $EXPORT_TAGS{$tag} = $symbols;
        push @{$EXPORT_TAGS{all}}, @$symbols;
    }
    Exporter::export_ok_tags('all', keys %tags);
}

1;

__END__

=head1 NAME

Senna::Constants - Constant Values In libsenna

=head1 SYNOPSIS

  use Senna::Constants qw(
    :key_size
    :flags
    :encoding
    :query
    :rc
    :rec_unit
    :sel_op
    :sel_mode
    :sort
    :log
  );

  use Senna::Constants qw(:all);

=head1 DESCRIPTION

Senna:::Constants gives you access to the various constant values defined in
libsenna. 

=head1 CONSTANTS

=head2 LIBSENNA_VERSION

This constant is not exported.

=head2 SEN_VARCHAR_KEY

=head2 SEN_INT_KEY

=head2 SEN_INDEX_NORMALIZE

=head2 SEN_INDEX_SPLIT_ALPHA

=head2 SEN_INDEX_SPLIT_DIGIT

=head2 SEN_INDEX_SPLIT_SYMBOL

=head2 SEN_INDEX_MORPH_ANALYSE

=head2 SEN_INDEX_NGRAM

=head2 SEN_INDEX_DELIMITED

=head2 SEN_INDEX_ENABLE_PREFIX_SEARCH

=head2 SEN_INDEX_ENABLE_SUFFIX_SEARCH

=head2 SEN_INDEX_DISABLE_SUFFIX_SEARCH

=head2 SEN_INDEX_WITH_VACUUM

=head2 SEN_ENC_DEFAULT

=head2 SEN_ENC_NONE

=head2 SEN_ENC_EUCJP

=head2 SEN_ENC_UTF8

=head2 SEN_ENC_SJIS

=head2 SEN_QUERY_ADJ_DEC

=head2 SEN_QUERY_ADJ_INC

=head2 SEN_QUERY_ADJ_NEG

=head2 SEN_QUERY_AND

=head2 SEN_QUERY_BUT

=head2 SEN_QUERY_PARENL

=head2 SEN_QUERY_PARENR

=head2 SEN_QUERY_PREFIX

=head2 SEN_QUERY_QUOTEL

=head2 SEN_QUERY_QUOTER

=head2 SEN_RC_SUCCESS

=head2 SEN_RC_MEMORY_EXHAUSTED

=head2 SEN_RC_INVALID_FORMAT

=head2 SEN_RC_FILE_ERR

=head2 SEN_RC_INVALID_ARG

=head2 SEN_RC_OTHER

=head2 SEN_REC_DOCUMENT

=head2 SEN_REC_SECTION

=head2 SEN_REC_POSITION

=head2 SEN_REC_USERDEF

=head2 SEN_REC_NONE

=head2 SEN_SELOP_OR

=head2 SEN_SELOP_AND

=head2 SEN_SELOP_BUT

=head2 SEN_SELOP_ADJUST

=head2 SEN_SELMODE_EXACT

=head2 SEN_SELMODE_PARTIAL

=head2 SEN_SELMODE_UNSPLIT

=head2 SEN_SELMODE_NEAR

=head2 SEN_SELMODE_SIMILAR

=head2 SEN_SELMODE_TERM_EXTRACT

=head2 SEN_SORT_ASC

=head2 SEN_SORT_DESC

=head2 SEN_LOG_NONE

=head2 SEN_LOG_EMERG

=head2 SEN_LOG_ALERT

=head2 SEN_LOG_CRIT

=head2 SEN_LOG_ERROR

=head2 SEN_LOG_WARNING

=head2 SEN_LOG_NOTICE

=head2 SEN_LOG_INFO

=head2 SEN_LOG_DEBUG

=head2 SEN_LOG_DUMP

=cut