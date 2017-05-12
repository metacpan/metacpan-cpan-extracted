package MooseX::Mangle;
our $VERSION = '0.02';
use Moose ();
use Moose::Exporter;

=head1 NAME

MooseX::Mangle - mangle the argument list or return values of your methods

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  package Foo;
  use Moose;

  sub foo { "FOO" }
  sub bar { shift; join '-', @_ }

  package Foo::Sub;
  use Moose;
  use MooseX::Mangle;
  extends 'Foo';

  mangle_return foo => sub {
      my $self = shift;
      my ($foo) = @_;
      return lc($foo) . 'BAR';
  };

  mangle_args bar => sub {
      my $self = shift;
      my ($a, $b, $c) = @_;
      return ($b, $c, $a);
  };

  my $foo = Foo::Sub->new->foo            # 'fooBAR'
  my $bar = Foo::Sub->new->bar(qw(a b c)) # 'b-c-a'

=head1 DESCRIPTION

C<MooseX::Mangle> provides some simple sugar for common usages of C<around>.
Oftentimes all that is needed is to adjust the argument list or returned values
of a method, but using C<around> directly for this can be tedious. This module
exports a few subroutines which make this a bit easier.

=cut

=head1 EXPORTS

=cut

=head2 mangle_args METHOD_NAME CODE

Applies an C<around> method modifier to METHOD_NAME, using CODE to mangle the
argument list. CODE is called as a method, and additionally receives the
arguments passed to the method; it should return the list of arguments to
actually pass to the method.

=cut

sub mangle_args {
    my $meta = shift;
    my ($method_name, $code) = @_;
    $meta->add_around_method_modifier($method_name => sub {
        my $orig = shift;
        my $self = shift;
        my @args = $self->$code(@_);
        return $self->$orig(@args);
    });
}

=head2 mangle_return METHOD_NAME CODE

Applies an C<around> method modifier to METHOD_NAME, using CODE to mangle the
returned values. CODE is called as a method, and additionally receives the
values returned by the method; it should return the list of values to actually
return.

=cut

sub mangle_return {
    my $meta = shift;
    my ($method_name, $code) = @_;
    $meta->add_around_method_modifier($method_name => sub {
        my $orig = shift;
        my $self = shift;
        if (wantarray) {
            my @ret = $self->$orig(@_);
            return $self->$code(@ret);
        }
        elsif (defined(wantarray)) {
            my $ret = $self->$orig(@_);
            return $self->$code($ret);
        }
        else {
            $self->$orig(@_);
            $self->$code();
            return;
        }
    });
}

=head2 guard METHOD_NAME CODE

Provides a requirement that must be satisfied in order for C<METHOD_NAME> to be
called. C<CODE> is called as a method, receiving the arguments passed to the
method. If C<CODE> returns true, the method is called as normal, otherwise
undef is returned without the original method being called at all.

=cut

sub guard {
    my $meta = shift;
    my ($method_name, $code) = @_;
    $meta->add_around_method_modifier($method_name => sub {
        my $orig = shift;
        my $self = shift;
        if ($self->$code(@_)) {
            return $self->$orig(@_);
        }
        return;
    });
}

Moose::Exporter->setup_import_methods(
    with_meta => [qw(mangle_args mangle_return guard)],
);

=head1 BUGS

No known bugs.

Suggestions for more modifiers are always welcome, though.

Please report any bugs through RT: email
C<bug-moosex-mangle at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-Mangle>.

=head1 SEE ALSO

L<Moose>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc MooseX::Mangle

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-Mangle>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Mangle>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-Mangle>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-Mangle>

=back

=head1 AUTHOR

  Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;