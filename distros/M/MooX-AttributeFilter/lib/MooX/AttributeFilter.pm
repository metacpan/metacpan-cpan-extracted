# ABSTRACT: Implements 'filter' option for Moo-class attributes


package MooX::AttributeFilter;
use v5.10;
use strictures 1;

our $VERSION = '0.002002';

use Carp;
use Scalar::Util qw<looks_like_number>;
use Class::Method::Modifiers qw(install_modifier);
use Sub::Quote qw<quotify>;
require Method::Generate::Accessor;

my %filterClasses;

sub _generate_filter_source {
    my $this = shift;
    my ( $me, $name, $spec, $source ) = @_;

    if ( $spec->{filter} && $spec->{filter_sub} ) {
        $this->{captures}{ '$filter_for_' . $name } = \$spec->{filter_sub};
        $source =
          $this->_generate_call_code( $name, 'filter', "${me}, ${source}",
            $spec->{filter_sub} );
    }

    return $source;
}

install_modifier "Method::Generate::Accessor", 'around', '_generate_core_set',
  sub {
    my $orig = shift;
    my $this = shift;
    my ( $me, $name, $spec, $source ) = @_;

    unless ( $spec->{".filter_dont_generate"} ) {
        $source = _generate_filter_source( $this, $me, $name, $spec, $source );
    }

    return $orig->( $this, $me, $name, $spec, $source );
  };

install_modifier "Method::Generate::Accessor", 'around', 'is_simple_set', sub {
    my $orig = shift;
    my $this = shift;
    my ( $name, $spec ) = @_;
    return $orig->( $this, @_ ) && !( $spec->{filter} && $spec->{filter_sub} );
};

install_modifier "Method::Generate::Accessor", 'around',
  '_generate_use_default', sub {
    my $orig = shift;
    my $this = shift;
    my ( $me, $name, $spec, $test ) = @_;

    # Prevent double generation for lazy attributes with default/builder.
    $spec->{'.filter_dont_generate'} = 1;
    return $orig->( $this, @_ );
  };

install_modifier "Method::Generate::Accessor", 'around',
  '_generate_get_default', sub {
    my $orig = shift;
    my $this = shift;
    my ( $me, $name, $spec ) = @_;

    my $default = $orig->( $this, $me, $name, $spec );

    return _generate_filter_source( $this, $me, $name, $spec, $default );
  };

install_modifier "Method::Generate::Accessor", 'around',
  '_generate_populate_set', sub {
    my $orig = shift;
    my $this = shift;
    my ( $me, $name, $spec, $source, $test, $init_arg ) = @_;
    local $spec->{".filter_dont_generate"} = 1;

    if ( !$this->has_eager_default( $name, $spec ) ) {
        $source = _generate_filter_source( $this, $me, $name, $spec, $source );
    }

    return $orig->( $this, $me, $name, $spec, $source, $test, $init_arg );
  };

install_modifier "Method::Generate::Accessor", 'around', '_generate_set', sub {
    my $orig = shift;
    my $this = shift;
    my ( $name, $spec ) = @_;
    local $spec->{".filter_dont_generate"} = 1;

    my $rc = $orig->( $this, @_ );

    return $rc unless $spec->{filter} && $spec->{filter_sub};

    my $capName = '$filter_for_' . $name;

    # Call to the filter was generated already.
    unless ( $this->{captures}{$capName} ) {

        # Work around Method::Generate::Accessor limitation: it predefines
        # source as being $_[1] only and not acceping any argument to define it
        # externally. For this purpose the only solution we have is to wrap it
        # into a sub and pass the filter as sub's argument.

        my $name_str = quotify $name;
        $rc = "sub { $rc }->( \$_[0], "
          . $this->_generate_call_code( $name, 'filter',
            "\$_[0], \$_[1], \$_[0]->{${name_str}}",
            $spec->{filter_sub} )
          . " )";
    }

    return $rc;
};

install_modifier "Method::Generate::Accessor", 'around', 'generate_method',
  sub {
    my $orig = shift;
    my $this = shift;
    my ( $into, $name, $spec, $quote_opts ) = @_;

    if ( $filterClasses{$into} && $spec->{filter} ) {

        croak "Incompatibe 'is' option '$spec->{is}': can't install filter"
          unless $spec->{is} =~ /^rwp?$/;

        my $filterSub;
        if ( $spec->{filter} eq 1 ) {
            $filterSub = "_filter_${name}";
        }
        else {
            $filterSub = $spec->{filter};
        }

        #        $spec->{filter} = 1;

        croak "Attribute '$name' filter option has invalid value"
          if ref($filterSub) && ref($filterSub) ne 'CODE';

        my $filterCode = ref($filterSub) ? $filterSub : $into->can($filterSub);

        croak
          "No filter method '$filterSub' defined for $into attribute '$name'"
          unless $filterCode;

        $spec->{filter_sub} = $filterCode;
    }

    return $orig->( $this, @_ );
  };

sub import {
    my ($class) = @_;
    my $target = caller;

    my $trait =
         Role::Tiny->can('is_role')
      && Role::Tiny->is_role($target)
      ? 'MooseX::AttributeFilter::Trait::Attribute::Role'
      : 'MooseX::AttributeFilter::Trait::Attribute';

    $filterClasses{$target} = 1;
    install_modifier $target, 'around', 'has', sub {
        my $orig = shift;
        my ( $attr, %opts ) = @_;
        return $orig->( $attr, %opts ) unless $opts{filter};
        $opts{moosify} ||= [];
        push @{ $opts{moosify} }, sub {
            my ($spec) = @_;
            require    # hide from CPANTS
              MooseX::AttributeFilter;
            $spec->{traits} ||= [];
            $spec->{bypass_filter_method_check} = 1;
            push @{ $spec->{traits} }, $trait;
        };
        $orig->( $attr, %opts );
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooX::AttributeFilter - Implements 'filter' option for Moo-class attributes

=head1 VERSION

version 0.002002

=head1 SYNOPSIS

    package My::Class;
    use Moo;
    use MooX::AttributeFilter;
    
    has field => (
        is     => 'rw',
        filter => 'filterField',
    );
    
    has lazyField => (
        is      => 'rw',
        lazy    => 1,
        builder => sub { [1, 2, 3 ] },
        filter  => 1,
    );
    
    has incremental => (
        is => 'rw',
        filter => sub {
            my $this = shift;
            my ($val, $oldVal) = @_;
            if ( @_ > 1 && defined $oldVal ) {
                die "incremental attribute value may only increase"
                    unless $val > $oldVal;
            }
            return $_[0];
        }
    );
    
    sub filterField {
        my $this = shift;
        return "filtered($_[0])";
    }
    
    sub _filter_lazyField {
        my $this = shift;
        my @a = @{$_[0]};
        push @a, -1;
        return \@a;
    }
    
    package main;
    my $obj = My::Class->new( field => "initial" );
    ($obj->field eq "filtered(initial)")  # True!
    $obj->lazyField;                      # [ 1, 2, 3, -1 ]
    $obj->field( "value" );               # "filtered(value)"
    $obj->incremental( -1 );              # -1
    $obj->incremental( 10 );              # 10
    $obj->incremental( 9 );               # dies...
    
    $obj = My::Class->new( incremental => 1 ); # incremental is set to 1
    $obj->incremental( 0 );                    # dies too.

=head1 DESCRIPTION

The idea behind this extension is to overcome the biggest deficiency of
coercion: its ignorance about the object it is acting for. While triggers are
executed as methods, they don't receive the previous attribute value; and
they're called after the attribute is set.

Filter is a method which is called right before attribute value is about to be
set. It receives one or two arguments of which the first is the new attribute
value; the second is the old value. Number of arguments passed depends on
what stage the filter get called at: one is for the construction, two is when
set by writer.

B<Note:> When an attribute was never set before and a writer is used then the
old value filter argument will be undefined.

It is also worth mentioning that a filter is called I<always> upon writing a
value into attribute, including initialization from constructor arguments or
lazy builders. See the L</SYNOPSIS>. In both cases the filter gets called with a
single argument.

I.e.:

    package LazyOne {
        use Moo;
        use MooX::AttributeFilter;
        
        has lazyField => (
            is => 'rw',
            lazy => 1,
            default => "value",
            filter => sub {
                my $this = shift;
                say "Arguments: ", scalar(@_);
                return $_[0];
            },
        );
    }
    
    my $obj = LazyOne->new;
    $obj->lazyField;        # Arguments: 1
    $obj->lazyField("foo"); # Arguments: 2
    
    $obj = LazyOne->new( lazyField => "bar" );  # Arguments: 1
    $obj->lazyField( "foobar" );                # Arguments: 2

Filter method must always return a (possibly modified) value.

Filter is called I<before> any other attribute handlers. Its return value is
then subject for passing through C<isa> and C<coerce>.

=head2 Use cases

Filters are of the most use when attribute value (or allowed values) depends on
other attributes of its object (or even other linked objects). The dependency
could be hard (C<isa>-like) – i.e. an exception must be thrown if value doesn't
pass validation. Or it could be soft: by storing a value calling code I<suggest>
what it would like to see in the attribute but the result might be changed
depending on the current environment. For example:

    package ChDir;
    use File::Spec;
    use Moo;
    extends qw<Project::BaseClass>;
    use MooX::AttributeFilter;
    
    has curDir => (
        is => 'rw',
        filter => 'fullPath',
    );
    
    sub fullPath {
        my $this = shift;
        my ( $subdir ) = @_;
        
        return File::Spec->catdir(
            $this->testMode ? $this->baseTestDir : $this->baseDir,
            $subdir
        );
    }
}

=head2 Inflation to Moose

This module inflates into L<MooseX::AttributeFilter>.

=head1 CAVEATS

* The code relies on low-level functionality of Method::Generate family of
  modules. For this reason it may become incompatible with their future versions 
  if they get drastically changed.

=head1 ACKNOWLEDGEMENTS

This work is a result of refusal to include filtering functionality into the Moo
core. Since the refusal was backed by strong reasoning while the functionality
itself is badly wanted there was no other choice but to create the module... So,
my great thanks to Graham Knopp <haarg@haarg.org> for his advises, sample code,
and Moo itself, of course!

My special thanks to Princess Kitten <littleprincess@kittymail.com> who
implemented similar module for Moose framework and made the inflation code
working.

=head1 AUTHOR

Vadim Belman <vrurg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Vadim Belman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
