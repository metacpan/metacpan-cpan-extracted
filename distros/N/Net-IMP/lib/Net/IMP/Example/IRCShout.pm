use strict;
use warnings;

package Net::IMP::Example::IRCShout;
use base 'Net::IMP::Base';
use fields (
    'pos',   # current position in stream
    'line',  # buffer for unfinished lines
);

use Net::IMP; # import IMP_ constants
use Net::IMP::Debug;
use Carp 'croak';

sub INTERFACE {
    return ([
	IMP_DATA_STREAM,
	[ IMP_PASS, IMP_REPLACE ]
    ])
}


# create new analyzer object
sub new_analyzer {
    my ($factory,%args) = @_;
    my $self = $factory->SUPER::new_analyzer(%args);

    $self->run_callback(
	# we are not interested in data from server
	[ IMP_PASS, 1, IMP_MAXOFFSET ],
    );

    $self->{line} = '';
    $self->{pos} = 0;
    return $self;
}

sub data {
    my ($self,$dir,$data) = @_;
    return if $dir == 1; # should not happen
    if ( $data eq '' ) {
	# eof
	$self->run_callback([ IMP_PASS,0,IMP_MAXOFFSET ]);
	return;
    }

    $self->{line} .= $data;

    my @rv;
    while ( $self->{line} =~s{\A([^\n]*\n)}{} ) {
	my $line = $1;
	$self->{pos} += length($line);
	if ( shout(\$line)) {
	    if ( @rv and $rv[-1][0] == IMP_REPLACE ) {
		# update last replacement
		$rv[-1][2] = $self->{pos};
		$rv[-1][3].= $line;
	    } else {
		# add new replacement
		push @rv, [ IMP_REPLACE,0,$self->{pos},$line ];
	    }
	} else {
	    if ( @rv and $rv[-1][0] == IMP_PASS ) {
		# update last pass
		$rv[-1][2] = $self->{pos};
	    } else {
		# add new pass
		push @rv, [ IMP_PASS,0,$self->{pos} ];
	    }
	}
    }
    $self->run_callback(@rv) if @rv;
}


sub shout {
    my $line = shift;
    return $$line =~s{\A
	(
	    (?: :\S+\x20+ )?      # opt msg prefix
	    PRIVMSG\x20+\S+\x20+  # privmsg rcpt
	)
	(.+)                      # message
    }{$1\U$2}x                    # shout message
}

1;

__END__

=head1 NAME

IRCShout - make IRC shout to others

=head1 DESCRIPTION

This plugins makes the message from all IRC PRIVMSG commands upper case.

=head1 AUTHOR

Steffen Ullrich <sullr@cpan.org>
