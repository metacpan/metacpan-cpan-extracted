
package in;

# ABSTRACT: no abstract.

=pod

=tmpl t1

Included

=tmpl -t2

Not included.

=tmpl

=cut

sub ignore_me {
    return 0;
}

=head1 MUST BE INCLUDED

With this text

=cut

1;
