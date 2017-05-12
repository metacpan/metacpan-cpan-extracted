{
  package Module::Locate;
$Module::Locate::VERSION = '1.80';
use warnings;
  use 5.8.8;

  our $Cache    = 0;
  our $Global   = 1;

  my $ident_re = qr{[_a-z]\w*}i;
  my $sep_re   = qr{'|::};
  our $PkgRe    = qr{\A(?:$ident_re(?:$sep_re$ident_re)*)\z};

  my @All      = qw(
    locate get_source acts_like_fh
    mod_to_path is_mod_loaded is_pkg_loaded
  );

  sub import {
    my $pkg = caller;
    my @args = @_[ 1 .. $#_ ];
    
    while(local $_ = shift @args) {
      *{ "$pkg\::$_" } = \&$_ and next
        if defined &$_;

      $Cache = shift @args, next
        if /^cache$/i;

      $Global = shift @args, next
        if /^global$/i;

      if(/^:all$/i) {
        *{ "$pkg\::$_" } = \&$_
          for @All;
        next;
      }

      warn("not in ".__PACKAGE__." import list: '$_'");
    }
  }

  use strict;

  use IO::File;
  use overload ();
  use Carp 'croak';
  use File::Spec::Functions 'catfile';
  
  sub get_source {
    my $pkg = $_[-1];

    my $f = locate($pkg);

    my $fh = ( acts_like_fh($f) ?
      $f
    :
      do { my $tmp = IO::File->new($f)
             or croak("invalid module '$pkg' [$f] - $!"); $tmp }
    );

    local $/;
    return <$fh>;
  }
  
  sub locate {
    my $pkg = $_[-1];

    croak("Undefined filename provided")
      unless defined $pkg;
      
    my $inc_path = mod_to_path($pkg);

    return $INC{$inc_path} if exists($INC{$inc_path}) && !wantarray;

    # On Windows the inc_path will use '/' for directory separator,
    # but when looking for a module, we need to use the OS's separator.
    my $partial_path = _mod_to_partial_path($pkg);

    my @paths;

    for(@INC) {
      if(ref $_) {
        my $ret = coderefs_in_INC($_, $inc_path);

        next
          unless defined $ret;

        croak("invalid \@INC subroutine return $ret")
          unless acts_like_fh($ret);

        return $ret;
      }

      my $fullpath = catfile($_, $partial_path);
      push(@paths, $fullpath) if -f $fullpath;
    }

    return unless @paths > 0;

    return wantarray ? @paths : $paths[0];
  }

  sub mod_to_path {
    my $pkg  = shift;
    my $path = $pkg;

    croak("Invalid package name '$pkg'")
      unless $pkg =~ $Module::Locate::PkgRe;

    # %INC always uses / as a directory separator, even on Windows
    $path =~ s!::!/!g;
    $path .= '.pm' unless $path =~ m!\.pm$!;

    return $path;
  }

  sub coderefs_in_INC {
    my($path, $c) = reverse @_;

    my $ret = ref($c) eq 'CODE' ?
      $c->( $c, $path )
    :
      ref($c) eq 'ARRAY' ?
        $c->[0]->( $c, $path )
      :
        UNIVERSAL::can($c, 'INC') ?
          $c->INC( $path )
        :
          warn("invalid reference in \@INC '$c'")
    ;

    return $ret;
  }

  sub acts_like_fh {
    no strict 'refs';
    return ( ref $_[0] and (
         ( ref $_[0] eq 'GLOB' and defined *{$_[0]}{IO} )
      or ( UNIVERSAL::isa($_[0], 'IO::Handle')          )
      or ( overload::Method($_[0], '<>')                )
    ) or ref \$_[0] eq 'GLOB' and defined *{$_[0]}{IO}  );
  }

  sub is_mod_loaded {
    my $mod  = shift;
    
    croak("Invalid package name '$mod'")
      unless $mod =~ $Module::Locate::PkgRe;
    
    ## it looks like %INC entries automagically use / as a separator
    my $path = join '/', split '::' => "$mod.pm";

    return (exists $INC{$path} && defined $INC{$path});
  }

  sub _mod_to_partial_path {
    my $package = shift;

    return catfile(split(/::/, $package)).'.pm';
  }

  sub is_pkg_loaded {
    my $pkg = shift;

    croak("Invalid package name '$pkg'")
      unless $pkg =~ $Module::Locate::PkgRe;

    my @tbls = map "${_}::", split('::' => $pkg);
    my $tbl  = \%main::;
    
    for(@tbls) {
      return unless exists $tbl->{$_};
      $tbl = $tbl->{$_};
    }
    
    return !!$pkg;
  }
}

q[ That better be make-up, and it better be good ];

=pod

=head1 NAME

Module::Locate - locate modules in the same fashion as C<require> and C<use>

=head1 SYNOPSIS

  use Module::Locate qw/ locate get_source /;
  
  add_plugin( locate "This::Module" );
  eval 'use strict; ' . get_source('legacy_code.plx');

=head1 DESCRIPTION

Using C<locate()>, return the path that C<require> would find for a given
module or filename (it can also return a filehandle if a reference in C<@INC>
has been used). This means you can test for the existence, or find the path
for, modules without having to evaluate the code they contain.

This module also comes with accompanying utility functions that are used within
the module itself (except for C<get_source>) and are available for import.

=head1 FUNCTIONS

=over 4

=item C<import>

Given function names, the appropriate functions will be exported into the
caller's package.

If C<:all> is passed then all subroutines are exported.

The B<Global> and B<Cache> options are no longer supported.
See the BUGS section below.


=item C<locate($module_name)>

Given a module name as a string (in standard perl bareword format) locate the
path of the module. If called in a scalar context the first path found will be
returned, if called in a list context a list of paths where the module was
found. Also, if references have been placed in C<@INC> then a filehandle will
be returned, as defined in the C<require> documentation. An empty C<return> is
used if the module couldn't be located.

As of version C<1.7> a filename can also be provided to further mimic the lookup
behaviour of C<require>/C<use>.

=item C<get_source($module_name)>

When provided with a package name, gets the path using C<locate()>.
If C<locate()> returned a path, then the contents of that file are returned
by C<get_source()> in a scalar.

=item C<acts_like_fh>

Given a scalar, check if it behaves like a filehandle. Firstly it checks if it
is a bareword filehandle, then if it inherits from C<IO::Handle> and lastly if
it overloads the C<E<lt>E<gt>> operator. If this is missing any other standard
filehandle behaviour, please send me an e-mail.

=item C<mod_to_path($module_name)>

Given a module name,
converts it to a relative path e.g C<Foo::Bar> would become C<Foo/Bar.pm>.

Note that this path will always use '/' for the directory separator,
even on Windows,
as that's the format used in C<%INC>.

=item C<is_mod_loaded($module_name)>

Given a module name, return true if the module has been
loaded (i.e exists in the C<%INC> hash).

=item C<is_pkg_loaded($package_name)>

Given a package name (like C<locate()>), check if the package has an existing
symbol table loaded (checks by walking the C<%main::> stash).

=back

=head1 SEE ALSO

A review of modules that can be used to get the path (and often other information)
for one or more modules: L<http://neilb.org/reviews/module-path.html>.

L<App::Module::Locate> and L<mlocate>.

=head1 REPOSITORY

L<https://github.com/neilb/Module-Locate>

=head1 BUGS

In previous versions of this module, if you specified C<Global =E<gt> 1>
when use'ing this module,
then looking up a module's path would update C<%INC>,
even if the module hadn't actually been loaded (yet).
This meant that if you subsequently tried to load the module,
it would wrongly not be loaded.

Bugs are tracked using RT (bug you can also raise Github issues if you prefer):

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Locate>

=head1 AUTHOR

Dan Brook C<< <cpan@broquaint.com> >>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut
