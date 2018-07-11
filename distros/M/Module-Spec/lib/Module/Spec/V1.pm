
package Module::Spec::V1;
$Module::Spec::V1::VERSION = '0.9.0';
# ABSTRACT: Load modules based on V1 specifications
use 5.012;

# use warnings;

our @EXPORT_OK = qw(need_module try_module);

BEGIN {
    require Module::Spec::V0;
    *_generate_code  = \&Module::Spec::V0::_generate_code;
    *_opts           = \&Module::Spec::V0::_opts;
    *_need_module    = \&Module::Spec::V0::_need_module;
    *_require_module = \&Module::Spec::V0::_require_module;
    *_try_module     = \&Module::Spec::V0::_try_module;
    *croak           = \&Module::Spec::V0::croak;
}

state $MODULE_RE  = qr/ [^\W\d]\w*+ (?: :: \w++ )*+ /x;
state $VERSION_RE = qr/ v?+ (?>\d+) (?: [\._] \d+ )*+ /x;

sub parse_module_spec {
    my $spec = pop;
    if ( my ( $m, @v ) = _parse_module_spec($spec) ) {
        my %info = ( module => $m );
        $info{version} = $v[0] if @v;
        return \%info;
    }
    return;
}

sub _parse_module_spec {
    if ( $_[0] =~ m/\A $MODULE_RE \z/x ) {
        return $_[0];
    }
    elsif ( ref $_[0] eq 'ARRAY' ) {

        croak(qq{Should contain one or two entries})
          unless @{ $_[0] } && @{ $_[0] } <= 2;
        my $m = $_[0][0];
        $m =~ m/\A $MODULE_RE \z/x
          or croak(qq{Can't parse $m});
        return ($m) if @{ $_[0] } == 1;
        my $v = $_[0][1];
        return ( $m, _parse_version_spec($v) );
    }
    elsif ( ref $_[0] eq 'HASH' ) {

        croak(qq{Should contain a single pair}) unless keys %{ $_[0] } == 1;
        my ( $m, $v ) = %{ $_[0] };
        $m =~ m/\A $MODULE_RE \z/x
          or croak(qq{Can't parse $m});
        return ( $m, _parse_version_spec($v) );
    }
    return;
}

sub _parse_v_spec { $_[0] eq '0' ? () : ( $_[0] ) }

sub _parse_version_spec {    # Extra sanity check
    unless ( defined $_[0] && $_[0] =~ m/\A $VERSION_RE \z/x ) {
        croak(qq{Invalid version $_[0]});
    }
    goto &_parse_v_spec;
}

# Precomputed for most common case
state $_OPTS = _opts();

# need_module($spec)
# need_module($spec, \%opts)
sub need_module {
    my $opts = @_ > 1 ? _opts(pop) : $_OPTS;

    my ( $m, @v ) = _parse_module_spec( $_[-1] )
      or croak(qq{Can't parse $_[-1]});
    return _need_module( $opts, $m, @v ) unless $opts->{try};
    return _try_module( $opts, $m, @v );
}

# generate_code($spec, \%opts);
sub generate_code {
    my $opts = @_ > 1 ? pop : {};

    my ( $m, @v ) = _parse_module_spec( $_[-1] )
      or croak(qq(Can't parse $_[-1]}));
    return _generate_code( $opts, $m, @v );
}

# try_module($spec)
# try_module($spec, \%opts)
sub try_module {
    my $opts = @_ > 1 ? _opts(pop) : $_OPTS;

    my ( $m, @v ) = _parse_module_spec( $_[-1] )
      or croak(qq{Can't parse $_[-1]});
    return _try_module( $opts, $m, @v );
}

sub need_modules {
    my $op = $_[0] =~ /\A-/ ? shift : '-all';
    state $SUB_FOR = {
        '-all'   => \&_need_all_modules,
        '-any'   => \&_need_any_modules,
        '-oneof' => \&_need_first_module,
    };
    croak(qq{Unknown operator "$op"}) unless my $sub = $SUB_FOR->{$op};
    if ( @_ == 1 && ref $_[0] eq 'HASH' ) {
        @_ = map { [ $_ => $_[0]{$_} ] } keys %{ $_[0] };
    }
    goto &$sub;
}

sub try_modules {
    unshift @_, '-any';
    goto &need_modules;
}

sub _need_all_modules {
    map { scalar need_module($_) } @_;
}

sub _need_any_modules {
    my ( @m, $m );
    ( $m = try_module($_) ) && push @m, $m for @_;
    return @m;
}

sub _need_first_module {
    my $m;
    ( $m = try_module($_) ) && return ($m) for @_;
    return;
}

1;

#pod =encoding utf8
#pod
#pod =head1 SYNOPSIS
#pod
#pod     use Module::Spec::V1 ();
#pod     Module::Spec::V1::need_module('Mango');
#pod     Module::Spec::V1::need_module( [ 'Mango' => '2.3' ] );
#pod     Module::Spec::V1::need_module( { 'Mango' => '2.3' } );
#pod
#pod =head1 DESCRIPTION
#pod
#pod B<This is alpha software. The API is likely to change.>
#pod
#pod =head2 MODULE SPECS
#pod
#pod As string
#pod
#pod     M               any version
#pod
#pod As a hash ref
#pod
#pod     { M => V }      minimum match, ≥ V
#pod     { M => '0' }    accepts any version
#pod
#pod As an array ref
#pod
#pod     [ M ]
#pod     [ M => V ]      minimum match, ≥ V
#pod     [ M => '0' ]    same as [ M ], accepts any version
#pod
#pod =head1 FUNCTIONS
#pod
#pod L<Module::Spec::V1> implements the following functions.
#pod
#pod =head2 need_module
#pod
#pod     $module = need_module('SomeModule');
#pod     $module = need_module( { 'SomeModule' => '2.3' } );
#pod     $module = need_module( [ 'SomeModule' => '2.3' ] );
#pod
#pod     $module = need_module($spec);
#pod     $module = need_module( $spec, \%opts );
#pod
#pod Loads a module and checks for a version requirement (if any).
#pod Returns the name of the loaded module.
#pod
#pod On list context, returns the name of the loaded module
#pod and its version (as reported by C<< $m->VERSION >>).
#pod
#pod     ( $m, $v ) = need_module($spec);
#pod     ( $m, $v ) = need_module( $spec, \%opts );
#pod
#pod These options are currently available:
#pod
#pod =over 4
#pod
#pod =item require
#pod
#pod     require => 1    # default
#pod     require => 0
#pod     require => sub { my ($m, @v) = @_; ... }
#pod
#pod Controls whether the specified module should be C<require>d or not.
#pod It can be given as a non-subroutine value, which gets
#pod interpreted as a boolean: true means that the module
#pod should be loaded with C<require> and false means
#pod that no attempt should be made to load it.
#pod This option can also be specified as a subroutine which gets
#pod passed the module name and version requirement (if any)
#pod and which should return true if the module should be loaded
#pod with C<require> or false otherwise.
#pod
#pod =item try
#pod
#pod     try => 0    # default
#pod     try => 1
#pod
#pod If C<try> is true, it behaves as L</"try_module">.
#pod
#pod =back
#pod
#pod =head2 need_modules
#pod
#pod     @modules = need_modules(@spec);
#pod     @modules = need_modules(-all => @spec);
#pod     @modules = need_modules(-any => @spec);
#pod     @modules = need_modules(-oneof => @spec);
#pod
#pod     @modules = need_modules(\%spec);
#pod     @modules = need_modules(-all => \%spec);
#pod     @modules = need_modules(-any => \%spec);
#pod     @modules = need_modules(-oneof => \%spec);
#pod
#pod Loads some modules according to a specified rule.
#pod
#pod The current supported rules are C<-all>, C<-any> and C<-oneof>.
#pod If none of these are given as the first argument,
#pod C<-all> is assumed.
#pod
#pod The specified modules are given as module specs,
#pod either as a  list or as a single hashref.
#pod If given as a list, the corresponding order will be respected.
#pod If given as a hashref, a random order is to be expected.
#pod
#pod The behavior of the rules are as follows:
#pod
#pod =over 4
#pod
#pod =item -all
#pod
#pod All specified modules are loaded by C<need_module>.
#pod If successful, returns the names of the loaded modules.
#pod
#pod =item -any
#pod
#pod All specified modules are loaded by C<try_module>.
#pod Returns the names of the modules successfully loaded.
#pod
#pod =item -oneof
#pod
#pod Specified modules are loaded by C<try_module>
#pod until a successful load.
#pod Returns (in list context) the name of the loaded module.
#pod
#pod =back
#pod
#pod =head2 try_module
#pod
#pod     $module = try_module('SomeModule');
#pod     $module = try_module( { 'SomeModule' => '2.3' } );
#pod     $module = try_module( [ 'SomeModule' => '2.3' ] );
#pod
#pod     $module = try_module($spec);
#pod     $module = try_module( $spec, \%opts );
#pod
#pod Tries to load a module (if available) and checks for a version
#pod requirement (if any). Returns the name of the loaded module
#pod if it can be loaded successfully and satisfies any specified version
#pod requirement.
#pod
#pod On list context, returns the name of the loaded module
#pod and its version (as reported by C<< $m->VERSION >>).
#pod
#pod     ( $m, $v ) = try_module($spec);
#pod     ( $m, $v ) = try_module($spec, \%opts);
#pod
#pod These options are currently available:
#pod
#pod =over 4
#pod
#pod =item require
#pod
#pod     require => 1    # default
#pod     require => 0
#pod     require => sub { my ($m, @v) = @_; ... }
#pod
#pod Controls whether the specified module should be C<require>d or not.
#pod It can be given as a non-subroutine value, which gets
#pod interpreted as a boolean: true means that the module
#pod should be loaded with C<require> and false means
#pod that no attempt should be made to load it.
#pod This option can also be specified as a subroutine which gets
#pod passed the module name and version requirement (if any)
#pod and which should return true if the module should be loaded
#pod with C<require> or false otherwise.
#pod
#pod =back
#pod
#pod =head2 try_modules
#pod
#pod     @modules = try_modules(@spec);
#pod     @modules = try_modules(\%spec);
#pod
#pod Shortcut for
#pod
#pod     @modules = need_modules(-any => @spec);
#pod     @modules = need_modules(-any => \%spec);
#pod
#pod =head1 CAVEATS
#pod
#pod =over 4
#pod
#pod =item *
#pod
#pod Single quotes (C<'>) are not accepted as package separators.
#pod
#pod =item *
#pod
#pod Exceptions are not thrown from the perspective of the caller.
#pod
#pod =back
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Module::Runtime>
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Spec::V1 - Load modules based on V1 specifications

=head1 VERSION

version 0.9.0

=head1 SYNOPSIS

    use Module::Spec::V1 ();
    Module::Spec::V1::need_module('Mango');
    Module::Spec::V1::need_module( [ 'Mango' => '2.3' ] );
    Module::Spec::V1::need_module( { 'Mango' => '2.3' } );

=head1 DESCRIPTION

B<This is alpha software. The API is likely to change.>

=head2 MODULE SPECS

As string

    M               any version

As a hash ref

    { M => V }      minimum match, ≥ V
    { M => '0' }    accepts any version

As an array ref

    [ M ]
    [ M => V ]      minimum match, ≥ V
    [ M => '0' ]    same as [ M ], accepts any version

=head1 FUNCTIONS

L<Module::Spec::V1> implements the following functions.

=head2 need_module

    $module = need_module('SomeModule');
    $module = need_module( { 'SomeModule' => '2.3' } );
    $module = need_module( [ 'SomeModule' => '2.3' ] );

    $module = need_module($spec);
    $module = need_module( $spec, \%opts );

Loads a module and checks for a version requirement (if any).
Returns the name of the loaded module.

On list context, returns the name of the loaded module
and its version (as reported by C<< $m->VERSION >>).

    ( $m, $v ) = need_module($spec);
    ( $m, $v ) = need_module( $spec, \%opts );

These options are currently available:

=over 4

=item require

    require => 1    # default
    require => 0
    require => sub { my ($m, @v) = @_; ... }

Controls whether the specified module should be C<require>d or not.
It can be given as a non-subroutine value, which gets
interpreted as a boolean: true means that the module
should be loaded with C<require> and false means
that no attempt should be made to load it.
This option can also be specified as a subroutine which gets
passed the module name and version requirement (if any)
and which should return true if the module should be loaded
with C<require> or false otherwise.

=item try

    try => 0    # default
    try => 1

If C<try> is true, it behaves as L</"try_module">.

=back

=head2 need_modules

    @modules = need_modules(@spec);
    @modules = need_modules(-all => @spec);
    @modules = need_modules(-any => @spec);
    @modules = need_modules(-oneof => @spec);

    @modules = need_modules(\%spec);
    @modules = need_modules(-all => \%spec);
    @modules = need_modules(-any => \%spec);
    @modules = need_modules(-oneof => \%spec);

Loads some modules according to a specified rule.

The current supported rules are C<-all>, C<-any> and C<-oneof>.
If none of these are given as the first argument,
C<-all> is assumed.

The specified modules are given as module specs,
either as a  list or as a single hashref.
If given as a list, the corresponding order will be respected.
If given as a hashref, a random order is to be expected.

The behavior of the rules are as follows:

=over 4

=item -all

All specified modules are loaded by C<need_module>.
If successful, returns the names of the loaded modules.

=item -any

All specified modules are loaded by C<try_module>.
Returns the names of the modules successfully loaded.

=item -oneof

Specified modules are loaded by C<try_module>
until a successful load.
Returns (in list context) the name of the loaded module.

=back

=head2 try_module

    $module = try_module('SomeModule');
    $module = try_module( { 'SomeModule' => '2.3' } );
    $module = try_module( [ 'SomeModule' => '2.3' ] );

    $module = try_module($spec);
    $module = try_module( $spec, \%opts );

Tries to load a module (if available) and checks for a version
requirement (if any). Returns the name of the loaded module
if it can be loaded successfully and satisfies any specified version
requirement.

On list context, returns the name of the loaded module
and its version (as reported by C<< $m->VERSION >>).

    ( $m, $v ) = try_module($spec);
    ( $m, $v ) = try_module($spec, \%opts);

These options are currently available:

=over 4

=item require

    require => 1    # default
    require => 0
    require => sub { my ($m, @v) = @_; ... }

Controls whether the specified module should be C<require>d or not.
It can be given as a non-subroutine value, which gets
interpreted as a boolean: true means that the module
should be loaded with C<require> and false means
that no attempt should be made to load it.
This option can also be specified as a subroutine which gets
passed the module name and version requirement (if any)
and which should return true if the module should be loaded
with C<require> or false otherwise.

=back

=head2 try_modules

    @modules = try_modules(@spec);
    @modules = try_modules(\%spec);

Shortcut for

    @modules = need_modules(-any => @spec);
    @modules = need_modules(-any => \%spec);

=head1 CAVEATS

=over 4

=item *

Single quotes (C<'>) are not accepted as package separators.

=item *

Exceptions are not thrown from the perspective of the caller.

=back

=head1 SEE ALSO

L<Module::Runtime>

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Adriano Ferreira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
