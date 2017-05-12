package Parse::Liberty::Define;

use strict;
use warnings;

our $VERSION    = 0.13;

use Parse::Liberty::Constants qw($e $e2 %errors %value_types);


sub new {
    my $class = shift;
    my %options = @_;

    my $self = {
        object_type => 'define',
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
    return (join "\n", qw(lineno comment remove type name allowed_group_name extract))."\n";
}


sub lineno {
    my $self = shift;
    my $si2_define = $self->{si2_object};
    return liberty::si2drObjectGetLineNo($si2_define, \$e);
}


sub comment {
    my $self = shift;
    my $si2_define = $self->{si2_object};
    return liberty::si2drDefineGetComment($si2_define, \$e);
}


sub remove {
    my $self = shift;
    my $si2_define = $self->{si2_object};
    liberty::si2drObjectDelete($si2_define, \$e);
#    $self->DESTROY; # no sure we need this
    return 1;
}

################################################################################

sub type {
    my $self = shift;
    my $si2_define = $self->{si2_object};
    return $value_types{liberty::si2drDefineGetValueType($si2_define, \$e)}->{type};
}


sub name {
    my $self = shift;
    my $si2_define = $self->{si2_object};
    my $name = liberty::si2drDefineGetName($si2_define, \$e);
    return (defined $name) ? $name : ''
}


sub allowed_group_name {
    my $self = shift;
    my $si2_define = $self->{si2_object};
    my $allowed_group_name = liberty::si2drDefineGetAllowedGroupName($si2_define, \$e);
    return (defined $allowed_group_name) ? $allowed_group_name : ''
}


sub extract {
    my $self = shift;
    my $indent = $self->{parser}->{indent};
    my $depth = $self->{depth};
    my $comment = $self->comment;

    my $type = $self->type;
    my $name = $self->name;
    my $allowed_group_name = $self->allowed_group_name;

    my $string = '';

    my $indent_string = ' ' x $indent;
    my $full_indent = $indent_string x $depth;

    $string .= "/*$comment*/\n" if defined $comment;
    $string .= $full_indent;
    $string .= ($type eq 'undefined')
        ? "define_group ($name, $allowed_group_name) ;"
        : "define ($name, $allowed_group_name, $type) ;";

    $string .= "\n";
    return $string;
}


1;
