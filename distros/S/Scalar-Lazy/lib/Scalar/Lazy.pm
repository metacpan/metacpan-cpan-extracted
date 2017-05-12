package Scalar::Lazy;
use warnings;
use strict;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.3 $ =~ /(\d+)/g;
use base 'Exporter';
our @EXPORT = qw/ delay lazy /;

sub new($&;$) { 
    my ($pkg, $code, $init) = @_;
    if ($init){
	my $val = $code->();
	$code = sub { $val };
    }
    bless $code, $pkg;
}

sub lazy(&;$) { __PACKAGE__->new(@_) }
*delay = \&lazy;

sub force($){
    my $pkg = ref $_[0];
    bless $_[0], $pkg . '::FORCE';
    my $val = $_[0]->();
    bless $_[0], $pkg;
    $val;
}

use overload (
    fallback => 1,
    map { $_ => \&force } qw( bool "" 0+ ${} @{} %{} &{} *{} )
);

1;    # End of Scalar::Lazy

=head1 NAME

Scalar::Lazy - Yet another lazy evaluation in Perl

=head1 VERSION

$Id: Lazy.pm,v 0.3 2008/06/01 17:09:08 dankogai Exp dankogai $

=head1 SYNOPSIS

  use Scalar::Lazy;
  my $scalar = lazy { 1 };
  print $scalar; # you don't have to force

  # Y-combinator made easy
  my $zm = sub { my $f = shift;
                 sub { my $x = shift; 
                       lazy { $f->($x->($x)) }
                   }->(sub { my $x = shift; 
                             lazy { $f->($x->($x)) }
                         })};
  my $fact = $zm->(sub { my $f = shift;
                         sub { my $n = shift;
                               $n < 2  ? 1 : $n * $f->($n - 1) } });
  print $fact->(10); # 3628800

=head1 DISCUSSION

The classical way to implement lazy evaluation in an eager-evaluating
languages (including perl, of course) is to wrap the value with a closure:

  sub delay{
    my $value = shift;
    sub { $value }
  }
  my $l = delay(42);

Then evaluate the closure whenever you need it.

  my $v = $l->();

Marking the variable lazy can be easier with prototypes:

  sub delay(&){ $_[0] }
  my $l = delay { 42 }

But forcing the value is pain in the neck.

This module makes it easier by making the value auto-forcing.

=head2 HOW IT WORKS

Check the source.  That's what the source is for.

There are various CPAN modules that does what this does.  But I found
others too complicated.  Hey, the whole code is only 25 lines long!
(Well, was until 0.03) Nicely fits in a good-old terminal screen.

The closest module is L<Scalar::Defer>, a brainchild of Audrey Tang.
But I didn't like the way it (ab)?uses namespace.

L<Data::Thunk> depends too many modules.

And L<Data::Lazy> is overkill.

All I needed was auto-forcing and this module does just that.

=head1 EXPORT

C<lazy> and C<delay>.

=head1 FUNCTIONS

=head2 lazy

  lazy { value }

is really:

  Scalar::Lazy->new(sub { value });

You can optionally set the second parameter.  If set, the value
becomes constant.  The folloing example illustrates the difference.

  my $x = 0;
  my $once = lazy { ++$x } 'init'; # $once is always 1
  is $once, 1, 'once';
  is $once, 1, 'once';
  my $succ = lazy { ++$x }; # $succ always increments $x
  isnt $succ, 1, 'succ';
  is $succ, 3, 'succ';

=head2 delay

an alias to L</lazy>.

=head1 METHODS

=head2 new

Makes a lazy variable which auto-forces on demand.

=head2 force

You don't really need to call this method (that's the whole point of this 
module!) but if you want, you can

  my $l = lazy { 1 };
  my $v = $l->force;

=head1 AUTHOR

Dan Kogai, C<< <dankogai at dan.co.jp> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-scalar-lazy at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Scalar-Lazy>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Scalar::Lazy

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Scalar-Lazy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Scalar-Lazy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Scalar-Lazy>

=item * Search CPAN

L<http://search.cpan.org/dist/Scalar-Lazy>

=back

=head1 ACKNOWLEDGEMENTS

Highly inspired by L<Scalar::Defer> by Audrey Tang.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Dan Kogai, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
