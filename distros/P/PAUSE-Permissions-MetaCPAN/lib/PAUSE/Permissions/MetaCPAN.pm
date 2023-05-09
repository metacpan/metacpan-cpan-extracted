package PAUSE::Permissions::MetaCPAN 0.100;
use v5.16;
use warnings;

use Carp ();
use HTTP::Tiny 0.055;
use IO::Socket::SSL 1.42;
use JSON::PP ();

sub new {
    my ($class, %args) = @_;
    my $http = $args{http} || do {
        my $agent = sprintf "%s/%s", $class =~ s/::/-/gr, $class->VERSION;
        HTTP::Tiny->new(verify_SSL => 1, agent => $agent);
    };
    my $url = $args{url} || "https://fastapi.metacpan.org/v1/permission/_search";
    bless { http => $http, url => $url }, $class;
}

sub get {
    my ($self, %args) = @_;

    Carp::croak "either author or modules is required" if !$args{author} && !$args{modules};

    if (my $author = $args{author}) {
        my $hit = $self->_query(%args);
        my %hit = (owner => [], co_maintainer => []);
        for my $module (@$hit) {
            if ($module->{owner} eq $author) {
                push @{$hit{owner}}, $module;
            } else {
                push @{$hit{co_maintainer}}, $module;
            }
        }
        return \%hit;
    }

    my @hit;
    my @module = @{$args{modules}}; # must copy
    # elasticsearch may return "too_many_clauses: maxClauseCount is set to 1024"
    while (my @m = splice @module, 0, 1024) {
        my $hit = $self->_query(modules => \@m);
        push @hit, @$hit;
    }
    my %hit;
    for my $module (@{$args{modules}}) {
        my ($found) = grep { $_->{module_name} eq $module} @hit;
        $hit{$module} = $found;
    }
    return \%hit;
}

sub _query {
    my ($self, %args) = @_;

    my %bool;
    if (my $author = $args{author}) {
        $bool{should} = [
            { term => { owner => $author } },
            { term => { co_maintainers => $author } },
        ];
        $bool{minimum_should_match} = 1;
    } elsif (my $modules = $args{modules}) {
        $bool{should} = [
            map +{ term => { module_name => $_ } }, @$modules
        ];
        $bool{minimum_should_match} = 1;
    }

    my $from = 0;
    my $times = 0;
    my @hit;
    while (1) {
        $times++;
        Carp::croak "too many request for $self->{url}" if $times > 6;
        my $payload = {
            query => { bool => \%bool },
            sort => [ { module_name => 'asc' } ],
            size => 2000,
            from => $from,
        };
        my $body = JSON::PP::encode_json $payload;
        my $res = $self->{http}->post($self->{url}, {
            'content-type' => 'application/json',
            'content-length' => length $body,
            content => $body,
        });
        if ($res->{status} == 404) {
            last;
        } elsif (!$res->{success}) {
            Carp::croak "$res->{status} $res->{reason}, $self->{url}\n$res->{content}";
        }
        my $json = JSON::PP::decode_json $res->{content};
        my $total = $json->{hits}{total};
        push @hit, map $_->{_source}, @{$json->{hits}{hits}};
        last if @hit >= $total;
        $from = @hit;
    }
    \@hit;
}

1;
__END__

=encoding utf-8

=head1 NAME

PAUSE::Permissions::MetaCPAN - get module permissions from MetaCPAN API

=head1 SYNOPSIS

  use PAUSE::Permissions::MetaCPAN;

  my $api = PAUSE::Permissions::MetaCPAN->new;

  my $perm = $api->get(author => 'SKAJI');
  # {
  #   co_maintainer => [
  #     {
  #       co_maintainers => ["MIYAGAWA", "SKAJI", "SLANNING", "SYOHEX"],
  #       module_name => "Minilla",
  #       owner => "TOKUHIROM",
  #     },
  #     ...
  #   ],
  #   owner => [
  #     {
  #       co_maintainers => [],
  #       module_name => "Acme::RandomEmoji",
  #       owner => "SKAJI",
  #     },
  #     ...
  #   ],
  # }

  my $perm = $api->get(modules => ['LWP', 'NotFound', 'Plack']);
  # {
  #   LWP => {
  #     co_maintainers => ["ETHER", "GAAS", "MSCHILLI", "MSTROUT", "OALDERS"],
  #     module_name => "LWP",
  #     owner => "LWWWP",
  #   },
  #   NotFound => undef,
  #   Plack => {
  #     co_maintainers => [],
  #     module_name => "Plack",
  #     owner => "MIYAGAWA",
  #   },
  # }

=head1 DESCRIPTION

PAUSE::Permissions::MetaCPAN gets module permissions from MetaCPAN API.

=head1 METHOD

=head2 new

  my $api = PAUSE::Permissions::MetaCPAN->new;

Constructor. It optionally takes the following argument:

=over 4

=item http

HTTP::Tiny object. Default is

  HTTP::Tiny->new(verify_SSL => 1, agent => 'PAUSE-Permissions-MetaCPAN/VERSION')

=item url

MetaCPAN API url. Default is L<https://fastapi.metacpan.org/v1/permission/_search>.

=back

=head2 get

  my $perm = $api->get(author => 'AUTHOR');
  my $perm = $api->get(modules => ['Module1', 'Module2', ...]);

Get module permissions from MetaCPAN API. It must be called with either
C<author> or C<modules> argument.
It returns a hash reference that contains module permissions.

=head1 SEE ALSO

=over 4

=item L<PAUSE::Permissions>

=item L<https://fastapi.metacpan.org/>

=back

=head1 AUTHOR

Shoichi Kaji <skaji@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2018 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
