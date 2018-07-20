
use strict;
use warnings;

package Net::Amazon::S3::Role::Bucket;
$Net::Amazon::S3::Role::Bucket::VERSION = '0.84';
use Moose::Role;
use Scalar::Util;

around BUILDARGS => sub {
    my ($orig, $class, %params) = @_;

    $params{bucket} = $params{bucket}->name
        if $params{bucket}
        and Scalar::Util::blessed( $params{bucket} )
        and $params{bucket}->isa( 'Net::Amazon::S3::Client::Bucket' )
        ;

    $params{bucket} = Net::Amazon::S3::Bucket->new(
        bucket => $params{bucket},
        account => $params{s3},
    ) if $params{bucket} and ! ref $params{bucket};

    $class->$orig( %params );
};

has bucket => (
    is => 'ro',
    isa => 'Net::Amazon::S3::Bucket',
    required => 1,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Role::Bucket

=head1 VERSION

version 0.84

=head1 AUTHOR

Leo Lapworth <llap@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
