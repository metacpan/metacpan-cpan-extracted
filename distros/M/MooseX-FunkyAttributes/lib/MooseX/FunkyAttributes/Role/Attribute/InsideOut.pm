package MooseX::FunkyAttributes::Role::Attribute::InsideOut;

use 5.008;
use strict;
use warnings;

BEGIN {
	$MooseX::FunkyAttributes::Role::Attribute::InsideOut::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::FunkyAttributes::Role::Attribute::InsideOut::VERSION   = '0.003';
}

use Hash::FieldHash ();
use Scalar::Util ();
use Moose::Role;
use namespace::autoclean;

with qw(MooseX::FunkyAttributes::Role::Attribute);

our @_HASHES;

my $i = 0;
before _process_options => sub
{
	my ($class, $name, $options) = @_;
	
	my $hashcount = $i++;
	Hash::FieldHash::fieldhash my %h;
	$_HASHES[$hashcount] = \%h;
	
	$options->{custom_get}           = sub { $h{ $_[1] } };
	$options->{custom_set}           = sub { $h{ $_[1] } = $_[2] };
	$options->{custom_has}           = sub { exists $h{ $_[1] } };
	$options->{custom_clear}         = sub { delete $h{ $_[1] } };
	$options->{custom_weaken}        = sub { Scalar::Util::weaken( $h{ $_[1] } ) };
	$options->{custom_init}          = sub { $h{ $_[1] } = $_[2] };
	$options->{custom_inline_get}    = sub { my ($self, $inst) = @_; qq(\$MooseX::FunkyAttributes::Role::Attribute::InsideOut::_HASHES[$hashcount]{$inst}) };
	$options->{custom_inline_set}    = sub { my ($self, $inst, $val) = @_; qq(\$MooseX::FunkyAttributes::Role::Attribute::InsideOut::_HASHES[$hashcount]{$inst} = $val) };
	$options->{custom_inline_weaken} = sub { my ($self, $inst) = @_; qq(Scalar::Util::weaken \$MooseX::FunkyAttributes::Role::Attribute::InsideOut::_HASHES[$hashcount]{$inst}) };
	$options->{custom_inline_has}    = sub { my ($self, $inst) = @_; qq(exists \$MooseX::FunkyAttributes::Role::Attribute::InsideOut::_HASHES[$hashcount]{$inst}) };
	$options->{custom_inline_clear}  = sub { my ($self, $inst) = @_; qq(delete \$MooseX::FunkyAttributes::Role::Attribute::InsideOut::_HASHES[$hashcount]{$inst}) };
};

1;

__END__

=head1 NAME

MooseX::FunkyAttributes::Role::Attribute::InsideOut - an inside-out attribute

=head1 SYNOPSIS

   package Person;
   
   use Moose;
   use MooseX::FunkyAttributes;
   
   has name => (
      traits => [ InsideOutAttribute ],
      is     => 'ro',
      isa    => 'Str',
   );
   
   has age => (
      is     => 'ro',
      isa    => 'Num',
   );
   
   package main;
   
   use feature 'say';
   
   my $bob = Person->new(name => 'Bob', age => 32);
   say $bob->name;   # Bob
   say $bob->dump;   # $VAR1 = bless({ age => 32 }, 'Person');

=head1 DESCRIPTION

This trait implements the "inside-out" technique for Moose attributes. Unlike
L<MooseX::InsideOut> it doesn't make all attributes in the class inside-out;
just the attribute(s) it is applied to.

One situation where you might want to do this is to hide certain attributes
from dumps. For example, a "password" attribute that you don't want to appear
in log files, or an attribute which contains a large chunk of textual data or
a deeply nested data structure which makes the logs less readable.

This trait inherits from L<MooseX::FunkyAttributes::Role::Attribute>, but
forget about most of what you read in the documentaton for that trait. Those
C<custom_set>, C<custom_get>, C<custom_inline_set>, etc options are all
automatically generated for you.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-FunkyAttributes>.

=head1 SEE ALSO

L<MooseX::FunkyAttributes>, L<MooseX::InsideOut>, L<Hash::FieldHash>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

