package Net::Airbrake::Request;

use strict;
use warnings;

use JSON qw(encode_json);
use Class::Tiny qw(errors context environment session params);

sub BUILDARGS {
    my $class = shift;
    my ($param) = @_;

    ## conceal secure parameters
    for my $member (qw(environment session params)) {
        for my $key (grep { /(?:cookie|password)/i } keys %{$param->{$member}}) {
            $param->{$member}{$key} =~ s/./*/g;
        }
    }

    $param;
}

sub to_json {
    my $self = shift;

    encode_json({
        notifier    => {
            name    => "Net-Airbrake/$Net::Airbrake::VERSION",
            version => "$Net::Airbrake::VERSION",
            url     => 'https://github.com/sixapart/Net-Airbrake',
        },
        errors      => [ map { $_->to_hash } @{$self->errors || []} ],
        environment => $self->environment || {},
        context     => $self->context     || {},
        session     => $self->session     || {},
        params      => $self->params      || {},
    });
}

1;
__END__

=pod

=head1 NAME

Net::Airbrake::Request - Request object

=head1 SYNOPSIS

  use Net::Airbrake::Request;
  my $req = Net::Airbrake::Request->new({
      errors  => $errors,
      context => $context,
  });

=cut
