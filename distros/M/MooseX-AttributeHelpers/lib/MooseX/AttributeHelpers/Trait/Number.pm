package MooseX::AttributeHelpers::Trait::Number;
use Moose::Role;

our $VERSION = '0.25';

with 'MooseX::AttributeHelpers::Trait::Base';

sub helper_type { 'Num' }

# NOTE:
# we don't use the method provider for this 
# module since many of the names of the provied
# methods would conflict with keywords
# - SL

has 'method_constructors' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        return +{
            set => sub {
                my ($attr, $reader, $writer) = @_;
                return sub { $writer->($_[0], $_[1]) };
            },
            add => sub {
                my ($attr, $reader, $writer) = @_;
                return sub { $writer->($_[0], $reader->($_[0]) + $_[1]) };
            },
            sub => sub {
                my ($attr, $reader, $writer) = @_;
                return sub { $writer->($_[0], $reader->($_[0]) - $_[1]) };
            },
            mul => sub {
                my ($attr, $reader, $writer) = @_;
                return sub { $writer->($_[0], $reader->($_[0]) * $_[1]) };
            },
            div => sub {
                my ($attr, $reader, $writer) = @_;
                return sub { $writer->($_[0], $reader->($_[0]) / $_[1]) };
            },
            mod => sub {
                my ($attr, $reader, $writer) = @_;
                return sub { $writer->($_[0], $reader->($_[0]) % $_[1]) };
            },
            abs => sub {
                my ($attr, $reader, $writer) = @_;
                return sub { $writer->($_[0], abs($reader->($_[0])) ) };
            },
        }
    }
);
    
no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::AttributeHelpers::Trait::Number

=head1 VERSION

version 0.25

=head1 SYNOPSIS

  package Real;
  use Moose;
  use MooseX::AttributeHelpers;
  
  has 'integer' => (
      metaclass => 'Number',
      is        => 'ro',
      isa       => 'Int',
      default   => sub { 5 },
      provides  => {
          set => 'set',
          add => 'add',
          sub => 'sub',
          mul => 'mul',
          div => 'div',
          mod => 'mod',
          abs => 'abs',
      }
  );

  my $real = Real->new();
  $real->add(5); # same as $real->integer($real->integer + 5);
  $real->sub(2); # same as $real->integer($real->integer - 2);  

=head1 DESCRIPTION

This provides a simple numeric attribute, which supports most of the
basic math operations.

=head1 METHODS

=over 4

=item B<meta>

=item B<helper_type>

=item B<method_constructors>

=back

=head1 PROVIDED METHODS

It is important to note that all those methods do in place
modification of the value stored in the attribute.

=over 4

=item I<set ($value)>

Alternate way to set the value.

=item I<add ($value)>

Adds the current value of the attribute to C<$value>.

=item I<sub ($value)>

Subtracts the current value of the attribute to C<$value>.

=item I<mul ($value)>

Multiplies the current value of the attribute to C<$value>.

=item I<div ($value)>

Divides the current value of the attribute to C<$value>.

=item I<mod ($value)>

Modulus the current value of the attribute to C<$value>.

=item I<abs>

Sets the current value of the attribute to its absolute value.

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-AttributeHelpers>
(or L<bug-MooseX-AttributeHelpers@rt.cpan.org|mailto:bug-MooseX-AttributeHelpers@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHOR

Stevan Little <stevan@iinteractive.com>

Robert Boone

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Stevan Little and Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
