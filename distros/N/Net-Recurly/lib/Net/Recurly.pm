package Net::Recurly;
use Moose;
use LWP::UserAgent;
use HTTP::Request;
use XML::Simple;

our $VERSION = '0.001';

has 'subdomain' => (is => 'ro', isa => 'Str', required => 1);
has 'username'  => (is => 'ro', isa => 'Str', required => 1);
has 'password'  => (is => 'ro', isa => 'Str', required => 1);

has 'ua' => (is => 'ro', isa => 'Object', lazy_build => 1);
has 'api_host' => (is => 'ro', isa => 'Str', lazy_build => 1);

sub get_account {
    my $self = shift;
    my $acct_code = shift;
    return $self->get("/accounts/$acct_code");
}

sub get_billing_info {
    my $self = shift;
    my $acct_code = shift;
    return $self->get("/accounts/$acct_code/billing_info");
}

sub get_charges {
    my $self = shift;
    my $acct_code = shift;
    return $self->get("/accounts/$acct_code/charges");
}

sub get_credits {
    my $self = shift;
    my $acct_code = shift;
    return $self->get("/accounts/$acct_code/credits");
}

sub get_invoices {
    my $self = shift;
    my $acct_code = shift;
    return $self->get("/accounts/$acct_code/invoices");
}

sub get_subscription {
    my $self = shift;
    my $acct_code = shift;
    return $self->get("/accounts/$acct_code/subscription");
}

sub get_subscription_plan {
    my $self = shift;
    my $plan_code = shift;
    return $self->get("/company/plans/$plan_code");
}

sub get_subscription_plans {
    my $self = shift;
    return $self->get("/company/plans");
}

sub get_transactions {
    my $self = shift;
    my %opts = @_;
    my $extra = '?';
    if (my $p = $opts{page}) {
        $extra .= "page=$p;";
    }
    return $self->get("/transactions$extra");
}

sub get_account_transactions {
    my $self = shift;
    my $acct_code = shift;
    my %opts = @_;
    my $extra = '?';
    if (my $p = $opts{page}) {
        $extra .= "page=$p;";
    }
    return $self->get("/accounts/$acct_code/transactions$extra");
}

sub get {
    my $self = shift;
    my $path = shift;
    
    my $url = 'https://' . $self->api_host . $path;
    my $req = HTTP::Request->new(GET => $url);
    $req->authorization_basic($self->username, $self->password);
    $req->header('Accept' => 'application/xml');
    my $resp = $self->ua->request($req);
    my $code = $resp->code;
    if ($code == 200) {
        return XMLin($resp->content);
    }
    return if $code == 404;
    die "GET $url failed ($code - " . $resp->content . ")\n";
}

sub _build_ua {
    my $self = shift;
    my $ua = LWP::UserAgent->new(agent => "Net::Recurly - $VERSION");
    $ua->credentials(
        $self->api_host . ':443',
        'default',
        $self->username => $self->password,
    );
    $ua->protocols_allowed(['https']);
    return $ua;
}

sub _build_api_host {
    my $self = shift;
    return $self->subdomain . '.recurly.com';
}

1;

__END__

=head1 NAME

Net::Recurly - Recurly client library

=head1 VERSION

version 0.001

=head2 SYNOPSIS

  use Net::Recurly;

  my $R = Net::Recurly->new(
      username => 'api-test@your-domain.com',
      password => 'your-password',
      subdomain => 'your-domain',
  );
  my $subscription = $r->get_subscription('your-account-code');

=head1 DESCRIPTION

Net::Recurly is a thin layer around the Recurly.com API.  It currently only
supports GET requests, although supporting the API more fully is planned.

The XML responses are returned as a hash, using XML::Simple.

=head1 CONSTRUCTOR OPTIONS

The constructor takes 3 mandatory arguments:

=over 4

=item username

This is the username you use to access the Recurly API.

=item password

This is the password you use to access the Recurly API.

=item subdomain

This is the domain you have configured for Recurly.

Note: If you are using the Recurly test account, your domain should 
end in '-test'.

=back

=head1 SEE ALSO

The Recurly API documentation: http://docs.recurly.com/

=head1 BUGS AND DEFECTS

This module is a simple first draft, it is not complete, it does not have tests.

YMMV, IANAL, Patches Welcome.

=head1 COPYRIGHT

Copyright 2011 Luke Closs.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.