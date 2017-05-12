package Sleep::Request;

use strict;
use warnings;

use JSON::XS;

sub new {
    my $klass   = shift;
    my $request = shift;
    my $db      = shift;
    my @vars    = @_;

    my $self = bless { request => $request, db => $db, vars => \@vars }, $klass;

    return $self;
}

sub id {
    my $self = shift;
    return $self->{vars}->[0];
}

sub decode {
    my $self = shift;
    my $data = shift;

    $self->{data} = decode_json($data);

    return;
}

sub data {
    my $self = shift;
    return $self->{data};
}

1;

__END__


=head1 NAME

Sleep::Request - A Sleep request.

=head1 DESCRIPTION

=head1 CLASS METHODS 

=over 4

=item new

Constructor. Needs three arguments: C<request>, the apache request; C<db>, a
database object; and C<vars>, an array with the variables parsed from the URL.

=back

=head1 METHODS 

=over 4

=item id

Returns the first variable from C<vars>.

=item decode($data)

Parses the JSON data in C<$data> to a perl representation. Retrieve this value using C<data>.

=item data

Return the parsed data object.

=back



=head1 BUGS

If you find a bug, please let the author know.

=head1 COPYRIGHT

Copyright (c) 2008 Peter Stuifzand.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 AUTHOR

Peter Stuifzand E<lt>peter@stuifzand.euE<gt>

