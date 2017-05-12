package Parallel::SubArray;
require v5.8.6;
our $VERSION = 0.6;
use strict;
use Storable qw(store_fd fd_retrieve);
use Exporter 'import';
our @EXPORT_OK = qw(par);

sub par {
  my( $timeout ) = @_;
  sub {
    my @subs = @{ shift(@_) };
    my %rets;
    my $c = 0;
    for my $sub ( @subs ) {
      $c++;
      my( $parent_w, $child_r );
      pipe( $child_r, $parent_w );
      select((select($parent_w ), $| = 1)[0]);
      if( my $pid = fork ) {
	close $parent_w;
	$rets{ $pid } = { fd  => $child_r,
			  ord => $c
			};
      } else {
	die "Cannot fork: $!" unless defined $pid;
	close $child_r;
	my $exit = sub {
	  my( $save_val, $exit_val ) = @_;
	  store_fd $save_val, $parent_w;
	  close $parent_w;
	  exit $exit_val;
	};
	local $SIG{ALRM} = sub { $exit->( ['TIMEOUT'], 1 ) };
	alarm( $timeout || 0 );
	my $ret = eval{ $sub->() };
	my $err = $@;
	alarm( 0 );
	$exit->( [$err], 1 ) if $err;
	$exit->(  $ret , 0 );
      }
    }
    while(1) {
      my $pid = wait();
      my $err = $?;
      last if( $pid == -1 or not @subs );
      next if not exists $rets{ $pid };
      if( $err ) {
	$rets{ $pid }->{err} = fd_retrieve( $rets{ $pid }->{fd} )->[0];
      } else {
	$rets{ $pid }->{val} = fd_retrieve( $rets{ $pid }->{fd} );
      }
      close $rets{ $pid }->{fd};
      pop @subs;
    }
    my $r = sub {
      my( $key ) = @_;
      # can be optimized
      [ map  { $rets{$_}->{ $key } }
	sort { $rets{$a}->{ord} <=> $rets{$b}->{ord} }
	keys %rets
      ];
    };
    return wantarray ? ( $r->('val'), $r->('err') ) : $r->('val');
  }
}

1;
__END__

=head1 NAME

Parallel::SubArray - Execute forked subref array and join return values, timeouts and error captures.

=head1 SYNOPSIS

  use Parallel::SubArray 'par';

  my $sub_arrayref = [
    sub{ sleep(1); [1]  }, # simple structure
    sub{ bless {}, 'a'  }, # blessed structure
    sub{ while(1){$_++} }, # runaway routine
    sub{ die 'TEST'     }, # bad code
    sub{ par()->([         # nested parallelism
           sub{ sleep(1);  [1]  },
           sub{ sleep(2); {2,3} },
         ]),
       },
  ];

  my($result_arrayref, $error_arrayref) = par(3)->($sub_arrayref);
  ## or you can ignore errors
  # my $result_arrayref = par(3)->($sub_arrayref);

  $result_arrayref == [
    [ 1 ],
    {}, # blessed into 'a'
    undef,
    undef,
    [ [1], { 2 => 3 } ]
  ];

  $error_arrayref == [
    undef,
    undef,
    'TIMEOUT',
    # can capture normal blessed exceptions aswell
    'TEST at some file on some line',
    undef,
  ];

=head1 DESCRIPTION

I want fast, safe, and simple parallelism.  Current offerings did not
satisfy me.  Most are not enough while remaining are too complex or
tedious.  L<Palallel::SubArray> scratches my itch: forking, joining,
timeouts, return values, and error handling done simply.

=head1 EXPORTS

Nothing automatically.  I don't like magic.

=head2 par

Takes one argument that represents timeout in seconds and evaluates
into a subref that will execute subarrayref in parallel returning
resultarrayref in scalar context or resultarrayref and errorarrayref
in list context.

Timeout can be undef or zero.  In this case timeout is disabled and
you might never join forks.

When nesting parallelism, keep in mind the outer timeout.  Because if
inner C<par> is cut off by the timeout of the outer, you will not be
able to recover return nor error values of finished inner processes as
the whole inner C<par> is considered to be a runaway process.

C<par> can die if unable to fork.

=head1 SEE ALSO

L<perlipc>
L<perlfunc/"fork">
L<perlfork>
L<subs::parallel>
L<Parallel::Simple>
L<Parallel::Queue>
L<Parallel::Forker>
L<Parallel::Jobs>
L<Parallel::Workers>
L<Parallel::SubFork>
L<Parallel::Pvm>
L<Parallel::Performing>
L<Parallel::Fork::BossWorker>
L<Parallel::ForkControl>
L<Proc::Fork>

=head1 BUGS

Expect lots if Windows and/or OOP is used.  Windows because of the
lack of forking and OOP because it requires locking.  This module is
designed functionally and is relying on copy-on-write forking.

The joining mechanism of this module can be incompatible with other
forking modules because it's waiting for child processes to finish.
Nesting of C<par> works as expected.

Subroutines passed to C<par> that return anything other than
references to simple Perl structures may behave unexpectedly. Joining
relies on L<Storable>.

=head1 AUTHOR

Eugene Grigoriev,

  let a b c d e f g  = concat [e,f,d,g,c,f,b] in
      a "com" "gmail" "grigoriev" "eugene" "." "@"

=head1 LICENSE

BSD

=cut
