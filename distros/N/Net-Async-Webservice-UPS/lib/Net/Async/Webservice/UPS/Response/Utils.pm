package Net::Async::Webservice::UPS::Response::Utils;
$Net::Async::Webservice::UPS::Response::Utils::VERSION = '1.1.4';
{
  $Net::Async::Webservice::UPS::Response::Utils::DIST = 'Net-Async-Webservice-UPS';
}
use strict;
use warnings;
use 5.010;
use Sub::Exporter -setup => {
    exports => [qw(img_if pair_if base64_if
                   in_if out_if in_object_if in_object_array_if in_datetime_if
                   set_implied_argument)],
};
use DateTime::Format::Strptime;
use Module::Runtime 'use_module';
use Scope::Upper qw(reap :words);

# ABSTRACT: utility functions to parse hashrefs into response objects


my $implied_arg;

sub set_implied_argument {
    my ($value) = @_;

    $implied_arg = $value;
    reap { undef $implied_arg } UP;
}


sub out_if {
    my ($key,$attr) = @_;
    if ($implied_arg->$attr) {
        return ($key => $implied_arg->$attr);
    }
    return;
}


sub in_if {
    my ($attr,$key) = @_;
    if ($implied_arg->{$key}) {
        return ($attr => $implied_arg->{$key});
    }
    return;
}


sub in_object_if {
    my ($attr,$key,$class) = @_;
    if ($implied_arg->{$key}) {
        return ($attr => use_module($class)->new($implied_arg->{$key}));
    }
    return;
}


sub in_object_array_if {
    my ($attr,$key,$class) = @_;
    if ($implied_arg->{$key}) {
        my $arr = $implied_arg->{$key};
        if (ref($arr) ne 'ARRAY') { $arr = [ $arr ] };
        return (
            $attr => [
                map { use_module($class)->new($_) } @$arr
            ],
        );
    }
    return;
}


{my $date_parser = DateTime::Format::Strptime->new(
    pattern => '%Y%m%d%H%M%S',
);
 sub in_datetime_if {
     my ($attr,$key) = @_;
     if ($implied_arg->{$key} && $implied_arg->{$key}{Date}) {
         return ( $attr => $date_parser->parse_datetime($implied_arg->{$key}{Date}.$implied_arg->{$key}{Time}) );
     }
     return;
}}


sub pair_if {
    return @_ if $_[1];
    return;
}


sub img_if {
    my ($key,$hash) = @_;
    if ($hash && %{$hash}) {
        require Net::Async::Webservice::UPS::Response::Image;
        return ( $key => Net::Async::Webservice::UPS::Response::Image->new($hash) )
    }
    return;
}


sub base64_if {
    return ($_[0],decode_base64($_[1])) if $_[1];
    return;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS::Response::Utils - utility functions to parse hashrefs into response objects

=head1 VERSION

version 1.1.4

=head1 DESCRIPTION

The functions in this module are mostly for internal use, they may
change or be removed without prior notice.

=head1 FUNCTIONS

=head2 C<set_implied_argument>

Sets the ref that most other functions read from. It localises the
assignment to the calling frame, so you don't have to remember to
unset it.

=head2 C<out_if>

  out_if($key,$attr)

If C<< $implied_arg->$attr >> is true, returns C<< $key =>
$implied_arg->$attr >>, otherwise returns an empty list.

=head2 C<in_if>

  in_if($attr,$key)

If C<< $implied_arg->{$key} >> is true, returns C<< $attr =>
$implied_arg->{$key} >>, otherwise returns an empty list.

=head2 C<in_object_if>

  in_object_if($attr,$key,$class)

If C<< $implied_arg->{$key} >> is true, returns C<< $attr =>
$class->new($implied_arg->{$key}) >>, otherwise returns an empty
list. It also loads C<$class> if necessary.

=head2 C<in_object_array_if>

  in_object_array_if($attr,$key,$class)

If C<< $implied_arg->{$key} >> is true, maps each of its elements via
C<< $class->new($_) >>, and returns C<< $attr => \@mapped_elements >>,
otherwise returns an empty list. It also loads C<$class> if necessary.

If C<< $implied_arg->{$key} >> is not an array, this function will map
C<< [ $implied_arg->{$key} ] >>.

=head2 C<in_datetime_if>

  in_datetime_if($attr,$key)

If C<< $implied_arg->{$key} >> is a hashref that contains a C<Date>
key, parses the values corresponding to the C<Date> and C<Time> keys,
and returns C<< $attr => $parsed_date >>, otherwise returns an empty
list.

The L<DateTime> object in the returned list will have a floating time
zone.

=head2 C<pair_if>

  pair_if($key,$value);

If C<$value> is true, returns the arguments, otherwise returns an
empty list.

This function does not use the implied argument.

=head2 C<img_if>

  img_if($key,$hash);

If C<$hash> is a non-empty hashref, coverts it into a
L<Net::Async::Webservice::UPS::Response::Image> and returns C<< $key
=> $image >>, otherwise returns an empty list.

This function does not use the implied argument.

=head2 C<base64_if>

  base64_if($key,$string);

If C<$string> is true, decodes its contents from Base64 and returns
C<< $key => $decoded_string >>, otherwise returns an empty list.

This function does not use the implied argument.

=head1 AUTHORS

=over 4

=item *

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=item *

Sherzod B. Ruzmetov <sherzodr@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
