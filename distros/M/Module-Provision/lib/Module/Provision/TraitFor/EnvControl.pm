package Module::Provision::TraitFor::EnvControl;

use namespace::autoclean;

use Class::Usul::Constants qw( FALSE NUL OK TRUE );
use Class::Usul::Functions qw( emit env_prefix );
use Moo::Role;

requires qw( next_argv project );

# Public methods
sub trace : method {
   my $self   = shift;
   my $token  = $self->next_argv // NUL;
   my $prefix = env_prefix $self->project;
   my @keys   = ( 'DBIC_TRACE', "${prefix}_DEBUG", "${prefix}_TRACE", );

   my ($key, $value);

   if ($token eq 'show') {
      emit "PATH = ".$ENV{PATH};

      for my $k (grep { m{ PERL }mx } sort keys %ENV) {
         emit "${k} = ".$ENV{ $k };
      }

      for my $k (@keys) { emit "${k} = ".($ENV{ $k } // NUL) }
   }
   elsif ($token eq 'dbic') {
      $key = 'DBIC_TRACE'; $value = $ENV{ $key } ? FALSE : TRUE;
   }
   elsif ($token) {
      $key = "${prefix}_TRACE";
      $value = $token eq ($ENV{ $key } // NUL) ? '""' : $token;
   }
   else { $key = "${prefix}_DEBUG"; $value = $ENV{ $key } ? FALSE : TRUE }

   $key and emit "${key}=${value}; export ${key}";

   return OK;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Module::Provision::TraitFor::EnvControl - Environment Control

=head1 Synopsis

   use Module::Provision::TraitFor::EnvControl;
   # Brief but working code examples

=head1 Description

Toggles environment variables used to control application trace output

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=back

=head1 Subroutines/Methods

=head2 C<trace> - Toggles environment variables

   $exit_code = $self->trace;

Toggles environment variables

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Usul>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Provision.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2017 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
