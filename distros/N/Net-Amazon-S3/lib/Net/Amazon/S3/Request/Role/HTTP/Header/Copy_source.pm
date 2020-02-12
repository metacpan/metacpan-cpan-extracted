package Net::Amazon::S3::Request::Role::HTTP::Header::Copy_source;
# ABSTRACT: x-amz-copy-source header role
$Net::Amazon::S3::Request::Role::HTTP::Header::Copy_source::VERSION = '0.89';
use Moose::Role;

with 'Net::Amazon::S3::Request::Role::HTTP::Header' => {
    name => '_copy_source',
    header => 'x-amz-copy-source',
    isa => 'Maybe[Str]',
    required => 0,
    default => sub {
        my ($self) = @_;
        defined $self->copy_source_bucket && defined $self->copy_source_key
            ? $self->copy_source_bucket.'/'.$self->copy_source_key
            : undef;
    },
};

has 'copy_source_bucket'    => ( is => 'ro', isa => 'Str',     required => 0 );
has 'copy_source_key'       => ( is => 'ro', isa => 'Str',     required => 0 );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::Role::HTTP::Header::Copy_source - x-amz-copy-source header role

=head1 VERSION

version 0.89

=head1 AUTHOR

Leo Lapworth <llap@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
