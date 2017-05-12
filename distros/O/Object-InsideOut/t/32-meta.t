use strict;
use warnings;

my $HAVE_STORABLE;
BEGIN {
    if ($] < 5.008) {
        print("1..0 # Skip Introspection requires Perl 5.8.0 or later\n");
        exit(0);
    }

    eval { require Storable; };
    $HAVE_STORABLE = !$@;
}

use Test::More 'tests' => 43;

package Foo; {
    use Object::InsideOut;

    my @data :Field :Type(num) :All(data);
    my @get  :Field
             :Type(\&Foo::my_sub)
             :Set(setget)
             :Get('name' => 'fooget', 'perm' => 'restricted');

    my $id = 1;
    sub id :ID(restricted) {
        return ($id++);
    }

    sub my_sub :Sub {}
    sub my_foo :Method(Class) {}
    sub my_fink :Restricted :Method(Object) {}

    sub cu :Cumulative   { return ('Foo cumulative'); }
    sub ch :Chain(Bottom up)
    {
        my ($self, $val) = @_;
        return ($val . ' ' . __PACKAGE__);
    }

    sub am :Automethod
    {
        return (sub {});
    }
}

package Bar; {
    BEGIN {
        no warnings 'once';
        $Bar::storable = $HAVE_STORABLE;
    }
    use Object::InsideOut qw(Foo);
    use Object::InsideOut::Metadata;

    my @info :Field :Type(list(num)) :All(info);
    my @more :Field :Type(ARRAY(Foo)) :Arg(more);
    my @set
        :Field
        :Type(sub { $_[0]->isa('UNIVERSAL') })
        :Set('name' => 'barset', 'ret' => 'old');

    sub cu :Cumulative   { return ('Bar cumulative'); }
    sub ch :Chain(Bottom up)
    {
        my ($self, $val) = @_;
        return ('Chain: ', __PACKAGE__);
    }

    sub _internal { return; }
    sub bar :Method { return; }
    add_meta(__PACKAGE__, 'bar', 'bork', 1);

    sub bork :Method :MergeArgs(restricted) { return; }
}


package main;

sub check_bar
{
    my $thing = shift;
    my $meta = $thing->meta();

    my @classes_are = (qw/Foo Bar Storable/);
    if (! $HAVE_STORABLE) {
        pop(@classes_are);
    }

    my @classes = $meta->get_classes();
    is_deeply(\@classes, \@classes_are, 'Meta classes');
    my $classes = $meta->get_classes();
    is_deeply($classes, \@classes_are, 'Meta classes (ref)');

    @classes = $thing->isa();
    is_deeply(\@classes, \@classes_are, '->isa() classes');
    $classes = $thing->isa();
    is_deeply($classes, \@classes_are, '->isa() classes (ref)');


    my %args_are = (
        'Foo' => {
            'data' => {
                'type' => 'numeric',
                'field' => 1,
            },
        },
        'Bar' => {
            'info' => {
                'type' => 'list(numeric)',
                'field' => 1,
            },
            'more' => {
                'type' => 'list(Foo)',
                'field' => 1,
            }
        },
    );

    my %args = $meta->get_args();
    is_deeply(\%args, \%args_are, 'Bar args');
    my $args = $meta->get_args();
    is_deeply($args, \%args_are, 'Bar args (ref)');

    my %meths_are = (
          'new'   => { 'class' => 'Bar',
                       'kind'  => 'constructor',
                       'merge_args' => 1 },
          'clone' => { 'class' => 'Bar',
                       'kind'  => 'object', },
          'meta'  => { 'class' => 'Bar' },
          'set'   => { 'class' => 'Bar',
                       'kind'  => 'object',
                       'restricted' => 1 },

          'can' => { 'class' => 'Object::InsideOut',
                     'kind'  => 'object', },
          'isa' => { 'class' => 'Object::InsideOut',
                     'kind'  => 'object', },

          'id' => { 'class' => 'Foo',
                    'restricted' => 1 },

          'dump' => { 'class' => 'Object::InsideOut',
                      'kind'  => 'object', },
          'pump' => { 'class' => 'Object::InsideOut',
                      'kind'  => 'class', },

          'create_field' => { 'class' => 'Object::InsideOut',
                              'kind'  => 'class', },
          'add_class'    => { 'class' => 'Object::InsideOut',
                              'kind'  => 'class', },

          'inherit'    => { 'class' => 'Bar',
                            'kind'  => 'object',
                            'restricted' => 1 },
          'heritage'   => { 'class' => 'Bar',
                            'kind'  => 'object',
                            'restricted' => 1 },
          'disinherit' => { 'class' => 'Bar',
                            'kind'  => 'object',
                            'restricted' => 1 },

          'freeze' => { 'class' => 'Storable',
                        'kind'  => 'foreign', },
          'thaw'   => { 'class' => 'Storable',
                        'kind'  => 'foreign', },

          'data' => { 'class'  => 'Foo',
                      'kind'   => 'accessor',
                      'type'   => 'numeric',
                      'return' => 'new' },

          'setget' => { 'class'  => 'Foo',
                        'kind'   => 'set',
                        'type'   => '\&Foo::my_sub',
                        'return' => 'new' },
          'fooget' => { 'class'  => 'Foo',
                        'kind'   => 'get',
                        'restricted' => 1 },

          'my_foo' => { 'class' => 'Foo',
                        'kind'  => 'class', },

          'my_fink' => { 'class' => 'Foo',
                         'kind'  => 'object',
                         'restricted' => 1 },

          'AUTOLOAD' => { 'class' => 'Foo',
                          'kind'  => 'automethod', },

          'info' => { 'class'  => 'Bar',
                      'kind'   => 'accessor',
                      'type'   => 'list(numeric)',
                      'return' => 'new' },

          'barset' => { 'class'  => 'Bar',
                        'kind'   => 'set',
                        'type'   => q/sub { $_[0]->isa('UNIVERSAL') }/,
                        'return' => 'old' },

          'cu' => { 'class'  => 'Bar',
                    'kind'   => 'cumulative' },

          'ch' => { 'class'  => 'Bar',
                    'kind'   => 'chained (bottom up)' },

          'bar' => { 'class' => 'Bar',
                     'bork'  => 1 },

          'bork' => { 'class' => 'Bar',
                      'merge_args' => 1,
                      'restricted' => 1 },
    );
    if (! $HAVE_STORABLE) {
        delete($meths_are{'freeze'});
        delete($meths_are{'thaw'});
        $meths_are{'inherit'}{'class'}    = 'Object::InsideOut';
        $meths_are{'heritage'}{'class'}   = 'Object::InsideOut';
        $meths_are{'disinherit'}{'class'} = 'Object::InsideOut';
    }

    my %meths = $meta->get_methods();

    # Remove most Storable methods
    foreach my $meth (keys(%meths)) {
        next if ($meth eq 'freeze' || $meth eq 'thaw');
        if ($meths{$meth}{'class'} eq 'Storable') {
            delete($meths{$meth});
        }
    }

    is_deeply(\%meths, \%meths_are, 'Bar methods');
}


sub check_meta_meta
{
    my $thing = shift;
    my $meta = $thing->meta();

    isa_ok($meta, 'Object::InsideOut::Metadata');

    my @meta_classes = ( 'Object::InsideOut::Metadata' );

    my @classes = $meta->get_classes();
    is_deeply(\@classes, \@meta_classes, 'no subclasses');
    my $classes = $meta->get_classes();
    is_deeply($classes, \@meta_classes, 'no subclasses (ref)');


    my %meta_args = (
        'Object::InsideOut::Metadata' => {
            'GBL'   => {},
            'CLASS' => {},
        },
    );

    my %args = $meta->get_args();
    is_deeply(\%args, \%meta_args, 'Meta args');
    my $args = $meta->get_args();
    is_deeply($args, \%meta_args, 'Meta args (ref)');

    my %meta_meths = (
          'clone' => { 'class' => 'Object::InsideOut::Metadata',
                       'kind'  => 'object' },
          'meta'  => { 'class' => 'Object::InsideOut::Metadata' },
          'set'   => { 'class' => 'Object::InsideOut::Metadata',
                       'kind'  => 'object',
                       'restricted' => 1 },

          'can' => { 'class' => 'Object::InsideOut',
                     'kind'  => 'object', },
          'isa' => { 'class' => 'Object::InsideOut',
                     'kind'  => 'object', },

          'dump' => { 'class' => 'Object::InsideOut',
                      'kind'  => 'object' },
          'pump' => { 'class' => 'Object::InsideOut',
                      'kind'  => 'class' },

          'get_classes' => { 'class' => 'Object::InsideOut::Metadata',
                             'kind'  => 'object' },
          'get_args'    => { 'class' => 'Object::InsideOut::Metadata',
                             'kind'  => 'object' },
          'get_methods' => { 'class' => 'Object::InsideOut::Metadata',
                             'kind'  => 'object' },

          'inherit'    => { 'class' => 'Object::InsideOut::Metadata',
                            'kind'  => 'object',
                            'restricted' => 1 },
          'heritage'   => { 'class' => 'Object::InsideOut::Metadata',
                            'kind'  => 'object',
                            'restricted' => 1 },
          'disinherit' => { 'class' => 'Object::InsideOut::Metadata',
                            'kind'  => 'object',
                            'restricted' => 1 },
    );
    if (! $HAVE_STORABLE) {
        $meta_meths{'inherit'}{'class'}    = 'Object::InsideOut';
        $meta_meths{'heritage'}{'class'}   = 'Object::InsideOut';
        $meta_meths{'disinherit'}{'class'} = 'Object::InsideOut';
    }

    my %meths = $meta->get_methods();
    is_deeply(\%meths, \%meta_meths, 'Meta methods');
    my $meths = $meta->get_methods();
    is_deeply($meths, \%meta_meths, 'Meta methods (ref)');

    my @meths = sort($thing->can());
    my @meths2 = sort(keys(%meta_meths));
    is_deeply(\@meths, \@meths2, '->can() methods');
    $meths = $thing->can();
    @meths = sort(@$meths);
    is_deeply(\@meths, \@meths2, '->can() methods (ref)');

    my $meta_meta = $meta->meta()->get_methods();
    is_deeply($meta_meta, \%meta_meths, 'meta meta');
}


sub check_res
{
    my $thing = shift;
    my $meta = $thing->meta();

    my @meta_classes = ( 'Object::InsideOut::Results' );

    my @classes = $meta->get_classes();
    is_deeply(\@classes, \@meta_classes, 'no subclasses');
    my $classes = $meta->get_classes();
    is_deeply($classes, \@meta_classes, 'no subclasses (ref)');


    my %meta_args = (
        'Object::InsideOut::Results' => {
            'VALUES'      => { 'field' => 1 },
            'CLASSES'     => { 'field' => 1 },
        },
    );

    my %args = $meta->get_args();
    is_deeply(\%args, \%meta_args, 'Meta args');
    my $args = $meta->get_args();
    is_deeply($args, \%meta_args, 'Meta args (ref)');


    my %meta_meths = (
          'clone' => { 'class' => 'Object::InsideOut::Results',
                       'kind'  => 'object' },
          'meta'  => { 'class' => 'Object::InsideOut::Results' },
          'set'   => { 'class' => 'Object::InsideOut::Results',
                       'kind'  => 'object',
                       'restricted' => 1 },

          'can' => { 'class' => 'Object::InsideOut',
                     'kind'  => 'object', },
          'isa' => { 'class' => 'Object::InsideOut',
                     'kind'  => 'object', },

          'dump' => { 'class' => 'Object::InsideOut',
                      'kind'  => 'object' },
          'pump' => { 'class' => 'Object::InsideOut',
                      'kind'  => 'class' },

          'as_string' => { 'class' => 'Object::InsideOut::Results',
                           'kind'  => 'overload', },
          'count'     => { 'class' => 'Object::InsideOut::Results',
                           'kind'  => 'overload', },
          'as_hash'   => { 'class' => 'Object::InsideOut::Results',
                           'kind'  => 'overload', },
          'values'    => { 'class' => 'Object::InsideOut::Results',
                           'kind'  => 'overload', },
          'have_any'  => { 'class' => 'Object::InsideOut::Results',
                           'kind'  => 'overload', },

          'inherit'    => { 'class' => 'Object::InsideOut::Results',
                            'kind'  => 'object',
                            'restricted' => 1 },
          'heritage'   => { 'class' => 'Object::InsideOut::Results',
                            'kind'  => 'object',
                            'restricted' => 1 },
          'disinherit' => { 'class' => 'Object::InsideOut::Results',
                            'kind'  => 'object',
                            'restricted' => 1 },
    );
    if (! $HAVE_STORABLE) {
        $meta_meths{'inherit'}{'class'}    = 'Object::InsideOut';
        $meta_meths{'heritage'}{'class'}   = 'Object::InsideOut';
        $meta_meths{'disinherit'}{'class'} = 'Object::InsideOut';
    }

    my %meths = $meta->get_methods();
    is_deeply(\%meths, \%meta_meths, 'Meta methods');
    my $meths = $meta->get_methods();
    is_deeply($meths, \%meta_meths, 'Meta methods (ref)');
}


MAIN:
{
    can_ok('Bar', 'meta');

    ### Bar class meta
    check_bar('Bar');

    ### Bar object meta
    my $obj = Bar->new();
    check_bar($obj);

    ### Meta class meta
    check_meta_meta('Object::InsideOut::Metadata');

    ### Meta object meta
    check_meta_meta($obj->meta());

    ### Cumulative meta
    my $res = $obj->cu();
    my @cum = @{$res};
    is_deeply(\@cum, [ 'Foo cumulative', 'Bar cumulative' ], 'cumulative results');
    check_res($res);

    eval { Object::InsideOut->meta(); };
    is($@->{'message'}, "'meta' called on non-class 'Object::InsideOut'", 'No OIO meta');
}

exit(0);

# EOF
