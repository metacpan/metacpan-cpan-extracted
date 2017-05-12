package Net::LiveJournal;
use strict;
use warnings;
use Net::LiveJournal::Entry;
use Carp qw(croak);
use LWP;
use LWP::UserAgent;
use HTTP::Request;
use vars qw($VERSION);
$VERSION = '0.27';

sub new {
    my ($class, %opts) = @_;
    my $self = bless {}, $class;

    $self->{server}   = delete $opts{server} || "www.livejournal.com";
    $self->{user}     = delete $opts{user} || delete $opts{username};
    $self->{password} = delete $opts{pass} || delete $opts{password};
    croak("Unknown options: " . join(", ", %opts)) if %opts;

    return $self;
}

sub ua {
    my $self = shift;
    return $self->{ua} ||= do {
        LWP::UserAgent->new(agent => "Net::LiveJournal");
    };
}

sub post {
    my ($self, $entry) = @_;

    my $params = {
        mode       => "postevent",
        user       => $self->{user} || croak("No username provided in the Net::LiveJournal ($self) object"),
        password   => $self->{password},
        version    => 1,
        event      => $entry->body,
        subject    => $entry->subject,
        security   => $entry->security,
        allowmask  => $entry->allowmask,
        year       => $entry->year,
        mon        => $entry->month,
        day        => $entry->day,
        hour       => $entry->hour,
        min        => $entry->minute,
        usejournal => $entry->journal,
    };
    # TODO: props ("prop_<name>")

    my $ua = $self->ua;
    my $req = HTTP::Request->new(POST => $self->_flat);
    $req->content(_encode($params));
    my $res = _parse($ua->request($req));
    return 0 unless $self->is_success($res);
    return $res->{url};
}

sub errstr {
    my $self = shift;
    return $self->{lasterrstr};
}

sub is_success {
    my ($self, $res) = @_;
    $self->{lasterrstr} = undef;
    return 1 if $res->{success} eq "OK";

    $self->{lasterrstr} = $res->{errmsg};
    return 0;
}

sub _parse {
    my $res = shift;
    return { success => "FAIL", errmsg => "Undefined response" } unless $res;
    my $ret = {};
    unless ($res->is_success) {
        $ret->{success} = "FAIL";
        $ret->{errmsg} = $res->status_line;
        return $ret;
    }
    $ret = { split(/\n/, $res->content) };
    return $ret;
}

sub _encode {
    my $val = shift;
    $val = "" unless defined $val;
    if (ref $val) {
        my $ret = "";
        while (my ($k, $v) = each %$val) {
            $ret .= _encode($k) . "=" . _encode($v) . "&";
        }
        chop $ret;
        return $ret;
    } else {
        $val =~ s/([^a-zA-Z0-9_\,\-.\/\\\: ])/uc sprintf("%%%02x",ord($1))/eg;
        $val =~ tr/ /+/;
        return $val;
    }
}

sub _flat {
    my $self = shift;
    return "http://$self->{server}/interface/flat";
}

1;

__END__

=head1 NAME

Net::LiveJournal -- access LiveJournal's APIs

=head1 SYNOPSIS

 use Net::LiveJournal;

 # make an account object...
 $lj = Net::LiveJournal->new(user => "brad", password => "xxxx");

 # make an entry object...
 $entry = Net::LiveJournal::Entry->new(subject => "This is a test",
                                       body    => "I'm posting this test at " . localtime);

 if (my $url = $lj->post($entry)) {
     print "Success: $url\n";
 } else {
     print "Failure: " . $lj->errstr . "\n";
 }

=head1 DESCRIPTION

This is a quick hack.  It could be fleshed out a lot.

=head1 AUTHOR

Brad Fitzpatrick <brad@danga.com>

=head1 COPYRIGHT AND LICENSING

This code is (C) 2006 Six Apart, Ltd.  You have permission to use and
distribute it under the same terms as Perl itself.
