package Perl6::Perl;
#
# $Id: Perl.pm,v 0.1 2006/12/23 23:12:17 dankogai Exp dankogai $
#
use 5.008001;
use strict;
use warnings;
use Data::Dumper ();
use Scalar::Util qw/blessed/;
use base 'Exporter';
our $VERSION = sprintf "%d.%02d", q$Revision: 0.1 $ =~ /(\d+)/g;
our @EXPORT = qw();
our %EXPORT_TAGS = ( 'all' => [ qw(
	p perl
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

# Default Values
our %DD_Default = (
    Deparse => 1,
    Terse   => 1,
    Useqq   => 1,
);

sub perl {
    my $self = shift;
    return $self unless ref $self;
    my $dd = Data::Dumper->new( [$self] );
    $dd->$_( $DD_Default{$_} ) for keys %DD_Default;
    $dd->Indent(
        blessed($self) && $self->isa('CODE') ? 2
	: ref $self eq 'CODE' ? 2 : 0
    );
    while ( my ( $k, $v ) = splice( @_, 0, 2 ) ){
	$k = ucfirst $k;
	$dd->$k($v);
    }
    return $dd->Dump;
}

sub p{ print perl(@_), "\n" }

*UNIVERSAL::perl = \&perl;

# Preloaded methods go here.

1;
__END__

=head1 NAME

Perl6::Perl - $obj->perl just like $obj.perl in Perl 6

=head1 SYNOPSIS

  # As UNIVERSAL method
  use Perl6::Perl;
  use Foo::Bar;
  my $baz  = Foo::Bar->new();
  my $bazz = eval( $baz->perl ); # $bazz is a copy of $baz

  # As subroutine so you can apply to non-objects
  use Perl6::Perl qw/perl/; # explicitly import
  perl $scalar;
  perl \@array;
  perl \%hash;
  perl \*GLOB;
  perl sub{ $_[0] + 1 };

  # Ruby's p

  p $complex_object;

=head1 DESCRIPTION

In Perl 6, everything is an object and every object comes with the
C<.perl> method that returns the C<eval()>uable representation
thereof.  This module does just that.

Since Perl 5 is already shipped with L<Data::Dumper>, this module
makes use of it; In fact C<< $obj->perl >> is just a wrapper to
C<Dumper($obj)> with options slightly different from Data::Dumper's
default.

=head2 p as in Ruby.

This module also comes with C<p>, which is analogous to that of ruby;
It is simply C< sub p{ print perl(@_), "\n" }>.  But you save a lot of
key strokes -- even more concise than C< say @_.perl >.

Though p is not Perl6's spec, I couldn't resist adding this to this
module because so many people envy Ruby for it :).

=head2 Data::Dumper options

Perl6::Perl uses the following values as default:

=over 2

=item Deparse

1 so you can serialize coderef.

=item Terse

1 so no C<$VAR1 = > appears.

=item Useqq

1 so you can safely inspect binary data as well as Unicode characters.

=item Indent

2 if the object is a coderef, 0 otherwise.

=back

You can override these by feeding Data::Dumper options as follows;

  $obj->perl(purity => 1); # if the object contains circular reference.

Note you can use all lowercaps here.

=head2 EXPORT

None by default. C<perl> and C<p> are exported on demand.

=head1 SEE ALSO

L<Data::Dumper>, L<http://dev.perl.org/perl6/>

=head1 AUTHOR

Dan Kogai, E<lt>dankogai@dan.co.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Dan Kogai

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
