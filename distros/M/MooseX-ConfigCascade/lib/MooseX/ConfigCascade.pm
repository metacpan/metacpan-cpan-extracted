package MooseX::ConfigCascade;

our $VERSION = '0.02';

use Moose::Role;
use MooseX::ConfigCascade::Util;

has cascade_util => (is => 'ro', lazy => 1, isa => 'MooseX::ConfigCascade::Util', default => sub{
    MooseX::ConfigCascade::Util->new(
        _to_set => $_[0],
        _role_name => __PACKAGE__
    );
});


sub BUILD{}
after BUILD => sub{
    my ($self,$args) = @_;
    my $util = $self->cascade_util;
    foreach my $k (keys %$args){ $util->_args->{$k} = 1 }
    $util->_parse_atts;
};


1;
__END__
=head1 NAME

MooseX::ConfigCascade - Set initial accessor values of your whole Moose-based project from a single config file

=head1 SYNOPSIS

    # /my_conf.json:

        "My::Bottle": {
            "label": {
                "logo": {
                    "company_name": "Bottle Company Name",
                    "slogan": "Bottle Slogan"
                }
            }
        },

        "My::Label": {
            "logo": {
                "company_name": "Label Company Nmae",
                "slogan": "Label Slogan"
            }
        },


        "My::Logo": {

            "company_name": "Logo Company Name",
            "slogan": "Logo Slogan",
           
        }

    # Packages:

    package Bottle;

    use Moose;
    with 'MooseX::ConfigCascade';  # MooseX::ConfigCascade is a Moose role

    has label => (is => 'rw', isa => 'My::Label', default => sub{
        My::Label->new;
    });
    

    package Label;

    use Moose;
    with 'MooseX::ConfigCascade';

    has logo => (is => 'rw', isa => 'My::Logo', default => sub {
        My::Logo->new;
    });
    

    package Logo;

    use Moose;
    with 'MooseX::ConfigCascade';

    has company_name => (is => 'rw', isa => 'Str', default => 'Default Company Name');
    has slogan => (is => 'ro', isa => 'Str', default => 'Default Slogan');


    # and in your script...


    my $logo = My::Logo->new;
    say $logo->company_name;                    # prints 'Default Company Name' because the path
                                                # to the config has not been set yet

    use MooseX::ConfigCascade::Util;            # use this package to set path to config
    MooseX::ConfigCascade::Util->path( 
        '/my_conf.json' 
    );


    $logo = My::Logo->new;
    say $logo->company_name;                    # Now this prints 'Logo Company Name'

    my $label = My::Label->new;
    say $label->logo->company_name;             # 'Label Company Name'
    say $label->logo->slogan;                   # 'Label Slogan'

    my $bottle = My::Bottle->new;
    say $bottle->label->logo->company_name;     # 'Bottle Company Name'
    say $bottle->label->logo->slogan;           # 'Bottle Slogan'  


=head1 DESCRIPTION

In my opinion getting values from some kind of centralised config to attributes in nested objects is problematic. There are several modules available which load config into accessors, but in one way or another these all involve telling each specific object about the config, and changing the code of each package to accommodate that config.

L<MooseX::ConfigCascade> attempts to solve not only the issue of loading from a centralised config file, but also delivery of config values to objects within objects, nested to arbitrary depth, without the need for any added code within the modules. Specify a config file once (perhaps at the top of your script), and from then on any object you create can enjoy having its attributes loaded directly from the config.

If you don't specify a config file, the object will just initialise with the default values it was going to take otherwise. Nor is there any requirement for how many attributes you choose to put in your config. Load lots of them, or just one. Any that don't get a definition in your config file will load package default values as before.

L<MooseX::ConfigCascade> also allows CSS style cascading of config declarations. In the example in the synopsis, the attributes 'company_name' and 'slogan' (belonging to the My::Logo package) were assigned values 3 times in the configuration file. The most specific definition in the config that matches the object structure wins. So in the example, if My::Logo is initialised on its own, then it will get the value provided in the C<My::Logo> directive in the config file. If the C<My::Logo> object is initialised in the accessor C<logo> in C<My::Label> however, the more specific C<My::Label> definition wins.

This module was born out of frustration with the paradox of trying to make sure config remains centralised while also keeping objects independent of one another. A tempting and easy way to deal with config is simply to pass a reference around to all objects that need it in your project. This works great, but it has the side effect of effectively tying all your objects to a specific heirarchy. 

If you pull out one of your objects to use somewhere else, it's still expecting that same config reference. If you coded with portability in mind originally, then you might have added code to say 'use the config if its available, but use defaults if not'. However there's also the issue that your config data structure still needs to be in the same format - and that format may not be appropriate any more.

L<MooseX::ConfigCascade> addresses this last point because it always expects a file format that matches the package structure of your project.


=head2 CAVEATS

1. It's not quite true that you don't need any additional code in your modules. But you only need

    with 'MooseX::ConfigCascade';

at the top of each module you want to take part. MooseX::ConfigCascade will not traverse into modules which don't adopt this role (as much a safety feature as anything else).

1. MooseX::ConfigCascade will populate C<ro> and C<rw> accessors of types C<HashRef>, C<ArrayRef>, C<Bool> or C<Str>, and any subtypes of these types (including C<Num> and C<Int> which are subtypes of C<Str> in Moose). It won't populate anything else. 

2. The magic is performed at object instantiation only.

3. Any affected attributes defined as C<lazy> will have their laziness thrown out of the window - ie they will get the values in the config straight away whatever. (This should be irrelevant. Attributes are generally C<lazy> when they depend on other attributes, which is not the case if the value comes from the config file)

3. L<MooseX::ConfigCascade> will traverse objects within objects provided they follow the one object per accessor rule. In other words it will not traverse collections of objects, such as C<HashRef[My::Object]> or C<ArrayRef[My::Object]>. (I looked into this, but decided it would be complex and would bloat the module).

4. L<MooseX::ConfigCascade> is compatible with inheritance and roles - ie it can populate objects that are comprised of locally defined attributes and attributes inherited from parent classes, or attributes absorbed from adopted roles. However, it will NOT see or populate class attributes using L<MooseX::ClassAttribute>.

5. Whilst some effort has gone into testing this module, it is presented at an early stage of development and without much real-world testing. It has not been tested at all with most C<MooseX::> extensions and there is the possibility of conflict. If you discover problems please let me know.


=head1 ATTRIBUTE LOADING

=head2 File Format

Off the shelf L<MooseX::ConfigCascade> supports text files containing YAML or JSON. If the file starts with a dash (-) it is assumed to be YAML and will be read in using the L<YAML> CPAN module. If it begins with an opening curly bracket ({) then it is assumed to be JSON and will be read in using the L<JSON> CPAN module. By default, if the file starts any other way an error is returned. (I decided against including XML as standard as it would have required too many options.)

However L<MooseX::ConfigCascade> can potentially support any file format, but you must create and pass in your own parsing subroutine. See the C<parser> method description in L<MooseX::ConfigCascade::Util>.

=head2 Basic Attribute Assignment

The file needs to be organised so that when the parser pulls the data into a hashref, the keys of the hash are the names of packages. When a new object is created, MooseX::ConfigCascade looks for the name of the package being created in the config file. If the package matches, it looks at the value corresponding to the package name key, where again it expects to find a hashref, this time containing ( attribute name, value) pairs. ie the overall config hashref might look something like this:

    {
        'First::Package' => {
            fp_attribute1 => 'fp value1',
            fp_attribute2 => 'fp value2'
        },

        'Second::Package' => {
            sp_attribute1 => 'sp value1',
            sp_attribute2 => 'sp value2'
        }

    }

C<First::Package> might look something like this:

    package First::Package;

    use Moose;
    with 'MooseX::ConfigCascade';

    has fp_attribute1 => (              # this will get assigned
        is => 'rw',                     # 'fp value1' from the config
        isa => 'Str'
    );

    has fp_attribute2 => (              # this will get assigned
        is => 'ro',                     # 'fp value2'
        isa => 'Str',                   # It doesn't matter whether
        default => 'some default',      # it is 'ro' or 'rw', or
        lazy => 1                       # if it is lazy
    );

    has some_other attribute => (       # our package can have other
        is => 'rw',                     # attributes not mentioned in the
        isa => 'Str',                   # config - these will not be
        default => 'another default'    # affected
    ); 


The config structure above will work provided those four attributes are all of type C<Str>. But lets say we change C<First::Package> so C<fp_attribute1> is a C<HashRef>. From now we will assume you understand that packages can have attributes not specified in the config, and leave these out. For simplicity we'll also just focus on the one package. So now C<First::Package> looks something like this:

    package First::Package;

    use Moose;
    with 'MooseX::ConfigCascade';

    has fp_attribute1 => (              # now of type 'HashRef'
        is => 'rw',                     
        isa => 'HashRef'
    );

    has fp_attribute2 => (              
        is => 'ro',                     
        isa => 'Str',                   
        default => 'some default',      
        lazy => 1                       
    );

    # ... other attributes ...


and our config hashref should look something like:

    {
        'First::Package' => {

            fp_attribute1 => {
                hash_key1 => 'hash_value1',
                hash_key2 => 'hash_value2',
                #  ....
            },

            fp_attribute2 => 'value2'
        },

        # ... rest of the config ...

    }

If we had made C<fp_attribute1> an C<ArrayRef> instead, then the config would need to look like:

   {
        'First::Package' => {

            fp_attribute1 => [
                'array_value1',
                'array_value2',
                #  ....
            },

            fp_attribute2 => 'value2'
        },

        # ... rest of the config ...

    }


=head2 Object Traversal

Lets say we have the following 2 packages:

    package Box::Package;

    use Moose;
    with 'MooseX::ConfigCascade';

    has contents => (is => 'ro', isa => 'Contents::Package', default => sub{
        Contents::Package->new;
    });

    has colors => (is => 'rw', isa => 'ArrayRef'); 

    # ... other attributes ...


    package Contents::Package;

    use Moose;
    with 'MooseX::ConfigCascade';

    has stuff => (is => 'ro', isa => 'Str');


So effectively an instance of C<Box::Package> is a compound object containing C<Contents::Package> in the accessor C<contents>. We can populate both C<Box::Package> and C<Contents::Package> using the following config structure:

    {
        'Box::Package' => {

            contents => {
 
                stuff => 'some stuff'

            },

            colors => [ 'red', 'blue', 'green' ]

        }

    }

(So The YAML config file would look like this:

    ---
    "Box::Package":

        contents:
            stuff: some stuff

        colors:
            - red
            - blue
            - green
   

or if you wanted to use JSON:

    {
        "Box::Package": { 

            "contents": {

                "stuff": "some stuff"

            },

            "colors": [

                "red",
                "blue",
                "green"

            ]

        }
    }

). When you create a new C<Box::Package> object, L<MooseX::ConfigCascade> looks for the attribute named C<contents>. It sees that C<contents> contains an object, and traverses into the object. It then attempts to assign the hash 

    {

        stuff => 'some stuff'

    }

to the attributes in the object. In this case it will find the attribute C<stuff> because it is a valid attribute in C<Contents::Package>, and this attribute will get assigned C<some stuff>.

Some things to note:

1. If we had created a new C<Box::Contents> on its own, it would not get assigned C<some stuff> because our config does not have a declaration which looks like:

    'Contents::Package' => {
        stuff => 'some stuff'
    }

(we could, of course, add one...)

2. the C<contents> attribute DOES need to be provided an initial value for this to work, either using C<default> or C<builder>. Obviously it's not possible to traverse an object that doesn't exist - and since the traversal happens at creation time, you need make sure the objects are there from the beginning.

3. If the attribute is specified as C<lazy> it will be pulled out of its lazy state and evaluated

4. You may have noticed that assignment to attributes of type C<HashRef> is done using a hashref, and assignment to attributes in nested objects also uses a hashref. It is true that (in the current release) there is no distinction in the config file between attributes of type C<HashRef> and attributes containing objects. You could swap out your attribute containing an object for an attribute containing a C<HashRef> and you would not get an error. It's up to you to make sure what you are delivering makes sense.

5. Further to point 4, nor does the config file distinguish the type of object contained in the attribute. Change C<Contents::Package> to C<DifferentContents::Package> and the attribute assignment will still work (provided C<DifferentContents::Package> also has a C<stuff> attribute of type C<Str>.)

6. If we had defined an attribute as a collection of objects, either by using C<HashRef[Some::Package]> or C<ArrayRef[Some::Package]> - for example:

    has obj_collection => (is => 'rw, isa => 'HashRef[My::Package]', default => sub{
        {
            object1 => My::Package->new( %obj_1_params )
            object2 => My::Package->new( %obj_2_params )
        }
    });

then there is B<no way> to assign values to the objects in the collection from the config. MooseX::ConfigCascade does NOT provide this functionality.


=head2 Cascading

Suppose we add that declaration mentioned in point 1 above, so our config hashref now looks like:

    {
        'Box::Package' => {

            contents => {
 
                stuff => 'some stuff (from box)'

            },

            colors => [ 'red', 'blue', 'green' ]

        },

        'Contents::Package' => {

            stuff => 'some stuff (from contents)'

        }

    }

but note that I also added C<(from box)> and C<(from contents)> to distinguish where the values are going to get loaded from. 

Now if we create a C<Box::Package> object and examine the C<stuff> attribute inside C<contents> we will find:

    # case 1: 

    my $box = Box::Package->new;
    print $box->contents->stuff;     # prints 'some stuff (from box)'


    # case 2:

    my $contents = Contents::Package->new;
    print $contents->stuff;         # prints 'some stuff (from contents)'

What happens in case 1 is that the C<Contents::Package> object which is created in contents first gets assigned the accessor default value (if it exists). Then it gets overwritten by C<some stuff (from contents)> which comes from the C<Contents::Package> declaration in the config. Then finally it gets overwritten by the more specific value in the C<Box::Package> config declaration - finally ending up as C<some stuff (from box)>.

It remains to be seen how useful this feature will turn out to be. Obviously there is a performance penalty in doing this - so it's probably not a good idea to use it extensively. It should also be used very carefully since having multiple defaults for a particular value is obviously potentially confusing. However, here is an example of how multiple defaults can be used in a way that makes a lot of sense:

    # /my_config.yaml:
    "Pets::BigDog":

        size: 
            height: 50
            weight: 80

    "Pets::SmallDog"

        size:
            height: 10
            weight: 25

    
    package Pets::Dog;

    use Moose;
    with 'MooseX::ConfigCascade';

    has size => (is => 'ro', isa => 'Pets::Size');

    # ...


    package Pets::BigDog;

    use Moose;
    extends 'Pets::Dog';

    # ...


    package Pets::SmallDog;

    use Moose;
    extends 'Pets::Dog';

    # ...


    package Pets::Size;

    use Moose;
    with 'MooseX::ConfigCascade';

    has height => (is => 'ro', isa => 'Int');
    has weight => (is => 'ro', isa => 'Int');


C<Pets::BigDog> and C<Pets::SmallDog> both inherit the C<size> attribute from C<Pets::Dog> - but the attributes in the C<Pets::Size> object contained in the C<size> attribute get assigned different defaults.


=head2 Loading Order

Loading of attributes happens after C<BUILD>. This means if you use C<BUILD> to assign values to attributes, L<MooseX::ConfigCascade> may overwrite those values (depending if there are values for those attributes specified in the config). If you want to be sure of overwriting the config values, then you could do this using

    after 'BUILD' => sub {
        # overwrite the attributes here
    };

(but perhaps you shouldn't be assigning config values to attributes in the first place if you are then going to want to overwrite them?)

You can also make sure objects get individual values by specifying them in the objects constructor in the normal way:

    my $widget = Widget->new( my_accessor => 'this value will win' );



=head1 METHODS

Remember B<not> to C<use MooseX::ConfigCascade>. It's a role, so you should state:

    with 'MooseX::ConfigCascade';

When you do this, a single new attribute is added to your class:

=head2 cascade_util

This is a L<MooseX::ConfigCascade::Util> object, which has 3 utility methods. So once you added the L<MooseX::ConfigCascade> role to your package, you can do:

    my $object = My::Package->new;

    $object->cascade_util->conf;     # access the config hash directly
    $object->cascade_util->path;     # the path to the config file (if any)
    $object->cascade_util->parser;   # the code ref to the subroutine which parses your config file

Note C<conf>, C<path> and C<parser> are all B<class attributes> of L<MooseX::ConfigCascade::Util>. That means it is intended that you generally set them by calling the class directly:

    MooseX::ConfigCascade::Util->path( '/path/to/config.yaml' );

    # etc ...

so you may not ever need to use C<cascade_util> at all. However, you may find it useful that you can access the full config from anywhere in your project:

    $whatever_object->cascade_util->conf;

See the documentation for L<MooseX::ConfigCascade::Util> for information about these methods.


=head1 SEE ALSO

L<MooseX::ConfigCascade::Util>
L<Moose>
L<MooseX::ClassAttribute>

=head1 AUTHOR

Tom Gracey E<lt>tomgracey@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Tom Gracey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
