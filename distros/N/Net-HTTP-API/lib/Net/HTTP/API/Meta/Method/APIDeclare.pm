package Net::HTTP::API::Meta::Method::APIDeclare;
BEGIN {
  $Net::HTTP::API::Meta::Method::APIDeclare::VERSION = '0.14';
}

# ABSTRACT: declare API

use Moose::Role;
use Net::HTTP::API::Error;

my @accepted_options = qw/
  api_base_url
  api_format
  api_format_mode
  api_username
  api_password
  authentication
  authentication_method
  /;

has api_options => (
    is      => 'ro',
    traits  => ['Hash'],
    isa     => 'HashRef[Str|CodeRef]',
    default => sub { {} },
    lazy    => 1,
    handles => {
        set_api_option => 'set',
        get_api_option => 'get',
    },
);

sub add_net_api_declare {
    my ($meta, $name, %options) = @_;

    if ($options{useragent}) {
        die Net::HTTP::API::Error->new(
            reason => "'useragent' must be a CODE ref")
          unless ref $options{useragent} eq 'CODE';
        $meta->set_api_option(useragent => delete $options{useragent});
    }

    # XXX for backward compatibility
    for my $attr (qw/base_url format format_mode username password/) {
        my $attr_name = "api_" . $attr;
        if (exists $options{$attr} && !exists $options{$attr_name}) {
            $options{$attr_name} = delete $options{$attr};
        }
    }

    for my $attr (@accepted_options) {
        $meta->set_api_option($attr => $options{$attr}) if defined $options{$attr};
    }
}

1;


__END__
=pod

=head1 NAME

Net::HTTP::API::Meta::Method::APIDeclare - declare API

=head1 VERSION

version 0.14

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

