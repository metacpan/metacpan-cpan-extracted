package RT::Action::CIFMinimal_ReopenReport;
use base 'RT::Action::Generic';

require CIF::FeedParser::ParseJsonIodef;
require CIF::Archive;
require JSON;

sub Prepare { return 1; }

sub Commit {
	my $self = shift;

    my $r = $self->TicketObj->IODEF();

    my $ret = CIF::FeedParser::ParseJsonIodef::parse({},JSON::to_json([$r->to_tree()]));

    foreach(@$ret){
        $_->{'detecttime'} = DateTime->from_epoch(epoch => time());
        my ($err,$id) = CIF::Archive->insert($_);
        warn $err if($err);
        warn $id if($id);
    }
}

1;
