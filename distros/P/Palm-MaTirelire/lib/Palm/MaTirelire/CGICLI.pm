=encoding iso-8859-1

=cut

#
# Copyright (C) 2005, Maxime Soulé
# You may distribute this file under the terms of the Artistic
# License, as specified in the README file.
#

package Palm::MaTirelire::CGICLI;

use strict;

our $VERSION = '1.0';

our $AUTOLOAD;

#
# -cgiopt value will be passed to use CGI qw(XXX)
# -cgicode value will be executed just after use CGI; statement
# -cginew value will be passed to the CGI new method
sub new
{
    my $class = shift;
    my $self = {};
    my %args = @_;

    bless $self, $class;

    # We are in a CGI
    if ($self->probe_cgi)
    {
	$args{-cgiopt} = exists($args{-cgiopt}) ? " qw($args{-cgiopt})" : '';
	$args{-cgicode} = '' unless exists $args{-cgicode};
	$args{-cginew} = exists($args{-cginew}) ? "($args{-cginew})" : '';

	$self->{cgi} = eval <<EOFCGI;
use CGI$args{-cgiopt};
$args{-cgicode};
new CGI$args{-cginew};
EOFCGI
    }
    # We are on CLI
    else
    {
	$self->{cli} = {};
	$self->getCliArgs(@ARGV);
    }

    return $self;
}


sub getCliArgs
{
    my($self, @args) = @_;

    return if $self->{cgi};

    for (my $index = 0; $index < @args; $index++)
    {
	my $arg = $args[$index];

	if ($arg =~ s/^--?//)
	{
	    # Case -key=value
	    if ($arg =~ /^([^=]+)=(.*)/)
	    {
		$self->{cli}{$1} = $2;
	    }
	    # Case -key value1 value2 value3  OR  -boolkey1 -nextopt
	    else
	    {
		my @values;

		for (my $val_idx = $index + 1; ; $val_idx++)
		{
		    # End of args OR new option
		    if ($val_idx >= @args or $args[$val_idx] =~ /^-/)
		    {
			$index = $val_idx - 1;
			last;
		    }

		    push(@values, $args[$val_idx]);
		}

		$self->{cli}{$arg} = @values ? (@values == 1
						? $values[0]
						: \@values) : 1;
	    }
	}
	else
	{
	    print STDERR "Unrecognised option: `$arg'\n";
	}
    }
}


sub saveCliArgs
{
    my($self, $file) = @_;

    return if $self->{cgi};

    open(ARGS, '>', $file) or die "Can't save CLI args: $!\n";

    while (my($param, $value) = each %{$self->{cli}})
    {
	print ARGS $param, "\n";

	if (not defined $value)
	{
	    print ARGS "0\n";
	}
	elsif (ref $value)
	{
	    print ARGS join("\n", @$value), "\n";
	}
	else
	{
	    print ARGS $value, "\n";
	}
    }

    close ARGS;
}


sub loadCliArgs
{
    my($self, $file) = @_;

    return if $self->{cgi};

    my @args;

    open(ARGS, '<', $file) or die "Can't open CLI args: $!\n";

    while (defined(my $line = <ARGS>))
    {
	chomp($line);
	push(@args, $line);
    }

    close ARGS;

    $self->getCliArgs(@args);
}

#
# Used to detect whether we are on CLI or CGI
sub probe_cgi
{
    return exists $ENV{SERVER_NAME};
}


#
# The CGI object, can be used to know in which case we are
sub cgi
{
    return shift->{cgi};
}


#
# Only used on CGI side
sub header
{
    my $self = shift;

    if ($self->{cgi})
    {
	$self->{cgi}->header(@_);
    }
}


sub param
{
    my $self = shift;

    #
    # CGI
    #
    return $self->{cgi}->param(@_) if $self->{cgi};

    #
    # CLI
    #

    return keys %{$self->{cli}} if @_ == 0;

    my($param_name, $set, $value);
    if (@_ == 1)
    {
	$param_name = $_[0];
    }
    else
    {
	if ($_[0] =~ /^-(name|value)\z/ and @_ % 2 == 0)
	{
	    my %args = @_;

	    if (exists $args{-name})
	    {
		$param_name = $args{-name};

		if (exists $args{-value})
		{
		    $set = 1;
		    $value = $args{-value};
		}
	    }
	    else
	    {
		goto normal_way;
	    }
	}
	else
	{
	  normal_way:
	    $param_name = shift;

	    $set = 1;

	    $value = @_ == 1 ? $_[0] : [ @_ ];
	}
    }

    # SET
    $self->{cli}{$param_name} = $value if $set;

    if (wantarray and ref($self->{cli}{$param_name}) eq 'ARRAY')
    {
	return @{$self->{cli}{$param_name}};
    }

    return $self->{cli}{$param_name};
}


sub upload
{
    my $self = shift;

    #
    # CGI
    #
    return $self->{cgi}->upload(@_) if $self->{cgi};

    #
    # CLI
    #
    my @params = wantarray ? @_ : ($_[0]);

    foreach my $param (@params)
    {
	if (exists $self->{cli}{$param})
	{
	    if (open(my $fh, '<', $self->{cli}{$param}))
	    {
		$param = $fh;
	    }
	    else
	    {
		$param = undef;
	    }
	}
	else
	{
	    $param = undef;
	}
    }

    return wantarray ? @params : $params[0];
}


sub cgi_error
{
    my $self = shift;

    return $self->{cgi}->cgi_error if $self->{cgi};

    # No upload error possible in CLI
    return 0;
}


sub AUTOLOAD
{
    my $self = shift;

    #
    # CGI
    $self->{cgi}->$AUTOLOAD(@_) if $self->{cgi};

    #
    # CLI
    # Ignore message...
}

1;
__END__

=head1 NAME

Palm::MaTirelire::CGICLI - Allow to make shell scripts that can be CGIs too

=head1 SYNOPSIS

  use Palm::MaTirelire::CGICLI;

=head1 DESCRIPTION

The Palm::MaTirelire::CGICLI module allow to make shell scripts that
can be CGIs too.

To be done XXX...

=head1 SEE ALSO

tools directory in the Palm::Matirelire distribution.

=head1 AUTHOR

Maxime Soulé, E<lt>max@Ma-Tirelire.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Maxime Soulé

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
