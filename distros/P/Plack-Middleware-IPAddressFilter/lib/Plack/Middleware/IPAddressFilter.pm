package Plack::Middleware::IPAddressFilter;
use parent qw(Plack::Middleware);

use strict;
use warnings;
our $VERSION = '0.02';

use Net::IP::AddrRanges;

use Plack::Util::Accessor qw( rules );

sub prepare_app {
    my $self = shift;

    my $rules = $self->rules;
    if(ref $rules ne 'ARRAY') {
        die 'rules should be an array reference';
    }
    my $ranges = Net::IP::AddrRanges->new();
    for(@$rules) {
        s/^([\+\-])? *//;
        if(not defined $1 or $1 eq '+') {
            $ranges->add($_);
        }
        else {
            $ranges->subtract($_);
        }
    }
    $self->rules($ranges);
}

sub call {
    my($self, $env) = @_;

    my $remote_address = $env->{REMOTE_ADDR}
        or return $self->forbidden;

    if($self->rules->find($remote_address)) {
        return $self->app->($env);
    }
    return $self->forbidden;
}

sub forbidden {
    my $self = shift;
    my $body = "You don't have permission to access this resouce.";
    return [
        403,
        [ 'Content-Type' => 'text/plain',
          'Content-Length' => length $body ],
        [ $body ],
    ];
}

1;
__END__

=head1 NAME

Plack::Middleware::IPAddressFilter - Simple IP address access control middleware

=head1 SYNOPSIS

  use Plack::Builder;
  my $app = sub { ... };
  
  builder {
    enable "IPAddressFilter", rules [
                                       # deny from all for default.
      '+ 127.0.0.1',                   # allow from localhost.
      '+ 192.168.0.0/24',              # allow from LAN
      '- 192.168.0.5-192.168.0.10',    #   except from some hosts.
      '+ 192.0.34.72/255.255.255.240', # allow from subnet.
    ];
    $app;
  }


=head1 DESCRIPTION

Plack::Middleware::IPAddressFilter is a IP address based access control handler
for Plack.

=head1 CONFIGURATION

=over 4

=item rules

IP address ranges to allow/deny. '-' prepended ranges are denied,'+' prepended
or prepend less are allowd.

=back

=head1 AUTHOR

Rintaro Ishizaki E<lt>rintaro@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
