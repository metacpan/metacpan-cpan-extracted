use strict;
use warnings;

package Sub::Methodical;

our $VERSION = '0.002';

my %methodical;
my %wrapped;
my %auto_methodical;

use B;
use PadWalker;
use Filter::EOF;
use Sub::Install ();
use Sub::Exporter -setup => {
  exports => [
    MODIFY_CODE_ATTRIBUTES => \&_build_MODIFY,
    AUTOLOAD => \&_build_AUTOLOAD,
  ],
  groups => {
    default => [qw(MODIFY_CODE_ATTRIBUTES)],
    inherit => [qw(AUTOLOAD)],
  },
  collectors => {
    -auto => sub {
      my ($col, $arg) = @_;
      $auto_methodical{$arg->{into}} = 1;
      push @{ $arg->{import_args} }, (
        [ 'MODIFY_CODE_ATTRIBUTES', undef ],
      );
    },
  },
};

sub _build_MODIFY {
  Filter::EOF->on_eof_call(sub {
    for my $pkg (keys %methodical) {
      for my $sub (@{ $methodical{$pkg} }) {
        _wrap($pkg, $sub);
      }
    }
    for my $pkg (keys %auto_methodical) {
      no strict 'refs';
      for my $subname (grep {
        !/^MODIFY_.+_ATTRIBUTES$/ &&
        $_ ne 'AUTOLOAD' &&
        !/^_/ &&
        *{$pkg . '::' . $_}{CODE}
      } keys %{$pkg . '::'}) {
        my $sub = \&{$pkg . '::' . $subname};
        next unless B::svref_2object($sub)->STASH->NAME eq $pkg;
        _wrap($pkg, $sub);
      }
    }
  });
  return sub {
    my ($pkg, $ref, @attrs) = @_;

    if (ref $ref eq 'CODE' and grep { $_ eq 'Methodical' } @attrs) {
      push @{ $methodical{$pkg} ||= [] }, $ref;
      @attrs = grep { $_ ne 'Methodical' } @attrs;
    }
    return @attrs;
  };
}

sub _build_AUTOLOAD {
  return sub {
    our $AUTOLOAD;
    my ($pkg, $method) = $AUTOLOAD =~ /^(.+)::(.+)$/;
    my ($wrap_pkg) = grep { $pkg->isa($_) && $wrapped{$_}{$method} }
      keys %wrapped;
    if ($wrap_pkg) {
      no strict 'refs';
      goto &{$wrap_pkg . '::' . $method};
    }
    require Carp;
    Carp::croak "Undefined subroutine &$AUTOLOAD called";
  };
}

sub _wrap {
  my ($pkg, $sub) = @_;
  require B;
  my $name = B::svref_2object($sub)->GV->NAME;
  (my $as = $name) =~ s/.*:://;
  #warn "wrapping $name ($pkg\::$as)\n";
  $wrapped{$pkg}{$as} = $sub;
  Sub::Install::reinstall_sub({
    into => $pkg,
    as   => $as,
    code => sub {
      if (eval { $_[0]->isa($pkg) }) {
        #warn "calling $name directly: @_\n";
        return $sub->(@_);
      }
      my $pad = PadWalker::peek_my(1);
      my $self = $pad->{'$self'};
      unless ($self) {
        die "can't find \$self!";
      }
      unless (eval { $$self->isa($pkg) }) {
        require Carp;
        Carp::croak sprintf 
          "Methodical '%s' called with incorrect invocant '%s' (wanted '%s')",
          $as, $$self, $pkg;
      }
      #warn "calling $name with self = $$self, @_\n";
      $$self->$as(@_);
    },
  });
}

1;
__END__

=head1 NAME

Sub::Methodical - call methods as functions

=head1 VERSION

Version 0.002

=head1 SYNOPSIS

  package My::Module;
  use Sub::Methodical;

  sub foo :Methodical { ... do stuff ... }

  sub bar {
    my ($self, $arg) = @_;
    
    # this secretly grabs the current scope's $self
    foo($arg, @more_args);

    # ... this is identical
    $self->foo($arg, @more_args);
  }

=head1 DESCRIPTION

Don't you get tired of typing C<< $self-> >> all the time when you're calling
your methods?

Now you don't have to anymore.  Any function you give the C<:Methodical>
attribute (or, with the C<-auto> import argument, any function that doesn't
start with '_') is automatically called as a method whenever you call it as a
function, taking its invocant (C<$self>) from the calling scope.

=head1 USE

=head2 The C<:Methodical> Attribute

This attribute marks a single function as a Methodical method.  Once marked,
these two invocations are identical:

  sub foo :Methodical { ... }

  sub bar {
    my ($self) = @_;
    foo();
    $self->foo;
  }

There must be a lexical variable named C<$self> in the function that calls a
Methodical method, and it must be blessed into a class that C<isa> the package
that the method was originally defined in.

Methods called as functions still behave like normal methods as far as
subclassing and overriding goes.  That is, given the example above, if a
subclass contained this code,

  sub foo { ... something else ... }

that subclass' C<bar> method would continue to work, and would call the correct
(subclass) C<foo> method, even when it was called as C<foo()> instead of
C<< $self->foo >>.

=head2 C<-auto>

  use Sub::Methodical -auto;

This argument tells Sub::Methodical to look for all functions defined in the
current package (whose names do not begin with '_') and treat them as though
they had the C<:Methodical> attribute.

=head2 C<-inherit>

  use Sub::Methodical -inherit;

This argument installs an C<AUTOLOAD> function that will perform redispatch to
inherited C<:Methodical> methods.

In other words, if you want to write a subclass that continues to call
(inherited) methods as functions, you need to use this.

=head1 EXPORTS

=head2 MODIFY_CODE_ATTRIBUTES

This is exported to grab the C<:Methodical> attribute.

=head2 AUTOLOAD

This is exported by the C<-inherit> import argument.

=head1 AUTHOR

Hans Dieter Pearcey, C<< <hdp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sub-methodical at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sub-Methodical>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sub::Methodical


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sub-Methodical>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sub-Methodical>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Sub-Methodical>

=item * Search CPAN

L<http://search.cpan.org/dist/Sub-Methodical>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Ricardo SIGNES for having this idea.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Hans Dieter Pearcey, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Sub::Methodical
