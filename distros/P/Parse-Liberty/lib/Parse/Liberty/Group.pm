package Parse::Liberty::Group;

use strict;
use warnings;

our $VERSION    = 0.13;

use Parse::Liberty::Constants qw($e $e2 %errors);
use Parse::Liberty::Attribute;
use Parse::Liberty::Define;


sub new {
    my $class = shift;
    my %options = @_;

    my $self = {
        object_type => 'group',
        parser      => $options{'parser'},
        parent      => $options{'parent'},
        si2_object  => $options{'si2_object'},
        depth       => $options{'depth'},
    };
    bless $self, $class;
    return $self;
}


sub methods {
    my $self = shift;
    return (join "\n", qw(lineno comment remove type get_names set_names get_attributes get_defines get_groups extract))."\n";
}


sub lineno {
    my $self = shift;
    my $si2_group = $self->{si2_object};
    return liberty::si2drObjectGetLineNo($si2_group, \$e);
}


sub comment {
    my $self = shift;
    my $si2_group = $self->{si2_object};
    return liberty::si2drGroupGetComment($si2_group, \$e);
}


sub remove {
    my $self = shift;
    my $si2_group = $self->{si2_object};
    liberty::si2drObjectDelete($si2_group, \$e);
#    $self->DESTROY; # no sure we need this
    return 1;
}

################################################################################

sub type {
    my $self = shift;
    my $si2_group = $self->{si2_object};

    my $type = liberty::si2drGroupGetGroupType($si2_group, \$e);
    $type = "\"$type\"" if $type =~ m/\s/;
    return $type;
}


sub get_names {
    my $self = shift;
    my $si2_group = $self->{si2_object};

    my $si2_names = liberty::si2drGroupGetNames($si2_group, \$e);
    my @names;
    while(my $name = liberty::si2drIterNextName($si2_names, \$e)) {
        $name = "\"$name\"" if $name =~ m/\s/;
        push @names, $name;
    }
    liberty::si2drIterQuit($si2_names, \$e);

    return wantarray ? @names : join(', ', @names);
}


sub set_names {
    my $self = shift;
    my @req_names = @_;
    my $si2_group = $self->{si2_object};

    my @names = $self->get_names;

    ## delete original names
    liberty::si2drGroupDeleteName($si2_group, $_, \$e) for @names;

    ## add names one by one
    liberty::si2drGroupAddName($si2_group, $_, \$e) for @req_names;

    return 1;
}


sub get_attributes {
    my $self = shift;
    my @req_names = @_;
    my $si2_group = $self->{si2_object};

    my $si2_attributes = liberty::si2drGroupGetAttrs($si2_group, \$e);
    my @attributes;
    while(!liberty::si2drObjectIsNull(my $si2_attribute = liberty::si2drIterNextAttr($si2_attributes, \$e), \$e2)) {
        my $name = liberty::si2drAttrGetName($si2_attribute, \$e);
        if(!@req_names || grep {$name =~ m/^$_$/} @req_names) {
            push @attributes, new Parse::Liberty::Attribute (
                parser      => $self->{parser},
                parent      => $self,
                si2_object  => $si2_attribute,
                depth       => $self->{depth} + 1,
            );
            last if !wantarray;
        }
    }
    liberty::si2drIterQuit($si2_attributes, \$e);

    return wantarray ? @attributes : $attributes[0];
}


sub get_defines {
    my $self = shift;
    my @req_names = @_;
    my $si2_group = $self->{si2_object};

    my $si2_defines = liberty::si2drGroupGetDefines($si2_group, \$e);
    my @defines;
    while(!liberty::si2drObjectIsNull(my $si2_define = liberty::si2drIterNextDefine($si2_defines, \$e), \$e2)) {
        my $name = liberty::si2drDefineGetName($si2_define, \$e);
        if(!@req_names || grep {$name =~ m/^$_$/} @req_names) {
            push @defines, new Parse::Liberty::Define (
                parser      => $self->{parser},
                parent      => $self,
                si2_object  => $si2_define,
                depth       => $self->{depth} + 1,
            );
            last if !wantarray;
        }
    }
    liberty::si2drIterQuit($si2_defines, \$e);

    return wantarray ? @defines : $defines[0];
}


sub get_groups {
    my $self = shift;
    my $req_type = shift;
    my @req_names = @_;
    my $si2_group = $self->{si2_object};

    my $si2_groups = liberty::si2drGroupGetGroups($si2_group, \$e);
    my @groups;
    while(!liberty::si2drObjectIsNull(my $si2_group = liberty::si2drIterNextGroup($si2_groups, \$e), \$e2)) {
        my $type = liberty::si2drGroupGetGroupType($si2_group, \$e);

        my $si2_names = liberty::si2drGroupGetNames($si2_group, \$e);
        my $first_name = liberty::si2drIterNextName($si2_names, \$e);
        liberty::si2drIterQuit($si2_names, \$e);

        if(!(defined $req_type)
        || ($type eq $req_type && (!@req_names || grep {$first_name =~ m/^$_$/} @req_names))) {
            push @groups, new Parse::Liberty::Group (
                parser      => $self->{parser},
                parent      => $self,
                si2_object  => $si2_group,
                depth       => $self->{depth} + 1,
            );
            last if !wantarray;
        }
    }
    liberty::si2drIterQuit($si2_groups, \$e);

    return wantarray ? @groups : $groups[0];
}


sub extract {
    my $self = shift;
    my $indent = $self->{parser}->{indent};
    my $depth = $self->{depth};
    my $comment = $self->comment;

    my $type = $self->type;
    my $names = $self->get_names; # get names as string

    my @attributes = $self->get_attributes;
    my @defines = $self->get_defines;
    my @groups = $self->get_groups;

    my $string = '';

    my $indent_string = ' ' x $indent;
    my $full_indent = $indent_string x $depth;

    $string .= "/*$comment*/\n" if defined $comment;
    $string .= $full_indent.sprintf("%s (%s) {\n", $type, $names);

##    $string .= $_->extract for @attributes;
    my @default_attributes;
    foreach my $attribute (@attributes) {
        ## collect 'default_' attributes
        if($attribute->name =~ m/^default_/) {
            push @default_attributes, $attribute;
        } else {
            $string .= $attribute->extract;
        }
    }

    $string .= "\n" if @defines && @attributes;
    $string .= $_->extract for @defines;

##    $string .= "\n".$_->extract for @groups;
    my $default_attributes_placed = 0;
    foreach my $group (@groups) {
        ## place 'default_' attributes before first 'template' or 'cell' group
        if(@default_attributes
        && $group->{depth} == 1
        && $group->type =~ m/template|^cell$/
        && !$default_attributes_placed) {
            $string .= "\n";
            $string .= $_->extract for @default_attributes;
            $default_attributes_placed = 1;
        }

        $string .= "\n".$group->extract;
    }
    ## place 'default_' attributes if no 'template'- or 'cell'-type groups in library
    if(!$default_attributes_placed) {$string .= $_->extract for @default_attributes}

    $string .= $full_indent."}";

    $string .= "\n";
    return $string;
}


1;
