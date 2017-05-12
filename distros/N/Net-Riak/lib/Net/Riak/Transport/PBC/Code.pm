package Net::Riak::Transport::PBC::Code;
{
  $Net::Riak::Transport::PBC::Code::VERSION = '0.1702';
}
use strict;
use warnings;
use base 'Exporter';

our @EXPORT_OK = qw/
    REQ_CODE
    RESP_CLASS
    EXPECTED_RESP
    RESP_DECODER
/;

sub EXPECTED_RESP {
    my $code = shift;
    return {
        1 => 2,
        3 => 4,
        5 => 6,
        7 => 8,
        9 => 10,
        11 => 12,
        13 => 14,
        15 => 16,
        17 => 18,
        19 => 20,
        21 => 22,
        23 => 24,
    }->{$code};
}
sub RESP_CLASS {
    my $code = shift;

    return {
        0 => 'RpbErrorResp',
        2 => 'RpbPingResp',
        4 => 'RpbGetClientIdResp',
        6 => 'RpbSetClientIdResp',
        8 => 'RpbGetServerInfoResp',
        10 => 'RpbGetResp',
        12 => 'RpbPutResp',
        14 => 'RpbDelResp',
        16 => 'RpbListBucketsResp',
        18 => 'RpbListKeysResp',
        20 => 'RpbGetBucketResp',
        22 => 'RpbSetBucketResp',
        24 => 'RpbMapRedResp',
    }->{$code};
}

sub RESP_DECODER {
    my $code = shift;

    return {
        0 => 'RpbErrorResp',
        2 => undef,
        4 => 'RpbGetClientIdResp',
        6 => undef,
        8 => 'RpbGetServerInfoResp',
        10 =>  'RpbGetResp',
        12 =>  'RpbPutResp',
        14 =>  undef,
        16 =>  'RpbListBucketsResp',
        18 =>  'RpbListKeysResp',
        20 =>  'RpbGetBucketResp',
        22 =>  undef,
        24 =>  'RpbMapRedResp'
    }->{$code};
};


sub REQ_CODE {
    my $class = shift;

    return {
        RpbPingReq => 1,
        RpbGetClientIdReq => 3,
        RpbSetClientIdReq => 5,
        RpbGetServerInfoReq => 7,
        RpbGetReq => 9,
        RpbPutReq => 11,
        RpbDelReq => 13,
        RpbListBucketsReq => 15,
        RpbListKeysReq => 17,
        RpbGetBucketReq => 19,
        RpbSetBucketReq => 21,
        RpbMapRedReq => 23,
    }->{$class};
}

1;

__END__

=pod

=head1 NAME

Net::Riak::Transport::PBC::Code

=head1 VERSION

version 0.1702

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>, robin edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
