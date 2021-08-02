package Pod::Coverage::TrustMe;
use strict;
use warnings;

our $VERSION = '0.001002';
$VERSION =~ tr/_//d;

use Pod::Coverage::TrustMe::Parser;
use B ();
use Carp qw(croak);
use constant _GVf_IMPORTED_CV => defined &B::GVf_IMPORTED_CV ? B::GVf_IMPORTED_CV() : 0x80;

use constant DEFAULT_PRIVATE => do {
  my %s;
  [
    qr/\A_/,
    # anything with non-word characters is not standard syntax, so exclude
    # them. this includes overloads, which are internally stored as methods
    # starting with '('.
    qr/\W/,
    (map qr{\A\Q$_\E\z}, grep !$s{$_}++, qw(
      import
      unimport

      can
      isa
      does
      DOES

      AUTOLOAD

      DESTROY
      CLONE
      CLONE_SKIP

      BUILD
      BUILDALL
      DEMOLISH
      DEMOLISHALL

      bootstrap

      TIESCALAR
      FETCH STORE

      TIEARRAY
      FETCH STORE FETCHSIZE STORESIZE EXTEND EXISTS
      DELETE CLEAR PUSH POP SHIFT UNSHIFT SPLICE

      TIEHASH
      FETCH STORE DELETE CLEAR EXISTS FIRSTKEY NEXTKEY SCALAR

      TIEHANDLE
      OPEN BINMODE FILENO SEEK TELL WRITE PRINT PRINTF
      READ READLINE GETC EOF CLOSE

      UNTIE
    )),
    qr/\A
      (?: MODIFY | FETCH )
      _
      (?: REF | SCALAR | ARRAY | HASH | CODE | GLOB | FORMAT | IO )
      _
      ATTRIBUTES
    \z/x,
  ];
};
&Internals::SvREADONLY(+DEFAULT_PRIVATE, 1);

our $PACKAGE_RE = qr{
  (?=[^0-9'])
  (?:
    ::
  |
    \w*
    (?:'[^\W0-9]\w*)*
  )*
}x;
&Internals::SvREADONLY(\$PACKAGE_RE, 1);

my %DEFAULTS = (
  trust_roles     => 1,
  trust_parents   => 1,
  trust_pod       => 1,
  require_link    => 0,
  export_only     => 0,
  ignore_imported => 1,
  nonwhitespace   => 0,
  trustme         => [],
  private         => DEFAULT_PRIVATE,
  pod_from        => undef,
  package         => undef,
);

sub new {
  my ($class, %args) = @_;
  $class = ref $class
    if ref $class;

  my $new = {
    map +($_ => exists $args{$_} ? $args{$_} : $DEFAULTS{$_}), keys %DEFAULTS,
  };

  if (exists $args{private} || exists $args{also_private}) {
    $new->{private} = [
      map +(ref $_ ? $_ : qr/\A\Q$_\E\z/), (
        @{ $new->{private} },
        exists $args{also_private} ? @{ $args{also_private} } : (),
      )
    ];
  }

  my $package = $new->{package}
    or die "package is a required parameter";

  eval { require(__pack_to_pm($package)); 1 } or do {
    $new->{why_unrated} = "requiring '$package' failed: $@";
    $new->{broken} = 1;
  };

  bless $new, $class;
}

sub package {
  my $self = shift;
  $self->{package};
}

sub symbols {
  my $self = shift;
  return undef
    if $self->{broken};
  $self->{symbols} ||= do {
    my $package = $self->package;

    my %pods    = map +( $_ => 1 ), @{ $self->_get_pods($package) };
    my %symbols = map +(
      $_ => ($pods{$_} || $self->_trustme_check($_) || 0),
    ), $self->_get_syms($package);

    if (!grep $_, values %symbols) {
      $self->{why_unrated} ||= "no public symbols defined";
    }

    \%symbols;
  };
}

sub coverage {
  my $self = shift;
  my $symbols = $self->symbols
    or return undef;

  my $total = scalar keys %$symbols
    or return undef;
  my $documented = scalar grep $_, values %$symbols;

  return $documented / $total;
}

sub why_unrated {
  my $self = shift;
  return $self->{why_unrated};
}

sub uncovered {
  my $self = shift;
  my $symbols = $self->symbols
    or return ();
  my @uncovered = sort grep !$symbols->{$_}, keys %$symbols;
  return @uncovered;
}
sub naked {
  my $self = shift;
  return $self->uncovered(@_);
}

sub covered {
  my $self = shift;
  my $symbols = $self->symbols
    or return ();
  my @covered = sort grep $symbols->{$_}, keys %$symbols;
  return @covered;
}

sub report {
  my $self = shift;
  my $rating = $self->coverage;

  $rating = 'unrated (' . $self->why_unrated . ')'
    unless defined $rating;

  my $message = sprintf "%s has a Pod coverage rating of %s\n", $self->package, $rating;

  my @uncovered = $self->uncovered;
  if (@uncovered) {
    $message .= "The following are uncovered:\n";
    $message .= "  $_\n"
      for @uncovered;
  }
  return $message;
}

sub print_report {
  my $self = shift;
  print $self->report;
}

sub import {
  my $class = shift;
  return
    if !@_;

  $class->new(@_ == 1 ? (package => $_[0]) : @_)->print_report;
  return;
}


sub _search_packages {
  my $self = shift;
  my @search = @_;
  @search = ('main')
    if !@search;

  s/\A(?:::)?(?:(?:main)?::)+//, s/(?:::)?\z/::/
    for @search;

  my @packages;

  while (@search) {
    my $search = shift @search;
    push @packages, $search;
    my $base = $search eq 'main::' ? '' : $search;

    no strict 'refs';
    my @add =
      map $base.$_,
      sort
      grep /::$/ && $_ ne 'main::',
      keys %$search;

    unshift @search, @add;
  }

  s/::\z//
    for @packages;

  return grep +(
    $_ ne 'main'
    && $_ ne ''
    && $_ ne 'UNIVERSAL'
  ), @packages;
}

sub _get_roles {
  my $self = shift;
  my $package = $self->package;
  my $does
    = $package->can('does') ? 'does'
    : $package->can('DOES') ? 'DOES'
                            : return;
  return grep $_ ne $package && $package->$does($_), $self->_search_packages;
}

sub _get_parents {
  my $self = shift;
  my $package = $self->package;
  return grep $_ ne $package && $package->isa($_), $self->_search_packages;
}

sub __pack_to_pm {
  my ($package) = @_;
  croak "Invalid package '$package'"
    unless $package =~ /\A$PACKAGE_RE\z/;
  (my $mod = "$package.pm") =~ s{'|::}{/}g;
  return $mod;
}

sub _pod_for {
  my $self = shift;
  my ($package) = @_;
  if ($self->package eq $package && defined $self->{pod_from}) {
    return $self->{pod_from};
  }

  my $mod = __pack_to_pm($package);
  my $full = $INC{$mod} or return;
  (my $maybe_pod = $full) =~ s{\.pm\z}{.pod};
  my $pod
    = -e $maybe_pod ? $maybe_pod
    : -e $full      ? $full
                    : undef
    ;
  if ($self->package eq $package) {
    $self->{pod_from} = $pod;
  }
  return $pod;
}

sub trusted_packages {
  my $self = shift;

  my %to_parse = (
    $self->package => 1,
  );
  @to_parse{$self->_get_roles} = ()
    if $self->{trust_roles};
  @to_parse{$self->_get_parents} = ()
    if $self->{trust_parents};

  my @trusted = sort keys %to_parse;
  return @trusted;
}

sub _pod_parser_class { 'Pod::Coverage::TrustMe::Parser' }
sub _new_pod_parser {
  my $self = shift;

  my $parser = $self->_pod_parser_class->new(@_);
  if ($self->{nonwhitespace}) {
    $parser->ignore_empty(1);
  }
  return $parser;
}
sub _pod_parser_for {
  my $self = shift;
  my ($pack) = @_;
  my $pod = $self->_pod_for($pack)
    or return undef;
  my $parser = $self->_new_pod_parser;
  $parser->parse_file($pod);
  return $parser;
}

sub _parsed {
  my $self = shift;
  return $self->{_parsed}
    if $self->{_parsed};

  my %parsed = map {
    my $pack = $_;
    my $parser = $self->_pod_parser_for($pack);
    $parser ? ($pack => $parser) : ();
  } $self->trusted_packages;

  if ($self->{require_link}) {
    my $package = $self->package;
    my %allowed;
    my %find_links = (
      $package => delete $parsed{$package} || $self->_pod_parser_for($package),
    );

    while (%find_links) {
      @allowed{keys %find_links} = values %find_links;
      %find_links =
        map +(exists $parsed{$_} ? ($_ => delete $parsed{$_}) : ()),
        map @{ $_->links },
        values %find_links;
    }

    %parsed = %allowed;
  }

  $self->{_parsed} = \%parsed;
}

sub _symbols_for {
  my $self = shift;
  my ($package) = @_;

  my @symbols;
  no strict 'refs';

  if ($self->{export_only}) {
    @symbols = (
      @{"${package}::EXPORT"},
      @{"${package}::EXPORT_OK"},
    );
  }
  else {
    @symbols =
      grep !(
        $self->{ignore_imported} && $self->_imported_check($_)
        or $self->_private_check($_)
      ),
      grep !/::\z/ && defined &{$package.'::'.$_},
      keys %{$package.'::'};
  }

  return @symbols;
}

sub _get_syms {
  my $self = shift;
  my $syms = $self->{_syms} ||= do {
    # recurse option?
    [ $self->_symbols_for($self->package) ];
  };
  return @$syms;
}

sub _get_pods {
  my $self = shift;

  $self->{_pods} ||= do {
    my $parsed = $self->_parsed;

    my %covered = map +( $_ => 1 ), map @{ $_->covered }, values %$parsed;

    [ sort keys %covered ];
  };
}

sub _trusted_from_pod {
  my $self = shift;

  $self->{_trusted_from_pod} ||= do {
    my $parsed = $self->_parsed;

    [ map @{ $_->trusted }, values %$parsed ];
  };
}

sub _private_check {
  my $self = shift;
  my ($sym) = @_;
  return scalar grep $sym =~ /$_/, @{ $self->{private} };
}

sub _trustme_check {
  my $self = shift;
  my ($sym) = @_;

  return scalar grep $sym =~ /$_/,
    @{ $self->{trustme} },
    @{ $self->_trusted_from_pod };
}

sub _imported_check {
  my $self = shift;
  my ($sym) = @_;
  my $package = $self->{package};
  no strict 'refs';
  return !!(B::svref_2object(\*{$package.'::'.$sym})->GvFLAGS & _GVf_IMPORTED_CV);
}

1;
__END__

=head1 NAME

Pod::Coverage::TrustMe - Pod::Coverage but more powerful

=head1 SYNOPSIS

  use Pod::Coverage::TrustMe;

  Pod::Coverage::TrustMe->new(package => 'My::Package')->print_report;

=head1 DESCRIPTION

Checks that all of the functions or methods provided by a package have
documentation. Compatible with most uses of L<Pod::Coverage>, but with
additional features.

=head1 CONSTRUCTOR OPTIONS

These options can be passed to C<< Pod::Coverage::TrustMe->new >>.

=for Pod::Coverage new

=over 4

=item package

The package to check coverage for. The module must be loadable.

=item pod_from

The Pod file to parse. By default, the module that is loaded will be used, or a
pod file existing in the same directory, if it exists.

=item private

An array ref of regular expressions for subs to consider private and not needing
to be documented. If non-regular expressions are included in the list, they will
be taken as literal sub names.
Defaults to L</DEFAULT_PRIVATE>.

=item also_private

An array ref of items to add to the private list. Makes it easy to augment the
default list.

=item trustme

An array ref of subs to consider documented even if no pod can be found. Has a
similar effect to L</private>, but will include the subs in the list of covered
subs, rather than excluding them from the list entirely.

=item nonwhitespace

Requires that the pod section for the sub have some non-whitespace characters in
it to be counted as covering the sub.

=item trust_parents

Includes Pod from parent classes in list of covered subs. Like
L<Pod::Coverage::CountParents>. Defaults to true.

=item trust_roles

Includes Pod from consumed roles in list of covered subs. Like
L<Pod::Coverage::CountParents>, but checking C<does> or C<DOES>. Defaults to
true.

=item trust_pod

Trusts subs or regexes listed in C<Pod::Coverage> blocks in Pod. Like
L<Pod::Coverage::TrustPod>. Defaults to true.

A section like:

  =for Pod::Coverage sub1 sub2 [A-Z_]+

will allow the subs C<sub1>, C<sub2>, and any sub that is all upper case to
exist without being documented.

=item require_link

Requires a link in the Pod to parent classes or roles to include them in the
coverage. If the documentation for subs is in different files, they should be
linked to in some way.

=item export_only

Only requires subs listed in C<@EXPORT> and C<@EXPORT_OK> to be covered.

=item ignore_imported

Ignore subs that were imported from other packages. If set to false, every sub
in the package needs to be covered, even if it is imported from another package.
Subs that aren't part of the API should be cleaned using a tool like
L<namespace::clean>, or excluded in some way. See also L<Test::CleanNamespaces>.
Defaults to true.

=back

=head1 METHODS

=over 4

=item coverage

Returns the percentage of subs covered as a value between 0 and 1.

=item why_unrated

=item covered

Returns a list of subs that are covered by the documentation.

=item uncovered

Returns a list of subs that are not covered by the documentation.

=item naked

An alias for uncovered.

=item report

Returns a text report on the covered and uncovered subroutines.

=item print_report

Print a text report on the covered and uncovered subroutines.

=item symbols

Returns the a hashref of symbols detected, with a value of true or false for
if the symbol is covered by pod.

=item trusted_packages

Returns the other packages that will have their pod checked for symbols to
treat as covered.

=back

=head1 METHODS FOR SUBCLASSES

There are some private methods provided that could be overridden in subclasses
to adjust the behavior.

=over 4

=item _get_syms($package)

Returns the list of symbols for a given package.

=item _get_pods($package)

Returns an array ref of all of the covered items in the pod.

=item _private_check($symbol)

Returns true if the given symbol should be considered private.

=item _trustme_check($symbol)

Returns true if the given symbol should be treated as covered even without any
documentation found.

=back

=head1 CONSTANTS

=over 4

=item DEFAULT_PRIVATE

An array reference of the default list of private regular expressions.

=back

=head1 TESTING

See L<Test::Pod::Coverage::TrustMe> for using this module in tests.

=head1 Pod::Coverage::TrustMe vs Pod::Coverage

There are some important differences between this module and L<Pod::Coverage>,
aside from the additional features.

=over 4

=item No _CvGV method

L<Pod::Coverage> provides and documents the _CvGV method, but doesn't use it
itself. This module does not provide the method.

=item No import method

L<Pod::Coverage> provides an import method to allow you to run code like
C<perl -MPod::Coverage=Some::Package -e1>. This module does not provide this,
instead encouraging the use of the L<pod-cover> script.

=item Uses L<Pod::Simple>

L<Pod::Coverage> parses pod using L<Pod::Parser>, which has been removed from
perl core and its use is discouraged. This module uses L<Pod::Simple> instead.

=back

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head1 CONTRIBUTORS

None so far.

=head1 COPYRIGHT

Copyright (c) 2020 the Pod::Coverage::TrustMe L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<https://dev.perl.org/licenses/>.

=cut
