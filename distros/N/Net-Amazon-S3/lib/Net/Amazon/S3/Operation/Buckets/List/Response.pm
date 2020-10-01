package Net::Amazon::S3::Operation::Buckets::List::Response;
# ABSTRACT: An internal class to process list all buckets response
$Net::Amazon::S3::Operation::Buckets::List::Response::VERSION = '0.94';
use Moose;

extends 'Net::Amazon::S3::Response';

sub owner_id {
    $_[0]->_data->{owner_id};
}

sub owner_displayname {
    $_[0]->_data->{owner_displayname};
}

sub buckets {
    @{ $_[0]->_data->{buckets} };
}

sub _parse_data {
    my ($self) = @_;

    my $xpc = $self->xpath_context;

    my $data = {
        owner_id          => $xpc->findvalue ("/s3:ListAllMyBucketsResult/s3:Owner/s3:ID"),
        owner_displayname => $xpc->findvalue ("/s3:ListAllMyBucketsResult/s3:Owner/s3:DisplayName"),
        buckets           => [],
    };

    foreach my $node ($xpc->findnodes ("/s3:ListAllMyBucketsResult/s3:Buckets/s3:Bucket")) {
        push @{ $data->{buckets} }, {
            name          => $xpc->findvalue ("./s3:Name", $node),
            creation_date => $xpc->findvalue ("./s3:CreationDate", $node),
        };
    }

    return $data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Operation::Buckets::List::Response - An internal class to process list all buckets response

=head1 VERSION

version 0.94

=head1 DESCRIPTION

Implements S3 operation L<< ListBuckets|https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBuckets.html >>

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
