package NetHack::Item::Spoiler;
{
  $NetHack::Item::Spoiler::VERSION = '0.21';
}
use strict;
use warnings;

use Module::Pluggable (
    search_path => __PACKAGE__,
    require     => 1,
    sub_name    => 'spoiler_types',
);

use Memoize;
memoize 'list';
memoize 'name_to_type_list';
memoize 'possibilities_to_appearances';
memoize 'plurals';
memoize 'plural_of_list';
memoize 'singular_of_list';
memoize 'all_identities';

my %artifact;

# actual item lookups {{{
sub spoiler_for {
    my $self = shift;
    my $name = shift;

    my $subspoiler = $self->name_to_class($name)
        or return;

    return $subspoiler->list->{$name};
}

sub list {
    my $self = shift;
    my ($items, %defaults) = $self->_list;
    my $type = lc $self;
    $type =~ s/.*:://;

    my @defer_appearance;

    # tag each item with its name, weight, appearances, etc
    for my $name (keys %$items) {
        my $stats = $items->{$name};
        $stats->{name}        = $name;
        $stats->{type}        = $type;
        $stats->{weight}    ||= $defaults{weight};
        $stats->{material}  ||= $defaults{material};
        $stats->{price}     ||= $defaults{price};
        $stats->{stackable} ||= $defaults{stackable};
        $stats->{glyph}     ||= $defaults{glyph};
        $stats->{plural}      = $defaults{plural}($name)
            if exists $defaults{plural};

        unless (exists $stats->{appearance} || exists $stats->{appearances}) {
            # the base item may not be processed yet, so we need to defer
            # checking this artifact's appearance for now..
            push @defer_appearance, $stats
                if $stats->{artifact} && $stats->{base};

            my $appearance = $defaults{appearance}
                          || $defaults{appearances}
                          || $name;

            if (ref $appearance eq 'ARRAY') {
                $stats->{appearances} = $appearance;
            }
            else {
                $stats->{appearance} = $appearance;
            }
        }
    }

    for my $stats (@defer_appearance) {
        $stats->{appearance} = $items->{ $stats->{base} }->{appearance};
        $stats->{appearances} = $items->{ $stats->{base} }->{appearances};
    }

    return $items;
}
# }}}
# names, appearances, and types {{{
sub name_to_type_list {
    my $self = shift;
    my %all_types;

    for my $class ($self->spoiler_types) {
        my $type = $class->type;

        my $list = $class->list;
        for (values %$list) {
            $all_types{$_->{name}} = $type;
            $all_types{$_} = $type
                for grep { defined }
                    $_->{appearance},
                    @{ $_->{appearances} || [] };

            $artifact{lc $_->{name}} = $_
                if $_->{artifact};
        }

        if ($class->can('extra_names')) {
            for ($class->extra_names) {
                $all_types{$_} = $type;
            }
        }
    }

    return \%all_types;
}

sub all_identities {
    my $self = shift;
    my @identities;

    for my $class ($self->spoiler_types) {
        my $list = $class->list;
        for (values %$list) {
            push @identities, $_->{name};
        }
    }

    return @identities;
}

sub name_to_type {
    my $self = shift;
    my $name = shift;

    my $list = $self->name_to_type_list;

    my $type = $list->{ $name || '' }
            || $list->{ $self->singularize($name) || '' };

    # handle e.g. "potion called fruit juice"
    $type ||= $name if $self->type_to_class($name)->can('list');

    return $type;
}

sub type_to_class {
    my $self = shift;
    my $type = shift;

    return __PACKAGE__ . "::\u\L$type";
}

sub name_to_class {
    my $self = shift;
    my $name = shift;

    my $type = $self->name_to_type($name);

    return undef if !$type;
    return $self->type_to_class($type);
}
# }}}
# possibilities and appearances {{{
sub possibilities_to_appearances {
    my $self = shift;
    my $list = $self->list;

    my %possibilities;

    for my $stats (values %$list) {
        next if $stats->{artifact} # artifacts are always known
             && $stats->{base};    # ..but we still want the special artifacts

        push @{ $possibilities{$_} }, $stats->{name}
            for grep { defined }
                     $stats->{appearance},
                     @{ $stats->{appearances} };
    }

    return \%possibilities;
}

sub possibilities_for_appearance {
    my $self = shift;
    my $appearance = shift;
    my $possibilities;

    my $subspoiler = $self->name_to_class($appearance)
        or return;

    $possibilities = [$appearance] if $subspoiler->list->{$appearance};
    $possibilities ||= $subspoiler->possibilities_to_appearances->{$appearance};
    $possibilities ||= [];

    return $possibilities;
}
# }}}
# singularize and pluralize {{{
sub plurals {
    my $self = shift;
    my $list = $self->list;
    my %plurals;

    for (values %$list) {
        $plurals{$_->{name}} = $_->{plural}
            if $_->{plural};
    }

    if ($self->can('extra_plurals')) {
        my $extra = $self->extra_plurals;
        @plurals{keys %$extra} = values %$extra;
    }

    return \%plurals;
}

sub plural_of_list {
    my $self = shift;
    my %all_plurals;

    for my $class ($self->spoiler_types) {
        my $plurals = $class->plurals;
        @all_plurals{keys %$plurals} = values %$plurals;
    }

    return \%all_plurals;
}

sub singular_of_list {
    my $self = shift;
    return { reverse %{ $self->plural_of_list } };
}

sub pluralize {
    my $self = shift;
    my $item = shift;

    $self->plural_of_list->{$item};
}

sub singularize {
    my $self = shift;
    my $item = shift;

    $self->singular_of_list->{$item};
}
# }}}
# japanese names {{{
sub japanese_to_english {
    return {
        "wakizashi"       => "short sword",
        "ninja-to"        => "broadsword",
        "nunchaku"        => "flail",
        "naginata"        => "glaive",
        "osaku"           => "lock pick",
        "koto"            => "wooden harp",
        "shito"           => "knife",
        "tanko"           => "plate mail",
        "kabuto"          => "helmet",
        "yugake"          => "leather gloves",
        "gunyoki"         => "food ration",
        "potion of sake"  => "potion of booze",
        "potions of sake" => "potions of booze",
    };
}
# }}}
# artifacts {{{
sub artifact_spoiler {
    my $self = shift;
    my $name = lc(shift);

    $name =~ s/^the\s+//;

    return $artifact{$name};
}
# }}}
# collapsing values {{{
sub collapse_value {
    my $self = shift;
    my $key  = shift;

    my @values = map { $self->spoiler_for($_)->{$key} } @_;
    my $value = shift @values;
    return undef if !defined($value);

    for (@values) {
        return undef if !defined($_) || $_ ne $value;
    }

    return $value;
}
# }}}

1;

