package OpusVL::AppKit::View::Email;

use strict;
use base 'Catalyst::View::Email';

__PACKAGE__->config(
    stash_key => 'email'
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::View::Email

=head1 VERSION

version 2.29

=head1 DESCRIPTION

View for sending email from OpusVL::AppKit. 

=head1 NAME

OpusVL::AppKit::View::Email - Email View for OpusVL::AppKit

=head1 SEE ALSO
L<OpusVL::AppKit>

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
