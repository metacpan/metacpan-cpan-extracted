# NAME

Net::Hadoop::DFSAdmin::ReportParser - Parser module for 'hadoop dfsadmin -report'

# SYNOPSIS

    use Net::Hadoop::DFSAdmin::ReportParser;
    open($fh, '-|', 'hadoop', 'dfsadmin', '-report')
        or die "failed to execute 'hadoop dfsadmin -report'";
    my @lines = <$fh>;
    close($fh);

    my $r = Net::Hadoop::DFSAdmin::ReportParser->parse(@lines);

# AUTHOR

TAGOMORI Satoshi <tagomoris {at} gmail.com>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
