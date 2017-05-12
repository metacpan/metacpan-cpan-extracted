package Sub::Op;

use 5.010;

use strict;
use warnings;

=head1 NAME

Sub::Op - Install subroutines as opcodes.

=head1 VERSION

Version 0.02

=cut

our ($VERSION, @ISA);

sub dl_load_flags { 0x01 }

BEGIN {
 $VERSION = '0.02';
 require DynaLoader;
 push @ISA, 'DynaLoader';
 __PACKAGE__->bootstrap($VERSION);
}

=head1 SYNOPSIS

In your XS file :

    #include "sub_op.h"

    STATIC OP *scalar_util_reftype(pTHX) {
     dSP;
     dMARK;
     SV *sv = POPs;
     if (SvMAGICAL(sv))
      mg_get(sv);
     if (SvROK(sv))
      PUSHs(sv_reftype(SvRV(sv), 0));
     else
      PUSHs(&PL_sv_undef);
     RETURN;
    }

    MODULE = Scalar::Util::Ops       PACKAGE = Scalar::Util::Ops

    BOOT:
    {
     sub_op_config_t c;
     c.name    = "reftype";
     c.namelen = sizeof("reftype")-1;
     c.pp      = scalar_util_reftype;
     c.check   = 0;
     c.ud      = NULL;
     sub_op_register(aTHX_ &c);
    }

In your Perl module file :

    package Scalar::Util::Ops;

    use strict;
    use warnings;

    our ($VERSION, @ISA);

    use Sub::Op; # Before loading our own shared library

    BEGIN {
     $VERSION = '0.01';
     require DynaLoader;
     push @ISA, 'DynaLoader';
     __PACKAGE__->bootstrap($VERSION);
    }

    sub import   { Sub::Op::enable(reftype => scalar caller) }

    sub unimport { Sub::Op::disable(reftype => scalar caller) }

    1;

In your F<Makefile.PL> :

    use ExtUtils::Depends;

    my $ed = ExtUtils::Depends->new('Scalar::Util::Ops' => 'Sub::Op');

    WriteMakefile(
     $ed->get_makefile_vars,
     ...
    );

=head1 DESCRIPTION

This module provides a C and Perl API for replacing subroutine calls by custom opcodes.
This has two main advantages :

=over 4

=item *

it gets rid of the overhead of a normal subroutine call ;

=item *

there's no symbol table entry defined for the subroutine.

=back

Subroutine calls with and without parenthesis are handled.
Ampersand calls are B<not> replaced, and as such will still allow to call a subroutine with same name defined earlier.
This may or may not be considered as a bug, but it gives the same semantics as Perl keywords, so I believe it's reasonable.

When L<B> and L<B::Deparse> are loaded, they get automatically monkeypatched so that introspecting modules like L<B::Concise> and L<B::Deparse> still produce a valid output.

=cut

use Scalar::Util;

use B::Hooks::EndOfScope;
use Variable::Magic 0.08;

my $placeholder;
BEGIN {
 $placeholder = sub { require Carp; Carp::croak('PLACEHOLDER') };
 _placeholder($placeholder);
}

my $sw = Variable::Magic::wizard(
 data  => sub { +{ guard => 0, pkg => $_[1], map => $_[2] } },
 fetch => sub {
  my ($var, $data, $name) = @_;

  return if $data->{guard};
  local $data->{guard} = 1;

  return unless $data->{map}->{$name};

  my $pkg = $data->{pkg};
  my $fqn = join '::', $pkg, $name;

  {
   local $SIG{__WARN__} = sub {
    CORE::warn(@_) unless $_[0] =~ /^Constant subroutine.*redefined/;
   } if _constant_sub(do { no strict 'refs'; \&$fqn });
   no strict 'refs';
   no warnings 'redefine';
   *$fqn = $placeholder;
  }

  return;
 },
);

sub _tag {
 my ($pkg, $name) = @_;

 my $fqn = join '::', $pkg, $name;

 return {
  old   => _defined_sub($fqn) ? \&$fqn : undef,
  proto => prototype($fqn),
 };
}

sub _map {
 my ($pkg) = @_;

 my $data = do {
  no strict 'refs';
  Variable::Magic::getdata(%{"${pkg}::"}, $sw);
 };

 defined $data ? $data->{map} : undef;
}

sub _cast {
 my ($pkg, $name) = @_;

 my $map = { $name => _tag(@_) };

 {
  no strict 'refs';
  Variable::Magic::cast(%{"${pkg}::"}, $sw, $pkg, $map);
 }

 return $map;
}

sub _dispell {
 my ($pkg) = @_;

 no strict 'refs';
 Variable::Magic::dispell(%{"${pkg}::"}, $sw);
}

=head1 C API

=head2 C<sub_op_config_t>

A typedef'd struct that configures how L<Sub::Op> should handle a given subroutine name.
It has the following members :

=over 4

=item *

C<const char *name>

The name of the subroutine you want to replace.
Allowed to be static.

=item *

C<STRLEN namelen>

C<name>'s length, in bytes.

=item *

C<Perl_ppaddr_t pp>

The pp function that will be called instead of the subroutine.
C<Perl_ppaddr_t> is a typedef'd function pointer defined by perl as :

    typedef OP *(*Perl_ppaddr_t)(pTHX);

=item *

C<sub_op_check_t check>

An optional callback that will be called each time a call to C<name> is replaced.
You can use it to attach extra info to those ops (e.g. with a pointer table) or to perform more optimizations to the optree.
C<sub_op_check_t> is a typedef'd function pointer defined by :

    typedef OP *(*sub_op_check_t)(pTHX_ OP *, void *);

=item *

C<void *ud>

An optional user data passed to the C<check> callback.

=back

=head2 C<void sub_op_register(pTHX_ const sub_op_config_t *c)>

Registers a name and its configuration into L<Sub::Op>.
The caller is responsible for allocating and freeing the C<sub_op_config_t> object.
No pointer to it or to its members is kept.

=head1 PERL API

=head2 C<enable $name, [ $pkg ]>

Enable the replacement with a custom opcode of calls to the C<$name> subroutine of the C<$pkg> package in the current lexical scope.
A pp callback must have been registered for C<$name> by calling the C function C<sub_op_register> in the XS section of your module.

When C<$pkg> is not set, it defaults to the caller package.

=cut

sub enable {
 my $name = shift;

 my $pkg = @_ > 0 ? $_[0] : caller;
 my $map = _map($pkg);

 if (defined $map) {
  $map->{$name} = _tag($pkg, $name);
 } else {
  $map = _cast($pkg, $name);
 }

 my $proto = $map->{$name}->{proto};
 if (defined $proto) {
  no strict 'refs';
  Scalar::Util::set_prototype(\&{"${pkg}::$name"}, undef);
 }

 $^H |= 0x00020000;
 $^H{+(__PACKAGE__)} = 1;

 on_scope_end { disable($name, $pkg) };

 return;
}

=head2 C<disable $name, [ $pkg ]>

Disable the replacement for calls to C<$name> in the package C<$pkg>.

When C<$pkg> is not set, it defaults to the caller package.

=cut

sub disable {
 my $name = shift;

 my $pkg = @_ > 0 ? $_[0] : caller;
 my $map = _map($pkg);

 my $fqn = join '::', $pkg, $name;

 if (defined $map) {
  my $tag = $map->{$name};

  my $old = $tag->{old};
  if (defined $old) {
   no strict 'refs';
   no warnings 'redefine';
   *$fqn = $old;
  }

  my $proto = $tag->{proto};
  if (defined $proto) {
   no strict 'refs';
   Scalar::Util::set_prototype(\&$fqn, $proto);
  }

  delete $map->{$name};
  unless (keys %$map) {
   _dispell($pkg);
  }
 }

 return;
}

sub _inject {
 my ($pkg, $inject) = @_;

 my $stash = do { no strict 'refs'; \%{"${pkg}::"} };

 while (my ($meth, $code) = each %$inject) {
  next if exists $stash->{$meth} and (*{$stash->{$meth}}{CODE} // 0) == $code;
  no strict 'refs';
  *{"${pkg}::$meth"} = $code;
 }
}

sub _defined_sub {
 my ($fqn) = @_;
 my @parts = split /::/, $fqn;
 my $name  = pop @parts;
 my $pkg   = '';
 for (@parts) {
  $pkg .= $_ . '::';
  return 0 unless do { no strict 'refs'; %$pkg };
 }
 return do { no strict 'refs'; defined &{"$pkg$name"} };
}

{
 my $injector;
 BEGIN {
  $injector = Variable::Magic::wizard(
   data  => sub { +{ guard => 0, pkg => $_[1], subs => $_[2] } },
   store => sub {
    my ($stash, $data, $key) = @_;

    return if $data->{guard};
    local $data->{guard} = 1;

    _inject($data->{pkg}, $data->{subs});

    return;
   },
  );
 }

 sub _monkeypatch {
  my %B_OP_inject;

  $B_OP_inject{first} = sub {
   if (defined _custom_name($_[0])) {
    $_[0] = bless $_[0], 'B::UNOP' unless $_[0]->isa('B::UNOP');
    goto $_[0]->can('first') || die 'oops';
   }
   require Carp;
   Carp::confess('Calling B::OP->first for something that isn\'t a custom op');
  };

  $B_OP_inject{can} = sub {
   my ($obj, $meth) = @_;
   if ($meth eq 'first') {
    return undef unless $obj->isa('B::UNOP') or defined _custom_name($obj);
   }
   $obj->SUPER::can($meth);
  };

  if (_defined_sub('B::OP::type')) {
   _inject('B::OP', \%B_OP_inject);
  } else {
   no strict 'refs';
   Variable::Magic::cast %{'B::OP::'}, $injector, 'B::OP', \%B_OP_inject;
  }

  my $B_Deparse_inject = {
   pp_custom => sub {
    my ($self, $op, $cx) = @_;
    my $name = _custom_name($op);
    die 'unhandled custom op' unless defined $name;
    if ($op->flags & do { no strict 'refs'; &{'B::OPf_STACKED'}() }) {
     my $kid = $op->first;
     $kid = $kid->first->sibling; # skip ex-list, pushmark
     my @exprs;
     while (not do { no strict 'refs'; &{'B::Deparse::null'}($kid) }) {
      push @exprs, $self->deparse($kid, 6);
      $kid = $kid->sibling;
     }
     my $args = join(", ", @exprs);
     return "$name($args)";
    } else {
     return $name;
    }
   },
  };

  if (_defined_sub('B::Deparse::pp_entersub')) {
   _inject('B::Deparse', $B_Deparse_inject);
  } else {
   no strict 'refs';
   Variable::Magic::cast %{'B::Deparse::'}, $injector, 'B::Deparse', $B_Deparse_inject;
  }
 }
}

BEGIN { _monkeypatch() }

=head1 EXAMPLES

See the F<t/Sub-Op-LexicalSub> directory that implements a complete example.

=head1 CAVEATS

Preexistent definitions of a sub whose name is handled by L<Sub::Op> are restored at the end of the lexical scope in which the module is used.
But if you define a sub in the scope of action of L<Sub::Op> with a name that is currently being replaced, the new declaration will be obliterated at the scope end.

Function calls without parenthesis inside an C<eval STRING> in the scope of the pragma won't be replaced.
I know a few ways of fixing this, but I've not yet decided on which.

=head1 DEPENDENCIES

L<perl> 5.10.

L<Variable::Magic>, L<B::Hooks::EndOfScope>.

L<ExtUtils::Depends>.

=head1 SEE ALSO

L<subs::auto>.

L<B::Hooks::XSUB::CallAsOp> provides a C API to declare XSUBs that effectively call a specific PP function.
Thus, it allows you to write XSUBs with the PP stack conventions used for implementing perl core keywords.
There's no opcode replacement and no parsing hacks.

L<B::Hooks::OP::Check::EntersubForCV>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-sub-op at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sub-Op>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sub::Op

Tests code coverage report is available at L<http://www.profvince.com/perl/cover/Sub-Op>.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Sub::Op
