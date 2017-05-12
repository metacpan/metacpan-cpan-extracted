package MouseX::StrictConstructor;

use 5.006_002;
use Mouse ();
use Mouse::Exporter;

our $VERSION = '0.02';

Mouse::Exporter->setup_import_methods();

sub init_meta {
    shift;
    my $meta = Mouse->init_meta(@_);
    $meta->strict_constructor(1); # XXX: Mouse-extended feature
    return $meta;
}

1;
__END__

=head1 NAME

MouseX::StrictConstructor - Make your object constructors blow up on unknown attributes 

=head1 SYNOPSIS

  use Mouse;
  use MouseX::StrictConstructor;

=head1 DESCRIPTION

Simply loading this module makes your constructors "strict". If your
constructor is called with an attribute argument that your class
does not declare, then it dies. This is a great way to catch small typos.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<Mouse>

L<Moose>

L<MooseX::StrictConstructor>

=head1 AUTHOR

Fuji, Goro (gfx) E<lt>gfuji(at)cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010, Fuji, Goro (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
