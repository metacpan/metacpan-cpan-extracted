###########################################
package Net::SSH::AuthorizedKey::SSH1;
###########################################
use strict;
use warnings;
use Net::SSH::AuthorizedKey::Base;
use base qw(Net::SSH::AuthorizedKey::Base);
use Log::Log4perl qw(:easy);

our @REQUIRED_FIELDS = qw(
    keylen exponent
);

__PACKAGE__->make_accessor( $_ ) for @REQUIRED_FIELDS;

  # No additional options, only global ones
our %VALID_OPTIONS = ();

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    return $class->SUPER::new( %options, type => "ssh-1" );
}

###########################################
sub key_read {
############################################
    my($class, $line) = @_;

    if($line !~ s/^(\d+)\s*//) {
        DEBUG "Cannot find ssh-1 keylen";
        return undef;
    }

    my $keylen = $1;
    DEBUG "Parsed keylen: $keylen";

    if($line !~ s/^(\d+)\s*//) {
        DEBUG "Cannot find ssh-1 exponent";
        return undef;
    }

    my $exponent = $1;
    DEBUG "Parsed exponent: $exponent";

    if($line !~ s/^(\d+)\s*//) {
        DEBUG "Cannot find ssh-1 key";
        return undef;
    }

    my $key = $1;
    DEBUG "Parsed key: $key";

    my $obj = __PACKAGE__->new();
    $obj->keylen( $keylen );
    $obj->key( $key );
    $obj->exponent( $exponent );
    $obj->email( $line );
    $obj->comment( $line );

    return $obj;
}

###########################################
sub as_string {
###########################################
    my($self) = @_;

    my $string = $self->options_as_string();
    $string .= " " if length $string;

    $string .= "$self->{keylen} $self->{exponent} $self->{key}";
    $string .= " $self->{email}" if length $self->{email};

    return $string;
}

###########################################
sub sanity_check {
###########################################
    my($self) = @_;

    for my $field (@REQUIRED_FIELDS) {
        if(! length $self->$field()) {
            WARN "ssh-1 sanity check failed '$field' requirement";
            return undef;
        }
    }

    return 1;
}

###########################################
sub option_type {
###########################################
    my($self, $option) = @_;

    if(exists $VALID_OPTIONS{ $option }) {
        return $VALID_OPTIONS{ $option };
    }

    return undef;
}

1;

__END__

=head1 NAME

Net::SSH::AuthorizedKey::SSH1 - Net::SSH::AuthorizedKey subclass for ssh-1

=head1 DESCRIPTION

See Net::SSH::AuthorizedKey.

=head1 LEGALESE

Copyright 2005 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2005, Mike Schilli <m@perlmeister.com>
