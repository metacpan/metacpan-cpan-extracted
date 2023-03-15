package MooseX::Role::Validatable::Error;

use Moose;

our $VERSION = '0.12';    ## VERSION

has message => (
    is       => 'ro',
    required => 1,
);

has message_to_client => (
    is       => 'ro',
    required => 1,
);

has details => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 0,
);

has set_by => (
    is       => 'ro',
    required => 1,
);

has severity => (
    is      => 'ro',
    isa     => 'Int',
    default => sub { 1 },
);

has transient => (
    is      => 'ro',
    isa     => 'Bool',
    default => sub { 0 },
);

has alert => (
    is      => 'ro',
    isa     => 'Bool',
    default => sub { 0 },
);

has info_link => (is => 'ro');
has info_text => (is => 'ro');

has code => (
    is      => 'ro',
    isa     => 'Str',
    default => sub {
        return 'General';
    },
);

sub as_html {
    my $self = shift;

    my $html = "<p>" . $self->message_to_client;
    if (my $info_link = $self->info_link) {
        my $info_text = $self->info_text || 'More Info...';
        $html .= qq~<a href="$info_link" class="info_link">$info_text</a>\n~;
    }
    $html .= "</p>\n";

    return $html;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=encoding utf-8

=head1 NAME

MooseX::Role::Validatable::Error - Base Error class for MooseX::Role::Validatable

=head1 SYNOPSIS

  use MooseX::Role::Validatable;

    my $error = MooseX::Role::Validatable::Error->new({
        message           => 'Internal debug message.',            # Required
        message_to_client => 'Client-facing message',              # Required
        details           => { field => 'duration' },            # Optional, Must be a HashRef
        set_by            => 'Source of the error',                # Required; MAY default to caller(1)
        severity          => 5,                                    # For ordering, bigger is worse. Defaults to 1.
        transient         => 1,                                    # Boolean, defaults to false
        alert             => 1,                                    # Boolean, defaults to false
        info_link         => 'https://example.com/',               # Client-facing URI for additional info on this error.
    });

=head1 DESCRIPTION

Represents an error in validation

=head1 ATTRIBUTES

=head2 message

A message which might help us figure out what is wrong.

=head2 details

An arbitrary optional HashRef to pass the error details.

=head2 message_to_client

A client-friendly string describing the error.

=head2 set_by

The source of the error.

=head2 severity

How bad is it that this happened?

=head2 transient

Is this something likely to resolve itself with a little time?

=head2 alert

Should someone be alerted when this condition triggers?

=head2 info_link

A URI for further explanation of the error.

=head2 info_text

Description of the info_link

=head2 as_html

=head2 code

Error code in string.

=head1 AUTHOR

Binary.com E<lt>fayland@binary.comE<gt>

=head1 COPYRIGHT

Copyright 2014- Binary.com

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
