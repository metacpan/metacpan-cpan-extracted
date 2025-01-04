package MooseX::Getopt::Dashes;
# ABSTRACT: convert underscores in attribute names to dashes

our $VERSION = '0.78';

use Moose::Role;
with 'MooseX::Getopt';
use namespace::autoclean;

around _get_cmd_flags_for_attr => sub {
    my $next = shift;
    my ( $class, $attr, @rest ) = @_;

    my ( $flag, @aliases ) = $class->$next($attr, @rest);
    $flag =~ tr/_/-/
        unless $attr->does('MooseX::Getopt::Meta::Attribute::Trait')
            && $attr->has_cmd_flag;

    return ( $flag, @aliases );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Getopt::Dashes - convert underscores in attribute names to dashes

=head1 VERSION

version 0.78

=head1 SYNOPSIS

  package My::App;
  use Moose;
  with 'MooseX::Getopt::Dashes';

  # Will be called as --some-thingy, not --some_thingy
  has 'some_thingy' => (
      is      => 'ro',
      isa     => 'Str',
      default => 'foo'
  );

  # Will be called as --another_thingy, not --another-thingy
  has 'another_thingy' => (
      traits   => [ 'Getopt' ],
      cmd_flag => 'another_thingy'
      is       => 'ro',
      isa      => 'Str',
      default  => 'foo'
  );

  # use as MooseX::Getopt

=head1 DESCRIPTION

This is a version of L<MooseX::Getopt> which converts underscores in
attribute names to dashes when generating command line flags.

You can selectively disable this on a per-attribute basis by supplying
a L<cmd_flag|MooseX::Getopt::Meta::Attribute/METHODS> argument with
the command flag you'd like for a given attribute. No underscore to
dash replacement will be done on the C<cmd_flag>.

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
