###########################################
package OAuth::Cmdline::CustomFile;
###########################################
use strict;
use warnings;
use MIME::Base64;
use Moo;

extends 'OAuth::Cmdline';

has custom_file => ( is => "rw" );

our $VERSION = '0.07'; # VERSION
# ABSTRACT: Use a custom cache file with  OAuth::Cmdline

###########################################
sub site {
###########################################
    return "custom-file";
}

###########################################
sub cache_file_path {
###########################################
    my( $self ) = @_;

    return $self->custom_file;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OAuth::Cmdline::CustomFile - Use a custom cache file with  OAuth::Cmdline

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    my $oauth = OAuth::Cmdline::CustomFile->new( custom_file => "<path>" );
    $oauth->access_token();

=head1 DESCRIPTION

This class overrides the cache_file_path method of C<OAuth::Cmdline>
and adds the custom_file attribute.

=head1 AUTHOR

Mike Schilli <cpan@perlmeister.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Mike Schilli.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
