###########################################
package Net::SSH::AuthorizedKey::SSH2;
###########################################
use strict;
use warnings;
use Net::SSH::AuthorizedKey::Base;
use base qw(Net::SSH::AuthorizedKey::Base);
use Log::Log4perl qw(:easy);

  # No additional options, only global ones
our %VALID_OPTIONS = ();

our $KEYTYPE_REGEX = qr/rsa|dsa|ssh-rsa|ssh-dss|ssh-ed25519|ecdsa-\S+/;

our @REQUIRED_FIELDS = qw(
    encryption
);

__PACKAGE__->make_accessor( $_ ) for 
   (@REQUIRED_FIELDS);

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    return $class->SUPER::new( %options, type => "ssh-2" );
}

###########################################
sub as_string {
###########################################
    my($self) = @_;

    my $string = $self->options_as_string();
    $string .= " " if length $string;

    $string .= "$self->{encryption} $self->{key}";
    $string .= " $self->{email}" if length $self->{email};

    return $string;
}

###########################################
sub parse_multi_line {
###########################################
    my($self, $string) = @_;

    my @fields = ();

    while($string =~ s/^(.*):\s+(.*)//gm) {
        my($field, $value) = ($1, $2);
          # remove quotes
        $value =~ s/^"(.*)"$/$1/;
        push @fields, $field, $value;
        my $lcfield = lc $field;

        if( $self->accessor_exists( $lcfield ) ) {
            $self->$lcfield( $value );
        } else {
            WARN "Ignoring unknown field '$field'";
        }
    }

      # Rest is the key, split across several lines
    $string =~ s/\n//g;
    $self->key( $string );
    $self->type( "ssh-2" );

      # Comment: "rsa-key-20090703"
    if($self->comment() =~ /\b(.*?)-key/) {
        $self->encryption( "ssh-" . $1 );
    } elsif( ! $self->{strict} ) {
        WARN "Unknown encryption [", $self->comment(), 
             "] fixed to ssh-rsa"; 
        $self->encryption( "ssh-rsa" );
    }
}

###########################################
sub key_read {
############################################
    my($class, $line) = @_;

    if($line !~ s/^($KEYTYPE_REGEX)\s*//) {
        DEBUG "No SSH2 keytype found";
        return undef;
    }

    my $encryption = $1;
    DEBUG "Parsed encryption $encryption";

    if($line !~ s/^(\S+)\s*//) {
        DEBUG "No SSH2 key found";
        return undef;
    }

    my $key = $1;
    DEBUG "Parsed key $key";

    my $email = $line;

    my $obj = __PACKAGE__->new();
    $obj->encryption( $encryption );
    $obj->key( $key );
    $obj->email( $email );
    $obj->comment( $email );

    return $obj;
}

###########################################
sub sanity_check {
###########################################
    my($self) = @_;

    for my $field (@REQUIRED_FIELDS) {
        if(! length $self->$field()) {
            WARN "ssh-2 sanity check failed '$field' requirement";
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

Net::SSH::AuthorizedKey::SSH2 - Net::SSH::AuthorizedKey subclass for ssh-2

=head1 DESCRIPTION

See Net::SSH::AuthorizedKey.

=head1 LEGALESE

Copyright 2005 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2005, Mike Schilli <m@perlmeister.com>
