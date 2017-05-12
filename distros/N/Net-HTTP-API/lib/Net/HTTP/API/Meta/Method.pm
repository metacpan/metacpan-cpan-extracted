package Net::HTTP::API::Meta::Method;
BEGIN {
  $Net::HTTP::API::Meta::Method::VERSION = '0.14';
}

# ABSTRACT: create api method

use Moose;
use Net::HTTP::API::Error;
use Moose::Util::TypeConstraints;

use MooseX::Types::Moose qw/Str Int ArrayRef/;

extends 'Moose::Meta::Method';

subtype UriPath
    => as 'Str'
    => where { $_ =~ m!^/! }
    => message {"path must start with /"};

enum Method => qw(HEAD GET POST PUT DELETE);

has path   => (is => 'ro', isa => 'UriPath', required => 1);
has method => (is => 'ro', isa => 'Method', required => 1);
has description => (is => 'ro', isa => 'Str',  predicate => 'has_description');
has strict      => (is => 'ro', isa => 'Bool', default   => 1,);
has authentication => (
    is => 'ro',
    isa => 'Bool',
    predicate => 'has_authentication',
    default => 0
);
has expected => (
    traits     => ['Array'],
    is         => 'ro',
    isa        => ArrayRef [Int],
    auto_deref => 1,
    required   => 0,
    predicate  => 'has_expected',
    handles    => {find_expected_code => 'grep',},
);
has params => (
    traits     => ['Array'],
    is         => 'ro',
    isa        => ArrayRef [Str],
    required   => 0,
    default    => sub { [] },
    auto_deref => 1,
    handles    => {find_request_parameter => 'first',}
);
has params_in_url => (
    traits     => ['Array'],
    is         => 'ro',
    isa        => ArrayRef [Str],
    required   => 0,
    default    => sub { [] },
    auto_deref => 0,
    handles => {find_request_url_parameters => 'first'}
);
has required => (
    traits     => ['Array'],
    is         => 'ro',
    isa        => ArrayRef [Str],
    default    => sub { [] },
    auto_deref => 1,
    required   => 0,
);
has documentation => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $doc;
        $doc .= "name:        " . $self->name . "\n";
        $doc .= "description: " . $self->description . "\n"
          if $self->has_description;
        $doc .= "method:      " . $self->method . "\n";
        $doc .= "path:        " . $self->path . "\n";
        $doc .= "arguments:   " . join(', ', $self->params) . "\n"
          if $self->params;
        $doc .= "required:    " . join(', ', $self->required) . "\n"
          if $self->required;
        $doc;
    }
);

before wrap => sub {
    my ($class, %args) = @_;

    if (!$args{params} && $args{required}) {
        die Net::HTTP::API::Error->new(
            reason => "You can't require a param that have not been declared");
    }

    if ( $args{required} ) {
        foreach my $required ( @{ $args{required} } ) {
            die Net::HTTP::API::Error->new( reason =>
                    "$required is required but is not declared in params" )
                if ( !grep { $_ eq $required } @{ $args{params} }, @{$args{params_in_url}} );
        }
    }
};

sub wrap {
    my ($class, %args) = @_;

    if (!defined $args{body}) {
        my $code = sub {
            my ($self, %method_args) = @_;

            my $method = $self->meta->find_net_api_method_by_name($args{name});

            $method->_validate_before_execute(\%method_args);
            my $path = $method->_build_path(\%method_args);
            my $local_url = $method->_build_uri($self, $path);

            my $result = $self->http_request(
                $method->method => $local_url,
                $method->params_in_url, \%method_args
            );

            my $code = $result->code;

            if ($method->has_expected
                && !$method->find_expected_code(sub {/$code/}))
            {
                die Net::HTTP::API::Error->new(
                    reason     => "unexpected code",
                    http_error => $result
                );
            }

            my $content = $self->get_content($result);;

            if ($result->is_success) {
                if (wantarray) {
                    return ($content, $result);
                }
                else {
                    return $content;
                }
            }

            die Net::HTTP::API::Error->new(
                http_error => $result,
                reason     => $result->message,
            );
        };
        $args{body} = $code;
    }

    $class->SUPER::wrap(%args);
}

sub _validate_before_execute {
    my ($self, $args) = @_;
    for my $method (qw/_check_params_before_run _check_required_before_run/) {
        $self->$method($args);
    }
}

sub _check_params_before_run {
    my ($self, $args) = @_;

    return if !$self->strict;

    # check if there is no undeclared param
    foreach my $arg (keys %$args) {
        if (   !$self->find_request_parameter(sub {/$arg/})
            && !$self->find_request_url_parameters(sub {/$arg/}))
        {
            die Net::HTTP::API::Error->new(
                reason => "'$arg' is not declared as a param");
        }
    }
}

sub _check_required_before_run {
    my ($self, $args) = @_;

    # check if all our params declared as required are present
    foreach my $required ($self->required) {
        if (!grep { $required eq $_ } keys %$args) {
            die Net::HTTP::API::Error->new(reason =>
                  "'$required' is declared as required, but is not present");
        }
    }
}

sub _build_path {
    my ($self, $args) = @_;
    my $path = $self->path;

    my $max_iter = keys %$args;
    my $i        = 0;
    while ($path =~ /(?:\$|:)(\w+)/g) {
        my $match = $1;
        $i++;
        if (my $value = delete $args->{$match}) {
            $path =~ s/(?:\$|:)$match/$value/;
        }
        if ($max_iter > $i) {
            $path =~ s/\/(?:(\$|\:).*)?$//;
        }
    }
    $path =~ s/\/(?:(\$|\:).*)?$//;
    return $path;
}

sub _build_uri {
    my ($method, $self, $path) = @_;

    my $local_url     = $self->api_base_url->clone;
    my $path_url_base = $local_url->path;
    $path_url_base =~ s/\/$// if $path_url_base =~ m!/$!;
    $path_url_base .= $path;

    if ($self->api_format && $self->api_format_mode eq 'append') {
        my $format = $self->api_format;
        $path_url_base .= "." . $format;
    }

    $local_url->path($path_url_base);
    return $local_url;
}

1;


__END__
=pod

=head1 NAME

Net::HTTP::API::Meta::Method - create api method

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

