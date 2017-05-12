use strict;
use warnings;

use Test::More 'tests' => 4;

package Foo; {
    use Object::InsideOut;

    sub we_are :Cumulative :Restricted
    {
        return __PACKAGE__;
    }

    sub whoami :Chained(bottom up) :Restricted
    {
        my ($self, $whoami) = @_;
        my $class = __PACKAGE__;
        return ($whoami) ? "$whoami son of $class" : $class;
    }

    sub auto : Automethod
    {
        my $self = $_[0];
        my $class = ref($self) || $self;
        my $name = $_;

        if ($name eq 'izza') {
            return (sub {
                        my $self = $_[0];
                        my $class = ref($self) || $self;
                        return ($class . ' isa ' . __PACKAGE__);
                   }, 'CUM(BOT)');
        }

        if ($name eq 'bork') {
            return (sub {
                        my $self = $_[0];
                        my $class = __PACKAGE__;
                        my ($whoami) = $class->whoami();
                        return ("$class says 'I am $whoami.'");
                   }, 'CUM');
        }

        return;
    }

    sub as_string :Stringify
    {
        my ($whoami) = $_[0]->whoami('');
        return ("I am $whoami");
    }

    sub as_hash :Hashify
    {
        return ($_[0]->we_are());
    }

    sub as_array :Arrayify
    {
        return ($_[0]->izza());
    }

    sub as_code :Codify
    {
        my $self = $_[0];
        return (sub { $self->can('bork')->($self) });
    }
}

package Bar; {
    use Object::InsideOut 'Foo';

    sub we_are :Cumulative :Restricted
    {
        return __PACKAGE__;
    }

    sub whoami :Chained(bottom up) :Restricted
    {
        my ($self, $whoami) = @_;
        my $class = __PACKAGE__;
        return ($whoami) ? "$whoami son of $class" : $class;
    }

    sub auto : Automethod
    {
        my $self = $_[0];
        my $class = ref($self) || $self;
        my $name = $_;

        if ($name eq 'izza') {
            return (sub {
                        my $self = $_[0];
                        my $class = ref($self) || $self;
                        return ($class . ' isa ' . __PACKAGE__);
                   }, 'CUM(BOT)');
        }

        if ($name eq 'bork') {
            return (sub {
                        my $self = $_[0];
                        my $class = __PACKAGE__;
                        my ($whoami) = $class->whoami();
                        return ("$class says 'I am $whoami.'");
                   }, 'CUM');
        }

        return;
    }
}

package Baz; {
    use Object::InsideOut 'Bar';

    sub we_are :Cumulative :Restricted
    {
        return __PACKAGE__;
    }

    sub whoami :Chained(bottom up) :Restricted
    {
        my ($self, $whoami) = @_;
        my $class = __PACKAGE__;
        return ($whoami) ? "$whoami son of $class" : $class;
    }

    sub auto : Automethod
    {
        my $self = $_[0];
        my $class = ref($self) || $self;
        my $name = $_;

        if ($name eq 'izza') {
            return (sub {
                        my $self = $_[0];
                        my $class = ref($self) || $self;
                        return ($class . ' isa ' . __PACKAGE__);
                   }, 'CUM(BOT)');
        }

        if ($name eq 'bork') {
            return (sub {
                        my $self = $_[0];
                        my $class = __PACKAGE__;
                        my ($whoami) = $class->whoami();
                        return ("$class says 'I am $whoami.'");
                   }, 'CUM');
        }

        return;
    }
}

package main;

MAIN:
{
    my $baz = Baz->new();
    is("$baz", 'I am Baz son of Bar son of Foo' => 'whoami');

    my %we_are = %{$baz};
    is_deeply(\%we_are, { 'Foo' => 'Foo',
                          'Bar' => 'Bar',
                          'Baz' => 'Baz' }      => 'we_are');

SKIP: {
    skip('due to Perl 5.8.0 bug', 2) if ($] == 5.008);

    my @izza = @{$baz};
    is_deeply(\@izza, [ 'Baz isa Baz',
                        'Baz isa Bar',
                        'Baz isa Foo' ]         => 'izza');

    my @says = @{$baz->()};
    is_deeply(\@says, [ "Foo says 'I am Foo.'",
                        "Bar says 'I am Bar son of Foo.'",
                        "Baz says 'I am Baz son of Bar son of Foo.'" ] => 'bork');
}

}

exit(0);

# EOF
