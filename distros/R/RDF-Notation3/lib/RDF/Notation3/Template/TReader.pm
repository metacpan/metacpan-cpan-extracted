use strict;
#use warnings;

package RDF::Notation3::Template::TReader;

require 5.005_62;
use Carp;

############################################################


sub get {
    my ($self) = @_;

    unless ($self->{tokens}->[0]) {
        $self->_more_tokens;
    }

    return shift @{$self->{tokens}};
}

sub try {
    my ($self) = @_;

    unless ($self->{tokens}->[0]) {
        $self->_more_tokens;
    }

    return $self->{tokens}->[0];
}

sub _more_tokens {
    my ($self) = @_;
    $self->{currentline} = $self->_new_line;
    my $line = \$self->{currentline};

    unless ($$line) {
        push @{$self->{tokens}}, ' EOF ';
        return;
    }
    while (1) {
        last unless $$line;
        my $token;
        if ( $$line =~ /^\"/ ) {
            my $tok = $self->_get_string;
            push @{$self->{tokens}}, $tok;
        }
        elsif ( $$line =~ /^\s+/ ) {
            $$line = $';
        }
	# " is sticked to the previous character, such as ("
        elsif ( $$line =~ /^([^\s\"]+)\"/ ) {
            $$line = '"' . $';
            push @{$self->{tokens}}, $1;
        }
        elsif ( $$line =~ /^(\S+)/ ) {
            $$line = $';
            push @{$self->{tokens}}, $1;
        }
    }
    push @{$self->{tokens}}, ' EOL ';
}

# returns a quoted string to be eval'ed
sub _get_string {
    my $self = shift;
    my $lineref = \$self->{currentline};

    # Handle escaped newlines
    my $have_escaped_newlines = ($$lineref =~ /\\\n$/);

    # Check if it's a python string
    if ( $$lineref =~ /^\"{3}/ ) {
        return $self->_get_triple_quoted_string;
    }

    my @parts = split /\"/, $$lineref;

    # First part should be empty
    shift @parts;

    my $return = "";
    my $part;
    while ( $part = shift @parts ) {
        $return .= $part;
        last unless $return =~ /\\$/;
        $return .= '"';
    }

    # if chewed up everything and not ending in a quote
    if ( @parts == 0 && $$lineref !~ /[^\\]\"$/) {

        # Escaped newlines should be ignored.
        if ( $have_escaped_newlines ) {
            # if there are more lines
            my $line = $self->_new_line(1);
            if ( $line ) {
                # tack them on and try again.
                $$lineref .= $line;
                return $self->_get_string( $lineref );
            }
        }
        $self->_do_error(111, $$lineref);
    }
    $$lineref = join '"', @parts;

    return "\"$return\"";
}

sub _get_triple_quoted_string {
    my $self = shift;
    my $lineref = \$self->{currentline};
    if ( $$lineref =~ /^\"{6}/ ) {
        $$lineref = $';
        return "\"\"";
    }
    elsif ( $$lineref =~ /^\"{3}(.*?[^\\])\"{3}/ ) {
        $$lineref = $';
        my $tok = $1;

        # quote unquoted double quotes
        while ($tok =~ s/(^|[^\\])\"/$1\\\"/ ){}
        return "\"$tok\"";
    }
    my $return = $$lineref;
    my $line = "";
    while ( $line = $self->_new_line(1) ) {
        if ( $line =~ /^((.*?[^\\])?\"{3})/ ) {
            $return .= $1;
            $$lineref = $';

            # remove the surrounding quotes
            $return =~ s/^\"{3}//;
            $return =~ s/\"{3}$//;

            # Handle escaped newlines
            $return =~ s/\\\n//g;

            # quote unquoted double quotes
            while ($return =~ s/(^|[^\\])\"/$1\\\"/ ){}
            return "\"$return\"";
        }
        else {
            $return .= $line;
        }
    }
    # Ran out of lines!
    $self->_do_error(113, $return);
}

sub _do_error {
    my ($self, $n, $tk) = @_;

    my %msg = (
	111 => 'string1 ("...") is not terminated',
	113 => 'string2 ("""...""")is not terminated',
	114 => 'string1 ("...") can\'t include newlines',
	);

    my $msg = "[Error $n]";
    $msg .= " line $self->{ln}, token" if $n > 100;
    $msg .= " \"$tk\"\n";
    $msg .= "$msg{$n}!\n";
    croak $msg;
}

1;

__END__
# Below is a documentation.

=head1 NAME

RDF::Notation3::Template::TReader - RDF Notation3 file reader template

=head1 LICENSING

Copyright (c) 2001 Ginger Alliance. All rights reserved. This program is free 
software; you can redistribute it and/or modify it under the same terms as 
Perl itself. 

=head1 AUTHOR

Petr Cimprich, petr@gingerall.cz

=head1 SEE ALSO

perl(1), RDF::Notation3.

=cut

