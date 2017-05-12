package SmokeRunner::Multi::Validate;
our $AUTHORITY = 'cpan:YANICK';
#ABSTRACT: Wrapper around Params::Validate for SmokeRunner::Multi
$SmokeRunner::Multi::Validate::VERSION = '0.21';
use strict;
use warnings;

use base 'Exporter';

use Params::Validate qw(:types);
use Scalar::Util qw( blessed );


my %Types;
BEGIN
{
    %Types =
        (
        DIR_TYPE => { type      => SCALAR,
                      callbacks => { 'is a dir' => sub { -d $_[0] } },
                    },

        TEST_SET_TYPE => { type => OBJECT,
                           isa  => 'SmokeRunner::Multi::TestSet',
                         },

        RUNNER_TYPE => { type => OBJECT,
                         isa  => 'SmokeRunner::Multi::Runner',
                       },
    );

    for my $t ( grep {/^[A-Z]+$/} @Params::Validate::EXPORT_OK )
    {
        my $name = $t . '_TYPE';
        $Types{$name} = { type => eval $t };
    }

    for my $t ( keys %Types )
    {
        my %t   = %{ $Types{$t} };

        my $sub = sub { die "Invalid additional args for $t: [@_]" if @_ % 2;
                        return { %t, @_ };
                    };

        no strict 'refs';
        *{$t} = $sub;
    }
}

our %EXPORT_TAGS = ( types => [ keys %Types ] );
our @EXPORT_OK = keys %Types;

my %MyExports = map { $_ => 1 }
    @EXPORT_OK,
    map { ":$_" } keys %EXPORT_TAGS;

sub import
{
    my $class = shift;

    my $caller = caller;

    my @pv_export = grep { !$MyExports{$_} } @_;

    {
        eval <<"EOF";
package $caller;

use Params::Validate qw(@pv_export);
EOF

        die $@ if $@;
    }

    $class->export_to_level( 1, undef, grep { $MyExports{$_} } @_ );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SmokeRunner::Multi::Validate - Wrapper around Params::Validate for SmokeRunner::Multi

=head1 VERSION

version 0.21

=head1 SYNOPSIS

  use SmokeRunner::Multi::Validate qw( validate DIR_TYPE TEST_SET_TYPE );

  my $spec = {
      dir => DIR_TYPE,
      set => TEST_SET_TYPE( optional => 1 ),
  };
  sub foo {
      my %p = validate( @_, $spec );

      ...
  }

=head1 DESCRIPTION

This module provides a wrapper around C<Params::Validate>. It
basically consists of type-generating subroutines which can be used to
easily create a validation spec for C<Params::Validate::validate()>.

=head1 EXPORTS

This module optionally exports all of the exported constants and
subroutines provided by C<Params::Validate>. In addition, it offers a
number of higher-level type-generating subroutines. Most of these are
wrappers around the C<Params::Validate> types.

=head2 SCALAR_TYPE, ARRAYREF_TYPE, HASHREF_TYPE, BOOLEAN_TYPE, UNDEF_TYPE, CODEREF_TYPE, GLOBREF_TYPE, GLOB_TYPE, HANDLE_TYPE, OBJECT_TYPE, SCALARREF_TYPE

These are all wrappers around the standard type parameters provided by
C<Params::Validate>.

=head2 DIR_TYPE

This is a scalar which must be a valid directory path.

=head2 TEST_SET_TYPE

This is an object of the C<SmokeRunner::Multi::TestSet> class.

=head2 RUNNER_TYPE

This is an object of the C<SmokeRunner::Multi::Runner> class.

=head2 Type Generator Usage

When you want to use one of the types exported by this module, you use
it as the entire definition for a named or position parameter. If you
want to further qualify the type with a default, pass this as a
parameter to the type generator subroutine:

  my $spec = {
      size => SCALAR_TYPE( default => 5 ),
  };

=head1 SEE ALSO

See the other classes in this distribution for more information:
L<SmokeRunner::Multi::TestSet>, L<SmokeRunner::Multi::Runner>,
L<SmokeRunner::Multi::Reporter>, and L<SmokeRunner::Multi::Config>.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-smokerunner-multi@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 LiveText, Inc., All Rights Reserved.

This program is free software; you can redistribute it and /or modify
it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=head1 AUTHORS

=over 4

=item *

Dave Rolsky <autarch@urth.org>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by LiveText, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
