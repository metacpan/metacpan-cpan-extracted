package Poz::Types::string;
use 5.032;
use strict;
use warnings;
use utf8;
use parent 'Poz::Types::scalar';
use Carp ();
use Email::Address ();
use URI::URL ();
use Net::IPv6Addr ();
use Time::Piece ();
use DateTime::Format::Strptime ();
use DateTime::Format::ISO8601 ();
use DateTime::Format::Duration::ISO8601 ();

sub new {
    my ($class, $opts) = @_;
    $opts = $opts || {};
    $opts->{required_error} //= "required";
    $opts->{invalid_type_error} //= "Not a string";
    my $self = $class->SUPER::new($opts);
    return $self;
}

sub rule {
    my ($self, $value) = @_;
    Carp::croak($self->{required_error}) unless defined $value;
    Carp::croak($self->{invalid_type_error}) unless !ref $value;
    return;
}

sub coerce {
    my ($self, $value) = @_;
    return "$value";
}

sub max {
    my ($self, $max, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Too long";
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        Carp::croak($opts->{message}) if CORE::length($value) > $max;
        return;
    };
    return $self;
}

sub min {
    my ($self, $min, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Too short";
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        Carp::croak($opts->{message}) if CORE::length($value) < $min;
        return;
    };
    return $self;
}

sub length {
    my ($self, $length, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Not the right length";
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        Carp::croak($opts->{message}) if CORE::length($value) != $length;
        return;
    };
    return $self;
}

sub email {
    my ($self, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Not an email";
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        my ($addr) = Email::Address->parse($value);
        Carp::croak($opts->{message}) unless defined $addr;
        return;
    };
    return $self;
}

sub url {
    my ($self, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Not an URL";
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        my $url = URI::URL->new($value);
        Carp::croak($opts->{message}) if !defined $url || !defined $url->scheme;
        return;
    };
    return $self;
}

sub emoji {
    my ($self, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Not an emoji";    
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        Carp::croak($opts->{message}) unless $value =~ /\p{Emoji}/;
        return;
    };
    return $self;
}

sub uuid {
    my ($self, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Not an UUID";
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        Carp::croak($opts->{message}) unless lc($value) =~ /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
        return;
    };
    return $self;
}

sub nanoid {
    my ($self, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Not a nanoid";
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        Carp::croak($opts->{message}) unless $value =~ /^[0-9a-zA-Z_-]{21}$/;
        return;
    };
    return $self;
}

sub cuid {
    my ($self, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Not a cuid";
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        Carp::croak($opts->{message}) unless $value =~ /^c[a-z0-9]{24}$/;
        return;
    };
    return $self;
}

sub cuid2 {
    my ($self, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Not a cuid2";
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        Carp::croak($opts->{message}) unless $value =~ /^[a-z0-9]{24,32}$/;
        return;
    };
    return $self;
}

sub ulid {
    my ($self, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Not an ulid";
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        Carp::croak($opts->{message}) unless $value =~ /^[0-9A-HJKMNP-TV-Z]{26}$/;
        return;
    };
    return $self;
}

sub regex {
    my ($self, $regex, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Not match regex";
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        Carp::croak($opts->{message}) unless $value =~ $regex;
        return;
    };
    return $self;
}

sub includes {
    my ($self, $includes, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Not includes $includes";
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        Carp::croak($opts->{message}) unless index($value, $includes) != -1;
        return;
    };
    return $self;
}

sub startsWith {
    my ($self, $startWith, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Not starts with $startWith";
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        Carp::croak($opts->{message}) unless index($value, $startWith) == 0;
        return;
    };
    return $self;
}

sub endsWith {
    my ($self, $endsWith, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Not ends with $endsWith";
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        Carp::croak($opts->{message}) unless substr($value, -1 * CORE::length($endsWith)) eq $endsWith;
        return;
    };
    return $self;
}

# supports ipv4 / ipv6
sub ip {
    my ($self, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Not an IP address";
    my $version = $opts->{version} || "any";
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        my $pass = 0;
        if ($version eq "v4" || $version eq "any") {
            my @octets = split(/\./, $value);
            if (scalar(@octets) == 4) {
                foreach my $octet (@octets) {
                    Carp::croak($opts->{message}) unless $octet =~ /^\d+$/ && $octet >= 0 && $octet <= 255;
                }
                $pass = 1;
            }
            if ($version eq "v4" && !$pass) {
                Carp::croak($opts->{message});
            }
        }
        if (!$pass && ($version eq "v6" || $version eq "any")) {
            Carp::croak($opts->{message}) unless Net::IPv6Addr::is_ipv6($value);
        }
        return;
    };
    return $self;
}

sub trim {
    my ($self) = @_;
    push @{$self->{transform}}, sub { 
        my ($self, $value) = @_;
        $value =~ s/^\s+|\s+$//g;
        return $value;
    };
    return $self;
}

sub toLowerCase {
    my ($self) = @_;
    push @{$self->{transform}}, sub { 
        my ($self, $value) = @_;
        return lc($value);
    };
    return $self;
}

sub toUpperCase {
    my ($self) = @_;
    push @{$self->{transform}}, sub { 
        my ($self, $value) = @_;
        return uc($value);
    };
    return $self;
}

sub date {
    my ($self, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Not a date";
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        Carp::croak($opts->{message}) unless $value =~ /^\d{4}-\d{2}-\d{2}$/;
        Carp::croak($opts->{message}) unless eval { Time::Piece->strptime($value, "%Y-%m-%d") };
        return;
    };
    return $self;
}

sub time {
    my ($self, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Not a time";
    my $precision = $opts->{precision} || 6;
    my $precision_regex = _build_precision_regex($precision);
    my $format_check = qr/^\d{2}:\d{2}:\d{2}$precision_regex$/;
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        my $format = "%H:%M:%S";
        Carp::croak($opts->{message}) unless $value =~ $format_check;
        if ($value =~ /\.[0-9]+/) {
            $format = "%H:%M:%S.%N";
        }
        my $formatter = DateTime::Format::Strptime->new(pattern => $format);
        Carp::croak($opts->{message}) unless eval { $formatter->parse_datetime($value) };
        return;
    };
    return $self;
}

# iso8601 format
sub datetime {
    my ($self, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Not a datetime";
    my $precision = $opts->{precision} || 6;
    my $precision_regex = _build_precision_regex($precision);
    my $offset = $opts->{offset} || 0;
    my $offset_regex = "(Z)?";
    if ($offset) {
        $offset_regex = "(Z|[+-][0-9]{4}|[+-][0-9]{2}(:[0-9]{2})?)?";
    }

    my $format_check = qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$precision_regex$offset_regex$/;
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        Carp::croak($opts->{message}) unless $value =~ $format_check;
        Carp::croak($opts->{message}) unless eval { DateTime::Format::ISO8601->parse_datetime($value) };
        return;
    };
    return $self;
}

sub _build_precision_regex {
    my ($precision) = @_;
    my $min_precision = 1;
    if ($precision < $min_precision) {
        $min_precision = $precision;
    }
    return "(\\.[0-9]{$min_precision,$precision})?";
}

# iso8601 duration
sub duration {
    my ($self, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Not a duration";
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        my $format = DateTime::Format::Duration::ISO8601->new;
        Carp::croak($opts->{message}) unless eval { $format->parse_duration($value) };
        return;
    };
    return $self;
}

sub base64 {
    my ($self, $opts) = @_;
    $opts = $opts || {};
    $opts->{message} //= "Not a base64";
    push @{$self->{rules}}, sub {
        my ($self, $value) = @_;
        Carp::croak($opts->{message}) unless $value =~ /^[A-Za-z0-9+\/]+={0,2}$/;
        return;
    };
    return $self;
}
1;

=head1 NAME

Poz::Types::string - A module for validating and transforming strings.

=head1 SYNOPSIS

    use Poz qw/z/;

    my $string = z->string;

    # Validate a string
    $string->rule($value);

    # Coerce a value to a string
    my $coerced_value = $string->coerce($value);

    # Add validation rules
    $string->max($max_length, \%opts);
    $string->min($min_length, \%opts);
    $string->email(\%opts);
    $string->url(\%opts);
    $string->emoji(\%opts);
    $string->uuid(\%opts);
    $string->nanoid(\%opts);
    $string->cuid(\%opts);
    $string->cuid2(\%opts);
    $string->ulid(\%opts);
    $string->regex($regex, \%opts);
    $string->includes($substring, \%opts);
    $string->startsWith($prefix, \%opts);
    $string->endsWith($suffix, \%opts);
    $string->ip(\%opts);
    $string->date(\%opts);
    $string->time(\%opts);
    $string->datetime(\%opts);
    $string->duration(\%opts);
    $string->base64(\%opts);

    # Add transformations
    $string->trim;
    $string->toLowerCase;
    $string->toUpperCase;

=head1 DESCRIPTION

This module provides a set of methods for validating and transforming strings. It includes rules for checking string length, format, and content, as well as transformations for modifying the string.

=head2 METHODS

=over 4

=item rule

    $string->rule($value);
    Validates that the value is a defined, non-reference string.

=item coerce

    my $coerced_value = $string->coerce($value);
    Coerces the value to a string.

=item max

    $string->max($max_length, \%opts);
    Adds a rule to ensure the string does not exceed the specified maximum length.

=item min

    $string->min($min_length, \%opts);
    Adds a rule to ensure the string is at least the specified minimum length.

=item email

    $string->email(\%opts);
    Adds a rule to validate that the string is a valid email address.

=item url

    $string->url(\%opts);
    Adds a rule to validate that the string is a valid URL.

=item emoji

    $string->emoji(\%opts);
    Adds a rule to validate that the string contains an emoji.

=item uuid

    $string->uuid(\%opts);
    Adds a rule to validate that the string is a valid UUID.

=item nanoid

    $string->nanoid(\%opts);
    Adds a rule to validate that the string is a valid NanoID.

=item cuid

    $string->cuid(\%opts);
    Adds a rule to validate that the string is a valid CUID.

=item cuid2

    $string->cuid2(\%opts);
    Adds a rule to validate that the string is a valid CUID2.

=item ulid

    $string->ulid(\%opts);
    Adds a rule to validate that the string is a valid ULID.

=item regex

    $string->regex($regex, \%opts);
    Adds a rule to validate that the string matches the specified regular expression.

=item includes

    $string->includes($substring, \%opts);
    Adds a rule to validate that the string includes the specified substring.

=item startsWith

    $string->startsWith($prefix, \%opts);
    Adds a rule to validate that the string starts with the specified prefix.

=item endsWith

    $string->endsWith($suffix, \%opts);
    Adds a rule to validate that the string ends with the specified suffix.

=item ip

    $string->ip(\%opts);
    Adds a rule to validate that the string is a valid IP address (IPv4 or IPv6).

=item trim

    $string->trim;
    Adds a transformation to trim whitespace from the string.

=item toLowerCase

    $string->toLowerCase;
    Adds a transformation to convert the string to lowercase.

=item toUpperCase

    $string->toUpperCase;
    Adds a transformation to convert the string to uppercase.

=item date

    $string->date(\%opts);
    Adds a rule to validate that the string is a valid date (YYYY-MM-DD).

=item time

    $string->time(\%opts);
    Adds a rule to validate that the string is a valid time (HH:MM:SS).

=item datetime

    $string->datetime(\%opts);
    Adds a rule to validate that the string is a valid ISO8601 datetime.

=item duration

    $string->duration(\%opts);
    Adds a rule to validate that the string is a valid ISO8601 duration.

=item base64

    $string->base64(\%opts);
    Adds a rule to validate that the string is a valid base64 encoded string.

=back

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut