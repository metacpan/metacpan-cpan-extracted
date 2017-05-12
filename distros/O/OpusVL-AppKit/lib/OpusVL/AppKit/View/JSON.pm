package OpusVL::AppKit::View::JSON;
use base qw( Catalyst::View::JSON );


__PACKAGE__->config(
    expose_stash => 'json',
);

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::View::JSON

=head1 VERSION

version 2.29

=head1 DESCRIPTION

This is our JSON view.  It only exposes the json key from the stash.

1;

=head1 NAME

OpusVL::AppKit::View::JSON

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
