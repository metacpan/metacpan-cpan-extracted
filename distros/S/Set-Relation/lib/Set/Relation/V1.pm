use 5.008000;
use utf8;
use strict;
use warnings;

###########################################################################
###########################################################################

{ package Set::Relation::V1; # class
    our $VERSION = '0.013004';
    $VERSION = eval $VERSION;

    use Carp 'confess';
    use Scalar::Util 'blessed', 'refaddr';
    use List::Util 'any', 'all', 'notall', 'uniqstr';

    # with Set::Relation::Mutable
    sub does {
        my ($self, $role_name) = @_;
        confess q{This does() may only be invoked on an object.}
            if not blessed $self;
        confess q{does(): Bad $role_name arg; it must be a defined string.}
            if !defined $role_name;
        return 0
            if !$self->isa( __PACKAGE__ );
        return 1
            if $role_name eq 'Set::Relation'
                or $role_name eq 'Set::Relation::Mutable';
        return 0;
    }

    # has _heading
        # isa HashRef
            # One elem per attribute:
                # hkey is Str attr name
                # hval is undef+unused
        # default {}
    sub _heading {
        my $self = shift;
        $self->{_heading} = $_[0] if scalar @_;
        return $self->{_heading};
    }
    # has _degree
        # isa Int
        # default 0
    sub _degree {
        my $self = shift;
        $self->{_degree} = $_[0] if scalar @_;
        return $self->{_degree};
    }
    sub degree {
        my $self = shift;
        return $self->{_degree};
    }

    # has _body
        # isa HashRef
            # One elem per tuple:
                # hkey is Str identity generated from all tuple attrs
                # hval is HashRef that is the coll of separate tuple attrs:
                    # hkey is Str attr name
                    # hval is 2-elem ArrayRef that is the tuple attr value
                        # [0] is actual attr value
                        # [1] is Str identity generated from attr value
        # default {}
    sub _body {
        my $self = shift;
        $self->{_body} = $_[0] if scalar @_;
        return $self->{_body};
    }
    # has _cardinality
        # isa Int
        # default 0
    sub _cardinality {
        my $self = shift;
        $self->{_cardinality} = $_[0] if scalar @_;
        return $self->{_cardinality};
    }
    sub cardinality {
        my $self = shift;
        return $self->{_cardinality};
    }

    # This may only be made defined when _has_frozen_identity is true.
    # has _which
        # isa Maybe[Str]
        # default undef
    sub _which {
        my $self = shift;
        $self->{_which} = $_[0] if scalar @_;
        return $self->{_which};
    }

    # has _indexes
        # isa HashRef
            # One elem per index:
                # hkey is index name;
                    # - is Str ident gen f head subset tha index ranges ovr
                # hval is 2-elem ArrayRef that is the index itself + meta
                    # [0] is HashRef of atnms that index ranges over
                        # - structure same as '_heading'
                    # [1] is index itself;
                        # - HashRef; one elem per tup of projection of body
                            # on attrs that index ranges over
                        # hkey is Str ident gen fr distinct projection tupl
                        # hval is set of body tup having projection tuples
                            # in comn; is HashRef; one elem per body tuple
                            # - structure same as '_body', is slice o _body
        # default {}
    sub _indexes {
        my $self = shift;
        $self->{_indexes} = $_[0] if scalar @_;
        return $self->{_indexes};
    }

    # has _keys
        # isa HashRef
            # One elem per key:
                # hkey is key name;
                    # - is Str ident gen f head subset tha index ranges ovr
                # hval is HashRef of atnms that index ranges over
                    # - structure same as '_heading'
        # default {}
    sub _keys {
        my $self = shift;
        $self->{_keys} = $_[0] if scalar @_;
        return $self->{_keys};
    }

    # If this is made true, no further mutation of S::R head/body allowed,
    # and then it can't be made false again.
    # has _has_frozen_identity
        # isa Bool
        # default 0
    sub _has_frozen_identity {
        my $self = shift;
        $self->{_has_frozen_identity} = $_[0] if scalar @_;
        return $self->{_has_frozen_identity};
    }
    sub has_frozen_identity {
        my $self = shift;
        return $self->{_has_frozen_identity};
    }

###########################################################################

sub new {
    my ($class, @args) = @_;
    $class = (blessed $class) || $class;

    my $params = $class->BUILDARGS( @args );

    my $self = bless {}, $class;

    # Set attribute default values.
    $self->_heading( {} );
    $self->_degree( 0 );
    $self->_body( {} );
    $self->_cardinality( 0 );
    $self->_which( undef );
    $self->_indexes( {} );
    $self->_keys( {} );
    $self->_has_frozen_identity( 0 );

    if (exists $params->{has_frozen_identity}) {
        $self->_has_frozen_identity( $params->{has_frozen_identity} ? 1 : 0 );
    }

    $self->BUILD( $params );

    return $self;
}

###########################################################################

sub BUILDARGS {
    my ($class, @args) = @_;
    if (@args == 1) {
        if (ref $args[0] ne 'HASH') {
            # Constructor was called with a single positional argument.
            return { members => $args[0] };
        }
        else {
            # Constructor was called with (possibly zero) named arguments.
            return { %{$args[0]} };
        }
    }
    elsif ((scalar @args % 2) == 0) {
        # Constructor was called with (possibly zero) named arguments.
        return { @args };
    }
    else {
        # Constructor was called with odd number positional arguments >= 3.
        confess q{new(): Bad arguments list; it must either have an even}
            . q{ number of elements or exactly 1 element.};
    }
}

###########################################################################

sub BUILD {
    my ($self, $args) = @_;
    my ($members, $keys) = @{$args}{'members', 'keys'};

    # Note, $members may be in all of the same formats as a HDMD_Perl_STD
    # Relation value literal payload, but with a few extra trivial options.

    if (!defined $members) {
        # Extra option 1.
        $members = [];
    }
    elsif (!ref $members) {
        # Extra option 2.
        $members = [$members];
    }
    elsif (blessed $members and $members->can( 'does' )
            and $members->does( 'Set::Relation' )
            and !$members->isa( __PACKAGE__ )) {
        # We got a $members that is a Set::Relation-doing class where that
        # class isn't us; so clone it from a dump using public interface.
        $members = $self->_new( $members->export_for_new() );
    }
    confess q{new(): Bad :$members arg; it must be either undefined}
            . q{ or an array-ref or a non-ref or a Set::Relation object.}
        if ref $members ne 'ARRAY'
            and not (blessed $members and $members->isa( __PACKAGE__ ));

    # If we get here, $members is either a Set::Relation::V1 or an ary-ref.

    if (!defined $keys) {
        $keys = [];
    }
    elsif (ref $keys ne 'ARRAY') {
        $keys = [$keys];
    }
    if (any { ref $_ ne 'ARRAY' } @{$keys}) {
        $keys = [$keys];
    }
    for my $key (@{$keys}) {
        confess q{new(): Bad $keys arg; it is not correctly formatted.}
            if ref $key ne 'ARRAY'
                or notall { defined $_ and !ref $_ } @{$key};
    }

    # If we get here, $keys is an Array of Array of Str.

    if (blessed $members and $members->isa( __PACKAGE__ )) {
        # We'll just shallow clone h, copy b of anoth V1 obj's member-set.
        $self->_heading( $members->_heading() );
        $self->_degree( $members->degree() );
        $self->_body( {%{$members->_body()}} );
        $self->_cardinality( $members->cardinality() );
        $self->_keys( {%{$members->_keys()}} );
    }
    elsif (@{$members} == 0) {
        # Input specifies zero attrs + zero tuples.
        # No-op; attr defaults are fine.
    }
    else {
        # Input specifies at least one attr or at least one tuple.
        my $member0 = $members->[0];
        if (!defined $member0) {
            confess q{new(): Bad :$members arg; it is an array ref}
                . q{ but it directly has an undefined element.};
        }
        elsif (!ref $member0) {
            # Input spec at least 1 attr + zero tuples.
            # Each $members elem is expected to be an atnm.
            confess q{new(): Bad :$members arg; it has a non-ref elem,}
                    . q{ indicating it should just be a list of attr}
                    . q{ names, but at least one other elem is}
                    . q{ undefined or is a ref.}
                if notall { defined $_ and !ref $_ } @{$members};
            confess q{new(): Bad :$members arg; it specifies a list of}
                    . q{ attr names with at least one duplicated name.}
                if (uniqstr @{$members}) != @{$members};
            $self->_heading( {CORE::map { ($_ => undef) } @{$members}} );
            $self->_degree( scalar @{$members} );
        }
        elsif (ref $member0 eq 'HASH') {
            # Input spec at least 1 tuple, in named attr format.
            my $heading
                = {CORE::map { ($_ => undef) } CORE::keys %{$member0}};
            my $body = {};
            for my $tuple (@{$members}) {
                confess q{new(): Bad :$members arg; it has a hash-ref}
                        . q{ elem, indicating it should just be a list of}
                        . q{ tuples in named-attr format, but at least one}
                        . q{ other elem is not a hash-ref, or the 2 elems}
                        . q{ don't have exactly the same set of hkeys.}
                    if ref $tuple ne 'HASH'
                        or !$self->_is_identical_hkeys( $heading, $tuple );
                confess q{new(): Bad :$members arg;}
                        . q{ at least one of its hash-ref elems is such}
                        . q{ that there exists circular refs between}
                        . q{ itself or its tuple-valued components.}
                    if $self->_tuple_arg_has_circular_refs( $tuple );
                $tuple = $self->_import_nfmt_tuple( $tuple );
                $body->{$self->_ident_str( $tuple )} = $tuple;
            }
            $self->_heading( $heading );
            $self->_degree( scalar CORE::keys %{$heading} );
            $self->_body( $body );
            $self->_cardinality( scalar CORE::keys %{$body} );
        }
        elsif (ref $member0 eq 'ARRAY') {
            # Input is in ordered attr format.
            my $member1 = $members->[1];
            confess q{new(): Bad :$members arg; it has an array-ref first}
                    . q{ elem, indicating it should just be a list of}
                    . q{ tuples in ordered-attr format, but either}
                    . q{ :$members doesn't have exactly 2 elements or its}
                    . q{ second element isn't also an array-ref.}
                if @{$members} != 2 or ref $member1 ne 'ARRAY';
            # Each $member0 elem is expected to be an atnm.
            confess q{new(): Bad :$members array-ref arg array-ref}
                    . q{ first elem; it should be just be a list of}
                    . q{ attr names, but at least one name}
                    . q{ is undefined or is a ref.}
                if notall { defined $_ and !ref $_ } @{$member0};
            confess q{new(): Bad :$members arg; it specifies a list of}
                    . q{ attr names with at least one duplicated name.}
                if (uniqstr @{$member0}) != @{$member0};
            my $heading = {CORE::map { ($_ => undef) } @{$member0}};
            my $body = {};
            for my $tuple (@{$member1}) {
                confess q{new(): Bad :$members array-ref arg array-ref}
                        . q{ second elem; at least one elem isn't an}
                        . q{ array-ref, or that doesn't have the same}
                        . q{ count of elems as the :$members first elem.}
                    if ref $tuple ne 'ARRAY' or @{$tuple} != @{$member0};
                # Each $tuple elem is expected to be an atvl.
                confess q{new(): Bad :$members arg;}
                        . q{ at least one of its array-ref elems}
                        . q{ is such that there exists circular refs}
                        . q{ between its tuple-valued components.}
                    if any { ref $_ eq 'HASH'
                            and $self->_tuple_arg_has_circular_refs( $_ )
                        } (@{$tuple});
                $tuple = $self->_import_ofmt_tuple( $member0, $tuple );
                $body->{$self->_ident_str( $tuple )} = $tuple;
            }
            $self->_heading( $heading );
            $self->_degree( scalar CORE::keys %{$heading} );
            $self->_body( $body );
            $self->_cardinality( scalar CORE::keys %{$body} );
        }
        else {
            confess q{new(): Bad :$members arg; it is an array-ref but it}
                . q{ has an elem that is neither a defined scalar nor}
                . q{ an array-ref nor a hash-ref.};
        }
    }

    my $self_h = $self->_heading();

    for my $key (@{$keys}) {
        confess q{new(): At least one of the relation keys defined by the}
                . q{ $keys arg isn't a subset of the heading of the}
                . q{ relation defined by the $members arg.}
            if notall { exists $self_h->{$_} } @{$key};
        confess q{new(): The relation defined by the $members arg violates}
                . q{ at least one of the candidate unique key constraints}
                . qq{ defined by the $members arg: [@{$key}].}
            if !$self->_has_key( $key );
    }

    return;
}

###########################################################################

sub _new {
    my ($self, @args) = @_;
    return (blessed $self)->new( @args );
}

###########################################################################

sub export_for_new {
    my ($self, $want_ord_attrs, $allow_dup_tuples) = @_;
    return {
        'members' => $self->_members(
            'export_for_new', '$want_ord_attrs', $want_ord_attrs ),
        'keys' => $self->keys(),
        # Note, we make an exception by not exporting the
        # 'has_frozen_identity' object attribute even though the 'new'
        # constructor can take an argument to user-initialize it;
        # there doesn't seem to be a point, as if a user wanted an
        # immutable clone of an immutable object, just use the original;
        # or if they wanted a mutable clone of a mutable object, then
        # mutable is what they get by default anyway; more likely they want
        # a mutable clone of an immutable object.
    };
}

###########################################################################

sub which {
    my ($self) = @_;
    my $ident_str = $self->_which();
    if (!defined $ident_str) {
        $self->_has_frozen_identity( 1 );
        my $hs = $self->_heading_ident_str( $self->_heading() );
        my $bs = CORE::join qq{,\n}, sort (CORE::keys %{$self->_body()});
        my $vstr = "H=$hs;\nB={$bs}";
        $ident_str = 'Relation:' . (length $vstr) . ':{' . $vstr . '}';
        $self->_which( $ident_str );
    }
    return $ident_str;
}

###########################################################################

sub members {
    my ($self, $want_ord_attrs, $allow_dup_tuples) = @_;
    return $self->_members(
        'members', '$want_ord_attrs', $want_ord_attrs );
}

sub _members {
    my ($self, $rtn_nm, $arg_nm, $want_ord_attrs) = @_;
    if ($want_ord_attrs) {
        my $ord_attr_names = $self->_normalize_true_want_ord_attrs_arg(
            $rtn_nm, $arg_nm, $want_ord_attrs );
        return [$ord_attr_names, [CORE::map {
                $self->_export_ofmt_tuple( $ord_attr_names, $_ )
            } values %{$self->_body()}]];
    }
    elsif ((CORE::keys %{$self->_body()}) == 0) {
        # We have zero tuples, just export attr names.
        return [sort (CORE::keys %{$self->_heading()})];
    }
    else {
        # We have at least one tuple, export in named-attr format.
        return [CORE::map { $self->_export_nfmt_tuple( $_ ) }
            values %{$self->_body()}];
    }
}

###########################################################################

sub heading {
    my ($self) = @_;
    return [sort (CORE::keys %{$self->_heading()})];
}

###########################################################################

sub body {
    my ($self, $want_ord_attrs, $allow_dup_tuples) = @_;
    if ($want_ord_attrs) {
        my $ord_attr_names = $self->_normalize_true_want_ord_attrs_arg(
            'body', '$want_ord_attrs', $want_ord_attrs );
        return [CORE::map { $self->_export_ofmt_tuple(
            $ord_attr_names, $_ ) } values %{$self->_body()}];
    }
    else {
        return [CORE::map { $self->_export_nfmt_tuple( $_ ) }
            values %{$self->_body()}];
    }
}

###########################################################################

sub _normalize_true_want_ord_attrs_arg {
    my ($self, $rtn_nm, $arg_nm, $want_ord_attrs) = @_;

    my $heading = $self->_heading();

    my $attr_names = [CORE::keys %{$heading}];
    confess qq{$rtn_nm(): Bad $arg_nm arg;}
            . q{ it must be either undefined|false or the scalar value '1'}
            . q{ or an array-ref of attr names whose degree and}
            . q{ elements match the heading of the invocant.}
        if not (!ref $want_ord_attrs and $want_ord_attrs eq '1'
            or ref $want_ord_attrs eq 'ARRAY'
                and @{$want_ord_attrs} == @{$attr_names}
                and all { exists $heading->{$_} } @{$want_ord_attrs});

    return
        $want_ord_attrs eq '1' ? [sort @{$attr_names}] : $want_ord_attrs;
}

###########################################################################

sub slice {
    my ($self, $attr_names, $want_ord_attrs, $allow_dup_tuples) = @_;

    (my $proj_h, $attr_names)
        = $self->_atnms_hr_from_assert_valid_atnms_arg(
        'slice', '$attr_names', $attr_names );
    my (undef, undef, $proj_only)
        = $self->_ptn_conj_and_disj( $self->_heading(), $proj_h );
    confess q{slice(): Bad $attr_names arg; that attr list}
            . q{ isn't a subset of the invocant's heading.}
        if @{$proj_only} > 0;

    if ($want_ord_attrs) {
        confess q{slice(): Bad $want_ord_attrs arg; it must be}
                . q{ either undefined|false or the scalar value '1'.}
            if $want_ord_attrs ne '1';
        return [CORE::map { $self->_export_ofmt_tuple(
            $attr_names, $_ ) } values %{$self->_body()}];
    }
    else {
        return [CORE::map {
            my $t = $_;
            $t = {CORE::map { ($_ => $t->{$_}) } @{$attr_names}};
            $self->_export_nfmt_tuple( $t );
        } values %{$self->_body()}];
    }
}

###########################################################################

sub attr {
    my ($self, $name, $allow_dup_tuples) = @_;

    $self->_assert_valid_atnm_arg( 'attr', '$name', $name );
    confess q{attr(): Bad $name arg; that attr name}
            . q{ doesn't match an attr of the invocant's heading.}
        if !exists $self->_heading()->{$name};

    return [CORE::map {
            my $atvl = $_->{$name}->[0];
            if (ref $atvl eq 'HASH') {
                $atvl = $self->_export_nfmt_tuple( $atvl );
            }
            $atvl;
        } values %{$self->_body()}];
}

###########################################################################

sub keys {
    my ($self) = @_;
    return [CORE::map { [sort @{$_}] } values %{$self->_keys()}];
}

###########################################################################

sub _normalize_same_heading_tuples_arg {
    my ($r, $rtn_nm, $arg_nm, $t) = @_;

    my $r_h = $r->_heading();

    if (ref $t eq 'HASH') {
        $t = [$t];
    }
    confess qq{$rtn_nm(): Bad $arg_nm arg; it must be}
            . q{ an array-ref or a hash-ref.}
        if ref $t ne 'ARRAY';
    for my $tuple (@{$t}) {
        confess qq{$rtn_nm(): Bad $arg_nm arg elem;}
                . q{ it isn't a hash-ref, or it doesn't have exactly the}
                . q{ same set of attr names as the invocant.}
            if ref $tuple ne 'HASH'
                or !$r->_is_identical_hkeys( $r_h, $tuple );
        confess qq{$rtn_nm(): Bad $arg_nm arg elem;}
                . q{ it is a hash-ref, and there exist circular refs}
                . q{ between itself or its tuple-valued components.}
            if $r->_tuple_arg_has_circular_refs( $tuple );
    }

    return $t;
}

###########################################################################

sub _tuple_arg_has_circular_refs {
    # This routine just checks that no Hash which would be treated as
    # being of a value type contains itself as a component, where the
    # component and any intermediate components are treated as value types.
    # It *is* fine for a Hash to contain the same other Hash more than once
    # such that the other is a sibling/cousin/etc to itself.
    my ($self, $tuple, $ancs_of_tup_atvls) = @_;
    $ancs_of_tup_atvls = $ancs_of_tup_atvls ? {%{$ancs_of_tup_atvls}} : {};
    $ancs_of_tup_atvls->{refaddr $tuple} = undef;
    for my $atvl (values %{$tuple}) {
        if (ref $atvl eq 'HASH') {
            return 1
                if exists $ancs_of_tup_atvls->{refaddr $atvl};
            return 1
                if $self->_tuple_arg_has_circular_refs(
                    $atvl, $ancs_of_tup_atvls );
        }
    }
    return 0;
}

###########################################################################

sub _self_is_component_of_tuple_arg {
    my ($self, $tuple) = @_;
    for my $atvl (values %{$tuple}) {
        if (blessed $atvl and $atvl->isa( __PACKAGE__ )) {
            return 1
                if refaddr $atvl == refaddr $self;
        }
        elsif (ref $atvl eq 'HASH') {
            return 1
                if $self->_self_is_component_of_tuple_arg( $atvl );
        }
    }
    return 0;
}

###########################################################################

sub _is_identical_hkeys {
    my ($self, $h1, $h2) = @_;
    my $h1_hkeys = [CORE::keys %{$h1}];
    my $h2_hkeys = [CORE::keys %{$h2}];
    return (@{$h1_hkeys} == @{$h2_hkeys}
        and all { exists $h1->{$_} } @{$h2_hkeys});
}

###########################################################################

sub _heading_ident_str {
    my ($self, $heading) = @_;
    my $vstr = CORE::join q{,}, CORE::map {
            'Atnm:' . (length $_) . ':<' . $_ . '>'
        } sort (CORE::keys %{$heading});
    return 'Heading:' . (length $vstr) . ':{' . $vstr . '}';
}

sub _ident_str {
    # Note, we assume that any hash-ref arg we get is specifically in
    # internal tuple format, meaning each hval is a 2-elem array etc,
    # and that this is recursive for hash-ref hvals of said.
    my ($self, $value) = @_;
    my $ident_str;
    if (!defined $value) {
        # The Perl undef is equal to itself, distinct from all def values.
        $ident_str = 'Undef';
    }
    elsif (!ref $value) {
        # Treat all defined non-ref values as their string representation.
        $ident_str = 'Scalar:' . (length $value) . ':<' . $value . '>';
    }
    elsif (!blessed $value) {
        # By default, every non-object reference is distinct, and its
        # identity is its memory address; the exception is if the reference
        # is a hash-ref, in which case it is treated as an internal tuple.
        if (ref $value eq 'HASH') {
            my $vstr = CORE::join q{,}, CORE::map {
                my $atnm = 'Atnm:' . (length $_) . ':<' . $_ . '>';
                my $atvl = $value->{$_}->[1];
                "N=$atnm;V=$atvl";
            } sort (CORE::keys %{$value});
            $ident_str = 'Tuple:' . (length $vstr) . ':{' . $vstr . '}';
        }
        else {
            my $vstr = "$value";
            $ident_str = 'Ref:' . (length $vstr) . ':<' . $vstr . '>';
        }
    }
    else {
        # By default, every object instance is distinct, and its identity
        # is its memory address; the exception is if the object is a
        # Set::Relation::V1 or if it overloads stringification.
        if ($value->isa( __PACKAGE__ )) {
            $ident_str = $value->which(); # 'Relation:...'
        }
        else {
            my $vstr = "$value";
            $ident_str = 'Object[' . (blessed $value) . ']:'
                . (length $vstr) . ':<' . $vstr . '>';
        }
    }
    return $ident_str;
}

###########################################################################

sub _import_nfmt_tuple {
    my ($self, $tuple) = @_;
    return {CORE::map {
        my $atnm = $_;
        my $atvl = $tuple->{$_};
        if (ref $atvl eq 'HASH') {
            $atvl = $self->_import_nfmt_tuple( $atvl );
        }
        elsif (blessed $atvl and $atvl->can( 'does' )
                and $atvl->does( 'Set::Relation' )
                and !$atvl->isa( __PACKAGE__ )) {
            $atvl = $self->_new( $atvl );
        }
        ($atnm => [$atvl, $self->_ident_str( $atvl )]);
    } CORE::keys %{$tuple}};
}

sub _export_nfmt_tuple {
    my ($self, $tuple) = @_;
    return {CORE::map {
        my $atnm = $_;
        my $atvl = $tuple->{$_}->[0];
        if (ref $atvl eq 'HASH') {
            $atvl = $self->_export_nfmt_tuple( $atvl );
        }
        ($atnm => $atvl);
    } CORE::keys %{$tuple}};
}

sub _import_ofmt_tuple {
    my ($self, $atnms, $atvls) = @_;
    return {CORE::map {
        my $atnm = $atnms->[$_];
        my $atvl = $atvls->[$_];
        if (ref $atvl eq 'HASH') {
            $atvl = $self->_import_nfmt_tuple( $atvl );
        }
        elsif (blessed $atvl and $atvl->can( 'does' )
                and $atvl->does( 'Set::Relation' )
                and !$atvl->isa( __PACKAGE__ )) {
            $atvl = $self->_new( $atvl );
        }
        ($atnm => [$atvl, $self->_ident_str( $atvl )]);
    } 0..$#{$atnms}};
}

sub _export_ofmt_tuple {
    my ($self, $atnms, $tuple) = @_;
    return [CORE::map {
        my $atvl = $tuple->{$_}->[0];
        if (ref $atvl eq 'HASH') {
            $atvl = $self->_export_nfmt_tuple( $atvl );
        }
        $atvl;
    } @{$atnms}];
}

###########################################################################

sub is_nullary {
    my ($topic) = @_;
    return $topic->degree() == 0;
}

sub has_attrs {
    my ($topic, $attr_names) = @_;
    (my $proj_h, $attr_names)
        = $topic->_atnms_hr_from_assert_valid_atnms_arg(
        'has_attrs', '$attr_names', $attr_names );
    my (undef, undef, $proj_only)
        = $topic->_ptn_conj_and_disj( $topic->_heading(), $proj_h );
    return @{$proj_only} == 0;
}

sub attr_names {
    my ($topic) = @_;
    return [sort (CORE::keys %{$topic->_heading()})];
}

###########################################################################

sub count {
    my ($self, @args) = @_;
    return $self->cardinality( @args );
}

sub is_empty {
    my ($topic) = @_;
    return $topic->cardinality() == 0;
}

sub has_member {
    my ($r, $t) = @_;
    $t = $r->_normalize_same_heading_tuples_arg( 'has_member', '$t', $t );
    my $r_b = $r->_body();
    return all {
            exists $r_b->{$r->_ident_str( $r->_import_nfmt_tuple( $_ ) )}
        } @{$t};
}

###########################################################################

sub has_key {
    my ($topic, $attr_names) = @_;
    (undef, $attr_names) = $topic->_atnms_hr_from_assert_valid_atnms_arg(
        'has_key', '$attr_names', $attr_names );
    my $topic_h = $topic->_heading();
    confess q{has_key(): Bad $attr_names arg; that attr list}
            . q{ isn't a subset of the invocant's heading.}
        if notall { exists $topic_h->{$_} } @{$attr_names};
    return $topic->_has_key( $attr_names );
}

sub _has_key {
    my ($topic, $attr_names) = @_;

    my $subheading = {CORE::map { ($_ => undef) } @{$attr_names}};
    my $subheading_ident_str = $topic->_heading_ident_str( $subheading );
    my $keys = $topic->_keys();

    return 1
        if exists $keys->{$subheading_ident_str};

    my $index = $topic->_want_index( $attr_names );

    return 0
        if notall { (CORE::keys %{$_}) == 1 } values %{$index};

    $keys->{$subheading_ident_str} = $subheading;
    return 1;
}

###########################################################################

sub empty {
    my ($topic) = @_;
    if ($topic->is_empty()) {
        return $topic;
    }
    my $result = $topic->_new();
    $result->_heading( $topic->_heading() );
    $result->_degree( $topic->_degree() );
    return $result;
}

sub insertion {
    my ($r, $t) = @_;
    $t = $r->_normalize_same_heading_tuples_arg( 'insertion', '$t', $t );
    if (@{$t} == 0) {
        return $r;
    }
    return $r->_new( $r )->_insert( $t );
}

sub deletion {
    my ($r, $t) = @_;
    $t = $r->_normalize_same_heading_tuples_arg( 'deletion', '$t', $t );
    if (@{$t} == 0) {
        return $r;
    }
    return $r->_new( $r )->_delete( $t );
}

###########################################################################

sub rename {
    my ($topic, $map) = @_;

    confess q{rename(): Bad $map arg; it must be a hash-ref.}
        if ref $map ne 'HASH';
    confess q{rename(): Bad $map arg;}
            . q{ its hash elem values should be just be a list of attr}
            . q{ names, but at least one name is undefined or isa ref.}
        if notall { defined $_ and !ref $_ } values %{$map};
    confess q{rename(): Bad $map arg;}
            . q{ its hash elem values specify a list of}
            . q{ attr names with at least one duplicated name.}
        if (uniqstr values %{$map}) != (CORE::keys %{$map});

    my ($topic_attrs_to_ren, $topic_attrs_no_ren, $map_hvals_not_in_topic)
        = $topic->_ptn_conj_and_disj(
            $topic->_heading(), {reverse %{$map}} );
    confess q{rename(): Bad $map arg; that list of attrs to be renamed,}
            . q{ the hash values, isn't a subset of th invocant's heading.}
        if @{$map_hvals_not_in_topic} > 0;

    my ($map_hkeys_same_as_topic_no_ren, undef, undef)
        = $topic->_ptn_conj_and_disj(
            {CORE::map { ($_ => undef) } @{$topic_attrs_no_ren}}, $map );
    confess q{rename(): Bad $map arg; at least one key of that hash,}
            . q{ a new name for an attr of the invocant to rename,}
            . q{ duplicates an attr of the invocant not being renamed.}
        if @{$map_hkeys_same_as_topic_no_ren} > 0;

    return $topic->_rename( $map );
}

sub _rename {
    my ($topic, $map) = @_;

    # Remove any explicit no-ops of an attr being renamed to the same name.
    $map = {CORE::map { ($_ => $map->{$_}) }
        grep { $map->{$_} ne $_ } CORE::keys %{$map}};

    if ((scalar CORE::keys %{$map}) == 0) {
        # Rename of zero attrs of input yields the input.
        return $topic;
    }

    # Expand map to specify all topic attrs being renamed to something.
    my $inv_map = {reverse %{$map}};
    $map = {CORE::map { ((
            exists $inv_map->{$_} ? $inv_map->{$_} : $_
        ) => $_) } CORE::keys %{$topic->_heading()}};

    my $result = $topic->_new();

    $result->_heading( {CORE::map { ($_ => undef) } CORE::keys %{$map}} );
    $result->_degree( $topic->degree() );

    my $result_b = $result->_body();

    for my $topic_t (values %{$topic->_body()}) {
        my $result_t = {CORE::map {
                ($_ => $topic_t->{$map->{$_}})
            } CORE::keys %{$map}};
        my $result_t_ident_str = $topic->_ident_str( $result_t );
        $result_b->{$result_t_ident_str} = $result_t;
    }
    $result->_cardinality( $topic->cardinality() );

    return $result;
}

###########################################################################

sub projection {
    my ($topic, $attr_names) = @_;

    (my $proj_h, $attr_names)
        = $topic->_atnms_hr_from_assert_valid_atnms_arg(
        'projection', '$attr_names', $attr_names );
    my (undef, undef, $proj_only)
        = $topic->_ptn_conj_and_disj( $topic->_heading(), $proj_h );
    confess q{projection(): Bad $attr_names arg; that attr list}
            . q{ isn't a subset of the invocant's heading.}
        if @{$proj_only} > 0;

    return $topic->_projection( $attr_names );
}

sub _projection {
    my ($topic, $attr_names) = @_;

    if (@{$attr_names} == 0) {
        # Projection of zero attrs yields identity relation zero or one.
        if ($topic->is_empty()) {
            return $topic->_new();
        }
        else {
            return $topic->_new( [ {} ] );
        }
    }
    if (@{$attr_names} == $topic->degree()) {
        # Projection of all attrs of input yields the input.
        return $topic;
    }

    my $result = $topic->_new();

    $result->_heading( {CORE::map { ($_ => undef) } @{$attr_names}} );
    $result->_degree( scalar @{$attr_names} );

    my $result_b = $result->_body();

    for my $topic_t (values %{$topic->_body()}) {
        my $result_t
            = {CORE::map { ($_ => $topic_t->{$_}) } @{$attr_names}};
        my $result_t_ident_str = $topic->_ident_str( $result_t );
        if (!exists $result_b->{$result_t_ident_str}) {
            $result_b->{$result_t_ident_str} = $result_t;
        }
    }
    $result->_cardinality( scalar CORE::keys %{$result_b} );

    return $result;
}

sub cmpl_proj {
    my ($topic, $attr_names) = @_;

    my $topic_h = $topic->_heading();

    (my $cproj_h, $attr_names)
        = $topic->_atnms_hr_from_assert_valid_atnms_arg(
        'cmpl_proj', '$attr_names', $attr_names );
    my (undef, undef, $cproj_only)
        = $topic->_ptn_conj_and_disj( $topic_h, $cproj_h );
    confess q{cmpl_proj(): Bad $attr_names arg; that attr list}
            . q{ isn't a subset of the invocant's heading.}
        if @{$cproj_only} > 0;

    return $topic->_projection(
        [grep { !$cproj_h->{$_} } CORE::keys %{$topic_h}] );
}

###########################################################################

sub wrap {
    my ($topic, $outer, $inner) = @_;

    $topic->_assert_valid_atnm_arg( 'wrap', '$outer', $outer );
    (my $inner_h, $inner) = $topic->_atnms_hr_from_assert_valid_atnms_arg(
        'wrap', '$inner', $inner );

    my (undef, $topic_attrs_no_wr, $inner_attrs_not_in_topic)
        = $topic->_ptn_conj_and_disj( $topic->_heading(), $inner_h );
    confess q{wrap(): Bad $inner arg; that list of attrs to be wrapped}
            . q{ isn't a subset of the invocant's heading.}
        if @{$inner_attrs_not_in_topic} > 0;
    confess q{wrap(): Bad $outer arg; that name for a new attr to add}
            . q{ to the invocant, consisting of wrapped invocant attrs,}
            . q{ duplicates an attr of the invocant not being wrapped.}
        if any { $_ eq $outer } @{$topic_attrs_no_wr};

    return $topic->_wrap( $outer, $inner, $topic_attrs_no_wr );
}

sub _wrap {
    my ($topic, $outer, $inner, $topic_attrs_no_wr) = @_;

    my $result = $topic->_new();

    $result->_heading(
        {CORE::map { ($_ => undef) } @{$topic_attrs_no_wr}, $outer} );
    $result->_degree( @{$topic_attrs_no_wr} + 1 );

    my $topic_b = $topic->_body();
    my $result_b = $result->_body();

    if ($topic->is_empty()) {
        # An empty $topic means an empty result.
        # So $result_b is already correct.
    }
    elsif (@{$inner} == 0) {
        # Wrap zero $topic attrs as new attr.
        # So this is a simple static extension of $topic w static $outer.
        my $inner_t = {};
        my $outer_atvl = [$inner_t, $topic->_ident_str( $inner_t )];
        for my $topic_t (values %{$topic_b}) {
            my $result_t = {$outer => $outer_atvl, {%{$topic_t}}};
            my $result_t_ident_str = $topic->_ident_str( $result_t );
            $result_b->{$result_t_ident_str} = $result_t;
        }
    }
    elsif (@{$topic_attrs_no_wr} == 0) {
        # Wrap all $topic attrs as new attr.
        for my $topic_t_ident_str (CORE::keys %{$topic_b}) {
            my $result_t = {$outer => [$topic_b->{$topic_t_ident_str},
                $topic_t_ident_str]};
            my $result_t_ident_str = $topic->_ident_str( $result_t );
            $result_b->{$result_t_ident_str} = $result_t;
        }
    }
    else {
        # Wrap at least one but not all $topic attrs as new attr.
        for my $topic_t (values %{$topic_b}) {
            my $inner_t = {CORE::map { ($_ => $topic_t->{$_}) } @{$inner}};
            my $outer_atvl = [$inner_t, $topic->_ident_str( $inner_t )];
            my $result_t = {
                $outer => $outer_atvl,
                CORE::map { ($_ => $topic_t->{$_}) } @{$topic_attrs_no_wr}
            };
            my $result_t_ident_str = $topic->_ident_str( $result_t );
            $result_b->{$result_t_ident_str} = $result_t;
        }
    }
    $result->_cardinality( $topic->cardinality() );

    return $result;
}

sub cmpl_wrap {
    my ($topic, $outer, $cmpl_inner) = @_;

    $topic->_assert_valid_atnm_arg( 'cmpl_wrap', '$outer', $outer );
    (my $cmpl_inner_h, $cmpl_inner)
        = $topic->_atnms_hr_from_assert_valid_atnms_arg(
            'cmpl_wrap', '$cmpl_inner', $cmpl_inner );

    my $topic_h = $topic->_heading();

    confess q{cmpl_wrap(): Bad $cmpl_inner arg; that attr list}
            . q{ isn't a subset of the invocant's heading.}
        if notall { exists $topic_h->{$_} } @{$cmpl_inner};

    my $inner = [grep { !$cmpl_inner_h->{$_} } CORE::keys %{$topic_h}];
    my $inner_h = {CORE::map { $_ => undef } @{$inner}};

    my (undef, $topic_attrs_no_wr, undef)
        = $topic->_ptn_conj_and_disj( $topic_h, $inner_h );
    confess q{cmpl_wrap(): Bad $outer arg; that name for a new attr to add}
            . q{ to the invocant, consisting of wrapped invocant attrs,}
            . q{ duplicates an attr of the invocant not being wrapped.}
        if any { $_ eq $outer } @{$topic_attrs_no_wr};

    return $topic->_wrap( $outer, $inner, $topic_attrs_no_wr );
}

###########################################################################

sub unwrap {
    my ($topic, $inner, $outer) = @_;

    (my $inner_h, $inner) = $topic->_atnms_hr_from_assert_valid_atnms_arg(
        'unwrap', '$inner', $inner );
    $topic->_assert_valid_atnm_arg( 'unwrap', '$outer', $outer );

    my $topic_h = $topic->_heading();

    confess q{unwrap(): Bad $outer arg; that attr name}
            . q{ doesn't match an attr of the invocant's heading.}
        if !exists $topic_h->{$outer};

    my $topic_h_except_outer = {%{$topic_h}};
    CORE::delete $topic_h_except_outer->{$outer};

    my ($inner_attrs_dupl_topic, $topic_attrs_no_uwr, undef)
        = $topic->_ptn_conj_and_disj( $topic_h_except_outer, $inner_h );
    confess q{unwrap(): Bad $inner arg; at least one name in that attr}
            . q{ list, which the invocant would be extended with when}
            . q{ unwrapping $topic{$outer}, duplicates an attr of the}
            . q{ invocant not being unwrapped.}
        if @{$inner_attrs_dupl_topic} > 0;

    my $topic_b = $topic->_body();

    for my $topic_t (values %{$topic_b}) {
        my $inner_t = $topic_t->{$outer}->[0];
        confess q{unwrap(): Can't unwrap $topic{$outer} because there is}
                . q{ not a same-heading tuple value for the $outer attr of}
                . q{ every tuple of $topic whose heading matches $inner.}
            if ref $inner_t ne 'HASH'
                or !$topic->_is_identical_hkeys( $inner_h, $inner_t );
    }

    my $result = $topic->_new();

    $result->_heading( {%{$topic_h_except_outer}, %{$inner_h}} );
    $result->_degree( @{$topic_attrs_no_uwr} + @{$inner} );

    my $result_b = $result->_body();

    if ($topic->is_empty()) {
        # An empty $topic means an empty result.
        # So $result_b is already correct.
    }
    elsif (@{$topic_attrs_no_uwr} == 0) {
        # Only $topic attr is $outer, all result attrs from $outer unwrap.
        for my $topic_t (values %{$topic_b}) {
            my $outer_atvl = $topic_t->{$outer};
            $result_b->{$outer_atvl->[1]} = $outer_atvl->[0];
        }
    }
    elsif (@{$inner} == 0) {
        # Unwrap of $outer adds zero attrs to $topic.
        # So this is a simple projection of $topic excising $outer.
        for my $topic_t (values %{$topic_b}) {
            my $result_t = {
                CORE::map { ($_ => $topic_t->{$_}) } @{$topic_attrs_no_uwr}
            };
            my $result_t_ident_str = $topic->_ident_str( $result_t );
            $result_b->{$result_t_ident_str} = $result_t;
        }
    }
    else {
        # Result has at least 1 attr from $outer, at least 1 not from it.
        for my $topic_t (values %{$topic_b}) {
            my $result_t = {
                %{$topic_t->{$outer}->[0]},
                CORE::map { ($_ => $topic_t->{$_}) } @{$topic_attrs_no_uwr}
            };
            my $result_t_ident_str = $topic->_ident_str( $result_t );
            $result_b->{$result_t_ident_str} = $result_t;
        }
    }
    $result->_cardinality( $topic->cardinality() );

    return $result;
}

###########################################################################

sub group {
    my ($topic, $outer, $inner) = @_;

    $topic->_assert_valid_atnm_arg( 'group', '$outer', $outer );
    (my $inner_h, $inner) = $topic->_atnms_hr_from_assert_valid_atnms_arg(
        'group', '$inner', $inner );

    my (undef, $topic_attrs_no_gr, $inner_attrs_not_in_topic)
        = $topic->_ptn_conj_and_disj( $topic->_heading(), $inner_h );
    confess q{group(): Bad $inner arg; that list of attrs to be grouped}
            . q{ isn't a subset of the invocant's heading.}
        if @{$inner_attrs_not_in_topic} > 0;
    confess q{group(): Bad $outer arg; that name for a new attr to add}
            . q{ to the invocant, consisting of grouped invocant attrs,}
            . q{ duplicates an attr of the invocant not being grouped.}
        if any { $_ eq $outer } @{$topic_attrs_no_gr};

    return $topic->_group( $outer, $inner, $topic_attrs_no_gr, $inner_h );
}

sub _group {
    my ($topic, $outer, $inner, $topic_attrs_no_gr, $inner_h) = @_;

    my $result = $topic->_new();

    $result->_heading(
        {CORE::map { ($_ => undef) } @{$topic_attrs_no_gr}, $outer} );
    $result->_degree( @{$topic_attrs_no_gr} + 1 );

    if ($topic->is_empty()) {
        # An empty $topic means an empty result.
        # So result body is already correct.
    }
    elsif (@{$inner} == 0) {
        # Group zero $topic attrs as new attr.
        # So this is a simple static extension of $topic w static $outer.
        my $result_b = $result->_body();
        my $inner_r = $topic->_new( [ {} ] );
        my $outer_atvl = [$inner_r, $inner_r->which()];
        for my $topic_t (values %{$topic->_body()}) {
            my $result_t = {$outer => $outer_atvl, {%{$topic_t}}};
            my $result_t_ident_str = $topic->_ident_str( $result_t );
            $result_b->{$result_t_ident_str} = $result_t;
        }
        $result->_cardinality( $topic->cardinality() );
    }
    elsif (@{$topic_attrs_no_gr} == 0) {
        # Group all $topic attrs as new attr.
        # So $topic is just used as sole attr of sole tuple of result.
        my $result_t = {$outer => [$topic, $topic->which()]};
        my $result_t_ident_str = $topic->_ident_str( $result_t );
        $result->_body( {$result_t_ident_str => $result_t} );
        $result->_cardinality( 1 );
    }
    else {
        # Group at least one but not all $topic attrs as new attr.
        my $result_b = $result->_body();
        my $topic_index = $topic->_want_index( $topic_attrs_no_gr );
        for my $matched_topic_b (values %{$topic_index}) {

            my $inner_r = $topic->_new();
            $inner_r->_heading( $inner_h );
            $inner_r->_degree( scalar @{$inner} );
            my $inner_b = $inner_r->_body();
            for my $topic_t (values %{$matched_topic_b}) {
                my $inner_t
                    = {CORE::map { ($_ => $topic_t->{$_}) } @{$inner}};
                $inner_b->{$topic->_ident_str( $inner_t )} = $inner_t;
            }
            $inner_r->_cardinality(
                scalar CORE::keys %{$matched_topic_b} );
            my $outer_atvl = [$inner_r, $inner_r->which()];

            my $any_mtpt = (values %{$matched_topic_b})[0];

            my $result_t = {
                $outer => $outer_atvl,
                CORE::map { ($_ => $any_mtpt->{$_}) } @{$topic_attrs_no_gr}
            };
            my $result_t_ident_str = $topic->_ident_str( $result_t );
            $result_b->{$result_t_ident_str} = $result_t;
        }
        $result->_cardinality( scalar CORE::keys %{$topic_index} );
    }

    return $result;
}

sub cmpl_group {
    my ($topic, $outer, $group_per) = @_;

    $topic->_assert_valid_atnm_arg( 'cmpl_group', '$outer', $outer );
    (my $group_per_h, $group_per)
        = $topic->_atnms_hr_from_assert_valid_atnms_arg(
            'cmpl_group', '$group_per', $group_per );

    my $topic_h = $topic->_heading();

    confess q{cmpl_group(): Bad $group_per arg; that attr list}
            . q{ isn't a subset of the invocant's heading.}
        if notall { exists $topic_h->{$_} } @{$group_per};

    my $inner = [grep { !$group_per_h->{$_} } CORE::keys %{$topic_h}];
    my $inner_h = {CORE::map { $_ => undef } @{$inner}};

    my (undef, $topic_attrs_no_gr, undef)
        = $topic->_ptn_conj_and_disj( $topic_h, $inner_h );
    confess q{cmpl_group(): Bad $outer arg; that name for a new attr to}
            . q{ add to th invocant, consisting of grouped invocant attrs,}
            . q{ duplicates an attr of the invocant not being grouped.}
        if any { $_ eq $outer } @{$topic_attrs_no_gr};

    return $topic->_group( $outer, $inner, $topic_attrs_no_gr, $inner_h );
}

###########################################################################

sub ungroup {
    my ($topic, $inner, $outer) = @_;

    (my $inner_h, $inner) = $topic->_atnms_hr_from_assert_valid_atnms_arg(
        'ungroup', '$inner', $inner );
    $topic->_assert_valid_atnm_arg( 'ungroup', '$outer', $outer );

    my $topic_h = $topic->_heading();

    confess q{ungroup(): Bad $outer arg; that attr name}
            . q{ doesn't match an attr of the invocant's heading.}
        if !exists $topic_h->{$outer};

    my $topic_h_except_outer = {%{$topic_h}};
    CORE::delete $topic_h_except_outer->{$outer};

    my ($inner_attrs_dupl_topic, $topic_attrs_no_ugr, undef)
        = $topic->_ptn_conj_and_disj( $topic_h_except_outer, $inner_h );
    confess q{ungroup(): Bad $inner arg; at least one name in that attr}
            . q{ list, which the invocant would be extended with when}
            . q{ ungrouping $topic{$outer}, duplicates an attr of the}
            . q{ invocant not being ungrouped.}
        if @{$inner_attrs_dupl_topic} > 0;

    my $topic_b = $topic->_body();

    for my $topic_t (values %{$topic_b}) {
        my $inner_r = $topic_t->{$outer}->[0];
        confess q{ungroup(): Can't ungroup $topic{$outer} because there is}
                . q{ not a same-heading relation val for the $outer attr}
                . q{ of every tuple of $topic whose head matches $inner.}
            if !blessed $inner_r or !$inner_r->isa( __PACKAGE__ )
                or !$topic->_is_identical_hkeys(
                    $inner_h, $inner_r->_heading() );
    }

    if ($topic->degree() == 1) {
        # Ungroup of a unary relation is the N-adic union of its sole
        # attribute's value across all tuples.
        return $topic->_new( $inner )
            ->_union( [CORE::map { $_->{$outer} } values %{$topic_b}] );
    }

    # If we get here, the input relation is not unary.

    my $result = $topic->_new();

    $result->_heading( {%{$topic_h_except_outer}, %{$inner_h}} );
    $result->_degree( @{$topic_attrs_no_ugr} + @{$inner} );

    my $topic_tuples_w_nonemp_inn
        = [grep { !$_->{$outer}->is_empty() } values %{$topic_b}];

    if (@{$topic_tuples_w_nonemp_inn} == 0) {
        # An empty post-basic-filtering $topic means an empty result.
        # So result body is already correct.
    }
    elsif (@{$inner} == 0) {
        # Ungroup of $outer adds zero attrs to $topic.
        # So this is a simple proj of post-basic-filt $topic excis $outer.
        my $result_b = $result->_body();
        for my $topic_t (@{$topic_tuples_w_nonemp_inn}) {
            my $result_t = {
                CORE::map { ($_ => $topic_t->{$_}) } @{$topic_attrs_no_ugr}
            };
            my $result_t_ident_str = $topic->_ident_str( $result_t );
            $result_b->{$result_t_ident_str} = $result_t;
        }
        $result->_cardinality( scalar @{$topic_tuples_w_nonemp_inn} );
    }
    else {
        # Result has at least 1 attr from $outer, at least 1 not from it.
        my $result_b = $result->_body();
        for my $topic_t (@{$topic_tuples_w_nonemp_inn}) {
            my $no_ugr_t = {CORE::map { ($_ => $topic_t->{$_}) }
                @{$topic_attrs_no_ugr}};
            my $inner_r = $topic_t->{$outer}->[0];
            for my $inner_t (values %{$inner_r->_body()}) {
                my $result_t = {%{$inner_t}, %{$no_ugr_t}};
                $result_b->{$topic->_ident_str( $result_t )} = $result_t;
            }
        }
        $result->_cardinality( scalar CORE::keys %{$result_b} );
    }

    return $result;
}

###########################################################################

sub tclose {
    my ($topic) = @_;

    confess q{tclose(): This method may only be invoked on a}
            . q{ Set::Relation object with exactly 2 (same-typed) attrs.}
        if $topic->degree() != 2;

    if ($topic->cardinality() < 2) {
        # Can't create paths of 2+ arcs when not more than 1 arc exists.
        return $topic;
    }

    # If we get here, there are at least 2 arcs, so there is a chance they
    # may connect into longer paths.

    my ($atnm1, $atnm2) = sort (CORE::keys %{$topic->_heading()});

    return $topic->_rename( { 'x' => $atnm1, 'y' => $atnm2 } )
        ->_tclose_of_xy()
        ->_rename( { $atnm1 => 'x', $atnm2 => 'y' } );
}

# TODO: Reimplement tclose to do all the work internally rather
# than farming out to rename/join/projection/union/etc; this should make
# performance an order of magnitude better and without being complicated.

sub _tclose_of_xy {
    my ($xy) = @_;

    my $xyz = $xy->_rename( { 'y' => 'x', 'z' => 'y' } )
        ->_regular_join( $xy, ['y'], ['z'], ['x'] );

    if ($xyz->is_empty()) {
        # No paths of xy connect to any other paths of xy.
        return $xy;
    }

    # If we get here, then at least one pair of paths in xy can connect
    # to form a longer path.

    my $ttt = $xyz->_projection( ['x', 'z'] )
        ->_rename( { 'y' => 'z' } )
        ->_union( [$xy] );

    if ($ttt->_is_identical( $xy )) {
        # All the longer paths resulting from conn were already in xy.
        return $xy;
    }

    # If we get here, then at least one longer path produced above was not
    # already in xy and was added; so now we need to check if any
    # yet-longer paths can be made from the just-produced.

    return $ttt->_tclose_of_xy();
}

###########################################################################

sub restriction {
    my ($topic, $func, $allow_dup_tuples) = @_;

    $topic->_assert_valid_func_arg( 'restriction', '$func', $func );

    if ($topic->is_empty()) {
        return $topic;
    }

    my $result = $topic->empty();

    my $topic_b = $topic->_body();
    my $result_b = $result->_body();

    for my $topic_t_ident_str (CORE::keys %{$topic_b}) {
        my $topic_t = $topic_b->{$topic_t_ident_str};
        my $is_matched;
        {
            local $_ = $topic->_export_nfmt_tuple( $topic_t );
            $is_matched = $func->();
        }
        if ($is_matched) {
            $result_b->{$topic_t_ident_str} = $topic_t;
        }
    }
    $result->_cardinality( scalar CORE::keys %{$result_b} );

    return $result;
}

sub restr_and_cmpl {
    my ($topic, $func, $allow_dup_tuples) = @_;
    $topic->_assert_valid_func_arg( 'restr_and_cmpl', '$func', $func );
    return $topic->_restr_and_cmpl( $func );
}

sub _restr_and_cmpl {
    my ($topic, $func) = @_;

    if ($topic->is_empty()) {
        return [$topic, $topic];
    }

    my $pass_result = $topic->empty();
    my $fail_result = $topic->empty();

    my $topic_b = $topic->_body();
    my $pass_result_b = $pass_result->_body();
    my $fail_result_b = $fail_result->_body();

    for my $topic_t_ident_str (CORE::keys %{$topic_b}) {
        my $topic_t = $topic_b->{$topic_t_ident_str};
        my $is_matched;
        {
            local $_ = $topic->_export_nfmt_tuple( $topic_t );
            $is_matched = $func->();
        }
        if ($is_matched) {
            $pass_result_b->{$topic_t_ident_str} = $topic_t;
        }
        else {
            $fail_result_b->{$topic_t_ident_str} = $topic_t;
        }
    }
    $pass_result->_cardinality( scalar CORE::keys %{$pass_result_b} );
    $fail_result->_cardinality( scalar CORE::keys %{$fail_result_b} );

    return [$pass_result, $fail_result];
}

sub cmpl_restr {
    my ($topic, $func, $allow_dup_tuples) = @_;

    $topic->_assert_valid_func_arg( 'cmpl_restr', '$func', $func );

    if ($topic->is_empty()) {
        return $topic;
    }

    my $result = $topic->empty();

    my $topic_b = $topic->_body();
    my $result_b = $result->_body();

    for my $topic_t_ident_str (CORE::keys %{$topic_b}) {
        my $topic_t = $topic_b->{$topic_t_ident_str};
        my $is_matched;
        {
            local $_ = $topic->_export_nfmt_tuple( $topic_t );
            $is_matched = $func->();
        }
        if (!$is_matched) {
            $result_b->{$topic_t_ident_str} = $topic_t;
        }
    }
    $result->_cardinality( scalar CORE::keys %{$result_b} );

    return $result;
}

###########################################################################

sub classification {
    my ($topic, $func, $class_attr_name, $group_attr_name,
        $allow_dup_tuples) = @_;

    $topic->_assert_valid_func_arg( 'classification', '$func', $func );
    $topic->_assert_valid_atnm_arg(
        'classification', '$class_attr_name', $class_attr_name );
    $topic->_assert_valid_atnm_arg(
        'classification', '$group_attr_name', $group_attr_name );

    my $result = $topic->_new();

    $result->_heading(
        {$class_attr_name => undef, $group_attr_name => undef} );
    $result->_degree( 2 );

    if ($topic->is_empty()) {
        # An empty $topic means an empty result.
        # So result body is already correct.
        return $result;
    }

    my $topic_h = $topic->_heading();
    my $topic_degree = $topic->degree();
    my $topic_b = $topic->_body();

    my $tuples_per_class = {};

    for my $topic_t_ident_str (CORE::keys %{$topic_b}) {
        my $topic_t = $topic_b->{$topic_t_ident_str};
        my $class;
        {
            local $_ = $topic->_export_nfmt_tuple( $topic_t );
            $class = $func->();
        }
        my $class_ident_str = $topic->_ident_str( $class );
        if (!exists $tuples_per_class->{$class_ident_str}) {
            $tuples_per_class->{$class_ident_str} = [$class, []];
        }
        push @{$tuples_per_class->{$class_ident_str}->[1]},
            [$topic_t, $topic_t_ident_str];
    }

    my $result_b = $result->_body();
    for my $class_ident_str (CORE::keys %{$tuples_per_class}) {
        my ($class, $tuples_in_class)
            = @{$tuples_per_class->{$class_ident_str}};

        my $inner_r = $topic->_new();
        $inner_r->_heading( $topic_h );
        $inner_r->_degree( $topic_degree );
        my $inner_b = $inner_r->_body();
        for my $topic_t_w_ident (@{$tuples_in_class}) {
            my ($topic_t, $topic_t_ident_str) = @{$topic_t_w_ident};
            $inner_b->{$topic_t_ident_str} = $topic_t;
        }
        $inner_r->_cardinality( scalar @{$tuples_in_class} );
        my $outer_atvl = [$inner_r, $inner_r->which()];

        my $result_t = {
            $class_attr_name => [$class, $class_ident_str],
            $group_attr_name => $outer_atvl,
        };
        my $result_t_ident_str = $topic->_ident_str( $result_t );
        $result_b->{$result_t_ident_str} = $result_t;
    }
    $result->_cardinality( scalar CORE::keys %{$result_b} );

    return $result;
}

###########################################################################

sub extension {
    my ($topic, $attr_names, $func, $allow_dup_tuples) = @_;

    (my $exten_h, $attr_names)
        = $topic->_atnms_hr_from_assert_valid_atnms_arg(
        'extension', '$attr_names', $attr_names );
    $topic->_assert_valid_func_arg( 'extension', '$func', $func );

    my ($both, undef, undef)
        = $topic->_ptn_conj_and_disj( $topic->_heading(), $exten_h );
    confess q{extension(): Bad $attr_names arg; that attr list}
            . q{ isn't disjoint with the invocant's heading.}
        if @{$both} > 0;

    return $topic->_extension( $attr_names, $func, $exten_h );
}

sub _extension {
    my ($topic, $attr_names, $func, $exten_h) = @_;

    if (@{$attr_names} == 0) {
        # Extension of input by zero attrs yields the input.
        return $topic;
    }

    my $result = $topic->_new();

    $result->_heading( {%{$topic->_heading()}, %{$exten_h}} );
    $result->_degree( $topic->degree() + @{$attr_names} );

    my $result_b = $result->_body();

    for my $topic_t (values %{$topic->_body()}) {
        my $exten_t;
        {
            local $_ = $topic->_export_nfmt_tuple( $topic_t );
            $exten_t = $func->();
        }
        $topic->_assert_valid_tuple_result_of_func_arg(
            'extension', '$func', '$attr_names', $exten_t, $exten_h );
        $exten_t = $topic->_import_nfmt_tuple( $exten_t );
        my $result_t = {%{$topic_t}, %{$exten_t}};
        my $result_t_ident_str = $topic->_ident_str( $result_t );
        $result_b->{$result_t_ident_str} = $result_t;
    }
    $result->_cardinality( $topic->cardinality() );

    return $result;
}

###########################################################################

sub static_exten {
    my ($topic, $attrs) = @_;

    confess q{static_exten(): Bad $attrs arg; it isn't a hash-ref.}
        if ref $attrs ne 'HASH';

    my ($both, undef, undef)
        = $topic->_ptn_conj_and_disj( $topic->_heading(), $attrs );
    confess q{static_exten(): Bad $attrs arg; that attr list}
            . q{ isn't disjoint with the invocant's heading.}
        if @{$both} > 0;

    confess q{static_exten(): Bad $attrs arg;}
            . q{ it is a hash-ref, and there exist circular refs}
            . q{ between itself or its tuple-valued components.}
        if $topic->_tuple_arg_has_circular_refs( $attrs );

    return $topic->_static_exten( $attrs );
}

sub _static_exten {
    my ($topic, $attrs) = @_;

    if ((scalar CORE::keys %{$attrs}) == 0) {
        # Extension of input by zero attrs yields the input.
        return $topic;
    }

    $attrs = $topic->_import_nfmt_tuple( $attrs );

    my $result = $topic->_new();

    $result->_heading( {%{$topic->_heading()},
        CORE::map { ($_ => undef) } CORE::keys %{$attrs}} );
    $result->_degree( $topic->degree() + (scalar CORE::keys %{$attrs}) );

    my $result_b = $result->_body();

    for my $topic_t (values %{$topic->_body()}) {
        my $result_t = {%{$topic_t}, %{$attrs}};
        my $result_t_ident_str = $topic->_ident_str( $result_t );
        $result_b->{$result_t_ident_str} = $result_t;
    }
    $result->_cardinality( $topic->cardinality() );

    return $result;
}

###########################################################################

sub map {
    my ($topic, $result_attr_names, $func, $allow_dup_tuples) = @_;

    (my $result_h, $result_attr_names)
        = $topic->_atnms_hr_from_assert_valid_atnms_arg(
            'map', '$result_attr_names', $result_attr_names );
    $topic->_assert_valid_func_arg( 'map', '$func', $func );

    if (@{$result_attr_names} == 0) {
        # Map to zero attrs yields identity relation zero or one.
        if ($topic->is_empty()) {
            return $topic->_new();
        }
        else {
            return $topic->_new( [ {} ] );
        }
    }

    my $result = $topic->_new();

    $result->_heading( $result_h );
    $result->_degree( scalar @{$result_attr_names} );

    my $result_b = $result->_body();

    for my $topic_t (values %{$topic->_body()}) {
        my $result_t;
        {
            local $_ = $topic->_export_nfmt_tuple( $topic_t );
            $result_t = $func->();
        }
        $topic->_assert_valid_tuple_result_of_func_arg(
            'map', '$func', '$result_attr_names', $result_t, $result_h );
        $result_t = $topic->_import_nfmt_tuple( $result_t );
        my $result_t_ident_str = $topic->_ident_str( $result_t );
        if (!exists $result_b->{$result_t_ident_str}) {
            $result_b->{$result_t_ident_str} = $result_t;
        }
    }
    $result->_cardinality( scalar CORE::keys %{$result_b} );

    return $result;
}

###########################################################################

sub summary {
    my ($topic, $group_per, $summ_attr_names, $summ_func,
        $allow_dup_tuples) = @_;

    (my $group_per_h, $group_per)
        = $topic->_atnms_hr_from_assert_valid_atnms_arg(
            'summary', '$group_per', $group_per );
    (my $exten_h, $summ_attr_names)
        = $topic->_atnms_hr_from_assert_valid_atnms_arg(
            'summary', '$summ_attr_names', $summ_attr_names );
    $topic->_assert_valid_func_arg( 'summary', '$summ_func', $summ_func );

    my $topic_h = $topic->_heading();

    confess q{summary(): Bad $group_per arg; that attr list}
            . q{ isn't a subset of the invocant's heading.}
        if notall { exists $topic_h->{$_} } @{$group_per};

    confess q{summary(): Bad $summ_attr_names arg; one or more of those}
            . q{ names for new summary attrs to add to the invocant }
            . q{ duplicates an attr of the invocant not being grouped.}
        if any { exists $group_per_h->{$_} } @{$summ_attr_names};

    my $inner = [grep { !$group_per_h->{$_} } CORE::keys %{$topic_h}];
    my $inner_h = {CORE::map { $_ => undef } @{$inner}};

    my (undef, $topic_attrs_no_gr, undef)
        = $topic->_ptn_conj_and_disj( $topic_h, $inner_h );

    my $result = $topic->_new();

    $result->_heading( {%{$group_per_h}, %{$exten_h}} );
    $result->_degree( @{$group_per} + @{$summ_attr_names} );

    if ($topic->is_empty()) {
        # An empty $topic means an empty result.
        return $result;
    }

    # Note: We skipped a number of shortcuts that _group() has for
    # brevity, leaving just the general case; they might come back later.

    my $result_b = $result->_body();
    my $topic_index = $topic->_want_index( $topic_attrs_no_gr );
    for my $matched_topic_b (values %{$topic_index}) {

        my $inner_r = $topic->_new();
        $inner_r->_heading( $inner_h );
        $inner_r->_degree( scalar @{$inner} );
        my $inner_b = $inner_r->_body();
        for my $topic_t (values %{$matched_topic_b}) {
            my $inner_t = {CORE::map { ($_ => $topic_t->{$_}) } @{$inner}};
            $inner_b->{$topic->_ident_str( $inner_t )} = $inner_t;
        }
        $inner_r->_cardinality( scalar CORE::keys %{$matched_topic_b} );

        my $any_mtpt = (values %{$matched_topic_b})[0];
        my $group_per_t = {CORE::map { ($_ => $any_mtpt->{$_}) }
            @{$topic_attrs_no_gr}};

        my $exten_t;
        {
            local $_ = {
                'summarize' => $inner_r,
                'per' => $topic->_export_nfmt_tuple( $group_per_t ),
            };
            $exten_t = $summ_func->();
        }
        $topic->_assert_valid_tuple_result_of_func_arg( 'summary',
            '$summ_func', '$summ_attr_names', $exten_t, $exten_h );
        $exten_t = $topic->_import_nfmt_tuple( $exten_t );

        my $result_t = {%{$group_per_t}, %{$exten_t}};
        my $result_t_ident_str = $topic->_ident_str( $result_t );
        if (!exists $result_b->{$result_t_ident_str}) {
            $result_b->{$result_t_ident_str} = $result_t;
        }
    }
    $result->_cardinality( scalar CORE::keys %{$result_b} );

    return $result;
}

###########################################################################

sub cardinality_per_group {
    my ($topic, $count_attr_name, $group_per, $allow_dup_tuples) = @_;

    $topic->_assert_valid_atnm_arg(
        'cardinality_per_group', '$count_attr_name', $count_attr_name );
    (my $group_per_h, $group_per)
        = $topic->_atnms_hr_from_assert_valid_atnms_arg(
            'cardinality_per_group', '$group_per', $group_per );

    my $topic_h = $topic->_heading();

    confess q{cardinality_per_group(): Bad $group_per arg;}
            . q{ that attr list isn't a subset of the invocant's heading.}
        if notall { exists $topic_h->{$_} } @{$group_per};

    confess q{cardinality_per_group(): Bad $count_attr_name arg;}
            . q{ that name for a new attr to add to the invocant}
            . q{ duplicates an attr of the invocant not being grouped.}
        if exists $group_per_h->{$count_attr_name};

    my $inner = [grep { !$group_per_h->{$_} } CORE::keys %{$topic_h}];
    my $inner_h = {CORE::map { $_ => undef } @{$inner}};

    my (undef, $topic_attrs_no_gr, undef)
        = $topic->_ptn_conj_and_disj( $topic_h, $inner_h );

    my $result = $topic->_new();

    $result->_heading( {%{$group_per_h}, $count_attr_name => undef} );
    $result->_degree( @{$group_per} + 1 );

    if ($topic->is_empty()) {
        # An empty $topic means an empty result.
        return $result;
    }

    my $result_b = $result->_body();
    my $topic_index = $topic->_want_index( $topic_attrs_no_gr );
    for my $matched_topic_b (values %{$topic_index}) {
        my $count = scalar CORE::keys %{$matched_topic_b};
        my $any_mtpt = (values %{$matched_topic_b})[0];
        my $group_per_t = {CORE::map { ($_ => $any_mtpt->{$_}) }
            @{$topic_attrs_no_gr}};
        my $result_t = {%{$group_per_t}, $count_attr_name => $count};
        my $result_t_ident_str = $topic->_ident_str( $result_t );
        if (!exists $result_b->{$result_t_ident_str}) {
            $result_b->{$result_t_ident_str} = $result_t;
        }
    }
    $result->_cardinality( scalar CORE::keys %{$result_b} );

    return $result;
}

sub count_per_group {
    my ($self, @args) = @_;
    return $self->cardinality_per_group( @args );
}

###########################################################################

sub _atnms_hr_from_assert_valid_atnms_arg {
    my ($self, $rtn_nm, $arg_nm, $atnms) = @_;

    if (defined $atnms and !ref $atnms) {
        $atnms = [$atnms];
    }
    confess qq{$rtn_nm(): Bad $arg_nm arg;}
            . q{ it must be an array-ref or a defined non-ref.}
        if ref $atnms ne 'ARRAY';
    confess qq{$rtn_nm(): Bad $arg_nm arg;}
            . q{ it should be just be a list of attr names,}
            . q{ but at least one name is undefined or is a ref.}
        if notall { defined $_ and !ref $_ } @{$atnms};
    confess qq{$rtn_nm(): Bad $arg_nm arg;}
            . q{ it specifies a list of}
            . q{ attr names with at least one duplicated name.}
        if (uniqstr @{$atnms}) != @{$atnms};

    my $heading = {CORE::map { ($_ => undef) } @{$atnms}};
    return ($heading, $atnms);
}

sub _assert_valid_atnm_arg {
    my ($self, $rtn_nm, $arg_nm, $atnm) = @_;
    confess qq{$rtn_nm(): Bad $arg_nm arg;}
            . q{ it should be just be an attr name,}
            . q{ but it is undefined or is a ref.}
        if !defined $atnm or ref $atnm;
}

sub _assert_valid_nnint_arg {
    my ($self, $rtn_nm, $arg_nm, $atnm) = @_;
    confess qq{$rtn_nm(): Bad $arg_nm arg;}
            . q{ it should be just be a non-negative integer,}
            . q{ but it is undefined or is a ref or is some other scalar.}
        if !defined $atnm or ref $atnm or not $atnm =~ /^[0-9]+$/;
}

sub _assert_valid_func_arg {
    my ($self, $rtn_nm, $arg_nm, $func) = @_;
    confess qq{$rtn_nm(): Bad $arg_nm arg;}
            . q{ it must be a Perl subroutine reference.}
        if ref $func ne 'CODE';
}

sub _assert_valid_tuple_result_of_func_arg {
    my ($self, $rtn_nm, $arg_nm_func, $arg_nm_attrs, $result_t, $heading)
        = @_;
    confess qq{$rtn_nm(): Bad $arg_nm_func arg;}
            . q{ at least one result of executing that Perl subroutine}
            . q{ reference was not a hash-ref or it didn't have the same}
            . qq{ set of hkeys as specified by the $arg_nm_attrs arg.}
        if ref $result_t ne 'HASH'
            or !$self->_is_identical_hkeys( $heading, $result_t );
    confess qq{$rtn_nm(): Bad $arg_nm_func arg;}
            . q{ at least one result of executing that Perl subroutine}
            . q{ reference was a hash-ref, and there exist circular refs}
            . q{ between itself or its tuple-valued components.}
        if $self->_tuple_arg_has_circular_refs( $result_t );
}

sub _normalize_same_heading_relation_arg {
    my ($self, $rtn_nm, $arg_nm, $other) = @_;
    if (blessed $other and $other->can( 'does' )
            and $other->does( 'Set::Relation' )
            and !$other->isa( __PACKAGE__ )) {
        $other = $self->_new( $other );
    }
    confess qq{$rtn_nm(): Bad $arg_nm arg; it isn't a Set::Relation}
            . q{ object, or it doesn't have exactly the}
            . q{ same set of attr names as the invocant.}
        if !blessed $other or !$other->isa( __PACKAGE__ )
            or !$self->_is_identical_hkeys(
                $self->_heading(), $other->_heading() );
    return $other;
}

sub _normalize_relation_arg {
    my ($self, $rtn_nm, $arg_nm, $other) = @_;
    if (blessed $other and $other->can( 'does' )
            and $other->does( 'Set::Relation' )
            and !$other->isa( __PACKAGE__ )) {
        $other = $self->_new( $other );
    }
    confess qq{$rtn_nm(): Bad $arg_nm arg;}
            . q{ it isn't a Set::Relation object.}
        if !blessed $other or !$other->isa( __PACKAGE__ );
    return $other;
}

###########################################################################

sub is_identical {
    my ($topic, $other) = @_;
    $other = $topic->_normalize_relation_arg(
        'is_identical', '$other', $other );
    return $topic->_is_identical( $other );
}

sub _is_identical {
    my ($topic, $other) = @_;
    return ($topic->degree() == $other->degree()
        and $topic->cardinality() == $other->cardinality()
        and $topic->_is_identical_hkeys(
            $topic->_heading(), $other->_heading() )
        and $topic->_is_identical_hkeys(
            $topic->_body(), $other->_body() ));
}

###########################################################################

sub is_subset {
    my ($topic, $other) = @_;
    $other = $topic->_normalize_same_heading_relation_arg(
        'is_subset', '$other', $other );
    my $other_b = $other->_body();
    return all { exists $other_b->{$_} }
        CORE::keys %{$topic->_body()};
}

sub is_superset {
    my ($topic, $other) = @_;
    $other = $topic->_normalize_same_heading_relation_arg(
        'is_superset', '$other', $other );
    my $topic_b = $topic->_body();
    return all { exists $topic_b->{$_} }
        CORE::keys %{$other->_body()};
}

sub is_proper_subset {
    my ($topic, $other) = @_;
    $other = $topic->_normalize_same_heading_relation_arg(
        'is_proper_subset', '$other', $other );
    my $other_b = $other->_body();
    return ($topic->cardinality() < $other->cardinality()
        and all { exists $other_b->{$_} }
            CORE::keys %{$topic->_body()});
}

sub is_proper_superset {
    my ($topic, $other) = @_;
    $other = $topic->_normalize_same_heading_relation_arg(
        'is_proper_superset', '$other', $other );
    my $topic_b = $topic->_body();
    return ($other->cardinality() < $topic->cardinality()
        and all { exists $topic_b->{$_} }
            CORE::keys %{$other->_body()});
}

sub is_disjoint {
    my ($topic, $other) = @_;
    $other = $topic->_normalize_same_heading_relation_arg(
        'is_disjoint', '$other', $other );
    return $topic->_intersection( [$other] )->is_empty();
}

###########################################################################

sub union {
    my ($topic, $others) = @_;
    $others = $topic->_normalize_same_heading_relations_arg(
        'union', '$others', $others );
    return $topic->_union( $others );
}

sub _union {
    my ($topic, $others) = @_;

    my $inputs = [
        sort { $b->cardinality() <=> $a->cardinality() }
        grep { !$_->is_empty() } # filter out identity value instances
        $topic, @{$others}];

    if (@{$inputs} == 0) {
        # All inputs were the identity value; so is result.
        return $topic->empty();
    }
    if (@{$inputs} == 1) {
        # Only one non-identity value input; so it is the result.
        return $inputs->[0];
    }

    # If we get here, there are at least 2 non-empty input relations.

    my $largest = shift @{$inputs};

    my $result = $largest->_new( $largest );

    my $smaller_bs = [CORE::map { $_->_body() } @{$inputs}];
    my $result_b = $result->_body();

    for my $smaller_b (@{$smaller_bs}) {
        for my $tuple_ident_str (CORE::keys %{$smaller_b}) {
            if (!exists $result_b->{$tuple_ident_str}) {
                $result_b->{$tuple_ident_str}
                    = $smaller_b->{$tuple_ident_str};
            }
        }
    }
    $result->_cardinality( scalar CORE::keys %{$result_b} );

    return $result;
}

###########################################################################

sub exclusion {
    # Also known as symmetric_diff().
    my ($topic, $others) = @_;

    $others = $topic->_normalize_same_heading_relations_arg(
        'exclusion', '$others', $others );

    my $inputs = [
        sort { $b->cardinality() <=> $a->cardinality() }
        grep { !$_->is_empty() } # filter out identity value instances
        $topic, @{$others}];

    if (@{$inputs} == 0) {
        # All inputs were the identity value; so is result.
        return $topic->empty();
    }
    if (@{$inputs} == 1) {
        # Only one non-identity value input; so it is the result.
        return $inputs->[0];
    }

    # If we get here, there are at least 2 non-empty input relations.

    my $largest = shift @{$inputs};

    my $result = $largest->_new( $largest );

    my $smaller_bs = [CORE::map { $_->_body() } @{$inputs}];
    my $result_b = $result->_body();

    for my $smaller_b (@{$smaller_bs}) {
        for my $tuple_ident_str (CORE::keys %{$smaller_b}) {
            if (exists $result_b->{$tuple_ident_str}) {
                CORE::delete $result_b->{$tuple_ident_str};
            }
            else {
                $result_b->{$tuple_ident_str}
                    = $smaller_b->{$tuple_ident_str};
            }
        }
    }
    $result->_cardinality( scalar CORE::keys %{$result_b} );

    return $result;
}

sub symmetric_diff {
    my ($self, @args) = @_;
    return $self->exclusion( @args );
}

###########################################################################

sub intersection {
    my ($topic, $others) = @_;
    $others = $topic->_normalize_same_heading_relations_arg(
        'intersection', '$others', $others );
    return $topic->_intersection( $others );
}

sub _intersection {
    my ($topic, $others) = @_;

    if (@{$others} == 0) {
        return $topic;
    }

    my $inputs = [
        sort { $a->cardinality() <=> $b->cardinality() }
        $topic, @{$others}];

    my $smallest = shift @{$inputs};

    if ($smallest->is_empty()) {
        return $smallest;
    }

    # If we get here, there are at least 2 non-empty input relations.

    my $result = $smallest->empty();

    my $smallest_b = $smallest->_body();
    my $larger_bs = [CORE::map { $_->_body() } @{$inputs}];
    my $result_b = $result->_body();

    TUPLE:
    for my $tuple_ident_str (CORE::keys %{$smallest_b}) {
        for my $larger_b (@{$larger_bs}) {
            next TUPLE
                if !exists $larger_b->{$tuple_ident_str};
        }
        $result_b->{$tuple_ident_str} = $smallest_b->{$tuple_ident_str};
    }
    $result->_cardinality( scalar CORE::keys %{$result_b} );

    return $result;
}

###########################################################################

sub _normalize_same_heading_relations_arg {
    my ($self, $rtn_nm, $arg_nm, $others) = @_;

    my $self_h = $self->_heading();

    if (blessed $others and $others->can( 'does' )
            and $others->does( 'Set::Relation' )) {
        $others = [$others];
    }
    confess qq{$rtn_nm(): Bad $arg_nm arg;}
            . q{ it must be an array-ref or a Set::Relation object.}
        if ref $others ne 'ARRAY';
    $others = [CORE::map {
        my $other = $_;
        if (blessed $other and $other->can( 'does' )
                and $other->does( 'Set::Relation' )
                and !$other->isa( __PACKAGE__ )) {
            $other = $self->_new( $other );
        }
        confess qq{$rtn_nm(): Bad $arg_nm arg elem;}
                . q{ it isn't a Set::Relation object, or it doesn't have}
                . q{ exactly the same set of attr names as the invocant.}
            if !blessed $other or !$other->isa( __PACKAGE__ )
                or !$self->_is_identical_hkeys(
                    $self_h, $other->_heading() );
        $other;
    } @{$others}];

    return $others;
}

sub _normalize_relations_arg {
    my ($self, $rtn_nm, $arg_nm, $others) = @_;

    if (blessed $others and $others->can( 'does' )
            and $others->does( 'Set::Relation' )) {
        $others = [$others];
    }
    confess qq{$rtn_nm(): Bad $arg_nm arg;}
            . q{ it must be an array-ref or a Set::Relation object.}
        if ref $others ne 'ARRAY';
    $others = [CORE::map {
        my $other = $_;
        if (blessed $other and $other->can( 'does' )
                and $other->does( 'Set::Relation' )
                and !$other->isa( __PACKAGE__ )) {
            $other = $self->_new( $other );
        }
        confess qq{$rtn_nm(): Bad $arg_nm arg elem;}
                . q{ it isn't a Set::Relation object.}
            if !blessed $other or !$other->isa( __PACKAGE__ );
        $other;
    } @{$others}];

    return $others;
}

###########################################################################

sub diff {
    my ($source, $filter) = @_;
    $filter = $source->_normalize_same_heading_relation_arg(
        'diff', '$other', $filter );
    return $source->_diff( $filter );
}

sub _diff {
    my ($source, $filter) = @_;
    if ($source->is_empty() or $filter->is_empty()) {
        return $source;
    }
    return $source->_regular_diff( $filter );
}

sub _regular_diff {
    my ($source, $filter) = @_;

    my $result = $source->empty();

    my $source_b = $source->_body();
    my $filter_b = $filter->_body();
    my $result_b = $result->_body();

    for my $tuple_ident_str (CORE::keys %{$source_b}) {
        if (!exists $filter_b->{$tuple_ident_str}) {
            $result_b->{$tuple_ident_str} = $source_b->{$tuple_ident_str};
        }
    }
    $result->_cardinality( scalar CORE::keys %{$result_b} );

    return $result;
}

###########################################################################

sub semidiff {
    my ($source, $filter) = @_;
    $filter = $source->_normalize_relation_arg(
        'semidiff', '$filter', $filter );
    if ($source->is_empty() or $filter->is_empty()) {
        return $source;
    }
    return $source->_regular_diff( $source->_semijoin( $filter ) );
}

sub antijoin {
    my ($self, @args) = @_;
    return $self->semidiff( @args );
}

sub semijoin_and_diff {
    my ($source, $filter) = @_;
    $filter = $source->_normalize_relation_arg(
        'semijoin_and_diff', '$filter', $filter );
    return $source->_semijoin_and_diff( $filter );
}

sub _semijoin_and_diff {
    my ($source, $filter) = @_;
    if ($source->is_empty()) {
        return [$source, $source];
    }
    if ($filter->is_empty()) {
        return [$source->empty(), $source];
    }
    my $semijoin = $source->_semijoin( $filter );
    return [$semijoin, $source->_regular_diff( $semijoin )];
}

sub semijoin {
    my ($source, $filter) = @_;
    $filter = $source->_normalize_relation_arg(
        'semijoin', '$filter', $filter );
    return $source->_semijoin( $filter );
}

sub _semijoin {
    my ($source, $filter) = @_;

    if ($source->is_empty()) {
        return $source;
    }
    if ($filter->is_empty()) {
        return $source->empty();
    }

    # If we get here, both inputs have at least one tuple.

    if ($source->is_nullary() or $filter->is_nullary()) {
        return $source;
    }

    # If we get here, both inputs also have at least one attribute.

    my ($both, $source_only, $filter_only) = $source->_ptn_conj_and_disj(
        $source->_heading(), $filter->_heading() );

    if (@{$both} == 0) {
        # The inputs have disjoint headings; result is source.
        return $source;
    }
    if (@{$source_only} == 0 and @{$filter_only} == 0) {
        # The inputs have identical headings; result is intersection.
        return $source->_intersection( [$filter] );
    }

    # If we get here, the inputs also have overlapping non-ident headings.

    return $source->_regular_semijoin( $filter, $both );
}

sub _regular_semijoin {
    my ($source, $filter, $both) = @_;

    my $result = $source->empty();

    my ($sm, $lg) = ($source->cardinality() < $filter->cardinality())
        ? ($source, $filter) : ($filter, $source);

    my $sm_index = $sm->_want_index( $both );
    my $lg_index = $lg->_want_index( $both );
    my $source_index = $source->_want_index( $both );
    my $result_b = $result->_body();

    for my $subtuple_ident_str (CORE::keys %{$sm_index}) {
        if (exists $lg_index->{$subtuple_ident_str}) {
            my $matched_source_b = $source_index->{$subtuple_ident_str};
            for my $tuple_ident_str (CORE::keys %{$matched_source_b}) {
                $result_b->{$tuple_ident_str}
                    = $matched_source_b->{$tuple_ident_str};
            }
        }
    }
    $result->_cardinality( scalar CORE::keys %{$result_b} );

    return $result;
}

###########################################################################

sub join {
    my ($topic, $others) = @_;
    $others = $topic->_normalize_relations_arg(
        'join', '$others', $others );
    return $topic->_join( $others );
}

sub _join {
    my ($topic, $others) = @_;

    if (@{$others} == 0) {
        return $topic;
    }

    my $inputs = [$topic, @{$others}];

    if (any { $_->is_empty() } @{$inputs}) {
        # At least one input has zero tuples; so does result.
        my $result = $topic->_new();
        my $result_h = {CORE::map { %{$_->_heading()} } @{$inputs}};
        $result->_heading( $result_h );
        $result->_degree( scalar CORE::keys %{$result_h} );
        return $result;
    }

    # If we get here, all inputs have at least one tuple.

    $inputs = [
        sort { $a->cardinality() <=> $b->cardinality() }
        grep { !$_->is_nullary() } # filter out identity value instances
        @{$inputs}];

    if (@{$inputs} == 0) {
        # All inputs were the identity value; so is result.
        return $topic;
    }
    if (@{$inputs} == 1) {
        # Only one non-identity value input; so it is the result.
        return $inputs->[0];
    }

    # If we get here, there are at least 2 non-empty non-nullary inp rels.

    my $result = shift @{$inputs};
    INPUT:
    for my $input (@{$inputs}) {
        # TODO: Optimize this better by determining more strategic order
        # to join the various inputs, such as by doing intersections first,
        # then semijoins, then regular joins, then cross-products.
        # But at least we're going min to max cardinality meanwhile.

        my ($both, $result_only, $input_only)
            = $result->_ptn_conj_and_disj(
                $result->_heading(), $input->_heading() );

        if (@{$both} == 0) {
            # The inputs have disjoint headings; result is cross-product.
            $result = $result->_regular_product( $input );
            next INPUT;
        }
        if (@{$result_only} == 0 and @{$input_only} == 0) {
            # The inputs have identical headings; result is intersection.
            $result = $result->_intersection( [$input] );
            next INPUT;
        }

        # If we get here, the inputs also have overlapping non-ident heads.

        if (@{$result_only} == 0) {
            # The first input's attrs are a proper subset of the second's;
            # result has same heading as second, a subset of sec's tuples.
            $result = $input->_regular_semijoin( $result, $both );
            next INPUT;
        }
        if (@{$input_only} == 0) {
            # The second input's attrs are a proper subset of the first's;
            # result has same heading as first, a subset of first's tuples.
            $result = $result->_regular_semijoin( $input, $both );
            next INPUT;
        }

        # If we get here, both inputs also have mini one attr of their own.

        $result = $result->_regular_join(
            $input, $both, $result_only, $input_only );
    }
    return $result;
}

sub _regular_join {
    my ($topic, $other, $both, $topic_only, $other_only) = @_;

    my $result = $topic->_new();

    $result->_heading( {CORE::map { ($_ => undef) }
        @{$both}, @{$topic_only}, @{$other_only}} );
    $result->_degree( @{$both} + @{$topic_only} + @{$other_only} );

    my ($sm, $lg) = ($topic->cardinality() < $other->cardinality())
        ? ($topic, $other) : ($other, $topic);

    my $sm_index = $sm->_want_index( $both );
    my $lg_index = $lg->_want_index( $both );
    my $result_b = {};

    for my $subtuple_ident_str (CORE::keys %{$sm_index}) {
        if (exists $lg_index->{$subtuple_ident_str}) {
            my $matched_sm_b = $sm_index->{$subtuple_ident_str};
            my $matched_lg_b = $lg_index->{$subtuple_ident_str};
            for my $sm_t (values %{$matched_sm_b}) {
                for my $lg_t (values %{$matched_lg_b}) {
                    my $result_t = {%{$sm_t}, %{$lg_t}};
                    $result_b->{$topic->_ident_str( $result_t )}
                        = $result_t;
                }
            }
        }
    }
    $result->_body( $result_b );
    $result->_cardinality( scalar CORE::keys %{$result_b} );

    return $result;
}

###########################################################################

sub product {
    my ($topic, $others) = @_;

    $others = $topic->_normalize_relations_arg(
        'product', '$others', $others );

    if (@{$others} == 0) {
        return $topic;
    }

    my $inputs = [$topic, @{$others}];

    my $attr_names
        = [CORE::map { CORE::keys %{$_->_heading()} } @{$inputs}];

    confess q{product(): Bad $others arg;}
            . q{ one of its elems has an attr name duplicated by}
            . q{ either the invocant or another $others elem.}
        if (uniqstr @{$attr_names}) != @{$attr_names};

    if (any { $_->is_empty() } @{$inputs}) {
        # At least one input has zero tuples; so does result.
        my $result = $topic->_new();
        $result->_heading( {CORE::map { ($_ => undef) } @{$attr_names}} );
        $result->_degree( scalar @{$attr_names} );
        return $result;
    }

    # If we get here, all inputs have at least one tuple.

    $inputs = [
        sort { $a->cardinality() <=> $b->cardinality() }
        grep { !$_->is_nullary() } # filter out identity value instances
        @{$inputs}];

    if (@{$inputs} == 0) {
        # All inputs were the identity value; so is result.
        return $topic;
    }
    if (@{$inputs} == 1) {
        # Only one non-identity value input; so it is the result.
        return $inputs->[0];
    }

    # If we get here, there are at least 2 non-empty non-nullary inp rels.

    my $result = shift @{$inputs};
    for my $input (@{$inputs}) {
        $result = $result->_regular_product( $input );
    }
    return $result;
}

sub _regular_product {
    my ($topic, $other) = @_;

    my $result = $topic->_new();

    $result->_heading( {%{$topic->_heading()}, %{$other->_heading()}} );
    $result->_degree( $topic->degree() + $other->degree() );

    my ($sm, $lg) = ($topic->cardinality() < $other->cardinality())
        ? ($topic, $other) : ($other, $topic);

    my $sm_b = $sm->_body();
    my $lg_b = $lg->_body();
    my $result_b = {};

    for my $sm_t (values %{$sm_b}) {
        for my $lg_t (values %{$lg_b}) {
            my $result_t = {%{$sm_t}, %{$lg_t}};
            $result_b->{$topic->_ident_str( $result_t )} = $result_t;
        }
    }
    $result->_body( $result_b );
    $result->_cardinality( $topic->cardinality() * $other->cardinality() );

    return $result;
}

###########################################################################

sub quotient {
    my ($dividend, $divisor) = @_;

    $divisor = $dividend->_normalize_relation_arg(
        'quotient', '$divisor', $divisor );

    my (undef, $dividend_only, $divisor_only)
        = $dividend->_ptn_conj_and_disj(
            $dividend->_heading(), $divisor->_heading() );

    confess q{quotient(): Bad $divisor arg;}
            . q{ its heading isn't a subset of the invocant's heading.}
        if @{$divisor_only} > 0;

    my $proj_of_dividend_only = $dividend->_projection( $dividend_only );

    if ($dividend->is_empty() or $divisor->is_empty()) {
        # At least one input has zero tup; res has all tup o dividend proj.
        return $proj_of_dividend_only;
    }

    # If we get here, both inputs have at least one tuple.

    if ($dividend->is_nullary() or $divisor->is_nullary()) {
        # Both inputs or just divisor is ident-one rel; result is dividend.
        return $dividend;
    }

    # If we get here, divisor has at least one attribute,
    # and divisor heading is proper subset of dividend heading.

    return $proj_of_dividend_only
        ->_diff( $proj_of_dividend_only
            ->_regular_product( $divisor )
            ->_diff( $dividend )
            ->_projection( $dividend_only )
        );
}

###########################################################################

sub composition {
    my ($topic, $other) = @_;

    $other = $topic->_normalize_relation_arg(
        'composition', '$other', $other );

    my ($both, $topic_only, $other_only) = $topic->_ptn_conj_and_disj(
        $topic->_heading(), $other->_heading() );

    if ($topic->is_empty() or $other->is_empty()) {
        # At least one input has zero tuples; so does result.
        return $topic->_new( [@{$topic_only}, @{$other_only}] );
    }

    # If we get here, both inputs have at least one tuple.

    if ($topic->is_nullary()) {
        # First input is identity-one relation; result is second input.
        return $other;
    }
    if ($other->is_nullary()) {
        # Second input is identity-one relation; result is first input.
        return $topic;
    }

    # If we get here, both inputs also have at least one attribute.

    if (@{$both} == 0) {
        # The inputs have disjoint headings; result is cross-product.
        return $topic->_regular_product( $other );
    }
    if (@{$topic_only} == 0 and @{$other_only} == 0) {
        # The inputs have identical headings; result is ident-one relation.
        return $topic->_new( [ {} ] );
    }

    # If we get here, the inputs also have overlapping non-ident headings.

    if (@{$topic_only} == 0) {
        # The first input's attributes are a proper subset of the second's;
        # result has same heading as second, a subset of second's tuples.
        return $other->_regular_semijoin( $topic, $both )
            ->_projection( $other_only );
    }
    if (@{$other_only} == 0) {
        # The second input's attributes are a proper subset of the first's;
        # result has same heading as first, a subset of first's tuples.
        return $topic->_regular_semijoin( $other, $both )
            ->_projection( $topic_only );
    }

    # If we get here, both inputs also have at least one attr of their own.

    return $topic->_regular_join(
        $other, $both, $topic_only, $other_only )
            ->_projection( [@{$topic_only}, @{$other_only}] );
}

###########################################################################

sub _ptn_conj_and_disj {
    # inputs are hashes, results are arrays
    my ($self, $src1, $src2) = @_;
    my $both = [grep { exists $src1->{$_} } CORE::keys %{$src2}];
    my $both_h = {CORE::map { ($_ => undef) } @{$both}};
    my $only1 = [grep { !exists $both_h->{$_} } CORE::keys %{$src1}];
    my $only2 = [grep { !exists $both_h->{$_} } CORE::keys %{$src2}];
    return ($both, $only1, $only2);
}

###########################################################################

sub _want_index {
    my ($self, $atnms) = @_;
    my $subheading = {CORE::map { ($_ => undef) } @{$atnms}};
    my $subheading_ident_str = $self->_heading_ident_str( $subheading );
    my $indexes = $self->_indexes();
    if (!exists $indexes->{$subheading_ident_str}) {
        my $index_and_meta = $indexes->{$subheading_ident_str}
            = [ $subheading, {} ];
        my $index = $index_and_meta->[1];
        my $body = $self->_body();
        for my $tuple_ident_str (CORE::keys %{$body}) {
            my $tuple = $body->{$tuple_ident_str};
            my $subtuple_ident_str = $self->_ident_str(
                {CORE::map { ($_ => $tuple->{$_}) } @{$atnms}} );
            my $matched_b = $index->{$subtuple_ident_str} ||= {};
            $matched_b->{$tuple_ident_str} = $tuple;
        }
    }
    return $indexes->{$subheading_ident_str}->[1];
}

###########################################################################

sub join_with_group {
    my ($primary, $secondary, $group_attr) = @_;

    $secondary = $primary->_normalize_relation_arg(
        'join_with_group', '$secondary', $secondary );
    $primary->_assert_valid_atnm_arg(
        'join_with_group', '$group_attr', $group_attr );

    my $primary_h = $primary->_heading();

    confess q{join_with_group(): Bad $group_attr arg;}
            . q{ that name for a new attr to add}
            . q{ to $primary, consisting of grouped $secondary-only attrs,}
            . q{ duplicates an attr of $primary (not being grouped).}
        if exists $primary_h->{$group_attr};

    # TODO: inline+merge what join/group do for better performance.

    my ($both, $primary_only, $inner) = $primary->_ptn_conj_and_disj(
            $primary_h, $secondary->_heading() );
    my $inner_h = {CORE::map { $_ => undef } @{$inner}};

    return $primary
        ->_join( [$secondary] )
        ->_group( $group_attr, $inner, [CORE::keys %{$primary_h}],
            $inner_h );
}

###########################################################################

sub rank {
    my ($topic, $name, $ord_func) = @_;

    my $topic_h = $topic->_heading();

    $topic->_assert_valid_atnm_arg( 'rank', '$name', $name );
    confess q{rank(): Bad $name arg; that name for a new attr to add}
            . q{ to the invocant, consisting of each tuple's numeric rank,}
            . q{ duplicates an existing attr of the invocant.}
        if exists $topic_h->{$name};

    $topic->_assert_valid_func_arg( 'rank', '$ord_func', $ord_func );

    my $result = $topic->_new();

    $result->_heading( {%{$topic_h}, $name => undef} );
    $result->_degree( $topic->degree() + 1 );

    if ($topic->is_empty()) {
        return $result;
    }

    my $ext_topic_tuples = [];
    my $topic_tuples_by_ext_tt_ref = {};

    for my $topic_t (values %{$topic->_body()}) {
        my $ext_topic_t = $topic->_export_nfmt_tuple( $topic_t );
        push @{$ext_topic_tuples}, $ext_topic_t;
        $topic_tuples_by_ext_tt_ref->{refaddr $ext_topic_t} = $topic_t;
    }

    my $sorted_ext_topic_tuples = [sort {
        local $_ = { 'a' => $a, 'b' => $b };
        $ord_func->();
    } @{$ext_topic_tuples}];

    my $result_b = $result->_body();

    my $rank = -1;
    for my $ext_topic_t (@{$sorted_ext_topic_tuples}) {
        my $topic_t = $topic_tuples_by_ext_tt_ref->{refaddr $ext_topic_t};
        $rank ++;
        my $rank_atvl = [$rank, $topic->_ident_str( $rank )];
        my $result_t = {$name => $rank_atvl, %{$topic_t}};
        my $result_t_ident_str = $topic->_ident_str( $result_t );
        $result_b->{$result_t_ident_str} = $result_t;
    }
    $result->_cardinality( $topic->cardinality() );

    return $result;
}

###########################################################################

sub rank_by_attr_names {
    my ($topic, $name, $order_by) = @_;

    my $topic_h = $topic->_heading();

    $topic->_assert_valid_atnm_arg( 'rank_by_attr_names', '$name', $name );
    confess q{rank_by_attr_names(): Bad $name arg; that name for a new}
            . q{ attr to add to the invocant, consisting of each tuple's}
            . q{ numeric rank, duplicates an existing attr of th invocant.}
        if exists $topic_h->{$name};

    $order_by = $topic->_normalize_order_by_arg(
        'rank_by_attr_names', '$order_by', $order_by );

    my $result = $topic->_new();

    $result->_heading( {%{$topic_h}, $name => undef} );
    $result->_degree( $topic->degree() + 1 );

    if ($topic->is_empty()) {
        return $result;
    }

    my $sort_func = $topic->_sort_func_from_order_by( $order_by );

    my $result_b = $result->_body();

    my $rank = -1;
    for my $topic_t (@{$sort_func->( $topic )}) {
        $rank ++;
        my $rank_atvl = [$rank, $topic->_ident_str( $rank )];
        my $result_t = {$name => $rank_atvl, %{$topic_t}};
        my $result_t_ident_str = $topic->_ident_str( $result_t );
        $result_b->{$result_t_ident_str} = $result_t;
    }
    $result->_cardinality( $topic->cardinality() );

    return $result;
}

###########################################################################

sub _normalize_order_by_arg {
    my ($topic, $rtn_nm, $arg_nm, $order_by) = @_;

    if (defined $order_by and !ref $order_by) {
        $order_by = [$order_by];
    }
    confess qq{$rtn_nm(): Bad $arg_nm arg;}
            . q{ it must be an array-ref or a defined non-ref.}
        if ref $order_by ne 'ARRAY';

    $order_by = [CORE::map {
              (ref $_ ne 'ARRAY') ? [$_, 0, 'cmp']
            : (@{$_} == 1)        ? [@{$_}, 0, 'cmp']
            : (@{$_} == 2)        ? [@{$_}, 'cmp']
            :                       $_
        } @{$order_by}];
    confess qq{$rtn_nm(): Bad $arg_nm arg elem;}
            . q{ it must be a 1-3 elem array-ref or a defined non-ref,}
            . q{ its first elem must be a valid attr name (defin non-ref),}
            . q{ and its third elem must be undef or one of 'cmp'|'<=>'.}
        if notall {
                ref $_ eq 'ARRAY' and @{$_} == 3
                and defined $_->[0] and !ref $_->[0]
                and (!defined $_->[2]
                    or $_->[2] eq 'cmp' or $_->[2] eq '<=>')
            } @{$order_by};

    my $atnms = [CORE::map { $_->[0] } @{$order_by}];
    confess qq{$rtn_nm(): Bad $arg_nm arg;}
            . q{ it specifies a list of}
            . q{ attr names with at least one duplicated name.}
        if (uniqstr @{$atnms}) != @{$atnms};

    my $topic_h = $topic->_heading();
    confess qq{$rtn_nm(): Bad $arg_nm arg;}
            . q{ the list of attr names it specifies isn't a subset of the}
            . q{ heading of the relation defined by the $members arg.}
        if notall { exists $topic_h->{$_} } @{$atnms};

    return $order_by;
}

###########################################################################

sub _sort_func_from_order_by {
    my ($topic, $order_by) = @_;
    my $sort_func_perl
    = "sub {\n"
        . "my (\$topic) = \@_;\n"
        . "return [sort {\n"
            . (CORE::join ' || ', '0', CORE::map {
                    my ($name, $is_reverse_order, $compare_op) = @{$_};
                    $compare_op ||= 'cmp';
                    ($is_reverse_order
                        ? "\$b->{'$name'} $compare_op \$a->{'$name'}"
                        : "\$a->{'$name'} $compare_op \$b->{'$name'}");
                } @{$order_by}) . "\n"
        . "} values \%{\$topic->_body()}];\n"
    . "}\n"
    ;
    my $sort_func = eval $sort_func_perl;
    if (my $err = $@) {
        confess qq{Oops, failed to compile Perl sort func from order by;\n}
            . qq{  error message is [[$err]];\n}
            . qq{  source code is [[$sort_func_perl]].}
    }
    return $sort_func;
}

###########################################################################

sub limit {
    my ($topic, $ord_func, $min_rank, $max_rank) = @_;

    $topic->_assert_valid_func_arg( 'limit', '$ord_func', $ord_func );

    $topic->_assert_valid_nnint_arg( 'limit', '$min_rank', $min_rank );
    $topic->_assert_valid_nnint_arg( 'limit', '$max_rank', $max_rank );
    confess q{limit(): The $max_rank arg can't be less than the $min_rank.}
        if $max_rank < $min_rank;

    if ($topic->is_empty()) {
        return $topic;
    }

    my $topic_b = $topic->_body();

    my $ext_topic_tuples = [];
    my $topic_tuples_by_ext_tt_ref = {};

    for my $topic_t_ident_str (CORE::keys %{$topic_b}) {
        my $topic_t = $topic_b->{$topic_t_ident_str};
        my $ext_topic_t = $topic->_export_nfmt_tuple( $topic_t );
        push @{$ext_topic_tuples}, $ext_topic_t;
        $topic_tuples_by_ext_tt_ref->{refaddr $ext_topic_t}
            = $topic_t_ident_str;
    }

    my $sorted_ext_topic_tuples = [sort {
        local $_ = { 'a' => $a, 'b' => $b };
        $ord_func->();
    } @{$ext_topic_tuples}];

    my $result = $topic->empty();

    my $result_b = $result->_body();

    for my $ext_topic_t
            (@{$sorted_ext_topic_tuples}[$min_rank..$max_rank]) {
        my $topic_t_ident_str
            = $topic_tuples_by_ext_tt_ref->{refaddr $ext_topic_t};
        $result_b->{$topic_t_ident_str} = $topic_b->{$topic_t_ident_str};
    }
    $result->_cardinality( scalar CORE::keys %{$result_b} );

    return $result;
}

###########################################################################

sub limit_by_attr_names {
    my ($topic, $order_by, $min_rank, $max_rank) = @_;

    $order_by = $topic->_normalize_order_by_arg(
        'limit_by_attr_names', '$order_by', $order_by );

    $topic->_assert_valid_nnint_arg(
        'limit_by_attr_names', '$min_rank', $min_rank );
    $topic->_assert_valid_nnint_arg(
        'limit_by_attr_names', '$max_rank', $max_rank );
    confess q{limit_by_attr_names():}
            . q{ The $max_rank arg can't be less than the $min_rank.}
        if $max_rank < $min_rank;

    if ($topic->is_empty()) {
        return $topic;
    }

    my $sort_func = $topic->_sort_func_from_order_by( $order_by );

    my $topic_b = $topic->_body();

    my $topic_tists_by_tt_ref = {};

    for my $topic_t_ident_str (CORE::keys %{$topic_b}) {
        my $topic_t = $topic_b->{$topic_t_ident_str};
        $topic_tists_by_tt_ref->{refaddr $topic_t} = $topic_t_ident_str;
    }

    my $result = $topic->empty();

    my $result_b = $result->_body();

    for my $topic_t (@{$sort_func->( $topic )}[$min_rank..$max_rank]) {
        my $topic_t_ident_str = $topic_tists_by_tt_ref->{refaddr $topic_t};
        $result_b->{$topic_t_ident_str} = $topic_t;
    }
    $result->_cardinality( scalar CORE::keys %{$result_b} );

    return $result;
}

###########################################################################

sub substitution {
    my ($topic, $attr_names, $func, $allow_dup_tuples) = @_;
    (my $subst_h, $attr_names)
        = $topic->_atnms_hr_from_assert_valid_subst_args(
        'substitution', '$attr_names', '$func', $attr_names, $func );
    return $topic->_substitution(
        'substitution', '$attr_names', '$func',
        $attr_names, $func, $subst_h );
}

sub _atnms_hr_from_assert_valid_subst_args {
    my ($topic, $rtn_nm, $arg_nm_atnms, $arg_nm_func, $atnms, $func) = @_;

    (my $subst_h, $atnms) = $topic->_atnms_hr_from_assert_valid_atnms_arg(
        $rtn_nm, $arg_nm_atnms, $atnms );
    my (undef, undef, $subst_only)
        = $topic->_ptn_conj_and_disj( $topic->_heading(), $subst_h );
    confess qq{$rtn_nm(): Bad $arg_nm_atnms arg; that attr list}
            . q{ isn't a subset of the invocant's heading.}
        if @{$subst_only} > 0;

    $topic->_assert_valid_func_arg( $rtn_nm, $arg_nm_func, $func );

    return ($subst_h, $atnms);
}

sub _substitution {
    my ($topic, $rtn_nm, $arg_nm_attrs, $arg_nm_func, $attrs, $func,
        $subst_h) = @_;

    if ($topic->is_empty()) {
        return $topic;
    }
    if (@{$attrs} == 0) {
        # Substitution in zero attrs of input yields the input.
        return $topic;
    }

    my $result = $topic->empty();

    my $result_b = $result->_body();

    for my $topic_t (values %{$topic->_body()}) {
        my $subst_t;
        {
            local $_ = $topic->_export_nfmt_tuple( $topic_t );
            $subst_t = $func->();
        }
        $topic->_assert_valid_tuple_result_of_func_arg(
            $rtn_nm, $arg_nm_func, $arg_nm_attrs, $subst_t, $subst_h );
        $subst_t = $topic->_import_nfmt_tuple( $subst_t );
        my $result_t = {%{$topic_t}, %{$subst_t}};
        my $result_t_ident_str = $topic->_ident_str( $result_t );
        if (!exists $result_b->{$result_t_ident_str}) {
            $result_b->{$result_t_ident_str} = $result_t;
        }
    }
    $result->_cardinality( scalar CORE::keys %{$result_b} );

    return $result;
}

###########################################################################

sub static_subst {
    my ($topic, $attrs) = @_;
    $topic->_assert_valid_static_subst_args(
        'static_subst', '$attrs', $attrs );
    return $topic->_static_subst( $attrs );
}

sub _assert_valid_static_subst_args {
    my ($topic, $rtn_nm, $arg_nm_attrs, $attrs) = @_;

    confess qq{$rtn_nm(): Bad $arg_nm_attrs arg; it isn't a hash-ref.}
        if ref $attrs ne 'HASH';

    my (undef, undef, $subst_only)
        = $topic->_ptn_conj_and_disj( $topic->_heading(), $attrs );
    confess qq{$rtn_nm(): Bad $arg_nm_attrs arg; that attr list}
            . q{ isn't a subset of the invocant's heading.}
        if @{$subst_only} > 0;

    confess qq{$rtn_nm(): Bad $arg_nm_attrs arg;}
            . q{ it is a hash-ref, and there exist circular refs}
            . q{ between itself or its tuple-valued components.}
        if $topic->_tuple_arg_has_circular_refs( $attrs );

    return;
}

sub _static_subst {
    my ($topic, $attrs) = @_;

    if ($topic->is_empty()) {
        return $topic;
    }
    if ((scalar CORE::keys %{$attrs}) == 0) {
        # Substitution in zero attrs of input yields the input.
        return $topic;
    }

    $attrs = $topic->_import_nfmt_tuple( $attrs );

    my $result = $topic->empty();

    my $result_b = $result->_body();

    for my $topic_t (values %{$topic->_body()}) {
        my $result_t = {%{$topic_t}, %{$attrs}};
        my $result_t_ident_str = $topic->_ident_str( $result_t );
        if (!exists $result_b->{$result_t_ident_str}) {
            $result_b->{$result_t_ident_str} = $result_t;
        }
    }
    $result->_cardinality( scalar CORE::keys %{$result_b} );

    return $result;
}

###########################################################################

sub subst_in_restr {
    my ($topic, $restr_func, $subst_attr_names, $subst_func,
        $allow_dup_tuples) = @_;

    $topic->_assert_valid_func_arg(
        'subst_in_restr', '$restr_func', $restr_func );

    (my $subst_h, $subst_attr_names) = $topic
        ->_atnms_hr_from_assert_valid_subst_args( 'subst_in_restr',
            '$subst_attr_names', '$subst_func',
            $subst_attr_names, $subst_func );

    my ($topic_to_subst, $topic_no_subst)
        = @{$topic->_restr_and_cmpl( $restr_func )};

    return $topic_to_subst
        ->_substitution( 'subst_in_restr', '$subst_attr_names',
            '$subst_func', $subst_attr_names, $subst_func, $subst_h )
        ->_union( [$topic_no_subst] );
}

###########################################################################

sub static_subst_in_restr {
    my ($topic, $restr_func, $subst, $allow_dup_tuples) = @_;

    $topic->_assert_valid_func_arg(
        'static_subst_in_restr', '$restr_func', $restr_func );

    $topic->_assert_valid_static_subst_args(
        'static_subst_in_restr', '$subst', $subst );

    my ($topic_to_subst, $topic_no_subst)
        = @{$topic->_restr_and_cmpl( $restr_func )};

    return $topic_to_subst
        ->_static_subst( $subst )
        ->_union( [$topic_no_subst] );
}

###########################################################################

sub subst_in_semijoin {
    my ($topic, $restr, $subst_attr_names, $subst_func, $allow_dup_tuples)
        = @_;

    $restr = $topic->_normalize_relation_arg(
        'subst_in_semijoin', '$restr', $restr );

    (my $subst_h, $subst_attr_names) = $topic
        ->_atnms_hr_from_assert_valid_subst_args( 'subst_in_semijoin',
            '$subst_attr_names', '$subst_func',
            $subst_attr_names, $subst_func );

    my ($topic_to_subst, $topic_no_subst)
        = @{$topic->_semijoin_and_diff( $restr )};

    return $topic_to_subst
        ->_substitution( 'subst_in_semijoin', '$subst_attr_names',
            '$subst_func', $subst_attr_names, $subst_func, $subst_h )
        ->_union( [$topic_no_subst] );
}

###########################################################################

sub static_subst_in_semijoin {
    my ($topic, $restr, $subst) = @_;

    $restr = $topic->_normalize_relation_arg(
        'static_subst_in_semijoin', '$restr', $restr );

    $topic->_assert_valid_static_subst_args(
        'static_subst_in_semijoin', '$subst', $subst );

    my ($topic_to_subst, $topic_no_subst)
        = @{$topic->_semijoin_and_diff( $restr )};

    return $topic_to_subst
        ->_static_subst( $subst )
        ->_union( [$topic_no_subst] );
}

###########################################################################

sub outer_join_with_group {
    my ($primary, $secondary, $group_attr) = @_;

    $secondary = $primary->_normalize_relation_arg(
        'outer_join_with_group', '$secondary', $secondary );
    $primary->_assert_valid_atnm_arg(
        'outer_join_with_group', '$group_attr', $group_attr );

    my $primary_h = $primary->_heading();

    confess q{outer_join_with_group(): Bad $group_attr arg;}
            . q{ that name for a new attr to add}
            . q{ to $primary, consisting of grouped $secondary-only attrs,}
            . q{ duplicates an attr of $primary (not being grouped).}
        if exists $primary_h->{$group_attr};

    # TODO: inline+merge what join/group/etc do for better performance.

    my ($both, $primary_only, $inner) = $primary->_ptn_conj_and_disj(
            $primary_h, $secondary->_heading() );
    my $inner_h = {CORE::map { $_ => undef } @{$inner}};

    my ($pri_matched, $pri_nonmatched)
        = @{$primary->_semijoin_and_diff( $secondary )};

    my $result_matched = $pri_matched
        ->_join( [$secondary] )
        ->_group( $group_attr, $inner, [CORE::keys %{$primary_h}],
            $inner_h );

    my $result_nonmatched = $pri_nonmatched
        ->_static_exten( {$group_attr => $primary->_new( $inner )} );

    return $result_matched->_union( [$result_nonmatched] );
}

###########################################################################

sub outer_join_with_undefs {
    my ($primary, $secondary) = @_;

    $secondary = $primary->_normalize_relation_arg(
        'outer_join_with_undefs', '$secondary', $secondary );

    my (undef, undef, $exten_attrs) = $primary->_ptn_conj_and_disj(
        $primary->_heading(), $secondary->_heading() );
    my $filler = {CORE::map { $_ => undef } @{$exten_attrs}};

    my ($pri_matched, $pri_nonmatched)
        = @{$primary->_semijoin_and_diff( $secondary )};

    my $result_matched = $pri_matched->_join( [$secondary] );

    my $result_nonmatched = $pri_nonmatched->_static_exten( $filler );

    return $result_matched->_union( [$result_nonmatched] );
}

###########################################################################

sub outer_join_with_static_exten {
    my ($primary, $secondary, $filler) = @_;

    $secondary = $primary->_normalize_relation_arg(
        'outer_join_with_static_exten', '$secondary', $secondary );

    confess q{outer_join_with_static_exten(): Bad $filler arg;}
            . q{ it isn't a hash-ref.}
        if ref $filler ne 'HASH';
    confess q{outer_join_with_static_exten(): Bad $filler arg;}
            . q{ it is a hash-ref, and there exist circular refs}
            . q{ between itself or its tuple-valued components.}
        if $primary->_tuple_arg_has_circular_refs( $filler );

    my (undef, undef, $exten_attrs) = $primary->_ptn_conj_and_disj(
        $primary->_heading(), $secondary->_heading() );
    my $exten_h = {CORE::map { $_ => undef } @{$exten_attrs}};

    confess q{outer_join_with_static_exten(): Bad $filler arg elem;}
            . q{ it doesn't have exactly the}
            . q{ same set of attr names as the sub-heading of $secondary}
            . q{ that doesn't overlap with the heading of $primary.}
        if !$primary->_is_identical_hkeys( $exten_h, $filler );

    my ($pri_matched, $pri_nonmatched)
        = @{$primary->_semijoin_and_diff( $secondary )};

    my $result_matched = $pri_matched->_join( [$secondary] );

    my $result_nonmatched = $pri_nonmatched->_static_exten( $filler );

    return $result_matched->_union( [$result_nonmatched] );
}

###########################################################################

sub outer_join_with_exten {
    my ($primary, $secondary, $exten_func, $allow_dup_tuples) = @_;

    $secondary = $primary->_normalize_relation_arg(
        'outer_join_with_exten', '$secondary', $secondary );
    $primary->_assert_valid_func_arg(
        'outer_join_with_exten', '$exten_func', $exten_func );

    my (undef, undef, $exten_attrs) = $primary->_ptn_conj_and_disj(
        $primary->_heading(), $secondary->_heading() );
    my $exten_h = {CORE::map { $_ => undef } @{$exten_attrs}};

    my ($pri_matched, $pri_nonmatched)
        = @{$primary->_semijoin_and_diff( $secondary )};

    my $result_matched = $pri_matched->_join( [$secondary] );

    # Note: if '_extension' dies due to what $exten_func did it would
    # state the error is reported by 'extension' and with some wrong
    # details; todo fix later; on correct it won't affect users though.
    my $result_nonmatched = $pri_nonmatched
        ->_extension( $exten_attrs, $exten_func, $exten_h );

    return $result_matched->_union( [$result_nonmatched] );
}

###########################################################################

sub clone {
    my ($self) = @_;
    return $self->_new( $self );
}

###########################################################################

sub freeze_identity {
    my ($self) = @_;
    $self->_has_frozen_identity( 1 );
    return;
}

###########################################################################

sub evacuate {
    my ($topic) = @_;
    confess q{evacuate(): Can't mutate invocant having a frozen identity.}
        if $topic->_has_frozen_identity();
    $topic->_body( {} );
    $topic->_cardinality( 0 );
    return $topic;
}

###########################################################################

sub insert {
    my ($r, $t) = @_;
    confess q{insert(): Can't mutate invocant that has a frozen identity.}
        if $r->_has_frozen_identity();
    $t = $r->_normalize_same_heading_tuples_arg( 'insert', '$t', $t );
    for my $tuple (@{$t}) {
        confess q{insert(): Bad $t arg; it contains the invocant}
                . q{ Set::Relation object as a tuple-valued component,}
                . q{ so the invocant would be frozen as a side-effect.}
            if $r->_self_is_component_of_tuple_arg( $tuple );
    }
    return $r->_insert( $t );
}

sub _insert {
    my ($r, $t) = @_;

    my $r_b = $r->_body();
    my $r_indexes = $r->_indexes();
    my $r_keys = $r->_keys();

    for my $tuple (@{$t}) {
        $tuple = $r->_import_nfmt_tuple( $tuple );
        my $tuple_ident_str = $r->_ident_str( $tuple );
        if (!exists $r_b->{$tuple_ident_str}) {
            $r_b->{$tuple_ident_str} = $tuple;

            for my $subheading_ident_str (CORE::keys %{$r_indexes}) {
                my ($subheading, $index)
                    = @{$r_indexes->{$subheading_ident_str}};
                my $subtuple_ident_str = $r->_ident_str(
                    {CORE::map { ($_ => $tuple->{$_}) }
                        CORE::keys %{$subheading}} );
                my $matched_b = $index->{$subtuple_ident_str} ||= {};
                $matched_b->{$tuple_ident_str} = $tuple;

                if (exists $r_keys->{$subheading_ident_str}) {
                    if ((CORE::keys %{$matched_b}) == 1) {
                        # A candidate key is still satisfied.
                        $r_keys->{$subheading_ident_str} = $subheading;
                    }
                    else {
                        # A candidate key is now violated.
                        CORE::delete $r_keys->{$subheading_ident_str};
                    }
                }

            }

        }
    }
    $r->_cardinality( scalar CORE::keys %{$r_b} );

    return $r;
}

###########################################################################

sub delete {
    my ($r, $t) = @_;
    confess q{delete(): Can't mutate invocant that has a frozen identity.}
        if $r->_has_frozen_identity();
    $t = $r->_normalize_same_heading_tuples_arg( 'delete', '$t', $t );
    for my $tuple (@{$t}) {
        confess q{delete(): Bad $t arg; it contains the invocant}
                . q{ Set::Relation object as a tuple-valued component,}
                . q{ so the invocant would be frozen as a side-effect.}
            if $r->_self_is_component_of_tuple_arg( $tuple );
    }
    return $r->_delete( $t );
}

sub _delete {
    my ($r, $t) = @_;

    my $r_b = $r->_body();
    my $r_indexes = $r->_indexes();

    for my $tuple (@{$t}) {
        $tuple = $r->_import_nfmt_tuple( $tuple );
        my $tuple_ident_str = $r->_ident_str( $tuple );
        if (exists $r_b->{$tuple_ident_str}) {
            CORE::delete $r_b->{$tuple_ident_str};

            for my $subheading_ident_str (CORE::keys %{$r_indexes}) {
                my ($subheading, $index)
                    = @{$r_indexes->{$subheading_ident_str}};
                my $subtuple_ident_str = $r->_ident_str(
                    {CORE::map { ($_ => $tuple->{$_}) }
                        CORE::keys %{$subheading}} );
                my $matched_b = $index->{$subtuple_ident_str};
                CORE::delete $matched_b->{$tuple_ident_str};
                if ((scalar CORE::keys %{$matched_b}) == 0) {
                    CORE::delete $index->{$subtuple_ident_str};
                }
            }

        }
    }
    $r->_cardinality( scalar CORE::keys %{$r_b} );

    return $r;
}

###########################################################################

} # class Set::Relation::V1

###########################################################################
###########################################################################

1;
