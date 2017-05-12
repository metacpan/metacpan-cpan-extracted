use strict; use warnings; use warnings (FATAL => qw(misc numeric uninitialized)); # use autodie;

use Test::Fatal;
use Test::More;

my @OUTPUT;

{ package MyClass;

    use Moose;
    use MooseX::OmniTrigger;

    has foo => (is => 'rw', isa => 'Str', default => 'FRELL',                  omnitrigger => \&_callback);
    has bar => (is => 'rw', isa => 'Str',                     lazy_build => 1, omnitrigger => \&_callback);

    has baz => (is => 'rw', isa => 'Str', omnitrigger => sub { $_[0]->baz("$_[2][0]!!!") });

    sub _callback {

        my ($self, $attr_name, $new, $old) = (shift, @_);

        push(@OUTPUT, "attribute '$attr_name' has been " . (@$new ? 'set' : 'cleared'));

        push(@OUTPUT, '   oldval: ' . (@$old ? defined($old->[0]) ? $old->[0] : 'UNDEF' : 'NOVAL'));
        push(@OUTPUT, '   newval: ' . (@$new ? defined($new->[0]) ? $new->[0] : 'UNDEF' : 'NOVAL'));
    }

    sub _build_bar { 'DREN' }
}

my $obj;

is(exception { $obj = MyClass->new }, undef, 'nothing blew up') or done_testing and exit;

push(@OUTPUT, $obj->bar);

$obj->clear_bar;

$obj->baz('YOTZ');

push(@OUTPUT, $obj->baz);

is(join("\n", @OUTPUT, ''), <<'');
attribute 'foo' has been set
   oldval: NOVAL
   newval: FRELL
attribute 'bar' has been set
   oldval: NOVAL
   newval: DREN
DREN
attribute 'bar' has been cleared
   oldval: DREN
   newval: NOVAL
YOTZ!!!

done_testing;
