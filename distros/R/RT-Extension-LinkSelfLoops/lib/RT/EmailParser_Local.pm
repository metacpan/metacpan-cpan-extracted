sub CullRTAddresses {
    my $self = shift;
    my @addresses= (@_);
    return @addresses if RT->Config->Get('LinkSelfLoops');
    my @addrlist;

    foreach my $addr( @addresses ) {
                                 # We use the class instead of the instance
                                 # because sloppy code calls this method
                                 # without a $self
      push (@addrlist, $addr)    unless RT::EmailParser->IsRTAddress($addr);
    }
    return (@addrlist);
}

1;
