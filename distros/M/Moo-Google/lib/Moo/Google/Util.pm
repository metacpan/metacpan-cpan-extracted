package Moo::Google::Util;
$Moo::Google::Util::VERSION = '0.01';

# ABSTRACT: Portable functions

# use Exporter 'import'; # gives you Exporter's import() method directly
# our @EXPORT_OK = qw(substitute_placeholders);  # symbols to export on request

use Moo;

has 'debug' => ( is => 'rw', default => 0, lazy => 1 );

# has 'calendarId' => ( is => 'rw' );

use Data::Dumper;


sub substitute_placeholders {
    my ( $self, $string, $parameters ) = @_;

    # find all parameters in string
    my @matches = $string =~ /{([a-zA-Z_]+)}/g;

    warn "Util substitute_placeholders() matches: " . Dumper \@matches
      if ( $self->debug );

    for my $prm (@matches) {

        # warn $prm;
        if ( defined $parameters->{$prm} ) {
            my $s = $parameters->{$prm};
            warn "Value of " . $prm . " took from passed parameters: " . $s
              if ( $self->debug );
            $string =~ s/{$prm}/$s/g;

            #}
            #  elsif (defined $self->$prm) {
            #   my $s = $self->$prm;
            #   warn "Value of ".$prm." took from class attributes: ".$s;
            #   $string =~ s/{$prm}/$s/g;
        }
        else {
            die "cant replace " . $prm . " placeholder: no source";
        }
    }
    return $string;
}


sub substitute_placeholder {
    my ( $self, $string, $var ) = @_;
    my $param_name;
    if ( $string =~ /{([a-zA-Z]+)}/ ) {
        $param_name = $1;
    }
    if ( defined $var ) {
        $string =~ s/{([a-zA-Z]+)}/$var/;
    }
    else {
        my $subst = $self->$param_name;
        $string =~ s/{([a-zA-Z]+)}/$subst/;
    }
    return $string;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Moo::Google::Util - Portable functions

=head1 VERSION

version 0.01

=head1 METHODS

=head2 substitute_placeholders

  placeholderS (S)!

  warn $gapi->Calendar->Events->substitute_placeholders('users/{token}/calendarList/{calendarId}/{eventID}', {
    token =>'12345',
    calendarId => '54321',
    eventId => 'abcdef'
  });  # must be users/12345/calendarList/54321/abcdef

  or

  $gapi->Calendar->Events->token('12345');
  $gapi->Calendar->Events->calendarId('54321');
  $gapi->Calendar->Events->eventId('abcdef');
  # all atributes must be set in class
  warn $gapi->Calendar->Events->substitute_placeholders('users/{token}/calendarList/{calendarId}/{eventID}');  # must be users/12345/calendarList/54321/abcdef

=head2 substitute_placeholder

Substitute only one placeholder (first in string)

  substitute_placeholders('users/me/calendarList/{calendarId}/', '12345'); # will return 'users/me/calendarList/12345'

but

  substitute_placeholders('users/me/calendarList/{calendarId}/{placeholder2}', '12345'); # will return 'users/me/calendarList/12345/{placeholder2}'

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
