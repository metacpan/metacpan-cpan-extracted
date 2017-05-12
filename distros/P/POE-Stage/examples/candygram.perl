#!/usr/bin/env perl
# $Id$

# Example taken from
# http://code2.0beta.co.uk/moose/svn/MooseX-POE/trunk/ex/candygram.pl
# which is based on http://candygram.sourceforge.net/node6.html

{
	package Proc;
	use POE::Stage qw(:base req);

	sub on_init { undef }

	sub on_knock {
		my ($self, $req, $arg_name);
		print "Heard knock from $arg_name\n";
		if ($arg_name eq "candygram") {
			$self->open_door({ name => $arg_name });
		}
		else {
			$self->close_door({ name => $arg_name });
		}
	}

	sub open_door :Handler {
		my $arg_name;
		print "Opening door for $arg_name\n";
		my $req->return(
			type => "hello",
			args => {
				name => $arg_name,
			},
		);
	}

	sub close_door {
		my ($self, $arg) = @_;
		print "Closing door for $arg->{name}\n";
		req()->return(
			type => "go_away",
			args => {
				name => $arg->{name},
			},
		);
	}
}

{
	package App;
	use POE::Stage::App qw(:base);

	sub on_init { undef }

	sub on_run {
		my $req_proc = Proc->new();

		my $req_ls = POE::Request->new(
			stage  => $req_proc,
			method => "knock",
			role => "knock",
			args => {
				name => "landshark"
			},
		);

		my $req_cg = POE::Request->new(
			stage  => $req_proc,
			method => "knock",
			role => "knock",
			args => {
				name => "candygram"
			},
		);
	}

	sub on_knock_hello {
		my $arg_name;
		print "$arg_name delivers candygram.\n";
	}

	sub on_knock_go_away {
		my $arg_name;
		print "$arg_name goes away\n";
	}
}

App->new()->run();

__END__

1) poerbook:~/projects/poe-stage% perl -Ilib candygram.perl
Heard knock from landshark
Closing door for landshark
Heard knock from candygram
Opening door for candygram
landshark goes away
candygram delivers candygram.

!!! callback leak: at lib/POE/Callback.pm line 321.
!!!   POE::Callback=CODE(0x1813978) = App::on_knock_hello
!!!   POE::Callback=CODE(0x1813c3c) = App::on_knock_go_away
!!!   POE::Callback=CODE(0x1813ce4) = App::on_run
!!!   POE::Callback=CODE(0x1814168) = Proc::on_knock
!!!   POE::Callback=CODE(0x1814408) = Proc::open_door
!!!   POE::Callback=CODE(0x1814684) = Proc::close_door
