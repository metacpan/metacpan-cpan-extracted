package Scalar::Does::MooseTypes;

use strict;
use warnings;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.203';

use base "Exporter::Tiny";

BEGIN {
	my @NAMES = qw(
		Any Item Undef Defined Bool Value Ref Str Num Int CodeRef RegexpRef
		GlobRef FileHandle Object ClassName RoleName ScalarRef ArrayRef HashRef
	);
	require constant;
	require Types::Standard;
	constant->import(+{ map +( $_ => "Types::Standard"->get_type($_) ), @NAMES });
	
	our @EXPORT_OK   = @NAMES;
	our %EXPORT_TAGS = (
		constants      => \@NAMES,
		only_constants => \@NAMES,
	);
}

1;

__END__

=head1 NAME

Scalar::Does::MooseTypes - (DEPRECATED) additional constants for Scalar::Does, inspired by the built-in Moose type constraints

=head1 SYNOPSIS

  use 5.010;
  use Scalar::Does qw(does);
  use Scalar::Does::MooseTypes -all;
  
  my $var = [];
  if (does $var, ArrayRef) {
    say "It's an arrayref!";
  }

=head1 STATUS

This module is deprecated; use L<Types::Standard> instead:

  use 5.010;
  use Scalar::Does qw(does);
  use Types::Standard qw(ArrayRef);
  
  my $var = [];
  if (does $var, ArrayRef) {
    say "It's an arrayref!";
  }

=head1 DESCRIPTION

=head2 Constants

=over

=item C<Any>

=item C<Item>

=item C<Bool>

=item C<Undef>

=item C<Defined>

=item C<Value>

=item C<Str>

=item C<Num>

=item C<Int>

=item C<ClassName>

=item C<RoleName>

=item C<Ref>

=item C<ScalarRef>

=item C<ArrayRef>

=item C<HashRef>

=item C<CodeRef>

=item C<RegexpRef>

=item C<GlobRef>

=item C<FileHandle>

=item C<Object>

=back

=head1 SEE ALSO

L<Types::Standard>.

L<Scalar::Does>,
L<Moose::Util::TypeConstraints>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

