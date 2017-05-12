#! /usr/bin/perl -w
# Author: Dongxu Ma

use warnings;
use strict;
#use English qw( -no_match_vars );
use Fcntl qw(O_RDONLY O_WRONLY O_TRUNC O_CREAT);
use File::Spec;

use YAML::Syck qw(Dump Load);

my $filename;

=head1 DESCIPTION

Format production from Parse::QTEDI into more binding-make-specific
look. This will both strip unrelevant entry and renew the structure
of other interested entries.

B<NOTE>: All new hash keys inserted here will be uppercase to
differentiate with QTEDI output, except meta field such as 'subtype'.

=cut

sub usage {
    print STDERR << "EOU";
usage: $0 <qtedi_production.yml> [<output_file>]
EOU
    exit 1;
}

=head1 ELEMENTS

Format functions.

=cut

=over

=item $FUNCTION_PROPERTIES

Keep all known C++ function and QT-specific property keywords.

Function format will firstly filter out them from prototype line.

B<NOTE>: Some properties are stored inside 'PROPERTY' field array for
futher reference.

B<NOTE>: Q_DECL_EXPORT == __attribute((visibility(default)))__ in
gcc.

=back

=cut

################ DICTIONARY ################
sub P_IGNORE() { 0 }
sub P_KEEP  () { 1 }
# QT-specific
my $QT_PROPERTIES = {
    Q_TESTLIB_EXPORT => P_IGNORE,
    Q_DECL_EXPORT    => P_KEEP,
    Q_DBUS_EXPORT    => P_IGNORE,
};

# KDE-specific
my $KDE_PROPERTIES = {
};

# function-specific
my $FUNCTION_PROPERTIES = {
    # C++ standard
    explicit         => P_IGNORE,
    implicit         => P_IGNORE,
    virtual          => P_KEEP,
    'pure virtual'   => P_KEEP,
    inline           => P_IGNORE,
    static           => P_KEEP,
    friend           => P_KEEP,
    # const belongs to return type
    # const           => P_IGNORE,
    %$QT_PROPERTIES,
    %$KDE_PROPERTIES,
};

# class/struct/union-specific
my $CLASS_PROPERTIES =  {
    # C++ standard
    inline           => P_IGNORE,
    static           => P_KEEP,
    friend           => P_KEEP,
    mutable          => P_IGNORE,
    %$QT_PROPERTIES,
    %$KDE_PROPERTIES,
};

#enum-specific
my $ENUM_PROPERTIES = $FUNCTION_PROPERTIES;

#namespace-specific
my $NAMESPACE_PROPERTIES = $CLASS_PROPERTIES;

################ FORMAT UNIT ################

=over

=item __format_macro

Keep Q_OBJECT and Q_PROPERTY for further consideration.

Each property field inside a Q_PROPERTY will be stored as a new
 key/value pair.

  # spec of Q_PROPERTY

  ---
  name : [from_QTEDI]
  type : macro
  NAME : [name]
  TYPE : [type]
  READ : [read function]
  WRITE: [write function]
  ...

=back

=cut

sub __format_macro {
    my $entry = shift;

    # keep Q_OBJECT Q_PROPERTY
    if ($entry->{name} eq 'Q_OBJECT') {
        delete $entry->{subtype};
        return 1;
    }
    elsif ($entry->{name} eq 'Q_PROPERTY') {
        my @values = split / /, $entry->{values};
        $entry->{TYPE} = shift @values;
        $entry->{NAME} = shift @values;
        while (@values) {
            my $k = shift @values;
            my $v = shift @values;
            $entry->{$k} = $v;
        }
        delete $entry->{subtype};
        delete $entry->{values};
        return 1;
    }
    else {
        return 0;
    }
}

sub __format_class_or_struct {
    my $entry = shift;
    my $type  = shift;
    # $type == 0 => class
    # $type == 1 => struct
    # by default class
    $type = 0 unless defined $type;

    # format name and property
    if ($entry->{name}) {
        my @values = split /\s+/, $entry->{name};
        my $cname = pop @values;
        foreach my $v (@values) {
            if (exists $CLASS_PROPERTIES->{$v} and
                  $CLASS_PROPERTIES->{$v} == P_KEEP) {
                push @{$entry->{property}}, $v;
            }
        }
        $entry->{NAME} = $cname;
    }
    foreach my $p (@{$entry->{property}}) {
        $p =~ s/\s+$//o;
        push @{$entry->{PROPERTY}}, $p;
    }
    delete $entry->{name};
    delete $entry->{property};
    # format inheritance line
    if (exists $entry->{inheritance} and $entry->{inheritance}) {
        foreach my $s (split /\s*,\s*/, $entry->{inheritance}) {
            next if !$s;
            if ($s =~ /^(public|private|protected) (.+)\s*$/o) {
                my $name = $2;
                my $rel  = $1;
                $name =~ s/\s+$//o;
                push @{$entry->{ISA}}, {
                    NAME => $name, RELATIONSHIP => $rel, };
            }
        }
        delete $entry->{inheritance};
    }
    # format variable
    if (exists $entry->{variable}) {
        my @variable = split /\s*,\s*/, $entry->{variable};
        foreach my $v (@variable) {
            $v =~ s/\s+$//io;
            push @{$entry->{VARIABLE}}, $v;
        }
        delete $entry->{variable};
    }
    # process body
    # strip private part
    my $abstract_class;
    if (exists $entry->{body}) {
        if ($type == 0) {
            # class
            ( $entry->{BODY}, $abstract_class ) =
              _format_class_body($entry->{body});
        }
        else {
            # struct
            ( $entry->{BODY}, $abstract_class ) =
              _format_struct_body($entry->{body});
        }
        push @{$entry->{PROPERTY}}, 'abstract' if $abstract_class;
        delete $entry->{body};
    }
    return 1;
}

=over

=item __format_class

Extract class name string and store as new field. Recursively process
 class body, strip private part.

Format inheritance line if has.

  # spec

  ---
  type     : class
  PROPERTY :
     - [class property1]
     ...
  NAME     : [name]
  ISA      :
     - NAME         : [parent class name]
       RELATIONSHIP : public/private/protected
     ...
  BODY     :
     ...
  VARIABLE :
     - [variable1]
     ...

=back

=cut

sub __format_class {
    return __format_class_or_struct($_[0], 0);
}

=over

=item __format_struct

Similar as __format_class.

B<NOTE>: As defined in C++, top entries not covered by any
public/private/protected keyword will be treated private.

See __format_class above regarding output spec.

=back

=cut

sub __format_struct {
    return __format_class_or_struct($_[0], 1);
}

=over

=item __format_union

Similar as __format_struct.

See __format_class above regarding output spec.

=back

=cut

sub __format_union {
    # FIXME: how to deal with union
    return __format_class_or_struct($_[0], 1);
}

=over

=item __normalize

Normalize type or function pointer string.

=back

=cut

sub __normalize {
    my $string = shift;
    # normalize
    $string =~ s/^\s+//gio;
    $string =~ s/\s+$//gio;
    $string =~ s/\s+/ /gio;
    $string =~ s/<\s+/</gio;
    $string =~ s/\s+,/,/gio;
    $string =~ s/,\s+/,/gio;
    $string =~ s/\s+>/>/gio;
    $string =~ s/>\s+::/>::/gio;
    return $string;
}

=over

=item __format_fpointer

Format a function pointer entry.

  # spec

  ---
  type          : fpointer
  PROPERTY      :
     - [function property1]
     ...
  NAME          : [T_FPOINTER_BLAH]
  NAME_ORIGIN   : [BLAH]
  PROTOTYPE     : [prototype string]
  DEFAULT_VALUE : [default value, mostly 0]
  FPOINTERINFO  :
     - NAME      : [same as NAME above]
                   [could be a ref to inner FPOINTERINFO structure
                    in case of function pointer which returns
                    another function pointer                      ]
     - RETURN    : [similar as in function]
     - PARAMETER : [similar as in function]

=back

=cut

sub __format_fpointer {
    my $entry = shift;

    # grep function property from return field
    my $properties =
      exists $entry->{property} ? $entry->{property} : [];
    my $fpreturn   = [];
    my @return = split /\s*\b\s*/, $entry->{return};
    foreach my $e (@return) {
        if (exists $FUNCTION_PROPERTIES->{$e} and
              $FUNCTION_PROPERTIES->{$e} == P_KEEP) {
            push @$properties, $e;
        }
        else {
            push @$fpreturn, $e;
        }
    }
    # cat return type string
    my $fpreturn_type = shift @$fpreturn;
    for (my $i = 0; $i < @$fpreturn; ) {
        if ($fpreturn->[$i] eq '::') {
            $fpreturn_type .= $fpreturn->[$i]. $fpreturn->[$i+1];
            $i += 2;
        }
        else {
            $fpreturn_type .= ' '. $fpreturn->[$i];
            $i++;
        }
    }
    # make new function pointer name
    # and cat function prototype string
    my $FP_TYPE_PREFIX = 'T_FPOINTER_';
    my $fpname;
    my $fpname_origin;
    my $fproto = $fpreturn_type. ' ';

    my $get_parameters = sub {
        my ( $plist, $params ) = @_;

        foreach my $p (@{$plist}) {
            if ($p->{subtype} eq 'fpointer') {
                __format_fpointer($p);
                my $proto = $p->{PROTOTYPE};
                if (exists $p->{DEFAULT_VALUE}) {
                    $proto .= ' = '. $p->{DEFAULT_VALUE};
                }
                push @$params, $proto;
            }
            elsif ($p->{name}) {
                # skip $p->{name} is ''
                my $param = $p->{name};
                if (exists $p->{default}) {
                    $param .= ' = '. $p->{default};
                }
                push @$params, $param;
            }
        }
    };
    my $patch_fpointer_name = sub {
        # add $FP_TYPE_PREFIX at the right place
        # change name into upper case
        # keep namespace prefix untouched
        my $fullname = shift;
        my @n = split /\:\:/, $fullname;
        ( my $patched = pop @n ) =~
          s/^(\*+\s*)(.+)/$1.$FP_TYPE_PREFIX.uc($2).'_'.uc($filename)/eio;
        my $origin = $2;
        return [ join("::", @n, $patched),
             join("::", @n, $origin)];
    };

    if (ref $entry->{name} eq 'HASH') {
        # well, a function pointer which returns
        # another function pointer
        my $name = $entry->{name}->{name};
        ( $fpname, $fpname_origin ) =
          @{ $patch_fpointer_name->($name) };
        $fproto .= '(('. $fpname. ')(';
        # process inner params
        my $params = [];
        $get_parameters->($entry->{name}->{parameter}, $params);
        $fproto .= join(',', @$params). '))';
    }
    else {
        my $name = $entry->{name};
        ( $fpname, $fpname_origin ) =
          @{ $patch_fpointer_name->($name) };
        $fproto .= '('. $fpname. ')';
    }
    # strip * inside $fpname
    $fpname =~ s/\*+//io;
    # process outer params
    my $params = [];
    $get_parameters->($entry->{parameter}, $params);
    $fproto .= '('. join(',', @$params). ')';
    # attach function pointer properties
    foreach my $p (@$properties) {
        if ($p eq 'const') {
            $fproto .= ' const';
        }
        else {
            $fproto = $p. ' '. $fproto;
        }
    }

    # masquerade as a normal function entry
    # delegate to __format_function
    # fill RETURN and PARAMETER fields
    # NOTE: soft copy
    my $masque_function = {};
    $masque_function->{name}      =
      join(" ", $entry->{return}, $fpname);
    $masque_function->{parameter} = $entry->{parameter};
    $masque_function->{type}      = 'function';
    __format_function($masque_function);
    if (ref $entry->{name} eq 'HASH') {
        # a function pointer returns another functipn pointer
        # FIXME: delegate inner part to __format_function
        my $masque_inner_function = {};
        $masque_inner_function->{name}      =
          join(" ", $entry->{return}, $entry->{name}->{name});
        $masque_inner_function->{parameter} =
          $entry->{name}->{parameter};
        $masque_inner_function->{type}      = 'function';
        __format_function($masque_inner_function);
        # store in $masque_function
        $masque_function->{NAME} = {};
        $masque_function->{NAME}->{PARAMETER} =
          $masque_inner_function->{PARAMETER} if
            exists $masque_inner_function->{PARAMETER};
    }
    # normalize
    $fpname = __normalize($fpname);
    $fproto = __normalize($fproto);
    # store
    delete $entry->{name};
    delete $entry->{return};
    delete $entry->{parameter} if exists $entry->{parameter};
    $entry->{NAME}        = $fpname;
    $entry->{NAME_ORIGIN} = $fpname_origin;
    $entry->{PROTOTYPE}   = $fproto;
    $entry->{PROPERTY}    = $properties if @$properties;
    if (exists $entry->{default}) {
        $entry->{DEFAULT_VALUE} = $entry->{default};
        delete $entry->{default};
    }
    $entry->{FPOINTERINFO}= {};
    $entry->{FPOINTERINFO}->{NAME}      = $masque_function->{NAME};
    $entry->{FPOINTERINFO}->{RETURN}    = $masque_function->{RETURN};
    $entry->{FPOINTERINFO}->{PARAMETER} =
    $masque_function->{PARAMETER} if exists $masque_function->{PARAMETER};
    return 1;
}

=over

=item __format_function

Format a function entry. Extract return type, function name and all
parameters from function entry from QTEDI.

  # spec

  ---
  type      : function
  subtype   : 1/0 [is operator or not]
  PROPERTY  :
     - [function property1]
     ...
  NAME      : [name]
  RETURN    : [return type]
  PARAMETER :
     - TYPE          : [param1 type]
                       [NOTE: could be '...' in ansi]
       NAME          : [param1 name]
       DEFAULT_VALUE : [param1 default value]
     ...

=back

=cut

sub __format_function {
    my $entry = shift;

    #print STDERR $entry->{name}, "\n";
    my $fname_with_prefix = $entry->{name};
    # filter out keywords from name
    my @fvalues = split /\s*\b\s*/, $fname_with_prefix;
    my $properties = [];
    my @fname        = ();
    my @freturn_type = ();
    # get function name
    # pre-scan for operator function
    my $is_operator_function = 0;
    FN_OPERATOR_LOOP:
    for (my $i = $#fvalues; $i >= 0; $i--) {
        if ($fvalues[$i] eq 'operator') {
            # store as function name starting by operator keyword
            @fname = splice @fvalues, $i;
            $is_operator_function = 1;
            last FN_OPERATOR_LOOP;
        }
    }
    unshift @fname, pop @fvalues unless $is_operator_function;
    FN_LOOP:
    for (my $i = $#fvalues; $i >= 0; ) {
        if ($fvalues[$i] eq '::') {
            # namespace
            unshift @fname, pop @fvalues;
            unshift @fname, pop @fvalues;
            $i -= 2;
        }
        elsif ($fvalues[$i] eq '~') {
            # C++ destructor
            unshift @fname, pop @fvalues;
            $i--;
        }
        elsif ($fvalues[$i] eq '::~') {
            # destructor within namespace ;-(
            unshift @fname, pop @fvalues;
            unshift @fname, pop @fvalues;
            $i -= 2;
        }
        elsif ($fvalues[$i] eq '>::') {
            # template namespace
            unshift @fname, pop @fvalues;
            $i--;
            TN_LOOP:
            for (my $depth = 1; $i >= 0; ) {
                if ($fvalues[$i] eq '<') {
                    unshift @fname, pop @fvalues;
                    unshift @fname, pop @fvalues;
                    $i -= 2;
                    last TN_LOOP if --$depth == 0;
                }
                elsif ($fvalues[$i] eq '>') {
                    unshift @fname, pop @fvalues;
                    $i--;
                    $depth++;
                }
                # FIXME: '>::'
                else {
                    unshift @fname, pop @fvalues;
                    $i--;
                }
            }
        }
        else {
            last FN_LOOP;
        }
    }
    # get return type
    # filter out properties
    foreach my $v (@fvalues) {
        if (exists $FUNCTION_PROPERTIES->{$v}) {
            if ($FUNCTION_PROPERTIES->{$v} == P_KEEP) {
                unshift @$properties, $v;
            }
        }
        else {
            push @freturn_type, $v;
        }
    }
    if (exists $entry->{property}) {
        foreach my $p (@{$entry->{property}}) {
            if (exists $FUNCTION_PROPERTIES->{$p} and
                  $FUNCTION_PROPERTIES->{$p} == P_KEEP) {
                unshift @$properties, $p;
            }
        }
    }
    # format return type
    my $return_type;
    if (@freturn_type) {
        $return_type = shift @freturn_type;
        for (my $i = 0; $i <= $#freturn_type; ) {
            #print STDERR "$i :", $freturn_type[$i], "\n";
            if ($freturn_type[$i] eq '::') {
                $return_type .= $freturn_type[$i]. $freturn_type[$i+1];
                $i += 2;
            }
            elsif ($freturn_type[$i] eq '>::') {
                $return_type .= $freturn_type[$i]. $freturn_type[$i+1];
                $i += 2;
            }
            elsif ($freturn_type[$i] eq '<') {
                $return_type .= $freturn_type[$i];
                $i++;
            }
            elsif ($freturn_type[$i] eq '>') {
                $return_type .= $freturn_type[$i];
                $i++;
            }
            else {
                $return_type .= ' '. $freturn_type[$i];
                $i++;
            }
        }
    }
    else {
        $return_type = '';
    }
    # format params
    my $parameters = [];
    PARAMETER_MAIN_LOOP:
    foreach my $p (@{$entry->{parameter}}) {
        next PARAMETER_MAIN_LOOP if
          $p->{subtype} eq 'simple' and $p->{name} eq '';

        my $pname_with_type = $p->{name};
        my $psubtype        = $p->{subtype};
        my $pdefault_value  =
          exists $p->{default} ? $p->{default} : '';
        $pdefault_value =~ s/\s+$//o;
        my ( $pname, $ptype, $fpinfo, );

        if ($psubtype eq 'fpointer') {
            __format_fpointer($p);
            $pname = $p->{PROTOTYPE};
            $ptype = $p->{NAME};
            $fpinfo= $p->{FPOINTERINFO};
        }
        elsif ($pname_with_type =~ m/\[/io) {
            # array pointer
            # TODO: ugly match
            # similar to fpointer
            # store variable name in TYPE
            # fall decl string    in NAME
            # NOTE: transform char array[] into char *array
            if ($pname_with_type =~ /^((?:const\s+)?char\s*\*\s*)(?:const\s+)?\s*(\w+)\s*\[\]/o) {
                $ptype = $1. '*';
                $pname = $2;
            }
            elsif ($pname_with_type =~ /^(.*?)\b(\w+)(\s*\[\])/o) {
                # int *array[] v.s. char[]
                $pname_with_type = $1 ? $1. '* T_ARRAY_'. uc($2) :
                  $2. '* T_ARRAY_'. uc($2);
                $ptype = 'T_ARRAY_'. uc($2);
                $pname = $pname_with_type;
            }
            else {
                $pname_with_type =~ s{^(.*?)\b(\w+)(\s*\[)}
                                     {$1.' T_ARRAY_'.uc($2).$3}eio;
                $ptype = 'T_ARRAY_'. uc($2);
                $pname = $pname_with_type;
            }
        }
        else {
            # simple && template
            # split param name [optional] and param type
            my @pvalues =
              split /\s*(?<!::)\b(?!::)\s*/, $pname_with_type;
            my @pname = ();
            my @ptype = ();
            if (@pvalues == 1) {
                # only one entry, must be param type
                # noop
            }
            elsif (@pvalues == 2 and $pvalues[0] eq 'const') {
                # const type
                # noop
            }
            # \w may be different on different systems
            # here strictly as an 'old' word
            elsif ($pvalues[$#pvalues] =~ m/^[a-z_A-Z_0-9_\_]+$/o) {
                # process param name
                unshift @pname, pop @pvalues;
                FP_LOOP:
                for (my $i = $#pvalues; $i >= 0; ) {
                    if ($pvalues[$i] eq '::') {
                        # namespace
                        unshift @pname, pop @pvalues;
                        unshift @pname, pop @pvalues;
                        $i -= 2;
                    }
                    else {
                        last FP_LOOP;
                    }
                }
            }
            # left are type items
            @ptype = @pvalues;
            # workaround for '(un)signed' keyword
            if ($ptype[$#ptype] eq 'signed' or
                  $ptype[$#ptype] eq 'unsigned') {
                # don't pull back 'short' unsigned like 'unsigned sec'
                if ($pname[0] =~ m/^(?:int|long|short|char)$/io) {
                    # shift one item back from @pname
                    push @ptype, shift @pname;
                }
            }
            # workaround for 'long long' keyword
            if ($ptype[$#ptype] eq 'long' and
                  @pname and $pname[0] eq 'long') {
                # (un)signed long long
                push @ptype, shift @pname;
            }
            # format param name
            $pname = @pname ? join('', @pname) : '';
            # format param type
            $ptype = '';
            if (@ptype) {
                $ptype = shift @ptype;
                for (my $i = 0; $i <= $#ptype; ) {
                    if ($ptype[$i] eq '::') {
                        $ptype .= $ptype[$i]. $ptype[$i+1];
                        $i += 2;
                    }
                    elsif ($ptype[$i] eq '<') {
                        $ptype .= $ptype[$i];
                        $i++;
                    }
                    elsif ($ptype[$i] eq '>') {
                        $ptype .= $ptype[$i];
                        $i++;
                    }
                    else {
                        $ptype .= ' '. $ptype[$i];
                        $i++;
                    }
                }
            }
            $ptype =~ s/\s+$//o;
        }
        $ptype = __normalize($ptype);
        # store param unit
        my $p = { TYPE => $ptype };
        $p->{NAME} = $pname if $pname;
        $p->{DEFAULT_VALUE} = $pdefault_value if $pdefault_value ne '';
        if ($psubtype eq 'fpointer') {
            # attach FPOINTERINFO for function pointer
            $p->{FPOINTERINFO} = $fpinfo;
        }
        push @$parameters, $p;
    }

    # format function name
    my $fname = '';
    if ($is_operator_function) {
        my $i = 0;
        FN_FORMAT_LOOP:
        for (; $i < @fname; $i++) {
            $fname .= $fname[$i];
            last FN_FORMAT_LOOP if $fname[$i] eq 'operator';
        }
        if ($fname[++$i] =~ m/^[a-z_A-Z_0-9_\_]+$/o) {
            # type cast operator such as
            # operator int
            $fname .= ' '. $fname[$i++];
        }
        else {
            # operator+ and like
            $fname .= $fname[$i++];
        }
        for (; $i < @fname; $i++) {
            if ($fname[$i] eq '<') {
                # template type
                $fname .= $fname[$i];
            }
            elsif ($fname[$i] eq '>') {
                $fname .= $fname[$i];
            }
            else {
                $fname .= ' '. $fname[$i];
            }
        }
    }
    else {
        $fname = join('', @fname);
    }
    # normalize
    $fname       = __normalize($fname);
    $return_type = __normalize($return_type) if $return_type;
    # store
    $entry->{NAME}      = $fname;
    # meta info field
    $entry->{subtype}   = $is_operator_function ? 1 : 0;
    $entry->{RETURN}    = $return_type if $return_type;
    $entry->{PROPERTY}  = $properties if @$properties;
    $entry->{PARAMETER} = $parameters if @$parameters;
    delete $entry->{name};
    delete $entry->{parameter};
    delete $entry->{property};
    return 1;
}

=over

=item __format_enum

Format enum, normalize name, property and enum value entries.

  # spec

  ---
  type     : enum
  NAME     : [name]
  PROPERTY :
     - [enum property1]
     ...
  VALUE    :
     - [enum value1]
     ...
  VARIABLE :
     - [variable1]
     ...

=back

=cut

sub __format_enum {
    my $entry = shift;

    # format name and property
    if ($entry->{name}) {
        my @values = split /\s+/, $entry->{name};
        my $ename = pop @values;
        foreach my $v (@values) {
            if (exists $ENUM_PROPERTIES->{$v} and
                  $ENUM_PROPERTIES->{$v} == P_KEEP) {
                push @{$entry->{property}}, $v;
            }
        }
        $entry->{NAME} = $ename;
    }
    foreach my $p (@{$entry->{property}}) {
        $p =~ s/\s+$//o;
        push @{$entry->{PROPERTY}}, $p;
    }
    delete $entry->{name};
    delete $entry->{property};
    # normalize value entries
    foreach my $i (@{$entry->{value}}) {
        my $index = @$i == 2 ? 1 : 0;
        my $v = $i->[$index];
        $v =~ s/\s+$//o;
        $i->[$index] = $v;
    }
    if (@{$entry->{value}}) {
        $entry->{VALUE} = $entry->{value};
        delete $entry->{value};
    }
    # format variable
    if (exists $entry->{variable}) {
        my @variable = split /\s*,\s*/, $entry->{variable};
        foreach my $v (@variable) {
            $v =~ s/\s+$//io;
            push @{$entry->{VARIABLE}}, $v;
        }
    }
    return 1;
}

=over

=item __format_accessibility

Format accessibility, normalize value entries.

B<NOTE>: private type should not appear here since being stripped.

  # spec

  ---
  type     : accessibility
  VALUE    :
     - [accessibility keyword1]
     ...

=back

=cut

sub __format_accessibility {
    my $entry = shift;

    $entry->{VALUE} = $entry->{value};
    delete $entry->{value};
    return 1;
}

=over

=item __format_typedef

Format typedef, normalize value entry.

Value entry could be of type:

  1. typedef simple type C<< typedef A B; >>
  2. typedef (anonymous) class/struct/enum/union C<< typdef enum A { } B; >>
  3. typedef function pointer C<< typedef void (*P)(int, uint); >>
  4. typedef an array C<< typedef unsigned char Digest[16]; >>

  # spec

  ---
  type      : typedef
  subtype   : class/struct/enum/union/fpointer/simple
  FROM      : [from type name for simple typedef    ]
              [a hashref for class/struct/enum/union]
              [type alias for function pointer      ]
  TO        : [to type name]
              [original name of function pointer    ]
  PROTOTYPE : [prototype string of function pointer ]

=back

=cut

sub __format_typedef {
    my $entry = shift;

    # extract body entry
    if (ref $entry->{body} eq 'HASH') {
        $entry->{subtype} = $entry->{body}->{type};
        if ($entry->{subtype} eq 'fpointer') {
            # fpointer
            __format_fpointer($entry->{body});
            $entry->{PROTOTYPE}    = $entry->{body}->{PROTOTYPE};
            $entry->{TO}           = $entry->{body}->{NAME_ORIGIN};
            $entry->{FROM}         = $entry->{body}->{NAME};
            $entry->{FPOINTERINFO} = $entry->{body}->{FPOINTERINFO};
        }
        else {
            # other container type
            my $temp = [];
            _format_primitive_loop($entry->{body}, $temp);
            my $body = $temp->[0];
            $entry->{FROM} = $body->{NAME} if exists $body->{NAME};
            # $body->{VARIABLE} should exist this case
            # and has only one entry
            # or else something is wrong
            $entry->{TO}   = $body->{VARIABLE}->[0];
            # pointer/reference digit be moved into FROM
            if ($entry->{TO} =~ s/^\s*((?:\*|\&))//io) {
                $entry->{FROM} .= ' '. $1;
            }
        }
    }
    else {
        # simple
        $entry->{subtype} = 'simple';
        if ($entry->{body} =~ m/^(.*)\b(\w+)((?:\[\d+\])+)$/io) {
            # array typedef
            $entry->{TO}   = $2;
            $entry->{FROM} = $1. $3;
        }
        else {
            # other simple typedef
            # NOTE: QValueList < KConfigSkeletonItem * >List
            # strip tail space
            $entry->{body} =~ s/\n+//sio;
            $entry->{body} =~ s/\s+$//io;
            ( $entry->{FROM}, $entry->{TO} ) =
              $entry->{body} =~ m/(.*)\s+([a-z_A-Z_0-9_\__\*_\&\>]+)$/io;
            # pointer/reference digit be moved into FROM
            if ($entry->{TO} =~ s/^\s*((?:\*|\&|\>))//io) {
                $entry->{FROM} .= ' '. $1;
            }
        }
    }
    delete $entry->{body};
    return 1;
}

=over

=item __format_extern

Format extern type body.

  # spec

  ---
  type    : extern
  subtype : C/function/expression/class/struct/union/enum
  BODY    :
     ...

B<NOTE>: For subtype C, there will be more than one entry in BODY
field array. For others, just one.

=back

=cut

sub __format_extern {
    my $entry = shift;
    my $rc    = 0;

    # keep function/enum/class/struct/C
    if ($entry->{subtype} eq 'function') {
        __format_function($entry->{body});
        $rc = 1;
    }
    elsif ($entry->{subtype} eq 'enum') {
        __format_enum($entry->{body});
        $rc = 1;
    }
    elsif ($entry->{subtype} eq 'class') {
        if ($entry->{body}->{type} eq 'class') {
            $entry->{body} = __format_class($entry->{body});
            $rc = 1;
        }
        elsif ($entry->{body}->{type} eq 'struct') {
            $entry->{body} = __format_struct($entry->{body});
            $rc = 1;
        }
    }
    elsif ($entry->{subtype} eq 'C') {
        $entry->{body} = _format($entry->{body});
        $rc = 1;
    }
    # store
    if ($rc) {
        if ($entry->{subtype} eq 'C') {
            $entry->{BODY} = $entry->{body};
        }
        else {
            push @{$entry->{BODY}}, $entry->{body};
        }
        delete $entry->{body};
    }
    return $rc;
}

=over

=item __format_namespace

Format namespace code block. Normalize name and recursively format
body entries.

  # spec

  ---
  type     : namespace
  NAME     : [namespace name]
  PROPERTY :
     - [property1]
     ...
  BODY     :
     ...

=back

=cut

sub __format_namespace {
    my $entry = shift;

    # format name and property
    if ($entry->{name}) {
        my @values = split /\s+/, $entry->{name};
        my $nname = pop @values;
        foreach my $v (@values) {
            if (exists $NAMESPACE_PROPERTIES->{$v} and
                  $NAMESPACE_PROPERTIES->{$v} == P_KEEP) {
                push @{$entry->{property}}, $v;
            }
        }
        $entry->{NAME} = $nname;
    }
    foreach my $p (@{$entry->{property}}) {
        $p =~ s/\s+$//o;
        push @{$entry->{PROPERTY}}, $p;
    }
    delete $entry->{name};
    delete $entry->{property};
    # format body
    if (exists $entry->{body}) {
        $entry->{BODY} = _format($entry->{body});
        delete $entry->{body};
    }
    return 1;
}

=over

=item __format_expression

Format expression.

B<NOTE>: currently expression is stripped.

  # spec

  ---
  type  : expression
  value : [expression line]

=back

=cut

sub __format_expression {
    # FIXME: how to use such information
    #        for now just skip
    0;
}

################ FORMAT FUNCTION ################
sub _format_primitive_loop {
    my $entry             = shift;
    my $formatted_entries = shift;

    #use Data::Dumper;
    #print Dump($entry), "\n";
    if ($entry->{type} eq 'macro') {
        __format_macro($entry) and
          push @$formatted_entries, $entry;
    }
    elsif ($entry->{type} eq 'class') {
        __format_class($entry) and
          push @$formatted_entries, $entry;
    }
    elsif ($entry->{type} eq 'struct') {
        __format_struct($entry) and
          push @$formatted_entries, $entry;
    }
    elsif ($entry->{type} eq 'union') {
        __format_union($entry) and
          push @$formatted_entries, $entry;
    }
    elsif ($entry->{type} eq 'extern') {
        __format_extern($entry) and
          push @$formatted_entries, $entry;
    }
    elsif ($entry->{type} eq 'namespace') {
        __format_namespace($entry) and
          push @$formatted_entries, $entry;
    }
    elsif ($entry->{type} eq 'function') {
        __format_function($entry) and
          push @$formatted_entries, $entry;
    }
    elsif ($entry->{type} eq 'fpointer') {
        __format_fpointer($entry) and
          push @$formatted_entries, $entry;
    }
    elsif ($entry->{type} eq 'enum') {
        __format_enum($entry) and
          push @$formatted_entries, $entry;
    }
#    elsif ($entry->{type} eq 'accessibility') {
#        __format_accessibility($entry) and
#          push @$formatted_entries, $entry;
#    }
    elsif ($entry->{type} eq 'typedef') {
        __format_typedef($entry) and
          push @$formatted_entries, $entry;
    }
}

sub _format {
    my $entries           = shift;
    my $formatted_entries = [];

    # strip strategy: comment/expression/template
    foreach my $entry (@$entries) {
        #print STDERR $entry->{type}, "\n";
        _format_primitive_loop($entry, $formatted_entries);
    }
    return $formatted_entries;
}

sub _format_with_accessibility {
    my $entries           = shift;
    my $private           = shift;
    $private = defined $private ? $private : 1;
    my $formatted_entries = [];
    my $abstract_class    = 0;

    # strip strategy: comment/template/expression
    LOOP_BODY:
    foreach my $entry (@$entries) {
        #print STDERR $entry->{type}, "\n";
        if (not $private) {
            if ($entry->{type} eq 'accessibility') {
                my $is_private = $entry->{value} =~ /^private/o ? 1 : 0;
                if ($is_private) {
                    $private = 1;
                }
                else {
                    __format_accessibility($entry) and
                      push @$formatted_entries, $entry;
                }
            }
            elsif ($entry->{type} eq 'expression') {
                __format_expression($entry) and
                  push @$formatted_entries, $entry;
            }
            else {
                if ($entry->{type} eq 'function') {
                    # check for pure virtual function
                    if (grep { $_ eq 'pure virtual' } @{$entry->{property}}) {
                        $abstract_class = 1;
                    }
                }
                _format_primitive_loop($entry, $formatted_entries);
            }
        }
        else {
            # private scope
            # mask until get another non-private function/singal/slot
            # begin declaration
            if ($entry->{type} eq 'accessibility') {
                my $is_private = $entry->{value} =~ /^private/o ? 1 : 0;
                unless ($is_private) {
                    # non-private function/signal/slot begin
                    $private = 0;
                    __format_accessibility($entry) and
                      push @$formatted_entries, $entry;
                }
            }
            elsif ($entry->{type} eq 'function') {
                # check for pure virtual function
                if (grep { $_ eq 'pure virtual' } @{$entry->{property}}) {
                    $abstract_class = 1;
                }
            }
        }
    }
    return +( $formatted_entries, $abstract_class );
}

sub _format_keep_expression {
    my $entries           = shift;
    my $formatted_entries = [];

    # strip strategy: comment/template
    foreach my $entry (@$entries) {
        #print STDERR $entry->{type}, "\n";
        if ($entry->{type} eq 'expression') {
            __format_expression($entry) and
              push @$formatted_entries, $entry;
        }
        else {
            _format_primitive_loop($entry, $formatted_entries);
        }
    }
    return $formatted_entries;
}

sub _format_struct_body {
    # initially public
    _format_with_accessibility($_[0], 0);
}

sub _format_class_body {
    # initially private
    _format_with_accessibility($_[0], 1);
}

################ MAIN ################
sub main {
    usage() unless @ARGV;
    my ( $in, $out ) = @ARGV;
    die "file not found" unless -f $in;
    my @path = File::Spec::->splitdir($in);
    $filename = $path[-1];
    $filename =~ s/\.yml$//o;
    local ( *INPUT );
    open INPUT, '<', $in or die "cannot open file: $!";
    my $cont = do { local $/; <INPUT>; };
    close INPUT;
    my ( $entries ) = Load($cont);
    $cont = Dump(_format($entries));

    if (defined $out) {
        local ( *OUTPUT );
        sysopen OUTPUT, $out, O_CREAT|O_WRONLY|O_TRUNC or
          die "cannot open file to write: $!";
        print OUTPUT $cont;
        close OUTPUT or die "cannot write to file: $!";
    }
    else {
        print STDOUT $cont;
    }
    exit 0;
}

&main;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 - 2011 by Dongxu Ma <dongxu@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/artistic.html>

=cut

