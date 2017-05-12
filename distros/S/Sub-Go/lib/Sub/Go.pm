package Sub::Go;
BEGIN {
  $Sub::Go::VERSION = '0.01';
}
use strict;
use v5.10;
use Exporter::Tidy default => [ qw/go yield skip stop/ ];
use Carp;
use Scalar::Util qw/blessed/;

# get rid of this annoying message
my $old_warn_handler = $SIG{ __WARN__ };
$SIG{ __WARN__ } = sub {
    if ( $_[ 0 ] !~ /^Useless use of smart match in void context/ ) {
        goto &$old_warn_handler if $old_warn_handler;
        warn( @_ );
    }
};

use overload '~~' => \&over_go;
#use overload '>>' => \&over_go_assign;

sub over_go_assign {
    $_[0]->{assign};
    goto \&over_go;
}

sub over_go {
    my $_go_self = shift;
    my $arg      = shift;
    my $place    = shift;

    return unless defined $arg;
    my $code = $_go_self->{ code };
    my $ret  = [];
    $_go_self->{arg} = $arg;

    # input value processing
    if ( ref $arg eq 'ARRAY' ) {
        for ( @$arg ) {
            my @r = $code->($_);
            last if ref $r[0] eq 'Sub::Go::Break';
            push @$ret, @r;
        }
    }
    elsif ( ref $arg eq 'HASH' ) {
        # get the caller's $k and $v
        my ( $caller_a, $caller_b ) = do {
            my $pkg = caller();
            no strict 'refs';
            \*{$pkg.'::a'}, \*{$pkg.'::b'};
        };
    
        # iterate the hash
        while ( my ( $k, $v ) = each %$arg ) {
            local $_ = [$k,$v];
            ( *$caller_a, *$caller_b ) = \( $k, $v );
            push @$ret, $code->( $k, $v );
        }
    }
    elsif ( ref $arg eq 'GLOB' ) {
        while ( <$arg> ) {
            my $r = $code->( $_ );
            last if ref $r eq 'Sub::Go::Break';
            push @$ret, $r;
        }
    }
    elsif ( ref $arg eq 'CODE' ) {
        for ( $arg->() ) {
            my $r = $code->( $_ );
            last if ref $r eq 'Sub::Go::Break';
            push @$ret, $r;
        }
    }
    elsif ( blessed $arg && $arg->can('next') ) {
        while( local $_ = $arg->next ) {
            push @$ret, $code->( $_ );
        }
    } else {
        push @$ret, $code->( $arg ) for $arg;
    }

    # chaining return value processing
    if (   ref $_go_self->{rest} eq __PACKAGE__
        && !$_go_self->{yielded}
        && !$_go_self->{stop} )
    {
        if ( @$ret > 1 ) {
            $_go_self->{by}
                ? $_go_self->{rest}->{code}->( @$ret )
                : $ret ~~ $_go_self->{rest};
        }
        else {
            return $_go_self->{ by }
                ? $_go_self->{rest}->{code}->( @$ret )
                : $ret ~~ $_go_self->{rest};
        }
    }
    elsif ( ref $_go_self->{rest} eq 'SCALAR' ) {
       ${ $_go_self->{rest} } = $ret->[0];
    }
    elsif ( ref $_go_self->{rest} eq 'ARRAY' ) {
       @{ $_go_self->{rest} } = @$ret;
    }
    elsif ( ref $_go_self->{rest} eq 'HASH' ) {
       %{ $_go_self->{rest} } = @$ret;
    }
    else {
        return @$ret > 1 ? $ret
            : $ret->[0] // $ret;
    }
}

sub stop {
    require PadWalker;
    my $self_ref;
    for ( 2 .. 3 ) {
        my $h = PadWalker::peek_my( $_ );
        $self_ref = $h->{ '$_go_self' } and last;
    }
    !$self_ref and croak 'Misplaced yield. It can only be used in a go block.';
    my $self = ${ $self_ref };
    $self->{stop} = 1;
    return bless {}, 'Sub::Go::Break';
}

sub skip {
    return bless {}, 'Sub::Go::Break';
}

sub yield {
    require PadWalker;
    my $self_ref;
    for ( 2 .. 3 ) {
        my $h = PadWalker::peek_my( $_ );
        $self_ref = $h->{ '$_go_self' } and last;
    }
    !$self_ref and croak 'Misplaced yield. It can only be used in a go block.';
    my $self = ${ $self_ref };
    $self->{yielded} = 1;
    $self->{rest}->{code}->( @_ );
}

sub go(&;@) {
    my $code = shift;
    my $rest = shift;
    
    return bless { code => $code, rest => $rest }, __PACKAGE__;
}

sub by(&;@) {
    my ( $code, $rest ) = @_;
    return bless { code => $code, rest => $rest, by => 1 }, __PACKAGE__;
}

1;

=pod

=head1 NAME

Sub::Go - DWIM sub blocks for smart matching 

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Sub::Go;

    [ 1, 2, 3 ] ~~ go { say $_  };
    # 1
    # 2
    # 3

    # hashes with $a and $b

    %h ~~ go { say "key $a, value $b" };

    undef ~~ go {
        # never gets called...
    };

    '' ~~ go {
        # ...but this does
    };

    # in-place modify

    my @rs = ( { name=>'jack', age=>20 }, { name=>'joe', age=>45 } );
    @rs ~~ go { $_->{name} = 'sue' };

    # filehandles 

    open my $fh, '<', 'file.txt';
    $fh ~~ go {
        my $line = shift;
        say ; # line by line 
    };

    # chaining
    @arr ~~ go { s/$/one/ } go { s/$/two/ };

    # combine with signatures, or Method::Signatures
    #   for improved sweetness
    use Method::Signatures;

    %h ~~ go func($x,$y) {
        say $x * $y;
    };

=head1 DESCRIPTION

In case you don't know, smart matching (C<~~>) data against a code block
will run the block once (for scalars) or, distributively, many times
for arrays and hashes:

    [1..10] ~~ sub { say shift };
    @arr ~~ sub { say shift };
    %h ~~ sub { ... };

The motivation behind this module is to improve
the experience of using a code block with the smart match 
operator.

This module imports a sub called C<go> into your package. 
This sub returns an object that overloads the smart match operator.

=head2 Benefits

=head3 proper handling of hashes, with $a and $b for keys and values

Smart matching sends only the keys, which may be useless
if your hash is anonymous.

   { foo=>1, bar=>2 } ~~ go { 
        say "key=$a, value=$b";
   };

=head3 context variables

Load C<$_> with the current value for arrays and scalars.
Look for C<$a> and C<$b> for hash values. 

=head3 in-place modification of original values

But only in the first C<go> block of a chain (although this
may change soon).

    my @arr = qw/a b c/;
    @arr ~~ go { s{$}{x} };
    # now @arr is qw/ax bx cx/

=head3 prevent the block from running on undef values

We're tired of checking if defined is defined in loops.

    undef ~~ go { say "never runs" };
    undef ~~ sub { say "but we do" };

=head3 chaining of sub blocks

So you can bind several blocks, one after the other, 
in the opposite direction of C<map>, C<grep> and friends. 

    $arr ~~ go { } go { } go { };

=head3 no warnings on the useless use of smart match operator in void context

Annoying warning for funky syntax overloading modules like this one
or L<IO::All>. Perl should have better way around this warning.

=head2 Pitfalls

A smart match (and most overloaded operators)
can only return scalar values. So you can only expect
to get a scalar (value or arrayref) from your block chaining.

=head1 FEATURES

=head2 chaining

You can chain C<go> statements together, in the reverse direction
as you would with C<map> or C<grep>.

    say 10 ~~ go { return $_[0] * 2 }
                go { return $_[0] + 1 }; 
    # 21  

The next C<go> block in the chain gets the return value
from the previous block. 

    [1..3] ~~ go { say "uno " . $_[0]; 100 + $_[0] }
              go { say "due " . shift };

    # uno 1    
    # uno 2    
    # uno 3    
    # due 101
    # due 102
    # due 103

To interleave two C<go> blocks
use the C<yield> statement.

    [1..3] ~~ go { say "uno " . $_[0]; yield 100 + $_[0] } go { say "due " . shift };

    # uno 1    
    # due 101
    # uno 2    
    # due 102
    # uno 3    
    # due 103

You can interrupt a C<go> block with an special return 
statement: C<return skip>.
    
    [1..1000] ~~ go {
        # after 100 this block won't execute anymore
        return skip if $_[0] > 100;
    } go {
        # but this one will keep going up to the 1000th
    };

Or break the whole chain at a given point:

    [1..1000] ~~ go {
        # after 100 this block won't execute anymore
        return stop if $_[0] > 100;
    } go {
        # this one will run 100 times too
    };

=head2 return values

Scalar is the only return value from a smart match expression,
and the same applies to C<go>. You can only return scalars, 
no arrays and hashes. So we return an arrayref if your go chain
returns more than one value.

    # scalar
    my $value = 'hello' ~~ go { "$_[0] world" } # hello world
    
    # arrayref 
    my $arr = [10..19] go { shift }; # @arr == 1, $arr[0] == 10

Just use C<map> in this case, which is syntactically more sound anyway.

So, there's an alternative implementation for returning values, by 
chaining a reference to a variable, as such:

    my @squares;
    @input ~~ go { $_ ** 2 } \@squares;
    
    my %hash = ( uno=>11, due=>22 );
    my %out;
    %hash ~~ go { "xxx$_[0]" => $_[1] } \%out;
    # %out = ( xxxuno => 11, xxxdue => 22 )

Now you have a C<map> like interface the other way around.

=head2 next iterators 

If you send the block an object which implements 
a method called C<next>, the method will be automatically called
and the return value fed to the block.

    # DBIx::Class resultset
    
    $resultset->search({ age=>100 }) ~~ go {
        $_->name . " is centenary!";
    };

=head1 IMPORTS

=head3 go CODE

The main function here. Don't forget the semicolon at the end of the block.

=head3 yield VALUE

Iterate over into the next block in the chain.
    
    [qw/sue mike/] ~~ go { yield "world, $_" } go { say "hello " . shift };

=head3 skip 

Tell the iterator to stop executing the current block and go
to the next, if any.
    
    return skip;

=head3 stop 

Tell the iterator to stop executing all blocks.

    return stop;

=head1 BUGS

This is pre-alfa, out in the CPAN for a test-drive. There 
are still inconsistencies in the syntax that need some 
more thought, so expect things to change badly. 

L<PadWalker>, a dependency, may segfault in perl 5.14.1.

=head1 SEE ALSO

L<autobox::Core> - has an C<each> method that can be chained together

L<List::Gen>

L<Sub::Chain>

=cut
