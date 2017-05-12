package Panda::Export;
use 5.012;

our $VERSION = '2.2.5';

=head1 NAME

Panda::Export - Replacement for Exporter.pm + const.pm written in C, also provides C API.

=cut

require Panda::XSLoader;
Panda::XSLoader::load();

=head1 SYNOPSIS

=head2 Exporting functions

    package MyModule;
    use parent 'Panda::Export';
    
    sub mysub { ... }
    sub mysub2 { ... }
    
    1;
    
    package Somewhere;
    use MyModule qw/mysub mysub2/;
    
    mysub();
    
=head2 Creating and using constants (without export)

    package MyModule;
    
    use Panda::Export
        CONST1 => 1,
        CONST2 => 'string';
    
    say CONST1;
    say CONST2;

=head2 Creating and using constants with export

    package MyModule;
    use parent 'Panda::Export';
    
    use Panda::Export {
        CONST1 => 1,
        CONST2 => 'string',
    };
    
    say CONST1;
    say CONST2;
    
    package Somewhere;
    
    use MyModule;
    
    say CONST1;
    say CONST2;
    
=head1 C SYNOPSIS

    #include <xs/export.h>
    using namespace xs::exp;
    
    // one-by-one using C types
    create_constant(stash, "STATUS_OFF",       0);
    create_constant(stash, "STATUS_ACTIVE",    1);
    create_constant(stash, "STATUS_SUSPENDED", 2);
    create_constant(stash, "STATUS_PENDING",   3);
    create_constant(stash, "DEFAULT_NAME", "john");
    
    // one-by-one using SV*
    create_constant(stash, name_sv, value_sv);
    
    // one-by-one using constant_t
    constant_t constant = {"myconstant", 123};
    create_constant(stash, constant);
    
    // bulk is always faster than one-by-one
    // bulk using constant_t
    constant_t constants[] = {
        {"STATUS_OFF",       0},
        {"STATUS_ACTIVE",    1},
        {"STATUS_SUSPENDED", 2},
        {"STATUS_PENDING",   3},
        {"DEFAULT_NAME", 0, "john"},
        {NULL}
    };
    create_constants(stash, constants);
    
    // bulk using SV* array
    SV** constant_names_and_values;
    create_constants(stash, constant_names_and_values);
    
    // bulk using hash
    HV* constants;
    create_constants(stash, constants);
    
    // getting constant names list
    AV* names = constants_list(stash);
    
    // exporting subs
    const char* name = ...;
    export_sub(from_stash, to_stash, name);
    SV* name = ...;
    export_sub(from_stash, to_stash, name);
    
    // bulk
    const char* names[] = {"sub1", "sub2", "sub3"};
    export_subs(from, to, sub_names, 3);
    const char* names[] = {"sub1", "sub2", "sub3", NULL};
    export_subs(from, to, sub_names);
    AV* sub_names = ...;
    export_subs(from, to, sub_names);
    SV** sub_names = ...;
    export_subs(from, to, sub_names, items_count);
    
    // export all constants
    export_constants(from, to);
    // same
    const char* names[] = {":const"};
    export_subs(from, to, names, 1);

=head1 DESCRIPTION

It's very fast not only in runtime but at compile time as well. That means you can create and export/import a
lot of constants/functions without slowing down the startup.

You can create constants by saying

    use Panda::Export {CONST_NAME1 => VALUE1, ...};
    use Panda::Export CONST_NAME1 => VALUE1, ... ;

If you want your class to able to export constants or functions you need to derive from Panda::Export.

Exports specified constants and functions to caller's package.

    use MyModule qw/subs list/;

Exports nothing

    use MyModule();
    

Exports all constants only (no functions)

    use MyModule;

Exports functions sub1 and sub2 and all constants

    use MyModule qw/sub1 sub2 :const/;


If Panda::Export discovers name collision while creating or exporting functions or constants it raises an exception.
If you specify wrong sub or const name in import list an exception will also be raisen.

=head1 C FUNCTIONS

Functions marked with C<[pTHX]> must receive C<aTHX_> as a first arg.

The whole API is thread-safe.

    struct constant_t {
        const char* name;
        int64_t     value;
        const char* svalue;
    };

=head4 void create_constant (HV* stash, SV* name, SV* value) [pTHX]

=head4 void create_constant (HV* stash, const char* name, const char* value) [pTHX]

=head4 void create_constant (HV* stash, const char* name, int64_t value) [pTHX]

Creates constant with name C<name> and value C<value> in package C<stash>.
Croaks if package already has sub/constant with that name.

=head4 void create_constant (HV* stash, constant_t constant) [pTHX]

If constant.svalue is null, creates numeric constant (constant.value), otherwise creates string constant (constant.svalue) 

=head4 void create_constants (HV* stash, HV* constants) [pTHX]

Creates a constant for each key/value pair in hash C<constants>.

=head4 void create_constants (HV* stash, SV** list, size_t items) [pTHX]

Creates a constant for each key/value pair in array C<list>.
It means that list[0] is a key, list[1] is a value, list[2] is a key, etc...
Array should not contain empty slots and empty keys or it will croak.
If elements count is odd, last element is ignored. You must pass the size of C<list> in C<items>.

=head4 void create_constants (HV* stash, constant_t* list, size_t items = MAX_ITEMS) [pTHX]

Creates a constant for each key/value pair in array C<list>.
Stops processing list if discovered an element with element.name == NULL. Therefore you must either pass a valid C<items>, or
end your list with "{NULL}" value.

=head4 void export_sub (HV* from, HV* to, SV* name) [pTHX]

=head4 void export_sub (HV* from, HV* to, const char* name) [pTHX]

Exports sub/constant with name C<name> from package C<from> to package <to>.

=head4 void export_constants (HV* from, HV* to) [pTHX]

Exports all constants from package C<from> to package <to>.

=head4 void export_subs (HV* from, HV* to, AV* list) [pTHX]

Exports contants/subs with names in C<list>.

=head4 void export_subs (HV* from, HV* to, SV** list, size_t items) [pTHX]

Exports contants/subs with names in C<list>. You must pass the size of C<list> in C<items>.

=head4 void export_subs (HV* from, HV* to, const char** list, size_t items = MAX_ITEMS) [pTHX]

Exports contants/subs with names in C<list>. Stops processing list if discovered NULL value in list.
Therefore you must either pass a valid C<items>, or end your list with NULL value.

=head4 AV* constants_list (HV* stash) [pTHX]

Returns the list of all constants defined in package C<stash> as a perl array.

=head3 TIP

If you receive SV* as constant/sub name from user, don't get it's content as const char* to call functions which receive const char*.
The reason is that those SVs are often so-called "shared hash string", i.e. besides a string itself, they contain its precomputed
hash value inside. This may significantly increase perfomance as exporting/creating sub/constants is always a matter of hash lookups.

However, if you only have const char*, don't make SV from it, as it will definitly decrease perfomance.

=head1 PERFOMANCE

Panda::Export is up to 10x faster than const.pm and Exporter.pm at compile-time.
The runtime perfomance is the same as it doesn't depend on this module.

=head1 AUTHOR

Pronin Oleg <syber@cpan.org>, Crazy Panda, CP Decision LTD

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

1;
