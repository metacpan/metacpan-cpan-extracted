# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Parse-Liberty.t'

#########################

use Test::More tests => 95;
BEGIN { use_ok('Parse::Liberty') };

#########################

use strict;
use warnings;

# check if $expr true for every element in @list
sub forall (&@) {
    my $expr = shift;
    my @list = @_;
    foreach (@list) { return 0 if !&{$expr} }
    return 1;
}

# check if ->isa($str) true for every element in @list
sub isa_all {
    my $str = shift;
    my @list = @_;
    return forall {$_->isa($str)} @list;
}


my $indent = 4;
my $file = "test.lib";

my ($attr, $def, $g, @vals, $val);


#### Liberty.pm tests ##########################################################

my $parser = new Parse::Liberty (verbose=>0, indent=>$indent, file=>$file);

isa_ok($parser, 'Parse::Liberty');

can_ok($parser, 'new', 'methods', 'library');

### properties

ok($parser->{file} eq "test.lib",
    "Parser 'file' property");

ok($parser->{indent} == 4,
    "Parser 'indent' property");

ok($parser->{verbose} == 0,
    "Parser 'verbose' property");

### common methods

ok($parser->methods eq "library\nwrite_library\n",
    "Parser methods");


#### Group.pm tests ############################################################

my $library = $parser->library;

isa_ok($library, 'Parse::Liberty::Group');

can_ok($library, 'new', 'methods', 'lineno', 'comment', 'remove',
    'type', 'get_names', 'set_names', 'get_attributes', 'get_defines', 'get_groups', 'extract');

### properties

ok($library->{object_type} eq 'group',
    "Library 'object_type' property");

isa_ok($library->{parser}, 'Parse::Liberty');

isa_ok($library->{parent}, 'Parse::Liberty');

isa_ok($library->{si2_object}, 'liberty::si2ObjectIdT');

ok($library->{depth} == 0,
    "Library 'depth' property");

### common methods

ok($library->methods eq "lineno\ncomment\nremove\ntype\nget_names\nset_names\nget_attributes\nget_defines\nget_groups\nextract\n",
    "Library methods");

ok($library->lineno == 1,
    "Library lineno");

ok(!defined $library->comment,
    "Library comment");

### methods

ok($library->type eq 'library',
    "Library type");

ok($library->get_names eq 'test1',
    "Library name");

ok($library->set_names('testlib') == 1,
    "Library set new name");

ok($library->get_names eq 'testlib',
    "Library get new name");

my @attrs;

@attrs = $library->get_attributes;
ok($#attrs == 8 && isa_all('Parse::Liberty::Attribute', @attrs),
    "Library get all attributes");

@attrs = $library->get_attributes('delay_model', 'FANOUT');
ok($#attrs == 1 && isa_all('Parse::Liberty::Attribute', @attrs),
    "Library get two attributes");

@attrs = $library->get_attributes('FAN.*T', '.*_unit');
ok($#attrs == 4 && isa_all('Parse::Liberty::Attribute', @attrs),
    "Library get attributes by regex");

$attr = $library->get_attributes('technology');
ok($attr->isa('Parse::Liberty::Attribute'),
    "Library get one attribute");

my @defs;

@defs = $library->get_defines;
ok($#defs == 3 && isa_all('Parse::Liberty::Define', @defs),
    "Library get all defines");

@defs = $library->get_defines('sec_acore_internal_power', 'sec_acore_when');
ok($#defs == 1 && isa_all('Parse::Liberty::Define', @defs),
    "Library get two defines");

@defs = $library->get_defines('.*when.*', '.*l_power');
ok($#defs == 2 && isa_all('Parse::Liberty::Define', @defs),
    "Library get defines by regex");

$def = $library->get_defines('sec_acore_rise_power');
ok($def->isa('Parse::Liberty::Define'),
    "Library get one define");

my @gps;

@gps = $library->get_groups;
ok($#gps == 5 && isa_all('Parse::Liberty::Group', @gps),
    "Library get all groups");

@gps = $library->get_groups('cell');
ok($#gps == 4 && isa_all('Parse::Liberty::Group', @gps),
    "Library get all groups by type");

@gps = $library->get_groups('cell', 'cell5', 'cell2');
ok($#gps == 1 && isa_all('Parse::Liberty::Group', @gps),
    "Library get two groups by type and name");

@gps = $library->get_groups('cell', 'c.*5', '.*[1-3]');
ok($#gps == 3 && isa_all('Parse::Liberty::Group', @gps),
    "Library get groups by type and regex");

$g = $library->get_groups('lu_table_template', 'dti_delay_drivex1_5x7');
ok($g->isa('Parse::Liberty::Group'),
    "Library get one group by type and name");


#### Attribute.pm tests ########################################################

$attr = $library->get_attributes('nom_temperature');    # first, get simple attribute

isa_ok($attr, 'Parse::Liberty::Attribute');

can_ok($attr, 'new', 'methods', 'lineno', 'comment', 'remove',
    'type', 'name', 'is_var', 'get_values', 'set_values', 'extract');

### properties

ok($attr->{object_type} eq 'attribute',
    "Attribute 'object_type' property");

isa_ok($attr->{parser}, 'Parse::Liberty');

isa_ok($attr->{parent}, 'Parse::Liberty::Group');

isa_ok($attr->{si2_object}, 'liberty::si2ObjectIdT');

ok($attr->{depth} == 1,
    "Attribute 'depth' property");

### common methods

ok($attr->methods eq "lineno\ncomment\nremove\ntype\nname\nis_var\nget_values\nset_values\nextract\n",
    "Attribute methods");

ok($attr->lineno == 10,
    "Attribute lineno");

ok($attr->comment eq '0',
    "Attribute comment");

### methods

ok($attr->type eq 'simple', # strange, but this still works after $attr->remove
    "Attribute type");

ok($attr->name eq 'nom_temperature', # but this not
    "Attribute name");

## simple

ok($attr->is_var == 0,
    "Simple attribute is not a variable declaration");

@vals = $attr->get_values;
ok($#vals == 0 && $vals[0]->type eq 'integer' && $vals[0]->value == 25,
    "Simple attribute get all values");

$val = $attr->get_values;
ok($val->type eq 'integer' && $val->value == 25,
    "Simple attribute get first value");

ok($attr->set_values('boolean', 0, 'string', "abc", 'float', 1.23) == 1,    # boolean value must be set as integer >=0
    "Simple attribute set new values (always first value only)");

@vals = $attr->get_values;
ok($#vals == 0                                          # but 'get' on boolean value give 'false' or 'true' as in .lib
    && $vals[0]->type eq 'boolean' && $vals[0]->value eq 'false',
    "Simple attribute get new value");

ok($attr->extract eq "/*0*/\n".' 'x$indent."nom_temperature : false ;\n",
    "Simple attribute extract");

## complex

$attr = $library->get_attributes('capacitive_load_unit');   # get complex attribute

ok($attr->is_var == 0,
    "Complex attribute cannot be a variable declaration");

@vals = $attr->get_values;
ok($#vals == 1
    && $vals[0]->type eq 'integer' && $vals[0]->value == 1
    && $vals[1]->type eq 'string' && $vals[1]->value eq "pf",
    "Complex attribute get all values");

$val = $attr->get_values;
ok($val->type eq 'integer' && $val->value == 1,
    "Complex attribute get first value");

ok($attr->set_values('boolean', 0, 'string', "abc", 'float', 1.23) == 1,
    "Complex attribute set new values");

@vals = $attr->get_values;
ok($#vals == 2
    && $vals[0]->type eq 'boolean' && $vals[0]->value eq 'false'
    && $vals[1]->type eq 'string' && $vals[1]->value eq "abc"
    && $vals[2]->type eq 'float' && $vals[2]->value == 1.23,
    "Complex attribute get new values");

ok($attr->extract eq ' 'x$indent."capacitive_load_unit (false, abc, 1.23) ;\n",
    "Complex attribute extract");

## variable declaration

$attr = $library->get_attributes('FANOUT');

ok($attr->is_var == 1,
    "Simple variable attribute is variable declaration");

@vals = $attr->get_values;
ok($#vals == 0
    && $vals[0]->type eq 'integer' && $vals[0]->value == 5,
    "Simple variable attribute get all values");

$val = $attr->get_values;
ok($val->type eq 'integer' && $val->value == 5,
    "Simple variable attribute get first value");

ok($attr->set_values('boolean', 0, 'string', "abc", 'float', 1.23) == 1,
    "Simple variable attribute set new values (always first value only)");

@vals = $attr->get_values;
ok($#vals == 0
    && $vals[0]->type eq 'boolean' && $vals[0]->value eq 'false',
    "Simple variable attribute get new value");

ok($attr->extract eq ' 'x$indent."FANOUT = false ;\n",
    "Simple variable attribute extract");


ok($attr->remove == 1 && !defined $library->get_attributes('FANOUT'),
    "Attribute remove");


#### Define.pm tests ###########################################################

$def = $library->get_defines('sec_acore_rise_power');

isa_ok($def, 'Parse::Liberty::Define');

can_ok($def, 'new', 'methods', 'lineno', 'comment', 'remove',
    'type', 'name', 'allowed_group_name', 'extract');

### properties

ok($def->{object_type} eq 'define',
    "Define 'object_type' property");

isa_ok($def->{parser}, 'Parse::Liberty');

isa_ok($def->{parent}, 'Parse::Liberty::Group');

isa_ok($def->{si2_object}, 'liberty::si2ObjectIdT');

ok($def->{depth} == 1,
    "Define 'depth' property");

### common methods

ok($def->methods eq "lineno\ncomment\nremove\ntype\nname\nallowed_group_name\nextract\n",
    "Define methods");

ok($def->lineno == 15,
    "Define lineno");

ok(!defined $def->comment,
    "Define comment");

### methods

ok($def->type eq 'float',
    "Define type");

ok($def->name eq 'sec_acore_rise_power',
    "Define name");

ok($def->allowed_group_name eq 'sec_acore_internal_power',
    "Define allowed group name");

ok($def->extract eq ' 'x$indent."define (sec_acore_rise_power, sec_acore_internal_power, float) ;\n",
    "Define extract");

ok($def->remove == 1 && !defined $library->get_defines('sec_acore_rise_power'),
    "Define remove");


#### Value.pm tests ############################################################

$attr = $library->get_attributes('default_max_transition');   # first, get simple attribute

$val = $attr->get_values;

isa_ok($val, 'Parse::Liberty::Value');

can_ok($val, 'new', 'methods', 'type', 'value');

### properties

ok($val->{object_type} eq 'value',
    "Value 'object_type' property");

isa_ok($val->{parser}, 'Parse::Liberty');

isa_ok($val->{parent}, 'Parse::Liberty::Attribute');

### simple attribute value properties

ok(!defined $val->{si2_object},
    "Simple attribute value 'si2_object' property (always undefined)");

### simple attribute value methods

ok($val->type eq 'float',
    "Simple attribute value type");

ok($val->value == 2.4,
    "Simple attribute value value");

### complex attribute value properties

$attr = $library->get_attributes('technology'); # get complex attribute

$val = $attr->get_values;

isa_ok($val->{si2_object}, '_p_si2drAttrComplexValIdT');

## complex attribute value methods

ok($val->type eq 'string',
    "Complex attribute value type");

ok($val->value eq "cmos",
    "Complex attribute value value");

### common methods

ok($val->methods eq "type\nvalue\n",
    "Value methods");


#### Group extract, remove and liberty extract #################################

my $cell = $library->get_groups('cell', 'cell2');

ok($cell->extract eq "/* cell */\n".' 'x$indent."cell (cell2) {\n".' 'x 2 x$indent."area : 777.88 ;\n".' 'x$indent."}\n",
    "Group extract");

ok($cell->remove == 1,
    "Group remove");

ok($library->extract eq join('', <DATA>),
    "Extract full library ");



__DATA__
library (testlib) {
    technology (cmos) ;
/* 0 */
    delay_model : table_lookup ;
    time_unit : 1ns ;
    voltage_unit : 1V ;
    current_unit : 1uA ;
/*0*/
    nom_temperature : false ;
    capacitive_load_unit (false, abc, 1.23) ;

    define_group (sec_acore_internal_power, pin) ;
    define (sec_acore_fall_power, sec_acore_internal_power, float) ;
    define (sec_acore_when, sec_acore_internal_power, string) ;

/* declaration */
    default_max_transition : 2.4 ;

    lu_table_template (dti_delay_drivex1_5x7) {
        variable_1 : input_net_transition ;
        variable_2 : total_output_net_capacitance ;
        index_1 ("0.0020, 0.0100, 0.0300, 0.0650, 0.1400") ;
        index_2 ("0.0003, 0.0030, 0.0100, 0.0300, 0.0950, 0.1700, 0.3000") ;
    }

    cell (cell1) {
        area : 456 ;

        ff (NET0108_5, NET078_4) {
            next_state : "((SE SI) + (!SE D))" ;
            clocked_on : "CK" ;
            clear : "(!RN)" ;
        }

        statetable ("CLK E SE", enl) {
            table : "H L L : - : L ,\
         H L H : - : H ,\
         H H L : - : H ,\
         H H H : - : H ,\
         L - - : - : N " ;
        }

        pin (TST) {
            direction : input ;
            capacitance : 0.1 ;

            sec_acore_internal_power (TST) {
                sec_acore_rise_power : 1000 ;
                sec_acore_fall_power : 0 ;
                sec_acore_when : "CNT' " ;
            }

            sec_acore_internal_power (TST) {
                sec_acore_rise_power : 1000 ;
                sec_acore_fall_power : 0 ;
                sec_acore_when : "CNT  " ;
            }
        }

        pin (TST2) {
            direction : inout ;
            capacitance : 0.2 ;

            sec_acore_internal_power (TST) {
                sec_acore_rise_power : 1000 ;
                sec_acore_fall_power : 0 ;
                sec_acore_when : "CNT' " ;
            }

            sec_acore_internal_power (TST1) {
                sec_acore_rise_power : 1000 ;
                sec_acore_fall_power : 0 ;
                sec_acore_when : CNT ;
            }
        }

        pin (TST3) {
            direction : output ;
            function : "TST" ;
            capacitance : 0.3 ;
            max_fanout : FANOUT * 2 ;

/* usage, here max_fanout : 10 */
            sec_acore_internal_power (TST) {
                sec_acore_rise_power : 1000 ;
            }

            timing () {
                related_pin : TST ;
                timing_sense : positive_unate ;

                cell_rise (dti_delay_drivex1_5x7) {
                    values ( \
                        "0.0111, 0.0164, 0.0277, 0.0587, 0.1607, 0.2785, 0.4858", \
                        "0.0131, 0.0185, 0.0297, 0.0608, 0.1627, 0.2813, 0.4814", \
                        "0.0163, 0.0219, 0.0330, 0.0641, 0.1663, 0.2839, 0.4950", \
                        "0.0196, 0.0255, 0.0371, 0.0683, 0.1701, 0.2885, 0.4904", \
                        "0.0351, 0.0458, 0.0652, 0.1059, 0.2140, 0.3333, 0.5357"  \
                    ) ;
                }

                rise_transition (dti_delay_drivex1_5x7) {
                    values ( \
                        "1.0111, 1.0164, 1.0277, 1.0587, 1.1607, 1.2785, 1.4858", \
                        "1.0131, 1.0185, 1.0297, 1.0608, 1.1627, 1.2813, 1.4814", \
                        "1.0163, 1.0219, 1.0330, 1.0641, 1.1663, 1.2839, 1.4950", \
                        "1.0196, 1.0255, 1.0371, 1.0683, 1.1701, 1.2885, 1.4904", \
                        "1.0351, 1.0458, 1.0652, 1.1059, 1.2140, 1.3333, 1.5357"  \
                    ) ;
                }
            }
        }
    }

    cell (cell3) {
        define (cell3_define, sec_acore_internal_power, string) ;
    }

    cell (cell4) {

        pin (A) {
        }
    }

    cell (cell5) {
    }
}
