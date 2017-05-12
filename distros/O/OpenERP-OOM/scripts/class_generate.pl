#!/usr/bin/env perl

# note this is a very rough script.
# you need to hand tweak the results afterwards.
# it has no safety built in and certain assumptions
# that may prove to be fatal.

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use File::Slurp;
use OpenERP::XMLRPC::Client;
use Getopt::Std;

my %opts;
getopts('h:p:m:c:d:u:l:', \%opts);
my $host = $opts{h};
my $db = $opts{d};
my $model = $opts{m};
my $user = $opts{u};
my $pass = $opts{p};
my $classname = $opts{c};
my $lib = $opts{l};

unless($db && $model && $classname)
{
    print "Usage $0 [-h host] -d db [-u user] [-p password] -m model.name -c ClassName -l My::Library\n";
    exit(1);
}

my $connection_details = { dbname => $db };
$connection_details->username => $user if $user;
$connection_details->password => $pass if $pass;
$connection_details->host => $host if $host;

my $client = OpenERP::XMLRPC::Client->new( $connection_details );
my $class_info = $client->model_fields($model);

my @class_methods;
my @properties;
my @relationships;
for my $field (sort keys %$class_info)
{
    my $info = $class_info->{$field};
    my $type = $info->{type};
    my $relation = $info->{relation};
    my $selection = $info->{selection}; # spit out as debug
    my $description = $info->{string};
    my $type = $info->{type};
    my $help = $info->{help};
    my $required = $info->{required} ? "(required) " : "";
    $help = "$required$description" . ($help =~ /\S/ ? "\n$help" : "");

    if($relation)
    {
        my $relation_name = $field;
        $relation_name =~ s/_id$//;
        my $pod = << "POD";
 =head2 $relation_name

 $help

 =cut
POD
        $pod =~ s/^ //mg;
        my $relation = << "EOR";
$pod
relationship '$relation_name' => (
    key   => '$field',
    type  => '$type',
    class => '$info->{relation}',
); # $required$description
EOR
        push @relationships, $relation;
    }
    else
    {
        my $perl_type = convert_type($type);
        # make the type optional.
        $perl_type = "Maybe[$perl_type]" unless $required;
        my $pod = << "POD";
 =head2 $field

 $help

 =cut
POD
        $pod =~ s/^ //mg;
        push @properties, "$pod\nhas $field => (is => 'rw', isa => '$perl_type'); # $required$description";
        if($selection) {
            push @properties, '    # possible values are,';
            for my $x (@$selection)
            {
                my ($p, $val) = @$x;
                push @properties, "    #      [ '$p', '$val' ]";
            }
            push @properties, '';
            # FIXME: setup a method for getting this info from openerp.
            my $select_method = << "METHOD";
sub get_${field}_options {
    return shift->get_options('$field');
}
METHOD
            push @class_methods, $select_method;
        }
    }
}
if($class_info->{active})
{
    my $active_methods = << 'EOM';

around 'search' => sub {
    my ($orig, $self, @args) = @_;

    return $self->$orig(
        @args,
        ['active', '=', 1],
    );
};

around 'create' => sub {
    my ($orig, $self, $object) = @_;
    
    # Make sure active is set to 1
    $object->{active} = 1;
    
    # Create the object
    return $self->$orig($object);
};

EOM
    push @class_methods, $active_methods;
}
# FIXME: if we have an active field make it a default.
# check for selections and add them.
my $search_method = "";
my $create_method = "";
my $extra_methods = join "\n", @class_methods;
my $class = << "EOC";
package ${lib}::Class::$classname;

use 5.010;
use OpenERP::OOM::Class;

object_type '${lib}::Object::$classname';

$create_method

$search_method

$extra_methods

1;

EOC

my $properties = join "\n\n", @properties;
my $relationships = join "\n\n", @relationships;
my $object = << "EOO";

package ${lib}::Object::$classname;

use 5.010;
use OpenERP::OOM::Object;

openerp_model '$model';

$properties

$relationships

1;

EOO

my $files = {
    Class => $class,
    Object => $object,
};
my $lib_path = $lib;
$lib_path =~ s/::/\//g;
for my $file (keys %$files)
{
    my $filename = "lib/$lib_path/$file/$classname.pm";
    print "Writing $filename\n";
    write_file($filename, $files->{$file});
}


sub convert_type
{
    my $type = shift;
    if($type =~ /float/i)
    {
        return "Num";
    }
    if($type =~ /integer/i)
    {
        return "Int";
    }
    if($type =~ /date/i)
    {
        return "DateTime";
    }
    return "Bool" if $type =~ /boolean/i;
    return "Str";
}

