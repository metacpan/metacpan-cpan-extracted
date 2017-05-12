###########################################
package Net::SSH::AuthorizedKey::Base;
###########################################
use strict;
use warnings;
use Log::Log4perl qw(:easy);
use Text::ParseWords;
use Digest::MD5 qw(md5_hex);

  # Accessors common for both ssh1 and ssh2 keys
our @accessors = qw(key type error email comment);
__PACKAGE__->make_accessor( $_ ) for @accessors;

  # Some functions must be implemented in the subclass
do {
    no strict qw(refs);

    *{__PACKAGE__ . "::$_"} = sub {
        die "Whoa! '$_' in the virtual base class has to be ",
            " implemented by a real subclass.";
    };

} for qw(option_type as_string);

  # Options accepted by all keys
our %VALID_OPTIONS = (
    "no-port-forwarding"  => 1,
    "no-agent-forwarding" => 1,
    "no-x11-forwarding"   => 1,
    "no-pty"              => 1,
    "no-user-rc"          => 1,
    command               => "s",
    environment           => "s",
    from                  => "s",
    permitopen            => "s",
    tunnel                => "s",
);

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        error        => "(no error)",
        option_order => [],
        %options,
    };

    bless $self, $class;
    return $self;
}

###########################################
sub option_type_global {
###########################################
    my($self, $key) = @_;

    if(exists $VALID_OPTIONS{ $key }) {
        return $VALID_OPTIONS{ $key };
    }

      # Maybe the subclass knows about it
    return $self->option_type($key);
}

###########################################
sub options {
###########################################
    my($self) = @_;

    return {
        map { $_ => $self->option( $_ ) } 
            keys %{ $self->{ options } } 
    };
}

###########################################
sub option {
###########################################
    my($self, $key, $value, $append) = @_;

    $key = lc $key;

    my $option_type = $self->option_type_global($key);

    if(! defined $option_type) {
        LOGWARN "Illegal option '$key'";
        return undef;
    }

    if(defined $value) {

        if( $append ) {
            if( $self->{options}->{$key} and
                ref($self->{options}->{$key}) ne "ARRAY" ) {
                $self->{options}->{$key} = [ $self->{options}->{$key} ];
            }
        } else {
            $self->option_delete( $key );
        }

        if($option_type eq "s") {
            if( $self->{options}->{$key} and
                ref($self->{options}->{$key}) eq "ARRAY" ) {
                DEBUG "Adding option $key to $value";
                push @{ $self->{options}->{$key} }, $value;
            } else {
                DEBUG "Setting option $key to $value";
                $self->{options}->{$key} = $value;
            }
        } else {
            $self->{options}->{$key} = undef;
        }
        push @{ $self->{option_order} }, $key;
    }

    if( "$option_type" eq "1" ) {
        return exists $self->{options}->{$key};
    }

    return $self->{options}->{$key};
}

###########################################
sub option_delete {
###########################################
    my($self, $key) = @_;

    $key = lc $key;

    @{ $self->{option_order} } = 
        grep { $_ ne $key } @{ $self->{option_order} };

    delete $self->{options}->{$key};
}

###########################################
sub options_as_string {
###########################################
    my($self) = @_;

    my $string = "";
    my @parts  = ();

    for my $option ( @{ $self->{option_order} } ) {
        if(defined $self->{options}->{$option}) {
            if(ref($self->{options}->{$option}) eq "ARRAY") {
                for (@{ $self->{options}->{$option} }) {
                    push @parts, option_quote($option, $_);
                }
            } else {
                push @parts, option_quote($option, $self->{options}->{$option});
            }
        } else {
            push @parts, $option;
        }
    }
    return join(',', @parts);
}

###########################################
sub option_quote {
###########################################
    my($option, $text) = @_;

    $text =~ s/([\\"])/\\$1/g;
    return "$option=\"" . $text . "\"";
}

###########################################
sub parse {
###########################################
    my($class, $string) = @_;

    DEBUG "Parsing line '$string'";

    # Clean up leading whitespace
    $string =~ s/^\s+//;
    $string =~ s/^#.*//;
 
    if(! length $string) {
        DEBUG "Nothing to parse";
        return;
    }

    if(my $key = $class->key_read( $string ) ) {
          # We found a key without options
        $key->{options} = {};
        DEBUG "Found ", $key->type(), " key: ", $key->as_string();
        return $key;
    }

    # No key found. Probably there are options in front of the key.
    # By the way: the openssh-5.x parser doesn't allow escaped 
    # backslashes (\\), so we don't either.
    my $rc = (
        (my $key_string = $string) =~ 
                      s/^((?:
                           (?:"(?:\\"|.)*?)"|
                           \S
                          )+
                         )
                       //x );
    my $options_string = ($rc ? $1 : "");
    $key_string        =~ s/^\s+//;

    DEBUG "Trying line with options stripped: [$key_string]";

    if(my $key = $class->key_read( $key_string ) ) {
          # We found a key with options
        $key->{options} = {};
        $key->options_parse( $options_string );
        DEBUG "Found ", $key->type(), " key: ", $key->as_string();
        return $key;
    }

    DEBUG "$class cannot parse line: $string";

    return undef;
}

###########################################
sub options_parse {
###########################################
    my($self, $string) = @_;

    DEBUG "Parsing options: [$string]";
    my @options = parse_line(qr/\s*,\s*/, 0, $string);

      # delete empty/undefined fields
    @options = grep { defined $_ and length $_ } @options;

    DEBUG "Parsed options: ", join(' ', map { "[$_]" } @options);

    for my $option (@options) {
        my($key, $value) = split /=/, $option, 2;
        $value = 1 unless defined $value;
        $value =~ s/^"(.*)"$/$1/; # remove quotes

        $self->option($key, $value, 1);
    }
}

###########################################
sub fingerprint {
###########################################
    my($self) = @_;

    my $data = $self->options();

    my $string = join '', map { $_ => $data->{$_} } sort keys %$data;
    $string .= $self->key();

    return md5_hex($string);
}

##################################################
# Poor man's Class::Struct
##################################################
sub make_accessor {
##################################################
    my($package, $name) = @_;

    no strict qw(refs);

    my $code = <<EOT;
        *{"$package\\::$name"} = sub {
            my(\$self, \$value) = \@_;

            if(defined \$value) {
                \$self->{$name} = \$value;
            }
            if(exists \$self->{$name}) {
                return (\$self->{$name});
            } else {
                return "";
            }
        }
EOT
    if(! defined *{"$package\::$name"}) {
        eval $code or die "$@";
    }
}

1;

__END__

=head1 NAME

Net::SSH::AuthorizedKey::Base - Virtual Base Class for ssh keys

=head1 SYNOPSIS

    # Documentation to understand methods shared
    # by all parsers. Not for direct use.

=head1 DESCRIPTION

This is the key parser base class, offering methods common to all
parsers. Don't use it directly, but read the documentation below to
see what functionality all parsers offer.

=over 4

=item error()

If a parser fails for any reason, it will leave a textual description of
the error that threw it off. This methods retrieves the error text.

=item options()

=item key()

The actual content of the key, either a big number in case of ssh-1 or
a base64-encoded string for ssh-2.

=item type()

Type of a key. (Somewhat redundant, as you could also check what subclass
a key is of). Either set to C<"ssh-1"> or C<"ssh-2">.

=item email()

Identical with comment().

=item comment()

Identical with email(). This is the text that follows in the authorized_keys
file after the key content. Mostly used for emails and host names.

=back

=head1 LEGALESE

Copyright 2005-2009 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2005, Mike Schilli <m@perlmeister.com>
