use strict;
use warnings;

BEGIN {
    if ($] == 5.008004 || $] == 5.008005) {
        my $z = ($] == 5.008004) ? 4 : 5;
        print("1..0 # Skip due to Perl 5.8.$z bug\n");
        exit(0);
    }
    eval {
        require Storable;
        Storable->import('thaw');
    };
    if ($@) {
        print("1..0 # Skip Storable not available\n");
        exit(0);
    }
}

use Test::More 'tests' => 8;

# Borg is a foreign hash-based class
package Borg; {
    sub new
    {
        my $class = shift;
        my %self = @_;
        return (bless(\%self, $class));
    }

    sub get_borg
    {
        my ($self, $data) = @_;
        return ($self->{$data});
    }

    sub set_borg
    {
        my ($self, $key, $value) = @_;
        $self->{$key} = $value;
    }

    sub warn
    {
        return ('Resistance is futile');
    }

    sub DESTROY {}
}


package Foo; {
    use Object::InsideOut qw(Borg);

    my @objs :Field('Acc'=>'obj', 'Type' => 'list');

    my %init_args :InitArgs = (
        'OBJ' => {
            'RE'    => qr/^obj$/i,
            'Field' => \@objs,
            'Type'  => 'list',
        },
        'BORG' => {
            'RE'    => qr/^borg$/i,
        }
    );

    sub init :Init
    {
        my ($self, $args) = @_;

        my $borg = Borg->new();
        $self->inherit($borg);

        if (exists($args->{'BORG'})) {
            $borg->set_borg('borg' => $args->{'BORG'});
        }
    }

    sub unborg
    {
        my $self = $_[0];
        #if (my $borg = $self->heritage('Borg')) {
        #    $self->disinherit($borg);
        #}
        $self->disinherit('Borg');
    }
}

package Bar; {
    use Object::InsideOut qw(Foo);
}

package Baz; {
    use Object::InsideOut qw(Bar Storable);
}


package Mat; {
    use Object::InsideOut qw(Storable);
    my @bom :Field( Standard => 'bom', Name => 'bom' );
}

package Bork; {
    use Object::InsideOut 'Storable';

    my @fld :Field;

    sub set_fld
    {
        my ($self, $data) = @_;
        $self->set(\@fld, $data);
    }
}


package main;
MAIN:
{
    my $obj = Baz->new('borg' => 'Picard');
    isa_ok($obj, 'Baz', 'Baz->new()');

    my $tmp = $obj->freeze();
    my $obj2 = thaw($tmp);
    is($obj->dump(1), $obj2->dump(1) => 'Storable works');

    # Test stored objects
    my $f1 = Mat->new();
    $f1->set_bom($obj);
    is($f1->get_bom(), $obj     => 'Stored object');

    my $f2 = thaw($f1->freeze());
    $obj2 = $f2->get_bom();
    is($obj->dump(1), $obj2->dump(1) => 'Storable works');

    # Test circular references
    $f1->set_bom($f1);
    is($f1->get_bom(), $f1      => 'Circular reference');

    $f2 = thaw($f1->freeze());
    is($f2->get_bom(), $f2      => 'Storable works');

    # Test that unnamed fields generate proper errors
    $obj = Bork->new();
    $obj->set_fld('foo');
    $tmp = $obj->freeze();
    undef($obj2);
    eval { $obj2 = thaw($tmp); };
    like($@, qr(Unnamed field encounted) => 'Unnamed field');
    is($obj2, undef,  'thaw failed');
}

exit(0);

# EOF
