package SeeAlso::Format::redirect;
#ABSTRACT: HTTP redirect as response format
$SeeAlso::Format::redirect::VERSION = '0.14';
use base 'SeeAlso::Format';

sub format { 'text/html' }

sub psgi {
    my ($self, $result) = @_;
    my ($url) = grep { $_ } @{$result->[3]};

    if ($url) {
        return [302, [
            Location => $url, URI => "<$url>",
            'Content-Type' => $self->format
        ], [ "<html><head><meta http-equiv='refresh' content='0; URL=$url'></head></html>" ]
        ]
    } else {
        return [404,['Content-Type' => $self->format],['<html><body>not found</body></html>']];
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SeeAlso::Format::redirect - HTTP redirect as response format

=head1 VERSION

version 0.14

=head1 AUTHOR

Jakob Voß

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
