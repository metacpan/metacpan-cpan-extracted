package Sub::Compose;

$VERSION = '0.01';

use strict;

use Data::Dump::Streamer ();
use Sub::Name qw( subname );

sub import {
    my $pkg = caller;

    for (@_) {
        no strict 'refs';
        if ( $_ eq 'compose' ) {
            *{ "${pkg}::compose" } = \&compose;
            next;
        }
        if ( $_ eq 'chain' ) {
            *{ "${pkg}::chain" } = \&chain;
            next;
        }
    }

    return;
}

sub chain {
    my (@subs) = @_;

    return subname chainer => sub {
        foreach my $sub ( @subs ) {
            @_ = $sub->( @_ );
        }

        return @_;
    };
}

sub compose {
    my @subs = @_;

    #{my $i;print map { $i++ . ":$_\n" } Data::Dump::Streamer::Dump( @subs )->Out;}

    my @code = do {
        grep {
            !/^;/
        } Data::Dump::Streamer::Dump( @subs )->Out;
    };

    #{my $i;print map { $i++ . " -> $_\n" } @code;}

    my %deparsed;
    my @vars;
    my @deparsed;
    foreach my $i ( 0 .. $#code ) {
        my @lines = split /\n/, $code[$i];
        
        my ($name) = $lines[0] =~ m{^ \$ (\S+) \s* = \s* (?:sub|\$)}x;

        unless ( $name ) {
            push @vars, @lines;
            next;
        }

        if ( @lines == 1 ) {
            my ($ref) = $lines[0] =~ m{ \$ (\S+) ; $}x;
            ($deparsed{ $name } = $deparsed{ $ref }) =~ s/END_SUB_\d+/END_SUB_$i/g;
        }
        else {
            shift @lines; pop @lines;

            local $_;
            my $seen_return;
            for (@lines) {
                if (/return /) {
                    s/return /\@_ = /g;
                    $_ .= "goto END_SUB_$i;";
                    $seen_return++;
                }
            }
            $lines[-1] = "\@_ = $lines[-1]" unless $seen_return;
            push @lines, "END_SUB_$i:;\n";
            $deparsed{ $name } = join "\n", @lines;
        }
        push @deparsed, $deparsed{ $name };
    }

    my $sub = eval "{ @vars; sub { @deparsed; return wantarray ? \@_ : \$_[0] } }";
    die $@ if $@;
    return subname composer => $sub; 
}

1;
__END__

=head1 NAME

Sub::Compose

=head1 SYNOPSIS

  use Sub::Compose qw( compose );

  sub factory {
      my ($mult) = @_;
      return sub {
          my $val = shift;
          return $val * $mult;
      }
  }

  my $times_two = factory( 2 );
  my $times_three = factory( 3 );

  my $times_six = compose( $times_two, $times_three );

  $times_six->( 4 ); # 24

=head1 DESCRIPTION

The compose() function takes any number of subroutine references and creates a
new subroutine reference from them that

=over 4

=item * Executes the code from the 1st with the parameters passed in

=item * Executes the code from (N+1)th with the return value from the Nth.

=item * Returns the return value from the last one.

=back

=head1 RATIONALE

I like creating little subroutines that do interesting bits of work. I then
like to build other subroutines by calling these guys and so on and so forth.
Sometimes, I build up subroutines with calls 3 and 4 levels deep. This causes
two problems:

=over 4

=item * Convoluted Stackdumps

Oftentimes, these little subroutines are validations that are supposed to die
when they find something wrong. The stacktrace that confess() provides shows a
whole bunch of subroutine calls that can be confusing.

This is demostrated in t/000_basic.t which highlights the difference between
compose() and chain().

=item * Performance

Calling a subroutine in Perl is one of the slowest single actions you can do.
I have been finding myself with 20-30 extra subroutine calls just to program
the way I want to program.

=back

While I could pass little strings around and eventually eval them, I don't
think that way - I think in terms of little pieces of work that I can put
together like Tinkertoys(TM) or Legos(TM).

Also, strings don't close over variables. Most of the functions I use in this
way are closures, so that method doesn't even work.

=head1 METHODOLOGY

Currently, this uses L<Data::Dump::Streamer> to deparse the subroutines along
with their lexical environments and then intelligently concatenates the output
to form a single subroutine. As such, it has all issues that DDS has in terms
of parsing coderefs. Please refer to that documentation for more details.

I am working on revamping this so that I manipulate the opcodes directly vs.
deparsing. This should have increased performance and, hopefully, will reduce
the likelihood of any edge cases. As this is my first foray into the world of
perlguts, we'll see how it goes. :-)

=head1 FUNCTIONS

=head2 chain()

This is the old style of doing this and is provided for reference. It is
implemented as so:

  sub chain {
      my (@subs) = @_;

      return subname chainer => sub {
          foreach my $sub ( @subs ) {
              @_ = $sub->( @_ );
          }

          return @_;
      };
  }

As you can see, if there's a good 10-15 subroutines involved, this can be a
lot of extra work, particularly if the subroutines are very small.

=head2 compose()

This is what this module is all about. Create a single subroutine from a bunch
of subroutines that were passed in while still preserving closures.

=head1 BUGS

I'm sure this code has bugs somewhere. If you find one, please email me a
failing test and I'll make it pass in the next release.

=head1 CODE COVERAGE

We use L<Devel::Cover> to test the code coverage of our tests. Below is the
L<Devel::Cover> report on this module's test suite.

  ---------------------------- ------ ------ ------ ------ ------ ------ ------
  File                           stmt   bran   cond    sub    pod   time  total
  ---------------------------- ------ ------ ------ ------ ------ ------ ------
  blib/lib/Sub/Compose.pm       100.0   92.9    n/a  100.0  100.0  100.0   99.0
  Total                         100.0   92.9    n/a  100.0  100.0  100.0   99.0
  ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 AUTHORS

Rob Kinyon E<lt>rob.kinyon@iinteractive.comE<gt>

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

Thanks to Infinity Interactive for generously donating our time.

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
