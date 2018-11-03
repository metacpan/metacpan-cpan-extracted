package typedjson;


# based on code from EDG::WP4::CCM::Fetch::JSONProfileTyped
# (and EDG::WP4::CCM::Fetch::ProfileCache::_decode_json)
# for an explanation and original code, see
# https://github.com/quattor/CCM/blob/master/src/main/perl/Fetch/JSONProfileTyped.pm
# This was ported and modified here because CCM is not that trivial to install from source

use strict;
use warnings;

use JSON::XS v2.3.0 qw(decode_json encode_json);

use parent qw(Exporter);

our @EXPORT = qw(process_json);

use B;
use Scalar::Util qw(blessed);

$SIG{__DIE__} = \&confess;

# Turns a JSON Object (an unordered associative array) into a Perl hash
# reference with all the types and metadata from the doc.
sub interpret_nlist
{
    my ($doc, $path, $all_scalars) = @_;

    my $nl = {};

    foreach my $k (sort keys %$doc) {
        my $b_obj = B::svref_2object(\$doc->{$k});
        $nl->{$k} = interpret_node($k, $doc->{$k}, $b_obj, $path, $all_scalars);
    }
    return $nl;
}

# Turns a JSON Array (an ordered list) in the doc into a perl array reference in which all
# the elements have the correct metadata associated.
sub interpret_list
{
    my ($doc, $path) = @_;

    my $l = [];

    my $last_idx = scalar @$doc -1;
    foreach my $idx (0..$last_idx) {
        my $b_obj = B::svref_2object(\$doc->[$idx]);
        push(@$l, interpret_node($idx, $doc->[$idx], $b_obj, $path));
    }

    return $l;
}

# Map the C<B::SV> class from C<B::svref_2object> to a scalar type
# C<IV> is 'long', C<PV> is 'double' and C<NV> is 'string'.
# Anything else will be mapped to string (including the combined
# classes C<PVNV> and C<PVIV>).
# This only works due to the XS C API used by JSON::XS and if you call
# B::svref_2object directly on the value without assigning it to a
# variable first. This is no magic function that will
# "just work" on anything you throw at it.
sub get_scalar_type
{
    my $b_obj = shift;

    if (! blessed($b_obj)) {
        # what was passed?
        return 'string';
    };

    if ($b_obj->isa('B::IV')) {
        return 'long';
    } elsif ($b_obj->isa('B::NV')) {
        return 'double';
    } elsif ($b_obj->isa('B::PV')) {
        return 'string';
    }

    # TODO: log all else?
    return 'string';

}

# C<b_obj> is returned by the C<B::svref_2object()> method on the C<doc>
# (ideally before C<doc> is assigned).
# The initial call doesn't pass the C<b_obj> value, but that is
# acceptable since we do not expect the whole JSON profile to be a single scalar value.
# returns nested hashref, with each json level a hashref with at least VALUE key
# for scalars, there's also a TYPE key
# nodes have a NAME field (except for the root node)
# only support non-empty list of scalars of same type
sub interpret_node
{
    my ($name, $doc, $b_obj, $path, $all_scalars) = @_;

    my $r = ref($doc);

    my $v = {};
    # TODO: ugly
    # name should only be undefined in the initial call
    $v->{PATH} = (defined($name) || @$path) ? [@$path, $name] : [@$path];
    if (!$r) {
        $v->{VALUE} = $doc;
        $v->{TYPE}  = get_scalar_type($b_obj);
    } elsif ($r eq 'HASH') {
        $v->{VALUE} = interpret_nlist($doc, $v->{PATH}, $all_scalars);
    } elsif ($r eq 'ARRAY') {
        $v->{TYPE} = 'list';
        # do not pass all_scalars here
        $v->{VALUE} = interpret_list($doc, $v->{PATH}, $all_scalars);
        # sanity check
        #   all same type
        #   only scalars
        my @types;
        foreach my $el (@{$v->{VALUE}}) {
            my $type = $el->{TYPE};
            if ($type) {
                push(@types, $type) if ! grep {$_ eq $type} @types;
            } else {
                die "Non-scalar list element in node $name";
            }
        }
        die "More then one scalar type in node $name: @types" if scalar(@types) != 1;
    } elsif (JSON::XS::is_bool($doc)) {
        $v->{TYPE} = "boolean";
        $v->{VALUE} = $doc ? 1 : 0;
    } else {
        die "Unknown ref type ($r) for JSON document $doc";
    }

    my $type = $v->{TYPE};
    if ($type) {
        my $scalar = {type => $type, path => $v->{PATH}};
        if ($type eq 'list') {
            # set type of scalar
            $scalar->{type} = $v->{VALUE}->[0]->{TYPE};
            $scalar->{islist} = 1;
        }
        push(@$all_scalars, $scalar);
    }

    return $v;
}


# read JSON input
# return arrayref with all scalars and their name. path and type
sub parse_json
{

    my ($txt) = @_;

    # from EDG::WP4::CCM::Fetch::ProfileCache::_decode_json

    my $tmptree = decode_json($txt);
    # Regenerated profile should be identical
    # (except for some panc xml-encoded string issues,
    #   alphabetic hash order and the prettyfied format)
    #   alphabetic hash order can be fixed with '->canonical(1)', but why bother
    # This assumption is the main reason json_typed works at all.
    # This should also untaint the profile
    my $tmpprofile = encode_json($tmptree);
    my $tree = decode_json($tmpprofile);

    my $scalars = [];
    my $nodes = interpret_node(undef, $tree, undef, [], $scalars);

    return $scalars;
}


# try to make a hashref of all scalars, with shortest name possible
# names will be generated from paths, joined by _
# dupes is arrayref of duplicate (ie not to be used) names, updated in place
sub process_scalars
{
    my ($scalars, $dupes) = @_;

    my $options = {};
    my @fails;

    foreach my $scalar (@$scalars) {
        my $depth = 1;
        my $name;
        while (!defined($name) || grep {$_ eq $name} @$dupes) {
            $name = join("_", @{$scalar->{path}}[-$depth..-1]);
            $depth += 1;
        }
        if (exists($options->{$name})) {
            # add name to dupes
            push(@$dupes, $name);
            push(@fails, $name);
            # replace value with undef
            $options->{$name} = undef;
        } else {
            $options->{$name} = $scalar;
        }
    };

    return ($options, \@fails);

}

# dupes: names that are already in use; eg url templates
sub process_json
{
    my ($json_txt, $dupes) = @_;

    my $scalars = parse_json($json_txt);

    my ($options, $fails);
    while (!defined($fails) || @$fails) {
        ($options, $fails) = process_scalars($scalars, $dupes);
    }

    return $options;
}

1;
