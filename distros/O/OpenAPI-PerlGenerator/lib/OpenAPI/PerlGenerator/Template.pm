package OpenAPI::PerlGenerator::Template 0.01;
use 5.020;
use experimental 'signatures';

our $info;

# Reflection package for template methods

sub map_type {
    $info->map_type( @_ );
}

sub openapi_submodules {
    $info->openapi_submodules( @_ );
}

sub openapi_response_content_types {
    $info->openapi_response_content_types( @_ );
}

sub openapi_http_code_match {
    $info->openapi_http_code_match( @_ );
}

sub render( $name, $args ) {
    $info->render( $name, $args );
}
*include = *include = \&render;

our %locations;
sub elsif_chain($id) {
    # Ignore all Mojo:: stuff!
    my $level = 0;
    if( !$locations{ $id }++) {
        return "if"
    #} elsif( $final ) {
    #    return " else "
    } else {
        return "} elsif"
    }
}

1;
__END__

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/OpenAPI-PerlGenerator>.

=head1 SUPPORT

The public support forum of this module is L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the Github bug queue at
L<https://github.com/Corion/OpenAPI-PerlGenerator/issues>

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2024- by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the Artistic License 2.0.

=cut
