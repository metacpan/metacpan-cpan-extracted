package Object::HashBase;
use strict;
use warnings;

our $VERSION = '0.017';
our $HB_VERSION = $VERSION;
# The next line is for inlining
# <-- START -->

require Carp;
{
    no warnings 'once';
    $Carp::Internal{+__PACKAGE__} = 1;
}

BEGIN {
    {
        # Make sure none of these get messed up.
        local ($SIG{__DIE__}, $@, $?, $!, $^E);
        if (eval { require Class::XSAccessor; Class::XSAccessor->VERSION(1.19); 1 }) {
            *CLASS_XS_ACCESSOR = sub() { 1 }
        }
        else {
            *CLASS_XS_ACCESSOR = sub() { 0 }
        }
    }

    # these are not strictly equivalent, but for out use we don't care
    # about order
    *_isa = ($] >= 5.010 && require mro) ? \&mro::get_linear_isa : sub {
        no strict 'refs';
        my @packages = ($_[0]);
        my %seen;
        for my $package (@packages) {
            push @packages, grep !$seen{$_}++, @{"$package\::ISA"};
        }
        return \@packages;
    }
}

sub _is_role {
    my $pkg = shift;
    return 0 unless $INC{'Role/Tiny.pm'};
    return Role::Tiny->is_role($pkg) ? 1 : 0;
}

my %SPEC = (
    '^' => {reader => 1, writer => 0, dep_writer => 1, read_only => 0, strip => 1},
    '-' => {reader => 1, writer => 0, dep_writer => 0, read_only => 1, strip => 1},
    '>' => {reader => 0, writer => 1, dep_writer => 0, read_only => 0, strip => 1},
    '<' => {reader => 1, writer => 0, dep_writer => 0, read_only => 0, strip => 1},
    '+' => {reader => 0, writer => 0, dep_writer => 0, read_only => 0, strip => 1},
    '~' => {reader => 1, writer => 1, dep_writer => 0, read_only => 0, strip => 1, no_xs => 1},
);

sub spec { \%SPEC }

sub import {
    my $class = shift;
    my $into  = caller;
    $class->do_import($into, @_);
}

sub do_import {
    my $class = shift;
    my $into  = shift;

    # Make sure we list the OLDEST version used to create this class.
    my $ver = $Object::HashBase::HB_VERSION || $Object::HashBase::VERSION;
    $Object::HashBase::VERSION{$into} = $ver if !$Object::HashBase::VERSION{$into} || $Object::HashBase::VERSION{$into} > $ver;

    my (@parents, @roles, @attrs);
    for my $arg (@_) {
        if (defined($arg) && length($arg)) {
            my $p = substr($arg, 0, 1);
            if ($p eq '@') {
                push @parents, substr($arg, 1);
                next;
            }
            if ($p eq '&') {
                push @roles, substr($arg, 1);
                next;
            }
        }
        push @attrs, $arg;
    }

    for my $parent (@parents) {
        my $pm = $parent;
        $pm =~ s{::}{/}g;
        $pm .= '.pm';
        unless ($INC{$pm}) {
            local ($@);
            unless (eval { require $pm; 1 }) {
                Carp::croak("Could not load parent class '$parent': $@");
            }
        }
        no strict 'refs';
        push @{"$into\::ISA"}, $parent unless grep { $_ eq $parent } @{"$into\::ISA"};
    }

    my $isa = _isa($into);
    my $attr_list = $Object::HashBase::ATTR_LIST{$into} ||= [];
    my $attr_subs = $Object::HashBase::ATTR_SUBS{$into} ||= {};

    my @pre_init;
    my @post_init;

    my $add_new = _is_role($into) ? 0 : 1;

    if ($add_new && (my $have_new = $into->can('new'))) {
        my $new_lookup = $Object::HashBase::NEW_LOOKUP //= {};
        $add_new = 0 unless $new_lookup->{$have_new};
    }

    my %subs = (
        ($add_new ? ($class->_build_new($into, \@pre_init, \@post_init)) : ()),
        (map %{$Object::HashBase::ATTR_SUBS{$_} || {}}, @{$isa}[1 .. $#$isa]),
        ($class->args_to_subs($attr_list, $attr_subs, \@attrs, $into)),
    );

    no strict 'refs';
    while (my ($k, $v) = each %subs) {
        if (ref($v) eq 'CODE') {
            *{"$into\::$k"} = $v;
        }
        else {
            my ($sub, @args) = @$v;
            $sub->(@args);
        }
    }

    if (@roles) {
        Carp::croak("Object::HashBase '&' role prefix requires Perl 5.010 or newer (this is $])")
            if $] < 5.010;

        unless ($INC{'Role/Tiny.pm'}) {
            local ($@);
            unless (eval { require Role::Tiny; 1 }) {
                Carp::croak("Object::HashBase '&' role prefix requires Role::Tiny but it could not be loaded: $@");
            }
        }

        unless (Role::Tiny->can('is_role')) {
            Carp::croak("Object::HashBase '&' role prefix requires Role::Tiny 1.003000 or newer (is_role missing)");
        }

        for my $role (@roles) {
            my $pm = $role;
            $pm =~ s{::}{/}g;
            $pm .= '.pm';

            unless ($INC{$pm}) {
                local ($@);
                unless (eval { require $pm; 1 }) {
                    Carp::croak("Could not load role '$role': $@");
                }
            }

            Carp::croak("'$role' is not a Role::Tiny role")
                unless Role::Tiny->is_role($role);

            Carp::croak("'$role' does not use Object::HashBase")
                unless exists $Object::HashBase::VERSION{$role};

            my $role_subs = $Object::HashBase::ATTR_SUBS{$role} || {};

            no strict 'refs';
            for my $const (keys %$role_subs) {
                next if defined &{"$into\::$const"};   # keep existing sub, no override, no warn
                *{"$into\::$const"} = $role_subs->{$const};
            }

            my $role_attr_list = $Object::HashBase::ATTR_LIST{$role} || [];
            push @{$Object::HashBase::ROLE_ATTRS{$into} ||= []}, @$role_attr_list;
        }

        my $key = "Object::HashBase::role_applier::$into";
        my $applier = $^H{$key} ||= Object::HashBase::_RoleApplier->new($into);
        $applier->add($_) for @roles;
    }
}

sub args_to_subs {
    my $class = shift;
    my ($attr_list, $attr_subs, $args, $into) = @_;

    my $use_gen = $class->can('gen_accessor') ;

    my %out;

    while (@$args) {
        my $x = shift @$args;
        my $p = substr($x, 0, 1);

        my $spec = $class->spec->{$p} || {reader => 1, writer => 1};
        substr($x, 0, 1) = '' if $spec->{strip};

        push @$attr_list => $x;
        my ($sub, $attr) = (uc $x, $x);

        $attr_subs->{$sub} = sub() { $attr };
        $out{$sub} = $attr_subs->{$sub};

        my $copy = "$attr";
        if ($spec->{reader}) {
            if ($use_gen) {
                $out{$attr} = $class->gen_accessor(reader => $copy, $spec, $args);
            }
            elsif (CLASS_XS_ACCESSOR && !$spec->{no_xs}) {
                $out{$attr} = [\&Class::XSAccessor::newxs_getter, "$into\::$attr", $copy];
            }
            else {
                $out{$attr} = sub { $_[0]->{$attr} };
            }
        }

        if ($spec->{writer}) {
            if ($use_gen) {
                $out{"set_$attr"} = $class->gen_accessor(writer => $copy, $spec, $args);
            }
            elsif(CLASS_XS_ACCESSOR && !$spec->{no_xs}) {
                $out{"set_$attr"} = [\&Class::XSAccessor::newxs_setter, "$into\::set_$attr", $copy, 0];
            }
            else {
                $out{"set_$attr"} = sub { $_[0]->{$attr} = $_[1] };
            }
        }
        elsif($spec->{read_only}) {
            $out{"set_$attr"} = $use_gen ? $class->gen_accessor(read_only => $copy, $spec, $args) : sub { Carp::croak("'$attr' is read-only") };
        }
        elsif($spec->{dep_writer}) {
            $out{"set_$attr"} = $use_gen ? $class->gen_accessor(dep_writer => $copy, $spec, $args) : sub { Carp::carp("set_$attr() is deprecated"); $_[0]->{$attr} = $_[1] };
        }

        if ($spec->{custom}) {
            my %add = $class->gen_accessor(custom => $copy, $spec, $args);
            $out{$_} = $add{$_} for keys %add;
        }
    }

    return %out;
}

sub attr_list {
    my $class = shift;

    my $isa = _isa($class);

    my %seen;
    my @list;
    for my $pkg (reverse @$isa) {
        if (0.004 > ($Object::HashBase::VERSION{$pkg} || 0)) {
            Carp::carp("$pkg uses an inlined version of Object::HashBase too old to support attr_list()");
            next;
        }
        my $own = $Object::HashBase::ATTR_LIST{$pkg};
        my $role_attrs = $Object::HashBase::ROLE_ATTRS{$pkg} || [];
        for my $a (@$role_attrs, ($own ? @$own : ())) {
            push @list, $a unless $seen{$a}++;
        }
    }

    return @list;
}

sub _build_new {
    my $class = shift;
    my ($into, $pre_init, $post_init) = @_;

    my $add_pre_init  = sub(&) { push @$pre_init  => $_[-1] };
    my $add_post_init = sub(&) { push @$post_init => $_[-1] };

    my $__pre_init = $into->can('_pre_init');
    my $_pre_init  = $__pre_init ? sub { ($__pre_init->(), @$pre_init) } : sub { @$pre_init };

    my $__post_init = $into->can('_post_init');
    my $_post_init  = $__post_init ? sub { ($__post_init->(), @$post_init) } : sub {  @$post_init };

    my $new = sub {
        my $class = shift;

        my $self;

        if (@_ == 1) {
            my $arg  = shift;
            my $type = ref($arg);

            if ($type eq 'HASH') {
                $self = bless({%$arg}, $class);
            }
            else {
                Carp::croak("Not sure what to do with '$type' in $class constructor")
                    unless $type eq 'ARRAY';

                my %proto;
                my @attributes = attr_list($class);
                while (@$arg) {
                    my $val = shift @$arg;
                    my $key = shift @attributes or Carp::croak("Too many arguments for $class constructor");
                    $proto{$key} = $val;
                }

                $self = bless(\%proto, $class);
            }
        }
        else {
            $self = bless({@_}, $class);
        }

        $Object::HashBase::CAN_CACHE{$class} = $self->can('init')
            unless exists $Object::HashBase::CAN_CACHE{$class};

        $self->$_() for $_pre_init->();
        $self->init() if $Object::HashBase::CAN_CACHE{$class};
        $self->$_() for reverse $_post_init->();

        $self;
    };

    my $new_lookup = $Object::HashBase::NEW_LOOKUP //= {};
    $new_lookup->{$new} = 1;

    my %out;

    {
        no strict 'refs';
        $out{new}           = $new           unless defined(&{"${into}\::new"});
        $out{add_pre_init}  = $add_pre_init  unless defined(&{"${into}\::add_pre_init"});
        $out{add_post_init} = $add_post_init unless defined(&{"${into}\::add_post_init"});
        $out{_pre_init}     = $_pre_init     unless defined(&{"${into}\::_pre_init"});
        $out{_post_init}    = $_post_init    unless defined(&{"${into}\::_post_init"});
    }

    return %out;
}

# _RoleApplier — deferred Role::Tiny composition.
#
# Object::HashBase's '&' import prefix copies role constants into the consumer
# eagerly (so `$self->{+FOO}` resolves at compile time), then defers actual
# Role::Tiny->apply_roles_to_package to end of consumer's compile scope by
# storing a blessed object in %^H. Perl destroys %^H entries at end of compile
# scope, triggering DESTROY here, which finally composes the role(s).

package    # hide from PAUSE indexer
    Object::HashBase::_RoleApplier;

sub new {
    my ($class, $into) = @_;
    return bless { into => $into, roles => [] }, $class;
}

sub add {
    my ($self, $role) = @_;
    push @{$self->{roles}}, $role
        unless grep { $_ eq $role } @{$self->{roles}};
}

sub DESTROY {
    my $self = shift;
    return unless @{$self->{roles}};
    local $@;
    my $ok = eval { Role::Tiny->apply_roles_to_package($self->{into}, @{$self->{roles}}); 1 };
    unless ($ok) {
        my $err = $@ || 'unknown error';
        my $into = $self->{into};
        my $roles = join(', ', @{$self->{roles}});
        warn "Object::HashBase: failed to compose role(s) [$roles] into $into: $err";
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Object::HashBase - Build hash based classes.

=head1 SYNOPSIS

A class:

    package My::Class;
    use strict;
    use warnings;

    # Generate 3 accessors
    use Object::HashBase qw/foo -bar ^baz <bat >ban +boo/;

    # Chance to initialize defaults
    sub init {
        my $self = shift;    # No other args
        $self->{+FOO} ||= "foo";
        $self->{+BAR} ||= "bar";
        $self->{+BAZ} ||= "baz";
        $self->{+BAT} ||= "bat";
        $self->{+BAN} ||= "ban";
        $self->{+BOO} ||= "boo";
    }

    sub print {
        my $self = shift;
        print join ", " => map { $self->{$_} } FOO, BAR, BAZ, BAT, BAN, BOO;
    }

Subclass it

    package My::Subclass;
    use strict;
    use warnings;

    # Note, you should subclass before loading HashBase.
    use base 'My::Class';
    use Object::HashBase qw/bub/;

    sub init {
        my $self = shift;

        # We get the constants from the base class for free.
        $self->{+FOO} ||= 'SubFoo';
        $self->{+BUB} ||= 'bub';

        $self->SUPER::init();
    }

use it:

    package main;
    use strict;
    use warnings;
    use My::Class;

    # These are all functionally identical
    my $one   = My::Class->new(foo => 'MyFoo', bar => 'MyBar');
    my $two   = My::Class->new({foo => 'MyFoo', bar => 'MyBar'});
    my $three = My::Class->new(['MyFoo', 'MyBar']);

    # Readers!
    my $foo = $one->foo;    # 'MyFoo'
    my $bar = $one->bar;    # 'MyBar'
    my $baz = $one->baz;    # Defaulted to: 'baz'
    my $bat = $one->bat;    # Defaulted to: 'bat'
    # '>ban' means setter only, no reader
    # '+boo' means no setter or reader, just the BOO constant

    # Setters!
    $one->set_foo('A Foo');

    #'-bar' means read-only, so the setter will throw an exception (but is defined).
    $one->set_bar('A bar');

    # '^baz' means deprecated setter, this will warn about the setter being
    # deprecated.
    $one->set_baz('A Baz');

    # '<bat' means no setter defined at all
    # '+boo' means no setter or reader, just the BOO constant

    $one->{+FOO} = 'xxx';

Add pre_init and post-init:

B<Note:> These are not provided if you define your own new() method (via a stub
at the top).

B<Note:> Single inheritence should work with child classes doing the pre/post
init subs during construction, so long as all classes in the chain use a
generated new(). This will probably explode badly in multiple-inheritence.

    package My::Class;
    use strict;
    use warnings;

    # Generate 3 accessors
    use Object::HashBase qw/foo -bar ^baz <bat >ban +boo/;

    # Do more stuff before init, add as many as you like by calling this
    # multiple times with a different code block each time
    add_pre_init {
        ...
    };

    # Chance to initialize defaults
    sub init { ... }

    # Do stuff after init, add as many as you want, they run in reverse order
    add_post_init {
        my $self = shift;
        ...
    };

    sub print {
        my $self = shift;
        print join ", " => map { $self->{$_} } FOO, BAR, BAZ, BAT, BAN, BOO;
    }

You can also call add_pre_init and add_post_init as class methods from anywhere
to add init and post-init to the class.

B<Please note:> This will apply to all future instances of the object created,
but not past ones. This is a form of meta-programming and it is easy to abuse.
It is also helpful for extending Object::HashBase.

    My::Class->add_pre_init(sub { ... });
    My::Class->add_post_init(sub { ... });

=head1 DESCRIPTION

This package is used to generate classes based on hashrefs. Using this class
will give you a C<new()> method, as well as generating accessors you request.
Generated accessors will be getters, C<set_ACCESSOR> setters will also be
generated for you. You also get constants for each accessor (all caps) which
return the key into the hash for that accessor. Single inheritance is also
supported.

=head1 XS ACCESSORS

If L<Class::XSAccessor> is installed, it will be used to generate XS getters
and setters.

=head2 CAVEATS

The only caveat noticed so far is that if you take a reference to an objects
attribute element: C<< my $ref = \($obj->{foo}) >> then use
C<< $obj->set_foo(1) >>, setting C<< $$ref = 2 >> will not longer work, and
getting the value via C<< $val = $$ref >> will also not work. This is not a
problem when L<Class::XSAccessor> is not used.

In practice it will nbe VERY rare for this to be a problem, but it was noticed
because it broke a performance optimization in L<Test2::API>.

You can request an accessor NOT be xs with the '~' prefix:

    use Object::HashBase '~foo';

The sample above generates C<foo()> and C<set_foo()> and they are NOT
implemented in XS.

=head1 INCLUDING IN YOUR DIST

If you want to use HashBase, but do not want to depend on it, you can include
it in your distribution.

    $ hashbase_inc.pl Prefix::For::Module

This will create 2 files:

    lib/Prefix/For/Module/HashBase.pm
    t/HashBase.t

You can then use the includes C<Prefix::For::Module::HashBase> instead of
C<Object::HashBase>.

You can re-run this script to regenerate the files, or upgrade them to newer
versions.

If the script was not installed, it can be found in the C<scripts/> directory.

=head1 METHODS

=head2 PROVIDED BY HASH BASE

=over 4

=item $it = $class->new(%PAIRS)

=item $it = $class->new(\%PAIRS)

=item $it = $class->new(\@ORDERED_VALUES)

Create a new instance.

HashBase will not export C<new()> if there is already a C<new()> method in your
packages inheritance chain.

B<If you do not want this method you can define your own> you just have to
declare it before loading L<Object::HashBase>.

    package My::Package;

    # predeclare new() so that HashBase does not give us one.
    sub new;

    use Object::HashBase qw/foo bar baz/;

    # Now we define our own new method.
    sub new { ... }

This makes it so that HashBase sees that you have your own C<new()> method.
Alternatively you can define the method before loading HashBase instead of just
declaring it, but that scatters your use statements.

The most common way to create an object is to pass in key/value pairs where
each key is an attribute and each value is what you want assigned to that
attribute. No checking is done to verify the attributes or values are valid,
you may do that in C<init()> if desired.

If you would like, you can pass in a hashref instead of pairs. When you do so
the hashref will be copied, and the copy will be returned blessed as an object.
There is no way to ask HashBase to bless a specific hashref.

In some cases an object may only have 1 or 2 attributes, in which case a
hashref may be too verbose for your liking. In these cases you can pass in an
arrayref with only values. The values will be assigned to attributes in the
order the attributes were listed. When there is inheritance involved the
attributes from parent classes will come before subclasses.

=back

=head2 HOOKS

=over 4

=item $self->init()

This gives you the chance to set some default values to your fields. The only
argument is C<$self> with its indexes already set from the constructor.

B<Note:> Object::HashBase checks for an init using C<< $class->can('init') >>
during construction. It DOES NOT call C<can()> on the created object. Also note
that the result of the check is cached, it is only ever checked once, the first
time an instance of your class is created. This means that adding an C<init()>
method AFTER the first construction will result in it being ignored.

=back

=head1 ACCESSORS

=head2 READ/WRITE

To generate accessors you list them when using the module:

    use Object::HashBase qw/foo/;

This will generate the following subs in your namespace:

=over 4

=item foo()

Getter, used to get the value of the C<foo> field.

=item set_foo()

Setter, used to set the value of the C<foo> field.

=item FOO()

Constant, returns the field C<foo>'s key into the class hashref. Subclasses will
also get this function as a constant, not simply a method, that means it is
copied into the subclass namespace.

The main reason for using these constants is to help avoid spelling mistakes
and similar typos. It will not help you if you forget to prefix the '+' though.

=back

=head2 READ ONLY

    use Object::HashBase qw/-foo/;

=over 4

=item set_foo()

Throws an exception telling you the attribute is read-only. This is exported to
override any active setters for the attribute in a parent class.

=back

=head2 DEPRECATED SETTER

    use Object::HashBase qw/^foo/;

=over 4

=item set_foo()

This will set the value, but it will also warn you that the method is
deprecated.

=back

=head2 NO SETTER

    use Object::HashBase qw/<foo/;

Only gives you a reader, no C<set_foo> method is defined at all.

=head2 NO READER

    use Object::HashBase qw/>foo/;

Only gives you a write (C<set_foo>), no C<foo> method is defined at all.

=head2 CONSTANT ONLY

    use Object::HashBase qw/+foo/;

This does not create any methods for you, it just adds the C<FOO> constant.

=head2 NO XS

    use Object::HashBase qw/~foo/;

This enforces that the getter and setter generated for C<foo> will NOT use
L<Class::XSAccessor> even if it is installed.

=head1 ISA AND ROLE PREFIXES

Two import prefixes provide shortcuts for declaring parent classes and
consuming roles.

=head2 PARENT PREFIX: @

    use Object::HashBase qw/@Some::Parent::Class foo bar/;

This loads C<Some::Parent::Class> and pushes it onto C<@ISA>. Equivalent to:

    use parent 'Some::Parent::Class';
    use Object::HashBase qw/foo bar/;

Multiple parents can be declared:

    use Object::HashBase qw/@Parent::A @Parent::B foo/;

The prefix may be combined freely with attribute declarations in any order;
parents are processed first regardless of position.

=head2 ROLE PREFIX: &

    use Object::HashBase qw/&Some::Role::Name foo/;

This consumes a L<Role::Tiny> role that itself uses L<Object::HashBase>. The
role's constants are copied into the consumer immediately so the
C<< $self->{+FOO} >> pattern resolves at compile time. The actual role
composition via C<< Role::Tiny->apply_roles_to_package >> is deferred until
the end of the consumer's compile scope, so the consumer's own methods are
present when role methods are composed (correct method-modifier and
required-method semantics).

Requirements:

=over 4

=item *

L<Role::Tiny> 1.003000 or newer must be installed. It is not a hard
dependency of L<Object::HashBase>; it is loaded on demand when the C<&>
prefix is used.

=item *

Perl 5.10 or newer. The compile-scope deferral relies on the lexically-scoped
C<%^H> hints hash, which was made reliable in 5.10.

=item *

The target package must be a Role::Tiny role that itself uses
L<Object::HashBase>.

=back

If a sub of the same name as a role constant already exists in the consumer
package, the existing sub is kept and the role constant is not copied. No
warning is issued.

=head1 SUBCLASSING

You can subclass an existing HashBase class.

    use base 'Another::HashBase::Class';
    use Object::HashBase qw/foo bar baz/;

The base class is added to C<@ISA> for you, and all constants from base classes
are added to subclasses automatically.

=head1 USING IN A ROLE

Object::HashBase can be used inside a L<Role::Tiny> role:

    package My::Role;
    use Role::Tiny;
    use Object::HashBase qw/foo -bar/;

    sub greet { "hello " . $_[0]->{+FOO} }

When the package being imported into is a Role::Tiny role, Object::HashBase
skips injection of C<new()>, C<add_pre_init>, C<add_post_init>,
C<_pre_init>, and C<_post_init>. Only accessor methods and constants are
installed.

B<Important:> C<use Role::Tiny;> must appear B<before> C<use Object::HashBase>
in the role package. Object::HashBase detects the role status of the target
package at import time; if Role::Tiny has not yet been loaded, the target
will be treated as a plain class and C<new()> and the init hooks will be
injected.

Consumers compose the role with the C<&> prefix (recommended) or with a
direct C<with()> call. The C<&> prefix copies the role's constants into the
consumer at compile time, which is required for the C<< $self->{+FOO} >>
pattern in consumer methods to resolve.

=head1 GETTING A LIST OF ATTRIBUTES FOR A CLASS

Object::HashBase provides a function for retrieving a list of attributes for an
Object::HashBase class.

=over 4

=item @list = Object::HashBase::attr_list($class)

=item @list = $class->Object::HashBase::attr_list()

Either form above will work. This will return a list of attributes defined on
the object. This list is returned in the attribute definition order, parent
class attributes are listed before subclass attributes. Duplicate attributes
will be removed before the list is returned.

Attributes from roles composed via the C<&> prefix are included in the
returned list, ordered before the consumer's own attributes at the same ISA
level.

B<Note:> This list is used in the C<< $class->new(\@ARRAY) >> constructor to
determine the attribute to which each value will be paired.

=back

=head1 SOURCE

The source code repository for HashBase can be found at
F<http://github.com/Test-More/HashBase/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2017 Chad Granum E<lt>exodist@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
