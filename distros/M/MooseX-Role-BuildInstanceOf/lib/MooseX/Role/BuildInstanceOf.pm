package MooseX::Role::BuildInstanceOf;
BEGIN {
  $MooseX::Role::BuildInstanceOf::AUTHORITY = 'cpan:FLORA';
}
{
  $MooseX::Role::BuildInstanceOf::VERSION = '0.08';
}
# ABSTRACT: Less Boilerplate when you need lots of Instances
{
    use MooseX::Role::Parameterized 0.13;
    use 5.008001;

    use Moose::Util::TypeConstraints;
    my $ClassName = subtype as 'ClassName';
    coerce $ClassName, from 'Str', via { Class::MOP::load_class($_); $_ };

    my $CodeRef = subtype as 'CodeRef';
    coerce $CodeRef, from 'ArrayRef', via { my $args = $_; sub { $args } };
    no Moose::Util::TypeConstraints;

    parameter 'target' => (
        isa  => 'Str',
        is => 'ro',
        required => 1,
    );

    my $decamelize = sub {
        my $s = shift;
        $s =~ s{([^a-zA-Z]?)([A-Z]*)([A-Z])([a-z]?)}{
            my $fc = pos($s)==0;
            my ($p0,$p1,$p2,$p3) = ($1,lc$2,lc$3,$4);
            my $t = $p0 || $fc ? $p0 : '_';
            $t .= $p3 ? $p1 ? "${p1}_$p2$p3" : "$p2$p3" : "$p1$p2";
            $t;
        }ge;
        $s;
    };

    parameter 'prefix' => (
        isa  => 'Str',
        is => 'ro',
        required => 1,
        lazy => 1,
        default => sub {
            my $self = shift @_;
            my $target = $self->target;
            $target = ($target =~m/(::|~)(.+)$/)[1];
            return $decamelize->($target);
        },
    );

    parameter 'constructor' => (
        isa  => 'Str',
        is => 'ro',
        required => 1,
        default => 'new',
    );

    parameter 'args' => (
        isa  => $CodeRef,
        is => 'ro',
        required => 1,
        coerce => 1,
        default => sub { [] },
    );

    parameter 'fixed_args' => (
        isa  => $CodeRef,
        is => 'ro',
        required => 1,
        coerce => 1,
        default => sub { [] },
    );

    parameter 'inherited_args' => (
        isa  => 'ArrayRef',
        is => 'ro',
        required => 1,
        default => sub { [] },
    );

    parameter 'type' => (
        isa => 'Str',
        is => 'ro',
        required => 1,
        default => sub { 'attribute' },
    );

    role {
        my $parameters = shift @_;
        my $prefix = $parameters->prefix;

        has $prefix."_class" => (
            is => 'ro',
            isa => $ClassName,
            lazy_build => 1,
            coerce => 1,
            handles => {
                "create_".$prefix => $parameters->constructor,
            },
        );

        method "normalize_".$prefix."target" => sub {
            my $self = shift @_;
            my $class = ref $self ? ref $self:$self;
            my $target = $parameters->target;

            if($target =~m/^::/) {
                $target = $class.$target;
            } elsif($target =~s/^~//) {
                my $first = ($class =~m/^(.+?)::/)[0];
                $first = $first ? $first : $class;
                $target = $first.'::'.$target;  ## get anything!
            }

            return $target;
        };

        method "_build_". $prefix ."_class" => sub {
            my $normalize_target = "normalize_".$prefix."target";
            return shift->$normalize_target;
        };

        has $prefix."_args" => (
            is => 'ro',
            isa => 'ArrayRef',
            lazy_build => 1,
        );

        method "_build_". $prefix ."_args" => sub {
            return $parameters->args->();
        };

        has $prefix."_fixed_args" => (
            is => 'ro',
            init_arg => undef,
            isa => 'ArrayRef',
            lazy_build => 1,
        );

        method "_build_". $prefix ."_fixed_args" => sub {
            return $parameters->fixed_args->();
        };

        has $prefix."_inherited_args" => (
            is => 'ro',
            init_arg => undef,
            isa => 'ArrayRef',
            lazy_build => 1,
        );

        method "_build_". $prefix ."_inherited_args" => sub {
            my $self = shift;

            my @args = @{ $parameters->inherited_args };

            my %resolved_args;

            for my $arg ( @args ) {
                if ( ! ref $arg ) {
                    $resolved_args{ $arg } = $self->$arg;
                }
                elsif( ref $arg eq 'HASH' ) {
                    while( my ($k,$v) = each %$arg ) {
                        $resolved_args{ $k } = ref $v ? $v->($self) : $self->$v;
                    }
                }
            }

            return [ %resolved_args ];
        };

        ## This needs to be broken out into roles or something
        ## not so lame...

        if($parameters->type eq 'attribute') {
            has $prefix => (
                is => 'ro',
                init_arg => undef,
                lazy_build => 1,
            );
        } elsif($parameters->type eq 'factory') {
            method "$prefix", sub {
                my $self = shift @_;
                my $build = "_build_".$prefix;
                return $self->$build;
            }
        } else {
            die $parameters->type ." is not a recognized type";
        }

        method "_build_". $prefix => sub {
            my $self = shift @_;
            my $create = "create_".$prefix;
            my $merge = "merge_".$prefix."_args";
            my $instance = $self->$create($self->$merge);

            my $normalize_target = "normalize_".$prefix."target";
            my $target_class = $self->$normalize_target;

            if($instance->isa($target_class)) {
                return $instance;
            } else {
                die ref($instance)."is not a $target_class.";
            }
        };

        method "merge_".$prefix ."_args" => sub {
            my $self = shift @_;
            my $fixed_args = $prefix."_fixed_args";
            my $inherited_args = $prefix."_inherited_args";
            my $args = $prefix."_args";
            return (
                @{ $self->$inherited_args },
                @{$self->$fixed_args},
                @{$self->$args},
            );
        };
    }
} 1;


1;



=pod

=encoding utf-8

=head1 NAME

MooseX::Role::BuildInstanceOf - Less Boilerplate when you need lots of Instances

=head1 SYNOPSIS

Here is the "canonical" form of this role's parameters:

    package MyApp::Album;
    use Moose;

    with 'MooseX::Role::BuildInstanceOf' => {
        target => 'MyApp::Album::Photo',
        prefix => 'photo',
        constructor => 'new',
        args => [],
        fixed_args => [],
    };

Given this, your "MyApp::Album" will now have an attribute called 'photo', which
is an instance of "MyApp::Album::Photo". Other methods and attributes are also
created.

    my $album = MyApp::Album->new;
    my $photo = $album->photo; ## $photo ISA MyApp::Album::Photo

Not all parameters are required.  We attempt sane defaults, for example the above
could also be written as:

    package MyApp::Album;
    use Moose;

    with 'MooseX::Role::BuildInstanceOf' => {target => '::Photo'};

And could be constructed and used as in the preceeding example.

Using this role is basically shorthand to create attributes and method.  Think
of it like a template.  Given the above parameters, this role calls a 'template'
and builds the following code into your class:

    package MyApp::Album;
    use Moose;

    has photo_class => (
        is => 'ro',
        # this type automatically coerces any string by trying to load it as a class
        isa => $anonymous_type,
        coerce => 1,
        required => 1,
        default => 'MyApp::Album::Photo',
        lazy => 1,
        handles => {
            create_photo => 'new',
        },
    );

    has photo_args => (
        is => 'ro',
        isa => 'ArrayRef',
        lazy_build => 1,
    );

    sub _build_photo_args {
        return [];
    };

    has photo_fixed_args => (
        is => 'ro',
        init_arg => undef,
        isa => 'ArrayRef',
        lazy_build => 1,
    );

    sub _build_args_fixed_args {
        return []; ## Populated from 'fixed_args' parameter
    };

    has photo => (
        is => 'ro',
        isa => 'Object',
        init_arg => undef,
        lazy_build => 1,
    );

    sub _build_photo {
        my $self = shift @_;
        my $create = 'create_photo';
        $self->$create($self->merge_album_args);
    }

    sub merge_photo_args {
        my $self = shift @_;
        my $fixed_args = "photo_fixed_args";
        my $args = "photo_args";
        return (
            @{$self->$fixed_args},
            @{$self->$args},
        );
    };

The above example removed a few extraneous bits, we were getting a little long
for a SYNOPSIS.

This role can be called multiple times, either against other target classes, or
even the same class (although using a different prefix.  You can also modify the
generated methods or attributes in the normal L<Moose> way.  See </COOKBOOK>
for examples.

You can now instantiate your class with the following (assuming your MyApp::Photos
class defines a 'source_dir' attribute.)

    my $album = MyApp::Album->new(photo_args=>[source_dir=>'~/photos']);

The overall goal here being to allow you to defer choice of class and arguments
to when the class is actually used, thus achieving maximum flexibility.  We can
do with with a minimum of Boilerplate code, thus encouraging rather than punishing
well separated and clean design.

Please review the test example and case in '/t' for more assistance.

=head1 DESCRIPTION

There can often be a tension between coding for flexibility and for future growth
and writing code that is terse, to the point, and solves the smallest possible
business problem that is brought to you.  Writing the minimum code to solve a
particular problem has merit, yet can eventually leave you with an application
that has many hacky modifications and is hard to test in an isolated manner.
Minimum code should not imply minimum forward planning or poorly tested code.

For me, doing the right thing means I need to both limit myself to the smallest
possible solution for a given business case, yet make sure I am not writing CODE
that is impossible to grow over time in a clean manner.  Generally I attempt to
do this by clearly separating the problem domains under a business case into
distinct classes.  I then tie all the functional bits together in the loosest
manner possible.  L<Moose> makes this easy, with its powerful attribute features,
type coercions and Roles to augment classical inheritance.

Loose coupling and deep configurability work well with inversion of control
systems, like L<Bread::Board> or the IOC built into the L<Catalyst> MVC
framework.  It helps me to defer decisions to the proper authority and also
makes it easier to test my logic, since pieces are easier to test independently.

Although this leaves me with the design I desire, I find there's a lot of
repeated boilerplate code and logic, particularly in my main application class
which often will marshall several underlying classes, each of which is
performing a particular job.  For example:

    package MyApp::WebPage;

    use Moose;
    use Path::Class qw(file);
    use MyApp::Web::Text;

    has text => (is=>'ro', required=>1, lazy_build=>1);

    sub _build_text {
        file("~/text_for_webpage")->slurp;
    }

NOTE: For clarity I removed some of the extra type constraint checking and type
coercions I'd normally have here.  Please see the test cases in '/t' for a working
example.

This retrieves the text for a single webpage.  But what happens when you want
to reuse the same class to load webpage data from different directories?

    package MyApp::WebPage;

    use Moose;
    use Path::Class qw(file);
    use MyApp::Web::Text;

    has root => (is=>'ro', required=>1);
    has text => (is=>'ro', required=>1, lazy_build=>1);

    sub _build_text {
        my ($self) = @_;
        file($self->root)->slurp;
    }

(Again, I removed the normal type checking and sanity/security checks in order
to keep things to the point).

Well, now I start to think that the job of slurping up text really belongs to
another dedicated class, since WebPage is about methods on web media, and is
not concerned at all with storage or storage mediums.  Delegating the job of
retrieval to a different class also has the big upsides of making it easier to
test each class in turn and gives me more reuseable code.  It also makes each
class smaller in terms of code line weight, and that promotes understanding.

    package MyApp::WebPage;

    use Moose;
    use MyApp::Storage
    use MyApp::Web::Text;

    has root => (is=>'ro', required=>1);
    has storage => (is=>'ro', required=>1, lazy_build=>1);
    has text => (is=>'ro', required=>1, lazy_build=>1);

    sub _build_storage {
        MyApp::Storage->new(root=>$self->root);
    }

    sub _build_text {
        my ($self) = @_;
        $self->storage->get_text;
    }

Then what happens when you start to realize Storage needs additional args, or
you need to be able to read from a subversion repository or a database?  Now
you need more control over which Storage class is loaded, and more flexibility
in what args are passed.  You also find out that you are going to need subclasses
of 'MyApp::Web::Text', since some text is going to be HTML and others in Wiki
format.  You may end up with something like:

    package MyApp::WebPage;

    use Moose;

    has storage_class => (
        is => 'ro',
        # this type automatically coerces any string by trying to load it as a class
        isa => $anonymous_type,
        coerce => 1,
        required => 1,
        default => 'MyApp::Storage',
        handles => { create_storage => 'new' },
    );

    has storage_args => (
        is => 'ro',
        isa => 'ArrayRef',
        required => 1,
    );

    has storage => (is=>'ro', required=>1, lazy_build=>1);

    sub _build_storage {
        my ($self) = @_;
        $self->create_storage(@{$self->storage_args});
    }


    has text_class => (
        is => 'ro',
        # this type automatically coerces any string by trying to load it as a class
        isa => $anonymous_type,
        coerce => 1,
        required => 1,
        default => 'MyApp::Text',
        handles => { create_text => 'new' },
    );

    has text_args => (
        is => 'ro',
        isa => 'ArrayRef',
        required => 1,
    );

    has text => (is=>'ro', required=>1, lazy_build=>1);

    sub _build_text {
        my ($self) = @_;
        $self->create_text(@{$self->text_args});
    }

Which would allow a very flexibile instantiation:

    my $app = MyApp->new(
        storage_class=>'MyApp::Storage::WebStorage',
        storage_args=>[host_website=>'http://mystorage.com/']
        text_class=>'MyApp::WikiText,
        text_args=>[wiki_links=>1]
    );

But is pretty verbose.  And if you wanted to add enough useful hooks so that
your subclassers can modify the whole process as needed, then you are going to
end up with even more repeated code.

With L<MooseX::Role::BuildInstanceOf> you could simple do instead:

    package MyApp::WebPage;
    use Moose;
    with 'MooseX::Role::BuildInstanceOf' => {target=>'~Storage'};
    with 'MooseX::Role::BuildInstanceOf' => {target=>'~Text'};

So basically you are free to concentrate on building your classes and let this
role do the heavy lifting of providing a sane system to tie it all together and
maintain flexibility to your subclassers.

=head1 NAME

MooseX::Role::BuildInstanceOf - Less Boilerplate when you need lots of Instances

=head1 PARAMETERS

This role defines the following parameters:

=head2 target

'target' is the only required parameter since it defines the target class that
you wish to have aggregated into your class.  This should be a real package
name in the form of a string, although if you prepend a "::" to the value we
will assume the target class is under the current classes namespace.  For
example:

    package MyApp::Album;
    use Moose;

    with 'MooseX::Role::BuildInstanceOf' => {
        target => '::Page',
    };

Would be the same as:

    package MyApp::Album;
    use Moose;

    with 'MooseX::Role::BuildInstanceOf' => {
        target => 'MyApp::Album::Page',
    };

Given a valid target, we will infer prefix and other required bits.  If for
some reason the default values result in a namespace conflict, you can resolve
the conflict by specifying a value.

You can also prepend a "~" to your 'target' class, in which case we will
assume the classes root namespace is the '~' or 'home' namespace.  For example:

    package MyApp::Album;
    use Moose;

    with 'MooseX::Role::BuildInstanceOf' => {
        target => '~Folder,
    };

Would be the same as:

    package MyApp::Album;
    use Moose;

    with 'MooseX::Role::BuildInstanceOf' => {
        target => 'MyApp::Folder',
    };

In this case we assume that 'MyApp' is the root home namespace.

Please note that when you specify a 'target' you are setting a default type.
You are free to change the target when you instantiate the object, however if
you choose an object that is not of the same type as what you specified in
target, this will result in a runtime error.  For example:

    package MyApp::Album;
    use Moose;

    with 'MooseX::Role::BuildInstanceOf' => {
        target => 'MyApp::Folder',
    };

You could do (assuming 'MyApp::Folder::Music' is a subclass of MyApp::Folder)

    my $album = MyApp::Album->new(folder_class=>'MyApp::Folder::Music');

However this would generate an error:

    my $album = MyApp::Album->new(folder_class=>'MyApp::NotAFolderAtAll);

=head2 prefix

'prefix' is an optional parameter that defines the unique string prepended to
each of the generated attributes and methods.  By default we take the last
part of the namespace passed in 'target' and process it through L<String::CamelCase>
to decamelize the path, however if this will result in namespace collision,
you can set something unique manually.

Example:

    package MyApp::Album;
    use Moose;

    with 'MooseX::Role::BuildInstanceOf' => {
        target => 'MyApp::Folder',
    };

    with 'MooseX::Role::BuildInstanceOf' => {
        target => 'MyApp::Secured::Folder', prefix=> 'secured_folder'
    };

=head2 constructor

This defaults to new.  Change this string to point to the actual name of the
constructor you wish, such as in the case where you've created your own custom
constructors or you are using something like L<MooseX::Traits>

    package MyApp::Album;
    use Moose;

    with 'MooseX::Role::BuildInstanceOf' => {
        target => 'MyApp::ClassWithTraits', constructor => 'new_with_traits',
    };

=head2 args

Although the goal of this role is to offer a lot of flexibility via configuration
it also makes sense to set rational defaults, as to help people along for the most
common cases.  Setting 'args' will create a default set of arguments passed to the
target class when we go to create it.  If the person using the class chooses to
set args, then those will override the defaults.

    package MyApp::Album;
    use Moose;

    with 'MooseX::Role::BuildInstanceOf' => {
        target => 'MyApp::Image', args => [source_dir=>'~/Pictures']
    };

    my $personal_album = MyApp::Album->new;
    $personal_album->list_images; ## List images from '~/Pictures/'

    my $shared_album = MyApp::Album->new(image_args=>[source_dir=>'/shared']);
    $shared_album->list_images; ## List images from '/shared'

=head2 fixed_args

Similar to 'args', however this args are 'fixed' and will always be sent to the
target class at creation time.

    package MyApp::Album;
    use Moose;

    with 'MooseX::Role::BuildInstanceOf' => {
        target => 'MyApp::Image',
        args => [source_dir=>'~/Pictures'],
        fixed_args => [show_types=>[qw/jpg gif png/]],
    };

In this case you could change the source_dir but not the 'show_types' at
instantiation time.  If your subclasses really need to do this, they would
need to override some of the generated methods.  See the next section for
more information.

=head2 inherited_args 

Additional args copied from the current class and passed to the target class 
at instantiation time. Individual args can be passed as strings (which is
assumed to be the argument name, both the current and target classes),
or as a hash ref. In the latter case, the hash's keys are the name of the 
attribute in the target class, and the value can either be a string (name
of the attribute in the main class) or a coderef (which will be evaluated
with the master object to determine the argument value).  

    package MyApp::Album;
    use Moose;

    has root_dir  => ( is => 'ro' );
    has is_public => ( is => 'ro' );

    with 'MooseX::Role::BuildInstanceOf' => {
        target => 'MyApp::Image',
        inherited_args => [ 
            'root_dir', 
            { world_visible => 'is_public' },
            { parent_album => sub { shift @_ } },
        }
    };

In this example, the creation of the image target object
would be quivalent to

    $image = MyApp::Image->new(
        root_dir      => $album->root_dir,
        world_visible => $album->is_public,
        parent_album  => $album,
    );

=head2 type

By default we create an attribute that holds an instance of the 'target'.
However, in some cases you would prefer to get a fresh instance for each
call to {$prefix}.  For example, you may have a set of items that are
loaded from a directory, where the directory can be updated.  In which case
you can set the type to 'factory' and instead of an attribute, we will
generate a method.

Default value is 'attribute'.

=head1 CODE GENERATION

This role creates a number of attributes and methods in your class.  All
generated items are under the 'prefix' you set, so you should be able to
avoid namespace collision.  The following section reviews the generated
attribute and methods, and has a brief discussion about how or when you may
wish to modified them in subclasses, or to create particular effects.

=head2 GENERATED ATTRIBUTES

This role generates the following attributes into your class.

=head3 {$prefix}_class

This holds a ClassName, which is a normalized and loaded version of the
string specified in the 'target' parameter by default.  You can put a
different class here, but if it's not the same class as specified in the
'target' you must ensure that is is a subclass, otherwise you will get a
runtime error.

=head3 {$prefix}_args

This will contain whatever you specified in 'args' as a default.  The person
instantiating the class can override them, but you can use this to specify some
sane defaults.

=head3 {$prefix}_fixed_args

Additional args passed to the target class at instantiation time, which cannot
be overidden by the person instantiating the class.  Your subclassers, however
can, if they are willing to go to trouble (see section below under GENERATED
METHODS for more.)

=head3 {$prefix}_inherited_args

Additional args copied from the current class and passed to the target class 
at instantiation time. 

=head2 {$prefix}

Contains an instance of the target class (the class name found in {$prefix}_class.)
You can easily add delegates here, for example:

    package MyApp::Album;
    use Moose;

    with 'MooseX::Role::BuildInstanceOf' => {
        target => 'MyApp::Image', args => [source_dir=>'~/Pictures']
    };

    '+image' => (handles => [qw/get_image delete_image/]);

Please note this is the default behavior (what you get if you set the parameter
'type' to 'attribute' or merely leave it default.  Please see below for what gets
generated when the 'type' is 'factory'.

=head2 GENERATED METHODS

This role generates the following methods into your class.

=head3 normalize_{$prefix}_target

This examines the string you passed in the target parameter and attempts to
normalize it (deal with the :: and ~ shortcuts mentioned above).  There's
not likely to be user serviceable bit here, unless you are trying to add you
own shortcut types.

=head3 _build_{$prefix}_class

If you don't set a {$prefix}_class we will use the parameter 'target' as the
default.

=head3 _build_{$prefix}_args

Sets the default args for your class.  Subclasses may wish to modify this if
they want to set different defaults.

=head3 _build_{$prefix}_fixed_args

as above but for the fixed_args.

=head3 _build_{$prefix}_inherited_args

as above but for the inherited_args.

=head3 _build_{$prefix}

You may wish to modify this if you want more control over how your classes are
instantiated.

=head3 merge_{$prefix}_args

This controls the process of merging args and fixed_args.  This is a good spot
to modify if you need more control over exactly how the args are presented.  For
example, you may wish to supply arguments whos values are from other attributes
in th class.

    package MyApp::Album;
    use Moose;

    with 'MooseX::Role::BuildInstanceOf' => {
        target => 'MyApp::Folder',
    };

    with 'MooseX::Role::BuildInstanceOf' => {
        target => 'MyApp::Image',
    };

    around 'merge_folder_args' => sub {
        my ($orig, $self) = @_;
        my @args = $self->$orig;
        return (
            image => $self->image,
            @args,
        );
    };

In the above case the Folder needed an Image as part of its instantiation.

=head2 {$prefix}

Returns an instance of the {$prefix}_class using the whatever is in the arguments.
Since this is a method you will get a new instance each time.

You will need to set the 'type' parameter to 'factory'.

    with 'MooseX::Role::BuildInstanceOf' => {
        target=>'~Set',
        type=>'factory',
    };

=head1 COOKBOOK

The following are example usage for this Role.

=head2 Combine with L<MooseX::Traits>

L<MooseX::Traits> allows you to apply roles to a class at instantiation time.
It does this by adding an additional constructor called 'new_with_traits.'.  I
Find using this role adds an additional level of flexibility which gives the
user of my class even more power.  If you want to make sure the 'traits'
argument is properly passed to your L<MooseX::Traits> based classes, you need to
specify the alternative constructor:

    package MyApp::WebPage;
    use Moose;

    with 'MooseX::Role::BuildInstanceOf' => {
        target=>'~Storage',
    };

    with 'MooseX::Role::BuildInstanceOf' => {
        target=>'~Text',
        constructor=>'new_with_traits',
    };

Then you can use the 'traits' argument, it will get passed corrected:

    my $app = MyApp->new(
        storage_class=>'MyApp::Storage::WebStorage',
        storage_args=>[host_website=>'http://mystorage.com/']
        text_class=>'MyApp::WikiText,
        text_args=>[traits=>[qw/BasicTheme WikiLinks AllowImages/]]
    );

=head2 You have a bunch of target classes

If you have a bunch of classes to target and you like all the defaults, you
can just loop:

    package MyApp::WebPage;
    use Moose;

    foreach my $target(qw/::Storage ::Text ::Image ::Album/) {
        with 'MooseX::Role::BuildInstanceOf' => {target=>$target};
    }

Which would save you even more boilerplate / repeated code.

=head2 You want additional type constraints on the generated attributes.

Sometimes you may wish to ensure that the generated attribute conforms to a 
particular interface.  You can use stand Moose syntax to add or override any
generated method.

    package MyApp::Album;
    use Moose;

    with 'MooseX::Role::BuildInstanceOf' => {target => '::Photo'};
    '+photo' => (does=>'MyApp::Role::Photo');

The above would ensure that whatever instance is created, it conforms to a 
particular Role.

=head1 DISCUSSION

Generally speaking, I believe this role is best suited for usage in a sort of 
'middle' complexity level.  That is, when the app has become somewhat complex
but not yet so much as to warrant seeking out an IOC solution, of which 
L<Bread::Board> is an ideal candidate.  However this is not to say that IOC
containers in general and L<Bread::Board> in particular cannot scale downward.
In fact such a system may be useful even for relatively small projects.  My 
recommendation is that if you are finding yourself heavily modifying this role
to get it to work for you, you might find your code clearer if you simple
took on the additional technical understanding and use L<Bread::Board> instead.

=head1 TODO

Currently the instance slot holding the instance attribute (ie, the 'photo' in
the above example) only has an 'Object' type constraint on it.  We hack in a post
instantiation check to make sure the create object isa of the default target type
but it is a bit hacky.  Would be nice if this code validate against a role as well.

Would be great if we could detect if the underlying target is using L<MooseX::Traits>
or one of the other standard MooseX roles that add an alternative constructor and
use that as the default constructor over 'new'.

Since the Role doesn't know anything about the Class, we can't normalize any
incoming {$prefix}_class class names in the same way we do with 'target'.  We
could do this with a second attribute that is used to defer checking until after
the class is loaded, but this adds even more generated attributes so I'm not
convinced its the best way.

Another thing that would be useful is that if the 'target' is a Role, we 'do
the right thing' in regards to setting a useful type constraint and constructor.

=head1 SEE ALSO

The following modules or resources may be of interest.

L<Moose>, L<Moose::Role>, L<MooseX::Role::Parameterized>, L<Bread::Board>

=head1 AUTHOR

John Napiorkowski C<< <jjnapiork@cpan.org> >>
Florian Ragwitz C<< <rafl@debian.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009, John Napiorkowski C<< <jjnapiork@cpan.org> >>

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

=over 4

=item *

John Napiorkowski <jjnapiork@cpan.org>

=item *

Florian Ragwitz <rafl@debian.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by John Napiorkowski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

Maybe call this MX::Helper::Role::BuildInstanceOf ???

