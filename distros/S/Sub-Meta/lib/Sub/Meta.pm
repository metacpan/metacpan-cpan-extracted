package Sub::Meta;
use 5.010;
use strict;
use warnings;

our $VERSION = "0.05";

use Carp ();
use Scalar::Util ();
use Sub::Identify ();
use Sub::Util ();
use attributes ();

use Sub::Meta::Parameters;
use Sub::Meta::Returns;

BEGIN {
    # for Pure Perl
    $ENV{PERL_SUB_IDENTIFY_PP} = $ENV{PERL_SUB_META_PP};
}

use overload
    fallback => 1,
    eq => \&is_same_interface
    ;

sub parameters_class { 'Sub::Meta::Parameters' }
sub returns_class    { 'Sub::Meta::Returns' }

sub _croak { require Carp; Carp::croak(@_) }

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;

    my $self = bless \%args => $class;

    $self->set_subname(delete $args{subname})     if exists $args{subname};
    $self->set_stashname(delete $args{stashname}) if exists $args{stashname};
    $self->set_fullname(delete $args{fullname})   if exists $args{fullname};

    if (exists $args{parameters}) {
        $self->set_parameters($args{parameters})
    }
    elsif(exists $args{args}) {
        $self->set_parameters(
            args => delete $args{args},
            ( exists $args{slurpy} ? (slurpy => delete $args{slurpy}) : () ),

            ( exists $args{nshift}    ? (nshift => delete $args{nshift}) :
              exists $args{is_method} ? (nshift => $args{is_method} ? 1 : 0) : () ),
        );
    }

    if (exists $args{returns}) {
        $self->set_returns($args{returns})
    }

    return $self;
}

sub sub()         { $_[0]{sub} }
sub subname()     { $_[0]->subinfo->[1] || '' }
sub stashname()   { $_[0]->subinfo->[0] || '' }
sub fullname()    { @{$_[0]->subinfo} ? sprintf('%s::%s', $_[0]->stashname, $_[0]->subname) : '' }
sub subinfo()     {
    return $_[0]{subinfo} if $_[0]{subinfo};
    $_[0]{subinfo} = $_[0]->_build_subinfo
}

sub file()        { $_[0]{file}        ||= $_[0]->_build_file }
sub line()        { $_[0]{line}        ||= $_[0]->_build_line }
sub is_constant() { $_[0]{is_constant} ||= $_[0]->_build_is_constant }
sub prototype()   { $_[0]{prototype}   ||= $_[0]->_build_prototype }
sub attribute()   { $_[0]{attribute}   ||= $_[0]->_build_attribute }
sub is_method()   { !!$_[0]{is_method} }
sub parameters()  { $_[0]{parameters} }
sub returns()     { $_[0]{returns} }
sub args()        { $_[0]->parameters->args }
sub slurpy()      { $_[0]->parameters->slurpy }
sub nshift()      { $_[0]->parameters->nshift }

sub set_sub($)    {
    $_[0]{sub} = $_[1];

    # rebuild subinfo
    delete $_[0]{subinfo};
    $_[0]->subinfo;
    $_[0];
}

sub set_subname($)     { $_[0]{subinfo}[1]  = $_[1]; $_[0] }
sub set_stashname($)   { $_[0]{subinfo}[0]  = $_[1]; $_[0] }
sub set_fullname($)    {
    $_[0]{subinfo} = $_[1] =~ m!^(.+)::([^:]+)$! ? [$1, $2] : [];
    $_[0];
}
sub set_subinfo($)     {
    $_[0]{subinfo} = @_ > 2 ? [ $_[1], $_[2] ] : $_[1];
    $_[0];
}

sub set_file($)        { $_[0]{file}        = $_[1]; $_[0] }
sub set_line($)        { $_[0]{line}        = $_[1]; $_[0] }
sub set_is_constant($) { $_[0]{is_constant} = $_[1]; $_[0] }
sub set_prototype($)   { $_[0]{prototype}   = $_[1]; $_[0] }
sub set_attribute($)   { $_[0]{attribute}   = $_[1]; $_[0] }
sub set_is_method($)   { $_[0]{is_method}   = $_[1]; $_[0] }

sub set_parameters {
    my $self = shift;
    my $v = $_[0];
    if (Scalar::Util::blessed($v)) {
        if ($v->isa('Sub::Meta::Parameters')) {
            $self->{parameters} = $v
        }
        else {
            _croak('object must be Sub::Meta::Parameters');
        }
    }
    else {
        $self->{parameters} = $self->parameters_class->new(@_);
    }
    return $self
}

sub set_args {
    my $self = shift;
    if ($self->parameters) {
        $self->parameters->set_args(@_);
    }
    else {
        $self->set_parameters($self->parameters_class->new(args => @_));
    }
    return $self;
}

sub set_slurpy {
    my $self = shift;
    $self->parameters->set_slurpy(@_);
    return $self;
}

sub set_nshift {
    my $self = shift;
    if ($self->is_method && $_[0] == 0) {
        _croak 'nshift of method cannot be zero';
    }
    $self->parameters->set_nshift(@_);
    return $self;
}

sub set_returns {
    my $self = shift;
    my $v = $_[0];
    if (Scalar::Util::blessed($v) && $v->isa('Sub::Meta::Returns')) {
        $self->{returns} = $v
    }
    else {
        $self->{returns} = $self->returns_class->new(@_);
    }
    return $self
}

sub _build_subinfo()     { $_[0]->sub ? [ Sub::Identify::get_code_info($_[0]->sub) ] : [] }
sub _build_file()        { $_[0]->sub ? (Sub::Identify::get_code_location($_[0]->sub))[0] : '' }
sub _build_line()        { $_[0]->sub ? (Sub::Identify::get_code_location($_[0]->sub))[1] : undef }
sub _build_is_constant() { $_[0]->sub ? Sub::Identify::is_sub_constant($_[0]->sub) : undef }
sub _build_prototype()   { $_[0]->sub ? Sub::Util::prototype($_[0]->sub) : '' }
sub _build_attribute()   { $_[0]->sub ? [ attributes::get($_[0]->sub) ] : undef }

sub apply_subname($) {
    my ($self, $subname) = @_;
    _croak 'apply_subname requires subroutine reference' unless $self->sub;
    $self->set_subname($subname);
    Sub::Util::set_subname($self->fullname, $self->sub);
    return $self;
}

sub apply_prototype($) {
    my ($self, $prototype) = @_;
    _croak 'apply_prototype requires subroutine reference' unless $self->sub;
    Sub::Util::set_prototype($prototype, $self->sub);
    $self->set_prototype($prototype);
    return $self;
}

sub apply_attribute(@) {
    my ($self, @attribute) = @_;
    _croak 'apply_attribute requires subroutine reference' unless $self->sub;
    {
        no warnings qw(misc);
        attributes->import($self->stashname, $self->sub, @attribute);
    }
    $self->set_attribute($self->_build_attribute);
    return $self;
}

sub is_same_interface {
    my ($self, $other) = @_;
    return unless Scalar::Util::blessed($other) && $other->isa('Sub::Meta');

    if ($self->subname) {
        return if $self->subname ne $other->subname;
    }
    else {
        return if $other->subname;
    }

    if ($self->parameters) {
        return if !($self->parameters->is_same_interface($other->parameters));
    }
    else {
        return if $other->parameters;
    }

    if ($self->returns) {
        return if !($self->returns->is_same_interface($other->returns));
    }
    else {
        return if $other->returns;
    }

    return !!1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sub::Meta - handle subroutine meta information

=head1 SYNOPSIS

    use Sub::Meta;

    sub hello($) :mehtod { }
    my $meta = Sub::Meta->new(sub => \&hello);
    $meta->subname; # => hello

    $meta->sub;        # \&hello
    $meta->subname;    # hello
    $meta->fullname    # main::hello
    $meta->stashname   # main
    $meta->file        # path/to/file.pl
    $meta->line        # 5
    $meta->is_constant # !!0
    $meta->prototype   # $
    $meta->attribute   # ['method']
    $meta->is_method   # undef
    $meta->parameters  # undef
    $meta->returns     # undef

    # setter
    $meta->set_subname('world');
    $meta->subname; # world
    $meta->fullname; # main::world

    # apply to sub
    $meta->apply_prototype('$@');
    $meta->prototype; # $@
    Sub::Util::prototype($meta->sub); # $@

And you can hold meta information of parameter type and return type. See also L<Sub::Meta::Parameters> and L<Sub::Meta::Returns>.

    $meta->set_parameters(args => ['Str']));
    $meta->parameters->args; # [ Sub::Meta::Param->new({ type => 'Str' }) ]
    
    $meta->set_args(['Str']);
    $meta->args; # [ Sub::Meta::Param->new({ type => 'Str' }) ]

    $meta->set_returns('Str');
    $meta->returns->scalar; # 'Str'
    $meta->returns->list;   # 'Str'

And you can compare meta informations:

    my $other = Sub::Meta->new(subname => 'hello');
    $meta->is_same_interface($other); # 1
    $meta eq $other; # 1

=head1 DESCRIPTION

C<Sub::Meta> provides methods to handle subroutine meta information. In addition to information that can be obtained from subroutines using module L<B> etc., subroutines can have meta information such as arguments and return values.

=head1 METHODS

=head2 new

Constructor of C<Sub::Meta>.

    use Sub::Meta;
    use Types::Standard -types;

    # sub Greeting::hello(Str) -> Str
    Sub::Meta->new(
        fullname    => 'Greeting::hello',
        is_constant => 0,
        prototype   => '$',
        attribute   => ['method'],
        is_method   => 1,
        parameters  => { args => [{ type => Str }]},
        returns     => Str,
    );

Others are as follows:

    # sub add(Int, Int) -> Int
    Sub::Meta->new(
        subname => 'add',
        args    => [Int, Int],
        returns => Int,
    );

    # method hello(Str) -> Str 
    Sub::Meta->new(
        subname   => 'hello',
        args      => [{ message => Str }],
        is_method => 1,
        returns   => Str,
    );

    # sub twice(@numbers) -> ArrayRef[Int]
    Sub::Meta->new(
        subname   => 'twice',
        args      => [],
        slurpy    => { name => '@numbers' },
        returns   => ArrayRef[Int],
    );

    # Named parameters:
    # sub foo(Str :a) -> Str
    Sub::Meta->new(
        subname   => 'foo',
        args      => { a => Str },
        returns   => Str,
    );

    # is equivalent to
    Sub::Meta->new(
        subname   => 'foo',
        args      => [{ name => 'a', isa => Str, named => 1 }],
        returns   => Str,
    );

=head2 sub

A subroutine reference.

=head2 set_sub

Setter for subroutine reference.

=head2 subname

A subroutine name, e.g. C<hello>

=head2 set_subname($subname)

Setter for subroutine name.

    $meta->subname; # hello
    $meta->set_subname('world');
    $meta->subname; # world
    Sub::Util::subname($meta->sub); # hello (NOT apply to sub)

=head2 apply_subname($subname)

Sets subroutine name and apply to the subroutine reference.

    $meta->subname; # hello
    $meta->apply_subname('world');
    $meta->subname; # world
    Sub::Util::subname($meta->sub); # world

=head2 fullname

A subroutine full name, e.g. C<main::hello>

=head2 set_fullname($fullname)

Setter for subroutine full name.

=head2 stashname

A subroutine stash name, e.g. C<main>

=head2 set_stashname($stashname)

Setter for subroutine stash name.

=head2 subinfo

A subroutine information, e.g. C<['main', 'hello']>

=head2 set_subinfo([$stashname, $subname])

Setter for subroutine information.

=head2 file

A filename where subroutine is defined, e.g. C<path/to/main.pl>.

=head2 set_file($filepath)

Setter for C<file>.

=head2 line

A line where the definition of subroutine started, e.g. C<5>

=head2 set_line($line)

Setter for C<line>.

=head2 is_constant

A boolean value indicating whether the subroutine is a constant or not.

=head2 set_is_constant($bool)

Setter for C<is_constant>.

=head2 prototype

A prototype of subroutine reference, e.g. C<$@>

=head2 set_prototype($prototype)

Setter for C<prototype>.

=head2 apply_prototype($prototype)

Sets subroutine prototype and apply to the subroutine reference.

=head2 attribute

A attribute of subroutine reference, e.g. C<undef>, C<['method']>

=head2 set_attribute($attribute)

Setter for C<attribute>.

=head2 apply_attribute(@attribute)

Sets subroutine attributes and apply to the subroutine reference.

=head2 is_method

A boolean value indicating whether the subroutine is a method or not.

=head2 set_is_method($bool)

Setter for C<is_method>.

=head2 parameters

Parameters object of L<Sub::Meta::Parameters>.

=head2 set_parameters($parameters)

Sets the parameters object of L<Sub::Meta::Parameters>.

    my $meta = Sub::Meta->new;
    $meta->set_parameters(args => ['Str']);
    $meta->parameters; # => Sub::Meta::Parameters->new(args => ['Str']);

    # or
    $meta->set_parameters(Sub::Meta::Parameters->new(args => ['Str']));

    # alias
    $meta->set_args(['Str']);

=head2 args

The alias of C<parameters.args>.

=head2 set_args($args)

The alias of C<parameters.set_args>.

=head2 nshift

The alias of C<parameters.nshift>.

=head2 set_nshift($nshift)

The alias of C<parameters.set_nshift>.

=head2 slurpy

The alias of C<parameters.slurpy>.

=head2 set_slurpy($slurpy)

The alias of C<parameters.set_slurpy>.

=head2 returns

Returns object of L<Sub::Meta::Returns>.

=head2 set_returns($returns)

Sets the returns object of L<Sub::Meta::Returns> or any object.

    my $meta = Sub::Meta->new;
    $meta->set_returns({ type => 'Type'});
    $meta->returns; # => Sub::Meta::Returns->new({type => 'Type'});

    # or
    $meta->set_returns(Sub::Meta::Returns->new(type => 'Foo'));
    $meta->set_returns(MyReturns->new)

=head2 is_same_interface($other_meta)

A boolean value indicating whether the subroutine's interface is same or not.
Specifically, check whether C<subname>, C<parameters> and C<returns> are equal.

=head2 parameters_class

Returns class name of parameters. default: Sub::Meta::Parameters
Please override for customization.

=head2 returns_class

Returns class name of returns. default: Sub::Meta::Returns
Please override for customization.

=head1 NOTE

=head2 setter

You can set meta information of subroutine. C<set_xxx> sets C<xxx> and does not affect subroutine reference. On the other hands, C<apply_xxx> sets C<xxx> and apply C<xxx> to subroutine reference.

Setter methods of C<Sub::Meta> returns meta object. So you can chain setting:

    $meta->set_subname('foo')
         ->set_stashname('Some')

=head2 Pure-Perl version

By default C<Sub::Meta> tries to load an XS implementation for speed.
If that fails, or if the environment variable C<PERL_SUB_META_PP> is defined to a true value, it will fall back to a pure perl implementation.

=head1 SEE ALSO

L<Sub::Identify>, L<Sub::Util>, L<Sub::Info>, L<Function::Paramters::Info>, L<Function::Return::Info>

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut

