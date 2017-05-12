#!/usr/bin/perl -c

package Symbol::Util;

=head1 NAME

Symbol::Util - Additional utils for Perl symbols manipulation

=head1 SYNOPSIS

  use Symbol::Util ':all';

  my $caller = caller;
  *{ fetch_glob("${caller}::foo") } = sub { "this is foo" };
  my $coderef = fetch_glob("${caller}::bar", "CODE");
  sub baz { 42; }
  export_glob($caller, "baz");

  print join "\n", keys %{ stash("main") };

  delete_glob("${caller}::foo", "CODE");

  use constant PI => 3.14159265;
  delete_sub "PI";   # remove constant from public API

  require YAML;
  export_package(__PACKAGE__, "YAML", "Dump");   # import YAML::Dump
  unexport_package(__PACKAGE, "YAML");   # remove imported symbols

  no Symbol::Util;   # clean all symbols imported from Symbol::Util

=head1 DESCRIPTION

This module provides a set of additional functions useful for Perl
symbols manipulation.

All Perl symbols from the same package are organized as a stash.  Each symbol
(glob) contains one or more of following slots: C<SCALAR>, C<ARRAY>, C<HASH>,
C<CODE>, C<IO>, C<FORMAT>.  These slots are also accessible as standard
variables or bare words.

The Perl symbols table is directly accessible with typeglob prefix but it can
be difficult to read and problematic if strict mode is used.  Also the access
to stash, glob and one of its slot have different syntax notation.

C<stash> and C<fetch_glob> functions gets stash or glob without need to use
C<no strict 'refs'>.

C<delete_glob> function allows to delete specific slot of
symbol name without deleting others.

C<delete_sub> removes the symbol from class API.  This symbol won't be
available as an object method.

C<export_glob> function exports a glob to the target package.

C<export_package> works like L<Exporter> module and allows to export symbols
from one package to other.

C<unexport_package> allows to delete previously exported symbols.

=for readme stop

=cut


use 5.006;

use strict;
use warnings;

our $VERSION = '0.0203';


# Exported symbols $EXPORTED{$target}{$package}{$name}{$slot} = 1
my %EXPORTED;


=head1 USAGE

By default, the class does not export its symbols.

=over

=item use Symbol::Util ':all';

Imports all available symbols.

=cut

sub import {
    my ($package, @names) = @_;

    my $caller = caller();

    my @EXPORT_OK = grep { /^[a-z]/ && !/^(?:import|unimport)$/ } keys %{ stash(__PACKAGE__) };
    my %EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

    return export_package($caller, $package, {
        OK => [ @EXPORT_OK ],
        TAGS => { %EXPORT_TAGS },
    }, @names);
};


=item no Symbol::Util;

Deletes all imported symbols from caller name space.

=back

=cut

sub unimport {
    my ($package) = @_;

    my $caller = caller();

    return unexport_package($caller, $package);
};


=head1 FUNCTIONS

=over

=item stash( I<name> : Str ) : HashRef

Returns a reference to the stash for the specified name.  If the stash does
not already exist then it will be created.  The name of the stash does not
include the C<::> at the end.  It is safe to use this function with
C<use strict 'refs'>.

  print join "\n", keys %{ stash("main") };

=cut

sub stash ($) {
    no strict 'refs';
    return *{ $_[0] . '::' }{HASH};
};


=item fetch_glob( I<name> : Str ) : GlobRef

=item fetch_glob( I<name> : Str, I<slot> : Str ) : Ref

Returns a reference to the glob for the specified symbol name.  If the symbol
does not already exist then it will be created.  If the symbol name is
unqualified then it will be looked up in the calling package.  It is safe to
use this function with C<use strict 'refs'>.

If the I<slot> argument is defined and this slot contains defined value,
reference to this value is returned.  The I<slot> argument can be one of the
following strings: C<SCALAR>, C<ARRAY>, C<HASH>, C<CODE>, C<IO>, C<FORMAT>).

  my $caller = caller;
  *{ fetch_glob("${caller}::foo") } = sub { "this is foo" };
  my $coderef = fetch_glob("${caller}::foo", "CODE");

=cut

sub fetch_glob ($;$) {
    my ($name, $slot) = @_;

    $name = caller() . "::$name" unless $name =~ /::/;

    no strict 'refs';

    if (defined $slot) {
        return if $slot eq 'SCALAR' and not defined ${ *{ $name }{SCALAR} };
        return *{ $name }{$slot};
    };

    return \*{ $name };
};


=item list_glob_slots( I<name> ) : Maybe[Array]

Returns a list of slot names for glob with specified I<name> which contain
defined value.  If the glob is undefined, the C<undef> value is returned.  If
the glob is defined and has no defined slots, the empty list is returned.

The C<SCALAR> slot is used only if it contains defined value.

  my $foo = 42;
  my @foo = (1, 2);
  sub foo { 1; };
  print join ",", list_glob_slots("foo");   # SCALAR,ARRAY,CODE

=cut

sub list_glob_slots ($) {
    my ($name) = @_;

    $name = caller() . "::$name" unless $name =~ /::/;

    no strict 'refs';

    return if not defined *{ $name };

    my @slots;

    push @slots, 'SCALAR'
        if defined *{ $name }{SCALAR} and defined ${ *{ $name }{SCALAR} };

    foreach my $slot (qw( ARRAY HASH CODE IO )) {
        push @slots, $slot if defined *{ $name }{$slot};
    };

    return @slots;
};


=item export_glob( I<target>, I<name> : Str ) : GlobRef

=item export_glob( I<target>, I<name> : Str, I<slots> : Array ) : Ref

Exports a glob I<name> to the I<target> package.  Optionally exports only
specified slots of the glob.

  sub my_function { ... };
  sub import {
      my $caller = caller;
      export_glob($caller, "my_function");
  }

=cut

sub export_glob ($$;@) {
    my ($target, $name, @slots) = @_;

    $name = caller() . "::$name" unless $name =~ /::/;
    (my $subname = $name) =~ s/^(.*):://;

    @slots = qw( SCALAR ARRAY HASH CODE IO ) unless @slots;

    no strict 'refs';

    return if not defined *{ $name };

    my $targetname = "${target}::$subname";

    my $defined;
    foreach my $slot (@slots) {
        next if $slot eq 'SCALAR' and not defined ${ *{ $name }{$slot} };
        next if not defined *{ $name }{$slot};
        *{ $targetname } = *{ $name }{$slot};
        $defined = 1;
    };

    return $defined ? \*{ $targetname } : undef;
};


=item delete_glob( I<name> : Str, I<slots> : Array[Str] ) : Maybe[GlobRef]

Deletes the specified symbol name if I<slots> are not specified, or deletes
the specified slots in the symbol name (could be one or more of the following
strings: C<SCALAR>, C<ARRAY>, C<HASH>, C<CODE>, C<IO>, C<FORMAT>).

Function returns the glob reference if there are any slots defined.

  our $FOO = 1;
  sub FOO { "bar" };

  delete_glob("FOO", "CODE");

  print $FOO;  # prints "1"
  FOO();       # error: sub not found

=cut

sub delete_glob ($;@) {
    my ($name, @slots) = @_;

    $name = caller() . "::$name" unless $name =~ /::/;
    $name =~ /^(.*)::([^:]*)/;
    my ($package, $subname) = ($1, $2);  ## no critic qw(ProhibitCaptureWithoutTest)

    my $stash = stash($package);

    if (@slots) {
        my %delete = map { $_ => 1 } @slots;
        my %backup;

        foreach my $slot (list_glob_slots($name)) {
            $backup{$slot} = fetch_glob($name, $slot)
                if not $delete{$slot};
        };

        undef $stash->{$subname};

        foreach my $slot (keys %backup) {
            *{ fetch_glob($name) } = $backup{$slot};
        };

        return fetch_glob($name);
    }
    else {
        # delete all slots
        undef $stash->{$subname};
    };

    return;
};


=item delete_sub( I<name> : Str ) : Maybe[GlobRef]

Deletes (or hides) the specified subroutine name from class API.  It means
that this subroutine will be no longer available as a class method.  The
purpose of this function is the same as L<namespace::clean> pragma has: it
cleans a package's namespace from unwanted subroutines.  Function doesn't
delete other slots than C<CODE> slot of the glob.

Function returns the glob reference if there are any other slots still defined
than <CODE> slot.

  package My::Class;

  use constant PI => 3.14159265;

  use Symbol::Util 'delete_sub';
  delete_sub "PI";   # remove constant from public API
  no Symbol::Util;   # remove also Symbol::Util::* from public API

  sub area {
      my ($self, $r) = @_;
      return PI * $r ** 2;
  }

  print My::Class->area(2);   # prints 12.5663706
  print My::Class->PI;        # Can't locate object method

=cut

sub delete_sub ($) {
    my ($name) = @_;

    $name = caller() . "::$name" unless $name =~ /::/;
    $name =~ /^(.*)::([^:]*)/;
    my ($package, $subname) = ($1, $2);  ## no critic qw(ProhibitCaptureWithoutTest)

    return if not defined fetch_glob($name, 'CODE');

    my $stash = stash($package);

    my %backup;

    foreach my $slot (list_glob_slots($name)) {
        $backup{$slot} = fetch_glob($name, $slot);
    };

    *{ fetch_glob($name) } = $backup{CODE};
    delete $backup{CODE};

    delete $stash->{$subname};

    foreach my $slot (keys %backup) {
        *{ fetch_glob($name) } = $backup{$slot};
    };

    return %backup ? fetch_glob($name) : undef;
};


=item export_package( I<target> : Str, I<package> : Str, I<names> : Array[Str] ) : Bool

=item export_package( I<target> : Str, I<package> : Str, I<spec> : HashRef, I<names> : Array[Str] ) : Bool

Exports symbols from I<package> to I<target>.  If I<spec> is defined as hash
reference, it contains the specification for exporter.  Otherwise the standard
global variables of I<package> are used (C<@EXPORT>, C<@EXPORT_OK> and
C<%EXPORT_TAGS>) to build the specification for exporter.  The optional list
of I<names> defines an import list.

The I<spec> is a reference to hash with following keys:

=over

=item EXPORT

Contains the list of default imports.  It is the same as C<@EXPORT> variable.

=item OK

Contains the list of allowed imports.  It is the same as C<@EXPORT_OK>
variable.

=item TAGS

Contains the hash with tags.  It is the same as C<%EXPORT_TAGS> variable.

=back

See L<Exporter> documentation for explanation of these global variables and
list of I<names>.

The C<export_package> function can export symbols from an external package to
an external package.  This function can also be used as a helper in C<import>
method.

  package My::Package;
  sub myfunc { };
  sub import {
      my ($package, @names) = @_;
      my $caller = caller();
      return export_package($caller, $package, {
          OK => [ qw( myfunc ) ],
      }, @names);
  };

All exported symbols are tracked and later can be removed with
C<unexport_package> function.

The function returns true value if there were no errors.

=cut

sub export_package ($$@) {
    my ($target, $package, @args) = @_;

    my $spec = ref $args[0] eq 'HASH' ? shift @args : {
        EXPORT => fetch_glob("${package}::EXPORT", "ARRAY"),
        OK     => fetch_glob("${package}::EXPORT_OK", "ARRAY"),
        TAGS   => fetch_glob("${package}::EXPORT_TAGS", "HASH"),
    };

    my @names = @args;

    # support: use Package 3.14 qw();
    return 1 if @names == 1 and $names[0] eq '';

    # default exports on empty list or if first element is negation
    unshift @names, ":DEFAULT" if not @names or @names and $names[0] =~ /^!/;

    my @export = ref ($spec->{EXPORT} || '') eq 'ARRAY' ? @{ $spec->{EXPORT} } : ();
    my @export_ok = ref ($spec->{OK} || '') eq 'ARRAY' ? @{ $spec->{OK} } : ();
    my %export_tags = ref ($spec->{TAGS} || '') eq 'HASH' ? %{ $spec->{TAGS} } : ();

    my %export = map { $_ => 1 } @export;
    my %export_ok = map { $_ => 1 } @export_ok;

    my %names;

    while (my $name = shift @names) {
        if ($name =~ m{^/(.*)/$}) {
            my $pattern = $1;
            $names{$_} = 1 foreach grep { /$pattern/ } (@export, @export_ok);
        }
        elsif ($name =~ m{^!/(.*)/$}) {
            my $pattern = $1;
            %names = map { $_ => 1 } grep { ! /$pattern/ } keys %names;
        }
        elsif ($name =~ /^(!?):DEFAULT$/) {
            my $neg = $1;
            unshift @names, map { "${neg}$_" } @export;
        }
        elsif ($name =~ /^(!?):(.*)$/) {
            my ($neg, $tag) = ($1, $2);
            if (defined $export_tags{$tag}) {
                unshift @names, map { "${neg}$_" } @{ $export_tags{$tag} };
            }
            else {
                require Carp;
                Carp::croak("$name is not a tag of the $package module");
            };
        }
        elsif ($name =~ /^!(.*)$/) {
            $name = $1;
            delete $names{$name};
        }
        elsif (defined $export_ok{$name} or defined $export{$name}) {
            $names{$name} = 1;
        }
        else {
            require Carp;
            Carp::croak("$name is not exported by the $package module");
        };
    };

    foreach my $name (keys %names) {
        my $type = '';
        if ($name =~ s/^(\W)//) {
            $type = $1;
        };

        my @slots;
        if ($type eq '&' or $type eq '') {
            push @slots, 'CODE';
        }
        elsif ($type eq '$') {
            push @slots, 'SCALAR';
        }
        elsif ($type eq '@') {
            push @slots, 'ARRAY';
        }
        elsif ($type eq '%') {
            push @slots, 'HASH';
        }
        elsif ($type eq '*') {
            push @slots, 'IO';
        }
        else {
            require Carp;
            Carp::croak("Can't export symbol $type$name");
        };
        foreach my $slot (@slots) {
            if (defined export_glob($target, "${package}::$name", $slot)) {
                $EXPORTED{$target}{$package}{$name}{$slot} = 1;
            };
        };
    };

    return 1;
};


=item unexport_package( I<target> : Str, I<package> : Str ) : Bool

Deletes symbols previously exported from I<package> to I<target> with
C<export_package> function.  If the symbol was C<CODE> reference it is deleted
with C<delete_sub> function.  Otherwise it is deleted with C<delete_glob>
function with proper slot as an argument.

Deleting with C<delete_sub> function means that this symbol is not available
via class API as an object method.

  require YAML;
  export_package(__PACKAGE__, "YAML", "Dump");
  unexport_package(__PACKAGE__, "YAML");
  print Dump @INC;     # OK
  __PACKAGE__->Dump;   # Can't locate object method

This function can be used as a helper in C<unimport> method.

  package My::Package;
  sub unimport {
      my ($package, @names) = @_;
      my $caller = caller();
      return unexport_package($caller, $package);
  };

  package main;
  use My::Package qw(something);
  no My::Package;
  main->something;   # Can't locate object method

The function returns true value if there were no errors.

=back

=cut

sub unexport_package ($$) {
    my ($target, $package) = @_;

    if (defined $EXPORTED{$target}{$package}) {
        foreach my $name (keys %{ $EXPORTED{$target}{$package} }) {
            # CODE slot have to be the last one
            foreach my $slot ( qw( SCALAR ARRAY HASH IO CODE ) ) {
                next unless exists $EXPORTED{$target}{$package}{$name}{$slot};
                if ($slot eq 'CODE') {
                    delete_sub("${target}::$name");
                }
                else {
                    delete_glob("${target}::$name", $slot);
                };
            };
        };
        delete $EXPORTED{$target}{$package};
    };

    return 1;
};


1;


=begin umlwiki

= Class Diagram =

[                      <<utility>>
                       Symbol::Util
 ------------------------------------------------------------------
 ------------------------------------------------------------------
 stash( name : Str ) : HashRef
 fetch_glob( name : Str ) : GlobRef
 fetch_glob( name : Str, slot : Str ) : Ref
 list_glob_slots( name : Str ) : Array
 export_glob( package : Str, name : Str ) : GlobRef
 export_glob( package : Str, name : Str, slots : Array[Str] ) : GlobRef
 delete_glob( name : Str, slots : Array[Str] ) : GlobRef
 delete_sub( name : Str ) : GlobRef
 export_package( target : Str, package : Str, names : Array[Str] ) : Bool
 export_package( target : Str, package : Str, spec : HashRef, names : Array[Str] ) : Bool
 unexport_package( target : Str, package : Str ) : Bool
                                                                   ]

=end umlwiki

=head1 SEE ALSO

L<Symbol>, L<Sub::Delete>, L<namespace::clean>, L<Exporter>.

=head1 BUGS

C<fetch_glob> returns C<undef> value if C<SCALAR> slot contains C<undef> value.

C<delete_glob> and C<delete_sub> delete C<SCALAR> slot if it exists and
contains C<undef> value.

C<delete_glob> and C<delete_sub> always delete C<FORMAT> slot.

If you find the bug or want to implement new features, please report it at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Symbol-Util>

=for readme continue

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (c) 2009, 2012 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>
