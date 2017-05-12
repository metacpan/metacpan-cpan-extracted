package Perl::Critic::Policy::Modules::RequireExplicitInclusion;

use strict;
use warnings;
use base 'Perl::Critic::Policy';

use Perl::Critic::Utils qw(
    :characters
    :severities
    &hashify
    &is_class_name
    &is_function_call
    &is_perl_builtin
    &is_qualified_name
    &policy_short_name
);

use Perl::Critic::StricterSubs::Utils qw(
    &get_package_names_from_include_statements
    &get_package_names_from_package_statements
);

#-----------------------------------------------------------------------------

our $VERSION = 0.05;

my $expl =
    'Without importing a package, it is unlikely that references to things inside it even exist.';

#-----------------------------------------------------------------------------

sub supported_parameters { return }
sub default_severity     { return $SEVERITY_HIGH          }
sub default_themes       { return qw( strictersubs bugs ) }
sub applies_to           { return 'PPI::Document'         }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, undef, $doc) = @_;

    my @declared_packages = get_package_names_from_package_statements($doc);

    if ( @declared_packages > 1 ) {
        my $fname = $doc->filename() || 'unknown';
        my $pname = policy_short_name(__PACKAGE__);
        warn qq{$pname: Cannot cope with mutiple packages in file "$fname"\n};
        return;
    }

    my @included_packages = get_package_names_from_include_statements($doc);
    my @builtin_packages = ( qw(main UNIVERSAL CORE CORE::GLOBAL), $EMPTY );

    my %all_packages =
        hashify( @declared_packages, @included_packages, @builtin_packages );

    my @violations = (
        $self->_find_subroutine_call_violations( $doc, \%all_packages ),
        $self->_find_class_method_call_violations( $doc, \%all_packages ),
        $self->_find_symbol_violations( $doc, \%all_packages ),
    );

    return @violations;
}

#-----------------------------------------------------------------------------

sub _find_qualified_subroutine_calls {
    my $doc = shift;

    my $calls =
        $doc->find(
            sub {
                my (undef, $elem) = @_;

                return
                         $elem->isa('PPI::Token::Word')
                     &&  is_qualified_name( $elem->content() )
                     &&  is_function_call( $elem );

            }
        );

    return @{$calls} if $calls;
    return;
}

#-----------------------------------------------------------------------------

sub _find_class_method_calls {
    my $doc = shift;

    my $calls =
        $doc->find(
            sub {
                my (undef, $elem) = @_;

                return
                         $elem->isa('PPI::Token::Word')
                     &&  is_class_name( $elem )
                     && !is_perl_builtin( $elem )
                     && '__PACKAGE__' ne $elem->content();  # RT 43314, 44609
                     # From a design standpoint we should filter later, but
                     # the violation code is generic. The patch included with
                     # 44609, or adding '__PACKAGE__ to @builtin_packages,
                     # would have also allowed, willy-nilly,
                     # __PACKAGE__::foo() or $__PACKAGE__::foo, neither of
                     # which is correct. So I just hid __PACKAGE__->foo() from
                     # the violation logic. Mea culpa! Tom Wyant
            }
        );

    return @{$calls} if $calls;
    return;
}

#-----------------------------------------------------------------------------

sub _find_qualified_symbols {
    my $doc = shift;

    my $symbols =
        $doc->find(
            sub {
                my (undef, $elem) = @_;

                return
                        $elem->isa('PPI::Token::Symbol')
                    &&  is_qualified_name( $elem->canonical() );
            }
        );

    return @{$symbols} if $symbols;
    return;
}

#-----------------------------------------------------------------------------

sub _extract_package_from_class_method_call {

    # Class method calls look like "Foo::Bar->baz()"
    # So the package name will be the entire word,
    # which should be everything to the left of "->"

    my $word = shift;
    return $word;
}

#-----------------------------------------------------------------------------

sub _extract_package_from_subroutine_call {

    # Subroutine calls look like "Foo::Bar::baz()"
    # So the package name will be everything up
    # to (but not including) the last "::".

    my $word = shift;
    if ($word->content() =~ m/\A ( .* ) :: [^:]+ \z/xms) {
        return $1;
    }

    return;
}

#-----------------------------------------------------------------------------

sub _extract_package_from_symbol {

    # Qualified symbols look like "$Foo::Bar::baz"
    # So the package name will be everything between
    # the sigil and the last "::".

    my $symbol = shift;
    if ($symbol->canonical() =~ m/\A [\$*@%&] ( .* ) :: [^:]+ \z/xms) {
        return $1;
    }

    return;
}

#-----------------------------------------------------------------------------

sub _find_violations {

    my ($self, $doc, $included_packages, $finder, $package_extractor) = @_;
    my @violations = ();

    for my $call ( $finder->( $doc ) ) {
        my $package = $package_extractor->( $call );
        next if exists $included_packages->{ $package };

        my $desc = qq{Use of "$call" without including "$package"};
        push @violations, $self->violation( $desc, $expl, $call );
    }

    return @violations;
}

#-----------------------------------------------------------------------------

sub _find_subroutine_call_violations {
    my ($self, $doc, $packages) = @_;
    my $finder    = \&_find_qualified_subroutine_calls;
    my $extractor = \&_extract_package_from_subroutine_call;
    return $self->_find_violations( $doc, $packages, $finder, $extractor );
}

#-----------------------------------------------------------------------------

sub _find_class_method_call_violations {
    my ($self, $doc, $packages) = @_;
    my $finder    = \&_find_class_method_calls;
    my $extractor = \&_extract_package_from_class_method_call;
    return $self->_find_violations( $doc, $packages, $finder, $extractor );
}

#-----------------------------------------------------------------------------

sub _find_symbol_violations {
    my ($self, $doc, $packages) = @_;
    my $finder    = \&_find_qualified_symbols;
    my $extractor = \&_extract_package_from_symbol;
    return $self->_find_violations( $doc, $packages, $finder, $extractor );
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::Modules::RequireExplicitInclusion

=head1 AFFILIATION

This policy is part of L<Perl::Critic::StricterSubs|Perl::Critic::StricterSubs>.

=head1 DESCRIPTION

Checks that, if a reference is made to something inside of another
package, that a module with the name of the package has been C<use>d
or C<require>d.

Without importing a package, it is unlikely that references to things
inside it even exist.  Due to the flexible nature of Perl, C<use
strict;> can not complain about references to things outside of the
current package and thus won't detect this situation.

=head2 Explanation

As an example, assume there is a third-party C<Foo> module with a
C<bar()> subroutine.  You then create a module of your own.

  package My::Module;

  ...
  $x = Foo::bar($y);
  ...

You don't have to worry about whether C<Foo> exports C<bar()> or not
because you're fully qualifying the name.  Or do you?  You then create
a program F<plugh> that uses your module that also needs to use C<Foo>
directly.

  #!/usr/bin/perl
  ...
  use Foo;
  use My::Module qw{ &frob };
  ...

This works fine.  At some later time, you use your module in a
F<xyzzy> program.

  #!/usr/bin/perl
  ...
  use My::Module qw{ &frob };
  ...

You now get compilation problems in the previously robust
C<My::Module>.  What is going on is that F<plugh> loaded the C<Foo>
module prior to C<My::Module>, which means that, when C<My::Module>
refers to C<Foo::bar()>, the subroutine actually exists, even though
C<My::Module> didn't actually C<use Foo;>.  When F<xyzzy> attempted to
use C<My::Module> without doing a C<use Foo;>, C<My::Module> fails
because C<Foo::bar()> doesn't exist.

=head2 Enforcement

Assuming that there are no C<use> or C<require> statements within the
current scope:

  @foo       = localtime;                        #ok
  @Bar::foo  = localtime                         #not ok
  @::foo     = localtime;                        #ok
  @main::foo = localtime;                        #ok

  baz(23, 'something', $x);                      #ok
  Bar::baz(23, 'something', $x);                 #not ok
  ::baz(23, 'something', $x);                    #ok
  main::baz(23, 'something', $x);                #ok

Only modules that are symbolically referenced by a C<use> or
C<require> are considered valid.  Loading a file does not count.

  use Foo;
  require Bar;
  require 'Baz.pm';

  $Foo:x = 57;                                   #ok
  $Bar:x = 57;                                   #ok
  $Baz:x = 57;                                   #not ok

Qualifying a name with the name of the current package is valid.

  package Xyzzy;

  my $ducks;

  sub increment_duck_count {
      $Xyzzy::ducks++;                           #ok
  }

A C<use> or C<require> statement is taken into account only when it is
in the scope of a file or a C<BEGIN>, C<CHECK>, or C<INIT> block.

  use File::Scope;

  BEGIN {
      require Begin::Block;
  }

  CHECK {
      require Check::Block;
  }

  INIT {
      require Init::Block;
  }

  END {
      require End::Block;
  }

  push @File::Scope::numbers, 52, 93, 25;        #ok
  push @Begin::Block::numbers, 52, 93, 25;       #ok
  push @Check::Block::numbers, 52, 93, 25;       #ok
  push @Init::Block::numbers, 52, 93, 25;        #ok
  push @End::Block::numbers, 52, 93, 25;         #not ok

  {
      require Lexical::Block;

      push @Lexical::Block::numbers, 52, 93, 25; #not ok
  }


=head1 CAVEATS

1.) It is assumed that the code for a package exists in a module of
the same name.


2.) It is assumed that a module will contain no more than one package.
This Policy will not complain about any problems in a module
containing multiple C<package> statements.  For example, a module
containing

  package Foo;

  sub frob {
      $Xyzzy::factor = rand 100;
  }

  package Bar;

  sub frob {
      $Plugh::factor = rand 1000;
  }

will not result in any violations.  There really shouldn't be more
than one package within a module anyway.


3.) No checks of whether the name actually exists in the referenced
package are done.  E.g., if a call to a C<Foo::process_widgets()>
subroutine is made, this Policy does not check that a
C<process_widgets()> subroutine actually exists in the C<Foo> package.


=head1 CONFIGURATION

None.

=head1 DIAGNOSTICS

=over

=item C<Modules::RequireExplicitInclusion: Cannot cope with mutiple packages in file>

This warning happens when the file under analysis contains multiple packages,
which is not currently supported.  This Policy will simply ignore any file
with multiple packages.

L<Perl::Critic|Perl::Critic> advises putting multiple packages in one file, and has
additional Policies to help enforce that.

=back

=head1 SEE ALSO

L<Perl::Critic::Policy::Modules::ProhibitMultiplePackages|Perl::Critic::Policy::Modules::ProhibitMultiplePackages>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2007 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  The full text of this license can be found in
the LICENSE file included with this module.

=cut


##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
