package Shared::Examples::Net::Amazon::S3::API;
# ABSTRACT: used for testing and as example
$Shared::Examples::Net::Amazon::S3::API::VERSION = '0.89';
use strict;
use warnings;

use parent qw[ Exporter::Tiny ];

use Hash::Util;
use Test::Deep;
use Test::More;

use Net::Amazon::S3;
use Shared::Examples::Net::Amazon::S3;

our @EXPORT_OK = (
    qw[ expect_signed_uri ],
    qw[ expect_api_list_all_my_buckets ],
    qw[ expect_api_bucket_acl_get ],
    qw[ expect_api_bucket_acl_set ],
    qw[ expect_api_bucket_create ],
    qw[ expect_api_bucket_delete ],
    qw[ expect_api_bucket_objects_list ],
    qw[ expect_api_bucket_objects_delete ],
    qw[ expect_api_object_acl_get ],
    qw[ expect_api_object_acl_set ],
    qw[ expect_api_object_create ],
    qw[ expect_api_object_delete ],
    qw[ expect_api_object_fetch ],
    qw[ expect_api_object_head ],
);

sub _exporter_expand_sub {
    my ($self, $name, $args, $globals) = @_;

    my $s3_operation = $name;
    $s3_operation =~ s/_api_/_operation_/;

    return +( $name => eval <<"GEN_SUB" );
        sub {
            push \@_, -shared_examples => __PACKAGE__;
            goto \\& Shared::Examples::Net::Amazon::S3::$s3_operation;
        }
GEN_SUB
}

sub _default_with_api {
    my ($self, $params) = @_;

    $params->{with_s3} ||= Shared::Examples::Net::Amazon::S3::s3_api_with_signature_2 ();
}

sub _mock_http_response {
    my (undef, %params) = @_;

    $params{with_response_code} ||= HTTP::Status::HTTP_OK;

    my %headers = (
        content_type => 'application/xml',
        %{ $params{with_response_headers} || {} },
    );

    my $guard = Sub::Override->new;
    $guard->replace (
        'Net::Amazon::S3::_do_http' => sub {
            ${ $params{into} } = $_[1];
            HTTP::Response->new (
                $params{with_response_code},
                HTTP::Status::status_message ($params{with_response_code}),
                [ %headers ],
                $params{with_response_data},
            ),
        }
    );

    $guard;
}

sub expect_signed_uri {
    my ($title, %params) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    Hash::Util::lock_keys %params,
        qw[ with_s3 ],
        qw[ with_bucket ],
        qw[ with_region ],
        qw[ with_key ],
        qw[ with_expire_at ],
        qw[ expect_uri ],
        ;

    my $got = Net::Amazon::S3::Bucket
        ->new ({
            account => $params{with_s3},
            bucket  => $params{with_bucket},
            region  => $params{with_region},
        })
        ->query_string_authentication_uri (
            $params{with_key},
            $params{with_expire_at}
        );

    cmp_deeply $got, $params{expect_uri}, $title;
}

sub operation_list_all_my_buckets {
    my ($self, %params) = @_;

    $self->buckets;
}

sub operation_bucket_acl_get {
    my ($self, %params) = @_;

    $self
        ->bucket ($params{with_bucket})
        ->get_acl
        ;
}

sub operation_bucket_acl_set {
    my ($self, %params) = @_;

    $self
        ->bucket ($params{with_bucket})
        ->set_acl ({
            (acl_short => $params{with_acl_short}) x!! exists $params{with_acl_short},
            (acl_xml => $params{with_acl_xml}) x!! exists $params{with_acl_xml},
        })
        ;
}

sub operation_bucket_create {
    my ($self, %params) = @_;

    $self
        ->add_bucket ({
            bucket => $params{with_bucket},
            (acl_short => $params{with_acl}) x!! exists $params{with_acl},
            (location_constraint => $params{with_region}) x!! exists $params{with_region},
            (region => $params{with_region}) x!! exists $params{with_region},
        })
        ;
}

sub operation_bucket_delete {
    my ($self, %params) = @_;

    $self
        ->delete_bucket ({
            bucket => $params{with_bucket},
        })
        ;
}

sub operation_bucket_objects_list {
    my ($self, %params) = @_;

    $self
        ->list_bucket ({
            bucket      => $params{with_bucket},
            delimiter   => $params{with_delimiter},
            max_keys    => $params{with_max_keys},
            marker      => $params{with_marker},
            prefix      => $params{with_prefix},
        })
        ;
}

sub operation_bucket_objects_delete {
    my ($self, %params) = @_;

    $self
        ->bucket ($params{with_bucket})
        ->delete_multi_object (@{ $params{with_keys} })
        ;
}

sub operation_object_acl_get {
    my ($self, %params) = @_;

    $self
        ->bucket ($params{with_bucket})
        ->get_acl ($params{with_key})
        ;
}

sub operation_object_acl_set {
    my ($self, %params) = @_;

    $self
        ->bucket ($params{with_bucket})
        ->set_acl ({
            key => $params{with_key},
            (acl_short => $params{with_acl_short}) x!! exists $params{with_acl_short},
            (acl_xml => $params{with_acl_xml}) x!! exists $params{with_acl_xml},
        })
        ;
}

sub operation_object_create {
    my ($self, %params) = @_;

    my $headers = { %{ $params{with_headers} || {} } };

    $headers->{$_} = $params{"with_$_"}
        for grep exists $params{"with_$_"},
        qw[ cache_control  ],
        qw[ content_disposition  ],
        qw[ content_encoding  ],
        qw[ content_type  ],
        qw[ encryption ],
        qw[ expires ],
        ;

    $headers->{x_amz_storage_class} = $params{with_storage_class}
        if $params{with_storage_class};

    $headers->{"x_amz_meta_\L$_"} = $params{with_user_metadata}{$_}
        for keys %{ $params{with_user_metadata} || {} };

    $self
        ->bucket ($params{with_bucket})
        ->add_key (
            $params{with_key},
            $params{with_value},
            $headers,
        )
        ;
}

sub operation_object_delete {
    my ($self, %params) = @_;

    $self
        ->bucket ($params{with_bucket})
        ->delete_key ($params{with_key})
        ;
}

sub operation_object_fetch {
    my ($self, %params) = @_;

    $self
        ->bucket ($params{with_bucket})
        ->get_key ($params{with_key}, 'GET')
        ;
}

sub operation_object_head {
    my ($self, %params) = @_;

    $self
        ->bucket ($params{with_bucket})
        ->head_key ($params{with_key})
        ;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shared::Examples::Net::Amazon::S3::API - used for testing and as example

=head1 VERSION

version 0.89

=head1 AUTHOR

Leo Lapworth <llap@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
