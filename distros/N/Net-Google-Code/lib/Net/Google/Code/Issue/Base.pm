package Net::Google::Code::Issue::Base;

use Any::Moose;
use LWP::UserAgent;

has 'project' => (
    isa => 'Str',
    is  => 'rw',
);

has 'token' => (
    isa     => 'Str',
    is      => 'rw',
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub feeds_issues_url {
    my $self = shift;
    return
        'http://code.google.com/feeds/issues/p/'
      . $self->project
      . '/issues';
}

sub ua {
    my $self = shift;
    my $skip_auth = shift;
    require Net::Google::Code;
    my $ua = LWP::UserAgent->new( agent => 'net-google-code-issue/'
          . $Net::Google::Code::VERSION );
    return $ua if $skip_auth;

    $ua->default_header( 'Content-Type' => 'application/atom+xml' );

    # get auth token
    if ( $self->email && $self->password && !$self->token ) {
        $self->get_token();
    }

    $ua->default_header( Authorization => 'GoogleLogin auth=' . $self->token )
      if $self->token;
    return $ua;
}

sub get_token {
    my $self     = shift;
    my $ua       = $self->ua(1);    # don't need auth
    my $response = $ua->post(
        'https://www.google.com/accounts/ClientLogin',
        {
            Email   => $self->email,
            Passwd  => $self->password,
            service => 'code',
        }
    );
    if ( $response->is_success && $response->content =~ /Auth=(\S+)/ ) {
        $self->token($1);
    }
    else {
        warn "failed to get auth token: "
          . $response->status_line . "\n"
          . $response->content;
        return;
    }
}

1;

__END__

=head1 NAME

Net::Google::Code::Issue::Base - Base

=head1 SYNOPSIS

    use Net::Google::Code::Issue::Base;

=head1 ATTRIBUTES

=over 4

=item auth

=back

=head1 INTERFACE

=over 4

=item feeds_issues_url

=item ua

returns an L<LWP::UserAgent> object, with agent and auth stuff prefilled.

=item get_token

try to get auth token and set $self->token if succeed.

=back

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2009 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

