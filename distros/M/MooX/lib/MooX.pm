package MooX;
BEGIN {
  $MooX::AUTHORITY = 'cpan:GETTY';
}
{
  $MooX::VERSION = '0.101';
}
# ABSTRACT: Using Moo and MooX:: packages the most lazy way

use strict;
use warnings;
use Import::Into;
use Module::Runtime qw( use_module );
use Carp;
use Data::OptList;

sub import {
	my ( $class, @modules ) = @_;
	my $target = caller;
	unshift @modules, '+Moo';
	MooX::import_base($class,$target,@modules);
}

sub import_base {
	my ( $class, $target, @modules ) = @_;
	my @optlist = @{Data::OptList::mkopt([@modules],{
		must_be => [qw( ARRAY HASH )],
	})};
	for (@optlist) {
		my $package = $_->[0];
		my $opts = $_->[1];
		for ($package) { s/^\+// or $_ = "MooX::$_" };
		my @args = ref $opts eq 'ARRAY'
			? @{$opts}
			: ref $opts eq 'HASH'
				? %{$opts}
				: ();
		use_module($package)->import::into($target,@args);
	}
}

1;


__END__
=pod

=head1 NAME

MooX - Using Moo and MooX:: packages the most lazy way

=head1 VERSION

version 0.101

=head1 SYNOPSIS

  package MyClass;

  use MooX qw(
    Options
  );

  # use Moo;
  # use MooX::Options;

  package MyClassComplex;

  use MooX
    SomeThing => [qw( import params )],
    'OtherThing', MoreThing => { key => 'value' },
    '+NonMooXStuff';

  # use Moo;
  # use MooX::SomeThing qw( import params );
  # use MooX::OtherThing;
  # use MooX::MoreThing key => 'value';
  # use NonMooXStuff;

  package MyMoo;

  use MooX ();

  sub import { MooX->import::into(scalar caller, qw( A B +Carp )) }

  # then you can do: use MyMoo; which does the same as:
  # use Moo;
  # use MooX::A;
  # use MooX::B;
  # use Carp;

=head1 DESCRIPTION

Using L<Moo> and MooX:: packages the most lazy way

=encoding utf8

=head1 SEE ALSO

=head2 L<Import::Into>

=head1 SUPPORT

Repository

  http://github.com/Getty/p5-moox
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-moox/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

