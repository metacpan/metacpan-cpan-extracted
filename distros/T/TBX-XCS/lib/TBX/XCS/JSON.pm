#
# This file is part of TBX-XCS
#
# This software is copyright (c) 2013 by Alan K. Melby.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package TBX::XCS::JSON;
use strict;
use warnings;
use TBX::XCS;
use JSON;
use Carp;
#carp from calling package, not from here
our @CARP_NOT = qw(TBX::XCS::JSON);
use Exporter::Easy (
    OK => [qw(xcs_from_json json_from_xcs)],
);
our $VERSION = '0.05'; # VERSION

# ABSTRACT: Read and write XCS data in JSON


#default: read XCS file and dump JSON data to STDOUT
print json_from_xcs(TBX::XCS->new(file => $ARGV[0]))
    unless caller;


sub json_from_xcs {
    my ($xcs) = @_;
    return to_json($xcs->{data}, {utf8 => 1, pretty => 1});
}


sub xcs_from_json {
    my ($json) = @_;
    my $struct  = decode_json $json;
    _check_structure($struct);
    my $xcs = {};
    $xcs->{data} = $struct;
    return bless $xcs, 'TBX::XCS';
}

sub _check_structure {
    my ($struct) = @_;
    if(exists $struct->{constraints}){
        _check_languages($struct->{constraints});
        _check_refObjects($struct->{constraints});
        _check_datCatSet($struct->{constraints});
    }else{
        croak 'no constraints key specified';
    }
    if(ref $struct->{name}){
        croak 'name value should be a plain string';
    }
    if(ref $struct->{title}){
        croak 'title value should be a plain string';
    }
    return;
}

sub _check_languages {
    my ($constraints) = @_;
    if(exists $constraints->{languages}){
        ref $constraints->{languages} eq 'HASH'
            or croak '"languages" value should be a hash of ' .
                'language abbreviations and names';
    }else{
        croak 'no "languages" key in constraints value';
    }
    return;
}

sub _check_refObjects {
    my ($constraints) = @_;
    #if they don't exist, fine; we don't check them anyway
    exists $constraints->{refObjects} or return;
    my $refObjects = $constraints->{refObjects};
    if('HASH' ne ref $refObjects){
        croak "refObjects should be a hash";
    };
    #empty means none allowed
    if(!keys %$refObjects){
        return;
    }
    for (keys %$refObjects) {
        croak "Reference object $_ is not an array"
            unless 'ARRAY' eq ref $refObjects->{$_};
        for my $element (@{ $refObjects->{$_} }){
            croak "Reference object $_ should refer to an array of strings"
                if(ref $element);
        }
    }
    return;
}

sub _check_datCatSet {
    my ($constraints) = @_;
    if(!exists $constraints->{datCatSet}){
        croak '"constraints" is missing key "datCatSet"';
    }
    my $datCatSet = $constraints->{datCatSet};
    if(!keys %$datCatSet){
        croak 'datCatSet should not be empty';
    }
    for my $meta_cat (keys %$datCatSet){
        my $data_cats = $datCatSet->{$meta_cat};
        _check_meta_cat($meta_cat, $data_cats);
    }
    return;
}

sub _check_meta_cat {
    my ($meta_cat, $data_cats) = @_;
    TBX::XCS::_check_meta_cat($meta_cat);
    if(ref $data_cats ne 'ARRAY'){
        croak "meta data category '$meta_cat' should be an array";
    }
    for my $data_cat (@$data_cats){
        _check_data_category($meta_cat, $data_cat);
    }
    return;
}

sub _check_data_category {
    my ($meta_cat, $data_cat) = @_;
    if( ref $data_cat ne 'HASH'){
        croak "data category for $meta_cat should be a hash";
    }
    if(!exists $data_cat->{name}){
        croak "missing name in data category of $meta_cat";
    }
    _check_datatype($meta_cat, $data_cat);
    if($meta_cat eq 'descrip'){
        if(! exists $data_cat->{levels}){
            croak "missing levels for $data_cat->{name}";
        }
        for my $level (@{ $data_cat->{levels} }){
            croak "levels in $data_cat->{name} should be single values"
                if ref $level;
        }
        TBX::XCS::_check_levels($data_cat);
        for my $level (@{ $data_cat->{levels} }){
            croak "levels in $data_cat->{name} should be single values"
                if ref $level;
        }
    }
    if(exists $data_cat->{targetType}){
        croak "targetType of $data_cat->{name} should be a string"
            if(ref $data_cat->{targetType});
    }
    if(exists $data_cat->{forTermComp}){
        if(JSON::is_bool($data_cat->{forTermComp})){
            if($data_cat->{forTermComp}){
                $data_cat->{forTermComp} = "yes";
            }else{
                $data_cat->{forTermComp} = "no";
            }
        }
        if(ref $data_cat->{forTermComp}){
            croak "forTermComp isn't a single value in $data_cat->{name}";
        }
    }
    return;
}

sub _check_datatype {
    my ($meta_cat, $data_cat) = @_;
    my $datatype = $data_cat->{datatype};
    if($meta_cat eq 'termCompList'){
        croak "termCompList cannot contain datatype"
            if $datatype;
    }else{
        if(!$datatype){
            $data_cat->{datatype} = TBX::XCS::_get_default_datatype($meta_cat);
        }else{
            TBX::XCS::_check_datatype($meta_cat, $datatype);
            _check_picklist($data_cat)
                if($datatype eq 'picklist');
        }
    }
    return;
}

sub _check_picklist {
    my ($data_cat) = @_;
    if(! exists $data_cat->{choices}){
        croak "need choices for picklist in $data_cat->{name}";
    }
    my $choices = $data_cat->{choices};
    if(ref $choices ne 'ARRAY'){
        croak "$data_cat->{name} choices should be an array"
    }
    for(@$choices){
        croak "$data_cat->{name} choices array elements should be strings"
            if(ref $_);
    }
    return;
}

1;

__END__

=pod

=head1 NAME

TBX::XCS::JSON - Read and write XCS data in JSON

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    use TBX::XCS;
    use TBX::XCS::JSON qw(json_from_xcs);
    my $xcs = TBX::XCS->new(file=>'/path/to/file.xcs');
    print json_from_xcs($xcs);

=head1 DESCRIPTION

This module allows you to work with XCS data in JSON format.

=head1 METHODS

=head2 C<json_from_xcs>

Returns a JSON string representing the structure of the input TBX::XCS
object.

=head2 C<xcs_from_json>

Returns a new XCS object created from an input JSON string. The JSON
structure is checked for validity; it should follow the same structure
as that created by json_from_xcs. If the input structure is invalid,
this method will croak.

Although all structure is checked for correctness, in many instances extra
values do not invalidate the input; therefore, comments and the like can
be inserted without error.

=head1 AUTHOR

Nathan Glenn <garfieldnate@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Alan K. Melby.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
