package Parse::Liberty;

use strict;
use warnings;

our $VERSION    = 0.13;

use liberty;
use Parse::Liberty::Constants qw($e $e2 %errors);
use Parse::Liberty::Group;


sub new {
    my $class = shift;
    my %options = @_;

    ## untilde path
    require File::Glob;
    $options{'file'} = File::Glob::bsd_glob($options{'file'});

    ## set debug mode
    liberty::si2drPISetDebugMode(\$e) if $options{'verbose'};

    ## initialize
    liberty::si2drPIInit(\$e);
    printf STDERR "* PIInit: %s\n", $errors{$e} if $options{'verbose'};

    ## read liberty file
    printf STDERR "* Reading %s...\n", $options{'file'} if $options{'verbose'};
    liberty::si2drReadLibertyFile($options{'file'}, \$e);
    printf STDERR "* ReadLibertyFile: %s\n", $errors{$e} if $options{'verbose'};
    die "\n" if $errors{$e} ne 'NO ERROR';

    my $self = {
        file    => $options{'file'},
        indent  => $options{'indent'}   || 2,
        verbose => $options{'verbose'}  || 0,
    };
    bless $self, $class;
    return $self;
}


sub methods {
    my $self = shift;
    return (join "\n", qw(library write_library))."\n";
}

################################################################################

sub library {
    my $self = shift;

    ## get root group
    my $si2_groups = liberty::si2drPIGetGroups(\$e);
    my $si2_group = liberty::si2drIterNextGroup($si2_groups, \$e);
    liberty::si2drIterQuit($si2_groups, \$e);
    my $group = new Parse::Liberty::Group (
        parser      => $self,
        parent      => $self,
        si2_object  => $si2_group,
        depth       => 0,
    );

    return $group;
}


sub write_library {
    my $self = shift;
    my $file = shift;

    my $si2_group = $self->library->{si2_object};

    printf "* Writing %s...\n", $file if $self->{verbose};
    liberty::si2drWriteLibertyFile($file, $si2_group, \$e);
    printf "* WriteLibertyFile: %s\n", $errors{$e} if $self->{verbose};

    return 1;
}


1;
__END__


=pod

=head1 NAME

Parse::Liberty - Parser for Synopsys Liberty files


=head1 SYNOPSIS

    use Parse::Liberty;
    my $parser = new Parse::Liberty (verbose=>0, indent=>4, file=>"test.lib");
    print 'indent: ', $parser->{indent}, "\n";

    ## get root 'library' group
    my $library = $parser->library;
    print $library->type;       # => library
    print $library->get_names;  # => testlib

    ## set new name for group
    $library->set_names('my_testlib');

    ## all 'cell'-type groups
    my @cells = $library->get_groups('cell');
    ## or
    my @cells = grep {$_->type eq 'cell'} $library->get_groups;
    ## get cells by name
    my @cells = $library->get_groups('cell', 'SDFFRHQX2', 'NAND.*X4');

    ## get one cell
    my $cell = $library->get_groups('cell', 'NAND2X1');

    ## cell attributes
    my @attributes = $cell->get_attributes;
    ## by name
    my @attributes = $cell->get_attributes(qw(area cell_leakage_power), 'dont_.*');
    my $area = $cell->get_attributes('area');
    print $area->get_values->value;

    ## cell 'pin'-type groups
    my @pins = $cell->get_groups('pin');
    my $pin = $cell->get_groups('pin', 'Y');

    ## pin function
    my $function = $pin->get_attributes('function')->get_values;
    print $function->type   # => string
    print $function->value  # => "(!(A B))"


=head1 DESCRIPTION

Parse::Liberty may be used to extract and modify information from Synopsys Liberty files.
Liberty format is widely used standard for keeping various information for EDA applications.

Parse::Liberty build on top Perl-C SWIG interface to Open Source Liberty liberty_parse functions.

To use Parse::Liberty, we need to build liberty_parse package from Open Source Liberty (links in L<"SEE ALSO"> section).

=head2 Liberty format

Every Liberty file consists of comments, empty lines, groups, attributes and defines.

Each group can contain comments, empty lines, attributes and other groups.

There is the root group called 'library', which contains library-level attributes, cell groups
and library-wide groups such operating conditions, voltages, and table templates.

=over

=item Comment syntax

    /* ... */

=item Group syntax

    type(name) {
        ...
    }

or with multiple names (for ex. 'ff(IQ,IQN)' groups in flip-flop cells)

    type(name1 [, name2, ...]) {
        ...
    }

Common types is 'cell' for 'library' group and 'pin' in 'cell'-type groups.

A new, non-predefined group can be created with 'define_group' statement (see below).

=item Attribute syntax

Simple attribute:

    name : value ;

Complex attribute:

    name(value1 [, value2, ...]) ;

Attribute value can be one of several types (see L<"Value types">).

Example of complex attribute is 'values()' table, where each value represent one row and
looks like comma-separated "string".

A new, non-predefined attribute can be created with 'define' statement (see below).

=item Define syntax

New group:

    define_group (name, allowed_group_name);

New attribute:

    define (name, allowed_group_name, type);

Can be used to create new groups and attributes. Type is one of the L<"Value types">.

=back

=head2 Common properties

=over

=item object_type

Type of object (string, see L<"Object types">)

=item parser

Reference to main parser object (C<Parse::Liberty>)

=item parent

Reference to parent object (C<Parse::Liberty::Attribute> or C<Parse::Liberty::Group>)

=item si2_object

Reference to underlying SWIG-C object (SI2DR object)

=item depth

Object depth (integer >= 0)

=back

=head2 Common methods

=over

=item methods

Return object avaible methods (string)

=item lineno

Return line number, associated with object (integer)

=item comment

Return comment, associated with object or undef (string, without C</**/>)

=item remove

Remove object, return 1

=item extract

Return object representation string (with indentation = indent*depth and trailing newline)

=back

=head2 Parse::Liberty methods

=over

=item new

Create new C<Parse::Liberty> object

Arguments:

=over

=item file

path to Liberty file (string, mandatory)

=item indent

intent to write out Liberty portions (integer, default 2)

=item verbose

enable verbose messages (any True or False value, default 0)

=back

=item library

Return root group (C<Parse::Liberty::Group> object)

=item write_library

Write library to a file. This is preferred and much faster way to output the
full library, than C<extract> method

Arguments:

=over

=item file

path to the file to write

=back

=back

=head2 Parse::Liberty::Attribute methods

=over

=item type

Return attribute type - simple or complex (string)

=item name

Return attribute name (string)

=item is_var

Return true if simple attribute is variable declaration (boolean)

=item get_values

Return attribute values (list of C<Parse::Liberty::Value> objects, or 1st object in scalar context)

=item set_values

Set attribute values. Input format: C<(type1, value1[, type2, value2, ...])>. Return 1

=back

=head2 Parse::Liberty::Define methods

=over

=item type

Return define type (string, see L<"Value types">)

=item name

Return define name (string)

=item allowed_group_name

Return define allowed group name (string)

=back

=head2 Parse::Liberty::Group methods

=over

=item type

Return group type (string)

=item get_names

Return group names (list of strings, or string of names joined with comma in scalar context, or '' if nameless group)

=item set_names

Set group names. Input format: C<(name1[, name2, ...])>. Return 1

=item get_attributes

Get group attributes (list of matched C<Parse::Liberty::Attribute> objects,
or 1st matched object in scalar context,
or empty list if no attributes in group)

Arguments:

=over

=item <none>

return all C<Parse::Liberty::Attribute> objects

=item (name1[, name2, ...])

return all matched objects by name(s)

=back

=item get_defines

Get group attributes (list of matched C<Parse::Liberty::Define> objects,
or 1st matched object in scalar context,
or empty list if no defines in group)

Arguments:

=over

=item <none>

return all C<Parse::Liberty::Define> objects

=item (name1[, name2, ...])

return all matched objects by name(s)

=back

=item get_groups

Get group subgroups (list of matched C<Parse::Liberty::Group> objects,
or 1st matched object in scalar context,
or empty list if no subgroups in group)

Arguments:

=over

=item <none>

return all C<Parse::Liberty::Group> objects

=item type

return all matched objects by type 'type'

=item (type, name1[, name2, ...])

return all matched objects by type 'type' and first name(s) 'name1'(, 'name2', ...)

=back

=item This last three get_ methods can accept regular expressions

This expression placed into C<m/^ $/>, so pattern C<NAND.*> correspond to names, started with 'NAND'

=back

=head2 Parse::Liberty::Value methods

=over

=item type

Return value type (string, see L<"Value types">)

=item value

Return value value (string)

=back

=head2 Object types

=over

=item group

=item attribute

=item define

=item value

=back

=head2 Attribute types

=over

=item simple

=item complex

=item unknown

=back

=head2 Value types

=over

=item boolean

=item integer

=item float

=item string

=item expression

=item undefined

=back


=head1 DIAGNOSTICS

=head2 Errors

=over

=item NO ERROR

=item INTERNAL SYSTEM ERROR

=item INVALID VALUE

=item INVALID NAME

=item INVALID OBJECTTYPE

=item INVALID ATTRTYPE

=item UNUSABLE OID

=item OBJECT ALREADY EXISTS

=item OBJECT NOT FOUND

=item SYNTAX ERROR

=item TRACE FILES CANNOT BE OPENED

=item PIINIT NOT CALLED

=item SEMANTIC ERROR

=item REFERENCE ERROR

=item UNKNOWN ERROR

=back


=head1 EXAMPLES

=head2 Transpose NLDM/NLPM values tables

    sub transpose {
        my $columns = shift;
        my @list = @_;
        map { my $i = $_; [map $_->[$i], @list] } 0 .. $columns-1;
    }

    sub process_values {
        my @table = @_;
        my @values;
        foreach my $row (@table) {
            $row =~ s/\s+//g; # remove spaces
            $row =~ s/"(.*)"/$1/; # remove first and last '"'
            my @row = split /\s*,\s*/, $row; # values in row delimeted by ','
            push @values, \@row;
        }
        my $columns = scalar @{$values[0]}; # length of first row
        my @values_transposed = transpose($columns, @values);
        ## get list of strings instead arrays
        map {$_ = join ', ', @{$_}} @values_transposed;
    }

    sub process_group {
        my $group = shift;
        ## process templates
        if($group->type =~ m/.*_template/) {
            if(!$group->get_attributes('variable_3')
            && (my $variable_2_attr = $group->get_attributes('variable_2'))) {
                my $variable_1_attr = $group->get_attributes('variable_1');
                my $index_1_attr = $group->get_attributes('index_1');
                my $index_2_attr = $group->get_attributes('index_2');

                my $variable_1 = $variable_1_attr->get_values->value;
                my $variable_2 = $variable_2_attr->get_values->value;
                $variable_1_attr->set_values('string', $variable_2);
                $variable_2_attr->set_values('string', $variable_1);

                my $index_1 = $index_1_attr->get_values->value;
                my $index_2 = $index_2_attr->get_values->value;
                $index_1_attr->set_values('string', $index_2);
                $index_2_attr->set_values('string', $index_1);
            }
        }
        ## process values tables
        elsif(my $values_attr = $group->get_attributes('values')) {
            if(!$group->get_attributes('index_3')
            && (my $index_2_attr = $group->get_attributes('index_2'))) {
                my $index_1_attr = $group->get_attributes('index_1');

                my $index_1 = $index_1_attr->get_values->value;
                my $index_2 = $index_2_attr->get_values->value;
                $index_1_attr->set_values('string', $index_2);
                $index_2_attr->set_values('string', $index_1);

                my @values = map {$_->value} $values_attr->get_values;
                my @values_transposed = process_values(@values);
                $values_attr->set_values(map {('string', $_)} @values_transposed);
            }
        }
        process_group($_) for $group->get_groups;
    }

    use Parse::Liberty;
    my $parser = new Parse::Liberty (file=>"test.lib");
    my $library = $parser->library;
    process_group($library);
    print OUT $library->extract;

=head2 Get cells with 'dont_touch' attribute

    foreach my $cell ($library->get_groups('cell')) {
        if(my $attr = $cell->get_attributes('dont_touch')) {
            printf "%15s: %s %s\n", $cell->get_names, $attr->name, $attr->get_values->value;
        }
    }

=head2 Using Parse::Liberty::Simple

    my $parser = new Parse::Liberty::Simple ("test.lib");

    print $parser->name; # library name

    my @attrs = $parser->attrs; # all library-level attributes
    my @attrs = $parser->attrs('date', '.*_unit');
    my $attr = $parser->attrs('date'); # object (print $attr->value)
    my $attr = $parser->attr('date'); # value of an attribute
    print $_->name.' | '.$_->value."\n" for @attrs;

    my @cells = $parser->cells; # all cell-type groups
    my @cells = $parser->cells('BUF2', 'DFF');
    my $cell = $parser->cells('INV3');
    print $cell->name; # cell name
    print $cell->attr('area');
    print $_->name for $cell->pins;

    my $pin = $cell->pins('Q.*');
    print $pin->name; # pin name
    print $pin->attr('direction');


=head1 AUTHOR

Eugene Gagarin <mosfet07@ya.ru>


=head1 COPYRIGHT AND LICENSE

Copyright 2015 Eugene Gagarin

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO

L<http://www.opensourceliberty.org> - Open Source Liberty

L<http://www.si2.org> - Silicon Integration Initiative

L<Liberty::Parser> - Liberty parser with different approach (probably faster)

=cut
