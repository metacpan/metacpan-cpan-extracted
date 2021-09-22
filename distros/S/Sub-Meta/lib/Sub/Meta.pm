package Sub::Meta;
use 5.010;
use strict;
use warnings;

our $VERSION = "0.14";

use Carp ();
use Scalar::Util ();
use Sub::Identify ();
use Sub::Util ();
use attributes ();

use Sub::Meta::Parameters;
use Sub::Meta::Returns;

BEGIN {
    # for Pure Perl
    $ENV{PERL_SUB_IDENTIFY_PP} = $ENV{PERL_SUB_META_PP}; ## no critic (RequireLocalizedPunctuationVars)
}

use overload
    fallback => 1,
    eq => \&is_same_interface
    ;

sub parameters_class { return 'Sub::Meta::Parameters' }
sub returns_class    { return 'Sub::Meta::Returns' }

sub _croak { require Carp; goto &Carp::croak }

sub new {
    my ($class, @args) = @_;

    my %args = @args == 1 && (ref $args[0]||"") ne "HASH" ? _croak "single arg must be hashref"
             : @args == 1 ? %{$args[0]}
             : @args;

    my $self = bless \%args => $class;

    $self->set_sub(delete $args{sub})             if exists $args{sub}; # build subinfo
    $self->set_subname(delete $args{subname})     if exists $args{subname};
    $self->set_stashname(delete $args{stashname}) if exists $args{stashname};
    $self->set_fullname(delete $args{fullname})   if exists $args{fullname};

    $self->set_is_method($self->_normalize_args_is_method(\%args));
    $self->set_parameters($self->_normalize_args_parameters(\%args));
    $self->set_returns($args{returns});

    # cleaning
    delete $args{args};
    delete $args{slurpy};
    delete $args{invocant};
    delete $args{nshift};

    return $self;
}

sub _normalize_args_is_method {
    my ($self, $args) = @_;

    return !!$args->{invocant}             if exists $args->{invocant};
    return !!$args->{nshift}               if exists $args->{nshift};
    return !!$args->{parameters}{nshift}   if exists $args->{parameters} && exists $args->{parameters}{nshift};
    return !!$args->{parameters}{invocant} if exists $args->{parameters} && exists $args->{parameters}{invocant};
    return !!$args->{is_method}            if exists $args->{is_method};
    return !!0;
}

sub _normalize_args_parameters {
    my ($self, $args) = @_;

    if (exists $args->{parameters}) {
        return $args->{parameters};
    }
    else {
        my $nshift = exists $args->{nshift}    ? $args->{nshift}
                   : $self->is_method          ? 1
                   : 0;

        my $parameters;
        $parameters->{args}     = $args->{args}     if exists $args->{args};
        $parameters->{slurpy}   = $args->{slurpy}   if exists $args->{slurpy};
        $parameters->{invocant} = $args->{invocant} if exists $args->{invocant};
        $parameters->{nshift}   = $nshift;
        return $parameters;
    }
}

sub sub() :method { my $self = shift; return $self->{sub} } ## no critic (ProhibitBuiltinHomonyms)
sub subname()     { my $self = shift; return $self->subinfo->[1] // '' }
sub stashname()   { my $self = shift; return $self->subinfo->[0] // '' }
sub fullname()    {
    my $self = shift;
    my $s = '';
    $s .= $self->stashname . '::' if $self->has_stashname;
    $s .= $self->subname          if $self->has_subname;
    return $s;
}

sub subinfo()     {
    my $self = shift;
    return $self->{subinfo} if $self->{subinfo};
    $self->{subinfo} = $self->_build_subinfo;
    return $self->{subinfo};
}

sub file()        { my $self = shift; return $self->{file}        ||= $self->_build_file }
sub line()        { my $self = shift; return $self->{line}        ||= $self->_build_line }
sub prototype() :method { my $self = shift; return $self->{prototype}   ||= $self->_build_prototype } ## no critic (ProhibitBuiltinHomonyms)
sub attribute()   { my $self = shift; return $self->{attribute}   ||= $self->_build_attribute }
sub is_constant() { my $self = shift; return $self->{is_constant} ||= !!$self->_build_is_constant }
sub is_method()   { my $self = shift; return !!$self->{is_method} }
sub parameters()  { my $self = shift; return $self->{parameters} }
sub returns()     { my $self = shift; return $self->{returns} }

sub args()        { my $self = shift; return $self->parameters->args }
sub all_args()    { my $self = shift; return $self->parameters->all_args }
sub slurpy()      { my $self = shift; return $self->parameters->slurpy }
sub nshift()      { my $self = shift; return $self->parameters->nshift }
sub invocant()    { my $self = shift; return $self->parameters->invocant }
sub invocants()   { my $self = shift; return $self->parameters->invocants }

sub has_sub()        { my $self = shift; return defined $self->{sub} }
sub has_subname()    { my $self = shift; return defined $self->subinfo->[1] }
sub has_stashname()  { my $self = shift; return defined $self->subinfo->[0] }
sub has_prototype()  { my $self = shift; return !!$self->prototype } # after build_prototype
sub has_attribute()  { my $self = shift; return !!$self->attribute } # after build_attribute
sub has_file()       { my $self = shift; return defined $self->{file} }
sub has_line()       { my $self = shift; return defined $self->{line} }

sub set_sub {
    my ($self, $v) = @_;
    $self->{sub} = $v;
    Scalar::Util::weaken($self->{sub});

    # rebuild
    for (qw/subinfo file line prototype attribute is_constant/) {
        delete $self->{$_};
        $self->$_;
    }
    return $self;
}

sub set_subname   { my ($self, $v) = @_; $self->{subinfo}[1]  = $v; return $self }
sub set_stashname { my ($self, $v) = @_; $self->{subinfo}[0]  = $v; return $self }
sub set_fullname  {
    my ($self, $v) = @_;
    $self->set_subinfo($v =~ m!^(.+)::([^:]+)$! ? [$1, $2] : []);
    return $self;
}
sub set_subinfo {
    my ($self, $args) = @_;
    $self->{subinfo} = [ $args->[0], $args->[1] ];
    return $self;
}

sub set_file        { my ($self, $v) = @_; $self->{file}        = $v; return $self }
sub set_line        { my ($self, $v) = @_; $self->{line}        = $v; return $self }
sub set_is_constant { my ($self, $v) = @_; $self->{is_constant} = $v; return $self }
sub set_prototype   { my ($self, $v) = @_; $self->{prototype}   = $v; return $self }
sub set_attribute   { my ($self, $v) = @_; $self->{attribute}   = $v; return $self }
sub set_is_method   { my ($self, $v) = @_; $self->{is_method}   = $v; return $self }

sub set_parameters {
    my ($self, @args) = @_;
    my $v = $args[0];
    if (Scalar::Util::blessed($v)) {
        if ($v->isa('Sub::Meta::Parameters')) {
            $self->{parameters} = $v
        }
        else {
            _croak('object must be Sub::Meta::Parameters');
        }
    }
    else {
        $self->{parameters} = $self->parameters_class->new(@args);
    }
    return $self
}

sub set_args {
    my ($self, $args) = @_;
    $self->parameters->set_args($args);
    return $self;
}

sub set_slurpy {
    my ($self, @args) = @_;
    $self->parameters->set_slurpy(@args);
    return $self;
}

sub set_nshift {
    my ($self, $v) = @_;
    if ($self->is_method && $v == 0) {
        _croak 'nshift of method cannot be zero';
    }
    $self->parameters->set_nshift($v);
    return $self;
}

sub set_invocant {
    my ($self, $v) = @_;
    $self->parameters->set_invocant($v);
    return $self;
}

sub set_returns {
    my ($self, @args) = @_;
    my $v = $args[0];
    if (Scalar::Util::blessed($v) && $v->isa('Sub::Meta::Returns')) {
        $self->{returns} = $v
    }
    else {
        $self->{returns} = $self->returns_class->new(@args);
    }
    return $self
}

sub _build_subinfo     {
    my $self = shift;
    return [] unless $self->has_sub;
    my @info = Sub::Identify::get_code_info($self->sub);
    return [ $info[0], $info[1] eq '__ANON__' ? undef : $info[1] ];
}

sub _build_file        { my $self = shift; return $self->sub ? (Sub::Identify::get_code_location($self->sub))[0] : undef }
sub _build_line        { my $self = shift; return $self->sub ? (Sub::Identify::get_code_location($self->sub))[1] : undef }
sub _build_is_constant { my $self = shift; return $self->sub ? Sub::Identify::is_sub_constant($self->sub) : undef }
sub _build_prototype   { my $self = shift; return $self->sub ? Sub::Util::prototype($self->sub) : undef }
sub _build_attribute   { my $self = shift; return $self->sub ? [ attributes::get($self->sub) ] : undef }

sub apply_subname {
    my ($self, $subname) = @_;
    _croak 'apply_subname requires subroutine reference' unless $self->sub;
    $self->set_subname($subname);
    Sub::Util::set_subname($self->fullname, $self->sub);
    return $self;
}

sub apply_prototype {
    my ($self, $prototype) = @_;
    _croak 'apply_prototype requires subroutine reference' unless $self->sub;
    Sub::Util::set_prototype($prototype, $self->sub);
    $self->set_prototype($prototype);
    return $self;
}

sub apply_attribute {
    my ($self, @attribute) = @_;
    _croak 'apply_attribute requires subroutine reference' unless $self->sub;
    {
        no warnings qw(misc); ## no critic (ProhibitNoWarnings)
        attributes->import($self->stashname, $self->sub, @attribute);
    }
    $self->set_attribute($self->_build_attribute);
    return $self;
}

sub apply_meta {
    my ($self, $other) = @_;

    $self->apply_subname($other->subname);
    $self->apply_prototype($other->prototype);
    $self->apply_attribute(@{$other->attribute});

    return $self;
}

sub is_same_interface {
    my ($self, $other) = @_;

    return unless Scalar::Util::blessed($other) && $other->isa('Sub::Meta');

    if ($self->has_subname) {
        return unless $self->subname eq $other->subname
    }
    else {
        return if $other->has_subname;
    }

    return unless $self->is_method eq $other->is_method;

    return unless $self->parameters->is_same_interface($other->parameters);

    return unless $self->returns->is_same_interface($other->returns);

    return !!1;
}

sub is_strict_same_interface;
*is_strict_same_interface = \&is_same_interface;

sub is_relaxed_same_interface {
    my ($self, $other) = @_;

    return unless Scalar::Util::blessed($other) && $other->isa('Sub::Meta');

    if ($self->has_subname) {
        return unless $self->subname eq $other->subname
    }

    return unless $self->is_method eq $other->is_method;

    return unless $self->parameters->is_relaxed_same_interface($other->parameters);

    return unless $self->returns->is_relaxed_same_interface($other->returns);

    return !!1;
}

sub is_same_interface_inlined {
    my ($self, $v) = @_;

    my @src;

    push @src => sprintf("Scalar::Util::blessed(%s) && %s->isa('Sub::Meta')", $v, $v);

    push @src => $self->has_subname ? sprintf("'%s' eq %s->subname", $self->subname, $v)
                                    : sprintf('!%s->has_subname', $v);

    push @src => sprintf("'%s' eq %s->is_method", $self->is_method, $v);

    push @src => $self->parameters->is_same_interface_inlined(sprintf('%s->parameters', $v));

    push @src => $self->returns->is_same_interface_inlined(sprintf('%s->returns', $v));

    return join "\n && ", @src;
}

sub is_strict_same_interface_inlined;
*is_strict_same_interface_inlined = \&is_same_interface_inlined;

sub is_relaxed_same_interface_inlined {
    my ($self, $v) = @_;

    my @src;

    push @src => sprintf("Scalar::Util::blessed(%s) && %s->isa('Sub::Meta')", $v, $v);

    push @src => sprintf("'%s' eq %s->subname", $self->subname, $v) if $self->has_subname;

    push @src => sprintf("'%s' eq %s->is_method", $self->is_method, $v);

    push @src => $self->parameters->is_relaxed_same_interface_inlined(sprintf('%s->parameters', $v));

    push @src => $self->returns->is_relaxed_same_interface_inlined(sprintf('%s->returns', $v));

    return join "\n && ", @src;
}

sub error_message {
    my ($self, $other) = @_;

    return sprintf('other must be Sub::Meta. got: %s', $other // 'Undef')
        unless Scalar::Util::blessed($other) && $other->isa('Sub::Meta');

    if ($self->has_subname) {
        return sprintf('invalid subname. got: %s, expected: %s', $other->subname, $self->subname)
            unless $self->subname eq $other->subname
    }
    else {
        return sprintf('should not have subname. got: %s', $other->subname) if $other->has_subname;
    }

    return 'invalid method'
        unless $self->is_method eq $other->is_method;

    return "invalid parameters: " . $self->parameters->error_message($other->parameters)
        unless $self->parameters->is_same_interface($other->parameters);

    return "invalid returns: " . $self->returns->error_message($other->returns)
        unless $self->returns->is_same_interface($other->returns);

    return '';
}

sub relaxed_error_message {
    my ($self, $other) = @_;

    return sprintf('other must be Sub::Meta. got: %s', $other // 'Undef')
        unless Scalar::Util::blessed($other) && $other->isa('Sub::Meta');

    if ($self->has_subname) {
        return sprintf('invalid subname. got: %s, expected: %s', $other->subname, $self->subname)
            unless $self->subname eq $other->subname
    }

    return 'invalid method'
        unless $self->is_method eq $other->is_method;

    return "invalid parameters: " . $self->parameters->relaxed_error_message($other->parameters)
        unless $self->parameters->is_relaxed_same_interface($other->parameters);

    return "invalid returns: " . $self->returns->relaxed_error_message($other->returns)
        unless $self->returns->is_relaxed_same_interface($other->returns);

    return '';
}

sub display {
    my $self = shift;

    my $keyword = $self->is_method ? 'method' : 'sub';
    my $subname = $self->subname;

    my $s = $keyword;
    $s .= ' ' . $subname if $subname;
    $s .= '('. $self->parameters->display .')';
    $s .= ' => ' . $self->returns->display;
    return $s;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sub::Meta - handle subroutine meta information

=head1 SYNOPSIS

    use Sub::Meta;

    sub hello($) :method { }
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
    $meta->display     # 'sub hello'

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

Another way to create a Sub::Meta is to use L<Sub::Meta::Creator>:

    use Sub::Meta::Creator;
    use Sub::Meta::Finder::FunctionParameters;

    my $creator = Sub::Meta::Creator->new(
        finders => [ \&Sub::Meta::Finder::FunctionParameters::find_materials ],
    );

    use Function::Parameters;
    use Types::Standard -types;

    method hello(Str $msg) { }
    my $meta = $creator->create(\&hello);
    # =>
    # Sub::Meta
    #   args [
    #       [0] Sub::Meta::Param->new(name => '$msg', type => Str)
    #   ],
    #   invocant   Sub::Meta::Param->(name => '$self', invocant => 1),
    #   nshift     1,
    #   slurpy     !!0

=head2 ACCESSORS

=head3 sub

Accessor for subroutine.

=over

=item C<< sub >>

    method sub() => Maybe[CodeRef]

Return a subroutine.

=item C<< has_sub >>

    method has_sub() => Bool

Whether Sub::Meta has subroutine or not.

=item C<< set_sub($sub) >>

    method set_sub(CodeRef $sub) => $self

Setter for subroutine.

    sub hello { ... }
    $meta->set_sub(\&hello);
    $meta->sub # => \&hello

    # And set subname, stashname
    $meta->subname; # hello
    $meta->stashname; # main

=back

=head3 subname

Accessor for subroutine name

=over

=item C<< subname >>

    method subname() => Str

=item C<< has_subname >>

    method has_subname() => Bool

Whether Sub::Meta has subroutine name or not.

=item C<< set_subname($subname) >>

    method set_subname(Str $subname) => $self

Setter for subroutine name.

    $meta->subname; # hello
    $meta->set_subname('world');
    $meta->subname; # world
    Sub::Util::subname($meta->sub); # hello (NOT apply to sub)

=item C<< apply_subname($subname) >>

    method apply_subname(Str $subname) => $self

Sets subroutine name and apply to the subroutine reference.

    $meta->subname; # hello
    $meta->apply_subname('world');
    $meta->subname; # world
    Sub::Util::subname($meta->sub); # world

=back

=head3 fullname

Accessor for subroutine full name

=over

=item C<< fullname >>

    method fullname() => Str

A subroutine full name, e.g. C<main::hello>

=item C<< has_fullname >>

    method has_fullname() => Bool

Whether Sub::Meta has subroutine full name or not.

=item C<< set_fullname($fullname) >>

    method set_fullname(Str $fullname) => $self

Setter for subroutine full name.

=back

=head3 stashname

Accessor for subroutine stash name

=over

=item C<< stashname >>

    method stashname() => Str

A subroutine stash name, e.g. C<main>

=item C<< has_stashname >>

    method has_stashname() => Bool

Whether Sub::Meta has subroutine stash name or not.

=item C<< set_stashname($stashname) >>

    method set_stashname(Str $stashname) => $self

Setter for subroutine stash name.

=back

=head3 subinfo

Accessor for subroutine information

=over

=item C<< subinfo >>

    method subinfo() => Tuple[Str,Str]

A subroutine information, e.g. C<['main', 'hello']>

=item C<< set_subinfo([$stashname, $subname]) >>

    method set_stashname(Tuple[Str $stashname, Str $subname]) => $self

Setter for subroutine information.

=back

=head3 file, line

Accessor for filename and line where subroutine is defined

=over

=item C<< file >>

    method file() => Maybe[Str]

A filename where subroutine is defined, e.g. C<path/to/main.pl>.

=item C<< has_file >>

    method has_file() => Bool

Whether Sub::Meta has a filename where subroutine is defined.

=item C<< set_file($filepath) >>

    method set_file(Str $filepath) => $self

Setter for C<file>.

=item C<< line >>

    method line() => Maybe[Int]

A line where the definition of subroutine started, e.g. C<5>

=item C<< has_line >>

    method has_line() => Bool

Whether Sub::Meta has a line where the definition of subroutine started.

=item C<< set_line($line) >>

    method set_line(Int $line) => $self

Setter for C<line>.

=back

=head3 is_constant

=over

=item C<< is_constant >>

    method is_constant() => Maybe[Bool]

If the subroutine is set, it returns whether it is a constant or not, if not set, it returns undef.

=item C<< set_is_constant($bool) >>

    method set_is_constant(Bool $bool) => $self

Setter for C<is_constant>.

=back

=head3 prototype

Accessor for prototype of subroutine reference.

=over

=item C<< prototype >>

    method prototype() => Maybe[Str]

If the subroutine is set, it returns a prototype of subroutine, if not set, it returns undef.
e.g. C<$@>

=item C<< has_prototype >>

    method has_prototype() => Bool

Whether Sub::Meta has prototype or not.

=item C<< set_prototype($prototype) >>

    method set_prototype(Str $prototype) => $self

Setter for C<prototype>.

=item C<< apply_prototype($prototype) >>

    method apply_prototype(Str $prototype) => $self

Sets subroutine prototype and apply to the subroutine reference.

=back

=head3 attribute

Accessor for attribute of subroutine reference.

=over

=item C<< attribute >>

    method attribute() => Maybe[ArrayRef[Str]]

If the subroutine is set, it returns a attribute of subroutine, if not set, it returns undef.
e.g. C<['method']>, C<undef>

=item C<< has_attribute >>

    method has_attribute() => Bool

Whether Sub::Meta has attribute or not.

=item C<< set_attribute($attribute) >>

    method set_attribute(ArrayRef[Str] $attribute) => $self

Setter for C<attribute>.

=item C<< apply_attribute(@attribute) >>

    method apply_attribute(Str @attribute) => $self

Sets subroutine attributes and apply to the subroutine reference.

=back

=head3 is_method

=over

=item C<< is_method >>

    method is_method() => Bool

Whether the subroutine is a method or not.

=item C<< set_is_method($bool) >>

    method set_is_method(Bool $bool) => Bool

Setter for C<is_method>.

=back

=head3 parameters

Accessor for parameters object of L<Sub::Meta::Parameters>

=over

=item C<< parameters >>

    method parameters() => InstanceOf[Sub::Meta::Parameters]

If the parameters is set, it returns the parameters object.

=item C<< set_parameters($parameters) >>

    method set_parameters(InstanceOf[Sub::Meta::Parameters] $parameters) => $self
    method set_parameters(@sub_meta_parameters_args) => $self

Sets the parameters object of L<Sub::Meta::Parameters>.

    my $meta = Sub::Meta->new;

    my $parameters = Sub::Meta::Parameters->new(args => ['Str']);
    $meta->set_parameters($parameters);

    # or
    $meta->set_parameters(args => ['Str']);
    $meta->parameters; # => Sub::Meta::Parameters->new(args => ['Str']);

    # alias
    $meta->set_args(['Str']);

=item C<< args >>

The alias of C<parameters.args>.

=item C<< set_args($args) >>

The alias of C<parameters.set_args>.

=item C<< all_args >>

The alias of C<parameters.all_args>.

=item C<< nshift >>

The alias of C<parameters.nshift>.

=item C<< set_nshift($nshift) >>

The alias of C<parameters.set_nshift>.

=item C<< invocant >>

The alias of C<parameters.invocant>.

=item C<< invocants >>

The alias of C<parameters.invocants>.

=item C<< set_invocant($invocant) >>

The alias of C<parameters.set_invocant>.

=item C<< slurpy >>

The alias of C<parameters.slurpy>.

=item C<< set_slurpy($slurpy) >>

The alias of C<parameters.set_slurpy>.

=back

=head3 returns

Accessor for returns object of L<Sub::Meta::Returns>

=over

=item C<< returns >>

    method returns() => InstanceOf[Sub::Meta::Returns]

If the returns is set, it returns the returns object.

=item C<< set_returns($returns) >>

    method set_returns(InstanceOf[Sub::Meta::Returns] $returns) => $self
    method set_returns(@sub_meta_returns_args) => $self

Sets the returns object of L<Sub::Meta::Returns> or any object.

    my $meta = Sub::Meta->new;
    $meta->set_returns({ type => 'Type'});
    $meta->returns; # => Sub::Meta::Returns->new({type => 'Type'});

    # or
    $meta->set_returns(Sub::Meta::Returns->new(type => 'Foo'));
    $meta->set_returns(MyReturns->new)

=back

=head2 METHODS

=head3 apply_meta($other_meta)

    method apply_meta(InstanceOf[Sub::Meta] $other_meta) => $self

Apply subroutine subname, prototype and attributes of C<$other_meta>.

=head3 is_same_interface($other_meta)

    method is_same_interface(InstanceOf[Sub::Meta] $other_meta) => Bool

A boolean value indicating whether the subroutine's interface is same or not.
Specifically, check whether C<subname>, C<is_method>, C<parameters> and C<returns> are equal.

=head3 is_strict_same_interface($other_meta)

Alias for C<is_same_interface>

=head3 is_relaxed_same_interface($other_meta)

    method is_relaxed_same_interface(InstanceOf[Sub::Meta] $other_meta) => Bool

A boolean value indicating whether the subroutine's interface is relaxed same or not.
Specifically, check whether C<subname>, C<is_method>, C<parameters> and C<returns> satisfy
the condition of C<$self> side.

=head4 Difference between C<strict> and C<relaxed>

If it is C<is_relaxed_same_interface> method, the conditions can be many.
For example, the number of arguments can be many.
The following code is a test to show the difference between strict and relaxed.

    my @tests = (
        {},                { subname => 'foo' },
        {},                { args => [Int] },
        { args => [Int] }, { args => [Int, Str] },
        { args => [Int] }, { args => [Int], slurpy => Str },
        { args => [Int] }, { args => [{ type => Int, name => '$a' }] },
        {},                { returns => Int },
        { returns => { scalar => Int } }, { returns => { scalar => Int, list => Int } },
    );

    while (@tests) {
        my ($a, $b) = splice @tests, 0, 2;
        my $meta = Sub::Meta->new($a);
        my $other = Sub::Meta->new($b);

        ok !$meta->is_strict_same_interface($other);
        ok $meta->is_relaxed_same_interface($other);
    }

=head3 is_same_interface_inlined($other_meta_inlined)

    method is_same_interface_inlined(InstanceOf[Sub::Meta] $other_meta) => Str

=head3 is_strict_same_interface_inlined($other_meta)

Alias for C<is_same_interface_inlined>

Returns inlined C<is_same_interface> string:

    use Sub::Meta;
    my $meta = Sub::Meta->new(subname => 'hello');
    my $inline = $meta->is_same_interface_inlined('$_[0]');
    # $inline looks like this:
    #    Scalar::Util::blessed($_[0]) && $_[0]->isa('Sub::Meta')
    #    && defined $_[0]->subname && 'hello' eq $_[0]->subname
    #    && !$_[0]->is_method
    #    && !$_[0]->parameters
    #    && !$_[0]->returns
    my $check = eval "sub { $inline }";
    $check->(Sub::Meta->new(subname => 'hello')); # => OK
    $check->(Sub::Meta->new(subname => 'world')); # => NG

=head3 is_relaxed_same_interface_inlined($other_meta_inlined)

    method is_relaxed_same_interface_inlined(InstanceOf[Sub::Meta] $other_meta) => Str

Returns inlined C<is_relaxed_same_interface> string.

=head3 error_message($other_meta)

    method error_message(InstanceOf[Sub::Meta] $other_meta) => Str

Return the error message when the interface is not same. If same, then return empty string

=head3 relaxed_error_message($other_meta)

    method relaxed_error_message(InstanceOf[Sub::Meta] $other_meta) => Str

Return the error message when the interface does not satisfy the C<$self> meta. If match, then return empty string.

=head3 display

    method display() => Str

Returns the display of Sub::Meta:

    use Sub::Meta;
    use Types::Standard qw(Str);
    my $meta = Sub::Meta->new(
        subname => 'hello',
        is_method => 1,
        args => [Str],
        returns => Str,
    );
    $meta->display;  # 'method hello(Str) => Str'

=head2 OTHERS

=head3 parameters_class

    method parameters_class() => Str

Returns class name of parameters. default: Sub::Meta::Parameters
Please override for customization.

=head3 returns_class

    method returns_class() => Str

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

L<Sub::Identify>, L<Sub::Util>, L<Sub::Info>

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut

