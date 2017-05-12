package Net::Kubernetes::Resource::Secret;
# ABSTRACT: Object representatioon of a Kubernetes Secret
$Net::Kubernetes::Resource::Secret::VERSION = '1.03';
use Moose;

use File::Slurp qw(write_file);
use MIME::Base64 qw(decode_base64);

extends 'Net::Kubernetes::Resource';

has type => (
	is       => 'ro',
	isa      => 'Str',
	required => 1
);

has data => (
	is       => 'ro',
	isa      => 'HashRef',
	required => 1
);


sub render {
    my $self = shift;

    my(%args);
    if (ref($_[0])) {
        %args = %{ $_[0] };
    } else {
        %args = @_;
    }

    $args{force} //= 0;

    if (! -d $args{directory}) {
        Throwable::Error->throw(message => "Directory must exist: $args{directory}");
    }

    for my $file (keys %{$self->data}) {
        write_file("$args{directory}/$file",
            {
                err_mode   => 'croak',
                no_clobber => !$args{force},
				binmode => ':raw',
            },
            decode_base64 ${$self->data}{$file}
        );
    }
    # if we didn't write them all, we better have thrown an exception.
    return scalar keys %{$self->data};
}

return 42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Kubernetes::Resource::Secret - Object representatioon of a Kubernetes Secret

=head1 VERSION

version 1.03

=head1 METHODS

=head2 render(directory => "/path/to/write/secret/files", [ force => 0/] )

Render the contents of a Kubernetes secret into the specified directory.  Will
not overwrite files unless 'force' is specified.

Returns the number of files written.

=head1 AUTHOR

Dave Mueller <dave@perljedi.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Dave Mueller.

This is free software, licensed under:

  The MIT (X11) License

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Net::Kubernetes|Net::Kubernetes>

=back

=cut
