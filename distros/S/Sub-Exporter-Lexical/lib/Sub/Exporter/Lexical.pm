use v5.12.0;
use warnings;
package Sub::Exporter::Lexical 1.000;
# ABSTRACT: to export lexically-available subs with Sub::Exporter

# I know about if.pm!  But we can't use it here because "use Lexical::Sub" will
# call import and then it dies "does no default importation".  And then what
# about this *utterly ridiculous* require?  Well, that's to avoid the prereq
# scanner picking up Lexical::Sub, which I do not want to just RemovePrereqs
# on, because that runs after the thing that adds optional prereqs.
BEGIN {
  if ($] <  5.037002) { eval "require Lexical::Sub;" || die $@ }
  else                { require builtin;      }
}

use Sub::Exporter -setup => {
  exports => [ qw(lexical_installer) ],
};

#pod =head1 SYNOPSIS
#pod
#pod In an exporting library:
#pod
#pod   package Some::Toolkit;
#pod
#pod   use Sub::Exporter -setup => {
#pod     exports   => [ qw(foo bar baz) ],
#pod   };
#pod
#pod   sub foo { ... }
#pod   sub bar { ... }
#pod   sub baz { ... }
#pod
#pod In an importing library:
#pod
#pod   package Vehicle::Autobot;
#pod
#pod   use Sub::Exporter::Lexical lexical_installer => { -as => 'lex' };
#pod
#pod   ...;
#pod
#pod   {
#pod     use Some:::Toolkit { installer => lex }, qw(foo bar);
#pod
#pod     foo(1,2,3);
#pod     my $x = bar;
#pod
#pod     ...
#pod   };
#pod
#pod   # ... and here, foo and bar are no longer available ...
#pod
#pod =head1 DESCRIPTION
#pod
#pod Sub::Exporter::Lexical provides an alternate installer for
#pod L<Sub::Exporter|Sub::Exporter>.  Installers are documented in Sub::Exporter's
#pod documentation; all you need to know is that by using Sub::Exporter::Lexical's
#pod installer, you can import routines into a lexical scope that will be cleaned up
#pod when that scope ends.
#pod
#pod There are two places it makes sense to use the lexical installer: when
#pod configuring Sub::Exporter in your exporting package or when importing from a
#pod package that uses Sub::Exporter.  For the first case, do something like this:
#pod
#pod   package Some::Toolkit;
#pod   use Sub::Exporter::Lexical ();
#pod   use Sub::Exporter -setup => {
#pod     exports   => [ ... ],
#pod     installer => Sub::Exporter::Lexical::lexical_installer,
#pod   };
#pod
#pod For the second:
#pod
#pod   package My::Library;
#pod
#pod   use Sub::Exporter::Lexical ();
#pod   use Some::Toolkit
#pod     { installer => Sub::Exporter::Lexical::lexical_installer },
#pod     qw(foo bar baz);
#pod
#pod =head1 EXPORTS
#pod
#pod Sub::Exporter::Lexical offers only one routine for export, and it may also
#pod be called by its full package name:
#pod
#pod =head2 lexical_installer
#pod
#pod This routine returns an installer suitable for use as the C<installer> argument
#pod to Sub::Exporter.  It installs all requested routines as usual, but marks them
#pod to be removed from the target package as soon as the block in which it was
#pod called is complete.
#pod
#pod It does not affect the behavior of routines exported into scalar references.
#pod
#pod B<More importantly>, it does not affect scopes in which it is invoked at
#pod runtime, rather than compile time.  B<This is important!>  It means that this
#pod works:
#pod
#pod   {
#pod     use Some::Toolkit { installer => lexical_installer }, qw(foo);
#pod     foo(1,2,3);
#pod   }
#pod
#pod   foo(); # this dies
#pod
#pod ...but this does not...
#pod
#pod   {
#pod     require Some::Toolkit;
#pod     Some::Toolkit->import({ installer => lexical_installer }, qw(foo));
#pod     foo(1,2,3);
#pod   }
#pod
#pod   foo(); # this does not die, even though you might expect it to
#pod
#pod Finally, you can't supply a C<< -as => \$var >> install destination yet.
#pod
#pod =cut

sub lexical_installer {
  sub {
    my ($arg, $to_export) = @_;

    my $into = $arg->{into};

    my @names =
      map { $to_export->[ $_ ] }
      grep { not($_ % 2) and ! ref $to_export->[$_] } (0 .. $#$to_export);

    my @pairs = @$to_export;
    while (my ($name, $code) = splice @pairs, 0, 2) {
      if (ref $name) {
        # We could implement this easily, but haven't. -- rjbs, 2013-11-24
        Carp::cluck("can't import to variable with lexical installer (yet)");
        next;
      }

      if ($] >= 5.037002) { builtin::export_lexically($name, $code); }
      else                { Lexical::Sub->import($name, $code); }
    }
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sub::Exporter::Lexical - to export lexically-available subs with Sub::Exporter

=head1 VERSION

version 1.000

=head1 SYNOPSIS

In an exporting library:

  package Some::Toolkit;

  use Sub::Exporter -setup => {
    exports   => [ qw(foo bar baz) ],
  };

  sub foo { ... }
  sub bar { ... }
  sub baz { ... }

In an importing library:

  package Vehicle::Autobot;

  use Sub::Exporter::Lexical lexical_installer => { -as => 'lex' };

  ...;

  {
    use Some:::Toolkit { installer => lex }, qw(foo bar);

    foo(1,2,3);
    my $x = bar;

    ...
  };

  # ... and here, foo and bar are no longer available ...

=head1 DESCRIPTION

Sub::Exporter::Lexical provides an alternate installer for
L<Sub::Exporter|Sub::Exporter>.  Installers are documented in Sub::Exporter's
documentation; all you need to know is that by using Sub::Exporter::Lexical's
installer, you can import routines into a lexical scope that will be cleaned up
when that scope ends.

There are two places it makes sense to use the lexical installer: when
configuring Sub::Exporter in your exporting package or when importing from a
package that uses Sub::Exporter.  For the first case, do something like this:

  package Some::Toolkit;
  use Sub::Exporter::Lexical ();
  use Sub::Exporter -setup => {
    exports   => [ ... ],
    installer => Sub::Exporter::Lexical::lexical_installer,
  };

For the second:

  package My::Library;

  use Sub::Exporter::Lexical ();
  use Some::Toolkit
    { installer => Sub::Exporter::Lexical::lexical_installer },
    qw(foo bar baz);

=head1 PERL VERSION

This module is shipped with no promise about what version of perl it will
require in the future.  In practice, this tends to mean "you need a perl from
the last three years," but you can't rely on that.  If a new version of perl
ship, this software B<may> begin to require it for any reason, and there is no
promise that patches will be accepted to lower the minimum required perl.

=head1 EXPORTS

Sub::Exporter::Lexical offers only one routine for export, and it may also
be called by its full package name:

=head2 lexical_installer

This routine returns an installer suitable for use as the C<installer> argument
to Sub::Exporter.  It installs all requested routines as usual, but marks them
to be removed from the target package as soon as the block in which it was
called is complete.

It does not affect the behavior of routines exported into scalar references.

B<More importantly>, it does not affect scopes in which it is invoked at
runtime, rather than compile time.  B<This is important!>  It means that this
works:

  {
    use Some::Toolkit { installer => lexical_installer }, qw(foo);
    foo(1,2,3);
  }

  foo(); # this dies

...but this does not...

  {
    require Some::Toolkit;
    Some::Toolkit->import({ installer => lexical_installer }, qw(foo));
    foo(1,2,3);
  }

  foo(); # this does not die, even though you might expect it to

Finally, you can't supply a C<< -as => \$var >> install destination yet.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords Hans Dieter Pearcey Ricardo Signes

=over 4

=item *

Hans Dieter Pearcey <hdp@weftsoar.net>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
