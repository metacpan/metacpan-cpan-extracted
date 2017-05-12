package Morpheus::Utils;
{
  $Morpheus::Utils::VERSION = '0.46';
}
use strict;

# ABSTRACT: some common functions which don't fit anywhere else

sub normalize ($);
sub adjust ($$);
sub merge ($$;$);

use base qw(Exporter);
our @EXPORT = qw(normalize merge adjust);

use Symbol qw(gensym);

use Morpheus::Key qw(key);

sub normalize ($) {
    my ($data) = @_;
    return $data unless ref $data eq "HASH";
    my $result = { %$data };
    for my $key ( keys %$data) {
        my @keys = @{key($key)};
        next if @keys == 1 and $keys[0] eq $key; # "/a//" -> "a"
        my $value = delete $result->{$key};
        my $p = my $patch = {};
        $p = $p->{$_} = {} for splice @keys, 0, -1;
        $p->{$keys[0]} = $value;
        $result = merge($result, $patch);
        # {"a/b/c"=>"d"} -> {a=>{b=>{c=>"d"}}}
    }
    return $result;
}

sub adjust ($$) {
    my ($value, $delta) = @_;
    return $value unless $delta;
    for (@{key($delta)}) {
        if (defined $value and ref $value eq "HASH") {
            $value = $value->{$_};
        } elsif (defined $value and ref $value eq "GLOB") {
            $value = ${*$value}{$_};
        } else {
            return (undef);
        }
    }
    return $value;
}

sub merge ($$;$) {
    my ($value, $patch, $die_on_collision) = @_;
    #TODO: support $die_on_collision!

    return $patch unless defined $value;
    return $value unless defined $patch;

    my %refs = map { $_ => 1 } qw(GLOB HASH ARRAY);
   
    # TODO: return a glob itself instead of a globref!
   
    my $ref_value = ref $value;
    $ref_value = "" unless $refs{$ref_value};
    my $ref_patch = ref $patch;
    $ref_patch = "" unless $refs{$ref_patch};
    
    if ($ref_value eq "GLOB") {
        my $result = gensym;
        *{$result} = *{$value};
        if ($ref_patch eq "GLOB") {
            my $hash = merge(*{$value}{HASH}, *{$patch}{HASH});
            *{$result} = $hash if $hash;
            my $array = merge(*{$value}{ARRAY}, *{$patch}{ARRAY});
            *{$result} = $array if $array;
            ${*{$result}} = merge(${*{$value}}, ${*{$patch}});
        } else {
            ${*{$result}} = merge(${*{$value}}, $patch);
        }
        return $result;
    } 
    
    if ($ref_patch eq "GLOB") {
        my $result = gensym;
        *{$result} = *{$patch};
        ${*{$result}} = merge($value, ${*{$patch}}); 
        return $result;
    }

    if ($ref_value eq "HASH" and $ref_patch eq "HASH") {
        my $result = { %$value };
        for (keys %$patch) {
            $result->{$_} = merge($value->{$_}, $patch->{$_});
        }
        return $result;
    }

    return $value;
}

1;

__END__
=pod

=head1 NAME

Morpheus::Utils - some common functions which don't fit anywhere else

=head1 VERSION

version 0.46

=head1 AUTHOR

Andrei Mishchenko <druxa@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

