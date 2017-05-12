use strict;
use warnings;

BEGIN {
    if ($] == 5.008) {
        print("1..0 # Skip due to Perl 5.8.0 bug\n");
        exit(0);
    }
}

use Test::More 'tests' => 6;

package My::Data; {
    use Object::InsideOut;

    my @data :Field('Accessor' => 'data');

    sub auto : Automethod
    {
        my $self = $_[0];
        my $class = ref($self) || $self;
        my $name = $_;

        # No data
        if (! exists($data[$$self])) {
            return;
        }

        my $data = \@data;      # Workaround for 5.6.X bug

        if ($$self == 1) {
            return (sub {
                        my $self = $_[0];
                        my $class = ref($self) || $self;
                        return (join(' ', $$self, $class, __PACKAGE__, $name, $$data[$$self]));
                   }, 'CUM');
        }

        return (sub {
                        my $self = shift;
                        my $class = ref($self) || $self;
                        return (@_, join(' ', $$self, $class, __PACKAGE__, $name, $$data[$$self]));
                   }, 'CHA(BOT)');
    }
}


package My::Info; {
    use Object::InsideOut qw(My::Data);

    my @info :Field('Accessor' => 'info');

    sub auto : Automethod
    {
        my $self = $_[0];
        my $class = ref($self) || $self;
        my $name = $_;

        # No info
        if (! exists($info[$$self])) {
            return;
        }

        my $info = \@info;      # Workaround for 5.6.X bug

        if ($$self == 1) {
            return (sub {
                        my $self = $_[0];
                        my $class = ref($self) || $self;
                        return (join(' ', $$self, $class, __PACKAGE__, $name, $$info[$$self]));
                   }, 'CUM');
        }
        return (sub {
                        my $self = shift;
                        my $class = ref($self) || $self;
                        return (@_, join(' ', $$self, $class, __PACKAGE__, $name, $$info[$$self]));
                   }, 'CHA(BOT)');
    }
}


package My::Comment; {
    use Object::InsideOut qw(My::Info);

    my @comment :Field('Accessor' => 'comment');

    sub AUTOMETHOD {
        if (/^foo$/) {
            return sub { return 'Bar->foo' }
        }
        return;
    }

    sub auto : Automethod
    {
        my $self = $_[0];
        my $class = ref($self) || $self;
        my $name = $_;

        # No comment
        if (! exists($comment[$$self])) {
            return;
        }

        my $comment = \@comment;      # Workaround for 5.6.X bug

        if ($$self == 1) {
            return (sub {
                        my $self = $_[0];
                        my $class = ref($self) || $self;
                        return (join(' ', $$self, $class, __PACKAGE__, $name, $$comment[$$self]));
                   }, 'CUM');
        }
        return (sub {
                        my $self = shift;
                        my $class = ref($self) || $self;
                        return (@_, join(' ', $$self, $class, __PACKAGE__, $name, $$comment[$$self]));
                   }, 'CHA(BOT)');
    }
}


package main;

MAIN:
{
    my $obj = My::Comment->new();

    my (@results, @data);

    $obj->info('test');
    @results = @{$obj->flog()};
    #print(join("\n", @results), "\n\n");

    @data = ('1 My::Comment My::Info flog test');
    is_deeply(\@results, \@data, 'Accumulation 1');

    $obj->data('tool');
    @results = @{$obj->bork()};
    #print(join("\n", @results), "\n\n");

    @data = ('1 My::Comment My::Data bork tool',
             '1 My::Comment My::Info bork test');
    is_deeply(\@results, \@data, 'Accumulation 2');

    $obj->comment('tassel');
    @results = @{$obj->funge()};
    #print(join("\n", @results), "\n\n");

    @data = ('1 My::Comment My::Data funge tool',
             '1 My::Comment My::Info funge test',
             '1 My::Comment My::Comment funge tassel');
    is_deeply(\@results, \@data, 'Accumulation 3');


    $obj = My::Comment->new();

    $obj->info('test');
    @results = $obj->flog();
    #print(join("\n", @results), "\n\n");

    @data = ('2 My::Comment My::Info flog test');
    is_deeply(\@results, \@data, 'Chained 1');

    $obj->data('tool');
    @results = $obj->bork();
    #print(join("\n", @results), "\n\n");

    @data = ('2 My::Comment My::Info bork test',
             '2 My::Comment My::Data bork tool');
    is_deeply(\@results, \@data, 'Chained 2');

    $obj->comment('tassel');
    @results = $obj->funge();
    #print(join("\n", @results), "\n\n");

    @data = ('2 My::Comment My::Comment funge tassel',
             '2 My::Comment My::Info funge test',
             '2 My::Comment My::Data funge tool');
    is_deeply(\@results, \@data, 'Chained 3');
}

exit(0);

# EOF
