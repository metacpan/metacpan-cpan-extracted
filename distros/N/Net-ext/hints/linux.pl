# Override DEFINE for linux, since TCP_MSS is messed up in some distributions.
# I've not seen a Linux with an old (non-RFC-1122) TCP_MSS value, anyway.
$self->{DEFINE} =~ s/$/ -DBAD_TCP_MSS/;
$self->{DEFINE} =~ s/^\s+//;
1;
