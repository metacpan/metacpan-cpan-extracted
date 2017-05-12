package Package::Pkg;
{
  $Package::Pkg::VERSION = '0.0020';
}
# ABSTRACT: Handy package munging utilities


use strict;
use warnings;

use Class::Load ':all';
require Sub::Install;
use Try::Tiny;
use Carp;

our $pkg = __PACKAGE__;
sub pkg { $pkg }
__PACKAGE__->export( pkg => \&pkg );

{
    no warnings 'once';
    *package = \&name;
}

sub name {
    my $self = shift;
    my $package = join '::', map { ref $_ ? ref $_ : $_ } @_;
    $package =~ s/:{2,}/::/g;
    return '' if $package eq '::';
    if ( $package =~ m/^::/ ) {
        my $caller = caller;
        $package = "$caller$package";
    }
    return $package;
}

sub load_name {
    my $self = shift;
    my $package = $self->name( @_ );
    $self->load( $package );
    return $package;
}

sub _is_package_loaded ($) { return is_class_loaded( $_[0] ) }

sub _package2pm ($) {
    my $package = shift;
    my $pm = $package . '.pm';
    $pm =~ s{::}{/}g;
    return $pm;
}

sub lexicon {
    my $self = shift;
    require Package::Pkg::Lexicon;
    my $lexicon = Package::Pkg::Lexicon->new;
    $lexicon->add( @_ ) if @_;
    return $lexicon;
}

sub loader {
    my $self = shift;
    require Package::Pkg::Loader;
    my $namespacelist = ref $_[0] eq 'ARRAY' ? shift : [ splice @_, 0, @_ ];
    Package::Pkg::Loader->new( namespacelist => $namespacelist, @_ );
}

sub load {
    my $self = shift;
    my $package = @_ > 1 ? $self->name( @_ ) : $_[0];
    return Mouse::Util::load_class( $package );
}

sub softload {
    my $self = shift;
    my $package = @_ > 1 ? $self->name( @_ ) : $_[0];
    
    return $package if _is_package_loaded( $package );

    my $pm = _package2pm $package;

    return $package if try {
        local $SIG{__DIE__};
        require $pm;
        return 1;
    }
    catch {
        unless (/^Can't locate \Q$pm\E in \@INC/) {
            confess "Couldn't load package ($package) because: $_";
        }
        return;
    };
}

# pkg->install( name => sub { ... } => 
sub install {
    my $self = shift;
    my %install;
    if      ( @_ == 1 ) { %install = %{ $_[0] } }
    elsif   ( @_ == 2 ) {
        if ( $_[1] && $_[1] =~ m/::$/ ) { @install{qw/ code into /} = @_ }
        else                            { @install{qw/ code as /} = @_ }
    }
    elsif   ( @_ == 3 ) { @install{qw/ code into as /} = @_ }
    else                { %install = @_ }

    my ( $from, $code, $into, $_into, $as, ) = @install{qw/ from code into _into as /};
    undef %install;

    die "Missing code (@_)" unless defined $code;

    if ( ref $code eq 'CODE' ) {
        die "Invalid (superfluous) from ($from) with code reference (@_)" if defined $from;
    }
    else {
        if ( defined $from )
            { die "Invalid code ($code) with from ($from)" if $code =~ m/::/ }
        elsif ( $code =~ m/::/) {
            $code =~ s/^<//; # Silently allow <Package::subroutine
            ( $from, $code ) = $self->split2( $code );
        }
        else { $from = caller }
    }

    if ( defined $as && $as =~ m/::/) {
        die "Invalid as ($as) with into ($into)" if defined $into;
        ( $into, $as ) = $self->split2( $as );
    }
    elsif ( defined $into ) {
        if ( $into =~ s/::$// ) { }
    }
    elsif ( defined $_into ) {
        $into = $_into;
    }

    if      ( defined $as ) {}
    elsif   ( ! ref $code ) { $as = $code }
    else                    { die "Missing as (@_)" }

    die "Missing into (@_)" unless defined $into;

    @install{qw/ code into as /} = ( $code, $into, $as );
    $install{from} = $from if defined $from;
    Sub::Install::install_sub( \%install );
}

sub split {
    my $self = shift;
    my $target = shift;
    return unless defined $target && length $target;
    return split m/::/, $target;
}

sub split2 {
    my $self = shift;
    return unless my @split = $self->split( @_ );
    return $split[0] if 1 == @split;
    my $name = pop @split;
    return( join( '::', @split ), $name );
}

sub export {
    my $self = shift;
    my $exporter = $self->exporter( @_ );

    my $package = caller;
    $self->install( code => $exporter, as => "${package}::import" );
}

sub exporter {
    my $self = shift;
    my ( %index, %group, $default_export );
    %group = ( default => [], optional => [], all => [] );
    $default_export = 1;

    while ( @_ ) {
        local $_ = shift;
        my ( $group, @install );
        if      ( $_ eq '-' )       { undef $default_export }
        elsif   ( $_ eq '+' )       { $default_export = 1 }
        elsif   ( s/^\+// )         { $group = 'default' }
        elsif   ( s/^\-// )         { $group = 'optional' }
        elsif   ( $default_export ) { $group = 'default' }
        else                        { $group = 'optional' }

        my $name = $_;

        push @install, $name;
        if ( @_ ) {
            my $value = shift;
            if      ( ref $value eq 'CODE' ) { push @install, $value }
            elsif   ( $value =~ s/^<// )     { push @install, $value }
            else                             { unshift @_, $value }
        }

        push @{ $group{$group} ||= [] }, $name;
        $index{$name} = \@install;
    }
    $group{all} = [ map { @$_ } @group{qw/ default optional /} ];

    my $exporter = sub {
        my ( $class ) = @_;

        my $package = caller;
        my @arguments = splice @_, 1;
    
        my @exporting;
        if ( ! @arguments ) {
            push @exporting, @{ $group{default} };
        }
        else {
            @exporting = @arguments;
        }

        for my $name ( @exporting ) {
            my $install = $index{$name} or die "Unrecognized export ($name)";
            my $as = $install->[0];
            my $code = $install->[1] || "${class}::$as";
            __PACKAGE__->install( as => $as, code => $code, into => $package );
        }
    };

    return $exporter;
}

1;

__END__
=pod

=head1 NAME

Package::Pkg - Handy package munging utilities

=head1 VERSION

version 0.0020

=head1 SYNOPSIS

First, import a new keyword: C<pkg>

    use Package::Pkg;

Package name formation:

    pkg->name( 'Xy', 'A' ) # Xy::A
    pkg->name( $object, qw/ Cfg / ); # (ref $object)::Cfg

Subroutine installation:

    pkg->install( sub { ... } => 'MyPackage::myfunction' );

    # myfunction in MyPackage is now useable
    MyPackage->myfunction( ... );

Subroutine exporting:

    package MyPackage;

    use Package::Pkg;

    sub this { ... }

    # Setup an exporter (literally sub import { ... }) for
    # MyPackage, exporting 'this' and 'that'
    pkg->export( that => sub { ... }, 'this' );

    package main;

    use MyPackage;

    this( ... );

    that( ... );

=head1 DESCRIPTION

Package::Pkg is a collection of useful, miscellaneous package-munging utilities. Functionality is accessed via the imported C<pkg> keyword, although you can also invoke functions directly from the package (C<Package::Pkg>)

=head1 USAGE

=head2 pkg->install( ... )

Install a subroutine, similar to L<Sub::Install>

This method takes a number of parameters and also has a two- and three-argument form (see below)

    # Install an anonymous subroutine as Banana::magic
    pkg->install( code => sub { ... } , as => 'Banana::magic' )
    pkg->install( code => sub { ... } , into => 'Banana::magic' ) # Bzzzt! Throws an error!

    # Install the subroutine Apple::xyzzy as Banana::magic
    pkg->install( code => 'Apple::xyzzy', as => 'Banana::magic' )
    pkg->install( code => 'Apple::xyzzy', into => 'Banana', as => 'magic' )
    pkg->install( from => 'Apple', code => 'xyzzy', as => 'Banana::magic' )
    pkg->install( from => 'Apple', code => 'xyzzy', into => 'Banana', as => 'magic' )

    # Install the subroutine Apple::xyzzy as Banana::xyzzy
    pkg->install( code => 'Apple::xyzzy', as => 'Banana::xyzzy' )
    pkg->install( code => 'Apple::xyzzy', into => 'Banana' )
    pkg->install( from => 'Apple', code => 'xyzzy', as => 'Banana::xyzzy' )
    pkg->install( from => 'Apple', code => 'xyzzy', into => 'Banana' )

With implicit C<from> (via C<caller()>)

    package Apple;

    sub xyzzy { ... }

    # Install the subroutine Apple::xyzzy as Banana::xyzzy
    pkg->install( code => 'xyzzy', as => 'Banana::xyzzy' ) # 'from' is implicitly 'Apple'
    pkg->install( code => \&xyzzy, as => 'Banana::xyzzy' )

Acceptable parameters are:

    code            A subroutine reference,
                    A package-with-name identifier, or
                    The name of a subroutine in the calling package

    from (optional) A package identifier
                    If :code is an identifier, then :from is the package where
                    the subroutine can be found
                    If :code is an identifier and :from is not given, then :from
                    is assumed to be the calling package (via caller())

    as              The name of the subroutine to install as. Can be a simple name
                    (when paired with :into) or a full package-with-name 

    into (optional) A package identifier
                    If :as is given, then the full name of the installed
                    subroutine is (:into)::(:as)

                    If :as is not given and we can derive a simple name from
                    :code (It is a package-with-name identifier), then :as will be 
                    the name identifier part of :code

=head2 pkg->install( $code => $as )

This is the two-argument form of subroutine installation

Install $code subroutine as $as

    pkg->install( sub { ... } => 'Banana::xyzzy' )

    pkg->install( 'Scalar::Util::blessed' => 'Banana::xyzzy' )

    pkg->install( 'Scalar::Util::blessed' => 'Banana::' )

    pkg->install( sub { ... } => 'Banana::' ) # Bzzzt! Throws an error!

$code should be:

=over

=item * A CODE reference

    sub { ... }

=item * A package-with-name identifier

    Scalar::Util::blessed

=item * The name of a subroutine in the calling package

    sub xyzzy { ... }

    pkg->install( 'xyzzy' => ... )

=back

$as should be:

=over

=item * A package-with-name identifier

    Acme::Xyzzy::magic

=item * A package identifier (with a trailing ::)

    Acme::Xyzzy::

=back

=head2 pkg->install( $code => $into, $as )

This is the three-argument form of subroutine installation

    pkg->install( sub { ... } => 'Banana', 'xyzzy' )

    pkg->install( sub { ... } => 'Banana::', 'xyzzy' )

    pkg->install( 'Scalar::Util::blessed' => 'Banana', 'xyzzy' )

    pkg->install( 'Scalar::Util::blessed' => 'Banana::', 'xyzzy' )

$code can be the same as the two argument form

$into should be:

=over

=item * A package identifier (trailing :: is optional)

    Acme::Xyzzy::

    Acme::Xyzzy

=back

$as should be:

=over

=item * A name (the name of the subroutine)

    xyzzy

    magic

=back

=head2 $package = pkg->name( $part, [ $part, ..., $part ] )

Return a namespace composed by joining each $part with C<::>

Superfluous/redundant C<::> are automatically cleaned up and stripped from the resulting $package

If the first part leads with a C<::>, the the calling package will be prepended to $package

    pkg->name( 'Xy', 'A::', '::B' )      # Xy::A::B
    pkg->name( 'Xy', 'A::' )             # Xy::A::
    
    {
        package Zy;

        pkg->name( '::', 'A::', '::B' )  # Zy::A::B
        pkg->name( '::Xy::A::B' )        # Zy::Xy::A::B
    }

In addition, if any part is blessed, C<name> will resolve that part to the package that the part makes reference to:

    my $object = bless {}, 'Xyzzy';
    pkg->name( $object, qw/ Cfg / );     # Xyzzy::Cfg

=head1 SEE ALSO

L<Sub::Install>

L<Sub::Exporter>

=head1 AUTHOR

Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

