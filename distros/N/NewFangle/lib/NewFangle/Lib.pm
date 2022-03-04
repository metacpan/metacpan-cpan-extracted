package NewFangle::Lib 0.08 {

  use strict;
  use warnings;
  use 5.014;
  use FFI::CheckLib 0.28 qw( find_lib );

# ABSTRACT: Private class for NewFangle.pm


  sub lib {
    find_lib lib => 'newrelic', alien => 'Alien::libnewrelic';
  }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

NewFangle::Lib - Private class for NewFangle.pm

=head1 VERSION

version 0.08

=head1 SYNOPSIS

 % perldoc NewFangle

=head1 DESCRIPTION

This is part of the internal workings for L<NewFangle>.

=head1 SEE ALSO

=over 4

=item L<NewFangle>

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Owen Allsopp (ALLSOPP)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
