#!/usr/bin/env perl
# $Id$

# Based on
# http://code2.0beta.co.uk/moose/svn/MooseX-POE/trunk/ex/tbray.pl
# which is based on
# http://www.tbray.org/ongoing/When/200x/2007/09/20/Wide-Finder

{
	package Slurper;
	use POE::Stage qw(:base);
	use IO::File;
	use POE::Watcher::Input;

	sub on_slurp {
		my $req_fh = IO::File->new( my $arg_filename );
		unless ($req_fh) {
			my $req->return(
				type => "open_failure",
				args => {
					error => ($!+0) . ": $!",
				},
			);
			return;
		}

		my $req_input = POE::Watcher::Input->new(
			handle => $req_fh,
			on_input => "on_next_line",
		);
	}

	sub on_next_line {
		my ($req, $req_fh);

		my $line = <$req_fh>;
		if (defined $line) {
			$req->emit(
				type => "line",
				args => {
					line => $line
				}
			);
			return;
		}

		my $req_input = undef;
		$req->return(
			type => "eof"
		);
	}
}

{
	package App;
	use POE::Stage::App qw(:base);

	sub on_run {
		my $req_count = 0;
		my $req_slurp = Slurper->new();
		my $req_start = POE::Request->new(
			stage => $req_slurp,
			method => "slurp",
			role => "slurper",
			args => {
				filename => "examples/o10k.ap",
			}
		);
	}

	sub on_slurper_line {
		my ($arg_line, $req_count);
		$req_count++ if (
			$arg_line =~ qr|GET /ongoing/When/\d\d\dx/(\d\d\d\d/\d\d/\d\d/[^ .]+)|
		);
	}

	sub on_slurper_eof {
		print "Tally = ", (my $req_count), "\n";
	}

	sub on_slurper_open_failure {
		my $arg_error;
		print "$arg_error\n";
	}
}

App->new()->run();

__END__

1) poerbook:~/projects/poe-stage% perl -Ilib examples/wide-finder.perl
Tally = 1705

!!! callback leak: at lib/POE/Callback.pm line 321, <GEN0> line 10000.
!!!   POE::Callback=CODE(0x1812b74) = App::on_slurper_line
!!!   POE::Callback=CODE(0x186ed24) = Slurper::on_slurp
!!!   POE::Callback=CODE(0x186f084) = Slurper::on_next_line
!!!   POE::Callback=CODE(0x18da0b4) = App::on_slurper_open_failure
!!!   POE::Callback=CODE(0x18da300) = App::on_slurper_eof
!!!   POE::Callback=CODE(0x18da690) = App::on_run


v
#

#
# Rather than Erlang (as was in here before) this is more based on the
# Scala version of this code at
# http://www.martin-probst.com/2007/09/24/wide-finder-in-scala/
#

#
# requires the data at http://www.tbray.org/tmp/o10k.ap
#

my %count = ();
$|++;

sub main {
    die 'no file' unless -e 'ex/tbray.data';
    Slurp->new( filename => 'ex/tbray.data');
    POE::Kernel->run();
}

{

    package Slurp;
    use MooseX::POE;
    use IO::File;
    has filename => (
        isa => 'Str',
        is  => 'ro',
    );

    my $file;

    sub START {
        $file ||= IO::File->new( $_[0]->filename, 'r' );
        shift->yield('loop');
    }

    sub on_loop {
        my ($self) = @_;
        if ( defined( my $line = <$file> ) ) {
            Count->new->yield( 'loop', $line );
            $self->yield('loop');
            return;
        }
        $self->yield('tally');
    }

    sub on_inc {
        $count{ $_[ARG0] }++;
    }

    sub on_tally {
        print "$count{$_}: $_"
          for sort { $count{$b} <=> $count{$a} } keys %count;
    }

}

{

    package Count;
    use MooseX::POE;

    sub on_loop {
        my ( $self, $sender, $line ) = @_[ OBJECT, SENDER, ARG0 ];
        POE::Kernel->post( $sender => 'inc', $1 )
          if $line =~ qr|GET /ongoing/When/\d\d\dx/(\d\d\d\d/\d\d/\d\d/[^ .]+)|;
    }

}

main();

