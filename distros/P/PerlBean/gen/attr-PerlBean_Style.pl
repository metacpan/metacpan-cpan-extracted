use strict;

push(@::bean_desc, {
    bean_opt => {
        abstract => 'PerlBean code style information',
        package => 'PerlBean::Style',
        use_perl_version => 5.005,
        singleton => 1,
        description => <<EOF,
C<PerlBean::Style> class for code generation style
EOF
        short_description => 'contains PerlBean code style information',
    },
    attr_opt => [
        {
            method_factory_name => 'indent',
            type => 'SINGLE',
            allow_rx => [qw(.*)],
            default_value => '    ',
            short_description => 'the string used for ONE indentation',
        },
        {
            method_factory_name => 'str_pre_block_open_curl',
            type => 'SINGLE',
            allow_rx => [qw(.*)],
            default_value => ' ',
            short_description => 'the string printed before the opening curly of a multi-line BLOCK. Any string C<__IND_BLOCK__> in the value is replaced with the correct block indentation',
        },
        {
            method_factory_name => 'str_post_block_close_curl',
            type => 'SINGLE',
            allow_rx => [qw(.*)],
            default_value => "\n__IND_BLOCK__",
            short_description => 'the string printed after the closing curly of a multi-line BLOCK. Any string C<__IND_BLOCK__> in the value is replaced with the correct block indentation',
        },
        {
            method_factory_name => 'str_around_operators',
            type => 'SINGLE',
            allow_rx => [qw(.*)],
            default_value => ' ',
            short_description => 'the string around most operators',
        },
        {
            method_factory_name => 'str_around_complex_subscripts',
            type => 'SINGLE',
            allow_rx => [qw(.*)],
            default_value => ' ',
            short_description => 'the string around "complex" subscripts(inside brackets)',
        },
        {
            method_factory_name => 'str_between_conditional_and_parenthesis',
            type => 'SINGLE',
            allow_rx => [qw(.*)],
            default_value => ' ',
            short_description => 'the string between conditionals (C<for>, C<if>, C<while>...) and parenthesis',
        },
        {
            method_factory_name => 'str_between_function_and_parenthesis',
            type => 'SINGLE',
            allow_rx => [qw(.*)],
            default_value => '',
            short_description => 'the string between function name and its opening parenthesis',
        },
        {
            method_factory_name => 'str_after_comma',
            type => 'SINGLE',
            allow_rx => [qw(.*)],
            default_value => ' ',
            short_description => 'the string after each comma',
        },
        {
            method_factory_name => 'method_factory_name_to_method_base_filter',
            type => 'SINGLE',
            allow_ref => [qw(CODE)],
		default_value => '\&default_method_factory_name_to_method_base_filter',
            short_description => 'the subroutine that converts an attribute name to the method base',
        },
        {
            method_factory_name => 'method_operation_filter',
            type => 'SINGLE',
            allow_ref => [qw(CODE)],
		default_value => '\&default_method_operation_filter',
            short_description => 'the subroutine that formats the method operation',
        },
    ],
    meth_opt => [
        {
            method_name => 'default_method_factory_name_to_method_base_filter',
            parameter_description => 'ATTRIBUTE',
            description => <<EOF,
Class method. Default attribute name to method filter. C<ATTRIBUTE> is the attribute name. This method adds a C<_> character to C<ATTRIBUTE> and returns it.
EOF
            body => <<EOF,
    return( '_' . shift );
EOF
        },
        {
            method_name => 'default_method_operation_filter',
            parameter_description => 'OPERATION',
            description => <<EOF,
Class method. Default method operation filter. C<OPERATION> is the operation name. This method plainly returns the C<OPERATION>.
EOF
            body => <<EOF,
    return(shift);
EOF
        },
#        {
#            method_name => 'instance',
#            parameter_description => '[OPT_HASH_REF]',
#            description => <<EOF,
#Always returns the same C<PerlBean::Style> -singleton- object instance. The first time it is called, parameter C<OPT_HASH_REF> -if specified- is passed to the constructor.
#EOF
#            body => <<EOF,
## If \$SINGLETON is defined return it
#defined(\$SINGLETON) && return(\$SINGLETON);
#
#\$SINGLETON = PerlBean::Style->new();
#\$SINGLETON->_initialize(\@_);
#return(\$SINGLETON);
#EOF
#        },
    ],
    sym_opt => [
        {
            symbol_name => '$AC',
            export_tag => [ qw( codegen ) ],
            description => <<EOF,
The value which would be obtained through the singleton object's C<get_str_after_comma()> method.
EOF
            comment => <<EOF,
# Shortcut for singleton's get_str_after_comma()
EOF
        },
        {
            symbol_name => '$ACS',
            export_tag => [ qw( codegen ) ],
            description => <<EOF,
The value which would be obtained through the singleton object's C<get_str_around_complex_subscripts()> method.
EOF
            comment => <<EOF,
# Shortcut for singleton's get_str_around_complex_subscripts()
EOF
        },
        {
            symbol_name => '$AN2MBF',
            export_tag => [ qw( codegen ) ],
            description => <<EOF,
The value which would be obtained through the singleton object's C<get_method_factory_name_to_method_base_filter()> method.
EOF
            comment => <<EOF,
# Shortcut for singleton's get_method_factory_name_to_method_base_filter()
EOF
        },
        {
            symbol_name => '$AO',
            export_tag => [ qw( codegen ) ],
            description => <<EOF,
The value which would be obtained through the singleton object's C<get_str_around_operators()> method.
EOF
            comment => <<EOF,
# Shortcut for singleton's get_str_around_operators()
EOF
        },
        {
            symbol_name => '$BCP',
            export_tag => [ qw( codegen ) ],
            description => <<EOF,
The value which would be obtained through the singleton object's C<get_str_between_conditional_and_parenthesis()> method.
EOF
            comment => <<EOF,
# Shortcut for singleton's get_str_between_conditional_and_parenthesis()
EOF
        },
        {
            symbol_name => '$BFP',
            export_tag => [ qw( codegen ) ],
            description => <<EOF,
The value which would be obtained through the singleton object's C<get_str_between_function_and_parenthesis()> method.
EOF
            comment => <<EOF,
# Shortcut for singleton's get_str_between_function_and_parenthesis()
EOF
        },
        {
            symbol_name => '$IND',
            export_tag => [ qw( codegen ) ],
            description => <<EOF,
The value which would be obtained through the singleton object's C<get_indent()> method.
EOF
            comment => <<EOF,
# Shortcut for singleton's get_indent()
EOF
        },
        {
            symbol_name => '$MOF',
            export_tag => [ qw( codegen ) ],
            description => <<EOF,
The value which would be obtained through the singleton object's C<get_method_operation_filter()> method.
EOF
            comment => <<EOF,
# Shortcut for singleton's get_method_operation_filter()
EOF
        },
        {
            symbol_name => '@PBCC',
            export_tag => [ qw( codegen ) ],
            description => <<EOF,
The values which would be obtained through the singleton object's C<get_str_post_block_close_curl()> method and the replacement of C<__IND_BLOCK__> with the correct indentation. The ARRAY's index is the level of indentation. C<10>(!) levels of indentation are available.
EOF
            comment => <<EOF,
# Shortcut for singleton's get_str_post_block_close_curl()
EOF
        },
        {
            symbol_name => '@PBOC',
            export_tag => [ qw( codegen ) ],
            description => <<EOF,
The values which would be obtained through the singleton object's C<get_str_pre_block_open_curl()> method and the replacement of C<__IND_BLOCK__> with the correct indentation. The ARRAY's index is the level of indentation. C<10>(!) levels of indentation are available.
EOF
            comment => <<EOF,
# Shortcut for singleton's get_str_pre_block_open_curl()
EOF
        },
    ],
    tag_opt => [
        {
            export_tag_name => 'codegen',
            description => <<EOF,
This tag contains variables useful for the actual code generation. You should not need to use this tag.
EOF
        },
    ],
} );

1;
