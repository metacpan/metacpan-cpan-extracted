package POEIKC::Daemon::Utility;

use strict;
use 5.008_001;

use warnings;
use Data::Dumper ();

use Class::Inspector;
use UNIVERSAL::require;
use POE::Sugar::Args;

our $DEBUG;

sub DEBUG {
	my $self = shift;
	$DEBUG = shift if @_;;
}

sub _new {
    my $class = shift ;
    my $self = {
        @_
        };
    $class = ref $class if ref $class;
    bless  $self,$class ;
    return $self ;
}


sub inc {shift->{inc}}
sub state_list {shift->{state_list}}

sub _init {
	my $self = shift;
	$self->{inc} = {};
	$self->{state_list} = {};
}



sub shutdown {
	my $self = shift;
	my %args = @_;
	my ($poe, $rsvp, $from, $args) = (
		$args{poe}, $args{rsvp}, $args{from}, $args{args} );
	my ($alias, $event_ary) = ($args{alias}, $args{event});

	$poe->kernel->yield('shutdown');
	return sprintf("%s PID:%s ... stopped!! (%s)\n", $0, $$, scalar(localtime));
}

### loop, relay, chain vvvvvvvvvvvvvvvvvvvvvvvvv
package POEIKC::Daemon::State;

use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw/event_name next_mthod destination module method module_delay/);

sub new {
	my $class = shift ;
	my %args = @_;
	my $self = $class->SUPER::new(\%args);
	$self->{limit} = $args{limit};
	return $self ;
}


package POEIKC::Daemon::Utility;


sub stop{
	my $self = shift;
	my %args = @_;
	my ($poe, $rsvp, $from, $args) = (
		$args{poe}, $args{rsvp}, $args{from}, $args{args} );
	my $kernel = $poe->kernel;
	my ($something, $method, @args) = @{$args} if ref $args eq 'ARRAY';
	$something ||= $args{something};

	$self->state_list->{$something} or return;

	if (ref $self->state_list->{$something} eq 'HASH') {
		my $event_name = $self->state_list->{$something}->event_name;
		$DEBUG and _DEBUG_log( $event_name, $something);
		$kernel->state( $event_name );
		if ($method) {
			my $destination = $self->state_list->{$something}->destination;
			my $module = $self->state_list->{$something}->module;
			$DEBUG and _DEBUG_log($self->state_list->{$something}, $event_name, $something, $destination, $module, $method, @args);
			$DEBUG and _DEBUG_log($destination, $module, $method, @args);
			return $self->execute(poe=>$poe, from=>$destination, module=>$module, method=>$method, args=>\@args);
		}
		delete $self->state_list->{$something};
		return $event_name;
	}
}


sub loop {
	my $self = shift;
	my %args = @_;
	my ($poe, $rsvp, $from, $args) = (
		$args{poe}, $args{rsvp}, $args{from}, $args{args} );
	my $kernel = $poe->kernel;

	$DEBUG and _DEBUG_log($args);

	my $limit = shift @{$args} if ($args->[0] and $args->[0] =~ /^\d+$/);

	my $func_full_name = $args->[0] || return;
	$DEBUG and _DEBUG_log("func_full_name=>"=>$func_full_name);
	$DEBUG and _DEBUG_log($args);

	my $destination;
	($destination, $args) = $self->_distinguish(poe=>$poe, args=>$args);
	my $module = shift @{$args};
	my $method = shift @{$args};
	$DEBUG and _DEBUG_log("module=>"=>$module);

	$self->use(module=>$module) or return $@;

	my $module_delay = '\$'."${module}::delay";
	$module_delay = eval $module_delay;

	my $event_name = join "_" => $module =~ /(\w+)/, $method, 'loop';
	$DEBUG and _DEBUG_log($event_name);

	if ($func_full_name) {
		$self->state_list->{$func_full_name} =
			POEIKC::Daemon::State->new(
				event_name	=>$event_name,
				next_mthod	=>'',
				limit	=>$limit,
				destination	=>$destination,
				module	=>$module,
				method	=>$method,
				module_delay	=>$module_delay
			);
		$kernel->state( $event_name , sub {
				my @args = @_[POE::Session::ARG0() ..$#_];
				$DEBUG and _DEBUG_log(@args);
				if ($limit and not $self->state_list->{$func_full_name}->{limit}) {
					$self->stop(poe=>$poe, something=>$func_full_name, );
					return;
				}
				my @re_args = $self->execute(
					poe=>$poe, from=>$destination, module=>$module, method=>$method, args=>\@args
				);

				my $delay = ${$self->state_list->{$func_full_name}->module_delay};
				$DEBUG and _DEBUG_log($delay);
				$delay ?
				$kernel->delay($event_name => $delay, @re_args) :
				$kernel->yield($event_name, @re_args);

				$self->state_list->{$func_full_name}->{limit}-- if ($limit);
			}
		);
		$kernel->yield($event_name, @{$args});
		return $event_name;
	}else{
		return;
	}
}


sub relay #{}
{
	my $self = shift;
	my %args = @_;
	my ($poe, $rsvp, $from, $args) = (
		$args{poe}, $args{rsvp}, $args{from}, $args{args} );
	my $kernel = $poe->kernel;

	$DEBUG and _DEBUG_log($args);

	my $something = $args->[0] || return;

	my $destination;
	($destination, $args) = $self->_distinguish(poe=>$poe, args=>$args);
	my $module = shift @{$args};
	my $method = $args->[0];

	$self->use(module=>$module) or return $@;

	my $module_delay = '\$'."${module}::delay";
	$module_delay = eval $module_delay;

	my $event_name = join "_" => $module =~ /(\w+)/, $method, 'relay';

	$DEBUG and _DEBUG_log($event_name, $something);

	if ($something) {
		$self->state_list->{$something} =
			POEIKC::Daemon::State->new(
				event_name=>$event_name,
				next_mthod=>'',
				destination=>[$destination, $module, $method],
				module_delay	=>$module_delay
			);
		$kernel->state( $event_name , sub {
				my @args = @_[POE::Session::ARG0() ..$#_];
				$DEBUG and _DEBUG_log(\@args);
				my $method = shift @args;
				$DEBUG and _DEBUG_log( from=>$destination, module=>$module, method=>$method, args=>\@args);
				my @re_args = $self->execute(poe=>$poe, from=>$destination, module=>$module, method=>$method, args=>\@args);
				$DEBUG and _DEBUG_log(@re_args);
				my $delay = shift @re_args if ($re_args[0] and not(ref $re_args[0]) and $re_args[0] =~ /^\d+$/);
				my $next_mthod = $re_args[0] if ($re_args[0] and not(ref $re_args[0]) and $re_args[0] =~ /^\w+/);

				(not $next_mthod) ?
					$self->stop(poe=>$poe, something=>$something,) :
				$delay ?
					$kernel->delay($event_name => $delay, @re_args ) :
					$kernel->yield($event_name, @re_args ) ;
			}
		);
		$kernel->yield($event_name => @{$args});
		return $event_name;
	}else{
		return;
	}
}

sub chain #{}
{
	my $self = shift;
	my %args = @_;
	my ($poe, $rsvp, $from, $args) = (
		$args{poe}, $args{rsvp}, $args{from}, $args{args} );
	my $kernel = $poe->kernel;

	$DEBUG and _DEBUG_log($args);

	my $something = $args->[0] || return;

	my $destination;
	($destination, $args) = $self->_distinguish(poe=>$poe, args=>$args);
	my $module = shift @{$args};
	my $method = shift @{$args};
	my @next_mthod = split /,/ => shift @{$args};
	unshift @next_mthod , $method;

	$self->use(module=>$module) or return $@;

	my $module_delay = '\$'."${module}::delay";
	$module_delay = eval $module_delay;

	my $event_name = join "_" => $module =~ /(\w+)/, $method, 'chain';

	$DEBUG and _DEBUG_log($event_name, $something);

	if ($something) {
		$self->state_list->{$something} =
			POEIKC::Daemon::State->new(
				event_name=>$event_name,
				next_mthod=>\@next_mthod,
				pointer=>0,
				destination=>[$destination, $module, $method],
				module_delay	=>$module_delay
			);
		$kernel->state( $event_name , sub {
				my @args = @_[POE::Session::ARG0() ..$#_];
				$DEBUG and _DEBUG_log(\@args);
				my $pointer = $self->state_list->{$something}->{pointer};
				my $method = $self->state_list->{$something}->{next_mthod}->[$pointer];
				my @re_args = $self->execute(poe=>$poe, from=>$destination, module=>$module, method=>$method, args=>\@args);
				$self->state_list->{$something}->{pointer}++;
				($pointer >= $#{$self->state_list->{$something}->{next_mthod}})
					?
					$self->stop(poe=>$poe, something=>$something,) :
					$kernel->yield($event_name, @re_args ) ;
			}
		);
		$kernel->yield($event_name => @{$args});
		return $event_name;
	}else{
		return;
	}
}



### exec vvvvvvvvvvvvvvvvvvvvvvvvv

sub execute {
	my $self = shift;
	my %args = @_;
	my ($poe, $rsvp, $from, $args) = (
		$args{poe}, $args{rsvp}, $args{from}, $args{args} );
	my ($module, $method) = ( $args{module}, $args{method} );
	my $kernel = $poe->kernel if $poe;
	#_DEBUG_log(wantarray);
	for ($from) {
		/^method/	and return eval {
				$DEBUG and _DEBUG_log("$module->$method( @{$args} )");
				$module->$method( @{$args} )
				} ;
		/^event/	and return eval {
				local $! = undef;
				$DEBUG and _DEBUG_log("call( $module => $method, @{$args} )");
				$kernel->call( $module => $method, @{$args} )or return $!
				} ;
		/^function/	and return eval {
				no strict 'refs';
				my $code = "${module}::$method";
				$DEBUG and _DEBUG_log($code);
				$DEBUG and _DEBUG_log("$code(@{$args})");
				$code = *{$code};
				$DEBUG and _DEBUG_log("defined($code) ?=>"=>defined(&$code));
				$code->( @{$args} );
				};
	}
	return {poeikcd_error=>
				'It is not discriminable. '.
				q{"ModuleName::functionName" or  "ClassName->methodName" or "AliasName eventName"}
			}
}

### get vvvvvvvvvvvvvvvvvvvvvvvvv

sub get_A_INC { return \@INC }
sub get_H_INC { return \%INC }
sub get_H_ENV { return \%ENV }
sub get_pid { return $$ }
sub get_VERSION { return $POEIKC::Daemon::VERSION }

sub get_stay {
	my $self = shift;
	return $self->inc->{stay};
}

sub get_load {
	my $self = shift;
	return $self->inc->{load};
}

sub get_session_alias_list {
  POE::API::Peek->use or return $@;
  my $api = POE::API::Peek->new;
  my %alias;
	for ($api->session_list()){
		my $id = $_->ID;
		my @list = $api->session_alias_list($_);
		$alias{$id} = (1 == @list) ? shift @list : \@list;
		#$DEBUG and _DEBUG_log( @list );
	}
	return \%alias;
}

sub get_session_id_list {
  POE::API::Peek->use or return $@;
  my $api = POE::API::Peek->new;
  my @list = $api->session_list();
		$DEBUG and _DEBUG_log( @list );
	@list = map {$_->ID} @list;
	return \@list;
}

sub get_poe_api_peek {
	my $self = shift;
	my %args = @_;
	my ($poe, $rsvp, $from, $args) = (
		$args{poe}, $args{rsvp}, $args{from}, $args{args} );
  POE::API::Peek->use or return $@;
  my $subname = shift @{$args{args}} || return;
  my $api = POE::API::Peek->new;
  my @list = $api->$subname(@{$args{args}});
	$DEBUG and _DEBUG_log( @list );
	return \@list;
}

sub get_methods {
	my $self = shift;
	my %args = @_;
	my ($poe, $rsvp, $from, $args) = (
		$args{poe}, $args{rsvp}, $args{from}, $args{args} );
	my $module = shift @{$args{args}} or return;
	return Class::Inspector->methods($module);
}

sub get_Class_Inspector {
	my $self = shift;
	my %args = @_;
	my ($poe, $rsvp, $from, $args) = (
		$args{poe}, $args{rsvp}, $args{from}, $args{args} );
	my $module = shift @{$args{args}} or return;
	return not(@{$args}) ? Class::Inspector->methods('Class::Inspector') : do {
		my $method = shift @{$args};
		Class::Inspector->$method($module);
	};
}

sub get_object_something {
	my $self = shift;
	my %args = @_;
	my $poe = $args{poe};
	my ($something) = @{$args{args}};
	return $poe->object->{$something}; # ikc_self_port alias;
}

### INC vvvvvvvvvvvvvvvvvvvvvvvvv

sub unshift_INC {
	my $self = shift;
	my %args = @_;
	my ($poe, $rsvp, $from, $args) = (
		$args{poe}, $args{rsvp}, $args{from}, $args{args} );
	for( @{$args{args}} ){
		unshift @INC, map {m'\$' and do{ $_= eval qq{"$_"}} ;s/~/$ENV{HOME}/;$_} split /:/ => $_;
	}
	my %inc;
	@INC = grep {
		$inc{$_} ? () : do{$inc{$_}++;$_};
	}  @INC;
	return \@INC;
}

sub reset_INC {
	my $self = shift;
	my %args = @_;
	my ($poe, $rsvp, $from, $args) = (
		$args{poe}, $args{rsvp}, $args{from}, $args{args} );
	my $path = shift @{$args{args}};
	@INC = @POEIKC::Daemon::inc;
	return \@INC;
}

sub delete_INC {
	my $self = shift;
	my %args = @_;
	my ($poe, $rsvp, $from, $args) = (
		$args{poe}, $args{rsvp}, $args{from}, $args{args} );
	my $path = shift @{$args{args}};
	@INC = grep {$_ ne $path} @INC;
	return \@INC;
}

sub use {
	my $self = shift;
	my %args = @_;
	my ($poe, $rsvp, $from, $module, $args) = (
		$args{poe}, $args{rsvp}, $args{from}, $args{module}, $args{args} );
	$module ||=  shift @{$args{args}} or return;
	return Class::Inspector->loaded( $module ) ? 1 : do{
		$module->use() or return ;
		$self->inc->{load}->{ $module } = [$INC{Class::Inspector->filename($module)},scalar localtime] ;
		1;
	}? 1 : ();
}



sub stay {
	my $self = shift;
	my %args = @_;
	my ($poe, $rsvp, $from, $module, $args) = (
		$args{poe}, $args{rsvp}, $args{from}, $args{module}, $args{args} );
	$module ||= shift @{$args{args}} or return;
	$self->inc->{stay}->{$module} ||= time;
	return $self->inc->{stay};
}


sub reload {
	my $self = shift;
	my %args = @_;
	my ($poe, $rsvp, $from, $args) = (
		$args{poe}, $args{rsvp}, $args{from}, $args{args} );
	my $module = shift @{$args{args}} or return;

	my @deletelist;

	if (not $self->inc->{stay}->{$module} and $module ne __PACKAGE__) {
		no warnings;
		for ( sort keys %INC ){
			next if $self->inc->{org_inc}->{$_} ;
			next if $self->inc->{stay}->{$_};
			push @deletelist, delete $INC{$_};
		}
		{no strict 'refs';%{"${module}::"}=();}
		delete $self->inc->{load}->{$module};
	}

	if( @{$args} >= 1) {
		unshift @{$args}, $module;
		$DEBUG and _DEBUG_log($rsvp, $args);
		$poe->kernel->call($poe->session => execute_respond => $from, $args, $rsvp )
			or return $!;
		$rsvp->{responded} = (caller(0))[3];
	}else{
		return \@deletelist;
	}
}

### eval vvvvvvvvvvvvvvvvvvvvvvvvv

sub eval {
	my $self = shift;
	my %args = @_;
	my $args = $args{args};

	my $expr = (ref $args eq 'ARRAY') ? shift @{$args} : $args;

	$DEBUG and _DEBUG_log($expr);

	return eval $expr || $@;
}


### IKC vvvvvvvvvvvvvvvvvvvvvvvvv

sub publish_IKC {
	my $self = shift;
	my %args = @_;
	my ($poe, $rsvp, $from, $args) = (
		$args{poe}, $args{rsvp}, $args{from}, $args{args} );
	my ($alias, $event_ary) = ($args{alias}, $args{event});
	if (not($alias) and not($event_ary) and ($args)){
		$alias = shift @{$args};
		my $flag_packagename_or_eventlist = shift @{$args};
		$event_ary = $flag_packagename_or_eventlist =~ /^_list$/i ? $args : do{
			Class::Inspector->methods($flag_packagename_or_eventlist);
		};
	}
	$DEBUG and _DEBUG_log( $alias, $event_ary);
	return  if (not($alias) or not($event_ary));
	return $poe->kernel->call(IKC =>publish => $alias, $event_ary) || $!;
}



###

sub _distinguish {
	my $self = shift;
	my %args = @_;
	my ($poe, $rsvp, $from, $args) = (
		$args{poe}, $args{rsvp}, $args{from}, $args{args} );
	my $kernel = $poe->kernel;

	$DEBUG and _DEBUG_log($args);

	my $something ;
	my ($module, $method);
	{
		$kernel->alias_list($args->[0]) and do {
			# event_respond
			$module = shift @{$args};
			$method = shift @{$args};
			$module or last; $method or last;
			#keys $self->pidu->inc->{load}
			unshift @{$args}, $module, $method;
			return ('event', $args);
		};
		$args->[0] =~ /->/ and do {
			# method_respond
			$module = $`;
			$method = $';
			$module or last; $method or last;
			shift @{$args};
			unshift @{$args}, $module, $method;
			return ('method', $args);
		};
		$args->[0] =~ /::(\w+)$/ and do {
			# function_respond
			$module = $`;
			$method = $1;
			$module or last; $method or last;
			shift @{$args};
			unshift @{$args}, $module, $method;
			return ('function', $args);
		};
	}
	$DEBUG and _DEBUG_log();
	return
}

### DEBUG vvvvvvvvvvvvvvvvvvvvvvvvv

sub _DEBUG_log {
	$DEBUG or return;
	Date::Calc->use or return(warn($@));
	#YAML->use or return;
	my ($pack, $file, $line, $subroutine) = caller(0);
	my $levels_up = 0 ;
	($pack, $file, $line, ) = caller($levels_up);
	$levels_up++;
	(undef, undef, undef, $subroutine, ) = caller($levels_up);
	{
		(undef, undef, undef, $subroutine, ) = caller($levels_up);
		if(defined $subroutine and $subroutine eq "(eval)") {
		    $levels_up++;
		    redo;
		}
		$subroutine = "main::" unless $subroutine;
	}
	my $log_header = sprintf "[DEBUG %04d/%02d/%02d %02d:%02d:%02d %s %d %s %d %s] - ",
			Date::Calc::Today_and_Now() , $ENV{HOSTNAME}, $$, $file, $line, $subroutine;
	my @data = @_;
	print(
		$log_header, (join "\t" => map {
			ref($_) ? Data::Dumper::Dumper($_) :
			defined $_ ? $_ : "`'" ;
		} @data ),"\n"
	);
}

sub _log_header {
	Date::Calc->use or return;
	my ($pack, $file, $line, $subroutine) = caller(0);
	my $levels_up = 0 ;
	($pack, $file, $line, ) = caller($levels_up);
	$levels_up++;
	(undef, undef, undef, $subroutine, ) = caller($levels_up);
	{
		(undef, undef, undef, $subroutine, ) = caller($levels_up);
		if(defined $subroutine and $subroutine eq "(eval)") {
		    $levels_up++;
		    redo;
		}
		$subroutine = "main::" unless $subroutine;
	}
	return sprintf "[DEBUG %04d/%02d/%02d %02d:%02d:%02d %s %d %s %d %s] - ",
			Date::Calc::Today_and_Now() , $ENV{HOSTNAME}, $$, $file, $line, $subroutine;
}

1;

__END__

=head1 NAME

POEIKC::Daemon::Utility - Utility for POEIKC::Daemon

=head1 SYNOPSIS

	$ret = $ikc->post_respond('POEIKCd/method_respond' =>
		['POEIKC::Daemon::Utility'=> $method_name, $args ..] );
	print Dumper $ret;

=head1 DESCRIPTION

POEIKC::Daemon::Utility is Utility for POEIKC::Daemon

=head1 AUTHOR

Yuji Suzuki E<lt>yujisuzuki@mail.arbolbell.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<POEIKC::Daemon>

=cut

