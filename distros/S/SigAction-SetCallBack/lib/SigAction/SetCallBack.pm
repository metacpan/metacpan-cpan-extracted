package SigAction::SetCallBack;

use strict;
use warnings;

our $VERSION = '0.01';

use POSIX qw();
    
    # sa_mask manager
    $SigAction::SetCallBack::SA_MASK = 'SA_NODEFER';     
    sub set_sa_mask {
        my ($class,$new_sa_mask) = @_;
        my $change = 0;
        no strict 'refs';
        if (defined "POSIX::${new_sa_mask}") {
            $SigAction::SetCallBack::SA_MASK = $new_sa_mask;
            $change++;
        }
        use strict 'refs';
        $change;
    }

    # stack callbacks storage
    my $sig_action_table = {};
 
    # registry callback for signal
    sub sig_registry {
        my ($class,$sig,$func) = @_;
        return 0 unless ($sig and $func); 
        my ($package) = caller;
        if (ref $func ne 'CODE') {
            # only exists method for callback
            return 0 unless $package->can($func);
            no strict 'refs';
            $func = \&{$package.'::'.$func};
            use strict 'refs';
        };
        
        ($sig = uc($sig)) =~ s/^SIG//;   
        my $bad_sig = 0;
        no strict 'refs';
        $bad_sig++ unless defined "POSIX::SIG$sig"->();
        use strict 'refs';
        return 0 if $bad_sig;
        
        unless (exists $sig_action_table->{$sig}) {
            no strict 'refs';    
            my $action = POSIX::SigAction->new(
                                       \&_sigaction,
                                       POSIX::SigSet->new(),
                                       "POSIX::${SigAction::SetCallBack::SA_MASK}"->()
            );
            POSIX::sigaction("POSIX::SIG$sig"->(), $action);    
            use strict 'refs';          
        }
         
        push @{$sig_action_table->{$sig}->{$package}},$func;
        
        return 1;
    }

   # action for any signal
   sub _sigaction {
       my ($sig) = @_;
       foreach my $pckg (keys %{$sig_action_table->{$sig}}) {
            map {
                $_->($pckg);    
            } @{$sig_action_table->{$sig}->{$pckg}}
       };       
   }

1;
__END__

=encoding utf-8

=head1 NAME

B<SigAction::SetCallBack> - set several callbacks for any signal

I<Version 0.01>

=head1 SYNOPSIS

Example:

	#!/usr/bin/perl
	use strict;
	use warnings;
	
	use SigAction::SetCallBack;
	
	package Foo;
	
	sub my_hup_callback {
	    my ($class) = @_;
	    print "$class: HUP signal recieved in my_hup_callback!\n";
	}
	SigAction::SetCallBack->sig_registry('HUP',\&my_hup_callback);
	
	
	sub my_anoter_hup_callback {
	    my ($class) = @_;
	    print "$class: HUP signal recieved in my_anoter_hup_callback!\n";
	}
	SigAction::SetCallBack->sig_registry('HUP','my_anoter_hup_callback');
	
	1; # ---------------
	
	package Bar;
	
	sub some_int_action {
	    my ($class) = @_;
	    print "$class: INT (Ctrl+C) signal recieved in some_int_action!\n";
	}
	SigAction::SetCallBack->sig_registry('INT',\&some_int_action);
	
	1; # ---------------
	
	package main; 
	
	kill HUP => $$;
	kill INT => $$;
	
	exit;
	
	# Output:
	# Foo: HUP signal recieved in my_hup_callback!
	# Foo: HUP signal recieved in my_anoter_hup_callback!
	# Bar: INT (Ctrl+C) signal recieved in some_int_action!


=head1 DESCRIPTION

Sometimes there is a need to define several callbacks in different packages.

Generally, we override value the %SIG hash. And if definition different action for signal in (may be different) packages,
will be called only the last callback.

SigAction::SetCallBack allows you to create the call stack.
The order of packets, which define the callbacks will not be respected.
On the other hand, will be complied with the procedure for determining the callbacks within the package, and all callbacks will work.

This package uses the POSIX.

=head1 METHODS

=head3 sig_registry($sig,$cb)

Register a callback stack storadge.
B<sig_registry> preserves the procedures order for registering callbacks within each package.

C<$sig> - short name of the signal (ie, 'INT', 'HUP'). 
Do not use the full names of signals such as SIGINT, SIGHUP. 
Full list of signals, that supports your system, you can see by calling the command C<kill -l> in shell.

C<$cb> - is the name of a class method for a callback or a reference to it.
The first argumets, who will receive the callback is the name of the class.

Returns true if successful.

=head3 set_sa_mask($new_sa_mask)

This method overrides the flag which can affect the behavior of the process in the processing of the signal. 
By default, this is 'SA_NODEFER'.

=over 4

=item *

C<SA_NOMASK> or C<SA_NODEFER> - do not interfere with the signal at its processing.

=item *

C<SA_NOCLDSTOP> - if signum is SIGCHLD, then a notice to stop the child process will not be received.

=item *

C<SA_ONESHOT> or C<SA_RESETHAND> - restore behavior of the signal after a one call handler. 

=item *

C<SA_ONSTACK> - call the signal handler stack additional signals provided by sigaltstack (2). If the additional stack is not available, then the stack will be used by default.

=item *

C<SA_RESTART> - the behavior must conform to the semantics of BSD signals and allow some system calls work, while being processed signals.

=item *

C<SA_SIGINFO>

=back

Returns true if successful.

=head1 SEE ALSO

=over 4

=item *

C<POSIX>

=back

=head1 AUTHOR

Ivan Sivirinov

=cut
