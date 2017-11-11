
BEGIN {
    require Jojo::Base;
    *Mojo::Bass:: = *Jojo::Base::;
}

package Mojo::Bass;
$Mojo::Bass::VERSION = '0.4.0';
# ABSTRACT: DEPRECATED! Mojo::Base + lexical "has"

1;

#pod =encoding utf8
#pod
#pod =head1 DESCRIPTION
#pod
#pod DEPRECATED! Use L<Jojo::Base> instead.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Jojo::Base>.
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojo::Bass - DEPRECATED! Mojo::Base + lexical "has"

=head1 VERSION

version 0.4.0

=head1 DESCRIPTION

DEPRECATED! Use L<Jojo::Base> instead.

=head1 SEE ALSO

L<Jojo::Base>.

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Adriano Ferreira.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
