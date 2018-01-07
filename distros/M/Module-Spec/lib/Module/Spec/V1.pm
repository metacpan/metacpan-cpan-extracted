
package Module::Spec::V1;
$Module::Spec::V1::VERSION = '0.5.1';
# ABSTRACT: Load modules based on specifications V1
use 5.010001;

# use strict;
# use warnings;

our @EXPORT_OK = qw(need_module try_module);

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
    if ( $_[0] =~ m/\A ($MODULE_RE) (?: ~ ($VERSION_RE) )? \z/x ) {
        my ( $m, $v ) = ( $1, $2 );    # Make a copy
        return ($m) unless $v;
        return ( $m, _parse_v_spec($v) );
    }
    elsif ( ref $_[0] eq 'ARRAY' ) {

        croak(qq{Should contain one or two entries})
          unless @{ $_[0] } && @{ $_[0] } <= 2;
        my $m = $_[0][0];
        my ( $m1, @v1 ) = _parse_module_spec($m)
          or croak(qq{Can't parse $m});
        return ( $m1, @v1 ) if @{ $_[0] } == 1;
        my $v = $_[0][1];
        return ( $m1, _parse_version_spec($v) );
    }
    elsif ( ref $_[0] eq 'HASH' ) {

        croak(qq{Should contain a single pair}) unless keys %{ $_[0] } == 1;
        my ( $m, $v ) = %{ $_[0] };
        my ($m1) = _parse_module_spec($m)
          or croak(qq{Can't parse $m});
        return ( $m1, _parse_version_spec($v) );
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
    _require_module($m) if $opts->{require}->( $m, @v );
    $m->VERSION(@v) if @v;
    return wantarray ? ( $m, $m->VERSION ) : $m;
}

# generate_code($spec, \%opts);
sub generate_code {
    my $opts = @_ > 1 ? pop : {};
    $opts->{context} ||= 'void';
    $opts->{indent}  ||= ' ' x 4;

    my ( $m, @v ) = _parse_module_spec( $_[-1] )
      or croak(qq(Can't parse $_[-1]}));
    my $code = "require $m;\n";
    $code .= "$m->VERSION('$v[0]');\n" if @v;

    if ( $opts->{context} eq 'void' ) {

        # nothing to do
    }
    elsif ( $opts->{context} eq 'scalar' ) {
        $code .= "'$m';\n";
    }
    elsif ( $opts->{context} eq 'list' ) {
        $code .= "('$m', '$m'->VERSION);\n";
    }

    if ( $opts->{wrap} ) {
        $code =~ s/^/$opts->{indent}/mg if $opts->{indent};
        $code = "do {\n$code};\n";
    }

    return $code;
}

sub _opts {
    my %opts = ( require => 1, %{ shift // {} } );

    my $v = $opts{require};
    $opts{require} = sub {$v}
      unless ref $v eq 'CODE';

    return \%opts;
}

# Diagnostics:
#  Can't locate Foo.pm in @INC (you may need to install the Foo module) (@INC contains:
#  Carp version 2.3 required--this is only version 1.40 at
#  Foo2 does not define $Foo2::VERSION--version check failed at

# try_module($spec)
# try_module($spec, \%opts)
sub try_module {
    my $opts = @_ > 1 ? _opts(pop) : $_OPTS;

    my ( $m, @v ) = _parse_module_spec( $_[-1] )
      or croak(qq{Can't parse $_[-1]});
    if ( $opts->{require}->( $m, @v ) ) {
        eval { _require_module($m) };
        if ($@) {
            my $err = $@;
            $err =~ /\ACan't locate\b/ ? return : die $err;
        }
    }
    if (@v) {
        eval { $m->VERSION(@v) };
        return if $@;

        # FIXME might ignore and eat non-load/non-version-check errors
    }
    return wantarray ? ( $m, $m->VERSION ) : $m;
}

# TODO need_modules($spec1, $spec1)

sub _require_module {
    ( my $f = "$_[0].pm" ) =~ s{::}{/}g;
    require $f;
}

sub croak {
    require Carp;
    no warnings 'redefine';
    *croak = \&Carp::croak;
    goto &croak;
}

1;

#pod =encoding utf8
#pod
#pod =head1 SYNOPSIS
#pod
#pod     use Module::Spec::V1 ();
#pod     Module::Spec::V1::need_module('Mango~2.3');
#pod
#pod =head1 DESCRIPTION
#pod
#pod B<This is alpha software. The API is likely to change.>
#pod
#pod =head2 MODULE SPECS
#pod
#pod As string
#pod
#pod     M
#pod     M~V       minimum match, ≥ V
#pod     M~0       same as M, accepts any version
#pod
#pod Example version specs are
#pod
#pod     2
#pod     2.3
#pod     2.3.4
#pod     v3.2.3
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
#pod     $module = need_module('SomeModule~2.3');
#pod     $module = need_module( { SomeModule => '2.3' } );
#pod     $module = need_module( [ SomeModule => '2.3' ] );
#pod
#pod     $module = need_module($spec);
#pod     $module = need_module($spec, \%opts);
#pod
#pod Loads a module and checks for a version requirement (if any).
#pod Returns the name of the loaded module.
#pod
#pod On list context, returns the name of the loaded module
#pod and its version (as reported by C<< $m->VERSION >>).
#pod
#pod     ( $m, $v ) = need_module($spec);
#pod     ( $m, $v ) = need_module($spec, \%opts);
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
#pod =head2 try_module
#pod
#pod     $module = try_module('SomeModule~2.3');
#pod     $module = try_module( { SomeModule => '2.3' } );
#pod     $module = try_module( [ SomeModule => '2.3' ] );
#pod
#pod     $module = try_module($spec);
#pod     $module = try_module($spec, \%opts);
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
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Spec::V1 - Load modules based on specifications V1

=head1 VERSION

version 0.5.1

=head1 SYNOPSIS

    use Module::Spec::V1 ();
    Module::Spec::V1::need_module('Mango~2.3');

=head1 DESCRIPTION

B<This is alpha software. The API is likely to change.>

=head2 MODULE SPECS

As string

    M
    M~V       minimum match, ≥ V
    M~0       same as M, accepts any version

Example version specs are

    2
    2.3
    2.3.4
    v3.2.3

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

    $module = need_module('SomeModule~2.3');
    $module = need_module( { SomeModule => '2.3' } );
    $module = need_module( [ SomeModule => '2.3' ] );

    $module = need_module($spec);
    $module = need_module($spec, \%opts);

Loads a module and checks for a version requirement (if any).
Returns the name of the loaded module.

On list context, returns the name of the loaded module
and its version (as reported by C<< $m->VERSION >>).

    ( $m, $v ) = need_module($spec);
    ( $m, $v ) = need_module($spec, \%opts);

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

=head2 try_module

    $module = try_module('SomeModule~2.3');
    $module = try_module( { SomeModule => '2.3' } );
    $module = try_module( [ SomeModule => '2.3' ] );

    $module = try_module($spec);
    $module = try_module($spec, \%opts);

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

=head1 CAVEATS

=over 4

=item *

Single quotes (C<'>) are not accepted as package separators.

=item *

Exceptions are not thrown from the perspective of the caller.

=back

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Adriano Ferreira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
