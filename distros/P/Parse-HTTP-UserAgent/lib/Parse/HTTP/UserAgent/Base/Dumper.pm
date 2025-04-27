package Parse::HTTP::UserAgent::Base::Dumper;
$Parse::HTTP::UserAgent::Base::Dumper::VERSION = '0.43';
use strict;
use warnings;
use Carp qw( croak );
use Parse::HTTP::UserAgent::Constants qw(:all);

sub dumper {
    my($self, @args) = @_;
    my %opt = @args % 2 ? () : (
        type      => 'dumper',
        format    => 'none',
        interpret => 0,
        @args
    );
    my $meth = '_dumper_' . lc $opt{type};
    croak "Don't know how to dump with $opt{type}" if ! $self->can( $meth );
    my $buf = $self->$meth( \%opt );
    return $buf if defined wantarray;
    my $pok = print $buf ."\n";
    return;
}

sub _dump_to_struct {
    my %struct    = shift->as_hash;
    $struct{$_} ||= [] for qw( dotnet mozilla extras tk );
    $struct{$_} ||= 0  for qw( unknown );
    return \%struct;
}

sub _dumper_json {
    my $self = shift;
    my $opt  = shift;
    require JSON;
    return  JSON::to_json(
                $self->_dump_to_struct,
                { pretty => $opt->{format} eq 'pretty' }
            );
}

sub _dumper_xml {
    my $self = shift;
    my $opt  = shift;
    require XML::Simple;
    return  XML::Simple::XMLout(
                $self->_dump_to_struct,
                RootName => 'ua',
                NoIndent => $opt->{format} ne 'pretty',
            );
}

sub _dumper_yaml {
    my $self = shift;
    my $opt  = shift;
    require YAML;
    return  YAML::Dump( $self->_dump_to_struct );
}

sub _dumper_dumper {
    # yeah, I know. Fugly code here
    my $self = shift;
    my $opt  = shift;
    my @ids  = $opt->{args} ?  @{ $opt->{args} } : $self->_object_ids;
    my $args = $opt->{args} ?                  1 : 0;
    my $max  = 0;
    map { $max = length $_ if length $_ > $max; } @ids;
    my @titles = qw( FIELD VALUE );
    my $buf    = sprintf "%s%s%s\n%s%s%s\n",
                        $titles[0],
                        (q{ } x (2 + $max - length $titles[0])),
                        $titles[1],
                        q{-} x $max, q{ } x 2, q{-} x ($max*2);
    require Data::Dumper;
    my @buf;
    foreach my $id ( @ids ) {
        my $name = $args ? $id->{name} : $id;
        my $val  = $args ? $id->{value} : $self->[ $self->$id() ];
        if ( $val && ref $val ) {
            my $d = Data::Dumper->new([$val]);
            $d->Indent(0);
            my $rv = $d->Dump;
            $rv =~ s{ \$VAR1 \s+ = \s+ }{}xms;
            $rv =~ s{ ; }{}xms;
            $val = $rv eq '[]' ? q{} : $rv;
        }
        push @buf, [
            $name,
            (q{ } x (2 + $max - length $name)),
            defined $val ? $val : q{}
        ];
    }
    foreach my $row ( sort { lc $a->[0] cmp lc $b->[0] } @buf ) {
        $buf .= sprintf "%s%s%s\n", @{ $row };
    }
    return $buf;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::HTTP::UserAgent::Base::Dumper

=head1 VERSION

version 0.43

=head1 DESCRIPTION

The parsed structure can be dumped to a text table for debugging.

=head1 NAME

Parse::HTTP::UserAgent::Base::Dumper - Base class to dump parsed structure

=head1 DEPRECATION NOTICE

This module is B<DEPRECATED>. Please use L<HTTP::BrowserDetect> instead.

=head1 METHODS

=head2 dumper

    my $ua = Parse::HTTP::UserAgent::Dumper->new( $string );
    print $ua->dumper;

=head1 SEE ALSO

L<Parse::HTTP::UserAgent>.

=head1 AUTHOR

Burak Gursoy

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
