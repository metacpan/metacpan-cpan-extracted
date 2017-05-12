package t::TryCatchAuto;

use Moove -trycatch, -autoclass;

func foo_bar ($throw) {

    try {
        die $throw;
    } catch (My::Bar $e) {
        return 'bar/'.ref($e);
    } catch (My::Foo $e) {
        return 'foo/'.ref($e);
    }

}

func bar_foo ($throw) {

    try {
        die $throw;
    } catch (My::Bar $e) {
        return 'bar/'.ref($e);
    } catch (My::Foo $e) {
        return 'foo/'.ref($e);
    }

}

package My::Foo;

sub new { bless([], shift) };

package My::Bar;

sub new { bless([], shift) };

our $caller = 0;
our $cought = 0;

sub caught {
    my $self = shift;
    my $class = ref($self) || $self;
    my $e = pop || $@;
    $caller++;
    if (ref($e) eq $class) {
        $cought++;
        return $e;
    } else {
        return;
    }
}

1;
