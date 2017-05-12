package MooX::Role::Reconstruct;

use strict;
use warnings FATAL => 'all';

use 5.006;

our $VERSION = 'v0.1.2';

use Sub::Quote;
use Sub::Defer;
use Role::Tiny;

sub import {
    my $target = shift;
    my %args = @_ ? (@_) : ( method => 'reconstruct' );

    my $method = delete( $args{method} );

    die 'MooX::Role::Reconstruct can only be used on Moo classes.'
      unless $Moo::MAKERS{$target} && $Moo::MAKERS{$target}{is_class};

    my $con = Moo->_constructor_maker_for($target);

    defer_sub(
        "${target}::${method}" => sub {

            # don't alter the original specs if called before new
            my %spec;
            for ( keys( %{ $con->{attribute_specs} } ) ) {
                $spec{$_} = { %{ $con->{attribute_specs}{$_} } };
            }
            for ( grep exists( $spec{$_}{init_arg} ), keys(%spec) )
            {
                delete($spec{$_}{init_arg}) unless $spec{$_}{keep_init};
            }
            unquote_sub $con->generate_method(
                $target, $method, \%spec, { no_install => 1 }
            );
        }
    );

    return;
}

1;

__END__

=head1 NAME

MooX::Role::Reconstruct - Reconstruct Moo Objects

=head1 SYNOPSIS

  
 # in a module
 package MyModule;

 use Moo;
 with qw( MooX::Role::Reconstruct );
  
 has row_id => (
    is => 'ro',
    init_arg => undef,
 );
  
 has foo => (
    is => 'rw',
 );
  
 1;
  
 # and in a script

 my $row_ref = $sth->fetchrow_hashref();
  
 # create a new object bypassing any init_arg restrictions
 my $obj = MyModule->reconstruct( $row_ref );
  

=head1 DESCRIPTION

It is often desirable to create an object from a database row or a decoded
JSON object. However, it is quite likely that you might have declared some
attributes with C<< init_arg => undef >> so simply calling
C<< class->new( %hash ) >> will fail.

This module makes it possible by providing a constructor that will ignore
all C<init_arg> directives. This behavior can be disabled on a case-by-case
basis by specifying C<< keep_init => 1 >> in the C<has> structure for a given
attribute as shown below:

  
 has foo => (
    is => 'ro',
    default => 'bar',
    init_arg => 'baz',
    keep_init => 1,
 );
  

In this case, the noraml behavior of taking the initializer value from
C<baz> if it is present will be retained.

C<BUILDARGS> and C<BUILD> will be called as they would be if C<< class->new >>
had been used, as will any C<coerce> and/or C<isa> specifiers. (This presumes
that one has written sensible C<coerce> and C<isa> conditions.)

=head1 METHODS

=head2 reconstruct

The module installs a method named C<reconstruct> by default.

Note: Any naming conflicts will show up as a C<Subroutine redefined> error.

=head1 ERROR CONDITIONS

This Role requires that L<Moo> be loaded prior to use. The module will
C<die> otherwise.

=head1 SUPPORT

Please report any bugs or feature requests through the issue tracker at
L<https://github.com/boftx/MooX-Role-Reconstruct/issues>. You will be
notified automatically of any progress on your issue.

GitHub: L<https://github.com/boftx/MooX-Role-Reconstruct>

=head1 DEPENDENCIES

L<Sub::Quote>, L<Sub::Defer>, L<Role::Tiny>

=head1 SEE ALSO

This module is based on ideas in L<MooseX::UnsafeConstructable>.

=head1 AUTHOR

Jim Bacon E<lt>jim@nortx.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jim Bacon

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.16 or,
at your option, any later version of Perl 5 you may have available.

=cut
