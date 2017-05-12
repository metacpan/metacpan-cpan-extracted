package PerlIO::via::json;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.02';

use XML::XML2JSON;


### PerlIO::via interface

sub PUSHED {
    bless {
        obj => XML::XML2JSON->new()
    }, $_[0];
}

sub FILL {
    my ($self, $fh) = @_;

    local $/;
    my $t = <$fh>;
    (defined $t) ? $self->{obj}->xml2json($t) : undef;
}

sub WRITE {
    my ($self, $buf, $fh) = @_;
    if (print $fh $self->{obj}->json2xml($buf)) {
        return length($buf);
    }
    else {
        return -1;
    }
}

1;
__END__

=head1 NAME

PerlIO::via::json - PerlIO layer to convert to and from JSON

=head1 SYNOPSIS

  use PerlIO::via::json;
  open my $fh, '<:via(json)', 'file.xml' or die "...: $!";
  my $json = <$fh>;

  open my $fh, '>:via(json)', 'file.xml' or die "...: $!";
  print $fh '{"key":"value"}';

=head1 DESCRIPTION

This module implements a PerlIO layer that converts a file to or from
JSON format.

In fact, it currently only supports converting between XML and JSON.
Any suggestions?

Note: The XMLE<lt>-E<gt>JSON conversion relies on XML::XML2JSON.
The XML file will be slurped and parsed all at once.

=head1 SEE ALSO

L<XML::XML2JSON|XML::XML2JSON>

=head1 AUTHORS

Scott Lanning E<lt>slanning@cpan.orgE<gt>.

Ideas and/or code taken freely from other PerlIO::via modules,
particularly those of Elizabeth Mattijsen (esp. PerlIO::via::QuotedPrint).

=head1 LICENSE

Copyright 2009,2017, Scott Lanning.
This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
