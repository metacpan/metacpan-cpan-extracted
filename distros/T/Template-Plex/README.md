# NAME

Template::Plex - (P)erl (L)exical and (EX)tendable Templating

# SYNOPSIS

Write a template:

```perl
    __DATA__        
    @{[ 
        init {
            use Time::HiRes qw<time>;
            $title="Mr.";
        }
    ]}
    Dear $title Connery,
    Ordered a $size pizza with $slices slices to share between @$people and
    myself.  That averages @{[$slices/(@$people+1)]} slices each.
```

Use a template:

```perl
    use Template::Plex;

    my $vars={
            size=>"large",
            slices=>8,
            people=>[qw<Kim Sam Harry Sally>]
    };

    my $template= Template::Plex->load(\*DATA, $vars);

    print $template->render;        


    #OUTPUT
    Dear Mr. Connery,
    Ordered a large pizza with 8 slices to share between Kim, Sam, Harry,
    Sally and myself.  That averages 1.6 slices each.     
    
```

Change values and render it again:

```perl
    $vars->{size}="extra large";
    $vars->{slices}=12;

    print $template->render;


    #OUTPUT
    Dear Mr. Connery,
    Ordered a extra large pizza with 12 slices to share between Kim, Sam,
    Harry, Sally and myself.  That averages 2.4 slices each.
```

# DESCRIPTION

`Template::Plex` facilitates the use of perl (not embedded perl) as a template
language. It implements bootstrapping and a system to load, cache,
inherit and render templates with minimal code.

The 'lexical' part of this module refers to the lexical aliasing of input
variables into the template. This reduces the amount of markup required to
reference variables and thus improves the style and readability of a template.

Templates can be extended and reused by way of inclusion, sub templates and
inheritance. The template system itself can be extended by sub classing
`Template::Plex` and implementing customised load routines and other  helper
methods

The short tutorial in this document plus the examples included in the
distribution cover the basics to get you started. Reading through the `load`
API options is also recommended to get a better understanding on how templates
are processed.

# MOTIATION

Many templating systems are available, yet none use perl as the template
language? Perl already has a great text interpolation, so why not use it? 

Lexical aliasing allows the input variables to be accessed directly by name
(i.e. `$name`) instead of as a member of a hash ref
(i.e.`$fields->{name}`) or by delimiting with custom syntax (i.e.
`<%=name%>`)

I like the idea of Jekyll's 'Front Matter', but think its potential is limited
as it can only support variables and not code. With perl's flexible syntax
introducing code is doable.

# TUTORIAL

## Syntax Genesis

We all know how to interpolate variables into a string in perl:

```perl
    "This string $uses a $some{variables}"
```

But how can we easily interpolate a statement, function or method call? We can
use the `@{[]}` construct. 

```
    "This is a perl string interpolating @{[ map uc, qw<a b c d>]}"
```

If we need more statements, we can combine with a `do` statement. Like always
the last statement executed in a `do` block is returned ( and interpolated
into the string):

```perl
    "This is a perl string interpolating 
    @{[ do {
            my $result="STATEMENTS";
            ...
            lc $result;
        }
    ]}
    "
```

Combining the above examples, we make a `Template::Plex` template simply by
removing the outer quoting operators:

```perl
    This string $uses a $some{variables}

    This is a perl string interpolating @{[ map uc, qw<a b c d>]}

    This is a perl string interpolating 
    @{[ do {
            my $result="STATEMENTS";
            lc $result;
            }
    ]}
```

A `Template::Plex` template is just perl! The above is the literal text you
can save to a file and load as a template.

Specifically, a `Template::Plex` template it is the subset of perl that's
valid between double quotation operators. 

## Smart Meta Data and Code

Templates can include an `init{}` block at the beginning which is executed
(only once) during the setup stage of the template.  In some ways this is
similar to Jekyll 'Front Matter', but more powerful. You can manipulate input
variables, define helper subroutines, or import modules:

```perl
    @{[ init {
            use Time::HiRes qw<time>;

            sub my_func{ 1+2 };

        }
    ]}

    Calculated @{[my_func]} at @{[time]}
```

The `init` block does not inject any content into a template, but manipulates
the state of a template.

Each template has access to it's self, using the `$self` variable. This comes
in very handy when loading sub templates and doing more advanced task or even
extending the template system.

So far we have seen the `do` and `init` directives. General code can also be
executed with a `pl` block. This does the same as `do` but does not inject
the result into the template.

## Loading and Rendering

There are a few ways of executing a template from your application. Each of
them are accessible via class methods:

```perl
    #Load a template and render later
    my $template=Template::Plex->load($path, $vars, %options);              
    my $result=$template->render;

    #Load a template from cache and render later
    my $template=Template::Plex->cache(undef, $path, $vars, %options);
    my $result=$template->render;

    #Load from cache and render now
    my $result= Template::Plex->immediate(undef, $path,$vars,%options);     
```

A `load` call returns a new template object each time, where a `cache` call
returns a template already loaded (or loads it once), for a user defined key.
The returned template is then rendered by calling the `render` method.

The `immediate` call loads and caches a template with a user define key and
then immediately renders it, returning the results.

An important option when loading templates is the **root** option. This is the
directory (relative to the working directory) which is prepended to all paths.
This makes it easy for templates to refer to other templates with relative
paths, regardless of the working directory.

## Template Reuse

Reusing templates can reduce the repetitive nature of content.
`Template::Plex` provides multiple facilities for template reuse.

### Sub Templates

A sub template is just another template. While you can load a sub template with
the class methods shown previously, it's not recommended. This is because you
would need to specify all the variables and options again manually.

You normally would like to pass on the same variables and options to sub
templates, so a better way is to call the same method on the `$self` object:

```perl
    @{[$self->load(...)]}
    @{[$self->cache(...)]}
    @{[$self->immediate(...)]}
```

This will automatically link the variables and relevant option to be the same
as the current template.

Better still, these methods are made available within a template simply as a
subroutine call:

```
    @{[load ... ]}
    @{[cache ... ]}
    @{[immediate ...]}
```

### Slots and Inheritance

A sub template can be used at any location within a template. However there are
special locations called slots. These are defined with the `slot` directive:

```perl
    @{[slot slot1=>"some text"]}

    @{[slot slot_abc=> cache "sub template"]}

    @{[slot]}
```

The slot name can be any string and the value can either be text or a template
object.  This value is the default value, which is used when no child template
wants to fill the slot. 

A slot named 'default' (or no name) is special and is the location at which a
child template body will be rendered. 

A child template can also fill other slots in the parent by explicitly using
the `fill_slot` directive. The value can be text or a loaded template

```perl
    @{[fill_slot name=>"override content"]}
    @{[fill_slot another=>load "path to template"]}
```

Child can setup inheritance by using the `inherit` directive within a
`init` block, specifying the template to use as the parent:

```perl
    @{[ init {
            inherit "my_parent.plex";
            }
    ]}
```

The following is an example showing a child template inheriting from a parent.
The child will provide content to the default slot in the parent and also
override the 'header' slot with another template which it loads:

Parent Template:

```perl
    @{[slot header=>"==HEADER=="]}
    More parent content...
    @{[slot]}
    @{[slot footer=>"==FOOTER=="]}
```

Sub template (header):

```
    -=-=-=Fancy header=-=-=-
```

Child template:

```perl
    @{[ init {
            
            inherit "parent.plex";
        }
    ]}

    @{[slot header=> load "header.plex";
    This content will render into default slot
```

### Inclusion

Much like the C language preprocessor, including an other template or other file
will do a literal copy of its contents into the calling template.  The resulting
text is processed again and again as long as more include statements are
present:

```
    @{[include("...")]}
```

This basically makes a single large template. As such the included templates
will use the same aliased variables.

In simple use cases, it is similar to loading a sub template. However it lacks
the flexibility of sub templates.

## Logging and Error Handling

As templates are executed, they may throw an exception. If a syntax error or
file can not be red, an exception is also thrown during load.

In the case of a syntax error, `die` is called with a summary of template,
prefixed with line numbers which caused the error. Currently 5 line before and
after the error are included for context. Deliberately breaking the synopsis
example gives the following error output:

```perl
    "use" not allowed in expression at (GLOB(0x7f9423a22368)) line 4, within string
    syntax error at (GLOB(0x7f9423a22368)) line 4, near "deliberate_ERROR
            use Time::HiRes "
    Type of arg 1 to init must be block or sub {} (not reference constructor) at (GLOB(0x7f9423a22368)) line 7, near "}
    ]"
    Execution of (GLOB(0x7f9423a22368)) aborted due to compilation errors.
    1  {@{[
    2      init {
    3      deliberate_ERROR
    4       use Time::HiRes qw<time>;
    5       $title="Mr.";
    6      }
    7  ]}
    8  Dear $title Connery,
    9  Ordered a $size pizza with $slices slices to share between @$people and
    10  myself.  That averages @{[$slices/(@$people+1)]} slices each.}
```

It is recommended to use a try/catch block to process the errors.

Currently [Log::ger](https://metacpan.org/pod/Log%3A%3Ager) combined with `Log::OK` is utilised for logging and
debugging purposes. This comes in very handy when developing sub classes.

## Filters

Unlike other template system, there are no built in filters. However as
`Template::Plex` templates are just perl you are free to use builtin string
routines or import other modules in to your template.

# API

## `load`

```perl
    #Class method. Used by top level applciation
    Template::Plex->load($path, $vars, %opts);

    #Object method. Used within a template
    @{[$self->load($path, $vars, %opts);    

    #Subroutine. Prefered within a template. 
    @{[load $path, $vars, %opts]}                   

    #Reuse existing $vars and %opts from withing a template
    @{[load $path]}
    
    
```

A factory method, returning a new instance of a template, loaded from a scalar,
file path or an existing file handle. 

From a top level user application, the class method must be used. From within a
template, either the object method form or subroutine form can be used.

If now variables or options are specified when loading a sub templates, the
variables and options from the calling templates are reused.

Arguments to this function:

- `$path`

    This is a required argument.

    If `$path` is a string, it is treated as a file path to a template file. The
    file is opened and slurped with the content being used as the template.

    If `$path` is a filehandle, or GLOB ref, it is slurped with the content being
    used as the template. Can be used to read template stored in `__DATA__` for
    example

    If `$path` is an array ref, the items of the array are joined into a string,
    which is used directly as the template.

- `$vars`

    This is an optional argument but if present must be an empty hash ref `{}` or
    `undef`.

    The top level items of the `$vars` hash are aliased into the
    template using the key name (key names must be valid for a variable name for
    this to operate). This allows an element such as `$fields{name`}> to be
    directly accessible as `$name` in the template and sub templates.

    External modification of the items in `$vars` will be visible in the
    template. This is thee primary mechanism change inputs for subsequent renders
    of the template.

    In addition, the `$vars` itself is aliased to `%fields` variable
    (note the %) and directly usable in the template like a normal hash e.g.
    `$fields{name}`

    If the `$vars` is an empty hash ref `{}` or `undef` then no
    variables will be lexically aliased. The only variables accessible to the
    template will be via the `render` method call.

- `%options`

    These are non required arguments, but must be key value pairs when used.

    Options are stored lexically for access in the template in the variable
    `%options`. This variable is automatically used as the options argument in
    recursive calls to `load` or `plx`, if no options are provided.

    Currently supported options are:

    - **root**

        `root` is a directory path, which if present, is prepended to to the `$path`
        parameter if `$path` is a string (file path).

    - **no\_include**

        Disables the uses of the preprocessor include feature. The template text will
        not be scanned  and will prevent the `include` feature from operating.
        See `include` for more details

        This doesn't impact recursive calls to `load` when dynamically/conditionally
        loading templates.

    - `no_init_fix`

        Disables correcting missing init blocks.

        If not specified or false, a template file is scanned for a `@{[init{..}]}`
        directive. If one is found, the template is not modified. Otherwise, a 'null'
        block is added at the beginning of the template.

        The added block is not effected by the enabling/disabling of block fix
        mechanism.

    - **no\_block\_fix**

        Disables removing of EOL after a `@{[]}`

        ```
            eg      
                    
                    Line 1
                    @{[
                            ""
                    ]}              <-- this NL removed by default
                    Line 3  
            
        ```

        In the above example, the default behaviour is to remove the newline after the
        closing `]}`. The rendered output would be:

        ```
                    Line1
                    Line3
        ```

        If block fix was disabled (i.e. `no_block_fix` was true) the output would be:

        ```
                    Line1

                    Line3
        ```

    - **no\_eof\_chomp**

        When this key is present and value is true, the last newline in the template
        file is left in place.

        Most text editors insert a extra newline as the last character in a file.  By
        default a chomp is performed before the template is prepared to avoid extra
        newlines in the output when using sub templates. 

        If you really need that newline you can specify the `no_eof_chomp => 1`
        key or place an extra empty line at the end of your template.

    - **package**

        Specifies a package to run the template in. Any `our` variables defined in
        the template will be in this package.  If a package is not specified, a unique
        package name is created to prevent name collisions

    - **base**

        Specifies the base class type of the template. If not specified, templates are
        of type `Template::Plex`. Sub classes must inherit from this class.

        Sub classes should force always specify this field.

    - **no\_alias**

        Top level elements in a $vars hash are aliased into the template by default.

        If this key is present and true, aliasing is disabled and all variables need to
        be accessed via the `%fields`.

    - **use**

        An array ref of packages names (as strings) to use within a template's package.
        Intended to be utilised by subclasses to add features to a template.

    - **inject**

        An array ref of strings, representing perl code, to be injected into the
        template package. Intended to be utilised for subclasses to  inject small
        pieces of code which cannot be otherwise required/used.

- Return value

    The return value is `Template::Plex` (or subclass) object which can be
    rendered using the `render` method.

- Example Usage
		my $hash={
			name=>"bob",
			age=>98
		};

    ```perl
                my $template_dir="/path/to/dir";

                my $obj=Template::Plex->load("template.plex", $hash, root=>$template_dir);
                $obj->render;
    =back
    ```

## `cache`

```perl
    #Class method
    Template::Plex->cache($key, $path, $vars, %options);

    #Object method
    $self->cache($key, $path, $vars, %options);

    #Subroutine
    cache $key, $path, $vars, %options;

    #Use the current line/package/template as a key

    cache undef, $path, $vars, $%opts;
```

This is a wrapper around the `load` API, to improve performance of sub
templates used in loops. The first argument is a key to identity the template
when loaded.  Subsequent calls with the same key will return the already loaded
template from active cache.

If called from the top level user application, the cache is shared.
Templates have their own cache storage to prevent cross collisions.

If no key is provided, then information about the caller (including the line
number, package and target template) is used generate one. This approach allows
for a template which maybe rendered multiple times in a loop, to only be loaded
once for example.

## `immediate`

```perl
    #Class method
    Template::Plex->immediate($key, $path, $vars, %options);
    
    #Object method
    $self->immediate($key, $path, $vars, %options);

    #Subrutine
    immediate $key, $path, $vars, %options;

    #Use current line/package/template as key
    immediate undef, $path, $vars, %options;
```

Loads and renders a template immediately. Uses the same arguments as `cache`.
Calls the `cache` API but also calls `render` on the returned template.

Returns the result or the rendered template.

## `include`

```
    @{[include("path")}]
```

This is a special directive that replaces the directive with the literal
contents of the file pointed to by path in a similar style to #include in the C
preprocessor. This is a preprocessing step which happens before the template is
prepared for execution. 

If `root` was included in the options to `load`, then it is prepended to
`path` if defined.

When a template is loaded by `load` the processing of this is
subject to the `no_include` option. If `no_include` is specified, any
template text that contains the `@{[include("path")}]` text will result in a
syntax error

## pl

## block

```
    @{[ block { ... } ]}

            # or 

    @{[ pl { ... }  ]}
```

A subroutine which executes a block just like the built in  `do`. However it
always returns an empty string.

Only usable in a template `@{[]}` construct, to execute arbitrary statements.
However, as an empty string is returned, perl's interpolation won't inject
anything at that point in the template.

If you DO want the last statement returned into the template, use the built in
`do`.

```perl
    eg
            
            @{[
                    # This will assign a variable for use later in the template
                    # but WILL NOT inject the value 1 into template when rendered
                    pl {
                            $i=1;
                    }

            ]}


            @{[
                    # This will assign a variable for use later in the tamplate
                    # AND immediately inject '1' into the template when rendered
                    do {
                            $i=1
                    }

            ]}
```

## init

```
    @{[ init {...} ]}
```

It is used to configure or setup meta data for a template and return
immediately. It takes a single argument which is a perl block.

Only the first `init {...}` block in a template will be executed.

A `init {...}` block is executed once, even when the template is rendered
multiple times

Before the block is run, the `pre_init` method is called.
After the block is run, the `post_init` method is called.

After the initialisation stages have run, a initialisation flag is set and the
remainder on the template is skipped with the `skip` method.

This means only the first `init` block in a template will be executed

## pre\_init

Do not call this directly. It is called internally by an init block.
Implemented as an empty method designed to be overridden in a subclass.

## post\_init

Do not call this directly. It is called internally by an init block.
Implemented as an empty method designed to be overridden in a subclass.

## inherit

```
    @{[ init {
            inherit "Path to template";
            }
    ]}
```

Specifies the template which will is the current template's parent. The
current template will be rendered into the default slot of the parent.

## slot

```perl
    @{[slot name=>$value]}
```

Declares a slot in a template which can be filled by a child template calling
`fill_slot` directives.

`name` is the name of the slot to render into the template. If not specified,
the slot is the default slot which will be rendered by the content of a child
template.

`$value` is optional and is the default content to render in the case a child
does not provide data for the slot. It can be a scalar value or a template
loaded by `load` or `cache`

## fill\_slot

```perl
    @{[fill_slot name=>$value]}
```

Fills an inherited slot of name `name` with `$value`. 

The default slot cannot be specified. It is filled with the rendered result of
the child template.

## clear

```
    clear;
```

**Subject to change**.  Clears the cached templates

## jmap

```
    jmap {block} $delimiter, @array
```

Performs a join using `$delimiter` between each item in the `@array` after
they are processed through `block`

Very handy for rendering lists:

```perl
    eg
            <ul>
                    @{[jmap {"<li>$_</li>"} "\n", @items]}
            </ul>
```

Note the lack of comma after the block.

## `skip`

Causes the template to immediately finish, with an empty string as result.
From within a template, either the class method or template directive can be used:

```perl
    @{[$self->skip]}
    @{[skip]}
```

## `meta`

Returns the options hash used to load the template.  From within a template, it
is recommended to use the `%options` hash instead:

```perl
    @{[$self->meta->{file}]}
            or
    @{[$options{file}]}
```

This can also be used outside  template text to inspect a templates meta information

```
    $template->meta;
```

## `args`

Returns the argument hash used to load the template.  From within a template,
it is recommended to use the aliased variables or the `%fields` hash instead:

```perl
    @{[$self->args->{my_arg}]}
            or
    @{[$fields{my_arg}]}

            or
    $my_arg
```

This can also be used outside template text to inspect a templates input variables

```
    $template->args;
```

## parent

```perl
    $self->parent;
```

Returns the parent template.

## render

```
    $template->render($fields);
```

This object method renders a template object created by `load` into
a string. It takes an optional argument `$fields` which is a reference to a
hash containing field variables. `fields` is aliased into the template as
`%fields` which is directly accessible in the template

```perl
    eg
            my $more_data={
                    name=>"John",
            };

            my $string=$template->render($more_data);
            
            #Template:
            My name is $fields{John}
```

Note that the lexically aliased variables setup in `load` are independent to
the `%fields` variable and can both be used simultaneously in a template

# SUB CLASSING

Sub classing is as per the standard perl `use parent`. The object storage is
actually an array.  

Package constants are defined for the indexes of the fields along with
`KEY_OFFSET` and `KEY_COUNT` to aid in adding extra fields in sub classes.

If you intend on adding additional fields in your class you will need to do the
following as the object

```perl
    use parent "Template::Plex";

    use constant KEY_OFFSET=>Template::Plex::KEY_OFFSET+ Template::Plex::KEY_COUNT;

    use enum ("first_field_=".KEYOFFSET, ..., last_field_);
    use constant  KEY_COUNT=>last_field_ - first_field_ +1;
```

Any further sub classing will need to repeat this using using your package name.

# FEATURE CHEAT SHEET

- Templates can contain a initialisation state

    ```
        @{[
                init {
                        # Nomral perl code here will only execute once
                        # when templates is loaded
                }
        ]}
    ```

- Templates can cache at caller location

    ```
        Sub/template is loaded only the first time in this map/loop

        @{[map {immediate undef, "path_to_template",{}} qw< a b c d e >]}
        
        And rendereds serveral times
                
    ```

- Lexical and package variables accessed/created within templates

    ```
        @{[
                init {
                        $input_var//=1; #set default
                }

        }]
        
        Value is $input_var;
    ```

- Call and create subroutines within templates:

    ```perl
        @{[
                init {
                        sub my_great_calc {
                                my $input=shift;
                                $input*2/5;
                        }
                }

        }]

        Result of calculation: @{[my_great_calc(12)]}
    ```

- 'Include' Templates within templates easily:

    ```
        @{[include("path_to_file")]}
    ```

- Recursive sub template loading

    ```perl
        @{[load "path_to_sub_template"]}
    ```

- Conditional rendering

    ```
        @{[ $flag and $var]}

        @{[ $flag?$var:""]}
        
        @{[
                pl {
                        if($flag){
                                #do stuff       
                        }
                }
        ]}
    ```

- Lists/Loops/maps

    ```perl
        template interpolates @$lists directly
        
        Items that are ok:
         @{[
                do {
                        #Standard for loop
                        my $output;
                        for(@$items){
                                $output.=$_."\n" if /ok/;
                        }
                        $output;
                }
        }]

        More ok items:
        @{[map {/ok/?"$_\n":()} @$items]}

        
    ```

- `use` other modules directly in templates:

    ```perl
        @{[
                init {  
                        use Time::HiRes qw<time>
                }
        ]}

        Time of day right now: @{[time]}
    ```

# TIPS ON USAGE

## Potential Pitfalls

- Remeber to set `$"` locally to your requied seperator

    The default is a space, however when generating HTML lists for example,
    a would make it easier to read:

    ```
        #Before executing template
        local $"="\n";

        load ...
    ```

    Or alternatively use `jmap` to explicitly set the interpolation separator each time

- Aliasing is a two way steet

    Changes made to aliased variables external to the template are available inside
    the template (one of the main tenets of this module)

    Changes make to aliased variables internal to the template are available outside
    the template.

- Unbalanced Delimiter Pairs

    Perl double quote operators are smart and work on balanced pairs of delimiters.
    This allows for the delimiters to appear in the text body without error.

    However if your template doesn't have balanced pairs (i.e. a missing "}" in
    javascript/c/perl/etc), the template will fail to compile and give a strange
    error.

    If you know you don't have balanced delimiters, then you can escape them with a
    backslash

    Currently [Template::Plex](https://metacpan.org/pod/Template%3A%3APlex) delimiter pair used is **{ }**.  It isn't changeable in
    this version.

- Are you sure it's one statement?

    If you are having trouble with `@{[...]}`, remember the result of the last
    statement is returned into the template.

    Example of single statements

    ```perl
        @{[time]}                       #Calling a sub and injecting result
        @{[$a,$b,$c,time,my_sub]}       #injecting list
        @{[our $temp=1]}                #create a variable and inject 
        @{[our ($a,$b,$c)=(7,8,9)]}     #declaring a
    ```

    If you are declaring a package variable, you might not want its value injected
    into the template at that point.  So instead you could use `block{..}`  or
    `pl{..}` to execute multiple statements and not inject the last statement:

    ```
        @{[ pl {our $temp=1;} }];
    ```

## More on Input Variables

If the variables to apply to the template completely change (note: variables
not values), then the aliasing setup during a `load` call will not
reflect what you want.

However the `render` method call allows a hash ref containing values to be
used.  The hash is aliased to the `%fields` variable in the template.

```perl
    my $new_variables={name=>data};
    $template->render($new_variables);
```

However to use this data the template must be constructed to access the fields
directly:

```perl
    my $template='my name is $fields{name} and I am $fields{age}';
```

Note that the `%field` is aliased so any changes to it is reflected outside
the template

Interestingly the template can refer to the lexical aliases and the direct
fields at the same time. The lexical aliases only refer to the data provided at
preparation time, while the `%fields` refer to the latest data provided during
a `render` call:

```perl
    my $template='my name is $fields{name} and I am $age

    my $base_data={name=>"jimbo", age=>10};

    my $override_data={name=>"Eva"};

    my $template=load $template, $base_data;

    my $string=$template->render($override_data);
    #string will be "my name is Eva and I am 10
```

As an example, this could be used to 'template a template' with global, slow
changing variables stored as the aliased variables, and the fast changing, per
render data being supplied as needed.

# ISSUES 

Templates are completely processed in memory. A template can execute sub
templates and run general IO code, so in theory it would be possible to break
up very large data templates and stream them to disk...

This module uses `eval` to generate the code for rendering. This means that
your template, being perl code, is being executed. If you do not know what is
in your templates, then maybe this module isn't for you.

Aliasing means that the template has write access to variables outside of it.
So again if you don't know what your templates are doing, then maybe this
module isn't for you

# TODO

Extending the template system has been mentioned but not elaborated on.
Probably need to make an other tutorial document.

# SEE ALSO

Yet another template module right? 

Do a search on CPAN for 'template' and make a cup of coffee.

# REPOSITORY and BUG REPORTING

Please report any bugs and feature requests on the repo page:
[GitHub](http://github.com/drclaw1394/perl-template-plex)

# AUTHOR

Ruben Westerberg, <drclaw@mac.com>

# COPYRIGHT AND LICENSE

Copyright (C) 2022 by Ruben Westerberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, or under the MIT license
