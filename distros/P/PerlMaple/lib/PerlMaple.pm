#: PerlMaple.pm
#: implementation for the PerlMaple class
#: Copyright (c) 2005-2006 Agent Zhang
#: 2005-11-14 2006-05-02

package PerlMaple;

use 5.006001;
use strict;
use warnings;

use PerlMaple::Expression;
use Carp qw(carp croak);
use vars qw( $AUTOLOAD );

our $VERSION = '0.07';
my $Started = 0;

require XSLoader;
XSLoader::load('PerlMaple', $VERSION);

sub new {
    my $class = shift;
    my %opts = @_;
    if (!exists $opts{PrintError}) {
        $opts{PrintError} = 1;
    }
    if ($Started or maple_start()) {
        $Started = 1;
        return bless \%opts, $class;
    }
    return undef;
}

sub eval_cmd {
    my ($self, $exp) = @_;
    $exp =~ s/[\s\n\r]+$//s;
    #if ($exp !~ /[;:]$/) {
    #    $exp .= ';';
    #}
    if ($self->{LogCmd}) {
        warn "$exp\n";
    }
    maple_eval($exp);
    my $warning = maple_warning();
    if ($self->{PrintError} and $warning) {
        carp "PerlMaple: $warning";
    }
    if (maple_success()) {
        my $res = maple_result();
        return
            $self->{ReturnAST} ? $self->to_ast($res) : $res;
    }
    if ($self->{PrintError}) {
        carp "PerlMaple: ", $self->error,
            " when evaluating \"$exp\"";
    }
    if ($self->{RaiseError}) {
        croak "PerlMaple: ", $self->error,
            " when evaluating \"$exp\"";
    }
    return undef;
}

sub PrintError {
    my $self = shift;
    if (@_) {
        $self->{PrintError} = shift;
    } else {
        return $self->{PrintError};
    }
}

sub RaiseError {
    my $self = shift;
    if (@_) {
        $self->{RaiseError} = shift;
    } else {
        return $self->{RaiseError};
    }
}

sub ReturnAST {
    my $self = shift;
    if (@_) {
        $self->{ReturnAST} = shift;
    } else {
        return $self->{ReturnAST};
    }
}

sub error {
    if (!maple_success()) {
        return maple_error();
    }
    return undef;
}

sub to_ast {
    shift;
    return PerlMaple::Expression->new(@_);
}

sub AUTOLOAD {
    my $self = shift;
    my $method = $AUTOLOAD;
    #warn "$method";

    $method =~ s/.*:://;
    return if $method eq 'DESTROY';

    my $args = join(',', @_);
    $args =~ s/,\s*$//g;
    return $self->eval_cmd("$method($args);");
}

1;

__END__

=head1 NAME

PerlMaple - Perl binding for Maplesoft's Maple mathematical package

=head1 VERSION

This document describes PerlMaple 0.07 released on Nov 20, 2009.

=head1 SYNOPSIS

  use PerlMaple;

  $maple = PerlMaple->new or
      die $maple->error;
  $ans = $maple->eval_cmd('int(2*x^3,x);');
  defined $ans or die $maple->error;

  $maple->eval_cmd(<<'.');
  lc := proc( s, u, t, v )
           description "form a linear combination of the arguments";
           s * u + t * v
  end proc;
  .

  $maple = PerlMaple->new(
    PrintError => 0,
    RaiseError => 1,
  );

  print $maple->eval('solve(x^2+2*x+4, x)');  # got: -1+I*3^(1/2), -1-I*3^(1/2)
  print $maple->solve('x^2+2*x+4', 'x');  # ditto
  print $maple->eval('int(2*x^3,x)', 'x=2');  # got: 8s
  print $maple->int('2*x^3', 'x=0..2');  # ditto

  $maple->PrintError(1);
  $maple->RaiseError(0);

  print $maple->diff('2*x^3', 'x'); # got: 6*x^2
  print $maple->ifactor('1000!');  # will get a lot of stuff...

  # Advanced usage (manipulating Maple ASTs directly):
  $ast = $maple->to_ast('[1,2,3]');
  foreach ($ast->ops) {
      print;  # got 1, 2, and 3 respectively
  }

  # Get eval_cmd and other AUTOLOADed Maple function
  # to return ASTs automagically:
  $maple->ReturnAST(1);
  $ast = $maple->solve('x^2+x=0', 'x');
  if ($ast and $ast->type('exprseq')) {
    foreach ($ast->ops) {
        push @roots, $_;
    }
  }
  print "@roots";  # got: 0 -1

  $maple->ReturnAST(1);
  $res = $maple->solve('{x+y=2,x-y=3}', '{x,y}');
  if ($res->type('set')) {
      $x = first { $_->lhs eq 'x' } $res->ops;
      print $x->rhs;  # 5/2
  }

=head1 DESCRIPTION

Maple is a great tool for solving mathematical problems and creating
interactive technical applications provided by Maplesoft. Its power of 
symbolic calculation is extremely impressive.

This is a simple (but already powerful) Perl binding for Maple's
OpenMaple C interface. To try out this binding, you have to 
purchase and install the Maple software first:

L<http://www.maplesoft.com>.

The Maple software is *not* free, sigh, unlike this CPAN distribution.

=head1 INSTALLATION

Currently this software is only tested on Win32 against Maple 9.01 and
Maple 10.00, but it's believed to work with other versions higher than
9. If you get it work with a specific version of Maple, please send me
a mail and let me know. :=)

To build this module properly, you must first have Maple 9 or better 
installed on your system and append
the paths of B<maplec.h> and B<maplec.lib> in your Maple installation to the
environments LIB and INC respectively. Because this module use Maple's
C interface (OpenMaple) via XS.

Both F<maplec.h> and F<maplec.lib> (or maplec.a on *NIX systems?) are
provided by your Maple installation itself. A typical path of maplec.h
is "C:\Program Files\Maple 9\extern\include",
which should be appended to the INCLUDE environment. And a typical path
of maplec.lib is "C:\Program Files\Maple 9\bin.win", which should be
appended to the LIB environment. These paths may be different on your
machine but do depend on your Maple's version and location.

It may be similar on UNIX, but I haven't tried that.

It's known that this library's XS part won't work with Maple 7 on Win32.
Sigh.

=head2 EXPORT

None by default.

=head1 METHODS

PerlMaple uses AUTOLOAD mechanism so that any Maple functions are also valid
methods of your PerlMaple object, even those Maple procedures defined by
yourself.

When the ReturnAST attribute is on, all AUTOLOADed methods, along with the
C<eval_cmd> method will return a
PerlMaple::Expression object constructed from the resulting expression.
Because there's a cost involved in constructing an AST from the given Maple
expression, so the ReturnAST attribute is off by default.

B<WARNING:> The C<eval> method is now incompatible with that of the first
release (0.01). It is AUTOLOADed as the Maple counterpart. So you have to turn to
C<eval_cmd> when Maple's eval function can't fit your needs. Sorry.

=over

=item $obj->new()

=item $obj->new(RaiseError => 0, PrintError => 1, ReturnAST => 0)

Class constructor. It starts a Maple session if it does not exist. It should
be noting that although you're able to create more than one PerlMaple objects,
all these maple objects share the same Maple session. So the context of each
PerlMaple objects may be corrupted intentionally. If any error occurs, this
method will return undef value, and set the internal error buffer which you can
read by the C<error> method.

This method also accepts two optional named arguments. When RaiseError is
set true, the constructor sets the RaiseError attribute of the new object
internally. And it is the same for the PrintError and ReturnAST attributes.

=item $obj->eval_cmd($command)

This method may be the most important one for the implementation of this class.
It evaluates the
command stored in the argument, and returns a string containing the result
when the ReturnAST attribute is off. (It's off by default.)
If an error occurs, it will return undef, and set the internal error buffer
which you can read by the C<error> method.

Frankly speaking, most of the time you can use C<eval> method instead of
invoking this method directly. However, this method is a bit faster,
because any AUTOLOADed method is invoked this one internally. Moreover, there
exists something that can only be eval'ed properly by C<eval_cmd>.
Here is a small example:

    $maple->eval_cmd(<<'.');
    lc := proc( s, u, t, v )
             description "form a linear combination of the arguments";
             s * u + t * v
    end proc;
    .

If you use C<eval> instead, you will get the following error message:

    `:=` unexpected

That's because "eval" is a normal Maple function and hence you can't use
assignment statement as the argument.

When the ReturnAST attribute is on, this method will return a
PerlMaple::Expression object constructed from the expression returned by
Maple automatically.

=item $obj->to_ast($maple_expr, ?$verified)

This method is a shortcut for constructing a PerlMaple::Expression
instance. For more information on the PerlMaple::Expression class
and the second optional argument of this method, please turn to
L<PerlMaple::Expression>.

Here is a quick demo to illustrate the power of the PerlMaple::Expression
class (you can get many more in the doc for L<PerlMaple::Expression>.

    $ast = $maple->to_ast('[1,2,3]');
    my @list;
    foreach ($ast->ops) {
        push @list, $_->expr;
    }
    # now @list contains numbers 1, 2, and 3.

=item $obj->error()

It returns the error message issued by the Maple kernel.

=back

=head1 ATTRIBUTES

All the attributes specified below can be set by passing name-value pairs to
the C<new> method.

=over

=item $obj->PrintError()

=item $obj->PrintError($new_value)

The PrintError attribute can be used to force errors to generate warnings
(using Carp::carp) in addition to returning error codes in the normal way. When
set ``on'' (say, a true value), any method which results in an error
occurring will cause the PerlMaple to effectively do a
C<< carp("PerlMaple error: ", $self->error, " when evaluating \"$exp\"";) >>.
Any warnings from the Maple kernel will also be sent to stderr via carp
if PrintError is on.

By default, the constructor C<new> sets PrintError ``on''.

=item $obj->RaiseError()

=item $obj->RaiseError($new_value)

The RaiseError attribute can be used to force errors to raise exceptions
rather than simply return error codes in the normal way. It is ``off''
(say, a false value in Perl) by default. When set ``on'', any method
which results in an error will cause the PerlMaple to effectively do a
C<< croak("PerlMaple error: ", $self->error, " when evaluating \"$exp\"";) >>.

If you turn RaiseError on then you'd normally turn PrintError off.
If PrintError is also on, then the PrintError is done first (naturally).

=item $obj->ReturnAST()

=item $obj->ReturnAST($new_value)

The ReturnAST attribute can be used to force the C<eval_cmd> method
and hence all AUTOLOADed Maple functions to return a Abstract
Syntactic Tree (AST). Because there is a cost to evaluate the C<to_ast>
method every time, so this attribute is off by default.

=back

=head1 INTERNAL FUNCTIONS

=over

=item maple_error

Returns the raw error message issued by the Maple kernel.

=item maple_warning

Returns the raw warning message returned by the Maple kernel.

=item maple_eval

Raw XS C method that evaluates any Maple commands.

=item maple_result

Returns the raw output of the Maple kernel.

=item maple_start

Starts the global Maple kernel. (No that all PerlMaple objects share
the same Maple engine, so preventing context clashes is the
duty of the user.

=item maple_success

Indicates whether the last Maple evaluation is successful.

=back

=head1 CODE COVERAGE

I use L<Devel::Cover> to test the code coverage of my tests, below is the
L<Devel::Cover> report on this module's test suite (version 0.06):

    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    blib/lib/PerlMaple.pm          92.4   80.8   66.7  100.0  100.0  100.0   89.9
    ...b/PerlMaple/Expression.pm   98.7   88.9   66.7  100.0  100.0    0.0   94.6
    Total                          95.9   85.5   66.7  100.0  100.0  100.0   92.5
    ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 BUGS

=over

At this point, every PerlMaple objects are merely a bunch of options (e.g.
PrintError, RaiseError, and ReturnAST). They actually share the same Maple
engine for performance reasons. So the evaluating contexts for each
PerlMaple objects may corrupt together. So please don't store
permanent values in Maple variables, avoid reference Maple special variables,
like %, %%, and don't trust the Maple contexts. Since they may be changed
accidentally by other PerlMaple objects, even those used by
PerlMaple::Expression instances, in the duration.

=back

=head1 TODO

=over

=item *

Add facilities to ease importing of Perl complex data structures to Maple
environment, i.e. a list of lists of numbers.

=item *

Port this binding to Linux Maple users and (hopefully) to MATLAB users as well.

=item *

Add the C<LogCommand> attribute so that PerlMaple will log down all the Maple 
commands sent to the Maple engine in disk files.

=item *

Added PerlMaple::Cookbook and PerlMaple::Tutorial to the distribution.
Programming Maple in Perl is extremely interesting and useful, so I
believe these docs are really worth my while.

=back

=head1 REPOSITORY

You can always get the latest version from the following SVN
repository:

L<https://svn.berlios.de/svnroot/repos/win32maple>

If you want a committer bit, please let me know.

=head1 SEE ALSO

L<PerlMaple::Expression>,
L<http://www.maplesoft.com>.

=head1 AUTHOR

Agent Zhang, E<lt>agentzh@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2006 Agent Zhang

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
