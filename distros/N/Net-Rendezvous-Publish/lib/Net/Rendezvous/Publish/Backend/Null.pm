package Net::Rendezvous::Publish::Backend::Null;

sub new {
    warn "We won't be doing any rendezvous publishing, please install a Net::Rendezvous::Publish::Backend:: module\n";
    bless {};
}

sub publish {}
sub publish_stop {}
sub step {}

1;
