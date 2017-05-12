=head1 NAME

Synapse::CLI::Config::Object - base class for your configuration objects


=head1 SYNOPSIS


=head2 Step 1. Write one or more config objects:

    package My::Config::User;
    use base qw /Synapse::CLI::Config::User/;
    use Synapse::CLI::Config;
    use strict;
    use warnings;
    
    # optional code goes here

    1;

    __END__


=head2 Step 2. Write your application CLI accessor:

    #!/usr/bin/perl
    # this is myapp-cli. It should be installed in /usr/local/bin/myapp-cli
    use Synapse::CLI::Config;
    use YAML::XS;
    use warning;
    use strict;
    $Synapse::CLI::Config::BASE_DIR = "/etc/myapp";
    $Synapse::CLI::Config::ALIAS->{type} = 'Synapse::CLI::Config::Type';
    $Synapse::CLI::Config::ALIAS->{user} = 'MyAPP::User';
    print Dump (Synapse::CLI::Config::execute (@ARGV));

=head2 Step 3. Have fun on the CLI

    myapp-cli type user create c-hiver "Clementine Hiver"
    myapp-cli user chiver set password moncontenkite
    myapp-cli user chiver set-add permission watchtv
    myapp-cli user chiver set-add permission playoncomputer
    myapp-cli user chiver set-add permission readbooks
    myapp-cli user chiver show 

=cut
package Synapse::CLI::Config::Object;
use Synapse::CLI::Config;
use Time::HiRes;
use File::Touch;
use File::Copy;
use YAML::XS;
use IO::File;
use strict;
use warnings;


=head1 Class methods

Usage: cli type object-class object-method arg1 ... argN

=head2 $class->create ($name, $label);

Usage: cli type mytype create foo "This is a beautiful Foo"

Creates an object of type $class of name $name. $name will be the object file
name on disk. Allowed names are /^[a-z0-9-_]+$/. If no 'name' is supplied,
$class->create() provides one.

Optionally, sets label to "This is a beautiful Foo", which is shorter than
doing:

    cli type mytype create foo
    cli mytype foo set label "This is a beautiful Foo"

=cut
sub create {
    my $class = shift;
    my $objid = shift;
    
    defined $objid or do {
        my $time = Time::HiRes::time();
        $time =~ s/\./-/g;
        $objid = $time;
    };
    
    $objid =~ /^[a-z0-9-_]+$/i or do {
        Synapse::CLI::Config::debug ("invalid object name $objid");
        return;
    };
    
    my $config_dir = $class->__confdir__();
    -d $config_dir or mkdir $config_dir;
    -d $config_dir or die "$config_dir does not exist and cannot be created";
    File::Touch::touch ( do { my $o = bless { name => $objid }, $class; $o->__filepath__() } );
    
    my $self = $class->new ($objid);
    @_ and do {
        $self->set (label => join ' ', @_);
        return $self->__save__ ('set', 'label', @_);
    };
    return $self;
}


=head2 $class->new($name);

This is one of the few methods which is NOT to be used on the CLI (although you
could since "cli myclass myid show" is logically equivalent to the less
intuitive "cli type myclass new myid").

Builds and returns object of type $class with name $name.

=cut
sub new {
    my $class = shift;
    my $name  = shift;
    my $self  = bless { @_ }, $class;
    $self->{name} = $name;
    return $self->__init__();
}


=head2 $class->list();

Usage: cli type myclass list

Returns a list of object ids for this class.

=cut
sub list {
    my $class = shift;
    my $dir   = $class->__confdir__();
    opendir (DIR, $dir);
    my @files = readdir (DIR);
    closedir (DIR);
    my @res = ();
    for my $f (@files) {
        $f =~ /^\.$/  and next;
        $f =~ /^\..$/ and next;
        -d "$dir/$f"  and next;
        $f =~ s/\.conf$// or next;
        push @res, $f;
    }
    return wantarray ? @res : \@res;
}


=head2 $class->list_l();

Usage: cli type myclass list

Returns a list of object ids for this class, as well as the corresponding
labels, separated with a CSV-style semicolumn.

=cut
sub list_l {
    my $class = shift;
    my @res   = map { "$_; " . $class->new ($_)->label() } $class->list (@_);
    return wantarray ? @res : \@res;
}


=head2 $class->count();

usage: cli type myclass count

counts how many objects of myclass exist.

=cut
sub count {
    my $class = shift;
    my @list  = $class->list();
    return 0 + @list;
}


=head1 Instance methods

Usage: cli object-class object-id object-method arg1 ... argN


=head2 $self->set($attr, $stuff);

Usage: cli mytype myobject set foo "this is bar"

Sets $self->{foo} to "this is bar"

=cut
sub set {
    my $self  = shift;
    my $attr  = shift;
    my $stuff = join ' ', @_;
    $self->{$attr} = $stuff;
    return $self;
}


=head2 $self->del($attr);

Usage: cli mytype myobject del foo

Removes $self->{foo}

=cut
sub del {
    my $self  = shift;
    my $attr  = shift;
    delete $self->{$attr};
    return $self;
}


=head2 $self->list_push($attr, $stuff);

Usage: cli mytype myobject list-push foo "this is bar"

Makes $self->{foo} an empty list if not defined. Adds "this is bar" to the list.

=cut
sub list_push {
    my $self  = shift;
    my $attr  = shift;
    my $stuff = join ' ', @_;
    $self->{$attr} ||= [];
    push @{$self->{$attr}}, $stuff;
    return $self;
}


=head2 $self->list_pop($attr)

Usage: cli mytype myobject list-pop foo

Makes $self->{foo} an empty list if not defined. Then pops the list.

=cut
sub list_pop {
    my $self  = shift;
    my $attr  = shift;
    $self->{$attr} ||= [];
    pop @{$self->{$attr}};
    return $self;
}


=head2 $self->list_shift($attr)

Usage: cli mytype myobject list-shift foo

Makes $self->{foo} an empty list if not defined. Then shifts the list.

=cut
sub list_shift {
    my $self  = shift;
    my $attr  = shift;
    my $stuff = join ' ', @_;
    $self->{$attr} ||= [];
    shift @{$self->{$attr}};
    return $self;
}


=head2 $self->list_unshift($attr, $stuff)

Usage: cli mytype myobject list-unshift foo "this is bar"

Makes $self->{foo} an empty list if not defined. Then unshifts the list with
"this is bar".

=cut
sub list_unshift {
    my $self  = shift;
    my $attr  = shift;
    my $stuff = join ' ', @_;
    $self->{$attr} ||= [];
    unshift @{$self->{$attr}}, $stuff;
    return $self;
}


=head2 $self->list_del($attr, $index)

Usage: cli mytype myobject list-del foo

Removes $self->{$attr}->{$index} from the list.

=cut
sub list_del {
    my $self  = shift;
    my $attr  = shift;
    my $index = shift;
    $self->{$attr} ||= [];
    splice @{$self->{$attr}}, $index, 1;
}


=head2 $self->list_add($attr, $index, $stuff)

Usage: cli mytype myobject list-add foo "this is stuff"

Adds "this is stuff" at position $index in $self->{$attr} list.

=cut
sub list_add {
    my $self  = shift;
    my $attr  = shift;
    my $index = shift;
    my $stuff = join ' ', @_;
    $self->{$attr} ||= [];
    splice @{$self->{$attr}}, $index, 0, $stuff;
}


=head2 $self->set_add($attr, $stuff)

Usage: cli mytype myobject set-add foo "this is stuff"

Treats $self->{$attr} as a set (creating it if needed, using a hash ref), and
adds "this is stuff" to the set.

=cut
sub set_add {
    my $self  = shift;
    my $attr  = shift;
    my $stuff = join ' ', @_;
    $self->{$attr} ||= {};
    $self->{$attr}->{$stuff} = 1;
    return $self;
}


=head2 $self->set_del($attr, $stuff)

Usage: cli mytype myobject set-del foo "this is stuff"

Removes "this is stuff" from the set.

=cut
sub set_del {
    my $self  = shift;
    my $attr  = shift;
    my $stuff = join ' ', @_;
    $self->{$attr} ||= {};
    delete $self->{$attr}->{$stuff};
    return $self;
}


=head2 $self->set_list($attr)

Usage: cli mytype myobject set-list foo

Lists all items in the set.

=cut
sub set_list {
    my $self = shift;
    my $attr = shift;
    $self->{$attr} ||= {};
    return wantarray ? 
        sort keys %{$self->{$attr}} :
        [ sort keys %{$self->{$attr}} ];
}


=head2 $self->label()

Usage: cli mytype myobject label

Each object as an optional label associated with it, this method returns it.
Returns name() is label is not defined.

=cut
sub label {
    my $self = shift;
    return $self->{label} || $self->name();
}


=head2 $self->name()

Usage: cli mytype myobject name

Each object as a name. Returns it.

=cut
sub name {
    my $self = shift;
    return $self->{name} || $self->name();
}


=head2 $self->show();

Usage: cli mytype myobject show

From Perl, this method is not very interesting since it just returns $self. But
on the CLI, will display a YAML representation of $self, which is handy to view
your objects.

=cut
sub show { return shift }


=head2 $self->rename_to ($newname);

Usage: cli mytype foo rename-to bar

Changes the object 'name' attribute as well as file name on disk.

=cut
sub rename_to_FORCE_NOSAVE { 1 }
sub rename_to {
    my $self  = shift;
    my $newid = shift;
    my $path1 = $self->__filepath__();
    my $path2 = $path1;
    my @path2 = split /\//, $path2;
    pop (@path2);
    push @path2, "$newid.conf";
    $path2 = join '/', @path2;
    File::Copy::move ($path1, $path2);
    $self->{name} = $newid;
    return $self;
}


=head2 $self->copy_as ($newname);

Usage: cli mytype foo copy-as bar

Copies the object and names the copy $newname. Returns the newly copied object.

=cut
sub copy_as {
    my $self  = shift;
    my $newid = shift;
    my $path1 = $self->__filepath__();
    my $path2 = $path1;
    my @path2 = split /\//, $path2;
    pop (@path2);
    push @path2, "$newid.conf";
    $path2 = join '/', @path2;
    File::Copy::copy ($path1, $path2);
    my $class = ref $self;
    return $class->new ($newid);
}


=head2 $self->remove();

Usage: cli mytype foo remove

Removes foo.

=cut
sub remove {
    my $self = shift;
    my $new  = shift;
    unlink $self->__filepath__();
}


## PRIVATE METHODS : if you made it this far and want to override them anyways,
## then you probably should


sub __init__ {
    my $self = shift;
    my $path = $self->__filepath__();
    -e $path or return;
     
    my $fh   = IO::File->new();
    if ($fh->open("<$path")) {
        while (my $line = <$fh>) {
            chomp($line);
            my ($timestamp, $method, @arguments) = split /\s+/, $line;
            $self->can ($method) or do {
                Synapse::CLI::Config::debug ("cannot invoke method $method on object $self - ignoring");
            };
            $self->$method (@arguments);
        }
        undef $fh;
    }
    else {
        Synapse::CLI::Config::debug ("cannot instantiate : file is not readable");
        return;
    };
    return $self;
}


sub __confdir__ {
    my $self  = shift;
    my $class = ref $self || $self;
    $class    =~ s/::/-/g;
    return Synapse::CLI::Config::base_dir() . "/$class";
}


sub __filepath__ {
    my $self = shift;
    return $self->__confdir__() . '/' . $self->name() . '.conf';
}


sub __save__ {
    my $self   = shift;
    my $objid  = $self->name();
    my $method = shift;
    my $args   = join ' ', @_;
    my $time   = Time::HiRes::time();
    my $path   = $self->__filepath__();
    open OBJECT, ">>$path" or die "cannot write-open $path";
    print OBJECT "$time $method $args\n";
    close OBJECT;
    return $self;
}


1;


__END__

=head1 EXPORTS

none.


=head1 BUGS

Please report them to me. Patches always welcome...


=head1 AUTHOR

Jean-Michel Hiver, jhiver (at) synapse (dash) telecom (dot) com

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
