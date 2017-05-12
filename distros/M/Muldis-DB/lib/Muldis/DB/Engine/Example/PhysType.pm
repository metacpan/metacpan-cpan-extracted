use 5.008001;
use utf8;
use strict;
use warnings FATAL => 'all';

###########################################################################
###########################################################################

my $BOOL_FALSE = (1 == 0);
my $BOOL_TRUE  = (1 == 1);

my $ORDER_INCREASE = (1 <=> 2);
my $ORDER_SAME     = (1 <=> 1);
my $ORDER_DECREASE = (2 <=> 1);

my $EMPTY_STR = q{};

###########################################################################
###########################################################################

{ package Muldis::DB::Engine::Example::PhysType; # module
    our $VERSION = 0.004000;
    # Note: This given version applies to all of this file's packages.

    use base 'Exporter';
    our @EXPORT_OK = qw(
        ptBool ptOrder ptInt ptBlob ptText
        ptTuple ptQuasiTuple
        ptRelation ptQuasiRelation
        ptTypeInvo ptQuasiTypeInvo
        ptTypeDict ptQuasiTypeDict
        ptValueDict ptQuasiTypeDict
    );

###########################################################################

sub ptBool {
    my ($args) = @_;
    my ($v) = @{$args}{'v'};
    return Muldis::DB::Engine::Example::PhysType::Bool->new({ 'v' => $v });
}

sub ptOrder {
    my ($args) = @_;
    my ($v) = @{$args}{'v'};
    return Muldis::DB::Engine::Example::PhysType::Order->new({ 'v' => $v });
}

sub ptInt {
    my ($args) = @_;
    my ($v) = @{$args}{'v'};
    return Muldis::DB::Engine::Example::PhysType::Int->new({ 'v' => $v });
}

sub ptBlob {
    my ($args) = @_;
    my ($v) = @{$args}{'v'};
    return Muldis::DB::Engine::Example::PhysType::Blob->new({ 'v' => $v });
}

sub ptText {
    my ($args) = @_;
    my ($v) = @{$args}{'v'};
    return Muldis::DB::Engine::Example::PhysType::Text->new({ 'v' => $v });
}

sub ptTuple {
    my ($args) = @_;
    my ($heading, $body) = @{$args}{'heading', 'body'};
    return Muldis::DB::Engine::Example::PhysType::Tuple->new({
        'heading' => $heading, 'body' => $body });
}

sub ptQuasiTuple {
    my ($args) = @_;
    my ($heading, $body) = @{$args}{'heading', 'body'};
    return Muldis::DB::Engine::Example::PhysType::QuasiTuple->new({
        'heading' => $heading, 'body' => $body });
}

sub ptRelation {
    my ($args) = @_;
    my ($heading, $body) = @{$args}{'heading', 'body'};
    return Muldis::DB::Engine::Example::PhysType::Relation->new({
        'heading' => $heading, 'body' => $body });
}

sub ptQuasiRelation {
    my ($args) = @_;
    my ($heading, $body) = @{$args}{'heading', 'body'};
    return Muldis::DB::Engine::Example::PhysType::QuasiRelation->new({
        'heading' => $heading, 'body' => $body });
}

sub ptTypeInvo {
    my ($args) = @_;
    my ($kind, $spec) = @{$args}{'kind', 'spec'};
    return Muldis::DB::Engine::Example::PhysType::TypeInvo->new({
        'kind' => $kind, 'spec' => $spec });
}

sub ptQuasiTypeInvo {
    my ($args) = @_;
    my ($kind, $spec) = @{$args}{'kind', 'spec'};
    return Muldis::DB::Engine::Example::PhysType::QuasiTypeInvo->new({
        'kind' => $kind, 'spec' => $spec });
}

sub ptTypeDict {
    my ($args) = @_;
    my ($map) = @{$args}{'map'};
    return Muldis::DB::Engine::Example::PhysType::TypeDict->new({
        'map' => $map });
}

sub ptQuasiTypeDict {
    my ($args) = @_;
    my ($map) = @{$args}{'map'};
    return Muldis::DB::Engine::Example::PhysType::QuasiTypeDict->new({
        'map' => $map });
}

sub ptValueDict {
    my ($args) = @_;
    my ($map) = @{$args}{'map'};
    return Muldis::DB::Engine::Example::PhysType::ValueDict->new({
        'map' => $map });
}

sub ptQuasiValueDict {
    my ($args) = @_;
    my ($map) = @{$args}{'map'};
    return Muldis::DB::Engine::Example::PhysType::QuasiValueDict->new({
        'map' => $map });
}

###########################################################################

} # module Muldis::DB::Engine::Example::PhysType

###########################################################################
###########################################################################

{ package Muldis::DB::Engine::Example::PhysType::Value; # role

    use Carp;
    use Scalar::Util qw(blessed);

#    my $ATTR_ROOT_TYPE = 'Value::root_type';
        # Muldis::DB::Engine::Example::PhysType::Cat_EntityName.
        # This is the fundamental Muldis D data type that this ::Value
        # object's implementation sees it as a generic member of, and which
        # generally determines what operators can be used with it.
        # It is a supertype of the declared type.
#    my $ATTR_DECL_TYPE = 'Value::decl_type';
        # Muldis::DB::Engine::Example::PhysType::Cat_EntityName.
        # This is the Muldis D data type that the ::Value was declared to
        # be a member of when the ::Value object was created.
#    my $ATTR_LAST_KNOWN_MST = 'Value::last_known_mst';
        # Muldis::DB::Engine::Example::PhysType::Cat_EntityName.
        # This is the Muldis::DB data type that is the most specific type
        # of this ::Value, as it was last determined.
        # It is a subtype of the declared type.
        # Since calculating a value's mst may be expensive, this object
        # attribute may either be unset or be out of date with respect to
        # the current type system, that is, not be automatically updated at
        # the same time that a new subtype of its old mst is declared.

#    my $ATTR_WHICH = 'Value::which';
        # Str.
        # This is a unique identifier for the value that this object
        # represents that should compare correctly with the corresponding
        # identifiers of all ::Value-doing objects.
        # It is a text string of format "<tnl> <tn> <vll> <vl>" where:
        #   1. <tn> is the value's root type name (fully qualified)
        #   2. <tnl> is the character-length of <tn>
        #   3. <vl> is the (class-determined) stringified value itself
        #   4. <vll> is the character-length of <vl>
        # This identifier is mainly used when a ::Value needs to be used as
        # a key to index the ::Value with, not necessarily when comparing
        # 2 values for equality.
        # This identifier can be expensive to calculate, so it will be done
        # only when actually required; eg, by the which() method.

###########################################################################

sub new {
    my ($class, $args) = @_;
    my $self = bless {}, $class;
    $self->_build( $args );
    return $self;
}

sub _build {
    return; # default for any classes having no attributes
}

###########################################################################

sub root_type {
    my ($self) = @_;
    confess q{not implemented by subclass } . (blessed $self);
}

sub declared_type {
    my ($self) = @_;
    confess q{not implemented by subclass } . (blessed $self);
}

sub most_specific_type {
    my ($self) = @_;
    confess q{not implemented by subclass } . (blessed $self);
}

sub which {
    my ($self) = @_;
    confess q{not implemented by subclass } . (blessed $self);
}

###########################################################################

sub as_ast {
    my ($self) = @_;
    confess q{not implemented by subclass } . (blessed $self);
}

###########################################################################

sub equal {
    my ($self, $args) = @_;
    my ($other) = @{$args}{'other'};
    return $BOOL_FALSE
        if blessed $other ne blessed $self;
    return $self->_equal( $other );
}

sub _equal {
    my ($self) = @_;
    confess q{not implemented by subclass } . (blessed $self);
}

###########################################################################

} # role Muldis::DB::Engine::Example::PhysType::Value

###########################################################################
###########################################################################

{ package Muldis::DB::Engine::Example::PhysType::Bool; # class
    use base 'Muldis::DB::Engine::Example::PhysType::Value';

    my $ATTR_V = 'v';
        # A p5 Scalar that equals $BOOL_FALSE|$BOOL_TRUE.

    my $ATTR_WHICH = 'which';

###########################################################################

sub _build {
    my ($self, $args) = @_;
    my ($v) = @{$args}{'v'};
    $self->{$ATTR_V} = $v;
    return;
}

###########################################################################

sub root_type {
    return 'sys.Core.Bool.Bool';
}

sub which {
    my ($self) = @_;
    if (!defined $self->{$ATTR_WHICH}) {
        my $s = ''.$self->{$ATTR_V};
        my $len_s = length $s;
        $self->{$ATTR_WHICH} = "18 sys.Core.Bool.Bool $len_s $s";
    }
    return $self->{$ATTR_WHICH};
}

###########################################################################

sub as_ast {
    my ($self) = @_;
    return Muldis::DB::LOSE::Bool->new({ 'v' => $self->{$ATTR_V} });
}

###########################################################################

sub _equal {
    my ($self, $other) = @_;
    return $other->{$ATTR_V} eq $self->{$ATTR_V};
}

###########################################################################

sub v {
    my ($self) = @_;
    return $self->{$ATTR_V};
}

###########################################################################

} # class Muldis::DB::Engine::Example::PhysType::Bool

###########################################################################
###########################################################################

{ package Muldis::DB::Engine::Example::PhysType::Order; # class
    use base 'Muldis::DB::Engine::Example::PhysType::Value';

    my $ATTR_V = 'v';
        # A p5 Scalar that equals $ORDER_(INCREASE|SAME|DECREASE).

    my $ATTR_WHICH = 'which';

###########################################################################

sub _build {
    my ($self, $args) = @_;
    my ($v) = @{$args}{'v'};
    $self->{$ATTR_V} = $v;
    return;
}

###########################################################################

sub root_type {
    return 'sys.Core.Order.Order';
}

sub which {
    my ($self) = @_;
    if (!defined $self->{$ATTR_WHICH}) {
        my $s = ''.$self->{$ATTR_V};
        my $len_s = length $s;
        $self->{$ATTR_WHICH} = "20 sys.Core.Order.Order $len_s $s";
    }
    return $self->{$ATTR_WHICH};
}

###########################################################################

sub as_ast {
    my ($self) = @_;
    return Muldis::DB::LOSE::Order->new({ 'v' => $self->{$ATTR_V} });
}

###########################################################################

sub _equal {
    my ($self, $other) = @_;
    return $other->{$ATTR_V} eq $self->{$ATTR_V};
}

###########################################################################

sub v {
    my ($self) = @_;
    return $self->{$ATTR_V};
}

###########################################################################

} # class Muldis::DB::Engine::Example::PhysType::Order

###########################################################################
###########################################################################

{ package Muldis::DB::Engine::Example::PhysType::Int; # class
    use base 'Muldis::DB::Engine::Example::PhysType::Value';

    use bigint; # this is experimental

    my $ATTR_V = 'v';
        # A p5 Scalar that is a Perl integer or BigInt or canonical string.

    my $ATTR_WHICH = 'which';

###########################################################################

sub _build {
    my ($self, $args) = @_;
    my ($v) = @{$args}{'v'};
    $self->{$ATTR_V} = $v;
    return;
}

###########################################################################

sub root_type {
    return 'sys.Core.Int.Int';
}

sub which {
    my ($self) = @_;
    if (!defined $self->{$ATTR_WHICH}) {
        my $s = ''.$self->{$ATTR_V};
        my $len_s = length $s;
        $self->{$ATTR_WHICH} = "16 sys.Core.Int.Int $len_s $s";
    }
    return $self->{$ATTR_WHICH};
}

###########################################################################

sub as_ast {
    my ($self) = @_;
    return Muldis::DB::LOSE::Int->new({ 'v' => $self->{$ATTR_V} });
}

###########################################################################

sub _equal {
    my ($self, $other) = @_;
    return $other->{$ATTR_V} == $self->{$ATTR_V};
}

###########################################################################

sub v {
    my ($self) = @_;
    return $self->{$ATTR_V};
}

###########################################################################

} # class Muldis::DB::Engine::Example::PhysType::Int

###########################################################################
###########################################################################

{ package Muldis::DB::Engine::Example::PhysType::Blob; # class
    use base 'Muldis::DB::Engine::Example::PhysType::Value';

    my $ATTR_V = 'v';
        # A p5 Scalar that is a byte-mode string; it has false utf8 flag.

    my $ATTR_WHICH = 'which';

###########################################################################

sub _build {
    my ($self, $args) = @_;
    my ($v) = @{$args}{'v'};
    $self->{$ATTR_V} = $v;
    return;
}

###########################################################################

sub root_type {
    return 'sys.Core.Blob.Blob';
}

sub which {
    my ($self) = @_;
    if (!defined $self->{$ATTR_WHICH}) {
        my $s = $self->{$ATTR_V};
        my $len_s = length $s;
        $self->{$ATTR_WHICH} = "18 sys.Core.Blob.Blob $len_s $s";
    }
    return $self->{$ATTR_WHICH};
}

###########################################################################

sub as_ast {
    my ($self) = @_;
    return Muldis::DB::LOSE::Blob->new({ 'v' => $self->{$ATTR_V} });
}

###########################################################################

sub _equal {
    my ($self, $other) = @_;
    return $other->{$ATTR_V} eq $self->{$ATTR_V};
}

###########################################################################

sub v {
    my ($self) = @_;
    return $self->{$ATTR_V};
}

###########################################################################

} # class Muldis::DB::Engine::Example::PhysType::Blob

###########################################################################
###########################################################################

{ package Muldis::DB::Engine::Example::PhysType::Text; # class
    use base 'Muldis::DB::Engine::Example::PhysType::Value';

    my $ATTR_V = 'v';
        # A p5 Scalar that is a text-mode string;
        # it either has true utf8 flag or is only 7-bit bytes.

    my $ATTR_WHICH = 'which';

###########################################################################

sub _build {
    my ($self, $args) = @_;
    my ($v) = @{$args}{'v'};
    $self->{$ATTR_V} = $v;
    return;
}

###########################################################################

sub root_type {
    return 'sys.Core.Text.Text';
}

sub which {
    my ($self) = @_;
    if (!defined $self->{$ATTR_WHICH}) {
        my $s = $self->{$ATTR_V};
        my $len_s = length $s;
        $self->{$ATTR_WHICH} = "18 sys.Core.Text.Text $len_s $s";
    }
    return $self->{$ATTR_WHICH};
}

###########################################################################

sub as_ast {
    my ($self) = @_;
    return Muldis::DB::LOSE::Text->new({ 'v' => $self->{$ATTR_V} });
}

###########################################################################

sub _equal {
    my ($self, $other) = @_;
    return $other->{$ATTR_V} eq $self->{$ATTR_V};
}

###########################################################################

sub v {
    my ($self) = @_;
    return $self->{$ATTR_V};
}

###########################################################################

} # class Muldis::DB::Engine::Example::PhysType::Text

###########################################################################
###########################################################################

{ package Muldis::DB::Engine::Example::PhysType::_Tuple; # role
    use base 'Muldis::DB::Engine::Example::PhysType::Value';

    use Carp;
    use Scalar::Util qw(blessed);

    my $ATTR_HEADING = 'heading';
    my $ATTR_BODY    = 'body';

    my $ATTR_WHICH = 'which';

###########################################################################

sub _build {
    my ($self, $args) = @_;
    my ($heading, $body) = @{$args}{'heading', 'body'};
    $self->{$ATTR_HEADING} = $heading;
    $self->{$ATTR_BODY}    = $body;
    return;
}

###########################################################################

sub root_type {
    my ($self) = @_;
    my $unqltp = ($self->_allows_quasi() ? 'Quasi' : '') . 'Tuple';
    return "sys.Core.$unqltp.$unqltp";
}

sub which {
    my ($self) = @_;
    if (!defined $self->{$ATTR_WHICH}) {
        my $unqltp = ($self->_allows_quasi() ? 'Quasi' : '') . 'Tuple';
        my $root_type = "sys.Core.$unqltp.$unqltp";
        my $tpwl = (length $root_type) . q{ } . $root_type;
        my $s = 'H ' . $self->{$ATTR_HEADING}->which()
            . ' B ' . $self->{$ATTR_BODY}->which();
        my $len_s = length $s;
        $self->{$ATTR_WHICH} = "$tpwl $len_s $s";
    }
    return $self->{$ATTR_WHICH};
}

###########################################################################

sub as_ast {
    my ($self) = @_;
    my $call_args = { 'heading' => $self->{$ATTR_HEADING}->as_ast(),
        'body' => $self->{$ATTR_BODY}->as_ast() };
    return $self->_allows_quasi()
        ? Muldis::DB::LOSE::QuasiTuple->new( $call_args ) : Muldis::DB::LOSE::Tuple->new( $call_args );
}

###########################################################################

sub _equal {
    my ($self, $other) = @_;
    return ($self->{$ATTR_HEADING}->equal({
            'other' => $other->{$ATTR_HEADING} })
        and $self->{$ATTR_BODY}->equal({
            'other' => $other->{$ATTR_BODY} }));
}

###########################################################################

sub heading {
    my ($self) = @_;
    return $self->{$ATTR_HEADING};
}

sub body {
    my ($self) = @_;
    return $self->{$ATTR_BODY};
}

###########################################################################

sub attr_count {
    my ($self) = @_;
    return $self->{$ATTR_HEADING}->elem_count();
}

sub attr_exists {
    my ($self, $args) = @_;
    my ($attr_name) = @{$args}{'attr_name'};
    return $self->{$ATTR_HEADING}->elem_exists({
        'elem_name' => $attr_name });
}

sub attr_type {
    my ($self, $args) = @_;
    my ($attr_name) = @{$args}{'attr_name'};
    return $self->{$ATTR_HEADING}->elem_value({
        'elem_name' => $attr_name });
}

sub attr_value {
    my ($self, $args) = @_;
    my ($attr_name) = @{$args}{'attr_name'};
    return $self->{$ATTR_BODY}->elem_value({ 'elem_name' => $attr_name });
}

###########################################################################

} # class Muldis::DB::Engine::Example::PhysType::_Tuple

###########################################################################
###########################################################################

{ package Muldis::DB::Engine::Example::PhysType::Tuple; # class
    use base 'Muldis::DB::Engine::Example::PhysType::_Tuple';
    sub _allows_quasi { return $BOOL_FALSE; }
} # class Muldis::DB::Engine::Example::PhysType::Tuple

###########################################################################
###########################################################################

{ package Muldis::DB::Engine::Example::PhysType::QuasiTuple; # class
    use base 'Muldis::DB::Engine::Example::PhysType::_Tuple';
    sub _allows_quasi { return $BOOL_TRUE; }
} # class Muldis::DB::Engine::Example::PhysType::QuasiTuple

###########################################################################
###########################################################################

{ package Muldis::DB::Engine::Example::PhysType::_Relation; # role
    use base 'Muldis::DB::Engine::Example::PhysType::Value';

    use Carp;
    use Scalar::Util qw(blessed);

    my $ATTR_HEADING      = 'heading';
    my $ATTR_BODY         = 'body';
    my $ATTR_KEY_OVER_ALL = 'key_over_all';

    my $ATTR_WHICH = 'which';

###########################################################################

sub _build {
    my ($self, $args) = @_;
    my ($heading, $body) = @{$args}{'heading', 'body'};

    my $key_over_all = {map { $_->which() => $_ } @{$body}}; # elim dup tpl

    $self->{$ATTR_HEADING}      = $heading;
    $self->{$ATTR_BODY}         = [values %{$key_over_all}]; # no dup in b
    $self->{$ATTR_KEY_OVER_ALL} = $key_over_all;

    return;
}

###########################################################################

sub root_type {
    my ($self) = @_;
    my $unqltp = ($self->_allows_quasi() ? 'Quasi' : '') . 'Relation';
    return "sys.Core.$unqltp.$unqltp";
}

sub which {
    my ($self) = @_;
    if (!defined $self->{$ATTR_WHICH}) {
        my $unqltp = ($self->_allows_quasi() ? 'Quasi' : '') . 'Relation';
        my $root_type = "sys.Core.$unqltp.$unqltp";
        my $tpwl = (length $root_type) . q{ } . $root_type;
        my $s = 'H ' . $self->{$ATTR_HEADING}->which()
            . ' B ' . (join ' ', sort keys %{$self->{$ATTR_KEY_OVER_ALL}});
        my $len_s = length $s;
        $self->{$ATTR_WHICH} = "$tpwl $len_s $s";
    }
    return $self->{$ATTR_WHICH};
}

###########################################################################

sub as_ast {
    my ($self) = @_;
    my $call_args = { 'heading' => $self->{$ATTR_HEADING}->as_ast(),
        'body' => [map { $_->as_ast() } @{$self->{$ATTR_BODY}}] };
    return $self->_allows_quasi()
        ? Muldis::DB::LOSE::QuasiRelation->new( $call_args ) : Muldis::DB::LOSE::Relation->new( $call_args );
}

###########################################################################

sub _equal {
    my ($self, $other) = @_;
    return $BOOL_FALSE
        if !$self->{$ATTR_HEADING}->equal({
            'other' => $other->{$ATTR_HEADING} });
    return $BOOL_FALSE
        if @{$other->{$ATTR_BODY}} != @{$self->{$ATTR_BODY}};
    my $v1 = $self->{$ATTR_KEY_OVER_ALL};
    my $v2 = $other->{$ATTR_KEY_OVER_ALL};
    for my $ek (keys %{$v1}) {
        return $BOOL_FALSE
            if !exists $v2->{$ek};
    }
    return $BOOL_TRUE;
}

###########################################################################

sub heading {
    my ($self) = @_;
    return $self->{$ATTR_HEADING};
}

sub body {
    my ($self) = @_;
    return $self->{$ATTR_BODY};
}

###########################################################################

sub tuple_count {
    my ($self) = @_;
    return 0 + @{$self->{$ATTR_BODY}};
}

###########################################################################

sub attr_count {
    my ($self) = @_;
    return $self->{$ATTR_HEADING}->elem_count();
}

sub attr_exists {
    my ($self, $args) = @_;
    my ($attr_name) = @{$args}{'attr_name'};
    return $self->{$ATTR_HEADING}->elem_exists({
        'elem_name' => $attr_name });
}

sub attr_type {
    my ($self, $args) = @_;
    my ($attr_name) = @{$args}{'attr_name'};
    return $self->{$ATTR_HEADING}->elem_value({
        'elem_name' => $attr_name });
}

sub attr_values {
    my ($self, $args) = @_;
    my ($attr_name) = @{$args}{'attr_name'};
    return [map {
            $_->elem_value({ 'elem_name' => $attr_name })
        } @{$self->{$ATTR_BODY}}];
}

###########################################################################

} # class Muldis::DB::Engine::Example::PhysType::_Relation

###########################################################################
###########################################################################

{ package Muldis::DB::Engine::Example::PhysType::Relation; # class
    use base 'Muldis::DB::Engine::Example::PhysType::_Relation';
    sub _allows_quasi { return $BOOL_FALSE; }
} # class Muldis::DB::Engine::Example::PhysType::Relation

###########################################################################
###########################################################################

{ package Muldis::DB::Engine::Example::PhysType::QuasiRelation; # class
    use base 'Muldis::DB::Engine::Example::PhysType::_Relation';
    sub _allows_quasi { return $BOOL_TRUE; }
} # class Muldis::DB::Engine::Example::PhysType::QuasiRelation

###########################################################################
###########################################################################

{ package Muldis::DB::Engine::Example::PhysType::_TypeInvo; # role
    use base 'Muldis::DB::Engine::Example::PhysType::Value';

    use Carp;
    use Scalar::Util qw(blessed);

    my $ATTR_KIND = 'kind';
    my $ATTR_SPEC = 'spec';

    my $ATTR_WHICH = 'which';

###########################################################################

sub _build {
    my ($self, $args) = @_;
    my ($kind, $spec) = @{$args}{'kind', 'spec'};
    $self->{$ATTR_KIND} = $kind;
    $self->{$ATTR_SPEC} = $spec;
    return;
}

###########################################################################

sub root_type {
    my ($self) = @_;
    return 'sys.LOSE._TypeInvo' . ($self->_allows_quasi() ? 'AQ' : 'NQ');
}

sub which {
    my ($self) = @_;
    if (!defined $self->{$ATTR_WHICH}) {
        my $tpwl = '20 sys.LOSE._TypeInvo'
            . ($self->_allows_quasi() ? 'AQ' : 'NQ');
        my $kind = $self->{$ATTR_KIND};
        my $spec = $self->{$ATTR_SPEC};
        my $sk = (length $kind) . q{ } . $kind;
        my $ss = ($kind eq 'Any' or $kind eq 'Scalar')
            ? (length $spec) . q{ } . $spec : $spec->which();
        my $s = "KIND $sk SPEC $ss";
        my $len_s = length $s;
        $self->{$ATTR_WHICH} = "$tpwl $len_s $s";
    }
    return $self->{$ATTR_WHICH};
}

###########################################################################

sub as_ast {
    my ($self) = @_;
    my $kind = $self->{$ATTR_KIND};
    my $spec = $self->{$ATTR_SPEC};
    my $call_args = { 'kind' => $kind,
        'spec' => ($kind eq 'Any' ? $spec
            : $kind eq 'Scalar' ? Muldis::DB::LOSE::EntityName->new({ 'text' => $spec })
            : $spec->as_ast()) };
    return $self->_allows_quasi()
        ? Muldis::DB::LOSE::QuasiTypeInvo->new( $call_args ) : Muldis::DB::LOSE::TypeInvo->new( $call_args );
}

###########################################################################

sub _equal {
    my ($self, $other) = @_;
    my $kind = $self->{$ATTR_KIND};
    my $spec = $self->{$ATTR_SPEC};
    return $BOOL_FALSE
        if $other->{$ATTR_KIND} ne $kind;
    return ($kind eq 'Any' or $kind eq 'Scalar')
            ? $other->{$ATTR_SPEC} eq $spec
        : $spec->equal({ 'other' => $other->{$ATTR_SPEC} });
}

###########################################################################

sub kind {
    my ($self) = @_;
    return $self->{$ATTR_KIND};
}

sub spec {
    my ($self) = @_;
    return $self->{$ATTR_SPEC};
}

###########################################################################

} # role Muldis::DB::Engine::Example::PhysType::_TypeInvo

###########################################################################
###########################################################################

{ package Muldis::DB::Engine::Example::PhysType::TypeInvo; # class
    use base 'Muldis::DB::Engine::Example::PhysType::_TypeInvo';
    sub _allows_quasi { return $BOOL_FALSE; }
} # class Muldis::DB::Engine::Example::PhysType::TypeInvo

###########################################################################
###########################################################################

{ package Muldis::DB::Engine::Example::PhysType::QuasiTypeInvo; # class
    use base 'Muldis::DB::Engine::Example::PhysType::_TypeInvo';
    sub _allows_quasi { return $BOOL_TRUE; }
} # class Muldis::DB::Engine::Example::PhysType::QuasiTypeInvo

###########################################################################
###########################################################################

{ package Muldis::DB::Engine::Example::PhysType::_TypeDict; # role
    use base 'Muldis::DB::Engine::Example::PhysType::Value';

    use Carp;
    use Scalar::Util qw(blessed);

    my $ATTR_MAP = 'map';
        # A p5 Hash with 0..N elements:
            # Each Hash key is a p5 text-mode string; an attr name.
            # Each Hash value is a TypeInvo; an attr declared type.

    my $ATTR_WHICH = 'which';

###########################################################################

sub _build {
    my ($self, $args) = @_;
    my ($map) = @{$args}{'map'};
    $self->{$ATTR_MAP} = $map;
    return;
}

###########################################################################

sub root_type {
    my ($self) = @_;
    return 'sys.LOSE._TypeDict' . ($self->_allows_quasi() ? 'AQ' : 'NQ');
}

sub which {
    my ($self) = @_;
    if (!defined $self->{$ATTR_WHICH}) {
        my $tpwl = '20 sys.LOSE._TypeDict'
            . ($self->_allows_quasi() ? 'AQ' : 'NQ');
        my $map = $self->{$ATTR_MAP};
        my $s = join q{ }, map {
                my $mk = (length $_) . q{ } . $_;
                my $mv = $map->{$_}->which();
                "K $mk V $mv";
            } sort keys %{$map};
        my $len_s = length $s;
        $self->{$ATTR_WHICH} = "$tpwl $len_s $s";
    }
    return $self->{$ATTR_WHICH};
}

###########################################################################

sub as_ast {
    my ($self) = @_;
    my $map = $self->{$ATTR_MAP};
    my $call_args = { 'map' => [map {
            [Muldis::DB::LOSE::EntityName->new({ 'text' => $_ }), $map->{$_}->as_ast()],
        } keys %{$map}] };
    return $self->_allows_quasi()
        ? Muldis::DB::LOSE::QuasiTypeDict->new( $call_args ) : Muldis::DB::LOSE::TypeDict->new( $call_args );
}

###########################################################################

sub _equal {
    my ($self, $other) = @_;
    my $v1 = $self->{$ATTR_MAP};
    my $v2 = $other->{$ATTR_MAP};
    return $BOOL_FALSE
        if keys %{$v2} != keys %{$v1};
    for my $ek (keys %{$v1}) {
        return $BOOL_FALSE
            if !exists $v2->{$ek};
        return $BOOL_FALSE
            if !$v1->{$ek}->equal({ 'other' => $v2->{$ek} });
    }
    return $BOOL_TRUE;
}

###########################################################################

sub map {
    my ($self) = @_;
    return $self->{$ATTR_MAP};
}

###########################################################################

sub elem_count {
    my ($self) = @_;
    return 0 + keys %{$self->{$ATTR_MAP}};
}

sub elem_exists {
    my ($self, $args) = @_;
    my ($elem_name) = @{$args}{'elem_name'};
    return exists $self->{$ATTR_MAP}->{$elem_name};
}

sub elem_value {
    my ($self, $args) = @_;
    my ($elem_name) = @{$args}{'elem_name'};
    return $self->{$ATTR_MAP}->{$elem_name};
}

###########################################################################

} # role Muldis::DB::Engine::Example::PhysType::_TypeDict

###########################################################################
###########################################################################

{ package Muldis::DB::Engine::Example::PhysType::TypeDict; # class
    use base 'Muldis::DB::Engine::Example::PhysType::_TypeDict';
    sub _allows_quasi { return $BOOL_FALSE; }
} # class Muldis::DB::Engine::Example::PhysType::TypeDict

###########################################################################
###########################################################################

{ package Muldis::DB::Engine::Example::PhysType::QuasiTypeDict; # class
    use base 'Muldis::DB::Engine::Example::PhysType::_TypeDict';
    sub _allows_quasi { return $BOOL_TRUE; }
} # class Muldis::DB::Engine::Example::PhysType::QuasiTypeDict

###########################################################################
###########################################################################

{ package Muldis::DB::Engine::Example::PhysType::_ValueDict; # role
    use base 'Muldis::DB::Engine::Example::PhysType::Value';

    use Carp;
    use Scalar::Util qw(blessed);

    my $ATTR_MAP = 'map';

    my $ATTR_WHICH = 'which';

###########################################################################

sub _build {
    my ($self, $args) = @_;
    my ($map) = @{$args}{'map'};
    $self->{$ATTR_MAP} = $map;
    return;
}

###########################################################################

sub root_type {
    my ($self) = @_;
    return 'sys.LOSE._ValueDict' . ($self->_allows_quasi() ? 'AQ' : 'NQ');
}

sub which {
    my ($self) = @_;
    if (!defined $self->{$ATTR_WHICH}) {
        my $tpwl = '20 sys.LOSE._ValueDict'
            . ($self->_allows_quasi() ? 'AQ' : 'NQ');
        my $map = $self->{$ATTR_MAP};
        my $s = join q{ }, map {
                my $mk = (length $_) . q{ } . $_;
                my $mv = $map->{$_}->which();
                "K $mk V $mv";
            } sort keys %{$map};
        my $len_s = length $s;
        $self->{$ATTR_WHICH} = "$tpwl $len_s $s";
    }
    return $self->{$ATTR_WHICH};
}

###########################################################################

sub as_ast {
    my ($self) = @_;
    my $map = $self->{$ATTR_MAP};
    return Muldis::DB::LOSE::_ExprDict->new({ 'map' => [map {
            [Muldis::DB::LOSE::EntityName->new({ 'text' => $_ }), $map->{$_}->as_ast()],
        } keys %{$map}] });
}

###########################################################################

sub _equal {
    my ($self, $other) = @_;
    my $v1 = $self->{$ATTR_MAP};
    my $v2 = $other->{$ATTR_MAP};
    return $BOOL_FALSE
        if keys %{$v2} != keys %{$v1};
    for my $ek (keys %{$v1}) {
        return $BOOL_FALSE
            if !exists $v2->{$ek};
        return $BOOL_FALSE
            if !$v1->{$ek}->equal({ 'other' => $v2->{$ek} });
    }
    return $BOOL_TRUE;
}

###########################################################################

sub map {
    my ($self) = @_;
    return $self->{$ATTR_MAP};
}

###########################################################################

sub elem_count {
    my ($self) = @_;
    return 0 + keys %{$self->{$ATTR_MAP}};
}

sub elem_exists {
    my ($self, $args) = @_;
    my ($elem_name) = @{$args}{'elem_name'};
    return exists $self->{$ATTR_MAP}->{$elem_name};
}

sub elem_value {
    my ($self, $args) = @_;
    my ($elem_name) = @{$args}{'elem_name'};
    return $self->{$ATTR_MAP}->{$elem_name};
}

###########################################################################

} # role Muldis::DB::Engine::Example::PhysType::_ValueDict

###########################################################################
###########################################################################

{ package Muldis::DB::Engine::Example::PhysType::ValueDict; # class
    use base 'Muldis::DB::Engine::Example::PhysType::_ValueDict';
    sub _allows_quasi { return $BOOL_FALSE; }
} # class Muldis::DB::Engine::Example::PhysType::ValueDict

###########################################################################
###########################################################################

{ package Muldis::DB::Engine::Example::PhysType::QuasiValueDict; # class
    use base 'Muldis::DB::Engine::Example::PhysType::_ValueDict';
    sub _allows_quasi { return $BOOL_TRUE; }
} # class Muldis::DB::Engine::Example::PhysType::QuasiValueDict

###########################################################################
###########################################################################

1; # Magic true value required at end of a reusable file's code.
__END__

=pod

=encoding utf8

=head1 NAME

Muldis::DB::Engine::Example::PhysType -
Physical representations of all core data types

=head1 VERSION

This document describes Muldis::DB::Engine::Example::PhysType version 0.4.0
for Perl 5.

It also describes the same-number versions for Perl 5 of [...].

=head1 DESCRIPTION

This file is used internally by L<Muldis::DB::Engine::Example>; it is not
intended to be used directly in user code.

It provides physical representations of data types that this Example Engine
uses to implement Muldis D.  The API of these is expressly not intended to
match the API that the language itself specifies as possible
representations for system-defined data types.

Specifically, this file represents the core system-defined data types that
all Muldis D implementations must have, namely: Bool, Order, Int, Num,
Text, Blob, Tuple, Relation, and the Cat.* types.

By contrast, the optional data types are given physical representations by
other files: L<Muldis::DB::Engine::Example::PhysType::Temporal>,
L<Muldis::DB::Engine::Example::PhysType::Spatial>.

=head1 BUGS AND LIMITATIONS

This file assumes that it will only be invoked by other components of
Example, and that they will only be feeding it arguments that are exactly
what it requires.  For reasons of performance, it does not do any of its
own basic argument validation, as doing so should be fully redundant.  Any
invoker should be validating any arguments that it in turn got from user
code.  Moreover, this file will often take or return values by reference,
also for performance, and the caller is expected to know that they should
not be modifying said then-shared values afterwards.

=head1 AUTHOR

Darren Duncan (C<perl@DarrenDuncan.net>)

=head1 LICENSE AND COPYRIGHT

This file is part of the Muldis DB framework.

Muldis DB is Copyright © 2002-2007, Darren Duncan.

See the LICENSE AND COPYRIGHT of L<Muldis::DB> for details.

=cut
