package MooseX::Getopt::Meta::Attribute::Trait::NoGetopt;
# ABSTRACT: Optional meta attribute trait for ignoring parameters

our $VERSION = '0.78';

use Moose::Role;
use namespace::autoclean;

# register this as a metaclass alias ...
package # stop confusing PAUSE
    Moose::Meta::Attribute::Custom::Trait::NoGetopt;
sub register_implementation { 'MooseX::Getopt::Meta::Attribute::Trait::NoGetopt' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Getopt::Meta::Attribute::Trait::NoGetopt - Optional meta attribute trait for ignoring parameters

=head1 VERSION

version 0.78

=head1 SYNOPSIS

  package App;
  use Moose;

  with 'MooseX::Getopt';

  has 'data' => (
      traits  => [ 'NoGetopt' ],  # do not attempt to capture this param
      is      => 'ro',
      isa     => 'Str',
      default => 'file.dat',
  );

=head1 DESCRIPTION

This is a custom attribute metaclass trait which can be used to
specify that a specific attribute should B<not> be processed by
C<MooseX::Getopt>. All you need to do is specify the C<NoGetopt>
metaclass trait.

  has 'foo' => (traits => [ 'NoGetopt', ... ], ... );

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Getopt>
(or L<bug-MooseX-Getopt@rt.cpan.org|mailto:bug-MooseX-Getopt@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHOR

Stevan Little <stevan@iinteractive.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
