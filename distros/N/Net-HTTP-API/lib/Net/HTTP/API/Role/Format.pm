package Net::HTTP::API::Role::Format;
BEGIN {
  $Net::HTTP::API::Role::Format::VERSION = '0.14';
}

# ABSTRACT: Set appropriate format to request header

use Moose::Role;
use Moose::Util::TypeConstraints;

sub content_type {
    {   json => {value => 'application/json', module => 'JSON',},
        yaml => {value => 'text/x-yaml',      module => 'YAML'},
        xml  => {value => 'text/xml',         module => 'XML::Simple'},
    };
}

subtype Format => as 'Str' => where {
    my $format = shift;
    grep {/^$format$/} keys %{content_type()};
};

enum 'FormatMode' => qw(content-type append);

has api_format => (
    is      => 'rw',
    isa     => 'Format',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->meta->get_api_option('api_format');
    }
);

has api_format_mode => (
    is      => 'rw',
    isa     => 'FormatMode',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $mode = $self->meta->get_api_option('api_format_mode') || 'append';
        $mode;
    }
);

1;


__END__
=pod

=head1 NAME

Net::HTTP::API::Role::Format - Set appropriate format to request header

=head1 VERSION

version 0.14

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item B<content_type>

=back

=head2 ATTRIBUTES

=over 4

=item B<api_format>

=item B<api_format_mode>

=back

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

