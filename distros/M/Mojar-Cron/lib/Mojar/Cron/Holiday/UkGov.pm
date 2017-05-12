package Mojar::Cron::Holiday::UkGov;
use Mojar::Cron::Holiday -base;

our $VERSION = 0.021;

use Mojo::UserAgent;

has agent => sub { Mojo::UserAgent->new(max_redirects => 3) };
has division => 'england-and-wales';
has url => 'https://www.gov.uk/bank-holidays.json';

sub load {
  my ($self, %param) = @_;
  require IO::Socket::SSL;

  my $tx = $self->agent->get($self->url);
  if (my $err = $tx->error) {
    $self->error(sprintf "Failed to fetch holidays (%u)\n%s",
        $err->{advice} // '0', $err->{message} // 'coded error');
    return undef;
  }

  my $loaded = $tx->res->json(sprintf '/%s/events', $self->division);
  return 0 unless @$loaded;

  $self->holidays({}) if $param{reset};
  $self->holiday($_->{date} => 1) for @$loaded;

  return scalar @$loaded;
}

1;
__END__

=head1 NAME

Mojar::Cron::Holiday::UkGov - Feed from gov.uk

=head1 SYNOPSIS

  use Mojar::Cron::Holiday::UkGov;
  my $calendar = Mojar::Cron::Holiday::UkGov->new(division => 'Scotland');
  say 'Whoopee!' if $calendar->load and $calendar->holiday($today);
  say join "\n", sort keys %{$calendar->holidays};

=head1 COPYRIGHT AND LICENCE

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

Copyright (C) 2014--2016, Nic Sandfield.

=head1 SEE ALSO

L<Mojar::Cron::Holiday::Kayaposoft>.
